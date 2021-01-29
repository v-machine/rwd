# rwd (Recent Working Directory)
```

	_________________________________________/\\\__        
	 ________________________________________\/\\\__       
	  ________________________________________\/\\\__      
	   __/\\/\\\\\\\___/\\____/\\___/\\________\/\\\__     
	    _\/\\\/////\\\_\/\\\__/\\\\_/\\\___/\\\\\\\\\__    
	     _\/\\\___\///__\//\\\/\\\\\/\\\___/\\\////\\\__   
	      _\/\\\__________\//\\\\\/\\\\\___\/\\\__\/\\\__  
	       _\/\\\___________\//\\\\//\\\____\//\\\\\\\/\\_ 
	        _\///_____________\///__\///______\///////\//__


```
## Description
A simple command line untility for bash users to quickly bookmark and navigate to recent working directories.

## Install
```
$ git clone https://github.com/v-machine/rwd.git
$ sh install.sh
```

## Usage
```
$ rwd [OPTION...] { <BOOKMARK> | <BOOKMARK> <PATH> }
```
## Options
```
-l	List bookmark(s) and its linked path
-d	Deletes bookmark(s)
-e	Terminate shell and pick up from where you left off
-a	Apply to all bookmarks
-s	Slience all warning messages
```

## Examples
To encourage brevity, the bookmark is limited to 4 alphanumeric characters. Adding `rwd <BOOKMARK> <PATH>` and navigating `rwd <BOOKMARK>` to bookmark require no optional argument. If no arguments are passed, rwd simply navigate to the last used bookmark.

### Adding bookmarks 
```
$ rwd dir1 .
	# bookmark current directory with "dir1"
$ rwd dir2 ..
	# bookmark parent directory with "dir2"
$ rwd prj2 /home/.../project/
	# bookmark "/home/.../project/" with "prj2"
$ rwd prj2 /home/.../new_project/
	# overwrite the path of "prj2"
$ rwd -s prj2 /home/.../new_project/
	# overwrite the path of "prj2" silently
```

### Navigting to bookmarks
```
$ rwd
	# cd to the last used/modified bookmark
$ rwd dir1
	# cd to "dir11"
```

### List Bookmarks
```
$ rwd -l
	# list the last used/modified bookmark and path
$ rwd -l prj2
	# list the bookmark "prj2" and path
$ rwd -la
	# list all bookmarks and paths
```

### Delete Bookmarks
```
$ rwd -d
	# delete (without warning) the last used/modified bookmark and path
$ rwd -d dir1
	# delete the bookmark "prj2" and path
$ rwd -das
	# delete all bookmarks silently
```

### Pick up where last left off
```
$ rwd -e
	# bookmark current directory and terminate shell
	# be in the current directory when relaunching shell
```

## License
Copyright (c) 2020 Vincent Mai

This program can be redistributed freely and/or modified under the terms of the GNU General Public License as published by the Free Software Foundation (version 3 or newer).

## To Do
- Support tab completion for existing bookmarks
- Make character limit modifiable.
- Support copy/move/remove with rwd bookmarks
