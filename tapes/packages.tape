package tools
    :: .versioner=git .repo="https://github.com/shuoyangd/tape4nmt-tools" .ref=HEAD {

  # TODO: if you have a virtualenv, enable these lines
  # set +u
  # source /path/to/virtualenv
  # set -u
  pip install -r requirements.txt
}

# using my fork for now, as fairseq evolves pretty fast
package fairseq
    :: .versioner=git .repo="https://github.com/shuoyangd/fairseq" .ref=HEAD
    :: realref="refs/remotes/origin/master" {

  # TODO: if you have a virtualenv, enable these lines
  git checkout -b working $realref
  # set +u
  # source /path/to/virtualenv
  # set -u
  python setup.py build develop
}

package sockeye :: .versioner=git .path="/home/hltcoe/mpost/code/sockeye" .ref=HEAD {

}

package sacrebleu :: .versioner=pip .package="sacrebleu" .version="1.2.12" {

}

package subword_nmt :: .versioner=git .repo="https://github.com/rsennrich/subword-nmt" .ref=HEAD {

}

package mosesdecoder :: .versioner=git .repo="https://github.com/moses-smt/mosesdecoder" .ref=HEAD {

}

# enable this when processing Chinese
# package stanford_seg :: .versioner=disk .path="/path/to/stanford-seg" {
# 
# }
