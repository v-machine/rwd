# Copyright (c) 2020, Vincent Mai, http://jiawei.vincent.mai@gmail.com
# All rights reserved.

# Main rwd program to be sourced in .bashrc
# Author: Vincent Mai
# Version: 0.1.0

get_source(){
	RWD_SOURCE="$1/rwd.sh"
	if [ -f "$RWD_SOURCE" ]
	then
		. "$RWD_SOURCE"
	else
		echo "rwd source not found in $RWD_PATH."
	fi
}

clean_up(){
	unset RWD_PATH RWD_SOURCE MSG
}

call_rwd(){
	RWD_PATH=$1
	shift 1
	get_source "$RWD_PATH"
	MSG=$(src_rwd "$RWD_PATH" "$@")
	case $? in
		0)	if [ "$MSG" ]; then echo "$MSG"; return 0; fi;;
		1)	echo "$MSG"; return 1;;
		2)	cd "$MSG";;
		3)	exit 0
	esac
	clean_up "$@"
}
