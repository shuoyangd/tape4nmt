# do not support merge for the moment
# as that will involve creating a wrap template for merged xml
task nist_bleu : mosesdecoder
    < in=$out@wrap_xml
    < wrap_template=$out@download_or_link[DevtestDataSection:test,side:src]
    < ref=$out@dummy_aggregate_merge[DevtestDataSection:test,side:trg]
    > bleu
    > bleu_c
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/generic/mteval-v13a.pl -s $wrap_template -r $ref -t $in > $bleu
  $mosesdecoder/scripts/generic/mteval-v13a.pl -c -s $wrap_template -r $ref -t $in > $bleu_c
}

task multi_bleu : mosesdecoder
    < in=$detokenized_output
    < ref=$out@dummy_aggregate_merge[DataSection:devtest,DevtestDataSection:test,side:trg]
    > bleu
    > bleu_c
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  refn=`ls $ref* | wc -l`
  if [ $refn -gt 1 ] ; then
    mv $ref ${ref}.tmp # get rid of dummy single reference
  fi

  $mosesdecoder/scripts/generic/multi-bleu-detok.perl $ref < $in > $bleu_c
  $mosesdecoder/scripts/generic/multi-bleu-detok.perl -lc $ref < $in > $bleu

  if [ $refn -gt 1 ] ; then
    mv ${ref}.tmp $ref
  fi
}

task sacrebleu : sacrebleu
    < in=$detokenized_output
    < ref=$out@dummy_aggregate_merge[DataSection:devtest,DevtestDataSection:test,side:trg]
    > bleu
    > signature
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags
    :: pyenv=@ {

  cat $in | sacrebleu $ref | cut -d' ' -f1 > $signature
  cat $in | sacrebleu $ref -b > $bleu
}
