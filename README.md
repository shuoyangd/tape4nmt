# tape4nmt

### What is that?

`tape4nmt` is a [`DuctTape`](https://github.com/jhclark/ducttape) workflow created for running NMT experiments. It currently supports [OpenNMT-py](https://github.com/OpenNMT/OpenNMT-py) but should be able to adapt to other frameworks with relatively modest amount of modifications.

[`DuctTape`](https://github.com/jhclark/ducttape) is a workflow management system written by Jonathon Clark. If you are writing bash scripts to run experiments, you may want to consider using `DuctTape` instead. It organizes your experiment script such that:

1.  you are much less likely to do stupid things by e.g. deleting your best model by accident, use the wrong data for the experiment, the list goes on;
2.  you can easily run, delete, and/or re-run batch experiments, re-using any partial results possible, with correctness guarantee;
3.  you can easily re-use part of your modularized experiment script (called "workflow") to create new workflows.

### I barely get rid of [EMS](http://www.statmt.org/moses/?n=FactoredTraining.EMS). Why creating another workflow for MT?

Face the truth: MT researchers are dealing with pipeline, even we are having a end-to-end system. For example, this is a minimalistic NMT system building pipeline with BPE:

![Minimalistic Workflow](https://raw.githubusercontent.com/shuoyangd/tape4nmt/master/workflow.png)

Doing this by hand, from my own experiences in several evaluation campaigns, is very error-prone and inefficient. Hence the need for a experiment management system.

`tape4nmt` also fixes a lot of problems EMS has. For example, EMS consolidated workflow management and workflow definition into one gigantic perl script, with some regular expressions failing about every 6 months. `tape4nmt` however, separated these two functionalities. And hopefully you'll also see that `tape4nmt` has a better structure for maintainence.

### I'm sold. How do I start to use it?

Before you start, note that this workflow is tested on the sun grid manager configured on [CLSP](https://www.clsp.jhu.edu) grid out-of-box. But don't worry, you may only need to slightly tweak `action_flags` and `resource_flags` in the `.tconf` file to be able to use this on other grid that uses sun grid manager. Or in the worse case, you could substitute all submitter with `"bash"` to run everything locally or define your own submitter!

Start by installing [DuctTape](https://github.com/jhclark/ducttape) following their readme.

The workflow provided has the following general dependencies. Good news: you are not supposed to manually install any of them, because DuctTape itself is designed to manage dependency packages for you! The workflow we provide already ships with the basic package setup procedures for you to start working, but you may have to make modifications to these procedures to cater your own special system requirements. Check out all the lines starting with `packages`.

+ [tape4nmt-tools](https://github.com/shuoyangd/tape4nmt-tools): The must-have -- includes scripts that we use in some of our tasks.
+ [Moses](https://github.com/moses-smt/mosesdecoder): No need to compile -- we'll just be using scripts.
+ [pytorch](https://github.com/pytorch/pytorch)
+ [subword-nmt](https://github.com/rsennrich/subword-nmt)
+ [Stanford Segmenter](https://nlp.stanford.edu/software/segmenter.shtml): (Optional) Only needed if you want to run experiment on Chinese Data.

`tape4nmt` aims to support all the NMT toolkits on the market. By default we use [fairseq](https://github.com/pytorch/fairseq), but we currently support [OpenNMT-py](https://github.com/OpenNMT/OpenNMT-py) as well, while [sockeye](https://github.com/awslabs/sockeye) support is in the near future. If your favorite NMT toolkit hasn't been supported yet, you should still be able to make a moderate amount of modifications and work mostly with this pipeline. (If you actually did, please consider contributing your effort!)

Once you are ready, clone this repository and edit working directory and the data directories etc. And run:

```
ducttape onmt.tape -C onmt.tconf
```

You should see things spinnng up.

### Hey I found your workflow does not do xxx...

This workflow is not supposed to include everything at the first place! I created this repository mainly in hope that people could benefit from running a basic workflow to learn the basics, and then modify it to do whatever they would like to do.

In order to modify this repository properly, you need to learn how to write DuctTape workflow. DuctTape itself contains a pretty comprehensive [tutorial](https://github.com/jhclark/ducttape/tree/master/tutorial). Nathan Schneider has [a better one](https://github.com/nschneid/ducttape-crash-course/blob/master/tutorial.md), albeit seems incomplete.

### What are the limitations I should keep in mind while using this?

While we try our best to make the workflow intuitive and easy to use, it should be kept in mind that our upstream project [DuctTape](https://github.com/jhclark/ducttape) hasn't been developed for quite a while. As a consequence, there are some loose ends that haven't been properly tied, e.g., [this](https://github.com/jhclark/ducttape/issues/159) and [this](https://github.com/ctongfei/ducttape/issues/2), which means there a moderate amounts of work-arounds we have to make (e.g., all the `dummy` tasks we've made) to achieve what we aim to do. I plan to make a short-list of failure cases that you can hopefully avoid should you modify the workflow to achieve your goal.

### What if I want to contribute?

If you think some of your changes are really general and other people should benefit from your changes as well, pull requests are always appreciated!

The developers of this project are actively collaborating with [Tongfei Chen](https://github.com/ctongfei) to make [improvements for DuctTape](https://github.com/ctongfei/ducttape) to weed out issues we've identified. If you love this project and write Scala, consider joining our force on this separate effort!
