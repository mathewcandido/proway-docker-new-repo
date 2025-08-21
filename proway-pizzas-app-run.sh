#!/bin/bash

# ===================================================================================
# Autonomous Deploy Script for Pizzaria Project (v2 - Fixed)
#
# Changelog:
# - Docker dependency check now looks for the repository file, ensuring configuration
#   always occurs if needed, even if old Docker versions are present.
# ===================================================================================

# --- Settings ---
set -euo pipefail # Script stops execution on error

readonly REPO_URL="https://github.com/mathewcandido/proway-docker-new-repo.git"
readonly APP_DIR="/opt/proway-docker"
readonly SCRIPT_PATH="$APP_DIR/scripts/deploy.sh"
readonly LOG_FILE="/var/log/pizzaria-deploy.log"

# --- Helper Functions ---
info() { echo "[INFO] $1"; }
success() { echo "✅ $1"; }
error() { echo "❌ [ERROR] $1" >&2; exit 1; }

# --- Main Functions ---

function initial_setup() {
    info "Starting initial setup..."
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run with superuser privileges (sudo)."
    fi
    mkdir -p "$(dirname "$SCRIPT_PATH")"
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chown -R "$SUDO_USER":"$SUDO_USER" "$APP_DIR"
    info "Directory $APP_DIR configured."
}

function install_dependencies() {
    info "Checking and installing dependencies..."
    apt-get update -y

    # --- Docker Installation (from official repository) ---
    # FIXED CHECK: Checks if the repository is already configured.
    if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
        info "Official Docker repository not found. Configuring now..."
        
        # Removes old conflicting packages for a clean install
        apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc || true
        
        apt-get install -y ca-certificates curl
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
          $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
          tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Updates package list AFTER adding the new repository
        apt-get update -y
    fi

    # With the repository ensured, installs the correct packages
    apt-get install -y git docker-ce docker-ce-cli containerd.io docker-compose-plugin python3-venv curl
    systemctl enable --now docker
    success "Docker and Docker Compose V2 installed and active."

    # --- Yarn Installation ---
    if ! command -v yarn &> /dev/null; then
        info "Yarn not found. Installing..."
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
        apt-get update -y && apt-get install -y yarn
        success "Yarn installed."
    fi
}

function manage_repo() {
    info "Managing repository..."
    if [ ! -d "$APP_DIR/.git" ]; then
        info "Cloning repository for the first time..."
        git clone "$REPO_URL" "$APP_DIR"
    else
        info "Fetching updates from repository..."
        cd "$APP_DIR" || exit
        sudo -u "$SUDO_USER" git config --global --add safe.directory "$APP_DIR"
        sudo -u "$SUDO_USER" git fetch origin main
    fi
}

function generate_docker_compose() {
    info "Generating docker-compose.yml file..."
    local frontend_dir backend_dir compose_file
    
    frontend_dir=$(find "$APP_DIR" -maxdepth 2 -type d -iname "*front*" -print -quit)
    backend_dir=$(find "$APP_DIR" -maxdepth 2 -type d -iname "*back*" -print -quit)
    compose_file="$APP_DIR/docker-compose.yml"

    if [ -z "$frontend_dir" ] || [ -z "$backend_dir" ]; then
        error "Could not find frontend and/or backend directories."
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
    success "docker-compose.yml generated successfully."
}

function run_docker_containers() {
    info "Checking if containers need to be rebuilt..."
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
        info "New changes detected. Rebuild is required."
        sudo -u "$SUDO_USER" git reset --hard origin/main
        echo "$current_hash" > "$last_hash_file"
        build_required=true
    else
        info "No changes detected."
    fi
    
    if [ "$build_required" = true ]; then
        info "Rebuilding and starting containers..."
        docker compose up -d --build
    else
        info "Starting existing containers..."
        docker compose up -d
    fi
    success "Containers are running."
}

function setup_cron() {
    local cron_entry="*/5 * * * * $0 >> $LOG_FILE 2>&1"
    
    if ! (crontab -l 2>/dev/null | grep -Fq "$0"); then
        info "Adding script to crontab for execution every 5 minutes."
        (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -
    else
        info "Crontab task already configured."
    fi
}

# --- Script Entry Point ---
function main() {
    initial_setup
    install_dependencies
    manage_repo
    generate_docker_compose
    run_docker_containers
    setup_cron

    # Final message
    echo -e "\n\n======================================================="
    success "DEPLOY PROCESS COMPLETED!"
    echo " "
    echo "  ➡️  Access Frontend at: http://127.0.0.1:8080"
    echo "  ➡️  Access Backend at:  http://127.0.0.1:5001"
    echo " "
    echo "  ℹ️   Execution logs are saved at: $LOG_FILE"
    echo "======================================================="
}

# Run main function
main
