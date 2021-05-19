#!/bin/sh
#
# Copyright (c) 2021: Jacob.Lundqvist@gmail.com 2021-04-30
# License: MIT
#
# Version: 0.2.0 2021-05-xx
#    Created a propper openrc daemn service (files/bgrun)
# 0.1.0 2021-04-30
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
. "$DEPLOY_PATH/scripts/extras/openrc.sh"


#
# Name of service
#
service_name=bgrun
service_fname="/etc/init.d/$service_name"



#==========================================================
#
#   Public functions
#
#==========================================================

task_run_in_background() {
    if [ "$1" != "" ]; then
        activate_bgrun=$1
    elif [ "$IT_BG_RUN" != "" ]; then
        activate_bgrun=$IT_BG_RUN
    else
        error_msg "IT_BG_RUN not defined, asuming no action"
        activate_bgrun=0
    fi
    msg_txt="Run in background"
    msg2_txt="  Ensuring iSH continues to run in the background."
    
    case "$activate_bgrun" in
        -1 ) # disable
            msg_2 "$msg_txt"
            echo "$msg2_txt"
            msg_3 "will be disabled"
            if [ ! "$IT_TASK_DISPLAY" = "1" ]; then
               service_installed="$(rc-service -l |grep $service_name )"
                echo ">> was installed: [$service_installed]"
                if [ "$service_installed"  != "" ]; then
                    disable_service $service_name
                    msg_3 "was disabled"
                else
                    echo "Service $service_name was not active, no action needed"
                fi
                rm $service_fname -f
            fi
            ;;
    
        0 )  # unchanged
            if [ "$IT_TASK_DISPLAY" = "1" ] &&  [ "$IT_DISPLAY_NON_TASKS" = "1" ]; then
                msg_2 "$msg_txt"
                echo "Will NOT be changed"
            fi
            ;;
    
        1 )  # activate 
            msg_2 "$msg_txt"
            echo "$msg2_txt"
            if [ "$IT_TASK_DISPLAY" = "1" ]; then
                msg_3 "Will be enabled"
            else
                ensure_installed openrc
                if [ "$(rc-update -a |grep runbg)" != "" ]; then
                    msg_3 "Removing broken AOK service runbg"
                    # Handling broken AOK service, remove it if found, and kill its 
                    # disconnected stray procss cat /dev/location
                    rc_runlevel=sysinit
                    disable_service runbg && killall cat
                fi
                
                rc_runlevel=default
                ensure_runlevel_default
                
                if [ ! -f "$service_fname" ]; then
                    # do this after 'ensure_runlevel_default', to be sure
                    # openrc has been installed, thus creating the dest
                    # dir for the service_file being copied into place
                    msg_3 "Installing service"
                    cp -av $DEPLOY_PATH/files/$service_name $service_fname
                    chmod 755 $service_fname
                fi
                msg_3 "Activating service"
                ensure_service_is_added $service_name restart
            fi
            ;;

        *)
            error_msg "Invalid setting: activate_bgrun=$activate_bgrun\nValid options: -1 0 1" 1
    esac
    echo
}



#==========================================================
#
#   Internals
#
#==========================================================

_run_this() {
    task_run_in_background $IT_BG_RUN
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
                test -z "$1" || IT_BG_RUN="$1"
                ;;
            
         esac
         shift
    done
    
    if [ $p_help = 0 ]; then
        _run_this
    else
        echo "task_run_in_background.sh [cfg] [h|-1|0|1]"
        echo "  If given service status should be one of"
        echo "    -1 - disable"
        echo "     0 - ignore/nochange"
        echo "     1 - enable"
        echo
        echo "Installs and Activates or Disables a service that monitors the iOS location"
        echo "this ensures that iSH will continue to run in the background."
        echo "defined by IT_BG_RUN or command line param."
        echo
        echo "Env paramas"
        echo "-----------"
        echo "IT_BG_RUN$(test -z "$IT_BG_RUN" && echo ' -  location_tacker status (-1/0/1)' || echo =$IT_BG_RUN)"
        echo
        echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi
