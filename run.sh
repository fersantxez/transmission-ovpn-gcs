export VPN_USERNAME=$(cat ~/.ssh/./expressvpn_username.txt)
export VPN_PASSWORD=$(cat ~/.ssh/./expressvpn_password.txt)
export BUCKET=nodesktop
export CREDENTIALS=~/.ssh/creds.json
export UI_PASSWORD="nopassword"

./run_docker.sh \
    ${BUCKET} \
    ${CREDENTIALS} \
    ${VPN_USERNAME} \
    ${VPN_PASSWORD} \
    ${UI_PASSWORD}

