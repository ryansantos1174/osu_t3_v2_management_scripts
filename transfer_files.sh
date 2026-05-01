#!/usr/bin/env bash
USERS=(
    abasnet
    czheng
    lnestor
    mcarrigan
    milliqan
#    mjoyce
    rsantos
)
OLD_T3_DATA_PATH="/abyss/users"
NEW_T3_DATA_PATH="/data/user"

for user in "${USERS[@]}"; do
    echo "========================================"
    echo "Starting transfer for user: $user at $(date)"
    echo "========================================"

    # Create directory if it doesn't exist
    if [ ! -d "$NEW_T3_DATA_PATH/$user" ]; then
        mkdir -p "$NEW_T3_DATA_PATH/$user"
    fi

    # Check if user exists on this server
    if id "$user" &>/dev/null; then
        echo "User $user exists, running rsync as $user"
        RSYNC_CMD="su - $user -c 'rsync -av --progress rsantos@128.146.39.20:$OLD_T3_DATA_PATH/${user}/ $NEW_T3_DATA_PATH/$user'"
        eval $RSYNC_CMD
    else
        echo "WARNING: User $user does not exist on this server yet, running as root"
        echo "Remember to run: chown -R $user:users $NEW_T3_DATA_PATH/$user after creating this user"
        rsync -av --progress rsantos@128.146.39.20:$OLD_T3_DATA_PATH/${user}/ "$NEW_T3_DATA_PATH/$user"
    fi

    if [ $? -eq 0 ]; then
        curl -d "Finished transferring $user files to new T3" https://ntfy.sh/OSUT3
    else
        curl -d "Failed to transfer $user files to new T3" https://ntfy.sh/OSUT3
    fi

    echo "Finished transfer for user: $user at $(date)"
done

echo "All transfers complete at $(date)"
