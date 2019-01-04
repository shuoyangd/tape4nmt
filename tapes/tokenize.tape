global {
  tokenized_data=(DoTokenize:
    yes=$out@tokenize
    no=$out@download_or_link
   )
}

func tokenize : mosesdecoder tools # stanford_seg
    < in
    > out
    :: Lang {

  cat $in | perl -C31 -pe 's/(\p{Han})/ \1 /g'  \
    | ${mosesdecoder}/scripts/tokenizer/normalize-punctuation.perl -l $Lang \
    | ${mosesdecoder}/scripts/tokenizer/remove-non-printing-char.perl \
    | ${mosesdecoder}/scripts/tokenizer/tokenizer.perl -l $Lang -no-escape -protected ${mosesdecoder}/scripts/tokenizer/basic-protected-patterns -q \
    > $out
}

task tokenize calls tokenize : mosesdecoder tools # stanford_seg
    < in=$raw_data
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
