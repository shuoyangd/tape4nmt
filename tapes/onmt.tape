task binarize_data : onmt
    < train_src_in=$out@dummy_aggregate_subword[DataSection:train,side:src]  # FIXME
    < train_trg_in=$out@dummy_aggregate_subword[DataSection:train,side:trg]  # FIXME
    < dev_src_in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:dev,side:src]  # FIXME
    < dev_trg_in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:dev,side:trg]  # FIXME
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags_16g
    :: pyenv=@ {

  python $onmt/preprocess.py -train_src $train_src_in -train_tgt $train_trg_in -valid_src $dev_src_in -valid_tgt $dev_trg_in -save_data $out

  if [ -f ${out}.train.1.pt ] ; then
    touch $out
  fi
}

task train : onmt
    < in=$out@binarize_data
    > out
    :: .submitter="sge"
    :: .action_flags="-m bae -M dings@jhu.edu -q g.q"
    :: .resource_flags="-l 'hostname=c*,gpu=1,mem_free=4g,ram_free=4g'"
    :: pyenv=@
    :: train_train_from=@
    :: train_train_from_state_dict=@
    :: train_start_epoch=@
    :: train_layers=@
    :: train_rnn_size=@
    :: train_word_vec_size=@
    :: train_batch_size=@
    :: train_epochs=@
    :: train_optim=@
    :: train_dropout=@
    :: train_learning_rate=@
    :: train_encoder_type=@ {


  sleep `od -An -N1 -i /dev/random` # avoid GPU clash

  cmd="python $onmt/train.py -data $in -save_model $out"

  if [ ! -z $train_train_from ] ; then
    cmd=$cmd" -train_from $train_from"
  fi

  if [ ! -z $train_train_from_state_dict ] ; then
    cmd=$cmd" -train_from $train_from_state_dict"
  fi

  if [ ! -z $train_start_epoch ] ; then
    cmd=$cmd" -start_epoch $start_epoch"
  fi

  if [ ! -z $train_encoder_type ] ; then
    cmd=$cmd" -encoder_type $train_encoder_type"
  fi

  cmd=$cmd" -layers $train_layers -rnn_size $train_rnn_size -word_vec_size $train_word_vec_size -batch_size $train_batch_size -epochs $train_epochs -optim $train_optim -dropout $train_dropout -learning_rate $train_learning_rate"
  cmd=$cmd" -gpuid `free-gpu`"
  echo $cmd
  $cmd

  models=`ls ${out}_* 2>/dev/null`
  if [ ! -z "$models" ] ; then
    touch $out # cheat
  fi
}

task model_selection
    < in=$out@train
    > out
    :: test_model_selection_strategy=@ {

  touch list
  for dump in `ls ${in}_*`; do
    echo $dump
    acc=`basename $dump | grep -Eo "acc_[0-9\.]+" | grep -Eo "[0-9\.]+"`
    ppl=`basename $dump | grep -Eo "ppl_[0-9\.]+" | grep -Eo "[0-9\.]+"`
    epc=`basename $dump | grep -Eo "e[0-9]+" | grep -Eo "[0-9]+"`
    if [ "$test_model_selection_strategy" == "acc" ] ; then
      echo $acc >> list
    fi
    if [ "$test_model_selection_strategy" == "ppl" ] ; then
      echo $ppl >> list
    fi
  done


  if [ "$test_model_selection_strategy" == "acc" ] ; then
    best_crit=`sort -g list | tail -1`
    echo $best_crit
    best=`ls ${in}_* | grep acc_${best_crit} | tail -1`
  fi
  if [ "$test_model_selection_strategy" == "ppl" ] ; then
    best_crit=`sort -g list | head -1`
    echo $best_crit
    best=`ls ${in}_* | grep ppl_${best_crit} | tail -1`
  fi

  if [ ! -z $best ] ; then
    echo "$best is selected as the best model according to strategy: $test_model_selection_strategy"
    cp $best $out
  else
    echo "unsupported strategy $test_model_selection_strategy detected"
  fi

  rm list
}

# the target input here is used to compute naïve acc and ppl,
# that's why we need post-bpe target input
task decode : onmt
    < src_in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:test,side:src]
    < trg_in=$out@dummy_aggregate_subword[DataSection:devtest,DevtestDataSection:test,side:trg]
    < model=$out@model_selection
    > out
    :: test_max_sent_length=@
    :: test_beam_size=@
    :: test_batch_size=@
    :: test_replace_unk=@
    :: .submitter="sge"
    :: .action_flags="-m ae -M dings@jhu.edu -q g.q"
    :: .resource_flags="-l 'hostname=c*,gpu=1,mem_free=4g,ram_free=4g'"
    :: pyenv=@ {

  sleep `od -An -N1 -i /dev/random` # avoid GPU clash

  export device=`free-gpu`
  echo $device
  refn=`ls $trg_in* | wc -l`

  if [ $refn -eq 1 ]; then
    cmd="python $onmt/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in -replace_unk -verbose -output $out -batch_size 1 -beam_size 12"
    # cmd="python $onmt/translate.py -gpu $device -model $model -src $src_in -verbose -output $out -batch_size $test_batch_size -beam_size $test_beam_size -max_sent_length $test_max_sent_length"
  else
    cmd="python $onmt/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in0 -replace_unk -verbose -output $out -batch_size 1 -beam_size 12"
    # cmd="python $onmt/translate.py -gpu $device -model $model -src $src_in -verbose -output $out -batch_size $test_batch_size -beam_size $test_beam_size -max_sent_length $test_max_sent_length"
  fi

  if [ ! -z $test_replace_unk ]; then
    cmd=$cmd" -replace_unk"
  fi

  echo $cmd
  $cmd
}
