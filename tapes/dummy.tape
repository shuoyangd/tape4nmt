func dummy
    < in
    > out {

  ln -s $in $out
}

task dummy_aggregate_mask calls dummy
    < in=$masked_data
    > out
