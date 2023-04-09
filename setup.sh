#!/bin/bash
set -e
echo "Setting up rclone_RD"
umount /data/$RCLONE_MOUNT_NAME || true 2>/dev/null
mkdir -p /data/$RCLONE_MOUNT_NAME
touch /config/rclone.config
cat <<EOF > /config/rclone.config
[$RCLONE_MOUNT_NAME]
type = realdebrid
api_key = $RD_API_KEY
EOF
echo "user_allow_other" >> /etc/fuse.conf
echo "Checking rclone_RD flags"
if [[ -n "$RCLONE_MOUNT_NAME" ]];
then echo "Setting the rclone mount name to $RCLONE_MOUNT_NAME";
else echo "Please set a name for the rclone mount" && exit 1;
fi
if [[ -n "$RD_API_KEY" ]];
then echo "Setting the API Key";
else echo "Please set the API Key for the rclone mount" && exit 1;
fi
echo "Starting rclone_rd"
./rclone-linux mount "$RCLONE_MOUNT_NAME": /data/"$RCLONE_MOUNT_NAME" --config /config/rclone.config --allow-other --daemon
echo "Setting up plex_debrid"
FILE=/config/settings.json
if [ ! -f "$FILE" ]; 
then cp /settings-default.json /config/settings.json && python pd_setup.py
else python pd_setup.py	
fi
printf "%s" "Waiting for Plex Server ..."
if ! wget --wait=1 --no-verbose --tries=0 --spider $PLEX_ADDRESS/identity &> /dev/null; then
    while ! wget --wait=1 --no-verbose --tries=0 --spider $PLEX_ADDRESS/identity &> /dev/null
do
    printf "%c" "."
    sleep 1
done
fi
printf "\n%s\n"  "Plex Server is online"
echo "Starting plex_debrid"
python /plex_debrid/main.py --config-dir /config