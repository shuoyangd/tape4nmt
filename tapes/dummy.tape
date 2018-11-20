func dummy
    < in
    > out {
    
  ln -s $in $out
}

task dummy_aggregate_dev_text calls dummy
    < in=$dev_text
    > out

task dummy_aggregate_test_text calls dummy
    < in=$test_text
    > out

task dummy_aggregate_merge calls dummy
    < in=$merged_data
    > out

task dummy_aggregate_tokenize calls dummy
    < in=$tokenized_data
    > out

task dummy_aggregate_truecase calls dummy
    < in=$truecased_data
    > out

task dummy_aggregate_subword calls dummy
    < in=$prepared_data
    > out
