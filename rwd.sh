#!/urs/bin/bash
# Copyright (c) 2020, Vincent Mai, http://jiawei.vincent.mai@gmail.com
# All rights reserved.

# rwd source functions
# Author: Vincent Mai
# Version: 0.1.0

ALIAS_LEN=4
ALIAS_HEADER="rwd_"
DEFAULT_ALIAS="$ALIAS_HEADER%tmp"
DEFAULT_ARCHIVE=".rwd_aliases"

get_rwd_aliases(){
	RWD_PATH="$1"
	RWD_ALIASES="$RWD_PATH/$DEFAULT_ARCHIVE"
	[ -f "$RWD_ALIASES" ] || touch "$RWD_ALIASES"
}

parse_args(){
	parse_opts "$1"
	shift $((ARG_SHIFT))
	create_alias "$@"
	create_dir "$@"
}

parse_opts(){
	ARG_SHIFT=0
	while getopts :asdel OPTION
	do
		case $OPTION in
			a)	ALL=True;;
			s)	SILIENT=True;;
			d)	DELETE=True;;
			e)	EXIT=True;;
			l)	LIST=True;;
			?)  echo "Unknown option: $OPTARG"; exit 1;;
		esac
		ARG_SHIFT=1
	done
	[ "$ARG_SHIFT" = 1 ] && validate_opts
}

validate_opts(){
	local MSG
	[ "$LIST" ] || [ "$DELETE" ] || [ "$EXIT" ] && return 0
	[ ! "$ALL" ] && return 0
	MSG="Please specify an optional command: "
	MSG="$MSG -l [list], -d [delete], or -e [exit]."
	echo $MSG; exit 1;
}

create_alias(){
	[ $1 ] && [[ "$1" =~ [^a-zA-Z0-9] ]] &&
	{ echo "Invalid characters. Must be alphanumeric."; exit 1; }
	[ ${#1} -gt $ALIAS_LEN ] &&
    { echo "Pleease limit Bookmarks to $ALIAS_LEN characters."; exit 1; }
	[ $1 ] && ALIAS="$ALIAS_HEADER$1" || ALIAS="$DEFAULT_ALIAS" 
}

create_dir(){
	[ "$2" = "." ] && { DIR=$(pwd); return 0; } ||
	[ "$2" = ".." ] && { DIR=$(dirname $(pwd)); return 0; }
	[ "$2" ] && [ ! -d "$2" ] &&
	{ echo "Directory \"$2\" does not exist."; exit 1; }
	DIR="$2"
}

overwrite_alias(){
	local ALIAS DIR MSG
	ALIAS=$1; DIR=$2
	MSG="Do you want to overwrite bookmark \"$ALIAS\""
	
	has_record "$ALIAS" 1>/dev/null && warning "$MSG" &&
	sed -i "/\b$ALIAS\b/d" "$RWD_ALIASES"
	
	[ "$DIR" ] && echo -e "$ALIAS\t$DIR" >> "$RWD_ALIASES"
}

delete_alias(){
	local ALIAS MSG
	ALIAS=$1
	MSG="Do you want to remove all bookmarks?"

	[ ! -s "$RWD_ALIASES" ] && { echo "Nothing to delete."; return 1; }
	[ "$ALL" ] && [ "$(warning "$MSG")" ] &&
	{ > $RWD_ALIASES; return 0; }
	
	SILIENT=True
	[ "$ALIAS" = "$DEFAULT_ALIAS" ] &&
	sed -i '$d' "$RWD_ALIASES" ||
	sed -i "/\b$ALIAS\b/d" "$RWD_ALIASES"
}

mark_exit(){
	SILIENT=True
	overwrite_alias "$ALIAS" "$(pwd)"
	exit 3
}

list_alias(){
	[ ! -s "$RWD_ALIASES" ] && { echo "Nothing to list."; return 1; }
	if [ "$ALL" = True ]; then
		cat $RWD_ALIASES | format | column -t -s$'\t'
	elif [ "$ALIAS" != "$DEFAULT_ALIAS" ]; then
		echo "$(has_record "$ALIAS")" | format
	else
		echo "$(tail -n 1 "$RWD_ALIASES")" | format
	fi
}

warning(){
	local MSG
	[ "$SILIENT" ] && return 0;
	MSG=$(echo "$1 (y/n)? " | format)
	while :
	do
		read -p "$MSG" RESPONSE
		case $RESPONSE in
			[yY]) 	return 0;;
			[nN])	return 1;;
		esac
	done
}

has_record(){
	local ALIAS RESULT
	ALIAS="$1"
	RESULT=$(grep -w "$ALIAS" "$RWD_ALIASES") && echo "$RESULT" ||
	{ echo "Bookmark \"$ALIAS\" not found." | format; return 1; }
}

format(){
	cat | sed "s@$ALIAS_HEADER@@g"
}

set_last(){
	local ALIAS ALIAS_DIR
	ALIAS="$1"; ALIAS_DIR="$2"
 	delete_alias "$ALIAS"
	echo -e "$ALIAS_DIR" >> "$RWD_ALIASES"
}

exec_alias(){
	[ -s "$RWD_ALIASES" ] || { echo "No bookmarks found."; return 1; }
	
	MSG=$(has_record "$ALIAS")
	if [[ $? -ne 0 ]]; then
		if [ "$ALIAS" != "$DEFAULT_ALIAS" ]; then
			echo "$MSG"
			return 1
		else
			MSG=$(tail -n 1 "$RWD_ALIASES")
			SPLIT_MSG=($MSG)
			ALIAS="${SPLIT_MSG[0]}"
		fi
	fi

	set_last "$ALIAS" "$MSG"
	[ "$ALIAS" = "$DEFAULT_ALIAS" ] && delete_alias "$ALIAS"
	echo ${MSG#"$ALIAS	"}
	return 2
}

setup(){
	get_rwd_aliases "$RWD_PATH"
	exec 3<"$RWD_ALIASES"
	parse_args "$@"
}

teardown(){
	exec 3<&-
}

src_rwd(){
	RWD_PATH=$1
	shift 1
	setup "$@"
	
	if [ "$EXIT" ]; then
		mark_exit
	elif [ "$LIST" ]; then
		list_alias
	elif [ "$DELETE" ]; then
		delete_alias "$ALIAS"
	elif [ "$DIR" ]; then
		overwrite_alias "$ALIAS" "$DIR"
	else
		exec_alias
	fi
}
