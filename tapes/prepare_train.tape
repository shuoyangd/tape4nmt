task train_clean : mosesdecoder
    < src_in=$out@download_or_link[DataSection:train,side:src]
    < trg_in=$out@download_or_link[DataSection:train,side:trg]
    > src_out
    > trg_out
    :: .submitter=$submitter .action_flags=$action_flags .resource_flags=$resource_flags
    :: SRC=@
    :: TRG=@
    :: Ratio=@
    :: MaxLen=@ {

  mkdir -p tmp
  filename=$(basename $src_in)
  cp $src_in tmp/$filename.$SRC
  cp $trg_in tmp/$filename.$TRG
  in=tmp/$filename

  $mosesdecoder/scripts/training/clean-corpus-n.perl $in $SRC $TRG $src_out $Ratio $MaxLen
  mv $src_out.$SRC $src_out
  mv $src_out.$TRG $trg_out
}

task train_sample : tools
    < src_in=$src_out@train_clean
    < trg_in=$trg_out@train_clean
    > src_out
    > trg_out
    :: train_sample_size=(TrainSampleSize: 100000 250000 500000 1000000 DontSample="") {

  linen=`wc -l $src_in | awk '{ print $1}'`
  if [ -z "$train_sample_size" ] || [[ "$train_sample_size" -ge "$linen" ]] ; then
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
