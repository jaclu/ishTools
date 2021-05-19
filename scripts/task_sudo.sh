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


task_nopasswd_sudo() {
    msg_2 "no-pw sudo for group wheel"
    if [ "$IT_TASK_DISPLAY" != "1" ]; then
        ensure_installed sudo
        grep restore-ish /etc/sudoers > /dev/null
        if [ $? -eq 1 ]; then
            msg_3 "adding %wheel NOPASSWD to /etc/sudoers"
            echo "%wheel ALL=(ALL) NOPASSWD: ALL # added by restore-ish" >> /etc/sudoers
        else
            msg_3 "pressent"
        fi
    elif [ "$IT_DISPLAY_NON_TASKS" = "1" ]; then
        echo "Will NOT be set"
    else
        echo "will be set if not done already"
    fi
    echo
}


#==========================================================
#
#   Internals
#
#==========================================================

_run_this() {
    task_nopasswd_sudo
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
                
         esac
         shift
    done
    
    if [ $p_help = 0 ]; then
        _run_this
    else
        echo "task_sudo.sh [cfg] [-h]"
        echo "Installs sudo and creates a no password sudo group wheel, if it does not allready exist."
        echo
        echo "Env paramas"
        echo "-----------"
            echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi
