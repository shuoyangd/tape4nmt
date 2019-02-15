global {
  cleaned_data_src=$src@train_clean
  cleaned_data_trg=$trg@train_clean
}

task train_clean : mosesdecoder
    < src_in=$out@download_or_link[DataSection:train,side:src]
    < trg_in=$out@download_or_link[DataSection:train,side:trg]
    > src
    > trg
    :: SRC=@
    :: TRG=@
    :: train_clean_ratio=@
    :: train_maxlen=@
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags {

  ln -s $src_in corpus.$SRC
  ln -s $trg_in corpus.$TRG

  $mosesdecoder/scripts/training/clean-corpus-n.perl corpus $SRC $TRG cleaned $train_clean_ratio $train_maxlen

  mv cleaned.$SRC $src_out
  mv cleaned.$TRG $trg_out
}

task train_sample : tools
    < src_in=$src_out@train_clean
    < trg_in=$trg_out@train_clean
    > src_out
    > trg_out
    :: train_sample_size=(TrainSampleSize: DontSample="" 100000 250000 500000 1000000) {

  linen=`wc -l $src_in | awk '{ print $1}'`
  if [[ -z $train_sample_size ]] || [[ $train_sample_size -ge $linen ]] ; then
    tee < $src_in > $src_out
    tee < $trg_in > $trg_out
  else
    ln -s $src_in $PWD/src_in
    ln -s $trg_in $PWD/trg_in
    python $tools/random_parallel_sample.py $train_sample_size $PWD/src_in $PWD/trg_in
    mv $PWD/src_in.sample $src_out
    mv $PWD/trg_in.sample $trg_out
  fi
}
