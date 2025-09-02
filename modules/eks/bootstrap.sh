#!/bin/bash
set -xeuo pipefail

echo "Starting NVMe disk setup"

# Install required tools
yum install -y nvme-cli lvm2

# Check if NVMe instance storage is available
if ! nvme list | grep -q "Amazon EC2 NVMe Instance Storage"; then
  echo "No NVMe instance storage devices found"
  exit 0
fi

# Collect NVMe instance storage devices
mapfile -t SSD_NVME_DEVICE_LIST < <(nvme list | grep "Amazon EC2 NVMe Instance Storage" | awk '{print $1}' || true)

echo "Found NVMe devices: ${SSD_NVME_DEVICE_LIST[*]:-none}"

if [ ${#SSD_NVME_DEVICE_LIST[@]} -eq 0 ]; then
  echo "No usable NVMe instance storage devices found"
  exit 0
fi

# Create physical volumes
for device in "${SSD_NVME_DEVICE_LIST[@]}"; do
  mkswap "$device"
  swapon "$device"
done

echo "Disk setup completed"

modprobe zram
zramctl /dev/zram0 --algorithm zstd --size "$(($(grep -Po 'MemTotal:\s*\K\d+' /proc/meminfo)/2))KiB"
mkswap /dev/zram0
swapon --discard --priority 100 /dev/zram0

echo "ram setup completed"
