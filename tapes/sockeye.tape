task prepare_data : sockeye
    < train_src_in=$prepared_data[DataSection:train,side:src]
    < train_trg_in=$prepared_data[DataSection:train,side:trg]
    < factor_files=(SourceFactors: no="/dev/null" yes=$factor_files@compute_source_factors[DataSection:train])
    > data
    :: pyenv=@
    :: train_max_sent_length=$MaxLen
    :: source_factors=@
    :: seed=1235813
    :: .submitter=$submitter
    :: .resource_flags=$resource_flags_16g
    :: .action_flags=@ {

  export PYTHONPATH=${sockeye}

  source_factor_flag=""
  if [[ $factor_files != "/dev/null" ]]; then
    source_factor_flag="--source-factors $(cat $factor_files)"
  fi

  python3 -m sockeye.prepare_data \
      --source $train_src_in \
      $source_factor_flag \
      --target $train_trg_in \
      --shared-vocab \
      --word-min-count 2:2 \
      --bucket-width 10 \
      --max-seq-len $train_max_sent_length \
      --num-samples-per-shard 10000000 \
      --seed $seed \
      --output data
}

task train : sockeye
    < prepared_data=$data@prepare_data
    < dev_src=$prepared_data[DataSection:dev,side:src]
    < dev_trg=$prepared_data[DataSection:dev,side:trg]
    < dev_factor_files=(SourceFactors: no="/dev/null" yes=$factor_files@compute_source_factors[DataSection:dev])
    > model
    :: pyenv=@
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

  dev_factor_flag=""
  if [[ $dev_factor_files != "/dev/null" ]]; then
    dev_factor_flag="--validation-source-factors $(cat $dev_factor_files)"
  fi

  export PYTHONPATH=${sockeye}

  source deactivate
  conda activate sockeye

  python3 -m sockeye.train \
    -o $model \
    $device \
    --disable-device-locking \
    --prepared-data $prepared_data \
    --source-factors-combine $source_factors_combine \
    --num-embed=$num_embed \
    --source-factors-num-embed $source_factors_num_embed \
    --validation-source $dev_src \
    --validation-target $dev_trg \
    $dev_factor_flag \
    --encoder=$encoder_type \
    --decoder=$decoder_type \
    --num-layers=$num_layers \
    --num-embed=$embed_size \
    --transformer-model-size=$model_size \
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
task package_model : sockeye mosesdecoder
  < in=$raw_data[DataSection:test,side:src]
  < subword_model=(SubwordMethod: sentencepiece=$model@train_sentencepiece bpe=$model@train_bpe none="/dev/null")
  < casing_model=(Casing: actual="/dev/null" true=$out@train_truecaser lower_source="/dev/null")
  < model=$model@train
  > bundle="bundle"
  :: casing=(Casing: actual true lower_source)
  :: tokenize=(DoTokenize: yes="yes" no="no")
  :: subword_method=(SubwordMethod: sentencepiece bpe none)
  :: SRC=@
  :: TRG=@
  :: .submitter=shell {

  mkdir bundle
  cd bundle
  cp -a ${sockeye} sockeye

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

  pre_cmd="cat"
  post_cmd="cat"
  if [[ $tokenize == "yes" ]]; then
    mkdir tokenizer
    cp -a ${mosesdecoder}/scripts/tokenizer/* tokenizer
    cp -a ${mosesdecoder}/scripts/share .
    pre_cmd="\$rundir/tokenizer/normalize-punctuation.perl -l \$lang | \$rundir/tokenizer/remove-non-printing-char.perl | \$rundir/tokenizer/tokenizer.perl -l \$lang -no-escape -protected \$rundir/tokenizer/basic-protected-patterns -q"
  fi

  if [[ $casing == "lower_source" ]]; then
    pre_cmd+=" | \$rundir/tokenizer/lowercase.perl"
  elif [[ $casing == "true" ]]; then
    cp -a ${mosesdecoder}/scripts/recaser .
    cp ${casing_model} truecase.model
    pre_cmd+=" | \$rundir/recaser/truecase.perl -model \$rundir/truecase.model"
  fi

  if [[ $subword_method == "sentencepiece" ]]; then
    mkdir bin
    cp ${sentencepiece}/build/src/spm_{encode,decode} bin
    cp $subword_model .
    pre_cmd+=" | \$rundir/bin/spm_encode --model \$rundir/$subword_model"
    post_cmd+=" | \$rundir/bin/spm_decode --model \$rundir/$subword_model"
  elif [[ $subword_method == "bpe" ]]; then
    cp $subword_model bpe.model
    pre_cmd+=" | subword-nmt apply-bpe -c \$rundir/bpe.model"
    post_cmd+=" | perl -pe 's/@@( |\$)//g'"
  fi

  if [[ $tokenize == "yes" ]]; then
    cp ${mosesdecoder}/scripts/tokenizer/detokenizer.perl moses
    post_cmd+=" | \$rundir/tokenizer/detokenizer.perl -q -l \$lang"
  fi

  echo $pre_cmd >> pre.sh
  echo $post_cmd >> post.sh

  ## Translate
  cp -a ${model} sockeye_model
  echo "#!/usr/bin/env bash" >> translate.sh
  echo "" >> translate.sh
  echo "bundledir=\$(dirname \$0)" >> translate.sh
  echo "" >> translate.sh
  echo "export PYTHONPATH=\$bundledir/sockeye" >> translate.sh
  echo "\$bundledir/pre.sh ${SRC} | python3 -m sockeye.translate -m \$bundledir/sockeye_model \"\$@\" | \$bundledir/post.sh" >> translate.sh

  # permissions
  chmod 755 pre.sh post.sh translate.sh
}

task decode_with_bundle : sockeye
    < in=$raw_data_test_src
    < bundled_model=$bundle@package_model
    > out="out"
    > log="out.log"
    > scores="out.scores"
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

  cat $in | ${bundled_model}/translate.sh \
    $device_flag \
    --disable-device-locking \
    --output-type translation_with_score \
    --beam-size $test_beam_size \
    --batch-size $test_batch_size \
    --max-input-len $test_max_sent_length \
    > out.all 2> $log

    cat out.all | unpaste $scores $out
}

# the target input here is used to compute naïve acc and ppl,
# that's why we need post-bpe target input
task decode : sockeye
    < in=$prepared_data[DataSection:test,side:src]
    < model=$model@train
    < factor_files=(SourceFactors: no="/dev/null" yes=$factor_files@compute_source_factors[DataSection:test])
    > out="out"
    > log="out.log"
    > scores="out.scores"
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

    cat out.all | unpaste $scores $out
    mv out.all.log $log
}
