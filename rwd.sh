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

# find .rwd_aliases or create one
get_rwd_aliases(){
	RWD_PATH="$1"
	RWD_ALIASES="$RWD_PATH/$DEFAULT_ARCHIVE"
	[ -f "$RWD_ALIASES" ] || touch "$RWD_ALIASES"
}

# parses command arguments
parse_args(){
	parse_opts "$1"
	shift $((ARG_SHIFT))
	init_alias "$@"
	init_dir "$@"
}

# parses optional commands
parse_opts(){
	ARG_SHIFT=0
	while getopts :asdel OPTION
	do
		case $OPTION in
			a)	ALL=True;;
			s)	SILENT=True;;
			d)	DELETE=True;;
			e)	EXIT=True;;
			l)	LIST=True;;
			?)  echo "Unknown option: $OPTARG"; exit 1;;
		esac
		ARG_SHIFT=1
	done
	[ "$ARG_SHIFT" = 1 ] && validate_opts
}

# validates optional commands
validate_opts(){
	local MSG
	[ "$LIST" ] || [ "$DELETE" ] || [ "$EXIT" ] && return 0
	MSG="Please specify an optional command: "
	MSG="$MSG -l [list], -d [delete], or -e [exit]."
	echo $MSG; exit 1;
}

# validates user input and initialize an alias (with a header)
init_alias(){
	[ $1 ] && [[ "$1" =~ [^a-zA-Z0-9] ]] &&
	{ echo "Invalid characters. Must be alphanumeric."; exit 1; }
	[ ${#1} -gt $ALIAS_LEN ] &&
    { echo "Pleease limit Bookmarks to $ALIAS_LEN characters."; exit 1; }
	[ $1 ] && ALIAS="$ALIAS_HEADER$1" || ALIAS="$DEFAULT_ALIAS" 
}

# parses and validate user input to initialize a directory
init_dir(){
	DIR="$2"
	DIR=${DIR/../$(dirname $(pwd))} 
	DIR=${DIR/./$(pwd)} 
	[ "$2" ] && [ ! -d "$DIR" ] &&
	{ echo "Directory \"$DIR\" does not exist."; exit 1; }
}

# displays warnings and overwrites an alias
overwrite_alias(){
	local ALIAS DIR MSG
	ALIAS=$1; DIR=$2
	MSG="Do you want to overwrite bookmark \"$ALIAS\""
	
	(has_record "$ALIAS" 1>/dev/null) && (warning "$MSG") &&
	sed -i "/\b$ALIAS\b/d" "$RWD_ALIASES"
	
	[ "$DIR" ] && echo -e "$ALIAS\t$DIR" >> "$RWD_ALIASES"
}

# displays warnings and deletes alias(es)
delete_alias(){
	local ALIAS MSG
	ALIAS=$1
	MSG="Do you want to remove"

	[ ! -s "$RWD_ALIASES" ] && { echo "Nothing to delete."; return 1; }
	[ "$ALL" ] && $(warning "${MSG} all bookmarks") &&
	{ > $RWD_ALIASES; return 0; }

	[ "$ALIAS" != "$DEFAULT_ALIAS" ] && 
	$(warning "$MSG \"$ALIAS\" bookmark") &&
	sed -i "/\b$ALIAS\b/d" "$RWD_ALIASES" ||
	sed -i '$d' "$RWD_ALIASES"
}

# temporarily save pwd and exit
mark_exit(){
	SILENT=True
	overwrite_alias "$ALIAS" "$(pwd)"
	exit 3
}

# list one or all stored aliases
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

# displays a warning message and request user input
warning(){
	local MSG
	[ "$SILENT" ] && return 0;
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

# echos the found alias_dir record or return an error
has_record(){
	local ALIAS RESULT
	ALIAS="$1"
	RESULT=$(grep -w "$ALIAS" "$RWD_ALIASES") && echo "$RESULT" ||
	{ echo "Bookmark \"$ALIAS\" not found." | format; return 1; }
}

# format internal repr of alias to be printable
format(){
	cat | sed "s@$ALIAS_HEADER@@g"
}

# move the given alias to last in the stored record
set_last(){
	local ALIAS ALIAS_DIR
	ALIAS="$1"; ALIAS_DIR="$2"
 	delete_alias "$ALIAS"
	echo -e "$ALIAS_DIR" >> "$RWD_ALIASES"
}

# execute default command (create new alias or change directory)
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
	SILENT=True
	set_last "$ALIAS" "$MSG"
	[ "$ALIAS" = "$DEFAULT_ALIAS" ] && delete_alias "$ALIAS"
	echo ${MSG#"$ALIAS	"}
	return 2
}

setup(){
	get_rwd_aliases "$RWD_PATH"
	exec 3<"$RWD_ALIASES" # assigns to File Descriptor 3
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
