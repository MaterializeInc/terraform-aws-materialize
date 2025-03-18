#!/bin/bash
set -xe

echo "Starting NVMe disk setup"

yum install -y lvm2

ROOT_PART=$(findmnt -n -o SOURCE / | sed 's/\[.*\]//')
ROOT_DEVICE=$(lsblk -no PKNAME "$ROOT_PART")
ROOT_DEVICE="/dev/${ROOT_DEVICE}"

NVME_DEVICES=()

for dev in /dev/nvme*n1; do
  if [ "$dev" != "$ROOT_DEVICE" ] && [ -b "$dev" ]; then
    NVME_DEVICES+=("$dev")
  fi
done

echo "Found NVMe devices: ${NVME_DEVICES[@]:-none}"

if [ ${#NVME_DEVICES[@]} -eq 0 ]; then
  echo "No NVMe instance storage devices found"
  exit 0
fi

for device in "${NVME_DEVICES[@]}"; do
  pvcreate -f "$device"
done

vgcreate instance-store-vg "${NVME_DEVICES[@]}"

pvs
vgs

echo "Disk setup completed"
