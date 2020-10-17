# Tutorial

This tutorial guide you through the process of building a fairseq convolutional NMT system with tape4nmt.

### Install DuctTape

Installing [DuctTape](https://github.com/jhclark/ducttape) following their readme.

### Clone Workflow

Clone this repository to experiment folder of your choice.

### Add Dependencies

The workflow provided has the following general dependencies:

+ [tape4nmt-tools](https://github.com/shuoyangd/tape4nmt-tools): The must-have. Includes scripts that we use in some of our tasks.
+ [Moses](https://github.com/moses-smt/mosesdecoder): No need to compile -- we'll just be using scripts.
+ [sentencepiece](https://github.com/google/sentencepiece)

and for this tutorial we need a NMT toolkit. You will be pointed to my fork, as that is what we use to test this workflow:

+ [fairseq](https://github.com/shuoyangd/fairseq)

Good news: you are not supposed to manually install any of them, because DuctTape itself is designed to manage dependency packages for you! The workflow we provide already ships with the basic package setup procedures for you to walk through this tutorial, but you may have to make modifications to these procedures to cater your own special system requirements, so check out [packages.tape](https://github.com/shuoyangd/tape4nmt/blob/master/tapes/packages.tape) to get an idea of what it's doing and see if the configurations fit.

Note that we assume you have installed PyTorch though. We don't provide auto-setup in the workflow as it's a bit too platform-dependent. If you haven't started using PyTorch yet, please manually install it from [here](https://pytorch.org).

### Data Configuration

We'll be using IWSLT 2014 German-English data. Download it [here](https://wit3.fbk.eu/archive/2014-01/texts/de/en/de-en.tgz) and un-tar it somewhere in your system. Next, modify [data.tconf](https://github.com/shuoyangd/tape4nmt/blob/master/confs/data.tconf) to point the corresponding data items to your system location.

### Pipeline Configuration

We have a different entry point for each toolkit we support. Since we are using fairseq for this tutorial, we'll be working on [fairseq.tape](https://github.com/shuoyangd/tape4nmt/blob/master/fairseq.tape) and [fairseq.tconf](https://github.com/shuoyangd/tape4nmt/blob/master/fairseq.tconf). Usually you'll have to modify the top-level `.tape` to set up your experiment plan and `.tconf` to add system configurations. For this tutorial, we've made a good plan for you, so just check [fairseq.tconf](https://github.com/shuoyangd/tape4nmt/blob/master/fairseq.tconf) to make sure the submitter and conda/virtualenv settings matches your system.

### Run It

If you use conda or python virtualenv, please activate the environment now so that python packages could be installed in the selected environment.

Once you are ready, run:

```
ducttape main.tape -C main.tconf
```

You should see things spinnng up. The system build will take ~2hrs depending on your machine.

Now it's up to the machine to do the heavy-lifting. Time for a coffee!

### Get Result

When the pipeline finishes running, the result of your system build should reside in `multi_bleu/A44E370C238C2174FAB258249B03505A`. Here is what I got:

```
> cat bleu bleu_c
BLEU = 33.65, 66.8/41.1/27.2/18.2 (BP=0.986, ratio=0.986, hyp_len=86338, ref_len=87550)
BLEU = 32.87, 65.7/40.2/26.5/17.7 (BP=0.986, ratio=0.986, hyp_len=86338, ref_len=87550)
```

There is randomness here and there, but you should get roughtly the same result (<1 BLEU point difference).

### Checklist For Future Experiments

Here is a list of files and contents you need to check/modify for your future experiments:

+ `TOOLKIT.tape`: experiment plan
+ `TOOLKIT.tconf`: system-related configurations and toolkit-dependent parameters
+ `confs/data.tconf`: data locations
