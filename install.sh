#!/usr/bin/bash
# Copyright (c) 2020 Vincent Mai
# Email: jiawei.vincent.mai@gmail.com

# rwd installation file
# Version: 0.5.0

BASHRC=$(eval echo "~/.bashrc")
CONFIG="\n# rwd for directory bookmarking\
	    \n. "$PWD/rwd.sh"\
		\n# launch last opened rwd path\
		\nrwd"

install() {
	while [ ! -f "$BASHRC" ]; do
		echo "Failed to locate .bashrc"
		read -p "Please provide path: " RESPONSE
		BASHRC=$(eval echo "$RESPONSE")
	done
	echo "$CONFIG" >> "$BASHRC"
	exec bash
}

install
