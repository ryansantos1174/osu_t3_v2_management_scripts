#!/bin/bash
#
# ==============================================================
# How to use this script:
#
#   1. Make executable:
#        chmod +x edit-vnfs.sh
#
#   2. List available VNFS images:
#        ls /opt/ohpc/admin/images
#
#   3. Enter and edit a VNFS image:
#        ./edit-vnfs.sh almalinux9.3-interactive
#        ./edit-vnfs.sh almalinux9.3-grid
#        ./edit-vnfs.sh almalinux9.2
#
#   4. When you exit the chroot:
#        - /proc, /sys, /dev are automatically unmounted
#        - wwvnfs --chroot <image> is automatically run
#          to regenerate the VNFS image used by Warewulf 3
#
#   This ensures:
#        Your edits become persistent on compute/interactive nodes.
#
# ==============================================================

set -euo pipefail

IMAGES_DIR="/opt/ohpc/admin/images"

usage() {
    echo "Usage: $0 <image-name>"
    echo "Example: $0 almalinux9.3-interactive"
    echo "Available images:"
    ls "$IMAGES_DIR"
    exit 1
}

# Must supply an image name
[[ $# -eq 1 ]] || usage

IMAGE_NAME="$1"
IMAGE_PATH="$IMAGES_DIR/$IMAGE_NAME"

# Validate that the image exists
if [[ ! -d "$IMAGE_PATH" ]]; then
    echo "Error: $IMAGE_PATH does not exist."
    usage
fi

# Paths to bind
BIND_POINTS=( "proc" "sys" "dev" )

mount_bind() {
    local src="/$1"
    local dst="$IMAGE_PATH/$1"

    if ! mountpoint -q "$dst"; then
        echo "Mounting $src → $dst"
        mount --bind "$src" "$dst"
    else
        echo "$dst already mounted."
    fi
}

umount_bind() {
    local dst="$IMAGE_PATH/$1"

    if mountpoint -q "$dst"; then
        echo "Unmounting $dst"
        umount "$dst"
    else
        echo "$dst not mounted."
    fi
}

cleanup() {
    echo "Cleaning up mounts..."
    for p in "${BIND_POINTS[@]}"; do
        umount_bind "$p"
    done

    echo
    echo "Regenerating VNFS image using wwvnfs..."
    echo "Running: wwvnfs --chroot $IMAGE_PATH"
    echo

    if wwvnfs --chroot "$IMAGE_PATH"; then
        echo "VNFS image for $IMAGE_NAME successfully rebuilt."
    else
        echo "ERROR: wwvnfs failed! Your changes may not be propagated."
        exit 1
    fi

    echo "Done."
}

# Ensure cleanup happens on exit, Ctrl+C, and errors
trap cleanup EXIT

# Mount everything
for p in "${BIND_POINTS[@]}"; do
    mount_bind "$p"
done

echo "Entering chroot → $IMAGE_NAME"
echo "Make your edits, then exit to automatically unmount and regenerate VNFS."
echo

chroot "$IMAGE_PATH" /bin/bash

echo "Exited chroot."
# Script now proceeds to cleanup() automatically

