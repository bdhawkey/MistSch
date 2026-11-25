#!/usr/bin/env bash
# Runs on the EC2 instance. Installs nginx if needed and publishes the site.
# Usage: deploy.sh <site-directory>
set -euo pipefail

SRC="${1:?usage: deploy.sh <site-directory>}"

if ! command -v nginx >/dev/null 2>&1; then
  if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y nginx
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
  else
    echo "No supported package manager (dnf or apt-get) found" >&2
    exit 1
  fi
fi

# Ubuntu/Debian serve /var/www/html, Amazon Linux/RHEL serve /usr/share/nginx/html.
if [ -d /var/www/html ]; then ROOT=/var/www/html; else ROOT=/usr/share/nginx/html; fi

sudo cp -r "$SRC"/. "$ROOT"/

# Browsers must revalidate on every load so new deploys show without a hard refresh.
# Unchanged files still return a cheap 304 thanks to ETag/Last-Modified.
echo 'add_header Cache-Control "no-cache" always;' | sudo tee /etc/nginx/conf.d/mistsch-nocache.conf >/dev/null

sudo nginx -t
sudo systemctl enable --now nginx
sudo systemctl reload nginx

# Capture first: piping into grep -q under pipefail fails when grep exits early.
page="$(curl -fsS http://localhost/)"
[[ "$page" == *'<title>Snake</title>'* ]] || { echo "Site check failed" >&2; exit 1; }
echo "Deployed to $ROOT"
