task dev_text_from_sgm : mosesdecoder
    < src_in=$out@download_or_link[DataSection:devtest,DevtestDataSection:dev,side:src]
    < trg_in=$out@download_or_link[DataSection:devtest,DevtestDataSection:dev,side:trg]
    < wrap_template=$out@download_or_link[DataSection:devtest,DevtestDataSection:dev,side:src]
    > src_out
    > trg_out {

  $mosesdecoder/scripts/ems/support/input-from-sgm.perl < $src_in > $src_out
  $mosesdecoder/scripts/ems/support/reference-from-sgm.perl $trg_in $wrap_template $trg_out

  # if there are multi-reference, just use the first one
  if [ -f ${trg_out}.ref0 ] ; then
    mv ${trg_out}.ref0 $trg_out
  fi

  if [ -f ${trg_out}0 ] ; then
    mv ${trg_out}0 $trg_out
  fi
}

task test_text_from_sgm : mosesdecoder
    < src_in=$out@download_or_link[DataSection:devtest,DevtestDataSection:test,side:src]
    < trg_in=$out@download_or_link[DataSection:devtest,DevtestDataSection:test,side:trg]
    < wrap_template=$out@download_or_link[DataSection:devtest,DevtestDataSection:test,side:src]
    > src_out
    > trg_out {

  $mosesdecoder/scripts/ems/support/input-from-sgm.perl < $src_in > $src_out
  $mosesdecoder/scripts/ems/support/reference-from-sgm.perl $trg_in $wrap_template $trg_out

  refn=`ls $trg_out* | wc -l`
  if [ $refn -gt 1 ] ; then
    touch $trg_out # cheat
  fi
}
