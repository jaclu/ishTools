
#
# This should only be sourced...
#
[ "$(basename $0)" = "read_params.sh" ] && error_msg "utils.sh is not meant to be run stand-alone!" 1



#==========================================================
#
#   Public functions
#
#==========================================================

read_config() {
    #
    #   Identify the local env, and parse config file
    #
 

    #
    # Set some defaults, in case they are not set in the config file
    # This prevents shellcheck from giving waarnings aboout unasigned variables
    # 
    IT_UNAME=""
    IT_APKS_DEL=""
    IT_APKS_ADD=""
    IT_TIME_ZONE=""
    IT_ROOT_UNPACKED_PTR=""
    IT_HOME_DIR_UNPACKED_PTR=""
    IT_EXTRA_TASK=""
    
    #
    # Config file
    #
    cfg_file=$DEPLOY_PATH/custom/ishTols.cfg
    
    if [ "$cfg_file" != "" ] && test -f "$cfg_file" ; then
        msg_2 "Reading configuration"
	echo " $cfg_file"
        . "$cfg_file"
	
	#
	# If a config file named as utils/HOSTNAME.cfg is found, reaf it after main config
	# in order to override with host specific settings.
	#
	cfg_file=$DEPLOY_PATH/custom/settings-$(hostname).cfg
	if [ -f "$cfg_file" ]; then 
    	    echo " $cfg_file"
	    . $cfg_file
	fi

    else
        echo
        echo "ERROR: No config file ($cfg_file) found, aborting"
        echo
        echo "You should find a template config file in the samples dir of this repo,"
        echo "copy it to the above location, and tweak it to your preferences."
        echo
        exit 1
    fi
    # process path references in config file
    _expand_path_all_params

    #
    # Extra checks for numerical params
    #
    if [ "$IT_DISPLAY_NON_TASKS" = "" ] || [ "$IT_DISPLAY_NON_TASKS" != "1" ]; then
        IT_DISPLAY_NON_TASKS="0"
    fi
    
    # Default sshd port
    [ "$IT_SSHD_PORT" = "" ] && IT_SSHD_PORT=1022
   
    if [ "$IT_ROOT_REPLACE" = "" ] || [ "$IT_ROOT_REPLACE" -ne 1 ]; then
        IT_ROOT_REPLACE=0
    fi

    #
    # Unset variables depending on others
    #
    
    # dont unpack user home without an username
    [ "$IT_UNAME" = "" ] && IT_HOME_DIR_TGZ=""
}



#==========================================================
#
#   Internals
#
#==========================================================

_expand_path() {
    #
    #  Path not starting with / are asumed to be relative to
    #  $DEPLOY_PATH
    #
    this_path="$1"
    char_1=$(echo "$this_path" | head -c1)

    if [ "$char_1" = "/" ]; then
        echo "$this_path"
    else
        echo "$DEPLOY_PATH/$this_path"
    fi
}


_expand_path_all_params() {
    #
    # Expands all path params that might be relative
    # to the deploy location into a full path
    #
    if [ "$IT_FILE_REPOSITORIES" = "*** do not touch ***" ]; then
        IT_FILE_REPOSITORIES=""
    elif [ "$IT_FILE_REPOSITORIES" != "" ] ; then
        IT_FILE_REPOSITORIES=$(_expand_path "$IT_FILE_REPOSITORIES")
    else
        # Use default Alpine repofile
        IT_FILE_REPOSITORIES="$DEPLOY_PATH/files/repositories-Alpine-v3.12"
    fi
    [ "$IT_FILE_HOSTS" != "" ] && IT_FILE_HOSTS=$(_expand_path "$IT_FILE_HOSTS")
    if [ "$IT_SSH_HOST_KEYS" != "" ]; then
        #echo "### expanding: [$IT_SSH_HOST_KEYS]"        
        IT_SSH_HOST_KEYS=$(_expand_path "$IT_SSH_HOST_KEYS")
        #echo "    expanded into: [$IT_SSH_HOST_KEYS]"
    fi
    if [ "$IT_HOME_DIR_TGZ" != "" ]; then
        #echo "### expanding: [$IT_HOME_DIR_TGZ]"        
        IT_HOME_DIR_TGZ=$(_expand_path "$IT_HOME_DIR_TGZ")
        #echo "    expanded into: [$IT_HOME_DIR_TGZ]"
    fi
    if [ "$IT_ROOT_HOME_TGZ" != "" ]; then
        #echo "### expanding: [$IT_ROOT_HOME_TGZ]"        
        IT_ROOT_HOME_TGZ=$(_expand_path "$IT_ROOT_HOME_TGZ")
        #echo "    expanded into: [$IT_ROOT_HOME_TGZ]"
    fi
    if [ "$IT_EXTRA_TASK" != "" ]; then
        #echo "### expanding: [$IT_EXTRA_TASK]"
        IT_EXTRA_TASK=$(_expand_path "$IT_EXTRA_TASK")
        #echo "    expanded into: [$IT_EXTRA_TASK]"
    fi
    #
    # switch to new params
    #
}



