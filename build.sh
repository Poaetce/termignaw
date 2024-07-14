#!/bin/bash
name="termignaw"
directory="build"

mkdir -p $directory

if odin build src -out:"$directory/$name"
then
	echo $directory/$name
else
	exit 1
fi

if [ "$1" = "run" ]
then
	$directory/$name
fi
