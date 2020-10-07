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
    :: .resource_flags="-l 'mem_free=16g,ram_free=16g'"
    :: .action_flags="-m ae -M dings@jhu.edu" {

  # . /export/home/sding/anaconda3/etc/profile.d/conda.sh  # start conda
  if [ ! -z $pyenv ] ; then
    # conda activate $pyenv
    set +u
    source $pyenv
    set -u
  fi

  ln -s $train_src_in train.$SRC
  ln -s $train_trg_in train.$TRG
  ln -s $dev_src_in dev.$SRC
  ln -s $dev_trg_in dev.$TRG

  python $fairseq/preprocess.py --source-lang $SRC --target-lang $TRG \
    --trainpref train --validpref dev \
    --destdir $out

  if [ -f ${out}.train.1.pt ] ; then
    touch $out
  fi
}

task train : fairseq
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
   :: train_weight_decay=@
   :: train_update_freq=@
   :: train_seed=@
   # :: train_encoder_type=@
   :: train_arch=@
   :: train_share_input_output_embed=@
   :: train_skip_invalid_size_inputs_valid_test=@
   :: .submitter=$submitter
   :: .resource_flags="-l 'hostname=c*,gpu=1,mem_free=4g,ram_free=4g'"
   :: .action_flags="-m bae -M dings@jhu.edu -q g.q" {

  sleep `od -An -N1 -i /dev/random` # avoid GPU clash

  # . /export/home/sding/anaconda3/etc/profile.d/conda.sh  # start conda
  if [ ! -z $pyenv ] ; then
   # conda activate $pyenv
   set +u
   source $pyenv
   set -u
  fi
  export device=`free-gpu`
  echo "gpu$device at "`hostname`
  if [ -z $device ] ; then
   echo "no device! grid cheaaaaaaaaaatin!"
   exit;
  fi

  cmd="python $fairseq/train.py $in --save-dir $out"
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
  CUDA_VISIBLE_DEVICES=`free-gpu` eval $cmd

  # models=`ls ${out}_* 2>/dev/null`
  # if [ ! -z "$models" ] ; then
  #   touch $out # cheat
  # fi
}

# the target input here is used to compute naïve acc and ppl,
# that's why we need post-bpe target input
task decode : fairseq
    # < src_in=$out@apply_bpe[DataSection:devtest,DevtestDataSection:test,side:src]
    # < trg_in=$out@apply_bpe[DataSection:devtest,DevtestDataSection:test,side:trg]
    < in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:test,side:src]
    < binarized_data_dir=$out@binarize_data
    < model=$out@train
    > out
    :: test_max_sent_length=@
    :: test_beam_size=@
    :: test_batch_size=@
    # :: test_replace_unk=@
    :: test_remove_bpe=@
    :: SRC=@
    :: TRG=@
    :: .submitter=$submitter
    :: .action_flags="-m ae -M dings@jhu.edu -q g.q"
    :: .resource_flags="-l 'hostname=c*,gpu=1,mem_free=4g,ram_free=4g'"
    :: pyenv=@ {

  # . /export/home/sding/anaconda3/etc/profile.d/conda.sh  # start conda
  if [ ! -z $pyenv ] ; then
    # conda activate $pyenv
    set +u
    source $pyenv
    set -u
  fi

  # if [ $refn -eq 1 ]; then
  #   cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in -replace_unk -verbose -output $out -batch_size 1 -beam_size 12"
    # cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -verbose -output $out -batch_size $test_batch_size -beam_size $test_beam_size -max_sent_length $test_max_sent_length"
  # else
  #   cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in0 -replace_unk -verbose -output $out -batch_size 1 -beam_size 12"
    # cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -verbose -output $out -batch_size $test_batch_size -beam_size $test_beam_size -max_sent_length $test_max_sent_length"
  # fi

  # if [ ! -z $test_replace_unk ]; then
  #   cmd=$cmd" -replace_unk"
  # fi

  cmd="python $fairseq/interactive.py --path $model/checkpoint_best.pt $binarized_data_dir --beam $test_beam_size --source-lang $SRC --target-lang $TRG"

  if [ ! -z $test_remove_bpe ] ; then
    cmd=$cmd" --remove-bpe"
  fi

  echo $cmd
  CUDA_VISIBLE_DEVICES=`free-gpu` $cmd < $in > decode.log
  cat decode.log | grep ^H | cut -f3- > $out
}

task cleanup
  < model_dir=$out@train
  > out {

    echo "remove intermediate models:" > $out
    ls $model_dir/checkpoint[0-9]*.pt >> $out
    rm $model_dir/checkpoint[0-9]*.pt
}

