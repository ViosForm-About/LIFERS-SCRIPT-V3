#!/bin/bash
set -e

MODE="$1"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PANEL="/var/www/pterodactyl"

if [[ "$MODE" != "protect" && "$MODE" != "super" ]]; then
  echo "[FATAL] Mode invalid"
  exit 1
fi

read -p "Enter Pterodactyl panel URL (without http/https): " PANEL_URL

if [ ! -d "$PANEL" ]; then
  echo "[FATAL] Pterodactyl not found at $PANEL"
  exit 1
fi

echo "[OK] Pterodactyl found at $PANEL"

# ================= MIDDLEWARE =================
MW="$PANEL/app/Http/Middleware/LifersProtect.php"

cat > "$MW" <<'PHP'
<?php

namespace App\Http\Middleware;

use Closure;

class LifersProtect
{
    public function handle($request, Closure $next)
    {
        if (!auth()->check() || auth()->user()->id !== 1) {
            abort(403);
        }
        return $next($request);
    }
}
PHP

# ================ REGISTER ====================
KERNEL="$PANEL/app/Http/Kernel.php"
grep -q LifersProtect "$KERNEL" || sed -i "/routeMiddleware = \[/a\        'lifers.protect' => \App\Http\Middleware\LifersProtect::class," "$KERNEL"

# ================ ROUTES ======================
ROUTES="$PANEL/routes/web.php"

grep -q lifers.protect "$ROUTES" || cat >> "$ROUTES" <<'PHP'

Route::middleware(['auth','lifers.protect'])->group(function () {
    Route::prefix('admin')->group(function () {
        Route::any('/nodes{any}', fn() => abort(403))->where('any','.*');
        Route::any('/nests{any}', fn() => abort(403))->where('any','.*');
        Route::any('/locations{any}', fn() => abort(403))->where('any','.*');
        Route::any('/users{any}', fn() => abort(403))->where('any','.*');
        Route::any('/servers{any}', fn() => abort(403))->where('any','.*');
        Route::any('/settings{any}', fn() => abort(403))->where('any','.*');
        Route::any('/api{any}', fn() => abort(403))->where('any','.*');
    });
    Route::any('/account/api{any}', fn() => abort(403))->where('any','.*');
});
PHP

# ================ VIEW 403 ====================
cp "$BASE_DIR/assets/protect.blade.php" \
"$PANEL/resources/views/errors/403.blade.php"

php "$PANEL/artisan" view:clear
php "$PANEL/artisan" route:clear
php "$PANEL/artisan" config:clear

echo "==============================="
echo " INSTALL FINISHED SUCCESSFULLY"
echo "==============================="
