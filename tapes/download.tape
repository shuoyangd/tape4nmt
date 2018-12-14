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

  if [[ $in == sacrebleu://* ]]; then
    # format: "sacrebleu://test-set langpair"

    # crazy bash notation to remove prefix
    args=(${in##*://})
    sacrebleu -t ${args[0]} -l ${args[1]} --echo $side > $out
  else
    for infile in $in; do
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
    done
  fi
}
