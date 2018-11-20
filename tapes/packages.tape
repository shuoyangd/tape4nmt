package sockeye :: .versioner=git .repo="/home/hltcoe/mpost/code/sockeye" .ref=HEAD { }
package sacrebleu :: .versioner=pip .package="sacrebleu" .tag="1.2.12" { }
package subword_nmt :: .versioner=pip .package="subword-nmt" .tag="0.3.5" { }
package mosesdecoder :: .versioner=git .repo="https://github.com/moses-smt/mosesdecoder" .ref=HEAD { }

package sentencepiece :: .versioner=git .repo="https://github.com/google/sentencepiece" .ref="refs/tags/v0.1.6" {
  mkdir build
  cd build
  cmake ..
  make -j $(nproc)
}

package tools
    :: .versioner=git .repo="https://github.com/shuoyangd/tape4nmt-tools" .ref=HEAD {
  pip install -r requirements.txt
}

# using my fork for now, as fairseq evolves pretty fast
package fairseq
    :: .versioner=git .repo="https://github.com/shuoyangd/fairseq" .ref=HEAD
    :: realref="refs/remotes/origin/master" {

  git checkout -b working $realref
  python setup.py build develop
}

