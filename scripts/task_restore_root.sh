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
. "$DEPLOY_PATH/scripts/extras/unpack_home_dir.sh"



#==========================================================
#
#   Public functions
#
#==========================================================

task_restore_root() {
    _update_root_shell
    msg_txt="Restoration of /root"
    if [ "$IT_ROOT_HOME_TGZ" != "" ]; then
        unpack_home_dir root /root "$IT_ROOT_HOME_TGZ" "$IT_ROOT_HOME_UNPACKED_PTR" "$IT_ROOT_REPLACE"
            echo
    fi
}



#==========================================================
#
#   Internals
#
#==========================================================

_update_root_shell() {
    IT_ROOT_SHELL="${IT_ROOT_SHELL:-"/bin/ash"}"
    #pidfile="${SSHD_PIDFILE:-"/run/$RC_SVCNAME.pid"}"

    if [ "$IT_ROOT_SHELL" = "" ]; then
        # no change requested
        return
    fi   
    
    current_shell=$(grep ^root /etc/passwd | sed 's/:/ /g'|  awk '{ print $NF }')
    
    if [ "$current_shell" != "$IT_ROOT_SHELL" ]; then
        msg_2 "Changing root shell"
        if [ "$IT_TASK_DISPLAY" = "1" ]; then
            echo "Will change root shell $current_shell -> $IT_ROOT_SHELL"
            ensure_shell_is_installed $IT_ROOT_SHELL
        else
            ensure_shell_is_installed $IT_ROOT_SHELL
            usermod -s $IT_ROOT_SHELL root
            msg_3 "new root shell: $IT_ROOT_SHELL"
        fi
        echo
 
    elif [ "$IT_TASK_DISPLAY" = "1" ] && [ "$IT_DISPLAY_NON_TASKS" = "1" ]; then
        msg_3 "root shell unchanged"
        echo "$current_shell"
        echo
    fi
}

_run_this() {
    task_restore_root
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
                test -z "$1" || IT_TIME_ZONE="$1"
                ;;
                
         esac
         shift
    done
    
    if [ $p_help = 0 ]; then
        _run_this
    else
        echo "task_restore_root.sh [cfg] [-h]"
        echo "Restores root environment. currently shell and /root content can be modified."            
        echo "Can restore /root from a tgz file. Optional ptr to indicate if it has"
        echo "already been unpacked."
        echo "Normal operation is to just untar it into /root."
        echo "IT_ROOT_REPLACE=1 moves /root to /root-OLD (previous such removed)"
        echo "Before unpacking."
        echo
        echo "Env paramas"
        echo "-----------"
        echo "IT_ROOT_SHELL$(test -z "$IT_ROOT_SHELL" && echo ' - switch to this shell' || echo =$IT_ROOT_SHELL )"
        echo "IT_ROOT_HOME_TGZ$(test -z "$IT_ROOT_HOME_TGZ" && echo ' - unpack this into /root if found' || echo =$IT_ROOT_HOME_TGZ )"
        echo
        echo "IT_ROOT_UNPACKED_PTR$(test -z "$IT_ROOT_UNPACKED_PTR" && echo ' - Indicates root.tgz is unpacked' || echo =$IT_ROOT_UNPACKED_PTR )"
        echo "IT_ROOT_REPLACE$(test -z "$IT_ROOT_REPLACE" && echo ' - move previous root and replace it' || echo =$IT_ROOT_REPLACE )"
        echo
        echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi

