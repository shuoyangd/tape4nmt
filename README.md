# tape4nmt

### What is that?

`tape4nmt` is a [`ducttape`](https://github.com/jhclark/ducttape) workflow created for running NMT experiments. It currently supports [OpenNMT-py](https://github.com/OpenNMT/OpenNMT-py) but should be able to adapt to other frameworks with relatively modest amount of modifications.

[`ducttape`](https://github.com/jhclark/ducttape) is a workflow management system written by Jonathon Clark. If you are writing bash scripts to run experiments, you may want to consider using `ducttape` instead. It organizes your experiment script such that:

1.  you are much less likely to do stupid things by e.g. deleting your best model by accident, use the wrong data for the experiment, the list goes on; 
2.  you can easily run, delete, and/or re-run batch experiments, re-using any partial results possible, with correctness guarantee; 
3.  you can easily re-use part of your modularized experiment script (called "workflow") to create new workflows.

### I barely get rid of [EMS](http://www.statmt.org/moses/?n=FactoredTraining.EMS). Why creating another workflow for MT?

Face the truth: MT researchers are dealing with pipeline, even we are having a end-to-end system. For example, this is a minimalistic NMT system building pipeline with BPE:

![Minimalistic Workflow](https://raw.githubusercontent.com/shuoyangd/tape4nmt/master/workflow.png)

Doing this by hand, from my own experiences in several evaluation campaigns, is very error-prone and inefficient. Hence the need for a experiment management system.

tape4nmt also fixes a lot of problems EMS has. For example, EMS consolidated workflow management and workflow definition into one gigantic perl script, with some regular expressions failing about every 6 months. tape4nmt however, separated these two functionalities. And hopefully you'll also see that tape4nmt has a better structure for maintainence.

### I'm sold. How do I start to use it?

Before you start, note that this workflow is tested on the sun grid manager configured on [CLSP](https://www.clsp.jhu.edu) grid out-of-box. But don't worry, you may only need to slightly tweak `action_flags` and `resource_flags` in the `.tconf` file to be able to use this on other grid that uses sun grid manager. Or in the worse case, you could substitute all submitter with `"bash"` to run everything locally or define your own submitter!

Start by installing [ducttape](https://github.com/jhclark/ducttape) following their readme.

The workflow provided has the following dependencies. You need to install them before hand and/or change the directory in the package section of this workflow. Consult respective documents of the dependencies for details:

+ [Moses](https://github.com/moses-smt/mosesdecoder): You don't have to compile -- we'll just be using scripts
+ [OpenNMT-py](https://github.com/OpenNMT/OpenNMT-py): You may have to setup PyTorch etc. for that to work -- check their document
+ [Stanford Segmenter](https://nlp.stanford.edu/software/segmenter.shtml): (Optional) Only needed if you want to run experiment on Chinese Data
+ [subword-nmt](https://github.com/rsennrich/subword-nmt)

Once you are ready, clone this repository and edit working directory and the data directories etc. And run:

```
ducttape onmt.tape -C onmt.tconf
```

You should see things spinnng up.

### Hey I found your workflow does not do xxx...

This workflow is not supposed to include everything at the first place! I created this repository mainly in hope that people could benefit from running a basic workflow to learn the basics, and then modify it to do whatever they would like to do.

In order to modify this repository properly, you need to learn how to write ducttape workflow. ducttape itself contains a pretty good [tutorial](https://github.com/jhclark/ducttape/tree/master/tutorial). Nathan Schneider has [another one](https://github.com/nschneid/ducttape-crash-course/blob/master/tutorial.md), albeit seems incomplete.

If you think some of your changes are really general and other people should benefit from your changes as well, pull requests are always appreciated! We also only support OpenNMT-py for the moment, but if you created a workflow with other NMT toolkit, you are more than welcome to contribute.
