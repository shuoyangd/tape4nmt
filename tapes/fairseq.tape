import "packages.tape"
import "submitters.tape"
import "versioners.tape"

# ==== pipeline starts here ====

# download all the data to the local directory
import "download.tape"

# perform masking on reserved symbols to improve consistency 
import "mask.tape"


# fast align for unmasking
import "fast_align.tape"

# tasks related to tokenize
import "tokenize.tape"

# tasks related to casing
import "recase.tape"

# tasks related to subword processing
import "subword.tape"

# TODO: source factors for fairseq?
# import "source_factors.tape"

# sacrebleu
import "bleu.tape"

# ==== pipeline ends here ====

# Nuts and bolts:
global {
  ducttape_experimental_packages=true
  ducttape_experimental_submitters=true
  ducttape_experimental_imports=true
  ducttape_experimental_multiproc=true
}

task binarize_data : fairseq
    < train_src_in=$prepared_data_src[DataSection:train]
    < train_trg_in=$prepared_data_trg[DataSection:train]
    < dev_src_in=$prepared_data_src[DataSection:dev]
    < dev_trg_in=$prepared_data_trg[DataSection:dev]
    > out
    :: pyenv=@
    # :: train_max_shard_size=@
    :: SRC=@
    :: TRG=@
    :: .submitter=$submitter
    :: .resource_flags=$resource_flags_16g
    :: .action_flags=@ {

  ln -s $train_src_in train.$SRC
  ln -s $train_trg_in train.$TRG
  ln -s $dev_src_in dev.$SRC
  ln -s $dev_trg_in dev.$TRG

  python $fairseq/preprocess.py --source-lang $SRC --target-lang $TRG \
    --trainpref train --validpref dev \
    --destdir $out

  if [ -f ${out}.train.1.pt ] ; then
    touch $out
  fi
}

task fairseq_train : fairseq
    < in=$out@binarize_data
    > out
    :: pyenv=@
    :: train_batch_size=@
    :: train_optim=@
    :: train_dropout=@
    :: train_adam_beta1=@
    :: train_adam_beta2=@
    :: train_lr=@
    :: train_lr_min=@
    :: train_lr_shrink=@
    :: train_lr_scheduler=@
    :: train_warmup_init_lr=@
    :: train_warmup_updates=@
    :: train_criterion=@
    :: train_label_smoothing=@
    :: train_clip_norm=@
    :: train_max_tokens=@
    # :: train_encoder_type=@
    :: train_arch=@
    :: train_share_input_output_embed=@
    :: train_skip_invalid_size_inputs_valid_test=@
    :: .submitter=sge
    :: .resource_flags=$resource_flags_train
    :: .action_flags=@ {

  cmd="python $fairseq/train.py $in --save-dir $out"
  cmd=$cmd" --lr $train_lr --clip-norm $train_clip_norm --dropout $train_dropout --max-tokens $train_max_tokens --arch $train_arch"

  if [ ! -z $train_optim ] ; then
    cmd=$cmd" --optimizer $train_optim"
  fi

  if [ ! -z $train_lr_min ] ; then
    cmd=$cmd" --min-lr $train_lr_min"
  fi

  if [ ! -z $train_lr_shrink ] ; then
    cmd=$cmd" --lr-shrink $train_lr_shrink"
  fi

  if [ ! -z $train_lr_scheduler ] ; then
    cmd=$cmd" --lr-scheduler $train_lr_scheduler"
  fi

  if [ ! -z $train_warmup_init_lr ] ; then
    cmd=$cmd" --warmup-init-lr $train_warmup_init_lr"
  fi

  if [ ! -z $train_warmup_updates ] ; then
    cmd=$cmd" --warmup-updates $train_warmup_updates"
  fi

  if [ ! -z $train_criterion ] ; then
    cmd=$cmd" --criterion $train_criterion"
  fi

  if [ ! -z $train_label_smoothing ] ; then
    cmd=$cmd" --label-smoothing $train_label_smoothing"
  fi

  if [ ! -z $train_max_tokens ] ; then
    cmd=$cmd" --max-tokens $train_max_tokens"
  fi

  if [ ! -z $train_adam_beta1 ] && [ ! -z $train_adam_beta2 ] ; then
    cmd=$cmd" --adam-betas '($train_adam_beta1, $train_adam_beta2)'"
  fi

  if [ ! -z $train_share_input_output_embed ] ; then
    cmd=$cmd" --share-input-output-embed"
  fi

  if [ ! -z $train_skip_invalid_size_inputs_valid_test ] ; then
    cmd=$cmd" --skip-invalid-size-inputs-valid-test"
  fi

  echo $cmd
  eval $cmd
}


# the target input here is used to compute naïve acc and ppl,
# that's why we need post-bpe target input
task decode : fairseq
    < in=$prepared_data_src[DataSection:test]
    < binarized_data_dir=$out@binarize_data
    < model=$out@fairseq_train
    > out
    :: test_max_sent_length=@
    :: test_beam_size=@
    :: test_batch_size=@
    :: test_remove_bpe=@
    :: SRC=@
    :: TRG=@
    :: .submitter=$submitter
    :: .action_flags=@
    :: .resource_flags=$resource_flags_decode
    :: pyenv=@ {

  # if [ $refn -eq 1 ]; then
  #   cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in -replace_unk -verbose -output $out -batch_size 1 -beam_size 12"
    # cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -verbose -output $out -batch_size $test_batch_size -beam_size $test_beam_size -max_sent_length $test_max_sent_length"
  # else
  #   cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in0 -replace_unk -verbose -output $out -batch_size 1 -beam_size 12"
    # cmd="python $fairseq/translate.py -gpu $device -model $model -src $src_in -verbose -output $out -batch_size $test_batch_size -beam_size $test_beam_size -max_sent_length $test_max_sent_length"
  # fi

  # if [ ! -z $test_replace_unk ]; then
  #   cmd=$cmd" -replace_unk"
  # fi

  cmd="python $fairseq/interactive.py --path $model/checkpoint_best.pt $binarized_data_dir --beam $test_beam_size --source-lang $SRC --target-lang $TRG"

  if [ ! -z $test_remove_bpe ] ; then
    cmd=$cmd" --remove-bpe"
  fi

  echo $cmd
  $cmd < $in > decode.log
  cat decode.log | grep ^H | cut -f3- > $out
}
