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
	if [ ! -f "$RWD_ALIASES" ]; then
		touch "$RWD_ALIASES"
	fi
}

parse_opts(){
	ARG_SHIFT=0
	while getopts :asdelp OPTION
	do
		case $OPTION in
			a)	ALL=True;;
			s)	SILIENT=True;;
			d)	DELETE=True;;
			e)	EXIT=True;;
			l)	LIST=True;;
			?)  echo "unknown option: $OPTARG"; exit 1;;
		esac
		ARG_SHIFT=1
	done
}

parse_args(){
	parse_opts "$@"
	shift $((ARG_SHIFT))
	create_alias "$@"
	create_dir "$@"
}

create_alias(){
	if [ $1 ] && [[ "$1" =~ [^a-zA-Z0-9] ]]; then
		echo "Invalid characters. Please use an alphanumeric string."
		exit 1
	elif [ ${#1} -gt $ALIAS_LEN ]; then
		echo "Please limit bookmarks to $ALIAS_LEN characters."
		exit 1
	elif [ ! "$1" ]; then
		ALIAS="$DEFAULT_ALIAS"
	else
		ALIAS="$ALIAS_HEADER$1"
	fi
}

create_dir(){
	if [ "$2" = "." ]; then
		DIR=$(pwd)
	elif [ "$2" = ".." ]; then
		DIR=$(dirname $(pwd))
	elif [ "$2" ] && [ ! -d "$2" ]; then
		echo "Directory $2 does not exist."
		exit 1
	else
		DIR="$2"
	fi
}
	
overwrite_alias(){
	ALIAS=$1; DIR=$2
	MSG="Do you want to overwrite existing $ALIAS"
	if [ "$(grep "$ALIAS" "$RWD_ALIASES")" ]; then
		ACTION=$(warning "$MSG")
		if [ ! $ACTION ]; then
			exit 0
		else
 			sed -i "/$ALIAS/d" "$RWD_ALIASES"
		fi
	fi
	if [ "$DIR" ]; then
		echo -e "$ALIAS\t$DIR" >> "$RWD_ALIASES"
	fi
}

delete_alias(){
	ALIAS=$1
	if [ ! -s "$RWD_ALIASES" ]; then
		echo "Nothing to delete."
		exit 1
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
	if [ ! -s "$RWD_ALIASES" ]; then
		echo "Nothing to list."
		exit 1
	fi
	if [ "$ALL" = True ]; then
		echo "$(sed "s@$ALIAS_HEADER@@g" $RWD_ALIASES)" | column -t -s$'\t'
	elif [ "$ALIAS" != "$DEFAULT_ALIAS" ]; then
		echo "$(get_alias "$ALIAS")" | sed "s@$ALIAS_HEADER@@g"
	else
		echo "$(tail -n 1 "$RWD_ALIASES")" | sed "s@$ALIAS_HEADER@@g"
	fi
}

warning(){
	if [ "$SILIENT" = True ]; then
		echo True
		return 0
	fi
	MSG="$1 (y/n)? ";
	while [ "$RESPONSE" != "q" ]
	do
		read -p "$MSG" RESPONSE
		case $RESPONSE in
			[yY]) 	echo True; return 0;;
			[nN])	exit 0;;
			[qQ]) 	exit 0;;
			*)		MSG="Please enter y/n or q to quit: ";;
		esac
	done
}

get_alias(){
	ALIAS="$1"
	RESULT=$(grep "$ALIAS" "$RWD_ALIASES")
	if [ "$RESULT" ]; then
		echo "$RESULT"
		return 0
	else
		echo "$ALIAS does not exist."
		exit 1
	fi
}

set_last(){
	ALIAS="$1"; ALIAS_DIR="$2"
 	delete_alias "$ALIAS"
	echo -e "$ALIAS_DIR" >> "$RWD_ALIASES"
}

exec_alias(){
	if [ ! -s "$RWD_ALIASES" ]; then
		echo "No directory bookmarks found."
		exit 1
	fi
	MSG=$(get_alias "$ALIAS")
	if [[ $? -ne 0 ]]; then
		if [ "$ALIAS" != "$DEFAULT_ALIAS" ]; then
			echo "$MSG"
			return 1
		else
			MSG=$(tail -n 1 "$RWD_ALIASES")
			SPLIT_MSG=(${MSG// / })
			ALIAS="${SPLIT_MSG[0]}"
		fi
	fi
	set_last "$ALIAS" "$MSG"
	if [ "$ALIAS" = "$DEFAULT_ALIAS" ]; then
		delete_alias "$ALIAS"
	fi
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
	return
}
