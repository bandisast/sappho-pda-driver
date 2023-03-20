#!/bin/bash
rm /lib/firmware/sappho-pda-00A0.dtbo
dtc -O dtb -o /home/debian/sappho-pda/Tools/sappho-pda-00A0.dtbo -b 0 -@ /home/debian/sappho-pda/Tools/sappho-pda.dts
sudo cp /home/debian/sappho-pda/Tools/sappho-pda-00A0.dtbo /lib/firmware
echo "Activating SAPPHO cape..."
modprobe uio_pruss
echo sappho-pda > /sys/devices/platform/bone_capemgr/slots
sleep .5
echo "uio_pruss and SAPPHO cape enabled."


