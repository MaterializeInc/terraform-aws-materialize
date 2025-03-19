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
  pvcreate -f "$device"
done

# Create volume group
vgcreate instance-store-vg "${SSD_NVME_DEVICE_LIST[@]}"

# Display results
pvs
vgs

echo "Disk setup completed"
