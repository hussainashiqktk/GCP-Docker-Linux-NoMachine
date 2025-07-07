#!/bin/bash

# Function to clean up
cleanup() {
    pkill -f ngrok >/dev/null 2>&1
    docker kill nomachine-xfce4 >/dev/null 2>&1
    docker rm nomachine-xfce4 >/dev/null 2>&1
}

# Install ngrok
wget -O ng.sh https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/raw/main/ngrok.sh >/dev/null 2>&1
chmod +x ng.sh
./ng.sh

function goto {
    label=$1
    cmd=$(sed -n "/^:[[:blank:]][[:blank:]]*${label}/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

: ngrok
clear
echo "Go to: https://dashboard.ngrok.com/get-started/your-authtoken"
read -p "Paste Ngrok Authtoken: " CRP
./ngrok config add-authtoken $CRP 

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
./ngrok tcp --region $CRP 4000 &>/dev/null &
sleep 1
if curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then 
    echo OK; 
else 
    echo "Ngrok Error! Please try again!" && sleep 1 && goto ngrok
fi

# Start container with NoMachine
docker run --rm -d \
    --network host \
    --privileged \
    --name nomachine-xfce4 \
    -e PASSWORD=123456 \
    -e USER=user \
    --cap-add=SYS_PTRACE \
    --shm-size=1g \
    thuonghai2711/nomachine-ubuntu-desktop:wine

# Install tools with error handling
echo "Installing system tools..."
docker exec nomachine-xfce4 bash -c "
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    apt update && \
    apt upgrade -y && \
    apt install -y tor proxychains psmisc python3-pip python3-venv wget curl nmap net-tools && \
    (sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains.conf 2>/dev/null || \
     sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains4.conf) && \
    service tor restart && \
    sleep 5 && \
    echo 'alias newip=\"pkill -HUP tor && sleep 5\"' >> /home/user/.bashrc && \
    . /home/user/.bashrc && \
    newip && \
    echo 'Proxychains check:' && \
    proxychains curl -s ifconfig.me
"

# Verify installations
docker exec nomachine-xfce4 bash -c "
    echo '=== Tool Verification ===' && \
    tor --version && \
    proxychains -q echo 'Proxychains working' && \
    python3 --version && \
    pip3 --version && \
    nmap --version
"

clear
echo "NoMachine: https://www.nomachine.com/download"
echo "=== Connection Info ==="
echo "IP: $(curl -s http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*).*/\1/p')"
echo "User: user"
echo "Pass: 123456"
echo "======================"

# Keep-alive
while true; do
    echo -ne "\rRunning @ $(date +%H:%M:%S) | Ctrl+C to exit"
    sleep 1
done
