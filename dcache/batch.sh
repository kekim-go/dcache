#!/bin/bash

echo $1 >> delete-result.csv
cat delete-result.csv

rm -rf cache/a
mkdir cache/a
./gen_files.sh 1 $2 a

ls -l ./cache/a | wc -l
