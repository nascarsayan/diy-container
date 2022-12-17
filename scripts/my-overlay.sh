#!/bin/bash
mkdir -p /home/vagrant/ship/overlay/{upper,lower,work,merged}
echo "_lower_" > /home/vagrant/ship/overlay/lower/in_lower.txt 
echo "_upper_" > /home/vagrant/ship/overlay/upper/in_upper.txt
echo "_lower_" > /home/vagrant/ship/overlay/lower/in_both.txt 
echo "_upper_" > /home/vagrant/ship/overlay/upper/in_both.txt
sudo mount -t overlay overlay -o \
lowerdir=/home/vagrant/ship/overlay/lower,\
upperdir=/home/vagrant/ship/overlay/upper,\
workdir=/home/vagrant/ship/overlay/work \
/home/vagrant/ship/overlay/merged