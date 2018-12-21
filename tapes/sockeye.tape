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
    :: model_size=@
    :: embed_size=@
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
    --num-embed=$embed_size \
    --source-factors-num-embed $source_factors_num_embed \
    --validation-source $dev_src \
    --validation-target $dev_trg \
    $dev_factor_flag \
    --encoder=$encoder_type \
    --decoder=$decoder_type \
    --num-layers=$num_layers \
    --num-embed=$embed_size \
    --transformer-model-size=$model_size \
    --transformer-attention-heads=8 \
    --transformer-feed-forward-num-hidden=2048 \
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
task package_model : sockeye
  < in=$raw_data[DataSection:test,side:src]
  > out
  :: .submitter=shell {

  # TODO
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
    device="--use-cpu"
  else
    device="--device-ids $(free-gpu)"
  fi

  factor_flag=""
  if [[ $factor_files != "/dev/null" ]]; then
    factor_flag="--input-factors $(cat $factor_files)"
  fi

  export PYTHONPATH=${sockeye}

  python3 -m sockeye.translate \
    -m $model \
    $device \
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
