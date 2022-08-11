#!/bin/bash

mkdir -m 777 /home/debian/sappho-pda/Code/Build
chmod -R 777 /home/debian/sappho-pda
rm /home/debian/sappho-pda/Samples/README.md

#rm /lib/firmware/sappho-pda-00A0.dtbo
#dtc -O dtb -o sappho-pda-00A0.dtbo -b 0 -@ sappho-pda.dts
#sudo cp sappho-pda-00A0.dtbo /lib/firmware
#echo "Activating SAPPHO cape..."
#modprobe uio_pruss
#echo sappho-pda > /sys/devices/platform/bone_capemgr/slots
#sleep .5
#echo "uio_pruss and SAPPHO cape enabled."

pasm -b /home/debian/sappho-pda/Code/PRU/PRU0.p
sleep .1
pasm -b /home/debian/sappho-pda/Code/PRU/PRU1.p
sleep .1
mv PRU0.bin /home/debian/sappho-pda/Code/PRU/
sleep .1
mv PRU1.bin /home/debian/sappho-pda/Code/PRU/
sleep .1
echo "PRU code assembled."

cp /home/debian/sappho-pda/Tools/motd /etc/
cp sapphocape.service /etc/systemd/system
chmod u+x capeMod.sh
systemctl start sapphocape.service
systemctl enable sapphocape.service
systemctl stop sapphocape.service

echo "Installation complete!"
