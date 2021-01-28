#!/bin/bash

for ((i=$1;i<=$2;i++))
do
        touch ./cache/$3/$i.test
done
