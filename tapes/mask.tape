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
  > masks
  :: section=(DataSection: train dev test)
  :: masking_add_index=@
  :: masking_dict_files=@
  :: masking_pattern_files=@ {

  # This always masks in parallel, but note that this is used
  # only for train and dev, since test is recomputed via the packaged
  # model. For dev, we mask in parallel since validation scores work
  # on the raw data anyway.

  cmd="python3 $sockeye_scripts/masking/mask_terms.py"
  if [[ $masking_pattern_files != "/dev/null" ]]; then
    cmd+=" --pattern-files $masking_pattern_files"
  fi

  if [[ $masking_dict_files != "/dev/null" ]]; then
    cmd+=" --dict-files $masking_dict_files"
  fi

  if [[ $masking_add_index == "yes" ]]; then
    cmd+=" --add-index"
  fi

  # for non-training, $trg will be a file full of blank lines
  paste $src_in $trg_in | $cmd | $tools/bin/unpaste $src $trg

  # write the set of observed masks
  cat $src $trg | perl -pe 's/ /\n/g' | perl -ne 'if (/^__[A-Z0-9]+(_\d+)?__$/) { print }' > $masks
}
