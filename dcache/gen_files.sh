#!/bin/bash

echo "usage: ./gen_files.sh start-number end-number folder-name"
echo "./gen_files.sh 1 1000 a"
echo " "

for ((i=$1;i<=$2;i++))
do
        touch ./cache/$3/$i.test
done
