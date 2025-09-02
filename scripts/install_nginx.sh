#!/usr/bin/env bash
set -euo pipefail

if command -v yum >/dev/null 2>&1; then
  sudo yum -y install nginx || sudo amazon-linux-extras install -y nginx1
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf -y install nginx
else
  echo "Unsupported package manager" >&2
  exit 1
fi

sudo systemctl enable nginx
sudo systemctl start nginx

echo 'Hello via ALB (private EC2, SSM-managed).' | sudo tee /usr/share/nginx/html/index.html
