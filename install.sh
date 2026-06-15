#!/bin/bash
# =============================================================================
# INSTALAÇÃO AUTOMÁTICA — Domínio Web Plugin no Ubuntu 24.04+
# =============================================================================
# Uso:
#   1. Coloque gg-client-linux.deb e DominioWebPlugin.7z em ~/Downloads/
#   2. Execute: chmod +x install.sh && ./install.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

step()   { echo -e "\n${BLUE}[${1}/${TOTAL}]${NC} $2"; }
success(){ echo -e "  ${GREEN}✓${NC} $1"; }
warn()   { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()   { echo -e "  ${RED}✗${NC} $1"; exit 1; }

TOTAL=10

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🕸️  Domínio Web Plugin — Instalação Automática         ║${NC}"
echo -e "${BLUE}║   Ubuntu 24.04 / 25.04 / 26.04 LTS                     ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"

# Verificar arquivos necessários
if [ ! -f ~/Downloads/gg-client-linux.deb ]; then
    fail "Arquivo ~/Downloads/gg-client-linux.deb não encontrado!
  Coloque o arquivo em ~/Downloads/ e execute novamente."
fi
if [ ! -f ~/Downloads/DominioWebPlugin.7z ]; then
    fail "Arquivo ~/Downloads/DominioWebPlugin.7z não encontrado!
  Coloque o arquivo em ~/Downloads/ e execute novamente."
fi

# ── Passo 1: Sudo sem senha ──
step 1 "Configurando sudo sem senha"
if sudo -n true 2>/dev/null; then
    success "sudo já está configurado sem senha"
else
    echo 'josue ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/josue-nopasswd > /dev/null
    success "sudo sem senha configurado"
fi

# ── Passo 2: Arquitetura i386 ──
step 2 "Habilitando arquitetura i386"
sudo dpkg --add-architecture i386
sudo apt-get update -qq
success "Arquitetura i386 habilitada"

# ── Passo 3: libpng12 ──
step 3 "Instalando libpng12"
cd /tmp
if [ ! -f libpng12.deb ]; then
    wget -q -O libpng12.deb "http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb"
fi
if sudo dpkg -i libpng12.deb 2>/dev/null; then
    success "libpng12 instalado via dpkg"
else
    warn "Instalação via dpkg falhou — instalando manualmente..."
    dpkg-deb -x libpng12.deb /tmp/libpng12-extract
    sudo cp /tmp/libpng12-extract/lib/x86_64-linux-gnu/libpng12.so.0.54.0 /lib/x86_64-linux-gnu/
    sudo ln -sf libpng12.so.0.54.0 /lib/x86_64-linux-gnu/libpng12.so.0
    sudo ldconfig
    success "libpng12 instalado manualmente"
fi

# ── Passo 4: libcrypt1:i386 ──
step 4 "Instalando libcrypt1:i386"
sudo apt-get install -y -qq libcrypt1:i386
success "libcrypt1:i386 instalado"

# ── Passo 5: libssl1.1 ──
step 5 "Instalando libssl1.1"
cd /tmp
if [ ! -f libssl1.1.deb ]; then
    wget -q -O libssl1.1.deb "http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb"
fi
sudo dpkg -i libssl1.1.deb
success "libssl1.1 instalado"

# ── Passo 6: AppController ──
step 6 "Instalando AppController (gg-client)"
sudo dpkg -i ~/Downloads/gg-client-linux.deb 2>/dev/null || true
sudo apt-get install -f -y -qq
if command -v /usr/bin/appcontroller &>/dev/null; then
    success "AppController instalado com sucesso"
else
    fail "Falha ao instalar o AppController"
fi

# ── Passo 7: DominioWebPlugin ──
step 7 "Extraindo e instalando DominioWebPlugin"
cd ~/Downloads
if ! command -v 7z &>/dev/null; then
    sudo apt-get install -y -qq p7zip-full
fi
if [ ! -d DominioWebPlugin ]; then
    7z x DominioWebPlugin.7z -oDominioWebPlugin > /dev/null
fi
cd ~/Downloads/DominioWebPlugin/DominioWebPlugin/
sudo mkdir -p /usr/share/handlers
sudo cp dominio-web-plugin-handler.sh /usr/share/handlers/
sudo cp dominio-web-plugin-handler.desktop /usr/share/applications/
sudo cp TRComputerPluginLinux /usr/bin/
sudo cp TRComputerPluginLinux.pdb /usr/bin/
sudo chmod 755 /usr/share/handlers
sudo chmod +x /usr/share/handlers/dominio-web-plugin-handler.sh
sudo chmod +x /usr/bin/TRComputerPluginLinux
sudo update-desktop-database
success "DominioWebPlugin instalado"

# ── Passo 8: Corrigir handler ──
step 8 "Corrigindo handler do protocolo trplugin://"
sudo tee /usr/share/handlers/dominio-web-plugin-handler.sh > /dev/null << 'SCRIPT'
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
success "Handler corrigido (URL stripping + DOTNET vars)"

# ── Passo 9: Chrome policy ──
step 9 "Configurando política do Chrome"
sudo mkdir -p /etc/opt/chrome/policies/managed
sudo tee /etc/opt/chrome/policies/managed/dominio-web.json > /dev/null << 'EOF'
{
    "AutoLaunchProtocolsFromOrigins": [
      { "allowed_origins": ["*"], "protocol": "appcontroller" },
      { "allowed_origins": ["*"], "protocol": "trplugin" }
    ]
}
EOF
success "Chrome policy configurada (sem popup de confirmação)"

# ── Passo 10: Finalizar ──
step 10 "Finalizando"
sudo update-desktop-database
success "Banco de dados MIME atualizado"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           INSTALAÇÃO CONCLUÍDA COM SUCESSO! 🎉          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  Próximos passos:"
echo "  1. Feche TODAS as janelas do Chrome"
echo "  2. Abra o Chrome e acesse: https://www.dominioweb.com.br"
echo "  3. Faça login"
echo "  4. O plugin será detectado automaticamente!"
echo ""
