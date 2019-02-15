global {

  debped_output=(SubwordMethod:
    sentencepiece=$out@remove_sentencepiece
    bpe=$out@debpe
    none=$out@decode
  )

  # don't do truecase when doing characterize
  # truecase will mess up the word boundary annotation
  detruecased_output=(Casing:
    actual=$debped_output
    true=$out@detruecase
    lower_source=$debped_output
  )

  detokenized_output=(DoTokenize:
    yes=$out@detokenize
    no=$detruecased_output
  )

  demasked_output=(DoMasking:
    no=$out@detokenize
    yes=$out@demask
  )
}

task debpe
    < in=$out@decode
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  cat $in | sed -r 's/\@\@ //g' > $out
}

task remove_sentencepiece
  < in=$out@decode
  < model=$model@train_sentencepiece
  > out
  :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  cat $in | spm_decode --model $model > $out
}

task detruecase : mosesdecoder
    < in=$debped_output
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/recaser/detruecase.perl < $in > $out
}

task detokenize : mosesdecoder
    < in=$detruecased_output
    > out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/tokenizer/detokenizer.perl < $in > $out
}

task decharacterize : tools
    < in=$out@detokenize
    > out
    :: pyenv=@
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  if [ ! -z $pyenv ] ; then
    set +u
    source $pyenv
    set -u
  fi

  python $tools/decharacterize.py < $in > $out
}

task demask : sockeye_scripts tools
    < sys_in=$detokenized_output
    < orig_src=$raw_data_src[DataSection:test]
    < mask_src=$masked_data_src[DataSection:test]
    > out {

    paste $sys_in $orig_src $mask_src > in
    python $sockeye_scripts/masking/mask_terms.py -u < in > $out
}
