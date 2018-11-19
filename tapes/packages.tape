package tools
    :: .versioner=git .repo="https://github.com/shuoyangd/tape4nmt-tools" .ref=HEAD
    :: pyenv="/path/to/virtualenv" {

  set +u
  if [[ ! -z $pyenv ]]; then
    virtualenv=$pyenv

    # Load the environment
    if [[ $virtualenv == conda:* ]]; then
      . /opt/anaconda3/etc/profile.d/conda.sh
      target=$(echo $virtualenv | cut -d: -f2-)
      conda activate $target
    else
      source $virtualenv
    fi
  fi
  set -u

  pip install -r requirements.txt
}

# using my fork for now, as fairseq evolves pretty fast
package fairseq
    :: .versioner=git .repo="https://github.com/shuoyangd/fairseq" .ref=HEAD
    :: pyenv="/path/to/virtualenv"
    :: realref="refs/remotes/origin/master" {

  git checkout -b working $realref

  set +u
  if [[ ! -z $pyenv ]]; then
    virtualenv=$pyenv

    # Load the environment
    if [[ $virtualenv == conda:* ]]; then
      . /opt/anaconda3/etc/profile.d/conda.sh
      target=$(echo $virtualenv | cut -d: -f2-)
      conda activate $target
    else
      source $virtualenv
    fi
  fi
  set -u
  python setup.py build develop
}

package sockeye :: .versioner=git .repo="/home/hltcoe/mpost/code/sockeye" .ref=HEAD { }

package subword_nmt :: .versioner=git .repo="https://github.com/rsennrich/subword-nmt" .ref=HEAD { }

package mosesdecoder :: .versioner=git .repo="https://github.com/moses-smt/mosesdecoder" .ref=HEAD { }

package sacrebleu :: .versioner=pip .package="sacrebleu" .tag="1.2.12" .pyenv="/path/to/virtualenv" { }
