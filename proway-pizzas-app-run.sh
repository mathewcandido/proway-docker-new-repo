#!/bin/bash

# ===================================================================================
# Script de Deploy Autônomo para o Projeto Pizzaria (v2 - Corrigido)
#
# Changelog:
# - A verificação de dependência do Docker agora checa pela existência do 
#   arquivo do repositório, garantindo que a configuração sempre ocorra se
#   necessário, mesmo que versões antigas do Docker estejam presentes.
# ===================================================================================

# --- Configurações ---
set -euo pipefail # Script para de executar em caso de erro

readonly REPO_URL="https://github.com/mathewcandido/proway-docker-new-repo.git"
readonly APP_DIR="/opt/proway-docker"
readonly SCRIPT_PATH="$APP_DIR/scripts/deploy.sh"
readonly LOG_FILE="/var/log/pizzaria-deploy.log"

# --- Funções Auxiliares ---
info() { echo "[INFO] $1"; }
success() { echo "✅ $1"; }
error() { echo "❌ [ERRO] $1" >&2; exit 1; }

# --- Funções Principais ---

function initial_setup() {
    info "Iniciando configuração inicial..."
    if [ "$EUID" -ne 0 ]; then
        error "Este script precisa ser executado com privilégios de superusuário (sudo)."
    fi
    mkdir -p "$(dirname "$SCRIPT_PATH")"
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chown -R "$SUDO_USER":"$SUDO_USER" "$APP_DIR"
    info "Diretório $APP_DIR configurado."
}

function install_dependencies() {
    info "Verificando e instalando dependências..."
    apt-get update -y

    # --- Instalação do Docker (do repositório oficial) ---
    # VERIFICAÇÃO CORRIGIDA: Checa se o repositório já está configurado.
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        info "Repositório oficial do Docker não encontrado. Configurando agora..."
        
        # Remove pacotes conflitantes antigos para uma instalação limpa
        apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc || true
        
        apt-get install -y ca-certificates curl
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Atualiza a lista de pacotes DEPOIS de adicionar o novo repositório
        apt-get update -y
    fi

    # Com o repositório garantido, instala os pacotes corretos
    apt-get install -y git docker-ce docker-ce-cli containerd.io docker-compose-plugin python3-venv curl
    systemctl enable --now docker
    success "Docker e Docker Compose V2 instalados e ativos."

    # --- Instalação do Yarn ---
    if ! command -v yarn &> /dev/null; then
        info "Yarn não encontrado. Instalando..."
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
        apt-get update -y && apt-get install -y yarn
        success "Yarn instalado."
    fi
}

function manage_repo() {
    info "Gerenciando o repositório..."
    if [ ! -d "$APP_DIR/.git" ]; then
        info "Clonando repositório pela primeira vez..."
        git clone "$REPO_URL" "$APP_DIR"
    else
        info "Buscando atualizações no repositório..."
        cd "$APP_DIR" || exit
        sudo -u "$SUDO_USER" git config --global --add safe.directory "$APP_DIR"
        sudo -u "$SUDO_USER" git fetch origin main
    fi
}

function generate_docker_compose() {
    info "Gerando arquivo docker-compose.yml..."
    local frontend_dir backend_dir compose_file
    
    frontend_dir=$(find "$APP_DIR" -maxdepth 2 -type d -iname "*front*" -print -quit)
    backend_dir=$(find "$APP_DIR" -maxdepth 2 -type d -iname "*back*" -print -quit)
    compose_file="$APP_DIR/docker-compose.yml"

    if [ -z "$frontend_dir" ] || [ -z "$backend_dir" ]; then
        error "Não foi possível encontrar os diretórios de frontend e/ou backend."
    fi

    local frontend_rel_path backend_rel_path
    frontend_rel_path=$(realpath --relative-to="$APP_DIR" "$frontend_dir")
    backend_rel_path=$(realpath --relative-to="$APP_DIR" "$backend_dir")

    cat > "$compose_file" <<EOL
version: "3.9"
services:
  frontend:
    build: ./${frontend_rel_path}
    ports: ["8080:80"]
    depends_on: [backend]
  backend:
    build: ./${backend_rel_path}
    ports: ["5001:5000"]
EOL
    success "docker-compose.yml gerado com sucesso."
}

function run_docker_containers() {
    info "Verificando a necessidade de reconstruir os contêineres..."
    cd "$APP_DIR" || exit
    
    local last_hash_file current_hash last_hash build_required=false
    last_hash_file="$APP_DIR/.last_commit_hash"
    current_hash=$(sudo -u "$SUDO_USER" git rev-parse origin/main)

    if [ -f "$last_hash_file" ]; then
        last_hash=$(cat "$last_hash_file")
    else
        last_hash=""
    fi

    if [ "$current_hash" != "$last_hash" ]; then
        info "Novas alterações detectadas. A reconstrução é necessária."
        sudo -u "$SUDO_USER" git reset --hard origin/main
        echo "$current_hash" > "$last_hash_file"
        build_required=true
    else
        info "Nenhuma alteração detectada."
    fi
    
    if [ "$build_required" = true ]; then
        info "Reconstruindo e iniciando os contêineres..."
        docker compose up -d --build
    else
        info "Iniciando contêineres existentes..."
        docker compose up -d
    fi
    success "Contêineres estão em execução."
}

function setup_cron() {
    local cron_entry="*/5 * * * * $0 >> $LOG_FILE 2>&1"
    
    if ! (crontab -l 2>/dev/null | grep -Fq "$0"); then
        info "Adicionando script ao crontab para execução a cada 5 minutos."
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    else
        info "Tarefa no crontab já configurada."
    fi
}

# --- Ponto de Entrada do Script ---
function main() {
    initial_setup
    install_dependencies
    manage_repo
    generate_docker_compose
    run_docker_containers
    setup_cron

    # Mensagem final
    echo -e "\n\n======================================================="
    success "PROCESSO DE DEPLOY CONCLUÍDO!"
    echo " "
    echo "  ➡️  Acesse o Frontend em: http://127.0.0.1:8080"
    echo "  ➡️  Acesse o Backend em:  http://127.0.0.1:5001"
    echo " "
    echo "  ℹ️   Logs de execução são salvos em: $LOG_FILE"
    echo "======================================================="
}

# Executa a função principal
main