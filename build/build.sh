# !/bin/bash
name="termignaw"
directory="build/output"

mkdir -p $directory

odin build src -out:$directory/$name

echo $directory/$name

if [ "$1" = "run" ]
then
	$directory/$name
fi
