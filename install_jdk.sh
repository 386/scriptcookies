#!/bin/bash
JDK_BIN_PATH=/usr/local/lib/jdk1.7.0_45/bin
for x in $(find $JDK_BIN_PATH)
do
    name=$(basename $x)
    sudo update-alternatives --install /usr/bin/$name $name $x 300
done
