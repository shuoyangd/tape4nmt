task train_bpe : subword_nmt
  < src_in=$tokenized_data[DataSection:train,side:src]
  < trg_in=$tokenized_data[DataSection:train,side:trg]
  > model="bpe.model"
  :: bpe_operations=@
  :: SRC=@
  :: TRG=@
  :: pyenv=@
  :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  subword-nmt learn-joint-bpe-and-vocab -i $src_in $trg_in -s $bpe_operations -o $model --write-vocabulary bpe.vocab.$SRC bpe.vocab.$TRG -v 2> log
}

task apply_bpe : subword_nmt
    # < in=$truecased_data
    < in=$tokenized_data
    < model=$model@train_bpe
    > out
    :: pyenv=@ {

  subword-nmt apply-bpe --codes $model --input $in --output $out
}

task train_sentencepiece : sentencepiece
  < src_in=$tokenized_data[DataSection:train,side:src]
  < trg_in=$tokenized_data[DataSection:train,side:trg]
  > model="sp.model"
  > vocab="sp.vocab"
  :: sentencepiece_vocab_size=@
  :: sentencepiece_model_type=@
  :: pyenv=@ {

  ${sentencepiece}/build/src/spm_train --input $src_in,$trg_in --model_prefix sp --vocab_size $sentencepiece_vocab_size --character_coverage 1.0 --model_type $sentencepiece_model_type
}

task apply_sentencepiece : sentencepiece
  < in=$tokenized_data
  < model=$model@train_sentencepiece
  > out 
  :: pyenv=@ {

  cat $in | ${sentencepiece}/build/src/spm_encode --model $model > $out
}
