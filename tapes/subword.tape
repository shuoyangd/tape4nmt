global {
  prepared_data_src=(SubwordMethod:
    sentencepiece=$src@apply_sentencepiece
    bpe=$src@apply_bpe
    none=$recased_data_src
  )
  prepared_data_trg=(SubwordMethod:
    sentencepiece=$trg@apply_sentencepiece
    bpe=$trg@apply_bpe
    none=$recased_data_trg
  )
}

task train_bpe : subword_nmt
  < src_in=$recased_data_src[DataSection:train]
  < trg_in=$recased_data_trg[DataSection:train]
  > model="bpe.model"
  :: bpe_operations=@
  :: SRC=@
  :: TRG=@
  :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags_16g {

  subword-nmt learn-joint-bpe-and-vocab -i $src_in $trg_in -s $bpe_operations -o $model --write-vocabulary bpe.vocab.$SRC bpe.vocab.$TRG -v 2> log
}

task apply_bpe : subword_nmt
  < src_in=$recased_data_src
  < trg_in=$recased_data_trg
  < model=$model@train_bpe
  < observed_masks=(DoMasking: no="/dev/null" yes=$masks@mask[DataSection:train])
  > src
  > trg
  :: masking=(DoMasking: no yes)
  :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags_16cpu {

  glossary_flag=""
  if [[ $observed_masks != "/dev/null" ]]; then
    glossary_flag="--glossaries '__[A-Za-z0-9]+(_\d+)?__'"
  fi

  echo "GLOSSARY FLAG: $glossary_flag"

  cat $src_in | parallel -j 10 -k --block-size 10k --pipe "subword-nmt apply-bpe --codes $model $glossary_flag" > $src
  cat $trg_in | parallel -j 10 -k --block-size 10k --pipe "subword-nmt apply-bpe --codes $model $glossary_flag" > $trg
}

task train_sentencepiece : sentencepiece
  < src_in=$recased_data_src[DataSection:train]
  < trg_in=$recased_data_trg[DataSection:train]
  < observed_masks=(DoMasking: no="/dev/null" yes=$masks@mask[DataSection:train])
  > model="sp.model"
  > vocab="sp.vocab"
  :: sentencepiece_vocab_size=@
  :: sentencepiece_model_type=@
  :: .submitter=$submitter
  :: .resource_flags=$resource_flags_16cpu
  :: .action_flags=@ {

  glossary_flag=""
  if [[ $observed_masks != "/dev/null" ]]; then
    glossary_flag="--user_defined_symbols $(cat $observed_masks)"
  fi  

  ${sentencepiece}/build/src/spm_train --input $src_in,$trg_in --model_prefix sp --vocab_size $sentencepiece_vocab_size $glossary_flag --character_coverage 1.0 --model_type $sentencepiece_model_type
}

task apply_sentencepiece : sentencepiece
  < src_in=$recased_data_src
  < trg_in=$recased_data_trg
  < model=$model@train_sentencepiece
  > src
  > trg
  :: sentencepiece_alpha=@ {

  cat $src_in | ${sentencepiece}/build/src/spm_encode --model $model --output_format sample_piece --alpha $sentencepiece_alpha > $src &
  cat $trg_in | ${sentencepiece}/build/src/spm_encode --model $model --output_format sample_piece --alpha $sentencepiece_alpha > $trg &
  wait
}
