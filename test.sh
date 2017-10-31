#!bin/bash

# $1 = EXECUTE_WITH_STRACES
# $2 = NUMBER_OF_PROCESSES

rm log* > /dev/null 2> /dev/null || true

if [ $1 -eq 1 ] 
then
    for (( i=1; i <= $2; i++ ))
    do
    strace -e trace=ipc,write -fv -ttt ./kernel_bug 2> ./log_$i &
    done
else
    for (( i=1; i <= $2; i++ ))
    do
    ./kernel_bug &
    done
fi
