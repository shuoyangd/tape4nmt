# COMMANDS: the bash commands from some task
# TASK, REALIZATION, CONFIGURATION: variables passed by ducttape
submitter shell :: COMMANDS TASK_VARIABLES {
  action run {
    set +u  # needed to fix a virtualenv bug
    if [[ ! -z ${pyenv:-} ]]; then
      virtualenv=$pyenv

      # Load the environment
      if [[ $virtualenv == conda:* ]]; then
        . /opt/anaconda3/etc/profile.d/conda.sh
        target=$(echo $virtualenv | cut -d: -f2-)
        source deactivate
        conda activate $target
      else
        source $virtualenv
      fi
    fi
    set -u

    STARTED=$(date +%s)
    time eval "$COMMANDS"
    STOPPED=$(date +%s)
    TIME=$(($STOPPED - $STARTED))
    echo $TIME > ducttape_time.txt
    set -u
  } 
}

# COMMANDS: the bash commands from some task
# TASK, REALIZATION, CONFIGURATION: variables passed by ducttape
submitter sge :: action_flags
              :: COMMANDS
              :: TASK REALIZATION TASK_VARIABLES CONFIGURATION {
  action run {
    wrapper="ducttape_sge_job.sh"
    echo "#!/usr/bin/env bash" >> $wrapper
    echo "" >> $wrapper
    echo "#$ $resource_flags" >> $wrapper
    echo "#$ $action_flags" >> $wrapper
    echo "#$ -j y" >> $wrapper
    echo "#$ -o $PWD/job.out" >> $wrapper
    echo "#$ -N $CONFIGURATION-$TASK-$REALIZATION" >> $wrapper
    echo "" >> $wrapper

    # Bash flags aren't necessarily passed into the scheduler
    # so we must re-initialize them

    echo "set -euo pipefail" >> $wrapper
    echo "" >> $wrapper
    echo "$TASK_VARIABLES" | perl -pe 's/=/="/; s/$/"/' >> $wrapper

    # Setup the virtual environment
    cat >> $wrapper <<EOF

set +u  # needed to fix a virtualenv bug
if [[ ! -z \${pyenv:-} ]]; then
  virtualenv=\$pyenv

  # Load the environment
  if [[ \$virtualenv == conda:* ]]; then
    . /opt/anaconda3/etc/profile.d/conda.sh
    target=\$(echo \$virtualenv | cut -d: -f2-)
    source deactivate
    conda activate \$target
  else
    source \$virtualenv
  fi
fi
set -u

EOF

    # The current working directory will also be changed by most schedulers
    echo "cd $PWD" >> $wrapper

    echo >> $wrapper
    echo "echo \"HOSTNAME: \$(hostname)\"" >> $wrapper
    echo "echo" >> $wrapper
    echo "echo CUDA in ENV:" >> $wrapper
    echo "env | grep CUDA" >> $wrapper
    echo "env | grep SGE" >> $wrapper
    echo "echo" >> $wrapper
    echo "if [[ ! -z \${SGE_HGR_GPU:-} ]]; then" >> $wrapper
    echo "  export CUDA_VISIBLE_DEVICES=\$(echo \${SGE_HGR_gpu:-} | perl -pe 's/ /,/g')" >> $wrapper
    echo "  echo \"Setting CUDA_VISIBLE_DEVICES=\${CUDA_VISIBLE_DEVICES}\"" >> $wrapper
    echo "fi" >> $wrapper
    echo >> $wrapper

    echo "$COMMANDS" >> $wrapper
    echo "echo \$? > exitcode" >> $wrapper  # saves the exit code of the inner process

    # Use SGE's -sync option to prevent qsub from immediately returning
    qsub -sync y -V -S /bin/bash $wrapper

    # restore the exit code saved from the inner process
    EXITCODE=$(cat $PWD/exitcode)
    [ $EXITCODE = "0" ]
  }
}
