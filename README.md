<div align="center">
  <img src="https://img.shields.io/badge/Ubuntu-26.04%20%7C%2025.04%20%7C%2024.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white" alt="Ubuntu">
  <img src="https://img.shields.io/badge/Status-Funcional-success?style=for-the-badge&logo=checkmarx&logoColor=white" alt="Status">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="License">
  <img src="https://img.shields.io/badge/Arquitetura-amd64%20%7C%20i386-0052CC?style=for-the-badge&logo=intel&logoColor=white" alt="Arch">
  <br><br>
  <h1>🕸️ Domínio Web (Thonsons Routers) — Linux</h1>
  <p><strong>Guia completo de instalação para Ubuntu 24.04, 25.04 e 26.04 LTS</strong></p>
  <p>Faça o AppController e o TRComputerPluginLinux (Thonsons Routers) funcionarem nas versões mais recentes do Ubuntu.</p>
  <br>
  <a href="#-instalação-automática"><strong>🚀 Script Automático</strong></a> •
  <a href="#-instalação-passo-a-passo"><strong>📋 Passo a Passo</strong></a> •
  <a href="#-solução-de-problemas"><strong>🔧 Troubleshooting</strong></a> •
  <a href="README-EN.md"><strong>🇺🇸 English</strong></a>
</div>

---

## 📌 Sobre

Este repositório contém tudo que você precisa para instalar o **Domínio Web Plugin** (Thonsons Routers) em distribuições Ubuntu modernas (24.04+). O plugin permite acessar aplicações contábeis e empresariais através do navegador, utilizando:

- **AppController** (`gg-client-linux.deb`) — Aplicação 32-bit que gerencia a comunicação com o site
- **TRComputerPluginLinux** — Plugin .NET que processa as requisições do protocolo `trplugin://`

> ⚠️ O Ubuntu 24.04+ não inclui várias bibliotecas necessárias para estes programas. Este guia resolve todas as dependências manualmente.

---

## 🎯 Instalação Automática

### Pré-requisitos

Baixe os **arquivos de instalação** e coloque na pasta `~/Downloads/`:

| Arquivo | Onde baixar |
|---------|-------------|
| `gg-client-linux.deb` | [Central de Soluções Domínio](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |
| `DominioWebPlugin.7z` | [Central de Soluções Domínio](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |

Depois de baixar, execute o script:

```bash
wget -O install-dominio-web.sh https://raw.githubusercontent.com/JosueMadureira/dominio-web-plugin-linux/main/install.sh
chmod +x install-dominio-web.sh
./install-dominio-web.sh
```

> 🛡️ O script é seguro e de código aberto — você pode [revisá-lo aqui](install.sh).

### 🖥️ Instalação Manual Passo a Passo

Se preferir fazer manualmente ou se o script automático não funcionar, siga os passos abaixo:

#### Passo 0 — Verificar a versão do Ubuntu

```bash
lsb_release -a
```

#### Passo 1 — Habilitar sudo sem senha

```bash
echo 'josue ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/josue-nopasswd
```

#### Passo 2 — Habilitar arquitetura i386

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
```

#### Passo 3 — Instalar libpng12

```bash
cd /tmp
sudo apt-get install -y wget
wget -O libpng12.deb "http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb"
sudo dpkg -i libpng12.deb
sudo apt-get install -f -y
```

> ⚠️ Se o `dpkg -i` falhar com erro de diretório, use a instalação manual:
> ```bash
> cd /tmp && dpkg-deb -x libpng12.deb extracted
> sudo cp extracted/lib/x86_64-linux-gnu/libpng12.so.0.54.0 /lib/x86_64-linux-gnu/
> sudo ln -sf libpng12.so.0.54.0 /lib/x86_64-linux-gnu/libpng12.so.0
> sudo ldconfig
> ```

#### Passo 4 — Instalar libcrypt1:i386

```bash
sudo apt-get install -y libcrypt1:i386
```

#### Passo 5 — Instalar libssl1.1

```bash
cd /tmp
wget -O libssl1.1.deb "http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb"
sudo dpkg -i libssl1.1.deb
```

#### Passo 6 — Instalar o AppController (gg-client)

```bash
sudo dpkg -i ~/Downloads/gg-client-linux.deb
sudo apt-get install -f -y
```

#### Passo 7 — Extrair e instalar o Domínio Web Plugin

```bash
cd ~/Downloads
sudo apt-get install -y p7zip-full
7z x DominioWebPlugin.7z -oDominioWebPlugin
cd ~/Downloads/DominioWebPlugin/DominioWebPlugin/
chmod +x InstallDominioWeb.sh
sudo ./InstallDominioWeb.sh
```

#### Passo 8 — Corrigir o handler (ESSENCIAL!)

O handler original passa a URL inteira (`trplugin://?content=BASE64`), mas o `TRComputerPluginLinux` espera **apenas o Base64**. Além disso, precisa de variáveis de ambiente .NET:

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

#### Passo 9 — Configurar política do Chrome

Evita o popup de confirmação ao abrir os protocolos:

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

#### Passo 10 — Finalizar e testar

```bash
sudo update-desktop-database
/usr/bin/appcontroller &
```

**Pronto!** 🎉 Agora abra o Chrome, acesse **https://www.dominioweb.com.br**, faça login e o plugin será detectado automaticamente.

---

## 🔧 Solução de Problemas

### ❌ "libpng12 não encontrado" ou erro ao instalar

```bash
cd /tmp && dpkg-deb -x libpng12.deb extracted
sudo cp extracted/lib/x86_64-linux-gnu/libpng12.so.0.54.0 /lib/x86_64-linux-gnu/
sudo ln -sf libpng12.so.0.54.0 /lib/x86_64-linux-gnu/libpng12.so.0
sudo ldconfig
```

### ❌ "Falha de dependência" ao instalar o AppController

```bash
sudo apt-get install -f -y
```

### ❌ Protocolo não abre no Chrome

1. Verifique se o appcontroller está rodando: `ps aux | grep appcontroller`
2. Verifique a política do Chrome: `cat /etc/opt/chrome/policies/managed/dominio-web.json`
3. Feche **todas** as janelas do Chrome e abra novamente

### ❌ "Falha no .NET" ou erro de globalização

```bash
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export DOTNET_SYSTEM_NET_HTTP_USESOCKETSHTTPHANDLER=0
```

O handler corrigido (Passo 8) já inclui estas variáveis.

---

## 📁 Arquivos necessários

| Arquivo | Tamanho | Origem |
|---------|---------|--------|
| `gg-client-linux.deb` | ~10 MB | [Central de Soluções Domínio](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |
| `DominioWebPlugin.7z` | ~22 MB | [Central de Soluções Domínio](https://suporte.dominioatendimento.com/central/faces/solucao.html?codigo=7165) |
| `libpng12-0_1.2.54-1ubuntu1_amd64.deb` | ~114 KB | Ubuntu Archive (baixado automaticamente) |
| `libssl1.1_1.1.1f-1ubuntu2_amd64.deb` | ~1.3 MB | Ubuntu Archive (baixado automaticamente) |

> 💾 **Dica:** Mantenha `gg-client-linux.deb` e `DominioWebPlugin.7z` salvos em uma pasta segura. Os outros arquivos são baixados da internet durante a instalação.

---

## 🏷️ Tags

`dominio-web` `dominioweb` `trcomputerplugin` `appcontroller` `gg-client` `ubuntu-26-04` `ubuntu-24-04` `ubuntu-linux` `plugin-navegador` `certificado-digital` `contabilidade` `sistema-contabil` `linux-plugin` `net-core-3.1` `protocol-handler` `chrome-policy`

---

## 📄 Licença

MIT © Josué Madureira

---

<div align="center">
  <p>🐛 Encontrou um problema? <a href="https://github.com/JosueMadureira/dominio-web-plugin-linux/issues">Abra uma issue</a></p>
  <p>⭐ Se este guia ajudou, deixe uma estrela!</p>
</div>
