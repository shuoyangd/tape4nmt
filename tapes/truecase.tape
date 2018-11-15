task train_truecaser : mosesdecoder
    < in=$out@dummy_aggregate_tokenize[DataSection:train]  # FIXME
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  for in_file in $in ; do
    cat $in_file >> $PWD/tmp
  done

  $mosesdecoder/scripts/recaser/train-truecaser.perl -corpus $PWD/tmp -model $out

  rm $PWD/tmp
}

task truecase : mosesdecoder
    < in=$out@dummy_aggregate_tokenize
    < model=(side: src=$src_truecaser trg=$trg_truecaser)
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/recaser/truecase.perl -model $model < $in > $out
}
