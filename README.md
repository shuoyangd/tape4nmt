# tape4nmt [![cloud build status](https://storage.googleapis.com/tape4nmt-builds-badge/build/myRepo-master.svg)](https://github.com/shuoyangd/tape4nmt)

### What is that?

`tape4nmt` is a [`DuctTape`](https://github.com/jhclark/ducttape) workflow created to replace your bash scripts for running NMT experiments. [`DuctTape`](https://github.com/jhclark/ducttape) is a workflow management system written by Jonathon Clark. In general, if you are writing bash scripts to run any experiments, you may want to consider using `DuctTape` instead. It organizes your experiment scripts such that:

1.  you are much less likely to do stupid things by e.g. deleting your best model by accident, use the wrong data for the experiment, the list goes on;
2.  you can easily run, delete, and/or re-run batch experiments, re-using any partial results possible, with correctness guarantee;
3.  you can easily re-use part of your modularized experiment script (called "workflow") to create new workflows.

### I barely get rid of [EMS](http://www.statmt.org/moses/?n=FactoredTraining.EMS). Why creating another workflow for MT?

Face the truth: MT researchers are dealing with pipeline, even we are having a end-to-end system. For example, this is a minimalistic NMT system building pipeline with BPE:

![Minimalistic Workflow](https://raw.githubusercontent.com/shuoyangd/tape4nmt/master/workflow.png)

Doing this by hand, from my own experiences in several evaluation campaigns, is very error-prone and inefficient. Hence the need for a experiment management system.

`tape4nmt` also fixes a lot of problems EMS has. For example, EMS consolidated workflow management and workflow definition into one gigantic perl script, with some regular expressions failing about every 6 months. `tape4nmt` however, uses `DuctTape` for workflow management and only take cares of workflow definition. It also keeps data/workflow separation in mind throughout its design. Besides, hopefully you'll also find `tape4nmt` has a better structure for maintainence.

`tape4nmt` aims to support all major NMT toolkits on the market. We currently support [fairseq](https://github.com/pytorch/fairseq), [sockeye](https://github.com/awslabs/sockeye), and [OpenNMT-py](https://github.com/OpenNMT/OpenNMT-py), with [marian](https://github.com/marian-nmt/marian) support in the near future. Also, if your favorite NMT toolkit hasn't been supported yet, you should only need to create one extra tape file containing toolkit-specific operations (binarize data, train, and decode). (If you actually did, please consider contributing your effort!)

### I'm sold. How do I start to use it?

The workflow is pre-configured to build an IWSLT German-English system with fairseq. Follow this [tutorial](https://github.com/shuoyangd/tape4nmt/blob/master/TUTORIAL.md) to get started.

Note that this workflow is tested on the sun grid manager configured on [CLSP](https://www.clsp.jhu.edu) grid out-of-box, so you may need to slightly tweak `action_flags` and `resource_flags` in the `main.tconf` file to be able to use this on other grid that uses sun grid manager. Or in the worse case, you could substitute all submitter with `"bash"` to run everything locally, or define your own submitter for grid manager of your choice!

### Hey I found your workflow does not do xxx...

This workflow is not supposed to include everything at the first place! I created this repository mainly in hope that people could benefit from running a basic workflow to learn the basics, and then modify it to do whatever they would like to do.

In order to modify this repository properly, you need to learn how to write DuctTape workflow. DuctTape itself contains a pretty comprehensive [tutorial](https://github.com/jhclark/ducttape/tree/master/tutorial). Nathan Schneider has [a better one](https://github.com/nschneid/ducttape-crash-course/blob/master/tutorial.md), albeit seems incomplete.

### What are the limitations I should keep in mind while using this?

While we try our best to make the workflow intuitive and easy to use, it should be kept in mind that our upstream project [DuctTape](https://github.com/jhclark/ducttape) hasn't been developed for quite a while. As a consequence, there are some loose ends that haven't been properly tied, e.g., [this](https://github.com/jhclark/ducttape/issues/159) and [this](https://github.com/ctongfei/ducttape/issues/2), which means there a moderate amounts of work-arounds we have to make (e.g., all the `dummy` tasks we've made) to achieve what we aim to do. I plan to make a short-list of failure cases that you can hopefully avoid should you modify the workflow to achieve your goal.

### What if I want to contribute?

Pull requests are always appreciated!
