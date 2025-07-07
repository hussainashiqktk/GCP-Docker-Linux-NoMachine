#!/bin/bash

# Function to clean up everything
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
wget -O ng.sh https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/raw/main/ngrok.sh >/dev/null 2>&1
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
while true; do
    clear
    echo "Go to: https://dashboard.ngrok.com/get-started/your-authtoken"
    echo "Note: If previous attempts failed, please restart Cloud Shell first"
    read -p "Paste Ngrok Authtoken (or Ctrl+C to exit): " CRP
    
    # Verify token looks valid
    if [[ ! $CRP =~ ^[a-zA-Z0-9_]{32,}$ ]]; then
        echo "Invalid token format! It should be 32+ alphanumeric characters."
        sleep 2
        continue
    fi
    
    cleanup
    ./ngrok config add-authtoken "$CRP" >/dev/null 2>&1
    
    # Verify token works
    timeout 5 ./ngrok tcp 4000 >/dev/null 2>&1 &
    sleep 3
    if curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
        pkill -f ngrok
        break
    else
        echo "Invalid token or ngrok error! Please check your token."
        sleep 2
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

# Start ngrok with fresh instance
cleanup
./ngrok tcp --region $CRP 4000 >/dev/null 2>&1 &
sleep 3

if ! curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
    echo "Ngrok failed to start! Trying one last time..."
    cleanup
    ./ngrok tcp --region $CRP 4000 >/dev/null 2>&1 &
    sleep 3
    if ! curl --silent --show-error http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
        echo "Critical ngrok error! Please restart Cloud Shell and try again."
        exit 1
    fi
fi

# Start Docker with Kali
docker run --rm -d --network host --privileged --name nomachine-xfce4 -e PASSWORD=123456 -e USER=user --cap-add=SYS_PTRACE --shm-size=1g kalilinux/kali-rolling

# Install requirements
docker exec nomachine-xfce4 bash -c "
    apt update && \
    apt install -y wget curl tor proxychains psmisc python3-pip python3-venv nmap net-tools && \
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains.conf 2>/dev/null || \
    sed -i 's/^socks4.*/socks5 127.0.0.1 9050/' /etc/proxychains4.conf && \
    service tor restart && \
    echo 'alias newip=\"pkill -HUP tor && sleep 5\"' >> /home/user/.bashrc && \
    . /home/user/.bashrc
"

clear
echo "NoMachine: https://www.nomachine.com/download"
echo "Done! NoMachine Information:"
echo "IP Address:"
curl --silent --show-error http://127.0.0.1:4040/api/tunnels | sed -nE 's/.*public_url":"tcp:..([^"]*).*/\1/p' 
echo "User: user"
echo "Passwd: 123456"
echo "VM can't connect? Restart Cloud Shell then Re-run script."

# Keep-alive with monitoring
while true; do
    echo -ne "\rRunning [$(date +%H:%M:%S)] | CTRL+C to exit"
    if ! curl --silent --output /dev/null http://127.0.0.1:4040; then
        echo -e "\nNgrok connection lost! Reconnecting..."
        cleanup
        ./ngrok tcp --region $CRP 4000 >/dev/null 2>&1 &
        sleep 3
    fi
    sleep 1
done
