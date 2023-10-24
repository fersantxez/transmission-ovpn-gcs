#!/bin/bash
export IMAGE=fernandosanchez/transmission-ovpn-gcs
####DEBUG/TEST CHANGEME
#export MOUNT_PATH="/data/completed"  #GCS HANGS ON BOOT - IS IT B/C IT EXISTS?
export MOUNT_PATH="/test"


# Check if the required number of arguments is provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <BUCKET_NAME> <CREDENTIALS_FILE> <EXPRESSVPN_USERNAME> <EXPRESSVPN_PASSWORD> <UI_PASSWORD>"
    exit 1
fi

# Assign command-line arguments to variables
BUCKET="$1"
CREDENTIALS="$2"
OPENVPN_USERNAME="$3"
OPENVPN_PASSWORD="$4"
TRANSMISSION_RPC_PASSWORD="$5"

# Check if the specified credentials file exists
if [ ! -f "$CREDENTIALS" ]; then
    echo "Credentials file not found: $CREDENTIALS"
    exit 1
fi

# Build the Docker image (if not already built)
if ! docker image ls | grep -q "${IMAGE}"; then
    echo "Building Docker image..."
    docker build -t ${IMAGE} .
fi

echo "bucket name: "$BUCKET
echo "credentials file: "$CREDENTIALS


# Run the Docker container with the specified environment variables
# Mount the bucket in the given mountpoint
docker run \
    --name "xmiss" \
    --rm \
    --privileged \
    --device /dev/fuse \
    -e BUCKET=$BUCKET \
    -e MOUNT_PATH=${MOUNT_PATH} \
    -v ${CREDENTIALS}:/creds/key.json:ro \
    -e CREDENTIALS=/creds/key.json \
    -e CREATE_TUN_DEVICE=true \
    -e WEBPROXY_ENABLED=false \
    -e OPENVPN_PROVIDER="EXPRESSVPN" \
    -e OPENVPN_OPTS="--inactive 3600 --ping 10 --ping-exit 60 --mute-replay-warnings" \
    -e OPENVPN_USERNAME=${OPENVPN_USERNAME} \
    -e OPENVPN_PASSWORD=${OPENVPN_PASSWORD} \
    -e PGID="1000" \
    -e TRANSMISSION_RPC_AUTHENTICATION_REQUIRED=true \
    -e TRANSMISSION_RPC_USERNAME="admin" \
    -e TRANSMISSION_RPC_PASSWORD=${TRANSMISSION_RPC_PASSWORD} \
    -e DROP_DEFAULT_ROUTE=true \
    -e TRANSMISSION_WEB_UI="combustion" \
    -e TRANSMISSION_RPC_BIND_ADDRESS="0.0.0.0" \
    -e TRANSMISSION_RPC_ENABLED=true \
    -e LOCAL_NETWORK=192.168.86.0/24 \
    -p 9091:9091/tcp \
    -p 51413:51413/tcp \
    -p 51413:51413/udp \
    -v config:/config \
    ${IMAGE}

