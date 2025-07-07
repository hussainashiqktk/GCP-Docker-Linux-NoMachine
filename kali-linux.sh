#!/bin/bash

# Function to kill all existing processes
cleanup() {
    echo "Cleaning up previous instances..."
    pkill -f ngrok >/dev/null 2>&1
    docker kill nomachine-xfce4 >/dev/null 2>&1
    docker rm nomachine-xfce4 >/dev/null 2>&1
    rm -f ngrok >/dev/null 2>&1
    sleep 2
}

# Initial cleanup
cleanup

# Download ngrok
echo "Downloading ngrok..."
wget -O ng.sh https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/raw/main/ngrok.sh >/dev/null 2>&1
chmod +x ng.sh
./ng.sh

# Ngrok setup
while true; do
    clear
    echo "Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken"
    sleep 2
    echo "Note: Copy the full token including the '2' at the beginning if present"
    sleep 2
    read -p "Paste your ngrok authtoken here: " CRP
    
    # Basic token validation
    if [[ ! $CRP =~ ^[a-zA-Z0-9_]{32,}$ ]]; then
        echo "ERROR: Token should be 32+ alphanumeric characters"
        sleep 2
        continue
    fi
    
    # Configure ngrok
    echo "Configuring ngrok..."
    ./ngrok config add-authtoken "$CRP" >/dev/null 2>&1
    
    # Test the token
    timeout 10 ./ngrok tcp 4000 >/dev/null 2>&1 &
    sleep 5
    
    if curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
        echo "Ngrok configured successfully!"
        pkill -f ngrok
        sleep 1
        break
    else
        echo "ERROR: Ngrok failed to start with this token"
        echo "Possible reasons:"
        echo "1. Invalid/expired token"
        echo "2. Network issues"
        echo "3. Ngrok service outage"
        read -p "Press Enter to try again or Ctrl+C to exit"
        cleanup
    fi
done

# Get region
clear
echo "Select ngrok region:"
echo "us - United States (Ohio)"
echo "eu - Europe (Frankfurt)"
echo "ap - Asia/Pacific (Singapore)"
echo "au - Australia (Sydney)"
echo "sa - South America (Sao Paulo)"
echo "jp - Japan (Tokyo)"
echo "in - India (Mumbai)"
read -p "Choose region (default: us): " CRP || CRP="us"

# Start ngrok
echo "Starting ngrok..."
cleanup
./ngrok tcp --region $CRP 4000 >/dev/null 2>&1 &
sleep 5

if ! curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
    echo "ERROR: Ngrok failed to start after authentication"
    echo "Please try restarting Cloud Shell and running again"
    exit 1
fi

# Start Kali Linux container
echo "Starting Kali Linux container..."
docker run --rm -d --network host --privileged --name nomachine-xfce4 -e PASSWORD=123456 -e USER=user --cap-add=SYS_PTRACE --shm-size=1g kalilinux/kali-rolling

# Install tools
echo "Installing required tools..."
docker exec nomachine-xfce4 bash -c "
    apt update && \
    apt install -y tor proxychains psmisc python3-pip python3-venv wget curl nmap net-tools && \
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains.conf 2>/dev/null || \
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains4.conf && \
    service tor restart && \
    echo 'alias newip=\"pkill -HUP tor && sleep 5\"' >> /home/user/.bashrc
"

# Display connection info
clear
echo "========================================"
echo "NoMachine Connection Information"
echo "========================================"
echo "IP: $(curl -s http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*).*/\1/p')"
echo "User: user"
echo "Password: 123456"
echo "========================================"
echo "Download NoMachine: https://www.nomachine.com"
echo "========================================"
echo "Note: If connection fails, restart Cloud Shell"

# Keep-alive
while true; do
    echo -ne "\r[$(date +%H:%M:%S)] Session active - Press Ctrl+C to exit"
    sleep 1
done
