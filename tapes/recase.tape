global {
  recased_data_src=(Casing:
    actual=$tokenized_data_src
    lower_source=$src@recase
    true=$src@recase
  )
  recased_data_trg=(Casing:
    actual=$tokenized_data_trg
    lower_source=$tokenized_data_trg
    true=$trg@recase
  )
}

task train_truecaser : mosesdecoder
  < src_in=$tokenized_data_src[DataSection:train]
  < trg_in=$tokenized_data_trg[DataSection:train]
  > out
  :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  tmpfile=$(mktemp)

  for in_file in $in ; do
    cat $in_file >> $tmpfile
  done

  $mosesdecoder/scripts/recaser/train-truecaser.perl -corpus $tmpfile -model $out

  rm -f $tmpfile
}

task recase : mosesdecoder
  < src_in=$tokenized_data_src
  < trg_in=$tokenized_data_trg
  < truecaser=(Casing: actual="/dev/null" lower_source="/dev/null" true=$out@train_truecaser)
  > src
  > trg
  :: method=(Casing: actual lower_source true)
  :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  if [[ $method == "lower_source" ]]; then
    cat $src_in | ${mosesdecoder}/scripts/tokenizer/lowercase.perl > $src
    ln -sf $trg_in $trg
  elif [[ $method == "true" ]]; then
    ${mosesdecoder}/scripts/recaser/truecase.perl -model $model < $src_in > $src &
    ${mosesdecoder}/scripts/recaser/truecase.perl -model $model < $trg_in > $trg &
    wait
  fi
}

