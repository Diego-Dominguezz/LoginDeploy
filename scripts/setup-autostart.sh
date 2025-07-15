#!/bin/bash
# setup-autostart.sh - Script to set up automatic startup on EC2

# Create systemd service file
sudo tee /etc/systemd/system/login-app.service > /dev/null << 'EOF'
[Unit]
Description=Login App Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu
ExecStart=/usr/local/bin/docker-compose -f docker-compose.testing.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.testing.yml down
TimeoutStartSec=0
User=ubuntu
Group=docker

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable login-app.service

echo "✅ Auto-start service created and enabled!"
echo "Your app will now automatically start when EC2 boots."
echo ""
echo "Useful commands:"
echo "  sudo systemctl status login-app    # Check service status"
echo "  sudo systemctl start login-app     # Start service manually"
echo "  sudo systemctl stop login-app      # Stop service manually"
echo "  sudo systemctl restart login-app   # Restart service"
