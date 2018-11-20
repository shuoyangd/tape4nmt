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

# do not support merge for the moment
task wrap_xml : mosesdecoder
    < in=$detokenized_output
    < wrap_template=$out@download_or_link[DevtestDataSection:test,side:src]
    > out
    :: trg_lang=@
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/ems/support/wrap-xml.perl $trg_lang $wrap_template < $in > $out
}
