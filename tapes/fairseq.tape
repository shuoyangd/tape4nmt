task binarize_data : fairseq
    < train_src_in=$out@dummy_aggregate_subword[DataSection:train,side:src]  # FIXME
    < train_trg_in=$out@dummy_aggregate_subword[DataSection:train,side:trg]  # FIXME
    < dev_src_in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:dev,side:src]  # FIXME
    < dev_trg_in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:dev,side:trg]  # FIXME
    > out
    :: pyenv=@
    # :: train_max_shard_size=@
    :: SRC=@
    :: TRG=@
    :: .submitter=$submitter
    :: .resource_flags=$resource_flags_16g
    :: .action_flags=$action_flags {

  ln -s $train_src_in train.$SRC
  ln -s $train_trg_in train.$TRG
  ln -s $dev_src_in dev.$SRC
  ln -s $dev_trg_in dev.$TRG

  PYTHONPATH=$fairseq fairseq-preprocess --source-lang $SRC --target-lang $TRG \
    --trainpref train --validpref dev \
    --destdir $out

  if [ -f ${out}.train.1.pt ] ; then
    touch $out
  fi
}

task train : fairseq tools
   < in=$out@binarize_data
   > out
   :: pyenv=@
   :: train_batch_size=@
   :: train_optim=@
   :: train_dropout=@
   :: train_adam_beta1=@
   :: train_adam_beta2=@
   :: train_lr=@
   :: train_lr_min=@
   :: train_lr_shrink=@
   :: train_lr_scheduler=@
   :: train_warmup_init_lr=@
   :: train_warmup_updates=@
   :: train_criterion=@
   :: train_label_smoothing=@
   :: train_clip_norm=@
   :: train_max_tokens=@
   :: train_max_epochs=@
   :: train_keep_last_epochs=@
   :: train_weight_decay=@
   :: train_update_freq=@
   :: train_seed=@
   # :: train_encoder_type=@
   :: train_arch=@
   :: train_share_input_output_embed=@
   :: train_skip_invalid_size_inputs_valid_test=@
   :: .submitter=$submitter
   :: .resource_flags=$resource_flags_train
   :: .action_flags=$action_flags {

  sleep `od -An -N1 -i /dev/random` # avoid GPU clash

  cmd="fairseq-train $in --save-dir $out"
  cmd=$cmd" --lr $train_lr --clip-norm $train_clip_norm --dropout $train_dropout --max-tokens $train_max_tokens --arch $train_arch"

  if [ ! -z $train_optim ] ; then
   cmd=$cmd" --optimizer $train_optim"
  fi

  if [ ! -z $train_lr_min ] ; then
   cmd=$cmd" --min-lr $train_lr_min"
  fi

  if [ ! -z $train_lr_shrink ] && [ "$train_lr_scheduler" != "inverse_sqrt" ] ; then
   cmd=$cmd" --lr-shrink $train_lr_shrink"
  fi

  if [ ! -z $train_lr_scheduler ] ; then
   cmd=$cmd" --lr-scheduler $train_lr_scheduler"
  fi

  if [ ! -z $train_warmup_init_lr ] ; then
   cmd=$cmd" --warmup-init-lr $train_warmup_init_lr"
  fi

  if [ ! -z $train_warmup_updates ] ; then
   cmd=$cmd" --warmup-updates $train_warmup_updates"
  fi

  if [ ! -z $train_criterion ] ; then
   cmd=$cmd" --criterion $train_criterion"
  fi

  if [ ! -z $train_label_smoothing ] ; then
   cmd=$cmd" --label-smoothing $train_label_smoothing"
  fi

  if [ ! -z $train_max_tokens ] ; then
   cmd=$cmd" --max-tokens $train_max_tokens"
  fi

  if [ ! -z $train_max_epochs ] ; then
  cmd=$cmd" --max-epoch $train_max_epochs"
  fi

  if [ ! -z $train_keep_last_epochs ] ; then
   cmd=$cmd" --keep-last-epochs $train_keep_last_epochs"
  fi

  if [ ! -z $train_weight_decay ] ; then
  cmd=$cmd" --weight-decay $train_weight_decay"
  fi

  if [ ! -z $train_update_freq ] ; then
  cmd=$cmd" --update-freq $train_update_freq"
  fi

  if [ ! -z $train_seed ] ; then
  cmd=$cmd" --seed $train_seed"
  fi

  if [ ! -z $train_adam_beta1 ] && [ ! -z $train_adam_beta2 ] ; then
   cmd=$cmd" --adam-betas '($train_adam_beta1, $train_adam_beta2)'"
  fi

  if [ ! -z $train_share_input_output_embed ] ; then
   cmd=$cmd" --share-input-output-embed"
  fi

  if [ ! -z $train_skip_invalid_size_inputs_valid_test ] ; then
   cmd=$cmd" --skip-invalid-size-inputs-valid-test"
  fi

  echo $cmd
  source $tools/get-gpu 1
  PYTHONPATH=$fairseq $cmd
}

# the target input here is used to compute naïve acc and ppl,
# that's why we need post-bpe target input
task decode : fairseq tools
    < in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:test,side:src]
    < binarized_data_dir=$out@binarize_data
    < model=$out@train
    > out
    :: test_max_sent_length=@
    :: test_beam_size=@
    :: test_batch_size=@
    :: test_remove_bpe=@
    :: SRC=@
    :: TRG=@
    :: .submitter=$submitter
    :: .resource_flags=$resource_flags_decode
    :: .action_flags=$action_flags
    :: pyenv=@ {

  cmd="fairseq-interactive --path $model/checkpoint_best.pt $binarized_data_dir --beam $test_beam_size --source-lang $SRC --target-lang $TRG"

  if [ ! -z $test_remove_bpe ] ; then
    cmd=$cmd" --remove-bpe"
  fi

  echo $cmd
  source $tools/get-gpu 1
  PYTHONPATH=$fairseq $cmd < $in > decode.log
  cat decode.log | grep ^H | cut -f3- > $out
}

task cleanup
  < model_dir=$out@train
  > out {

    echo "remove intermediate models:" > $out
    ls $model_dir/checkpoint[0-9]*.pt >> $out
    rm $model_dir/checkpoint[0-9]*.pt
}

