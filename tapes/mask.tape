global {
  masked_data_src=(DoMasking:
    no=$raw_data_src
    yes=$src@mask
  )
  masked_data_trg=(DoMasking:
    no=$raw_data_trg
    yes=$trg@mask
  )
}

task mask : sockeye_scripts tools
  < src_in=$raw_data_src
  < trg_in=$raw_data_trg
  > src
  > trg
  :: section=(DataSection: train dev test)
  :: masking_add_index=@
  :: masking_pattern_files=@ {

  if [[ $section == "train" ]]; then
    paste $src_in $trg_in > in
  else
    ln -s $src_in in
  fi

  cmd="cat in | python $sockeye_scripts/masking/mask_terms.py --pattern_files $masking_pattern_files"

  if [[ $masking_add_index -eq "yes" ]]; then
    cmd+=" --add-index"
  fi

  $cmd | $tools/bin/unpaste $src $trg

  rm -f $in
}
