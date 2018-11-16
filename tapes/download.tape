task download_or_link : tools
    < in=(DataSection: train=$train_data devtest=(DevtestDataSection: dev=$dev_data test=$test_data))
    > out
    :: pyenv=@ {
  python $tools/download_or_link.py $in $out
}
