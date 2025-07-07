#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Trap CTRL+C, CTRL+Z and cleanup
trap 'cleanup' SIGINT SIGTERM SIGTSTP

# Function to clean up
cleanup() {
    echo -e "\n${RED}[-] Cleaning up...${NC}"
    pkill -f ngrok >/dev/null 2>&1
    docker kill nomachine-xfce4 >/dev/null 2>&1
    docker rm nomachine-xfce4 >/dev/null 2>&1
    echo -e "${GREEN}[+] Cleanup done. Exiting.${NC}"
    exit 0
}

# Install ngrok
echo -e "${YELLOW}[*] Installing ngrok...${NC}"
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
echo -e "${BLUE}Go to: https://dashboard.ngrok.com/get-started/your-authtoken${NC}"
read -p "$(echo -e "${YELLOW}Paste Ngrok Authtoken: ${NC}")" CRP
./ngrok config add-authtoken $CRP 

clear
echo -e "${BLUE}Repo: https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine${NC}"
echo -e "${YELLOW}=======================${NC}"
echo -e "${YELLOW}choose ngrok region:${NC}"
echo -e "${YELLOW}=======================${NC}"
echo -e "us - United States (Ohio)"
echo -e "eu - Europe (Frankfurt)"
echo -e "ap - Asia/Pacific (Singapore)"
echo -e "au - Australia (Sydney)"
echo -e "sa - South America (Sao Paulo)"
echo -e "jp - Japan (Tokyo)"
echo -e "in - India (Mumbai)"
read -p "$(echo -e "${YELLOW}Choose ngrok region (default: us): ${NC}")" CRP || CRP="us"
./ngrok tcp --region $CRP 4000 &>/dev/null &
sleep 1
if curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then 
    echo -e "${GREEN}[+] OK${NC}"; 
else 
    echo -e "${RED}[-] Ngrok Error! Please try again!${NC}" && sleep 1 && goto ngrok
fi

# Start container with NoMachine
echo -e "${YELLOW}[*] Starting Docker container...${NC}"
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
echo -e "${YELLOW}[*] Installing system tools...${NC}"
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
    proxychains curl -s ifconfig.me && \
    echo \"alias newip='sudo pkill -HUP tor'\" | sudo tee -a ~/.bashrc > /dev/null && source ~/.bashrc && \
    echo \"alias pc='proxychains'\" | sudo tee -a ~/.bashrc > /dev/null && source ~/.bashrc
"

# Verify installations
docker exec nomachine-xfce4 bash -c "
    echo -e '${BLUE}=== Tool Verification ===${NC}' && \
    tor --version && \
    proxychains -q echo 'Proxychains working' && \
    python3 --version && \
    pip3 --version && \
    nmap --version
"

clear
echo -e "${BLUE}NoMachine: https://www.nomachine.com/download${NC}"
echo -e "${YELLOW}=== Connection Info ===${NC}"
echo -e "IP: $(curl -s http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*).*/\1/p')"
echo -e "User: user"
echo -e "Pass: 123456"
echo -e "${YELLOW}======================${NC}"

# Keep-alive
while true; do
    echo -ne "\r${GREEN}[+] Running @ $(date +%H:%M:%S) | ${RED}Press CTRL+C to exit${NC}"
    sleep 1
done
