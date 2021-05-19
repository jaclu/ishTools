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
. "$DEPLOY_PATH/scripts/extras/openrc.sh"



#==========================================================
#
#   Public functions
#
#==========================================================

task_sshd() {
    if [ "$1" != "" ]; then
        IT_SSHD_SERVICE="$1"
    elif [ "$IT_SSHD_SERVICE" = "" ]; then
        IT_SSHD_SERVICE="0"
        error_msg "IT_SSHD_SERVICE not defined, asuming no action"
    fi
    msg_txt="sshd service"
    case "$IT_SSHD_SERVICE" in
        "-1" ) # disable
            msg_2 "$msg_txt"
            msg_3 "will be disabled"
            if [ ! "$IT_TASK_DISPLAY" = "1" ]; then                        
                if [ "$(2> /dev/null rc-status |grep sshd)" != "" ]; then
                    rc-service sshd stop
                    rc-update del sshd
                    msg_3 "was disabled"
                else
                    echo "sshd not active, no action needed"
                fi
            fi
            echo
            ;;
            
        "0" )  # unchanged
            if [ "$IT_TASK_DISPLAY" = "1" ] &&  [ $IT_DISPLAY_NON_TASKS = "1" ]; then
                msg_2 "$msg_txt"
                echo "Will NOT be changed"
            fi
            ;;
        
        "1" )  # activate 
            msg_txt_2=$msg_txt
            _unpack_ssh_host_keys
            msg_2 "$msg_txt_2"
            if [ "$IT_SSHD_PORT" = "" ]; then
                error_msg "Invalid setting: IT_SSHD_PORT must be specified" 1
            fi
            # This will be run regardless if it was already running,
            # since the sshd_config might have changed
            if [ "$IT_TASK_DISPLAY" = "1" ]; then
                msg_3 "Will be enabled"
                echo "port: $IT_SSHD_PORT"
                echo
            else
                msg_3 "Ensuring hostkeys exist"
                ssh-keygen -A
                echo "hostkeys ready"
                echo
                ensure_runlevel_default
                ensure_installed openssh
                # use requested port
                sed -i "s/.*Port.*/Port $IT_SSHD_PORT/" /etc/ssh/sshd_config
                ensure_service_is_added sshd restart
                # in case some config changes happened, make sure sshd is restarted
                #rc-service sshd restart
                msg_1 "sshd listening on port: $IT_SSHD_PORT"
            fi
            ;;

        *)
            error_msg "Invalid setting: IT_SSHD_SERVICE=$IT_SSHD_SERVICE\nValid options: -1 0 1" 1
    esac
}




#==========================================================
#
#   Internals
#
#==========================================================

_unpack_ssh_host_keys() {
    #
    #  Even if you don't intend to activate sshd initially
    #  it still makes senc to deploy any saved ssh host keys
    #  A) they are there if you need them
    #  B) you dont have to wait for host keys to be generated
    #     when and if you want to run sshd
    #
    msg_txt="Device specific ssh host keys"

    if [ "$IT_SSH_HOST_KEYS" != "" ]; then
        msg_2 "$msg_txt"
        if test -f "$IT_SSH_HOST_KEYS" ; then
            msg_3 "Will be untared into /etc/ssh"
            echo "$IT_SSH_HOST_KEYS"
            if [ "$IT_TASK_DISPLAY" != "1" ]; then
                ensure_installed openssh-client
                cd /etc/ssh || error_msg "Failed to cd into /etc/ssh" 1
                2>/dev/null rm /etc/ssh/ssh_host_*
                tar xvfz "$IT_SSH_HOST_KEYS"
            fi
        else
            msg_3 "Not found"
            echo "$IT_SSH_HOST_KEYS"
        fi
    elif [ "$IT_TASK_DISPLAY" = "1" ] &&  [ "$IT_DISPLAY_NON_TASKS" = "1" ]; then
        msg_2 "$msg_txt"
        echo "Will NOT be used"
    fi
    echo
}


_run_this() {
    task_sshd
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
                test -z "$1" || IT_SSHD_SERVICE="$1"
                ;;
                
         esac
         shift
    done
    
    if [ $p_help = 0 ]; then
        _run_this
    else
        echo "task_sshd.sh [cfg] [-h|-1|0|1]"
        echo "  cfg - reads config file for params"
        echo "  If given service status should be one of"
        echo "    -1 - disable"
        echo "     0 - ignore/nochange"
        echo "     1 - enable"
        echo
        echo "Activates or Disables sshd, status defined by"
        echo "IT_SSHD_SERVICE or command line param."

        echo 
        echo "Env paramas"
        echo "-----------"
        echo "IT_SSHD_SERVICE$(test -z "$IT_SSHD_SERVICE" && echo '  - sshd status (-1/0/1)' || echo =$IT_SSHD_SERVICE )"
        echo "IT_SSHD_PORT$(test -z "$IT_SSHD_PORT" && echo '     - what port sshd should use' || echo =$IT_SSHD_PORT )"
        echo "IT_SSH_HOST_KEYS$(test -z "$IT_SSH_HOST_KEYS" && echo ' - tgz file with host_keys' || echo =$IT_SSH_HOST_KEYS )"
        echo
        echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi
