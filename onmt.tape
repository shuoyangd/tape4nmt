package onmt
    :: .versioner=git .repo="https://github.com/OpenNMT/OpenNMT-py" .ref=HEAD
    :: realref="refs/remotes/origin/master" {

  git checkout -b working $realref
}

package subword_nmt :: .versioner=disk .path="/home/shuoyangd/nmt/subword-nmt" {

}

package mosesdecoder :: .versioner=disk .path="/export/b11/shuoyangd/mosesstd" {

}

package stanford_seg :: .versioner=disk .path="/home/shuoyangd/stanford-seg" {

}

package fasttext :: .versioner=disk .path="/export/b18/shuoyangd/projects/nmt-source-mono/fastText" {

}

task dev_text_from_sgm : mosesdecoder
    < src_in=$dev_data[side:src]
    < trg_in=$dev_data[side:trg]
    < wrap_template=$wrap_template
    > src_out
    > trg_out
    :: sgm_dev=@ {

  if [ ! -z $sgm_dev ] ; then
    $mosesdecoder/scripts/ems/support/input-from-sgm.perl < $src_in > $src_out
  else
    cp $src_in $src_out
  fi

  if [ ! -z $sgm_dev ] ; then
    $mosesdecoder/scripts/ems/support/reference-from-sgm.perl $trg_in $wrap_template $trg_out
  else
    cp $trg_in $trg_out
  fi

  if [ -f ${trg_out}.ref0 ] ; then
    mv ${trg_out}.ref0 $trg_out
  fi

  if [ -f ${trg_out}0 ] ; then
    mv ${trg_out}0 $trg_out
  fi
}

task devtest_text_from_sgm : mosesdecoder
    < src_in=$devtest_data[side:src]
    < trg_in=$devtest_data[side:trg]
    < wrap_template=$wrap_template
    > src_out
    > trg_out
    :: sgm_devtest=@ {

  if [ ! -z $sgm_devtest ] ; then
    $mosesdecoder/scripts/ems/support/input-from-sgm.perl < $src_in > $src_out
  else
    cp $src_in $src_out
  fi

  if [ ! -z $sgm_devtest ] ; then
    $mosesdecoder/scripts/ems/support/reference-from-sgm.perl $trg_in $wrap_template $trg_out
  else
    cp $src_in $src_out
  fi

  refn=`ls $trg_out* | wc -l`
  if [ $refn -gt 1 ] ; then
    touch $trg_out # cheat
  fi
}

task train_tokenize : stanford_seg mosesdecoder
    < in=$train_data
    > out
    :: working_dir=@ 
    :: njobs=@ 
    :: resource_flags=$resource_flags
    :: SRC=@
    :: TRG=@ {

  filename=`basename $in`
  # Lang=`echo $filename | awk -F . '{print $NF}'`
  if [ $filename == "src_out" ] ; then
    Lang=$SRC
  else
    Lang=$TRG
  fi

  # segmentation for chinese
  if [ $Lang == "zh" ] || [ $Lang == "chn" ] || [ $Lang == "cn" ] ; then

    mkdir -p $PWD/tmp
    $mosesdecoder/scripts/ems/support/generic-parallelizer.perl --queue-flags "$resource_flags" \
        -in $in -out $out \
        -cmd "$stanford_seg/segmentstd.sh $stanford_seg/segment.sh $PWD/tmp ctb UTF-8 0 < %s | $mosesdecoder/scripts/tokenizer/escape-special-chars.perl | $working_dir/chinese-punctuations-utf8.perl > %s" \
        -jobs $njobs -tmpdir $PWD/tmp

    rm -r $PWD/tmp

  else

    mkdir -p $PWD/tmp
    $mosesdecoder/scripts/ems/support/generic-parallelizer.perl --queue-flags "$resource_flags" \
        -in $in -out $out \
        -cmd "$mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $Lang < %s | $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $Lang > %s" \
        -jobs $njobs -tmpdir $PWD/tmp

    rm -r $PWD/tmp
  fi
}

task dev_tokenize : stanford_seg mosesdecoder
    < in=(side: src=$src_out@dev_text_from_sgm trg=$trg_out@dev_text_from_sgm)
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
    :: working_dir=@
    :: SRC=@ 
    :: TRG=@ {

  side=`pwd | rev | cut -d "/" -f 1 | rev`
  is_src=`echo $side | grep -o "baseline"``echo $side | grep -o "side.src" $side`
  is_trg=`echo $side | grep -o "side.trg"`
  if [ ! -z $is_src ] ; then
    Lang=$SRC
  fi
  if [ ! -z $is_trg ] ; then
    Lang=$TRG
  fi

  # segmentation for chinese
  if [ $Lang == "zh" ] || [ $Lang == "chn" ] || [ $Lang == "cn" ] ; then

    mkdir -p $PWD/tmp
    $stanford_seg/segmentstd.sh $stanford_seg/segment.sh $PWD/tmp ctb UTF-8 0 < $in | $mosesdecoder/scripts/tokenizer/escape-special-chars.perl | $working_dir/chinese-punctuations-utf8.perl > $out
    rm -r $PWD/tmp

  else

    mkdir -p $PWD/tmp
    $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $Lang < $in | $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $Lang > $out

    rm -r $PWD/tmp
  fi
}

task devtest_tokenize : stanford_seg mosesdecoder
    < in=(side: src=$src_out@devtest_text_from_sgm trg=$trg_out@devtest_text_from_sgm)
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
    :: working_dir=@
    :: SRC=@
    :: TRG=@ {

  side=`pwd | rev | cut -d "/" -f 1 | rev`
  is_src=`echo $side | grep -o "baseline"``echo $side | grep -o "side.src" $side`
  is_trg=`echo $side | grep -o "side.trg"`
  if [ ! -z $is_src ] ; then
    Lang=$SRC
  fi
  if [ ! -z $is_trg ] ; then
    Lang=$TRG
  fi

  refn=`ls $in* | wc -l`
  echo "$refn"

  # single reference
  if [ $refn -eq 1 ] ; then
  
    # segmentation for chinese
    if [ $Lang == "zh" ] || [ $Lang == "chn" ] || [ $Lang == "cn" ] ; then
  
      mkdir -p $PWD/tmp
      $stanford_seg/segmentstd.sh $stanford_seg/segment.sh $PWD/tmp ctb UTF-8 0 < $in | $mosesdecoder/scripts/tokenizer/escape-special-chars.perl | $working_dir/chinese-punctuations-utf8.perl > $out
      rm -r $PWD/tmp
  
    else
  
      mkdir -p $PWD/tmp
      $mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $Lang < $in | $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $Lang > $out
  
      rm -r $PWD/tmp
    fi

  # multiple reference
  else

    rm $in # get rid of cheating file

    # segmentation for chinese
    if [ $Lang == "zh" ] || [ $Lang == "chn" ] || [ $Lang == "cn" ] ; then
  
      mkdir -p $PWD/tmp
      $mosesdecoder/scripts/ems/support/run-command-on-multiple-refsets.perl "$stanford_seg/segmentstd.sh $stanford_seg/segment.sh $PWD/tmp ctb UTF-8 0 < mref-input-file| $mosesdecoder/scripts/tokenizer/escape-special-chars.perl | $working_dir/chinese-punctuations-utf8.perl > mref-output-file" $in $out
      rm -r $PWD/tmp
  
    else
  
      mkdir -p $PWD/tmp
      $mosesdecoder/scripts/ems/support/run-command-on-multiple-refsets.perl "$mosesdecoder/scripts/tokenizer/normalize-punctuation.perl -l $Lang < mref-input-file | $mosesdecoder/scripts/tokenizer/tokenizer.perl -a -l $Lang > mref-output-file" $in $out
  
      rm -r $PWD/tmp
    fi

    touch $in # recover cheat
    touch $out # cheat
    
  fi
}

task clean : mosesdecoder
    < src_in=$out@train_tokenize[side:src]
    < trg_in=$out@train_tokenize[side:trg]
    > src_out
    > trg_out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
    :: SRC=@
    :: TRG=@
    :: Ratio=@
    :: MaxLen=@ {

  mkdir -p tmp
  filename=`basename $src_in`
  cp $src_in tmp/$filename.$SRC
  cp $trg_in tmp/$filename.$TRG
  in=tmp/$filename

  $mosesdecoder/scripts/training/clean-corpus-n.perl $in $SRC $TRG $src_out $Ratio $MaxLen
  mv $src_out.$SRC $src_out
  mv $src_out.$TRG $trg_out
}

task train_truecaser : mosesdecoder
    < in=(side: src=$src_out@clean trg=$trg_out@clean)
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/recaser/train-truecaser.perl -corpus $in $out -model $out
}

task truecase : mosesdecoder
    < in=(DataSection: train=(side: src=$src_out@clean trg=$trg_out@clean) dev=$out@dev_tokenize devtest=$out@devtest_tokenize)
    < model=$out@train_truecaser
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags {

  $mosesdecoder/scripts/recaser/truecase.perl -model $model < $in > $out
}

# task train_bpe : subword_nmt
#     < src_in=$out@truecase[DataSection:train,side:src]
#     < trg_in=$out@truecase[DataSection:train,side:trg]
#     > out 
#     :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
#     :: bpe_operations=@
#     :: SRC=@ 
#     :: TRG=@ {
# 
#   cat $src_in $trg_in | $subword_nmt/learn_bpe.py -s $bpe_operations > $out
# }

task train_bpe : subword_nmt
      < src_in=$out@truecase[DataSection:train,side:src]
      < trg_in=$out@truecase[DataSection:train,side:trg]
      > out
      :: .submitter="sge" .action_flags=$action_flags .resource_flags="-l 'mem_free=16g,ram_free=16g'"
      :: bpe_operations=@
      :: SRC=@ 
      :: TRG=@ {

  cat $src_in $trg_in | $subword_nmt/learn_bpe.py -s $bpe_operations > $out
}

task apply_bpe : subword_nmt
    < in=$out@truecase
    < model=$out@train_bpe
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags {

  $subword_nmt/apply_bpe.py -c $model < $in > $out
}

task binarize_data : onmt
    < train_src_in=$out@apply_bpe[DataSection:train,side:src]
    < train_trg_in=$out@apply_bpe[DataSection:train,side:trg]
    < dev_src_in=$out@apply_bpe[DataSection:dev]
    < dev_trg_in=$out@apply_bpe[DataSection:dev,side:trg]
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags="-l 'mem_free=24g,ram_free=24g'" {

  source /home/shuoyangd/pyenv/py3/bin/activate
  python $onmt/preprocess.py -train_src $train_src_in -train_tgt $train_trg_in -valid_src $dev_src_in -valid_tgt $dev_trg_in -save_data $out 

  if [ -f ${out}.train.pt ] ; then
    touch $out
  fi
}

task train : onmt
    < in=$out@binarize_data
    > out
    :: .submitter="sge" 
    :: .action_flags="-m ae -M dings@jhu.edu -q g.q"
    :: .resource_flags="-l 'hostname=c*,gpu=1,mem_free=12g,ram_free=12g'"
    :: train_train_from=@
    :: train_train_from_state_dict=@
    :: train_start_epoch=@
    :: train_layers=@
    :: train_rnn_size=@
    :: train_word_vec_size=@
    :: train_batch_size=@
    :: train_epochs=@
    :: train_optim=@
    :: train_dropout=@
    :: train_learning_rate=@
    :: train_encoder_type=@ {

  source /home/shuoyangd/pyenv/py3/bin/activate
  export n_gpus=`lspci | grep -i "nvidia" | wc -l`
  export device=`nvidia-smi | sed -e '1,/Processes/d' | tail -n+3 | head -n-1 | perl -ne 'next unless /^\|\s+(\d)\s+\d+/; $a{$1}++; for(my $i=0;$i<$ENV{"n_gpus"};$i++) { if (!defined($a{$i})) { print $i."\n"; last; }}' | tail -n 1`
  echo "gpu$device at "`hostname`
  if [ -z $device ] ; then
    echo "no device! grid cheaaaaaaaaaatin!"
    exit;
  fi
  
  cmd="python $onmt/train.py -data $in -save_model $out -gpuid $device"
  
  if [ ! -z $train_train_from ] ; then
    cmd=$cmd" -train_from $train_from"
  fi
  
  if [ ! -z $train_train_from_state_dict ] ; then
    cmd=$cmd" -train_from $train_from_state_dict"
  fi
  
  if [ ! -z $train_start_epoch ] ; then
    cmd=$cmd" -start_epoch $start_epoch"
  fi
  
  if [ ! -z $train_brnn ] ; then
    cmd=$cmd" -brnn" 
  fi
  
  if [ ! -z $train_encoder_type ] ; then
    cmd=$cmd" -encoder_type $train_encoder_type"
  fi
  
  cmd=$cmd" -layers $train_layers -rnn_size $train_rnn_size -word_vec_size $train_word_vec_size -batch_size $train_batch_size -epochs $train_epochs -optim $train_optim -dropout $train_dropout -learning_rate $train_learning_rate"
  echo $cmd
  $cmd

  models=`ls ${out}_* 2>/dev/null`
  if [ ! -z "$models" ] ; then
    touch $out # cheat
  fi
}

task model_selection
    < in=$out@train
    > out
    :: test_model_selection_strategy=@ {

  touch list
  for dump in `ls ${in}_*`; do
    echo $dump
    acc=`basename $dump | grep -Eo "acc_[0-9\.]+" | grep -Eo "[0-9\.]+"`
    ppl=`basename $dump | grep -Eo "ppl_[0-9\.]+" | grep -Eo "[0-9\.]+"`
    epc=`basename $dump | grep -Eo "e[0-9]+" | grep -Eo "[0-9]+"`
    if [ "$test_model_selection_strategy" == "acc" ] ; then
      echo $acc >> list
    fi
    if [ "$test_model_selection_strategy" == "ppl" ] ; then
      echo $ppl >> list
    fi
  done


  if [ "$test_model_selection_strategy" == "acc" ] ; then
    best_crit=`sort -g list | tail -1`
    echo $best_crit
    best=`ls ${in}_* | grep acc_${best_crit} | tail -1`
  fi
  if [ "$test_model_selection_strategy" == "ppl" ] ; then
    best_crit=`sort -g list | head -1`
    echo $best_crit
    best=`ls ${in}_* | grep ppl_${best_crit} | tail -1`
  fi

  if [ ! -z $best ] ; then
    echo "$best is selected as the best model according to strategy: $test_model_selection_strategy"
    cp $best $out
  else
    echo "unsupported strategy $test_model_selection_strategy detected"
  fi

  rm list
}

# the target input here is used to compute naïve acc and ppl,
# that's why we need post-bpe target input
task decode : onmt
    < src_in=$out@apply_bpe[DataSection:devtest]
    < trg_in=$out@apply_bpe[DataSection:devtest,side:trg]
    < model=$out@model_selection
    > out
    :: .submitter="sge" 
    :: .action_flags="-m ae -M dings@jhu.edu -q g.q"
    :: .resource_flags="-l 'hostname=c*,gpu=1'" {

  source /home/shuoyangd/pyenv/py3/bin/activate
  export n_gpus=`lspci | grep -i "nvidia" | wc -l`
  export device=`nvidia-smi | sed -e '1,/Processes/d' | tail -n+3 | head -n-1 | perl -ne 'next unless /^\|\s+(\d)\s+\d+/; $a{$1}++; for(my $i=0;$i<$ENV{"n_gpus"};$i++) { if (!defined($a{$i})) { print $i."\n"; last; }}' | tail -n 1`
  echo $device
  refn=`ls $trg_in* | wc -l`

  if [ $refn -eq 1 ]; then
#     python $onmt/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in -replace_unk -verbose -output $out
    python $onmt/translate.py -gpu $device -model $model -src $src_in -replace_unk -verbose -output $out -batch_size 1 -beam_size 12
  else
#     python $onmt/translate.py -gpu $device -model $model -src $src_in -tgt $trg_in0 -replace_unk -verbose -output $out
    python $onmt/translate.py -gpu $device -model $model -src $src_in -replace_unk -verbose -output $out -batch_size 1 -beam_size 12
  fi
}

task debpe 
    < in=$out@decode
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
    :: working_dir=@ {

  cat $in | sed -r 's/\@\@ //g' > $out
}

task detruecase : mosesdecoder 
    < in=$out@debpe
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
    :: working_dir=@ {

  $mosesdecoder/scripts/recaser/detruecase.perl < $in > $out
}

task detokenize : mosesdecoder
    < in=$out@detruecase
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
    :: working_dir=@ 
    :: TRG=@ {

  $mosesdecoder/scripts/tokenizer/detokenizer.perl < $in > $out
}

task wrap_xml : mosesdecoder
    < in=$out@detokenize
    < wrap_template=$wrap_template
    > out
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags
    :: trg_lang=@ {

  $mosesdecoder/scripts/ems/support/wrap-xml.perl $trg_lang $wrap_template < $in > $out
}

task nist_bleu : mosesdecoder
    < in=$out@wrap_xml
    < wrap_template=$wrap_template
    < ref=$devtest_data[side:trg]
    > bleu
    > bleu_c
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags {


  $mosesdecoder/scripts/generic/mteval-v13a.pl -s $wrap_template -r $ref -t $in > $bleu
  $mosesdecoder/scripts/generic/mteval-v13a.pl -c -s $wrap_template -r $ref -t $in > $bleu_c
}

task multi_bleu : mosesdecoder
    < in=$out@detruecase
    < ref=$out@devtest_tokenize[side:trg]
    > bleu
    > bleu_c 
    :: .submitter="sge" .action_flags=$action_flags .resource_flags=$resource_flags {

  refn=`ls $ref* | wc -l`
  if [ $refn -gt 1 ] ; then 
    rm $ref # get rid of cheat
  fi

  $mosesdecoder/scripts/generic/multi-bleu.perl $ref < $in > $bleu_c
  $mosesdecoder/scripts/generic/multi-bleu.perl -lc $ref < $in > $bleu

  if [ $refn -gt 1 ] ; then 
    touch $ref
  fi
}

# COMMANDS: the bash commands from some task
# TASK, REALIZATION, CONFIGURATION: variables passed by ducttape
submitter sge :: action_flags
              :: COMMANDS
              :: TASK REALIZATION TASK_VARIABLES CONFIGURATION {
  action run {
    wrapper="ducttape_job.sh"
    echo "#$ $resource_flags" >> $wrapper
    echo "#$ $action_flags" >> $wrapper
    echo "#$ -j y" >> $wrapper
    echo "#$ -o localhost:$PWD/job.out" >> $wrapper
    echo "#$ -N $CONFIGURATION-$TASK-$REALIZATION" >> $wrapper

    # Bash flags aren't necessarily passed into the scheduler
    # so we must re-initialize them

    # these two doesn't work well with virtualenv ...
    # echo "set -e # stop on errors" >> $wrapper
    # echo "set -u # stop on undeclared variables" >> $wrapper


    echo "set -o pipefail # stop on pipeline errors" >> $wrapper
    echo "set -x # show each command as it is executed" >> $wrapper
    echo "$TASK_VARIABLES" | grep -v "resource_flags" | grep -v "action_flags" >> $wrapper

    # The current working directory will also be changed by most schedulers
    echo "cd $PWD" >> $wrapper

    echo "$COMMANDS" >> $wrapper

    # Use SGE's -sync option to prevent qsub from immediately returning
    qsub -sync y $wrapper
  }
}

versioner git :: repo ref {
  action checkout > dir {
    git clone $repo $dir
  }
  action repo_version > version {
    git ls-remote $repo $ref | cut -f1 > $version
  }
  # Used to confirm version after checkout
  action local_version > version date {
    git rev-parse HEAD > $version
    git log -1 | awk '/^Date/{$1=""; print}' > $date
  }
}

plan test {
  reach nist_bleu, multi_bleu
}

# Nuts and bolts:
global {
  ducttape_experimental_packages=true
  ducttape_experimental_submitters="true"
  ducttape_experimental_imports="true"
  ducttape_experimental_multiproc=true
}

