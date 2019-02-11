import "../tapes/versioners.tape"
import "../tapes/submitters.tape"

global {
  pypackage=(PyPackage: sacrebleu
    subword_nmt="subword-nmt")

  command=(Command: sacrebleu
    subword_nmt="subword-nmt"
  )

  pyenv=(PyEnv: venv="/root/pytorch/bin/activate" conda="conda:pytorch")
  ducttape_output="out"
}

task check_python_package : sockeye sacrebleu subword_nmt mosesdecoder sentencepiece tools fairseq
  > out
  :: pypackage=@
  :: pyenv=@ {

  if [ ! -z "`pip list | grep $pypackage`" ] ; then
    touch $out
  else
    echo "python package $pypackage does not exist!"
  fi
}

task check_command : sockeye sacrebleu subword_nmt mosesdecoder sentencepiece tools fairseq
  > out
  :: command=@ {

  if [ ! -z "`command -v $command`" ] ; then
    touch $out
  else
    echo "command $command does not exist!"
  fi
}

task check_sentence_piece_binaries : sentencepiece
  > out {

  $sentencepiece/build/src/spm_decode --help
  if [[ $? != 0 ]] ; then
    exit
  fi

  $sentencepiece/build/src/spm_encode --help
  if [[ $? != 0 ]] ; then
    exit
  fi

  $sentencepiece/build/src/spm_train --help
  if [[ $? != 0 ]] ; then
    exit
  fi

  touch $out
}

plan test_venv {
  reach check_python_package, check_command, check_sentence_piece_binaries via (PyPackage: *) * (Command: *) * (PyEnv: venv)
}

plan test_conda {
  reach check_python_package, check_command, check_sentence_piece_binaries via (PyPackage: *) * (Command: *) * (PyEnv: conda)
}

# Nuts and bolts:
global {
  ducttape_experimental_packages=true
  ducttape_experimental_submitters=true
  ducttape_experimental_imports=true
  ducttape_experimental_multiproc=true
}

