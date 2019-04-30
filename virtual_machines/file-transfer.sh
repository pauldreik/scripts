#!/bin/bash

usage() {
    echo "Transfers files from virtual machine vm1 to vm2."
    echo "Usage: file-transfer <storage in MB> <vm1> <vm2> [filesystem_type]"
    echo "To see which names are ok, use \"virsh list\""
}

case "$1" in
    -h|--help|help)
	usage
	exit 0
	;;
esac

storage_size=$1
vm1=$2
vm2=$3
filesystem=$4
tmp_storage="/opt/vmtmpstorage/tmp_mount"
host_mntpt="/mnt/guestshare"

if [ -z $filesystem ]; then
    filesystem=ext4
fi

# Must be a number
if [ "${storage_size}" -eq "${storage_size}" ] 2>/dev/null ; then
	bla=1	
else
	echo "[!] Size is not a number"
        usage
	exit 1
fi

# Check if vms exists and are running
if [[ "${vm1}" == "HOST" ]] ; then
	echo "[*] Mounting to host before."
else

	status=$(virsh domstate "${vm1}" 2>&1 || exit)
	if [[ "${status}" == "error:"* ]]
	then
		echo "[!] Domain '${vm1}' doesn't exist." 
		exit 1
	elif [[ "${status}" != "running" ]] 
	then
		echo "[!] Domain '${vm1}' not running."
		exit 1
	fi
fi

if [[ "${vm2}" == "HOST" ]] ; then
	echo "[*] Mounting to host after."
else

status=$(virsh domstate "${vm2}" 2>&1 || exit)
if [[ "${status}" == "error:"* ]]
then
        echo "Domain '${vm2}' doesn't exist." 
        exit 1
elif [[ "${status}" != "running" ]] 
then
	echo "Domain '${vm2}' not running."
	exit 1
fi

fi 

echo "[*] Creating temporary share..."
truncate -s ${storage_size}M ${tmp_storage}
mkfs.$filesystem ${tmp_storage}

#make sure it is readable by default
blah=$(mktemp -d)
mount ${tmp_storage} $blah
chmod 777 $blah
umount ${tmp_storage}
rm -rf $blah

if [ "${vm1}" == "HOST" ]; then
	if [ ! -d ${host_mntpt} ] ; then
		mkdir ${host_mntpt}	
	fi
	echo "[*] Mounting to host at ${host_mntpt}"
	mount ${tmp_storage} ${host_mntpt}
	echo "[!] Press enter to umount from HOST"
	read x
	umount ${host_mntpt}
else
	echo "[*] Attaching disk to ${vm1}"
	virsh attach-disk ${vm1} ${tmp_storage} vdb --targetbus usb --cache none
	echo "[!] Press enter to unmount from ${vm1}"
	read x
	virsh detach-disk ${vm1} ${tmp_storage}
fi

if [ "${vm2}" == "HOST" ]; then
	if [ ! -d ${host_mntpt} ] ; then
		mkdir ${host_mntpt}	
	fi
	echo "[*] Mounting to host at ${host_mntpt}"
	mount ${tmp_storage} ${host_mntpt}
	echo "[!] Press enter to umount from HOST"
	read x
	umount ${host_mntpt}
else
	echo "[*] Attaching disk to ${vm2}"
	virsh attach-disk ${vm2} ${tmp_storage} vdb --targetbus usb --cache none
	echo "[!] Press enter to unmount from ${vm2}"
	read x
	virsh detach-disk ${vm2} ${tmp_storage}
fi

#shred it, but don't be paranoid since we are on an encrypted disk
echo "[*] shredding the disk...."
shred -n1 -u ${tmp_storage}

echo "[*] all done, bye bye"
