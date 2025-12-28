#!/bin/bash
set -e

# ==========================================================
# LIFERS SCRIPT v2 - FINAL
# Cloudflare DNS Validation + Wildcard SSL
# One Domain Per Install (STRICT)
# ==========================================================

clear

GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

LOCK_FILE="/tmp/lifers_script.lock"

# ===== SINGLE RUN LOCK =====
if [ -f "$LOCK_FILE" ]; then
  echo -e "${RED}Another LIFERS SCRIPT process is running.${RESET}"
  exit 1
fi
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# ===== LOAD BANNER =====
if [ -f assets/banner.txt ]; then
  cat assets/banner.txt
else
  echo "LIFERS SCRIPT v2"
fi

echo ""

# ===== CHECK ROOT =====
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Run this script as root.${RESET}"
  exit 1
fi

# ===== CHECK DEPENDENCIES =====
for cmd in nginx certbot curl; do
  if ! command -v $cmd >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing missing dependency: $cmd${RESET}"
    apt update -y
    apt install -y $cmd
  fi
done

# ===== USER INPUT =====
read -p "Enter root domain (example.com): " DOMAIN
read -p "Enter Cloudflare API Token: " CF_TOKEN
read -p "Enter email for SSL registration: " EMAIL

echo ""
read -p "Create Wildcard SSL for *.$DOMAIN ? (y/n): " CONFIRM
[ "$CONFIRM" != "y" ] && echo "Cancelled." && exit 0

# ===== DOMAIN VALIDATION =====
if [[ "$DOMAIN" =~ [^a-zA-Z0-9.-] ]]; then
  echo -e "${RED}Invalid domain format.${RESET}"
  exit 1
fi

# ===== CLOUDFLARE CREDENTIALS =====
CF_DIR="/root/.secrets/certbot"
CF_FILE="$CF_DIR/cloudflare.ini"

mkdir -p "$CF_DIR"
chmod 700 "$CF_DIR"

cat <<EOF > "$CF_FILE"
dns_cloudflare_api_token = $CF_TOKEN
EOF

chmod 600 "$CF_FILE"

# ===== INSTALL CLOUDFLARE PLUGIN =====
if ! certbot plugins | grep -q cloudflare; then
  echo -e "${CYAN}Installing Cloudflare DNS plugin...${RESET}"
  apt install -y python3-certbot-dns-cloudflare
fi

# ===== REQUEST WILDCARD SSL =====
echo -e "${CYAN}Requesting Wildcard SSL certificate...${RESET}"

certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials "$CF_FILE" \
  -d "$DOMAIN" \
  -d "*.$DOMAIN" \
  --agree-tos \
  --non-interactive \
  -m "$EMAIL"

# ===== RESULT =====
if [ $? -eq 0 ]; then
  echo -e "${GREEN}SSL SUCCESSFULLY CREATED.${RESET}"
  cat assets/success.txt
else
  echo -e "${RED}SSL CREATION FAILED.${RESET}"
  cat assets/error.txt
  exit 1
fi
