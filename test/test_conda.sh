#! /bin/bash

source activate pytorch
ducttape test/test_env.tape -C sockeye.tconf -p test_conda -y
rm -r out
