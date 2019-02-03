#! /bin/bash

source activate pytorch
ducttape test/test_env.tape -p test_conda -y
