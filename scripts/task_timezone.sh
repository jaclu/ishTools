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

task_timezone() { 
    tz_file=/usr/share/zoneinfo/$IT_TIME_ZONE
    
    msg_txt="Setting timezone"
    if [ "$IT_TIME_ZONE" != "" ]; then
        msg_2 "$msg_txt"
        echo "$IT_TIME_ZONE"
        if [ ! "$IT_TASK_DISPLAY" = "1" ]; then
            ensure_installed tzdata
            if [ "$tz_file" != "" ] && test -f $tz_file ; then
                cp "$tz_file" /etc/localtime
                # remove obsolete file
                2> /dev/null rm /etc/timezone
                msg_3 "displaying time"
                date
            else
                error_msg "BAD TIMEZONE: $IT_TIME_ZONE" 1
            fi
        fi
        echo
    elif [ "$IT_TASK_DISPLAY" = "1" ] &&  [ $IT_DISPLAY_NON_TASKS = "1" ]; then
        msg_2 "$msg_txt"
        echo "Timezone ill NOT be changed"
        echo
    fi
}



#==========================================================
#
#   Internals
#
#==========================================================

_run_this() {
    task_timezone
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
        echo "task_timezone.sh [cfg] [-h|tz]"
        echo " cfg Read configuration file"
        echo " -h  Display help, and either describe or display content for environment"
        echo " tz  Use this time zone."
        echo
        echo "Sets time-zone baesed on IT_TIME_ZONE or command line param"
        echo
        echo "Env paramas"
        echo "-----------"
        echo "IT_TIME_ZONE$(test -z "$IT_TIME_ZONE" && echo ' - set time-zone' || echo =$IT_TIME_ZONE )"
        echo
        echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi
