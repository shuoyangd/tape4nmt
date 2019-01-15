global {
  tokenized_data=(DoTokenize:
    yes=$out@tokenize
    no=$out@download_or_link
   )
}

func tokenize : mosesdecoder tools sockeye_scripts # stanford_seg
    < in
    > out
    :: Lang {

  if [[ $Lang == "zh" ]]; then
    cat $in | ${sockeye_scripts}/zh/segment-chinese.pl \
      | ${mosesdecoder}/scripts/tokenizer/normalize-punctuation.perl -l $Lang \
      | ${mosesdecoder}/scripts/tokenizer/remove-non-printing-char.perl \
      | ${mosesdecoder}/scripts/tokenizer/tokenizer.perl -l $Lang -no-escape -protected ${mosesdecoder}/scripts/tokenizer/basic-protected-patterns -q \
      > $out
  else
    cat $in \
      | ${mosesdecoder}/scripts/tokenizer/normalize-punctuation.perl -l $Lang \
      | ${mosesdecoder}/scripts/tokenizer/remove-non-printing-char.perl \
      | ${mosesdecoder}/scripts/tokenizer/tokenizer.perl -l $Lang -no-escape -protected ${mosesdecoder}/scripts/tokenizer/basic-protected-patterns -q \
      > $out
  fi
}

task tokenize calls tokenize : mosesdecoder tools # stanford_seg
    < in=$masked_data
    > out
    :: Lang=(side: src=$SRC trg=$TRG)
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags

task characterize : tools
    < in=$out@tokenize
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
