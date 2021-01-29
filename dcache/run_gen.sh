#!/bin/bash

for i in {1..100000..5000}
do
	echo "Number $i to $((i + 5000))"
	./gen_files.sh $i $((i + 5000)) a
	read -p "Press key to continue.. " -n1 -s
done
