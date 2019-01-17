global {
  src_truecaser=(UseExistingTruecaser:
    yes=""
    no=$out@train_truecaser[side:src]
  )
  trg_truecaser=(UseExistingTruecaser:
    yes=""
    no=$out@train_truecaser[side:trg]
  )

  # This has to be separated out from the recased_data definition, don't know why.
  maybe_lowered=(side: src=$out@lowercase trg=$out@dummy_aggregate_mask)

  # don't do truecase when doing characterize
  # truecase will mess up the word boundary annotation
  recased_data=(Casing:
    actual=$out@dummy_aggregate_mask
    true=$out@truecase
    lower_source=$maybe_lowered)
}

task train_truecaser : mosesdecoder
    < src_in=$out@dummy_aggregate_mask[DataSection:train,side:src]
    < trg_in=$out@dummy_aggregate_mask[DataSection:train,side:trg]
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
    < in=$out@dummy_aggregate_mask
    < model=(side: src=$src_truecaser trg=$trg_truecaser)
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/recaser/truecase.perl -model $model < $in > $out
}

task lowercase : mosesdecoder
  < in=$out@dummy_aggregate_mask
  > out
  :: .submitter=shell {

  cat $in | ${mosesdecoder}/scripts/tokenizer/lowercase.perl > $out
}

