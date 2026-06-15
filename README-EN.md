<div align="center">
  <img src="https://img.shields.io/badge/Ubuntu-26.04%20%7C%2025.04%20%7C%2024.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" alt="Ubuntu">
  <img src="https://img.shields.io/badge/Status-Working-success?style=for-the-badge&logo=checkmarx&logoColor=white" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Architecture-amd64%20%7C%20i386-0052CC?style=for-the-badge&logo=intel&logoColor=white" alt="Arch">
  <br><br>
  <h1>🕸️ Domínio Web (Thonsons Routers) — Linux</h1>
  <p><strong>Complete installation guide for Ubuntu 24.04, 25.04 and 26.04 LTS</strong></p>
  <p>Get AppController and TRComputerPluginLinux (Thonsons Routers) working on the latest Ubuntu versions.</p>
  <br>
  <a href="#-automated-installation"><strong>🚀 Automated Script</strong></a> •
  <a href="#-step-by-step-installation"><strong>📋 Step by Step</strong></a> •
  <a href="#-troubleshooting"><strong>🔧 Troubleshooting</strong></a> •
  <a href="README.md"><strong>🇧🇷 Português</strong></a>
</div>

---

## 📌 About

This repository contains everything you need to install the **Domínio Web Plugin** (Thonsons Routers) on modern Ubuntu distributions (24.04+). This plugin allows you to access accounting and business applications through your browser using:

- **AppController** (`gg-client-linux.deb`) — 32-bit application that manages communication with the website
- **TRComputerPluginLinux** — .NET plugin that processes `trplugin://` protocol requests

> ⚠️ Ubuntu 24.04+ does not include several libraries required by these programs. This guide resolves all dependencies manually.

---

## 🎯 Automated Installation

### Prerequisites

Download the **installation files** to `~/Downloads/`:

| File | Where to download |
|------|-------------------|
| `gg-client-linux.deb` | [Domínio Support Center](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |
| `DominioWebPlugin.7z` | [Domínio Support Center](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |

Once downloaded, run:

```bash
wget -O install-dominio-web.sh https://raw.githubusercontent.com/JosueMadureira/dominio-web-plugin-linux/main/install.sh
chmod +x install-dominio-web.sh
./install-dominio-web.sh
```

> 🛡️ The script is safe and open source — you can [review it here](install.sh).

### 🖥️ Step-by-Step Installation

If you prefer to do it manually or the automated script doesn't work, follow these steps:

#### Step 0 — Check Ubuntu version

```bash
lsb_release -a
```

#### Step 1 — Enable passwordless sudo

```bash
echo 'josue ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/josue-nopasswd
```

#### Step 2 — Enable i386 architecture

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
```

#### Step 3 — Install libpng12

```bash
cd /tmp
sudo apt-get install -y wget
wget -O libpng12.deb "http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb"
sudo dpkg -i libpng12.deb
sudo apt-get install -f -y
```

> ⚠️ If `dpkg -i` fails with a directory error, try manual installation:
> ```bash
> cd /tmp && dpkg-deb -x libpng12.deb extracted
> sudo cp extracted/lib/x86_64-linux-gnu/libpng12.so.0.54.0 /lib/x86_64-linux-gnu/
> sudo ln -sf libpng12.so.0.54.0 /lib/x86_64-linux-gnu/libpng12.so.0
> sudo ldconfig
> ```

#### Step 4 — Install libcrypt1:i386

```bash
sudo apt-get install -y libcrypt1:i386
```

#### Step 5 — Install libssl1.1

```bash
cd /tmp
wget -O libssl1.1.deb "http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb"
sudo dpkg -i libssl1.1.deb
```

#### Step 6 — Install AppController (gg-client)

```bash
sudo dpkg -i ~/Downloads/gg-client-linux.deb
sudo apt-get install -f -y
```

#### Step 7 — Extract and install Domínio Web Plugin

```bash
cd ~/Downloads
sudo apt-get install -y p7zip-full
7z x DominioWebPlugin.7z -oDominioWebPlugin
cd ~/Downloads/DominioWebPlugin/DominioWebPlugin/
chmod +x InstallDominioWeb.sh
sudo ./InstallDominioWeb.sh
```

#### Step 8 — Fix the handler (ESSENTIAL!)

The original handler passes the full URL (`trplugin://?content=BASE64`), but `TRComputerPluginLinux` expects **only the Base64** content. It also needs .NET environment variables:

```bash
sudo tee /usr/share/handlers/dominio-web-plugin-handler.sh << 'SCRIPT'
#!/usr/bin/env bash
request="$1"
content="${request#*content=}"
if [ -n "$content" ]; then
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 \
    DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0 \
    /usr/bin/TRComputerPluginLinux "$content"
fi
SCRIPT

sudo chmod +x /usr/share/handlers/dominio-web-plugin-handler.sh
```

#### Step 9 — Configure Chrome policy

Prevents the confirmation popup when opening protocols:

```bash
sudo mkdir -p /etc/opt/chrome/policies/managed
sudo tee /etc/opt/chrome/policies/managed/dominio-web.json << 'EOF'
{
    "AutoLaunchProtocolsFromOrigins": [
      { "allowed_origins": ["*"], "protocol": "appcontroller" },
      { "allowed_origins": ["*"], "protocol": "trplugin" }
    ]
}
EOF
```

#### Step 10 — Finalize and test

```bash
sudo update-desktop-database
/usr/bin/appcontroller &
```

**Done!** 🎉 Now open Chrome, go to **https://www.dominioweb.com.br**, log in and the plugin will be automatically detected.

---

## 🔧 Troubleshooting

### ❌ "libpng12 not found" or installation error

```bash
cd /tmp && dpkg-deb -x libpng12.deb extracted
sudo cp extracted/lib/x86_64-linux-gnu/libpng12.so.0.54.0 /lib/x86_64-linux-gnu/
sudo ln -sf libpng12.so.0.54.0 /lib/x86_64-linux-gnu/libpng12.so.0
sudo ldconfig
```

### ❌ "Dependency error" when installing AppController

```bash
sudo apt-get install -f -y
```

### ❌ Protocol doesn't open in Chrome

1. Check if appcontroller is running: `ps aux | grep appcontroller`
2. Check Chrome policy: `cat /etc/opt/chrome/policies/managed/dominio-web.json`
3. Close **all** Chrome windows and reopen

### ❌ ".NET error" or globalization error

```bash
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
```

The fixed handler (Step 8) already includes these variables.

---

## 🔄 Autostart (optional)

To start AppController automatically on boot:

```bash
mkdir -p ~/.config/autostart
cp /usr/share/applications/appcontroller.desktop ~/.config/autostart/
```

To remove from autostart:

```bash
rm ~/.config/autostart/appcontroller.desktop
```

---

## 📁 Required files

| File | Size | Source |
|------|------|--------|
| `gg-client-linux.deb` | ~10 MB | [Domínio Support Center](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |
| `DominioWebPlugin.7z` | ~22 MB | [Domínio Support Center](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |
| `libpng12-0_1.2.54-1ubuntu1_amd64.deb` | ~114 KB | Ubuntu Archive (downloaded automatically) |
| `libssl1.1_1.1.1f-1ubuntu2_amd64.deb` | ~1.3 MB | Ubuntu Archive (downloaded automatically) |

> 💾 **Tip:** Keep `gg-client-linux.deb` and `DominioWebPlugin.7z` from the [Domínio Support Center](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) saved in a safe folder. Other files are downloaded from the internet during installation.

---

## 🏷️ Tags

`dominio-web` `dominioweb` `trcomputerplugin` `appcontroller` `gg-client` `ubuntu-26-04` `ubuntu-24-04` `ubuntu-linux` `plugin-navegador` `certificado-digital` `contabilidade` `sistema-contabil` `linux-plugin` `net-core-3.1` `protocol-handler` `chrome-policy`

---

## 📄 License

MIT © Josué Madureira

---

<div align="center">
  <p>🐛 Found a problem? <a href="https://github.com/JosueMadureira/dominio-web-plugin-linux/issues">Open an issue</a></p>
  <p>⭐ If this guide helped you, leave a star!</p>
</div>
