func tokenize
    < in
    > out
    :: tokenizer_flags
    :: Lang {

  # segmentation for chinese
  if [ $Lang == "zh" ] || [ $Lang == "chn" ] || [ $Lang == "cn" ] ; then
    mkdir -p $PWD/tmp
    cat $in | $stanford_seg/segmentstd.sh $stanford_seg/segment.sh $PWD/tmp ctb UTF-8 0 | $mosesdecoder/scripts/tokenizer/escape-special-chars.perl | $tools/chinese-punctuations-utf8.perl > $out
    rm -r $PWD/tmp
  elif [ $Lang == "ro" ] ; then
    cat $in | $mosesdecoder/scripts/tokenizer/replace-unicode-punctuation.perl \
      | $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl \
      | $mosesdecoder/scripts/tokenizer/remove-non-printing-char.perl \
      | $wmt16_scripts/preprocess/normalise-romanian.py \
      | $wmt16_scripts/preprocess/remove-diacritics.py \
      | $mosesdecoder/scripts/tokenizer/tokenizer.perl -l $Lang $tokenizer_flags > $out
  else
    cat $in | $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $Lang | $mosesdecoder/scripts/tokenizer/tokenizer.perl -l $Lang $tokenizer_flags > $out
  fi
}

task tokenize calls tokenize : mosesdecoder tools wmt16_scripts # stanford_seg
    < in=$out@dummy_aggregate_merge
    > out
    :: Lang=(side: src=$SRC trg=$TRG)
    :: tokenizer_flags=@
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
