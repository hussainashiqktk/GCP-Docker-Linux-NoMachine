#!/bin/bash

# Function to clean up
cleanup() {
    pkill -f ngrok >/dev/null 2>&1
    docker kill nomachine-xfce4 >/dev/null 2>&1
    docker rm nomachine-xfce4 >/dev/null 2>&1
    rm -f ngrok >/dev/null 2>&1
    sleep 2
}

# Initial cleanup
cleanup

# Proper ngrok installation
echo "Installing ngrok..."
if [ ! -f ngrok ]; then
    wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O ngrok.tgz >/dev/null 2>&1
    tar xvzf ngrok.tgz >/dev/null 2>&1
    rm ngrok.tgz
    chmod +x ngrok
fi

# Verify ngrok installation
if [ ! -f ngrok ]; then
    echo "ERROR: Failed to install ngrok!"
    exit 1
fi

# Ngrok authentication
while true; do
    clear
    echo "Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "Note: Copy the full token exactly as shown"
    read -p "Paste your ngrok authtoken here: " CRP
    
    # Verify token looks valid
    if [[ ! $CRP =~ ^[a-zA-Z0-9_]{32,}$ ]]; then
        echo "ERROR: Invalid token format! Should be 32+ alphanumeric chars"
        sleep 2
        continue
    fi
    
    # Test the token
    echo "Verifying token..."
    ./ngrok config add-authtoken "$CRP" >/dev/null 2>&1
    timeout 10 ./ngrok tcp 4000 >/dev/null 2>&1 &
    sleep 5
    
    if curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
        pkill -f ngrok
        sleep 1
        break
    else
        echo "ERROR: Token verification failed!"
        echo "Possible reasons:"
        echo "1. Incorrect token"
        echo "2. Token already used elsewhere"
        echo "3. Network issues"
        read -p "Press Enter to try again or Ctrl+C to exit"
        cleanup
    fi
done

# Rest of the script remains the same as previous version...
# [Include the region selection, docker setup, etc from previous script]
