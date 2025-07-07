# 🐳 Docker Ubuntu Desktop with NoMachine 🖥️


## 🌟 Quick Reference Table

| Desktop Configuration          | Installation Command |
|--------------------------------|----------------------|
| Kali Linux | `bash <(curl -sL https://github.com/hussainashiqktk/GCP-Docker-Linux-NoMachine/blob/3bbbd8f1f08fe5e70f14d24239882c374176f506/kali-linux.sh)` |
| XFCE4 (Standard) | `bash <(curl -sL https://raw.githubusercontent.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/main/xfce4-install.sh)` |
| XFCE4 with WineHQ | `bash <(curl -sL https://raw.githubusercontent.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/main/wine-install.sh)` |
| XFCE4 with Windows 10 Theme | `bash <(curl -sL https://raw.githubusercontent.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/main/win10-theme-install.sh)` |
| XFCE4 with Tor+Proxychains | `bash <(wget -qO- https://raw.githubusercontent.com/hussainashiqktk/GCP-Docker-Linux-NoMachine/main/ubuntu-desktop-tor.sh)` |
| MATE Desktop | `bash <(curl -sL https://raw.githubusercontent.com/kmille36/Docker-Ubuntu-Desktop-NoMachine/main/mate-install.sh)` |



![Ubuntu Desktop Environments](https://user-images.githubusercontent.com/58414694/149808540-5cfe38ee-a88b-4e8b-a1e9-2a5a1fda7f1d.png)


## 🚀 Installation Commands

### 1. XFCE4 with Tor+Proxychains (NEW!)
![Tor Desktop](https://user-images.githubusercontent.com/58414694/149620450-4558489e-f00e-4035-8ccd-4ca231f900a4.png)
```bash
wget https://raw.githubusercontent.com/hussainashiqktk/GCP-Docker-Linux-NoMachine/main/ubuntu-desktop-tor.sh && bash ubuntu-desktop-tor.sh
```

### 2. XFCE4 (Standard)
![XFCE4](https://user-images.githubusercontent.com/58414694/149454910-33dd1c5b-bbbd-4cc8-b9b7-5b7331723034.png)
```bash
curl -sLkO https://is.gd/nomachinexfce4 && bash nomachinexfce4
```

### 3. XFCE4 with WineHQ
![WineHQ](https://user-images.githubusercontent.com/58414694/149620450-4558489e-f00e-4035-8ccd-4ca231f900a4.png)
```bash
curl -sLkO https://is.gd/nomachinewine && bash nomachinewine
```

### 4. XFCE4 with Windows 10 Theme
![Win10 Theme](https://user-images.githubusercontent.com/58414694/149808540-5cfe38ee-a88b-4e8b-a1e9-2a5a1fda7f1d.png)
```bash
curl -sLkO https://is.gd/nomachinewindows10 && bash nomachinewindows10
```

### 5. MATE Desktop
![MATE](https://user-images.githubusercontent.com/58414694/149459685-27d51920-4616-4b3e-94de-2982f78f9295.png)
```bash
curl -sLkO https://is.gd/nomachineMATE && bash nomachineMATE
```

## ⚙️ Default Credentials
- **Username:** `user`
- **Password:** `123456`
- **NoMachine:** [Download Client](https://www.nomachine.com)

## ❓ Troubleshooting
**If connection fails:**  
1. Restart Cloud Shell  
2. Re-run the installation script  

## 📦 Source
[kmille36/Docker-Ubuntu-Desktop-NoMachine](https://github.com/kmille36/Docker-Ubuntu-Desktop-NoMachine)
