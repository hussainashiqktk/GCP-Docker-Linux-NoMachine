#!/bin/bash

# Function to clean up everything
cleanup() {
    echo -e "\nCleaning up..."
    pkill -f ngrok >/dev/null 2>&1 || true
    docker kill nomachine-xfce4 >/dev/null 2>&1 || true
    docker rm nomachine-xfce4 >/dev/null 2>&1 || true
    rm -f ngrok ngrok.tgz >/dev/null 2>&1 || true
    echo "Cleanup complete."
    sleep 2
}

# Initial cleanup
cleanup

# Install ngrok properly
echo -e "\n\033[1;34mInstalling ngrok...\033[0m"
wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz -O ngrok.tgz
tar xzf ngrok.tgz
rm ngrok.tgz
chmod +x ngrok
mv ngrok /usr/local/bin/
echo -e "\033[1;32mNgrok installed successfully\033[0m"

# Ngrok authentication
while true; do
    clear
    echo -e "\n\033[1;34mNgrok Authentication\033[0m"
    echo "1. Go to: https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "2. Copy your authtoken"
    echo "3. Paste it below (Ctrl+C to exit)"
    echo -e "\n\033[1;31mIMPORTANT: Token must be EXACTLY as shown (usually starts with 2...)\033[0m"
    
    read -p $'\nEnter your ngrok authtoken: ' CRP
    
    if [[ ! $CRP =~ ^[a-zA-Z0-9_]{32,}$ ]]; then
        echo -e "\n\033[1;31mERROR: Invalid token format! Must be 32+ alphanumeric chars\033[0m"
        sleep 2
        continue
    fi
    
    echo -e "\n\033[1;33mVerifying token...\033[0m"
    ngrok config add-authtoken "$CRP" >/dev/null 2>&1
    
    ngrok tcp 4000 >/dev/null 2>&1 &
    sleep 5
    
    if curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
        pkill -f ngrok
        sleep 1
        echo -e "\n\033[1;32mToken verified successfully!\033[0m"
        break
    else
        echo -e "\n\033[1;31mERROR: Token verification failed!\033[0m"
        read -p $'\nPress Enter to try again or Ctrl+C to exit'
        cleanup
    fi
done

# Region selection
clear
echo "Repo: https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine"
echo "======================="
echo "choose ngrok region:"
echo "======================="
echo "us - United States (Ohio)"
echo "eu - Europe (Frankfurt)"
echo "ap - Asia/Pacific (Singapore)"
echo "au - Australia (Sydney)"
echo "sa - South America (Sao Paulo)"
echo "jp - Japan (Tokyo)"
echo "in - India (Mumbai)"
read -p "Choose ngrok region (default: us): " CRP || CRP="us"

# Start ngrok
echo -e "\n\033[1;33mStarting ngrok tunnel...\033[0m"
ngrok tcp --region $CRP 4000 >/dev/null 2>&1 &
sleep 5

if ! curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
    echo -e "\n\033[1;31mERROR: Ngrok failed to start!\033[0m"
    exit 1
fi

# Start container with NoMachine
echo -e "\n\033[1;34mStarting NoMachine container...\033[0m"
docker run --rm -d \
    --network host \
    --privileged \
    --name nomachine-xfce4 \
    -e PASSWORD=123456 \
    -e USER=user \
    --cap-add=SYS_PTRACE \
    --shm-size=1g \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    thuonghai2711/nomachine-ubuntu-desktop:wine

# Install tools (WITHOUT breaking NoMachine)
echo -e "\n\033[1;33mInstalling tools...\033[0m"
docker exec nomachine-xfce4 bash -c "
    apt update -y && \
    apt install -y \
        tor \
        proxychains \
        psmisc \
        python3-pip \
        python3-venv \
        wget \
        curl \
        nmap \
        net-tools \
        xfce4 \
        xfce4-goodies \
        dbus-x11 && \
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains.conf 2>/dev/null || \
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains4.conf && \
    echo 'alias newip=\"pkill -HUP tor && sleep 5\"' >> /home/user/.bashrc && \
    echo 'export DISPLAY=:1' >> /home/user/.bashrc
"

# Wait for services
sleep 15

# Get connection info
clear
NGROK_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*).*/\1/p')

echo -e "\n\033[1;32mSETUP COMPLETE!\033[0m"
echo -e "\n\033[1;34mCONNECTION INFO:\033[0m"
echo -e "IP: \033[1;33m$NGROK_URL\033[0m"
echo -e "User: \033[1;33muser\033[0m"
echo -e "Pass: \033[1;33m123456\033[0m"
echo -e "\n\033[1;34mNoMachine Client:\033[0m"
echo "Download: https://www.nomachine.com/download"

# Keep-alive
while true; do
    echo -ne "\r\033[1;36mRunning @ $(date +%H:%M:%S) | Ctrl+C to exit\033[0m"
    sleep 1
done
