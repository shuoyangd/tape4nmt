task merge
    < in=(DataSection:
            train=(side:
              src=$src_out@train_sample[TrainDataSource:*]
              trg=$trg_out@train_sample[TrainDataSource:*]
            )
            devtest=(DevtestDataSection:
              dev=$out@dummy_aggregate_dev_text[DevDataSource:*]
              test=$out@dummy_aggregate_test_text[TestDataSource:*]
            )
         )
    > out {

  for file in $in ; do
    cat $file >> $out
  done
}
