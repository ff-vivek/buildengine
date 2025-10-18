#!/bin/bash

# BuildEngine Server Installation Script for Linux
# Version: 1.0.0

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation directory
INSTALL_DIR="/opt/buildengine"
SERVICE_USER="buildengine"
SERVICE_GROUP="buildengine"
CONFIG_DIR="/etc/buildengine"
LOG_DIR="/var/log/buildengine"
DATA_DIR="/var/lib/buildengine"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi
}

# Function to install system dependencies
install_dependencies() {
    print_status "Installing system dependencies..."
    
    case $DISTRO in
        ubuntu|debian)
            apt-get update
            apt-get install -y curl wget unzip git build-essential
            ;;
        centos|rhel|fedora)
            if command -v dnf &> /dev/null; then
                dnf install -y curl wget unzip git gcc gcc-c++ make
            else
                yum install -y curl wget unzip git gcc gcc-c++ make
            fi
            ;;
        arch|manjaro)
            pacman -S --noconfirm curl wget unzip git base-devel
            ;;
        *)
            print_warning "Unsupported distribution: $DISTRO"
            print_warning "Please install the following packages manually:"
            print_warning "- curl, wget, unzip, git, build-essential (or equivalent)"
            ;;
    esac
}

# Function to install Dart SDK
install_dart() {
    print_status "Installing Dart SDK..."
    
    if command -v dart &> /dev/null; then
        DART_VERSION=$(dart --version | cut -d' ' -f4)
        print_success "Dart SDK already installed: $DART_VERSION"
        return
    fi
    
    # Download and install Dart SDK
    DART_VERSION="3.4.4"
    DART_ARCH="linux-x64"
    DART_URL="https://storage.googleapis.com/dart-archive/channels/stable/release/${DART_VERSION}/sdk/dartsdk-${DART_ARCH}-release.zip"
    
    cd /tmp
    wget -O dart-sdk.zip "$DART_URL"
    unzip dart-sdk.zip
    mv dart-sdk /opt/dart-sdk
    
    # Add Dart to PATH
    echo 'export PATH="/opt/dart-sdk/bin:$PATH"' >> /etc/environment
    export PATH="/opt/dart-sdk/bin:$PATH"
    
    # Create symlink for system-wide access
    ln -sf /opt/dart-sdk/bin/dart /usr/local/bin/dart
    ln -sf /opt/dart-sdk/bin/pub /usr/local/bin/pub
    
    print_success "Dart SDK installed successfully"
}

# Function to create system user
create_user() {
    print_status "Creating system user and group..."
    
    if ! getent group $SERVICE_GROUP > /dev/null 2>&1; then
        groupadd $SERVICE_GROUP
        print_success "Created group: $SERVICE_GROUP"
    else
        print_status "Group $SERVICE_GROUP already exists"
    fi
    
    if ! getent passwd $SERVICE_USER > /dev/null 2>&1; then
        useradd -r -g $SERVICE_GROUP -d $INSTALL_DIR -s /bin/false $SERVICE_USER
        print_success "Created user: $SERVICE_USER"
    else
        print_status "User $SERVICE_USER already exists"
    fi
}

# Function to create directories
create_directories() {
    print_status "Creating directories..."
    
    mkdir -p $INSTALL_DIR/{bin,lib,config}
    mkdir -p $CONFIG_DIR
    mkdir -p $LOG_DIR
    mkdir -p $DATA_DIR/{storage,workspace}
    
    chown -R $SERVICE_USER:$SERVICE_GROUP $INSTALL_DIR
    chown -R $SERVICE_USER:$SERVICE_GROUP $CONFIG_DIR
    chown -R $SERVICE_USER:$SERVICE_GROUP $LOG_DIR
    chown -R $SERVICE_USER:$SERVICE_GROUP $DATA_DIR
    
    print_success "Directories created successfully"
}

# Function to install BuildEngine server
install_buildengine() {
    print_status "Installing BuildEngine server..."
    
    # Copy server binary
    cp buildengine_server $INSTALL_DIR/bin/
    chmod +x $INSTALL_DIR/bin/buildengine_server
    
    # Copy configuration files
    cp config/* $CONFIG_DIR/ 2>/dev/null || true
    
    # Create default configuration if it doesn't exist
    if [ ! -f $CONFIG_DIR/config.yaml ]; then
        cat > $CONFIG_DIR/config.yaml << EOF
# BuildEngine Server Configuration
server:
  host: "0.0.0.0"
  port: 8080
  
database:
  path: "$DATA_DIR/buildengine.db"
  
storage:
  local_path: "$DATA_DIR/storage"
  workspace_path: "$DATA_DIR/workspace"
  
logging:
  level: "INFO"
  file: "$LOG_DIR/buildengine.log"
  
flutter:
  sdk_path: "/opt/dart-sdk"
  
security:
  enable_cors: true
  allowed_origins: ["*"]
EOF
    fi
    
    chown -R $SERVICE_USER:$SERVICE_GROUP $INSTALL_DIR
    chown -R $SERVICE_USER:$SERVICE_GROUP $CONFIG_DIR
    
    print_success "BuildEngine server installed successfully"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    cat > /etc/systemd/system/buildengine.service << EOF
[Unit]
Description=BuildEngine Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_GROUP
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/bin/buildengine_server --config=$CONFIG_DIR/config.yaml
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=buildengine

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$DATA_DIR $LOG_DIR $CONFIG_DIR

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    print_success "Systemd service created successfully"
}

# Function to install FlutterFlow CLI
install_flutterflow_cli() {
    print_status "Installing FlutterFlow CLI..."
    
    # Switch to service user to install CLI
    sudo -u $SERVICE_USER bash -c "
        export PATH='/opt/dart-sdk/bin:$PATH'
        dart pub global activate flutterflow_cli
    "
    
    print_success "FlutterFlow CLI installed successfully"
}

# Function to start and enable service
start_service() {
    print_status "Starting BuildEngine service..."
    
    systemctl enable buildengine
    systemctl start buildengine
    
    sleep 2
    
    if systemctl is-active --quiet buildengine; then
        print_success "BuildEngine service started successfully"
        print_status "Service status:"
        systemctl status buildengine --no-pager
    else
        print_error "Failed to start BuildEngine service"
        print_status "Service logs:"
        journalctl -u buildengine --no-pager -n 20
        exit 1
    fi
}

# Function to create management scripts
create_management_scripts() {
    print_status "Creating management scripts..."
    
    # Create start script
    cat > $INSTALL_DIR/bin/start-buildengine.sh << 'EOF'
#!/bin/bash
sudo systemctl start buildengine
echo "BuildEngine service started"
EOF
    
    # Create stop script
    cat > $INSTALL_DIR/bin/stop-buildengine.sh << 'EOF'
#!/bin/bash
sudo systemctl stop buildengine
echo "BuildEngine service stopped"
EOF
    
    # Create restart script
    cat > $INSTALL_DIR/bin/restart-buildengine.sh << 'EOF'
#!/bin/bash
sudo systemctl restart buildengine
echo "BuildEngine service restarted"
EOF
    
    # Create status script
    cat > $INSTALL_DIR/bin/status-buildengine.sh << 'EOF'
#!/bin/bash
sudo systemctl status buildengine --no-pager
EOF
    
    # Create logs script
    cat > $INSTALL_DIR/bin/logs-buildengine.sh << 'EOF'
#!/bin/bash
sudo journalctl -u buildengine -f
EOF
    
    chmod +x $INSTALL_DIR/bin/*.sh
    chown -R $SERVICE_USER:$SERVICE_GROUP $INSTALL_DIR/bin
    
    print_success "Management scripts created successfully"
}

# Function to create uninstall script
create_uninstall_script() {
    print_status "Creating uninstall script..."
    
    cat > $INSTALL_DIR/uninstall.sh << 'EOF'
#!/bin/bash

# BuildEngine Server Uninstall Script

set -e

print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    print_error "This script must be run as root (use sudo)"
    exit 1
fi

print_warning "This will completely remove BuildEngine server and all its data!"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_status "Uninstall cancelled"
    exit 0
fi

print_status "Stopping BuildEngine service..."
systemctl stop buildengine || true
systemctl disable buildengine || true

print_status "Removing systemd service..."
rm -f /etc/systemd/system/buildengine.service
systemctl daemon-reload

print_status "Removing BuildEngine files..."
rm -rf /opt/buildengine
rm -rf /etc/buildengine
rm -rf /var/log/buildengine
rm -rf /var/lib/buildengine

print_status "Removing system user..."
userdel buildengine || true
groupdel buildengine || true

print_success "BuildEngine server uninstalled successfully"
EOF
    
    chmod +x $INSTALL_DIR/uninstall.sh
    print_success "Uninstall script created"
}

# Function to display installation summary
show_summary() {
    print_success "BuildEngine Server installation completed successfully!"
    echo
    echo "Installation Summary:"
    echo "===================="
    echo "Installation Directory: $INSTALL_DIR"
    echo "Configuration Directory: $CONFIG_DIR"
    echo "Data Directory: $DATA_DIR"
    echo "Log Directory: $LOG_DIR"
    echo "Service User: $SERVICE_USER"
    echo "Service Group: $SERVICE_GROUP"
    echo
    echo "Service Management:"
    echo "=================="
    echo "Start:   sudo systemctl start buildengine"
    echo "Stop:    sudo systemctl stop buildengine"
    echo "Restart: sudo systemctl restart buildengine"
    echo "Status:  sudo systemctl status buildengine"
    echo "Logs:    sudo journalctl -u buildengine -f"
    echo
    echo "Management Scripts:"
    echo "=================="
    echo "Start:   $INSTALL_DIR/bin/start-buildengine.sh"
    echo "Stop:    $INSTALL_DIR/bin/stop-buildengine.sh"
    echo "Restart: $INSTALL_DIR/bin/restart-buildengine.sh"
    echo "Status:  $INSTALL_DIR/bin/status-buildengine.sh"
    echo "Logs:    $INSTALL_DIR/bin/logs-buildengine.sh"
    echo
    echo "Configuration:"
    echo "==============="
    echo "Config file: $CONFIG_DIR/config.yaml"
    echo "Database: $DATA_DIR/buildengine.db"
    echo
    echo "API Endpoint: http://localhost:8080"
    echo
    print_success "BuildEngine server is now running and ready to use!"
}

# Main installation function
main() {
    echo "BuildEngine Server Installation Script"
    echo "======================================="
    echo
    
    check_root
    detect_distro
    install_dependencies
    install_dart
    create_user
    create_directories
    install_buildengine
    create_systemd_service
    install_flutterflow_cli
    create_management_scripts
    create_uninstall_script
    start_service
    show_summary
}

# Run main function
main "$@"

