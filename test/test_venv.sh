#! /bin/bash

source /root/pytorch/bin/activate
grep -Ev "^\s+pyenv" fairseq.tconf > tmp.tconf
ducttape test/test_env.tape -C tmp.tconf -p test_venv -y
rm -r out tmp.tconf
