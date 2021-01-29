#!/usr/bin/bash
# Copyright (c) 2020 Vincent Mai
# Email: jiawei.vincent.mai@gmail.com

# rwd [recent working directory]
# Version: 0.5.0

# find .rwd_aliases or create one
get_rwd_aliases(){
	RWD_ARCHIVE="$RWD_PATH/$DEFAULT_ARCHIVE"
	[ -f "RWD_ARCHIVE" ] || touch "$RWD_ARCHIVE"
}

# parses optional commands
parse_opts(){
	ARG_SHIFT=0; OPTIND=1  # need to reset OPTIND
	while getopts ":asdel" OPTION
	do
		case ${OPTION} in
			a) ALL=true;;
			s) SILENT=true;;
			d) DELETE=true;;
			e) EXIT=true;;
			l) LIST=true;;
			?) echo "Unknown option: $OPTARG"; exit 1;;
		esac
		ARG_SHIFT=1
	done
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
	DIR=${DIR/../$(dirname $PWD)} 
	DIR=${DIR/./$PWD}
	[ "$2" ] && [ ! -d "$DIR" ] &&
	{ echo "Directory \"$DIR\" does not exist."; exit 1; }
}

parse_args(){
	parse_opts $@;
	shift $(($ARG_SHIFT))
	init_alias $@
	init_dir $@
}

# displays warnings and overwrites an alias
overwrite_alias(){
	local ALIAS DIR MSG
	ALIAS=$1; DIR=$2
	MSG="Do you want to overwrite bookmark \"$ALIAS\""
	
	(has_record "$ALIAS" 1>/dev/null) && (warning "$MSG") &&
	sed -i "/\b$ALIAS\b/d" "$RWD_ARCHIVE"
	
	[ "$DIR" ] && echo -e "$ALIAS\t$DIR" >> "$RWD_ARCHIVE"
}

# displays warnings and deletes alias(es)
delete_alias(){
	local ALIAS MSG
	ALIAS=$1
	MSG="Do you want to remove"

	[ ! -s "$RWD_ARCHIVE" ] && { echo "Nothing to delete."; return 1; }
	[ "$ALL" ] && $(warning "${MSG} all bookmarks") &&
	{ > $RWD_ARCHIVE; return 0; }

	[ "$ALIAS" != "$DEFAULT_ALIAS" ] && 
	$(warning "$MSG \"$ALIAS\" bookmark") &&
	sed -i "/\b$ALIAS\b/d" "$RWD_ARCHIVE" ||
	sed -i '$d' "$RWD_ARCHIVE"
}

# temporarily save pwd and exit
mark_exit(){
	SILENT=True
	overwrite_alias "$ALIAS" "$PWD"
	echo "exit 0"
	exit 121
}

# list one or all stored aliases
list_alias(){
	[ ! -s "$RWD_ARCHIVE" ] && { echo "Nothing to list."; exit 1; }
	if [ $ALL ]; then
		cat $RWD_ARCHIVE | format | column -t -s$'\t'
	elif [ "$ALIAS" != "$DEFAULT_ALIAS" ]; then
		echo "$(has_record "$ALIAS")" | format
	else
		echo "$(tail -n 1 "$RWD_ARCHIVE")" | format
	fi
}

# displays a warning message and request user input
warning(){
	local MSG
	[ $SILENT ] && return 0;
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
	RESULT=$(grep -w "$ALIAS" "$RWD_ARCHIVE") && echo "$RESULT" ||
	{ echo Bookmark \"$ALIAS\" not found. | format; return 1; }
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
	echo -e "$ALIAS_DIR" >> "$RWD_ARCHIVE"
}

# execute default command (create new alias or change directory)
exec_alias(){
	[ -s "$RWD_ARCHIVE" ] || { echo No bookmarks found.; return 1; }
	
	MSG=$(has_record "$ALIAS")
	if [[ $? -ne 0 ]]; then
		if [ "$ALIAS" != "$DEFAULT_ALIAS" ]; then
			echo "$MSG"
			return 1
		else
			MSG=$(tail -n 1 "$RWD_ARCHIVE")
			SPLIT_MSG=($MSG)
			ALIAS="${SPLIT_MSG[0]}"
		fi
	fi
	SILENT=True
	set_last "$ALIAS" "$MSG"
	[ "$ALIAS" = "$DEFAULT_ALIAS" ] && delete_alias "$ALIAS"
	echo cd \"${MSG#"$ALIAS	"}\"
	exit 121
}

setup(){
	get_rwd_aliases "$RWD_PATH"
	exec 3<"$RWD_ARCHIVE" # assigns to File Descriptor 3
	parse_args "$@"
}

teardown(){
	exec 3<&-
}

# rwd main program
main(){
	EXPORT=true
	ALIAS_LEN=4
	ALIAS_HEADER="rwd_"
	DEFAULT_ALIAS="$ALIAS_HEADER%tmp"
	DEFAULT_ARCHIVE=".rwd_aliases"
	RWD_PATH="$PWD"
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
	teardown
}

clean_up(){
	GLOBAL_ARGS=(EXPORT RETURN)
	for ARG in ${GLOBAL_ARGS[@]}
	do
		unset -v $ARG
	done
}

# forward commands from subshell to current shell
rwd(){
	RETURN=$(main $@)
	[ "$?" -eq 121 ] && EXPORT=true
	[ "$EXPORT" = "true" ] && eval "$RETURN" || echo "$RETURN"
	clean_up
}

# opens file windows file explorer from pwd
goto(){
	explorer.exe .
}
