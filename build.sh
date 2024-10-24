#!/bin/bash
name="termignaw"
directory="build"

mkdir -p $directory

if case "$1" in
	"normal")
		target="${directory}/${name}"
		odin build src -out:${target}
		;;
	"debug")
		target="${directory}/${name}_debug"
		odin build src -debug -out:${target}
		;;
	*)
		exit 1
		;;
esac
then
	echo $target
else
	exit 1
fi

if [ "$2" = "run" ]
then
	$target
fi
