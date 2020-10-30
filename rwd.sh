# Copyright (c) 2020, Vincent Mai, http://jiawei.vincent.mai@gmail.com
# All rights reserved.

# rwd source functions
# Author: Vincent Mai
# Version: 0.1.0

ALIAS_LEN=4
ALIAS_HEADER="rwd_"
DEFAULT_ALIAS="$ALIAS_HEADER%tmp"
DEFAULT_ARCHIVE=".rwd_aliases"

# finds or create an archival file 
get_rwd_aliases(){
	RWD_PATH="$1"
	RWD_ALIASES="$RWD_PATH/$DEFAULT_ARCHIVE"
	[ -f "$RWD_ALIASES" ] || touch "$RWD_ALIASES"
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
			?)  echo "Unknown option: $OPTARG"; return 1;;
		esac
		ARG_SHIFT=1
	done
	if [ "$ARG_SHIFT" = 1 ]; then
		validate_opts
	fi
}

validate_opts(){
	[ $LIST ] || [ $DELETE ] || [ $EXIT ] && return 0
	[ ! $ALL ] && return 0
	MSG="Optional command error. Please specify one: "
	MSG="${MSG} -l [list], -d [delete], or -e [exit]."
	echo $MSG; return 1;
}

parse_args(){
	parse_opts "$1" &&
	{ shift $((ARG_SHIFT)); create_alias "$@"; } &&
	create_dir "$@" ||
	return 1
}

create_alias(){
	[ $1 ] && [[ "$1" =~ [^a-zA-Z0-9] ]] &&
	{ echo "Invalid characters. Must be alphanumeric."; return 1; }
	[ ${#1} -gt $ALIAS_LEN ] &&
    { echo "Pleease limit Bookmarks to $ALIAS_LEN characters."; return 1; }
	[ $1 ] && ALIAS="$ALIAS_HEADER$1" || ALIAS="$DEFAULT_ALIAS" 
}

create_dir(){
	if [ "$2" = "." ]; then
		DIR=$(pwd)
	elif [ "$2" = ".." ]; then
		DIR=$(dirname $(pwd))
	elif [ "$2" ] && [ ! -d "$2" ]; then
		echo "Directory \"$2\" does not exist."
		return 1
	else
		DIR="$2"
	fi
}
	
overwrite_alias(){
	ALIAS=$1; DIR=$2
	MSG="Do you want to overwrite bookmark \"$ALIAS\""
	
	has_record "$ALIAS" 1>/dev/null && warning "$MSG" &&
	sed -i "/$ALIAS/d" "$RWD_ALIASES"
	
	[ "$DIR" ] && echo -e "$ALIAS\t$DIR" >> "$RWD_ALIASES"
}

delete_alias(){
	ALIAS=$1
	if [ ! -s "$RWD_ALIASES" ]; then
		echo "Nothing to delete."
		return 1
	fi
	if [ "$ALL" = True ]; then
		MSG="Do you want to remove all bookmarks?"
		if [ "$(warning "$MSG")" = True ]; then
			> $RWD_ALIASES
		fi
	else
		SILIENT=True
		if [ "$ALIAS" != "$DEFAULT_ALIAS" ]; then
			sed -i "/$ALIAS/d" "$RWD_ALIASES"
		else
			sed -i '$d' "$RWD_ALIASES"
		fi
	fi
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
	[ "$SILIENT" ] && { echo True; return 0; }
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
	ALIAS="$1"
	RESULT=$(grep "$ALIAS" "$RWD_ALIASES") && echo "$RESULT" ||
	{ echo "Bookmark \"$ALIAS\" not found." | format; return 1; }
}

format(){
	cat | sed "s@$ALIAS_HEADER@@g"
}

set_last(){
	ALIAS="$1"; ALIAS_DIR="$2"
 	delete_alias "$ALIAS" || return 1
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
	# TODO: change to cd ... ; return 0
	echo ${MSG#"$ALIAS	"}
	return 2
}

setup(){
	get_rwd_aliases "$RWD_PATH"
	exec 3<"$RWD_ALIASES"
	parse_args "$@" || return 1
}

teardown(){
	exec 3<&-
}

src_rwd(){
	RWD_PATH=$1
	shift 1
	setup "$@" || return 1

	if [ "$EXIT" ]; then
		mark_exit
	elif [ "$LIST" ]; then
		list_alias || return 1
	elif [ "$DELETE" ]; then
		delete_alias "$ALIAS" || return 1
	elif [ "$DIR" ]; then
		overwrite_alias "$ALIAS" "$DIR"
	else
		exec_alias
	fi
}
