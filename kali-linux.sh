#!/bin/bash

# Function to clean up existing processes
cleanup() {
    pkill -f ngrok 2>/dev/null
    docker kill nomachine-xfce4 2>/dev/null
    docker rm nomachine-xfce4 2>/dev/null
}

# Clean up before starting
cleanup

# Download ngrok
wget -O ng.sh https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/raw/main/ngrok.sh > /dev/null 2>&1
chmod +x ng.sh
./ng.sh

function goto {
    label=$1
    cd
    cmd=$(sed -n "/^:[[:blank:]][[:blank:]]*${label}/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

: ngrok
clear
echo "Go to: https://dashboard.ngrok.com/get-started/your-authtoken"

# Input validation loop for ngrok token
while true; do
    read -p "Paste Ngrok Authtoken (or press Enter to retry): " CRP
    if [ -z "$CRP" ]; then
        echo "Token cannot be empty. Please try again."
        continue
    fi
    
    # Validate token format (basic check)
    if [[ ! "$CRP" =~ ^[a-zA-Z0-9_]{32,}$ ]]; then
        echo "Invalid token format. Please check and try again."
        continue
    fi
    
    # Configure ngrok
    if ./ngrok config add-authtoken "$CRP"; then
        break
    else
        echo "Failed to configure ngrok with this token. Please try again."
        cleanup
        sleep 1
    fi
done

clear
echo "Repo: https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine"
echo "======================="
echo "choose ngrok region (for better connection)."
echo "======================="
echo "us - United States (Ohio)"
echo "eu - Europe (Frankfurt)"
echo "ap - Asia/Pacific (Singapore)"
echo "au - Australia (Sydney)"
echo "sa - South America (Sao Paulo)"
echo "jp - Japan (Tokyo)"
echo "in - India (Mumbai)"
read -p "Choose ngrok region (default: us): " CRP || CRP="us"

# Start ngrok with retry logic
max_retries=3
retry_count=0

while [ $retry_count -lt $max_retries ]; do
    cleanup
    ./ngrok tcp --region "$CRP" 4000 &>/dev/null &
    sleep 3  # Give ngrok more time to start
    
    # Check if ngrok is running properly
    if curl --silent --show-error http://127.0.0.1:4040/api/tunnels > /dev/null 2>&1; then
        echo "Ngrok started successfully"
        break
    else
        retry_count=$((retry_count+1))
        echo "Ngrok Error! Retrying ($retry_count/$max_retries)..."
        sleep 2
    fi
done

if [ $retry_count -eq $max_retries ]; then
    echo "Failed to start ngrok after $max_retries attempts. Please check your connection and try again."
    exit 1
fi

# Start Docker container
docker run --rm -d --network host --privileged --name nomachine-xfce4 -e PASSWORD=123456 -e USER=user --cap-add=SYS_PTRACE --shm-size=1g kalilinux/kali-rolling

# Run commands inside the Docker container with error handling
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
    proxychains curl -s ifconfig.me || echo 'Some non-critical commands failed'
"

clear
echo "NoMachine: https://www.nomachine.com/download"
echo "Done! NoMachine Information:"
echo "IP Address:"
curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*).*/\1/p' 
echo "User: user"
echo "Passwd: 123456"
echo "VM can't connect? Restart Cloud Shell then Re-run script."

# Keep-alive with better error handling
seq 1 43200 | while read i; do
    if ! ps -p $! >/dev/null; then
        echo -e "\nNgrok process died! Restarting..."
        cleanup
        ./ngrok tcp --region "$CRP" 4000 &>/dev/null &
        sleep 3
    fi
    echo -en "\r Running .     $i s /43200 s"; sleep 0.1
    echo -en "\r Running ..    $i s /43200 s"; sleep 0.1
    echo -en "\r Running ...   $i s /43200 s"; sleep 0.1
    echo -en "\r Running ....  $i s /43200 s"; sleep 0.1
    echo -en "\r Running ..... $i s /43200 s"; sleep 0.1
done
