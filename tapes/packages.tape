package sockeye :: .versioner=git .repo="https://github.com/mjpost/sockeye" .ref=HEAD { }
package sacrebleu :: .versioner=pip .package="sacrebleu" .tag="1.2.17" { }
package subword_nmt :: .versioner=pip .package="subword-nmt" .tag="0.3.5" { }
package sockeye_scripts :: .versioner=git .repo="https://github.com/mjpost/sockeye-scripts/sockeye-scripts" .ref=HEAD { }

package mosesdecoder :: .versioner=git .repo="https://github.com/moses-smt/mosesdecoder" .ref=HEAD { 
  # This is needed to prevent the Moses tokenizer from splitting out masks
  echo '__[A-Za-z0-9]+(_\d+)?__' >> scripts/tokenizer/basic-protected-patterns
}

package sentencepiece :: .versioner=git .repo="https://github.com/google/sentencepiece" .ref="tags/v0.1.8" {
  mkdir build
  cd build
  cmake ..
  make -j $(nproc)
}

package tools :: .versioner=git .repo="https://github.com/shuoyangd/tape4nmt-tools" .ref=HEAD {
  git submodule update --init --recursive
  pip install -r requirements.txt
}

# using a fork for now, as fairseq evolves pretty fast
package fairseq :: .versioner=git .repo="https://github.com/shuoyangd/fairseq" .ref=HEAD {
  python setup.py build develop
}

