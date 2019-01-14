# Tutorial

This tutorial guide you through the process of building a fairseq convolutional NMT system with tape4nmt.

### Install DuctTape

Installing [DuctTape](https://github.com/jhclark/ducttape) following their readme.

### Clone Workflow

Clone this repository to your experiment folder of your choice.

### Add Dependencies

The workflow provided has the following general dependencies:

+ [tape4nmt-tools](https://github.com/shuoyangd/tape4nmt-tools): The must-have. Includes scripts that we use in some of our tasks.
+ [Moses](https://github.com/moses-smt/mosesdecoder): No need to compile -- we'll just be using scripts.
+ [pytorch](https://github.com/pytorch/pytorch)
+ [subword-nmt](https://github.com/rsennrich/subword-nmt)

Good news: you are not supposed to manually install any of them, because DuctTape itself is designed to manage dependency packages for you! The workflow we provide already ships with the basic package setup procedures for you to walk through this tutorial, but you may have to make modifications to these procedures to cater your own special system requirements, so check out [packages.tape](https://github.com/shuoyangd/tape4nmt/blob/master/tapes/packages.tape) to get an idea of what it's doing and see if the configurations fit. Especially, if you are using virtualenv, you'll have to fill out your virtual environment directories there.

### Data Configuration

We'll be using IWSLT 2014 German-English data. Download it [here](https://wit3.fbk.eu/archive/2014-01/texts/de/en/de-en.tgz) and un-tar it somewhere in your system. Next, modify [data.tconf](https://github.com/shuoyangd/tape4nmt/blob/master/confs/data.tconf) to point the corresponding data items to your system location.

### Pipeline Configuration

Usually you'll have to modify [main.tape](https://github.com/shuoyangd/tape4nmt/blob/master/main.tape) to set up your experiment plan and [main.tconf](https://github.com/shuoyangd/tape4nmt/blob/master/main.tconf) to do some system configurations. For this tutorial, we've made a good plan for you, so just modify the submitter and the virtualenv section of `main.tconf` to your system configurations.

### Run It

Once you are ready, run:

```
./run sockeye sockeye.tconf -p transformer -j 10
```

This will run ducttape using Sockeye with the plans defined in sockeye.tconf, executing the "transformer" plan with 10 tasks allowed at a time.

You should see things spinnng up. The system build will take ~2hrs depending on your machine.

Now it's up to the machine to do the heavy-lifting. Time for a coffee!

### Get Result

When the pipeline finishes running, the result of your system build should reside in `multi-bleu/Architecture.fconv_iwslt_de_en+ClipNorm.0.1+TrainSampleSize.DontSample+UseExistingTruecaser.no`. Here is what I got:

```
> cat bleu bleu_c
BLEU = 30.49, 64.2/37.9/24.3/15.9 (BP=0.979, ratio=0.979, hyp_len=85741, ref_len=87550)
BLEU = 29.78, 63.1/37.1/23.7/15.4 (BP=0.979, ratio=0.979, hyp_len=85741, ref_len=87550)
```

There is randomness here and there, but you should get roughtly the same result (<1 BLEU point difference).
