#! /bin/bash

source activate pytorch
grep -Ev "^\s+pyenv" sockeye.tconf > tmp.tconf
ducttape test/test_env.tape -C tmp.tconf -p test_venv -y
rm -r out tmp.tconf
