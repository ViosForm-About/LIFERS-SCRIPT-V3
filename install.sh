#!/bin/bash
# ============================================
# LIFERS SCRIPT V3 - install.sh (STABLE)
# ============================================

set -e

echo "================================="
echo " LIFERS INSTALLER"
echo "================================="

MODE="$1"

if [ -z "$MODE" ]; then
  echo "[FATAL] Mode not provided"
  exit 1
fi

# -------------------------------
# INPUT PANEL URL
# -------------------------------
read -p "Enter Pterodactyl panel URL (without http/https): " PANEL_URL
echo "[INFO] Panel URL: $PANEL_URL"

# -------------------------------
# AUTO DETECT PANEL PATH
# -------------------------------
echo "[INFO] Detecting Pterodactyl panel path..."

PANEL_PATH=""

for p in \
  /var/www/pterodactyl \
  /var/www/panel \
  /var/www/html/pterodactyl \
  /var/www/html/panel
do
  if [ -f "$p/artisan" ]; then
    PANEL_PATH="$p"
    break
  fi
done

if [ -z "$PANEL_PATH" ]; then
  echo "[FATAL] artisan file not found"
  echo "[HINT] Pterodactyl must be installed WITHOUT Docker"
  exit 1
fi

echo "[OK] Pterodactyl found at: $PANEL_PATH"
cd "$PANEL_PATH"

# -------------------------------
# SSL INSTALL
# -------------------------------
if [ "$MODE" = "ssl" ]; then
  read -p "Enter domain/subdomain: " DOMAIN

  echo "[INFO] Installing SSL for $DOMAIN"

  apt update -y
  apt install -y nginx certbot python3-certbot-nginx

  certbot --nginx \
    -d "$DOMAIN" \
    --non-interactive \
    --agree-tos \
    -m "admin@$DOMAIN"

  echo "[SUCCESS] SSL CREATED"
  exit 0
fi

# -------------------------------
# VALIDATE SOURCE FILES
# -------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ ! -f "$SCRIPT_DIR/assets/protect.blade.php" ]; then
  echo "[FATAL] assets/protect.blade.php not found"
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/middleware/ProtectDF.php" ]; then
  echo "[FATAL] middleware/ProtectDF.php not found"
  exit 1
fi

if [ ! -f "$SCRIPT_DIR/middleware/SuperProtectDF.php" ]; then
  echo "[FATAL] middleware/SuperProtectDF.php not found"
  exit 1
fi

# -------------------------------
# CREATE DIRECTORIES
# -------------------------------
echo "[INFO] Creating directories..."

mkdir -p app/Http/Middleware/Lifers
mkdir -p resources/views/lifers

# -------------------------------
# COPY FILES
# -------------------------------
echo "[INFO] Copying protect files..."

cp "$SCRIPT_DIR/assets/protect.blade.php" \
   resources/views/lifers/protect.blade.php

cp "$SCRIPT_DIR/middleware/ProtectDF.php" \
   app/Http/Middleware/Lifers/ProtectDF.php

cp "$SCRIPT_DIR/middleware/SuperProtectDF.php" \
   app/Http/Middleware/Lifers/SuperProtectDF.php

# -------------------------------
# REGISTER MIDDLEWARE
# -------------------------------
echo "[INFO] Registering middleware..."

KERNEL="app/Http/Kernel.php"

if ! grep -q "lifers.protect" "$KERNEL"; then
  sed -i "/routeMiddleware = \[/a \
        'lifers.protect' => \\\App\\\\Http\\\\Middleware\\\\Lifers\\\\ProtectDF::class,\
        'lifers.super'   => \\\App\\\\Http\\\\Middleware\\\\Lifers\\\\SuperProtectDF::class," \
  "$KERNEL"
fi

# -------------------------------
# INJECT ROUTES
# -------------------------------
echo "[INFO] Injecting routes..."

ROUTES="routes/web.php"
sed -i '/LIFERS PROTECT START/,/LIFERS PROTECT END/d' "$ROUTES"

echo "// ===== LIFERS PROTECT START =====" >> "$ROUTES"

if [ "$MODE" = "protect" ]; then
cat <<EOF >> "$ROUTES"
Route::middleware(['web','auth','lifers.protect'])->group(function () {
    Route::any('/admin/nodes{any?}', fn() => view('lifers.protect'))->where('any','.*');
    Route::any('/admin/nests{any?}', fn() => view('lifers.protect'))->where('any','.*');
    Route::any('/admin/locations{any?}', fn() => view('lifers.protect'))->where('any','.*');
});
EOF
fi

if [ "$MODE" = "super" ]; then
cat <<EOF >> "$ROUTES"
Route::middleware(['web','auth','lifers.super'])->group(function () {
    Route::any('/admin{any?}', fn() => view('lifers.protect'))->where('any','.*');
    Route::any('/server{any?}', fn() => view('lifers.protect'))->where('any','.*');
    Route::any('/account/api{any?}', fn() => view('lifers.protect'))->where('any','.*');
});
EOF
fi

echo "// ===== LIFERS PROTECT END =====" >> "$ROUTES"

# -------------------------------
# CLEAR CACHE
# -------------------------------
echo "[INFO] Clearing Laravel cache..."
php artisan optimize:clear

# -------------------------------
# DONE
# -------------------------------
echo "================================="
echo " INSTALL SUCCESSFUL"
echo " MODE : $MODE"
echo " UUID 1 ONLY ACTIVE"
echo "================================="
