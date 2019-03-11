task fast_align : fast_align
    < src_in=$tokenized_data_src[DataSection]
    < trg_in=$tokenized_data_trg[DataSection:train]
    > forward_log="log.forward"
    > reverse_log="log.reverse"
    > forward_lexicon="lexicon.forward"
    > reverse_lexicon="lexicon.reverse"
    :: .submitter=$submitter
    :: .resource_flags=$resource_flags_16g
    :: .action_flags=@ {

  # Create the merged orpus needed for fast_align
  zpaste $src_in $trg_in | perl -pe 's/\t/ ||| /g' > corpus

  # Run fast_align in both directions (or should we just do P(src | trg)?)
  ${fast_align}/build/src/fast_align -i corpus -v -d -o -p $forward_lexicon 2> $forward_log | gzip -9n > alignments.forward.gz
  ${fast_align}/build/src/fast_align -i corpus -v -d -o -r -p $reverse_lexicon 2> $reverse_log | gzip -9n > alignments.reverse.gz

  # Merge the alignments
  paste corpus | ${fast_align}/src/force_align.py lexicon.forward log.forward lexicon.reverse log.reverse
}
