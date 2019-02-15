global {

  raw_data_src=$src@download_or_link
  raw_data_trg=$trg@download_or_link

  raw_data_train_src=$src@download_or_link[DataSection:train]
  raw_data_train_trg=$trg@download_or_link[DataSection:train]

  raw_data_test_src=$src@download_or_link[DataSection:test]
  raw_data_test_trg=$trg@download_or_link[DataSection:test]

  raw_data_dev_src=$src@download_or_link[DataSection:dev]
  raw_data_dev_trg=$trg@download_or_link[DataSection:dev]
}

task download_or_link : tools mosesdecoder
  > src
  > trg
  :: prefixes=(DataSection: train=$train_prefix dev=$dev_prefix test=$test_prefix)
  :: SRC=@
  :: TRG=@
  :: section=(DataSection: train dev test)
  :: testing=(TestMode: no yes)
  :: train_clean_ratio=@
  :: train_maxlen=@
  :: pyenv=@ {

  rm -f $src $trg
  for prefix in $prefixes; do
    if [[ $prefix == sacrebleu://* ]]; then
      # format: "sacrebleu://test-set" (language pair taken from $SRC and $TRG)

      # Remove "sacrebleu://" from the prefix
      test_set=${prefix##*://}
      sacrebleu -t ${test_set} -l ${SRC}-${TRG} --echo both | ${tools}/bin/unpaste -a $src $trg
      if [[ $testing == "yes" ]]; then
        head -n 20 $src > t; mv t $src
        head -n 20 $trg > t; mv t $trg
      fi
    else
      if [[ $testing == "yes" ]]; then
        if [[ $section == "train" ]]; then
          numlines=10000
        else
          numlines=20
        fi
        head -n $numlines $prefix.$SRC >> $src    
        head -n $numlines $prefix.$TRG >> $trg
      else
        ${tools}/bin/zpaste $prefix.{$SRC,$TRG} | ${tools}/bin/unpaste -a $src $trg
      fi
    fi
  done

  mv $src corpus.$SRC
  mv $trg corpus.$TRG

  ${mosesdecoder}/scripts/training/clean-corpus-n.perl corpus $SRC $TRG cleaned $train_clean_ratio $train_maxlen

  mv cleaned.$SRC $src
  mv cleaned.$TRG $trg
}
