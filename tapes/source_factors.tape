task compute_source_factors : sockeye_scripts
  < subword_in=$prepared_data
  < tok_in=$tokenized_data
  > factor_files="factors.txt"
  :: source_factors=@
  :: .submitter=shell {

  PYTHONPATH=${sockeye_scripts}

  rm -f $factor_files

  # compute each factor
  tmpfiles=""
  for factor in $source_factors; do
    # The final destination file
    outfile=$(pwd)/source_factors.$factor
    echo $outfile >> $factor_files

    # First write to tmpfile
    tmpfile=$(mktemp tmp.$factor.XXXXXX)
    tmpfiles+=" $tmpfile"
    python3 -m source_factors.compute $factor -i $tok_in -o $tmpfile
  done

  # combine them all
  paste $tmpfiles | python3 -m source_factors.broadcast | unpaste $(cat $factor_files)

  rm -f $tmpfiles
}
