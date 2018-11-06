task train_bpe : subword_nmt
      < src_in=$out@dummy_aggregate_truecase[DataSection:train,side:src]  # FIXME
      < trg_in=$out@dummy_aggregate_truecase[DataSection:train,side:trg]  # FIXME
      > out
      :: bpe_operations=@
      :: SRC=@
      :: TRG=@
      :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  cat $src_in $trg_in | $subword_nmt/learn_bpe.py -s $bpe_operations > $out
}

task apply_bpe : subword_nmt
    # < in=$truecased_data
    < in=$out@dummy_aggregate_truecase
    < model=$out@train_bpe
    > out {

  $subword_nmt/apply_bpe.py -c $model < $in > $out
}
