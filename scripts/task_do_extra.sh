#!/bin/sh
#
# Copyright (c) 2021: Jacob.Lundqvist@gmail.com 2021-04-30
# License: MIT
#
# Version: 0.1.0 2021-04-30
#    Initial release
#
# Part of ishTools
#


if test -z "$DEPLOY_PATH" ; then
    # Most likely not sourced...
    DEPLOY_PATH="$(dirname "$0")/.."               # relative
    DEPLOY_PATH="$( cd "$DEPLOY_PATH" && pwd )"  # absolutized and normalized
fi
. "$DEPLOY_PATH/scripts/extras/utils.sh"



#==========================================================
#
#   Public functions
#
#==========================================================

task_do_extra_task() {
    msg_txt="Running custom task"
    if [ "$IT_EXTRA_TASK" != "" ]; then
        if [ "$IT_TASK_DISPLAY" = "1" ]; then
            msg_2 "$msg_txt"
            echo "$IT_EXTRA_TASK"
        else
            msg_1 "$msg_txt"
        fi
        test -f "$IT_EXTRA_TASK" || error_msg "$IT_EXTRA_TASK not found" 1
        test -x "$IT_EXTRA_TASK" || error_msg "$IT_EXTRA_TASK not executable" 1
        if [ "$IT_TASK_DISPLAY" != "1" ]; then
            echo "Running:   $IT_EXTRA_TASK"
            echo
            . "$IT_EXTRA_TASK"
            echo "Completed: $IT_EXTRA_TASK"
        fi
    elif [ "$IT_TASK_DISPLAY" = "1" ] &&  [ "$IT_DISPLAY_NON_TASKS" = "1" ]; then
        msg_2 "NO custom task will be run"
    fi
    echo
}



#==========================================================
#
#   Internals
#
#==========================================================

_run_this() {
    task_do_extra_task
    echo "Task Completed."
}



#==========================================================
#
#     main
#
#==========================================================

if [ "$IT_INITIAL_SCRIPT" = "" ]; then
    #
    # Since sourced mode cant be detected in a practiacl way under ash,
    # I use this workaround, first script is expected to set it, if set
    # script can assume to be sourced
    #
    IT_INITIAL_SCRIPT=1

    p_help=0
    p_cfg=0
    while [ "$1" != "" ]; do
        case "$1" in
            "-?"|"-h"|"--help")
                p_help=1
                ;;
                
            "cfg")
                . "$DEPLOY_PATH/scripts/extras/read_config.sh"
                read_config
                ;;
                
            *)
                test -z "$1" || IT_EXTRA_TASK="$1"
                ;;
                
         esac
         shift
    done
    
    if [ $p_help = 0 ]; then
        _run_this
    else
        echo "task_do_extra.sh [script_to_be_run]"
        echo
        echo "Runs additional script defined by IT_EXTRA_TASK or command line param."
        echo "Intended as part of ish-restore, not meaningful to run standalone."
        echo "This is mostly for describing and testing the script"
        echo
        echo "Env paramas"
        echo "-----------"
        echo "IT_EXTRA_TASK$(test -z "$IT_EXTRA_TASK" && echo ' - script with additional task(-s) Will be sourced, so can use existing functions and variables' || echo =$IT_EXTRA_TASK )"
        echo
        echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi
