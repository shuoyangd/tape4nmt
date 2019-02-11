global {
  dev_text=(SgmDev:
    no=$out@download_or_link[DevtestDataSection:dev]
    yes=(side: src=$src_out@dev_text_from_sgm trg=$trg_out@dev_text_from_sgm)
  )

  test_text=(SgmTest:
    no=$out@download_or_link[DevtestDataSection:test]
    yes=(side: src=$src_out@test_text_from_sgm trg=$trg_out@test_text_from_sgm)
  )

  src_truecaser=(UseExistingTruecaser:
    yes=""
    no=$out@train_truecaser[side:src]
  )
  trg_truecaser=(UseExistingTruecaser:
    yes=""
    no=$out@train_truecaser[side:trg]
  )

  merged_data=(MergeTest:
    no=(DataSection:
      train=$out@merge[DataSection:train]
      devtest=(DevtestDataSection:
        dev=$out@merge[DevtestDataSection:dev]
        test=$test_text
      )
    )
    yes=$out@merge
  )

  tokenized_data=(DoTokenize:
    yes=$out@tokenize
    no=(DataSection:
      train=$out@dummy_aggregate_merge[DataSection:train]
      devtest=(DevtestDataSection:
        dev=$out@dummy_aggregate_merge[DevtestDataSection:dev]
        test=$test_text
      )
    )
  )

  # don't do truecase when doing characterize
  # truecase will mess up the word boundary annotation
  truecased_data=(DoTruecase:
    yes=$out@truecase
    no=$tokenized_data
  )

  prepared_data=(SubwordMethod:
    sentencepiece=$out@apply_sentencepiece
    bpe=$out@apply_bpe
    none=$truecased_data
  )

  debped_output=(SubwordMethod:
    sentencepiece=$out@remove_sentencepiece
    bpe=$out@debpe
    none=$out@decode
  )

  # don't do truecase when doing characterize
  # truecase will mess up the word boundary annotation
  detruecased_output=(DoTruecase:
    yes=$out@detruecase
    no=$debped_output
  )

  detokenized_output=(DoTokenize:
    yes=$out@detokenize
    no=$detruecased_output
  )
}
