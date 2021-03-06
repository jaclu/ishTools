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

task_update() {
    msg_2 "update & fix apk index"
    if [ "$IT_TASK_DISPLAY" = "1" ]; then
        msg_3 "Will happen"
    elif ! apk update && apk fix ; then
        error_msg "Failed to update repos - network issue?" 1
    fi
    echo
}


task_upgrade() {
    msg_2 "upgrade installed apks"
    if [ "$IT_TASK_DISPLAY" = "1" ]; then
        msg_3 "Will happen"
    else
        apk upgrade ||  error_msg "Failed to upgrade apks - network issue?" 1
    fi
    echo
}


task_remove_software() {
    msg_txt="Removing unwanted software"
    
    if [ "$IT_APKS_DEL" != "" ]; then
        msg_2 "$msg_txt"
        if [ "$IT_TASK_DISPLAY" = "1" ]; then
            echo "$IT_APKS_DEL"
        else
            echo "$IT_APKS_DEL"
            # TODO: fix
            # argh due to shellcheck complaining that
            #   apk del $IT_APKS_DEL
            # should instead be:
            #   apk del "$IT_APKS_DEL"
            # and that leads to apk not recognizing it as multiple apks
            # this seems to be a useable workarround
            #
            cmd="apk del $IT_APKS_DEL"
            $cmd
        fi
        echo
    elif [ "$IT_TASK_DISPLAY" = "1" ] &&  [ "$IT_DISPLAY_NON_TASKS" = "1" ]; then
        msg_2 "$msg_txt"
        echo "Will NOT remove any listed software"
        echo
    fi
}


task_install_my_software() {
    msg_txt="Installing my selection of software"
    if [ "$IT_APKS_ADD" != "" ]; then
        msg_2 "$msg_txt"
        if [ "$IT_TASK_DISPLAY" = "1" ]; then
            echo "$IT_APKS_ADD"
        else
            # TODO: see in task_remove_software() for description
            # about why this seems needed ATM
            echo "$IT_APKS_ADD"
            cmd="apk add $IT_APKS_ADD"
            $cmd || error_msg "Failed to install requested software - network issue?" 1
        fi
        echo
    elif [ "$IT_TASK_DISPLAY" = "1" ] &&  [ "IT_DISPLAY_NON_TASKS" = "1" ]; then
        msg_2 "$msg_txt"
        echo "Will NOT install any listed software"
        echo
    fi
}



#==========================================================
#
#   Internals
#
#==========================================================

_run_this() {
    task_update
    [ "$IT_APKS_DEL" != "" ] && task_remove_software
    task_upgrade
    [ "$IT_APKS_ADD" != "" ] && task_install_my_software
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
        echo "m_tasks_apk.sh [cfg] [-h]"
        echo " cfg Read configuration file"
        echo " -h  Display help, and either describe or display content for environment"
        echo
        echo "Tasks included:"
        echo " task_update              - updates repository"
        echo " task_upgrade             - upgrades all installed apks"
        echo " task_remove_software     -  deletes all apks listed in IT_APKS_DEL"
        echo " task_install_my_software - adds all apks listed in IT_APKS_ADD"
        echo
        echo "Env paramas"
        echo "-----------"
        echo "IT_APKS_DEL$(test -z "$IT_APKS_DEL" && echo ' - packages to remove, comma separated' || echo =$IT_APKS_DEL )"
        echo "IT_APKS_ADD$(test -z "$IT_APKS_ADD" && echo ' - packages to add, comma separated' || echo =$IT_APKS_ADD )"
        echo
        echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi
