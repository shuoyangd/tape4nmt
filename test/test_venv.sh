#! /bin/bash

source /root/pytorch/bin/activate
ducttape test/test_env.tape -C fairseq.tconf -p test_venv -y
rm -r out
