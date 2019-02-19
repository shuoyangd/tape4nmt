global {
  tokenized_data_src=(DoTokenize:
    yes=$src@tokenize
    no=$masked_data_src
  )
  tokenized_data_trg=(DoTokenize:
    yes=$trg@tokenize
    no=$masked_data_trg
  )
}

task tokenize : mosesdecoder tools sockeye_scripts
  < src_in=$masked_data_src
  < trg_in=$masked_data_trg
  > src
  > trg
  :: SRC=@ TRG=@
  :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  for lang in $SRC $TRG; do
    if [[ $lang == $SRC ]]; then
      get=$src_in
      put=$src
    else
      get=$trg_in
      put=$trg
    fi
    if [[ $lang == "zh" || $lang == "ja" || $lang == "ko" ]]; then
      cat $get | ${sockeye_scripts}/cjk/segment-cjk.py \
        | ${mosesdecoder}/scripts/tokenizer/normalize-punctuation.perl -l $lang \
        | ${mosesdecoder}/scripts/tokenizer/remove-non-printing-char.perl \
        | ${mosesdecoder}/scripts/tokenizer/tokenizer.perl -l $lang -no-escape -protected ${mosesdecoder}/scripts/tokenizer/basic-protected-patterns -q \
        > $put &
    else
      cat $get \
        | ${mosesdecoder}/scripts/tokenizer/normalize-punctuation.perl -l $lang \
        | ${mosesdecoder}/scripts/tokenizer/remove-non-printing-char.perl \
        | ${mosesdecoder}/scripts/tokenizer/tokenizer.perl -l $lang -no-escape -protected ${mosesdecoder}/scripts/tokenizer/basic-protected-patterns -q \
        > $put &
    fi
  done

  wait
}

# task characterize : tools
#     < in=$out@tokenize
#     > out
#     :: pyenv=@
#     :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

#   if [ ! -z $pyenv ] ; then
#     set +u
#     source $pyenv
#     set -u
#   fi

#   python $tools/characterize.py < $in > $out
# }
