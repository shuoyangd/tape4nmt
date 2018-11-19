task train_bpe : subword_nmt
      < src_in=$out@dummy_aggregate_truecase[DataSection:train,side:src]  # FIXME
      < trg_in=$out@dummy_aggregate_truecase[DataSection:train,side:trg]  # FIXME
      > out
      :: bpe_operations=@
      :: SRC=@
      :: TRG=@
      :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  subword-nmt learn-joint-bpe-and-vocab -i $src_in $trg_in -s $bpe_operations -o $out -v
}

task apply_bpe : subword_nmt
    # < in=$truecased_data
    < in=$out@dummy_aggregate_truecase
    < model=$out@train_bpe
    > out {

  subword-nmt apply-bpe -c $model
  $subword_nmt/apply_bpe.py -c $model -i $in -o $out
}

task train_sentencepiece : sentencepiece
  < src_in=$out@dummy_aggregate_merge[DataSection:train,side:src]
  < trg_in=$out@dummy_aggregate_merge[DataSection:train,side:trg]
  > model="sp.model"
  > vocab="sp.vocab"
  :: sentencepiece_vocab_size=@
  :: sentencepiece_model_type=@
{
  spm_train --input=$src_in,$trg_in --model_prefix=sp --vocab_size=$sentencepiece_vocab_size --character_coverage=1.0 --model_type=$sentencepiece_model_type
}

task apply_sentencepiece : sentencepiece
  < in=$out@dummy_aggregate_truecase
  < model=$model@train_sentencepiece
  > out
{
  cat $in spm_encode --model=$model > $out
}
