#!/bin/bash
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

clear
echo "================================="
echo "        LIFERS SCRIPT V3"
echo "================================="
echo "[1] Create SSL (Nginx + Certbot)"
echo "[2] Install Protect DF"
echo "[3] Install Super Protect DF"
echo "[4] Uninstall Protect DF"
echo "[5] Uninstall Super Protect DF"
echo "[0] Exit"
echo "================================="
read -p "Select option: " opt

case "$opt" in
  1) bash "$BASE_DIR/ssl.sh" ;;
  2) bash "$BASE_DIR/install.sh" protect ;;
  3) bash "$BASE_DIR/install.sh" super ;;
  4) bash "$BASE_DIR/uninstall.sh" protect ;;
  5) bash "$BASE_DIR/uninstall.sh" super ;;
  0) exit 0 ;;
  *) echo "[ERROR] Invalid option"; exit 1 ;;
esac
