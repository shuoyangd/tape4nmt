task prepare_data : sockeye
    < train_src_in=$prepared_data_src[DataSection:train]
    < train_trg_in=$prepared_data_trg[DataSection:train]
    < factor_files=(SourceFactors: no="/dev/null" yes=$factor_files@compute_source_factors[DataSection:train])
    > data
    :: pyenv=@
    :: train_maxlen=@
    :: source_factors=@
    :: seed=1235813
    :: .submitter=$submitter
    :: .resource_flags=$resource_flags_16g
    :: .action_flags=@ {

  export PYTHONPATH=${sockeye}

  source_factors_flag=""
  if [[ $factor_files != "/dev/null" ]]; then
    source_factors_flag="--source-factors $(cat $factor_files)"
  fi

  python3 -m sockeye.prepare_data \
      --source $train_src_in \
      $source_factors_flag \
      --target $train_trg_in \
      --shared-vocab \
      --word-min-count 2:2 \
      --bucket-width 10 \
      --max-seq-len $train_maxlen \
      --num-samples-per-shard 10000000 \
      --seed $seed \
      --output data
}

task train : sockeye
    < prepared_data=$data@prepare_data
    < dev_src=$prepared_data_src[DataSection:dev]
    < dev_trg=$prepared_data_trg[DataSection:dev]
    < dev_factor_files=(SourceFactors: no="/dev/null" yes=$factor_files@compute_source_factors[DataSection:dev])
    > model
    :: pyenv=@
    :: use_source_factors=(SourceFactors: no yes)
    :: train_batch_type=@
    :: train_batch_size=@
    :: train_max_checkpoints_not_improved=@
    :: train_checkpoint_freq=@
    :: train_num_decode_and_eval=@
    :: encoder_type=@
    :: decoder_type=@
    :: num_layers=@
    :: num_embed=@
    :: transformer_model_size=@
    :: transformer_attention_heads=@
    :: transformer_feed_forward_num_hidden=@
    :: source_factors=@
    :: source_factors_num_embed=@
    :: source_factors_combine=@
    :: use_cpu=@
    :: num_devices=@
    :: .submitter=$submitter
    :: .resource_flags=$resource_flags_train
    :: .action_flags=@ {

  if [[ $use_cpu == "yes" ]]; then
    device="--use-cpu"
  else
    device="--device-ids -$num_devices"
  fi

  dev_factors_flag=""
  source_factors_flag=""
  if [[ $use_source_factors == "yes" ]]; then
    dev_factors_flag="--validation-source-factors $(cat $dev_factor_files)"
    source_factors_flag="--source-factors-num-embed $source_factors_num_embed --source-factors-combine $source_factors_combine"
  fi

  export PYTHONPATH=${sockeye}

  python3 -m sockeye.train \
    -o $model \
    $device \
    --disable-device-locking \
    --prepared-data $prepared_data \
    --num-embed=$num_embed \
    $source_factors_flag \
    --validation-source $dev_src \
    --validation-target $dev_trg \
    $dev_factors_flag \
    --encoder=$encoder_type \
    --decoder=$decoder_type \
    --num-layers=$num_layers \
    --transformer-model-size=$transformer_model_size \
    --transformer-attention-heads=$transformer_attention_heads \
    --transformer-feed-forward-num-hidden=$transformer_feed_forward_num_hidden \
    --transformer-positional-embedding-type=fixed \
    --transformer-preprocess=n \
    --transformer-postprocess=dr \
    --transformer-dropout-attention=0.1 \
    --transformer-dropout-act=0.1 \
    --transformer-dropout-prepost=0.1 \
    --weight-tying \
    --weight-tying-type=src_trg_softmax \
    --weight-init=xavier \
    --weight-init-scale=3.0 \
    --weight-init-xavier-factor-type=avg \
    --optimizer=adam \
    --optimized-metric=perplexity \
    --label-smoothing=0.1 \
    --gradient-clipping-threshold=-1 \
    --initial-learning-rate=0.0002 \
    --learning-rate-reduce-num-not-improved=8 \
    --learning-rate-reduce-factor=0.9 \
    --learning-rate-scheduler-type=plateau-reduce \
    --learning-rate-decay-optimizer-states-reset=best \
    --learning-rate-decay-param-reset \
    --max-num-checkpoint-not-improved $train_max_checkpoints_not_improved \
    --batch-type=$train_batch_type \
    --batch-size=$train_batch_size \
    --checkpoint-frequency=$train_checkpoint_freq \
    --decode-and-evaluate=$train_num_decode_and_eval \
    --decode-and-evaluate-use-cpu \
    --keep-last-params=10
}

# Takes all the data and builds a packaged model directory.
# Ideally this should be used for evaluation.
task package_model : sockeye mosesdecoder sockeye_scripts
  < subword_model=(SubwordMethod: sentencepiece=$model@train_sentencepiece bpe=$model@train_bpe none="/dev/null")
  < casing_model=(Casing: actual="/dev/null" lower_source="/dev/null" true=$out@train_truecaser)
  < model=$model@train
  < observed_masks=(DoMasking: no="/dev/null" yes=$masks@mask[DataSection:train])
  > bundle="bundle"
  :: casing=(Casing: actual true lower_source)
  :: tokenize=(DoTokenize: yes="yes" no="no")
  :: mask=(DoMasking: no="no" yes="yes")
  :: masking_pattern_files=@
  :: masking_dict_files=@
  :: masking_add_index=@
  :: subword_method=(SubwordMethod: sentencepiece bpe none)
  :: use_factors=(SourceFactors: no yes)
  :: source_factors=@
  :: SRC=@
  :: TRG=@
  :: .submitter=shell {

  mkdir bundle
  cd bundle
  cp -a ${sockeye} sockeye
  cp -a ${sockeye_scripts} sockeye_scripts

  ## Pre-processing and post-processing
  rm -f pre.sh
  echo "#!/usr/bin/env bash" >> pre.sh
  echo >> pre.sh
  echo "lang=\${1:-$SRC}" >> pre.sh
  echo "rundir=\$(dirname \$0)" >> pre.sh

  rm -f post.sh
  echo "#!/usr/bin/env bash" >> post.sh
  echo >> post.sh
  echo "lang=\${1:-$TRG}" >> post.sh
  echo "rundir=\$(dirname \$0)" >> post.sh

  # Creates a JSON object from the plain input
  pre_cmd="\$rundir/sockeye_scripts/preparation/wrap_in_json -r raw_text"
  post_cmd="cat"

  if [[ $mask == "yes" ]]; then
    mkdir masker
    pre_cmd+=" | python \$rundir/sockeye_scripts/masking/mask_terms.py --json"

    if [[ $masking_pattern_files != "/dev/null" ]]; then
      pre_cmd+=" --pattern-files $masking_pattern_files"
    fi
    if [[ $masking_dict_files != "/dev/null" ]]; then
      pre_cmd+=" --dict-files $masking_dict_files"
    fi
    if [[ $masking_add_index == "yes" ]] ; then
      pre_cmd+=" --add-index"
    fi
  fi

  if [[ $tokenize == "yes" ]]; then
    mkdir tokenizer
    cp -a ${mosesdecoder}/scripts/tokenizer/* tokenizer/
    cp -a ${mosesdecoder}/scripts/share .
    cat > tokenizer/moses_tokenizer <<EOF
#!/bin/bash

rundir=\$(dirname \$0)
\$rundir/normalize-punctuation.perl -b -l $SRC \\
  | \$rundir/remove-non-printing-char.perl -b \\
  | \$rundir/tokenizer.perl -b -l $SRC -no-escape -protected \$rundir/basic-protected-patterns -q
EOF
    chmod 755 tokenizer/moses_tokenizer
    if [[ $SRC == "zh" || $SRC == "ja" || $SRC == "ko" ]]; then
      cp ${sockeye_scripts}/cjk/segment-cjk.py tokenizer/
      pre_cmd+=" | \$rundir/tokenizer/segment-cjk.py --json"
    fi

    pre_cmd+=" | \$rundir/sockeye_scripts/preparation/wrap_in_json text tok_text \$rundir/tokenizer/moses_tokenizer"
  fi

  prepare_casing_arg=""
  if [[ $casing == "lower_source" ]]; then
    prepare_casing_arg="--casing lower"
  elif [[ $casing == "true" ]]; then
    # cp -a ${mosesdecoder}/scripts/recaser .
    # cp ${casing_model} truecase.model
    # pre_cmd+=" | \$rundir/sockeye_scripts/preparation/wrap_in_json text recased_text \"\$rundir/recaser/truecase.perl -b -model \$rundir/truecase.model\""
    prepare_casing_arg="--casing true"
  fi

  prepare_subword_arg=""
  if [[ $subword_model != "/dev/null" ]]; then
    cp $subword_model subword.model
    prepare_subword_arg="--subword-type $subword_method --subword-model \$rundir/subword.model"

    if [[ $mask == "yes" && $subword_method == "bpe" ]]; then
      prepare_subword_arg+=" --subword-glossary $(cat $observed_masks | perl -pe 's/\n/ /g')"
    fi
  fi

  pre_cmd+=" | \$rundir/sockeye_scripts/preparation/prepare.py $prepare_casing_arg $prepare_subword_arg"

  if [[ $use_factors == "yes" ]]; then
    pre_cmd+=" | PYTHONPATH=\$rundir/sockeye_scripts python3 -m source_factors.compute --json $source_factors"
  fi  

  if [[ $subword_method != "none" ]]; then
      post_cmd+=" | \$rundir/sockeye_scripts/preparation/prepare.py --input-field translation --undo --subword-type $subword_method"
  fi

  if [[ $tokenize == "yes" ]]; then
    post_cmd+=" | \$rundir/sockeye_scripts/preparation/wrap_in_json text detok_translation \"\$rundir/tokenizer/detokenizer.perl -q -b -l $TRG\""
  fi

  if [[ $mask == "yes" ]]; then
    post_cmd+=" | python \$rundir/sockeye_scripts/masking/mask_terms.py --json --unmask"
  fi

  echo $pre_cmd >> pre.sh
  echo $post_cmd >> post.sh

  ## Translate
  cp -a ${model} sockeye_model
  cat > translate.sh <<EOF
#!/usr/bin/env bash

bundledir=\$(dirname \$0)

\$bundledir/pre.sh ${SRC} \\
  | PYTHONPATH=\$bundledir/sockeye python3 -m sockeye.translate -q -m \$bundledir/sockeye_model --json-input --output-type json "\$@" \\
  | \$bundledir/post.sh
EOF

  # permissions
  chmod 755 pre.sh post.sh translate.sh
}

task decode_with_bundle : sockeye tools
    < in=$raw_data_test_src
    < bundled_model=$bundle@package_model
    > out="out"
    > log="out.log"
    :: num_devices=@
    :: test_max_sent_length=@
    :: test_beam_size=@
    :: test_batch_size=@
    :: use_cpu=@
    :: .submitter=$submitter
    :: .action_flags=@
    :: .resource_flags=$resource_flags_decode
    :: pyenv=@ {

  if [[ $use_cpu == "yes" ]]; then
    device_flag="--use-cpu"
  else
    device_flag="--device-ids -1"
  fi

  ln -s $in corpus.in
  ln -s ${bundled_model} bundle

  cat $in | ${bundled_model}/translate.sh \
    $device_flag \
    --disable-device-locking \
    --beam-size $test_beam_size \
    --batch-size $test_batch_size \
    --max-input-len $test_max_sent_length \
    | tee ${out}.json | jq -r .text > $out 2> $log
}

# the target input here is used to compute naïve and ppl,
# that's why we need post-bpe target input
task decode : sockeye tools
    < in=$prepared_data_src[DataSection:test]
    < model=$model@train
    < factor_files=(SourceFactors: no="/dev/null" yes=$factor_files@compute_source_factors[DataSection:test])
    > out="out"
    > log="out.log"
    > scores="out.scores"
    :: num_devices=@
    :: test_max_sent_length=@
    :: test_beam_size=@
    :: test_batch_size=@
    :: use_cpu=@
    :: .submitter=$submitter
    :: .action_flags=@
    :: .resource_flags=$resource_flags_decode
    :: pyenv=@ {

  if [[ $use_cpu == "yes" ]]; then
    device_flag="--use-cpu"
  else
    device_flag="--device-ids -$num_devices"
  fi

  factor_flag=""
  if [[ $factor_files != "/dev/null" ]]; then
    factor_flag="--input-factors $(cat $factor_files)"
  fi

  export PYTHONPATH=${sockeye}

  python3 -m sockeye.translate \
    -m $model \
    $device_flag \
    --disable-device-locking \
    -i $in \
    $factor_flag \
    -o out.all \
    --output-type translation_with_score \
    --beam-size $test_beam_size \
    --batch-size $test_batch_size \
    --max-input-len $test_max_sent_length \

    cat out.all | $tools/bin/unpaste $scores $out
    mv out.all.log $log
}
