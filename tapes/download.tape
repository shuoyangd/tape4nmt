global {

  raw_data=$out@download_or_link
  raw_data_test_src=$out@download_or_link[DataSection:test,side:src]
  raw_data_test_trg=$out@download_or_link[DataSection:test,side:trg]

  dev_text=(SgmDev:
    no=$out@download_or_link[DataSection:dev]
    yes=(side: src=$src_out@dev_text_from_sgm trg=$trg_out@dev_text_from_sgm)
  )

  test_text=(SgmTest:
    no=$out@download_or_link[DataSection:test]
    yes=(side: src=$src_out@test_text_from_sgm trg=$trg_out@test_text_from_sgm)
  )
}

task download_or_link : tools
    :: in=(DataSection: train=$train_prefix dev=$dev_prefix test=$test_prefix)
    :: side=(side: src trg)
    :: SRC=@
    :: TRG=@
    :: section=(DataSection: train dev test)
    :: testing=(TestMode: no yes)
    > out
   :: pyenv=@ {

  if [[ $side == "src" ]]; then
    side="src"
    lang=$SRC
  elif [[ $side == "trg" ]]; then
    side="ref"
    lang=$TRG
  fi

  rm -f $out

  for infile in $in; do
    if [[ $infile == sacrebleu://* ]]; then
      # format: "sacrebleu://test-set" (language pair taken from $SRC and $TRG)

      # Removes the "sacrebleu://" prefix from $in
      test_set=${infile##*://}
      sacrebleu -t ${test_set} -l ${SRC}-${TRG} --echo $side >> $out
    else
      infile="$infile.$lang"

      if [[ $testing == "yes" ]]; then
        if [[ $section == "train" ]]; then
          numlines=10000
        else
          numlines=100
        fi
        head -n $numlines $infile >> $out
      else
        zcat -f $infile >> $out
      fi
    fi
  done
}
