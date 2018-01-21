#!/bin/bash

# this script does very simple things
# reading it before executing it
# is a good idea

# make sure that it is running as root
if [[ $EUID -ne 0 ]]; then
   echo 'This script must be run as root';
   exit 1
fi

# make sure that mrtg has been installed
if [[ ! -f /usr/bin/mrtg ]] ; then
    echo 'mrtg binary "/usr/bin/mrtg" does not exist, aborting.';
    echo 'please make sure that you have correctly installed mrtg by typing';
    echo 'apt-get install mrtg';
    exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# install those config files
mkdir -p /etc/mrtg
mkdir -p /var/log/mrtg/
cp $DIR/cpu.cfg /etc/mrtg/
cp $DIR/mrtg.cpu.sh /etc/mrtg/
env LANG=C mrtg /etc/mrtg/cpu.cfg
#  env LANG=C mrtg /etc/mrtg/cpu-mem-traffic.cfg --logging /var/log/mrtg/mrtg.log

env LANG=C /usr/bin/mrtg


# generate index in destination folder
mkdir -p /var/mrtg

env LANG=C /usr/bin/indexmaker --output=/var/mrtg/index.html \
--title="idunn usage" \
--sort=name \
--enumerate \
/etc/mrtg/mrtg.cfg \
/etc/mrtg/cpu.cfg \
/etc/mrtg/mem.cfg \
/etc/mrtg/traffic.cfg \
/etc/mrtg/disk.cfg \
/etc/mrtg/temp.cfg \

# add to cron
# using this technique
# https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor
# write out current crontab
crontab -l > mycron.tmp
# every 5 minutes, check cpu, memory and traffic
# every half an hour, check disk
# every hour, check temperature

echo "*/5 * * * * env LANG=C mrtg /etc/mrtg/cpu-mem-traffic.cfg --logging /var/log/mrtg/mrtg.log >/dev/null 2>&1" >> mycron.tmp
echo "*/30 * * * * env LANG=C mrtg /etc/mrtg/disk.cfg --logging /var/log/mrtg/mrtg.log >/dev/null 2>&1" >> mycron.tmp
echo "1 * * * * env LANG=C mrtg /etc/mrtg/temp.cfg --logging /var/log/mrtg/mrtg.log >/dev/null 2>&1" >> mycron.tmp

#install new cron file
crontab mycron.tmp
rm mycron.tmp
