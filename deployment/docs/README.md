# BuildEngine Server - Linux Deployment Package

BuildEngine is a powerful Flutter build service that provides automated building, packaging, and deployment capabilities for Flutter applications. This package provides everything needed to install and run BuildEngine on Linux systems.

## Features

- **Automated Flutter Builds**: Support for web, Android, and iOS builds
- **Multiple Source Types**: Upload ZIP files, Git repositories, or FlutterFlow projects
- **Artifact Management**: Automatic packaging and storage of build artifacts
- **RESTful API**: Complete API for integration with CI/CD pipelines
- **Systemd Integration**: Automatic startup and service management
- **Security**: Built-in CORS, rate limiting, and security features
- **Monitoring**: Health checks and metrics collection
- **Scalable**: Support for concurrent build jobs

## System Requirements

### Minimum Requirements
- **OS**: Linux (Ubuntu 18.04+, CentOS 7+, Debian 9+, Fedora 30+)
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 10GB free space minimum
- **CPU**: 2 cores minimum, 4 cores recommended

### Dependencies
- **Dart SDK**: 3.0.0 or higher (automatically installed)
- **System Packages**: curl, wget, unzip, git, build-essential
- **Optional**: Node.js (for FlutterFlow CLI via npm)

## Quick Installation

### Automated Installation

1. **Download the package**:
   ```bash
   wget https://releases.buildengine.com/latest/buildengine-server-linux.tar.gz
   tar -xzf buildengine-server-linux.tar.gz
   cd buildengine-server-linux
   ```

2. **Run the installer**:
   ```bash
   sudo ./scripts/install.sh
   ```

3. **Verify installation**:
   ```bash
   sudo systemctl status buildengine
   curl http://localhost:8080/health
   ```

### Manual Installation

If you prefer manual installation or need custom configuration:

1. **Install system dependencies**:
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install curl wget unzip git build-essential
   
   # CentOS/RHEL/Fedora
   sudo yum install curl wget unzip git gcc gcc-c++ make
   ```

2. **Install Dart SDK**:
   ```bash
   curl -fsSL https://storage.googleapis.com/dart-archive/channels/stable/release/latest/sdk/dartsdk-linux-x64-release.zip -o dart-sdk.zip
   unzip dart-sdk.zip
   sudo mv dart-sdk /opt/dart-sdk
   sudo ln -sf /opt/dart-sdk/bin/dart /usr/local/bin/dart
   ```

3. **Create system user**:
   ```bash
   sudo groupadd buildengine
   sudo useradd -r -g buildengine -d /opt/buildengine -s /bin/false buildengine
   ```

4. **Install BuildEngine**:
   ```bash
   sudo mkdir -p /opt/buildengine/{bin,lib,config}
   sudo cp buildengine_server /opt/buildengine/bin/
   sudo cp config/* /etc/buildengine/
   sudo chown -R buildengine:buildengine /opt/buildengine /etc/buildengine
   ```

5. **Create systemd service**:
   ```bash
   sudo cp config/buildengine.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable buildengine
   sudo systemctl start buildengine
   ```

## Configuration

### Main Configuration File

The main configuration file is located at `/etc/buildengine/config.yaml`. Key configuration options:

```yaml
# Server settings
server:
  host: "0.0.0.0"  # Bind to all interfaces
  port: 8080       # Server port

# Storage settings
storage:
  local_path: "/var/lib/buildengine/storage"
  workspace_path: "/var/lib/buildengine/workspace"
  max_storage_size: 10737418240  # 10GB

# Build settings
build:
  max_concurrent_jobs: 5
  build_timeout: 1800  # 30 minutes

# Security settings
security:
  enable_cors: true
  allowed_origins: ["*"]
```

### Environment Variables

You can override configuration using environment variables:

```bash
export BUILDENGINE_PORT=8080
export BUILDENGINE_HOST=0.0.0.0
export BUILDENGINE_CONFIG=/etc/buildengine/config.yaml
export BUILDENGINE_DATA=/var/lib/buildengine
export BUILDENGINE_LOGS=/var/log/buildengine
```

## Service Management

### Using systemctl

```bash
# Start the service
sudo systemctl start buildengine

# Stop the service
sudo systemctl stop buildengine

# Restart the service
sudo systemctl restart buildengine

# Check status
sudo systemctl status buildengine

# View logs
sudo journalctl -u buildengine -f
```

### Using Management Scripts

Convenience scripts are installed in `/opt/buildengine/bin/`:

```bash
# Start service
sudo /opt/buildengine/bin/start-buildengine.sh

# Stop service
sudo /opt/buildengine/bin/stop-buildengine.sh

# Restart service
sudo /opt/buildengine/bin/restart-buildengine.sh

# Check status
sudo /opt/buildengine/bin/status-buildengine.sh

# View logs
sudo /opt/buildengine/bin/logs-buildengine.sh
```

## API Usage

### Health Check

```bash
curl http://localhost:8080/health
```

### Create a Build Job

```bash
curl -X POST http://localhost:8080/api/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "source": {
      "type": "uploadZip",
      "uploadId": "your-upload-id"
    },
    "config": {
      "buildType": "release",
      "platform": "web",
      "flutterVersion": "3.24.0"
    }
  }'
```

### Check Job Status

```bash
curl http://localhost:8080/api/jobs/job-id
```

### Download Artifacts

```bash
curl http://localhost:8080/api/artifacts/job-id/download
```

## Directory Structure

```
/opt/buildengine/           # Installation directory
├── bin/
│   ├── buildengine_server  # Main executable
│   └── *.sh                # Management scripts
├── lib/                    # Library files
└── config/                 # Configuration files

/etc/buildengine/           # Configuration directory
└── config.yaml             # Main configuration file

/var/lib/buildengine/        # Data directory
├── buildengine.db          # SQLite database
├── storage/                # Uploads and artifacts
└── workspace/              # Build workspaces

/var/log/buildengine/        # Log directory
└── buildengine.log         # Application logs
```

## Monitoring and Logs

### Log Files

- **Application Logs**: `/var/log/buildengine/buildengine.log`
- **System Logs**: `journalctl -u buildengine`
- **Service Logs**: `/var/log/syslog` (Ubuntu/Debian) or `/var/log/messages` (CentOS/RHEL)

### Health Monitoring

The service provides several monitoring endpoints:

- **Health Check**: `GET /health`
- **Metrics**: `GET /metrics`
- **API Status**: `GET /api/status`

### Performance Monitoring

Monitor key metrics:

```bash
# Check service status
sudo systemctl status buildengine

# Monitor resource usage
sudo systemctl show buildengine --property=MemoryCurrent,CPUUsageNSec

# Check disk usage
du -sh /var/lib/buildengine/storage
du -sh /var/lib/buildengine/workspace
```

## Troubleshooting

### Common Issues

1. **Service won't start**:
   ```bash
   sudo journalctl -u buildengine -n 50
   sudo systemctl status buildengine
   ```

2. **Permission errors**:
   ```bash
   sudo chown -R buildengine:buildengine /var/lib/buildengine
   sudo chown -R buildengine:buildengine /var/log/buildengine
   ```

3. **Port already in use**:
   ```bash
   sudo netstat -tlnp | grep :8080
   sudo lsof -i :8080
   ```

4. **Dart SDK not found**:
   ```bash
   export PATH="/opt/dart-sdk/bin:$PATH"
   dart --version
   ```

### Debug Mode

Enable debug logging by modifying `/etc/buildengine/config.yaml`:

```yaml
logging:
  level: "DEBUG"
  enable_console: true
```

Then restart the service:

```bash
sudo systemctl restart buildengine
```

## Security Considerations

### Firewall Configuration

```bash
# Allow HTTP traffic
sudo ufw allow 8080/tcp

# Or for specific IP ranges
sudo ufw allow from 192.168.1.0/24 to any port 8080
```

### SSL/TLS Configuration

For production deployments, consider using a reverse proxy (nginx, Apache) with SSL termination:

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### API Key Authentication

Enable API key authentication in `/etc/buildengine/config.yaml`:

```yaml
security:
  enable_api_key: true
  api_key: "your-secure-api-key"
```

## Backup and Recovery

### Database Backup

```bash
# Backup database
sudo cp /var/lib/buildengine/buildengine.db /backup/buildengine-$(date +%Y%m%d).db

# Restore database
sudo systemctl stop buildengine
sudo cp /backup/buildengine-20240101.db /var/lib/buildengine/buildengine.db
sudo chown buildengine:buildengine /var/lib/buildengine/buildengine.db
sudo systemctl start buildengine
```

### Full Backup

```bash
# Create full backup
sudo tar -czf buildengine-backup-$(date +%Y%m%d).tar.gz \
  /var/lib/buildengine \
  /etc/buildengine \
  /var/log/buildengine
```

## Uninstallation

### Automated Uninstallation

```bash
sudo /opt/buildengine/uninstall.sh
```

### Manual Uninstallation

```bash
# Stop and disable service
sudo systemctl stop buildengine
sudo systemctl disable buildengine

# Remove service file
sudo rm /etc/systemd/system/buildengine.service
sudo systemctl daemon-reload

# Remove files and directories
sudo rm -rf /opt/buildengine
sudo rm -rf /etc/buildengine
sudo rm -rf /var/lib/buildengine
sudo rm -rf /var/log/buildengine

# Remove user and group
sudo userdel buildengine
sudo groupdel buildengine
```

## Support and Documentation

- **GitHub Repository**: https://github.com/your-org/buildengine
- **Documentation**: https://docs.buildengine.com
- **API Reference**: https://api.buildengine.com/docs
- **Community Forum**: https://community.buildengine.com

## License

This software is licensed under the MIT License. See the LICENSE file for details.

## Changelog

### Version 1.0.0
- Initial release
- Support for Flutter web, Android, and iOS builds
- RESTful API with comprehensive endpoints
- Systemd integration
- Automatic FlutterFlow CLI installation
- Security features and rate limiting
- Health monitoring and metrics

