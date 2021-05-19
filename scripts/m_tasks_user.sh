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

task_restore_user() {
    msg_txt="Username: $IT_UNAME"
    IT_SHELL=${IT_SHELL:-/bin/ash}
    IT_UID=${IT_UID:-501}
    IT_GID=${IT_GID:-501}
    
    if [ "$IT_UNAME" != "" ]; then
        #
        # Ensure user is created
        #
        msg_2 "$msg_txt"
        if ! grep ^"$IT_UNAME" /etc/passwd > /dev/null ; then
            # ensure shadow and hence adduser is installed
            if [ "$IT_TASK_DISPLAY" -eq 1 ]; then
                [ "$(grep "x:$IT_UID:" /etc/passwd)" != "" ] && error_msg "uid:$IT_UID already in use" 1
                [ "$(grep $IT_GID /etc/passwd)" != "" ] && error_msg "gid:$IT_GID already in use" 1
                msg_3 "Will be created as $IT_UNAME:x:$IT_UID:$IT_GID::/home/$IT_UNAME:$IT_SHELL"
                msg_3 "shell: $IT_SHELL"
                ensure_shell_is_installed $IT_SHELL
            else
                ensure_installed shadow "Adding shadow (provides useradd)"
                # we need to ensure the group exists, before using it in useradd
                # TODO: identidy a 501 group by name and delete it
                #groupdel -g "$IT_UNAME" 2> /dev/null
                groupadd -g $IT_GID "$IT_UNAME"
                [ $? != 0 ] && error_msg "group id already in use: $IT_GID" 1
                #  sets uid & gid to 501, to match apples uid/gid on iOS mounts
                useradd -u $IT_UID -g $IT_GID -G wheel -m -s "$IT_SHELL" "$IT_UNAME"
                if [ $? != 0 ]; then
                    groupdel $IT_UNAME
                    error_msg "task_restore_user() - useradd failed to complete." 1
                fi
                msg_3 "added: $IT_UNAME"
                msg_3 "shell: $IT_SHELL"
            fi
        else
            msg_3 "Already pressent"
            current_shell=$(grep $IT_UNAME /etc/passwd | sed 's/:/ /g'|  awk '{ print $NF }')
            if [ "$current_shell" != "$IT_SHELL" ]; then
                if [ "$IT_TASK_DISPLAY" = "1" ]; then
                    echo "Will change shell $current_shell -> $IT_SHELL"
                else
                    ensure_shell_is_installed $IT_SHELL
                    usermod -s $IT_SHELL $IT_UNAME
                    msg_3 "new shell: $IT_SHELL"
                fi
            fi
        fi
        echo

        #
        # Restore user home
        #
        if [ "$IT_HOME_DIR_TGZ" != "" ]; then
            msg_txt="Restoration of /home/$IT_UNAME"
            unpack_home_dir "$IT_UNAME" /home/"$IT_UNAME" "$IT_HOME_DIR_TGZ" "$IT_HOME_DIR_UNPACKED_PTR"
        fi
    elif [ "$IT_TASK_DISPLAY" = "1" ] && [ "$IT_DISPLAY_NON_TASKS" = "1" ]; then
        msg_2 "Will NOT create any user"
    fi
    echo
}


task_user_pw_reminder() {
    [ "$IT_TASK_DISPLAY" -eq 1 ] && return

    if [ "$IT_UNAME" != "" ] && [ "$(grep "$IT_UNAME":\!: /etc/shadow)" != "" ]; then
        echo "+------------------------------+"
        echo "|                              |"
        echo "|  Remember to set a password  |"
        echo "|  for your added user:        |"
        echo "|    sudo passwd $IT_UNAME"
        echo "|                              |"
        echo "+------------------------------+"
        echo
    fi
}



#==========================================================
#
#   Internals
#
#==========================================================

_run_this() {
    task_restore_user
    task_user_pw_reminder
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
        echo "m_tasks_user.sh [-h|cfg]"
        echo " cfg Read configuration file"
        echo " -h   Display help, and either describe or display content for environment"
        echo "      variables if defined"
        echo
        echo "Tasks included:"
        echo " task_restore_user      - creates user according to env variables"
        echo " task_user_pw_reminder  - displays a reminder if no password has been set"
        echo 
        echo "Creates a new user, ensuring it will not overwrite an existing one."
        echo
        echo "Env variables used"
        echo "------------------"
        echo "IT_UNAME$(test -z "$IT_UNAME" && echo ' - username to ensure exists' || echo =$IT_UNAME )"
        echo "IT_UID$(test -z "$IT_UID" && echo ' - userid to be used, defaulting to 501' || echo =$IT_UID )"
        echo "IT_GID$(test -z "$IT_GID" && echo ' - groupid to be used, defaulting to 501' || echo =$IT_GID )"
        echo "IT_SHELL$(test -z "$IT_SHELL" && echo ' - shell for username' || echo =$IT_SHELL )"
        echo "IT_HOME_DIR_TGZ$(test -z "$IT_HOME_DIR_TGZ" && echo ' - unpack this tgz file if found' || echo =$IT_HOME_DIR_TGZ )"
        echo "IT_HOME_DIR_UNPACKED_PTR$(test -z "$IT_HOME_DIR_UNPACKED_PTR" && echo ' -  Indicates home.tgz is unpacked' || echo =$IT_HOME_DIR_UNPACKED_PTR )"
    
        echo
        echo "IT_TASK_DISPLAY$(test -z "$IT_TASK_DISPLAY" && echo ' -  if 1 will only display what will be done' || echo =$IT_TASK_DISPLAY)"
        echo "IT_DISPLAY_NON_TASKS$(test -z "$IT_DISPLAY_NON_TASKS" && echo ' -  if 1 will show what will NOT happen' || echo =$IT_DISPLAY_NON_TASKS)"
    fi
fi
