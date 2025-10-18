#!/bin/bash

# BuildEngine Server Startup Script
# This script sets up the necessary environment and starts the BuildEngine server

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$SCRIPT_DIR/server"

# Change to server directory
cd "$SERVER_DIR"

# Create symbolic link for SQLite library if it doesn't exist
if [ ! -L "lib/libsqlite3.so" ]; then
    echo "Creating SQLite library symbolic link..."
    mkdir -p lib
    ln -sf /usr/lib/aarch64-linux-gnu/libsqlite3.so.0 lib/libsqlite3.so
fi

# Set LD_LIBRARY_PATH to include our lib directory
export LD_LIBRARY_PATH="./lib:$LD_LIBRARY_PATH"

# Start the server
echo "Starting BuildEngine Server..."
dart run bin/buildengine_server.dart
