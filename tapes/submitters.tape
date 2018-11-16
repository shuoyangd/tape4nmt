# COMMANDS: the bash commands from some task
# TASK, REALIZATION, CONFIGURATION: variables passed by ducttape
submitter shell :: COMMANDS TASK_VARIABLES {
  action run {
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

    STARTED=$(date +%s)
    time eval "$COMMANDS"
    STOPPED=$(date +%s)
    TIME=$(($STOPPED - $STARTED))
    echo $TIME > ducttape_time.txt
  } 
}

# COMMANDS: the bash commands from some task
# TASK, REALIZATION, CONFIGURATION: variables passed by ducttape
submitter sge :: action_flags
              :: COMMANDS
              :: TASK REALIZATION TASK_VARIABLES CONFIGURATION {
  action run {
    wrapper="ducttape_job.sh"
    echo "#$ resource_flags" >> $wrapper
    echo "#$ action_flags" >> $wrapper
    echo "#$ -j y" >> $wrapper
    echo "#$ -o localhost:$PWD/job.out" >> $wrapper
    echo "#$ -N $CONFIGURATION-$TASK-$REALIZATION" >> $wrapper

    # Bash flags aren't necessarily passed into the scheduler
    # so we must re-initialize them

    # these two doesn't work well with virtualenv ...
    # echo "set -e # stop on errors" >> $wrapper
    # echo "set -u # stop on undeclared variables" >> $wrapper

    echo >> $wrapper
    echo ". ~/.bashrc" >> $wrapper
    echo >> $wrapper

    echo "set -o pipefail # stop on pipeline errors" >> $wrapper
    echo "set -x # show each command as it is executed" >> $wrapper
    echo "${TASK_VARIABLES[@]}" | grep -v "resource_flags" | grep -v "action_flags" >> $wrapper

    # Setup the virtual environment
    cat >> $wrapper <<EOF

    set +u
    if [[ ! -z \$pyenv ]]; then
      virtualenv=\$pyenv

      # Load the environment
      if [[ \$virtualenv == conda:* ]]; then
        . /opt/anaconda3/etc/profile.d/conda.sh
        target=\$(echo \$virtualenv | cut -d: -f2-)
        conda activate \$target
      else
        source \$virtualenv
      fi
    fi
    set -u

EOF

    # The current working directory will also be changed by most schedulers
    echo "cd $PWD" >> $wrapper

    echo "$COMMANDS" >> $wrapper
    echo "echo \$? > exitcode" >> $wrapper  # saves the exit code of the inner process

    # Use SGE's -sync option to prevent qsub from immediately returning
    qsub -V -S /bin/bash -sync y $wrapper

    # restore the exit code saved from the inner process
    EXITCODE=$(cat $PWD/exitcode)
    [ $EXITCODE = "0" ]
  }
}
