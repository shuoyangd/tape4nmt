task train_truecaser : mosesdecoder
    < src_in=$prepared_data[DataSection:train,side:src]
    < trg_in=$prepared_data[DataSection:train,side:trg]
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  tmpfile=$(mktemp)

  for in_file in $in ; do
    cat $in_file >> $PWD/tmp
  done

  $mosesdecoder/scripts/recaser/train-truecaser.perl -corpus $tmpfile -model $out

  rm -f $tmpfile
}

task truecase : mosesdecoder
    < in=$tokenized_data
    < model=(side: src=$src_truecaser trg=$trg_truecaser)
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/recaser/truecase.perl -model $model < $in > $out
}
