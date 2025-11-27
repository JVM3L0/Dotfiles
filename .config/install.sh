#!/bin/sh

# --- CONFIGURAÇÕES ---
# Coloque aqui o link do SEU repositório (HTTPS para pedir senha/token ou SSH se já tiver chave)
REPO_URL="https://github.com/SEU_USUARIO/dotfiles.git"
DOTFILES_DIR="$HOME/.local/share/dotfiles"

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}### INICIANDO RESTAURAÇÃO DO SISTEMA ###${NC}"

# 1. Atualizar e instalar bases essenciais (Git e Stow são obrigatórios)
echo -e "${GREEN}[1/5] Atualizando sistema e instalando base...${NC}"
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel git stow

# 2. Instalar o Paru (se não existir)
if ! command -v paru &> /dev/null; then
    echo -e "${GREEN}[2/5] Instalando Paru...${NC}"
    git clone https://aur.archlinux.org/paru-bin.git
    cd paru-bin
    makepkg -si --noconfirm
    cd ..
    rm -rf paru-bin
else
    echo -e "${GREEN}[2/5] Paru já instalado.${NC}"
fi

# 3. Baixar e Instalar Pacotes (Oficiais e AUR)
# Verifica se os arquivos de lista existem na mesma pasta do script
if [ -f "pkgs-native.txt" ]; then
    echo -e "${GREEN}[3/5] Instalando pacotes oficiais...${NC}"
    sudo pacman -S --needed --noconfirm - < pkgs-native.txt
fi

if [ -f "pkgs-aur.txt" ]; then
    echo -e "${GREEN}[3/5] Instalando pacotes do AUR...${NC}"
    paru -S --needed --noconfirm - < pkgs-aur.txt
fi

# 4. Clonar suas Dotfiles
if [ -d "$DOTFILES_DIR" ]; then
    echo -e "${BLUE}A pasta $DOTFILES_DIR já existe. Pulando clone.${NC}"
else
    echo -e "${GREEN}[4/5] Clonando dotfiles em $DOTFILES_DIR...${NC}"
    echo "Se o repo for privado, use seu Token de Acesso Pessoal (PAT) como senha."
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# 5. Aplicar Configurações com Stow
echo -e "${GREEN}[5/5] Aplicando configurações (Symlinks)...${NC}"

if [ -d "$DOTFILES_DIR" ]; then
    cd "$DOTFILES_DIR"

    # --- LIMPEZA DE CONFLITOS ---
    # O Stow falha se o arquivo de destino já existir.
    # Vamos remover configs padrões comuns que atrapalham.
    # Adicione aqui qualquer outra pasta que dê erro de "existing target".
    echo "Removendo configs padrões para evitar conflitos..."
    rm -rf ~/.config/nvim ~/.config/fish ~/.config/kitty 2>/dev/null
    rm -f ~/.bashrc 2>/dev/null

    # --- APLICAR STOW ---
    # -t ~ : Define o alvo como a Home do usuário
    # .    : Aplica o diretório atual
    stow -t "$HOME" .
    
    echo -e "${GREEN}Configurações linkadas com sucesso!${NC}"
else
    echo -e "${RED}Erro: Diretório de dotfiles não encontrado.${NC}"
fi

echo -e "${BLUE}### INSTALAÇÃO CONCLUÍDA! ###${NC}"
echo "Recomendado reiniciar o sistema ou a sessão."
