#! /bin/bash
#
# test_venv.sh
# Copyright (C) 2019 Shuoyang Ding <shuoyangd@gmail.com>
#
# Distributed under terms of the MIT license.
#

source /root/pytorch/bin/activate
grep -Ev "^\s+pyenv" fairseq.tconf > tmp.tconf
ducttape test/test_env.tape -C tmp.tconf -p test_venv -y
rm -r out tmp.tconf
