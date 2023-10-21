#!/usr/bin/env bash

# gcsfuse: mount a GCS bucket to a local directory

# every exit != 0 fails the script
#set -e

# Print commands as executed:
#set -x

# =============================================================================
# Default values, arguments as env variables
# =============================================================================

#BUCKET=fake=bucket-name #name of the bucket to sync from 
#MOUNT_PATH=/share #path to mount on inside container (mount as volume for host)
#CREDS=/key/key.json

# =============================================================================
# Pretty colours
# =============================================================================

RED='\033[0;31m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# =============================================================================
# Banner
# =============================================================================

echo -e "${BLUE}
 ___ ___ ___ ___ ___ _ _ ___ ___ 
|   | . |_ -| -_|  _| | | -_|  _|
|_|_|___|___|___|_|  \_/|___|_|  
${NC}"


# =============================================================================
# Functions
# =============================================================================

# Prefixes output and writes to STDERR:
error() {
	echo -e "\n\n${RED}$(basename $0) error${NC}: $@\n" >&2
	print_usage
	exit 1 #Exit on error
}

# Display a formatted message to shell:
message() {
	echo -e "\n** $@" >&2
}

# Display a formatted WARNING message to shell:
warning() {
	echo -e "\n\n${RED}$(basename $0) warning${NC}: $@\n" >&2
}

# Ask for user input and return the validated response:
input() {
	#redirect echo to >&2 so that it doesnt return this
	echo -e "\n${BLUE}** ${@}${NC}" >&2
	read -p "" user_input
	#return string through echo
	echo $user_input
}

# Checks for command presence in $PATH, errors:
check_command() {
	TESTCOMMAND=$1
	HELPTEXT=$2

	printf '%-50s' " - $TESTCOMMAND..."
	command -v $TESTCOMMAND >/dev/null 2>&1 || {
		echo "${RED}[ MISSING ]${NC}"
		error "The '$TESTCOMMAND' command was not found. $HELPTEXT"
		exit 1
	}
	echo "[ OK ]"
}

# Due to the interesting locking behavior of /var/lib/dpkg/lock and `flock`,
# let's intercept the requested call in this function block, and perform the
# necessary waiting. dpkg might be running on newly-spawned machines as part
# of initialization protocols, so catch that case here (should run once): 
apt_catch() {
    # Rather than attempt an elaborate process inspection, simply run the
    # command until it works. If it doesn't, there's another issue:
    until [ $(apt-get $@ > /dev/null 2>&1)$? -eq 0 ]; do
        echo "Waiting for APT/DPKG lock..."
        sleep 1;
    done
}
# =============================================================================
# Argument validation and correction
# =============================================================================

#Ensure all parameters are passed as env variables
# List of mandatory parameters:
REQUIRED_PARAMS="
	BUCKET
	MOUNT_PATH
	CREDENTIALS
"

for PARAM in $REQUIRED_PARAMS; do
	if [ -z "${!PARAM}" ]; then
		# It's empty and needs to be defined:
		printf '%-50s' " + $PARAM"
		echo "[ OFF ]"
		#assing a value for each $PARAM
		#export "$PARAM"=$(input "Enter a value for ${PARAM}:" )
        error "Missing value for "$PARAM
	else
		# It's already defined:
		#DEBUG - show passed CLI parameters
		printf '%-50s' " - $PARAM is :"${!PARAM}
		echo "[ ON ]"
	fi
done

# =============================================================================
# Set up local filesystem
# =============================================================================

# MOUNT_PATH: ensure it exists. Not needed with launcher script
mkdir -p $MOUNT_PATH
if [ ! -d "$MOUNT_PATH" ]; then 
	error "Local directory $MOUNT_PATH not found"
fi


# validate credentials file exists
if [ ! -f "$CREDENTIALS" ]; then 
	error "Credentials file $CREDENTIALS not found. Please mount as docker volume"
fi

# =============================================================================
# Mount GCS bucket
# =============================================================================

gcsfuse \
	-o allow_other \
	--key-file $CREDENTIALS \
	--implicit-dirs \
	--stat-cache-ttl 1h \
	--dir-mode 777 \
	${BUCKET} \
	${MOUNT_PATH} && \
  echo -e "Bucket gs://"${BUCKET}" mounted on "${MOUNT_PATH}
 
#    -o nonempty #ERRORS OUT: deprecated?
#	--debug_fuse #ERRORS OUT: deprecated?


# =============================================================================
# Start openvpn
# =============================================================================

sh -c /etc/openvpn/start.sh
