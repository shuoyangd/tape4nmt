global {
  masked_data=(DoMasking:
    no=$raw_data
    yes=(side:
      src=$src_out@mask
      trg=$trg_out@mask
    )
  )
}

func dummy
    < in
    > out {
    
  ln -s $in $out
} 

task mask : sockeye_scripts tools
  :: masking_add_index=@
  :: masking_pattern_files=@
  < src_in=$raw_data[side:src]
  < trg_in=$raw_data[side:trg]
  > src_out
  > trg_out {

    paste $src_in $trg_in > in
    cmd="cat in | python $sockeye_scripts/masking/mask_terms.py --pattern_files $masking_pattern_files"

    if [ ! -z "$masking_add_index" ] ; then
      cmd=$cmd" --add-index"
    fi

    cmd=$cmd" > out"
    echo $cmd
    eval $cmd

    $tools/bin/unpaste $src_out $trg_out < out
}

task dummy_aggregate_mask calls dummy
    < in=$masked_data
    > out
