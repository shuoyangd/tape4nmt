task fast_align : fast_align
  < src_in=$tokenized_data_src[DataSection:train]
  < trg_in=$tokenized_data_trg[DataSection:train]
  > forward_log="log.forward"
  > reverse_log="log.reverse"
  > forward_lexicon="lexicon.forward"
  > reverse_lexicon="lexicon.reverse"
  :: .submitter=$submitter
  :: .resource_flags=$resource_flags_16g
  :: .action_flags=@ {

  # Create the merged orpus needed for fast_align
  ln -s $src_in src
  ln -s $trg_in trg
  zpaste src trg | perl -ne 'if ($_ !~ /^\s*\t/ and $_ !~ /\t\s*$/) { s/\t/ ||| /; print }' > corpus

  # Run fast_align in both directions (or should we just do P(src | trg)?)
  ${fast_align}/build/fast_align -i corpus -v -d -o -p $forward_lexicon > /dev/null 2> $forward_log &
  ${fast_align}/build/fast_align -i corpus -v -d -o -p $reverse_lexicon -r > /dev/null 2> $reverse_log &

  wait
}
