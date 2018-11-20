func tokenize : mosesdecoder tools # stanford_seg
    < in
    > out
    :: Lang {

  # segmentation for chinese
  if [ $Lang == "zh" ] || [ $Lang == "chn" ] || [ $Lang == "cn" ] ; then

    mkdir -p $PWD/tmp
    $stanford_seg/segmentstd.sh $stanford_seg/segment.sh $PWD/tmp ctb UTF-8 0 < $in | $mosesdecoder/scripts/tokenizer/escape-special-chars.perl | $tools/chinese-punctuations-utf8.perl > $out
    rm -r $PWD/tmp

  else
    $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $Lang < $in | $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $Lang -no-escape -q > $out
  fi
}

task tokenize calls tokenize : mosesdecoder tools # stanford_seg
    < in=$out@dummy_aggregate_merge
    > out
    :: Lang=(side: src=$SRC trg=$TRG)
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags

task characterize : tools
    < in=$out@tokenize  # FIXME fix test
    > out
    :: pyenv=@
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  if [ ! -z $pyenv ] ; then
    set +u
    source $pyenv
    set -u
  fi

  python $tools/characterize.py < $in > $out
}
