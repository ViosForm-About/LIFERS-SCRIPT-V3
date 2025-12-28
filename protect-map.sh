#!/bin/bash

MODE=$1
ROUTE="/var/www/pterodactyl/routes/web.php"

echo "" >> $ROUTE
echo "// ==== LIFERS PROTECT START ====" >> $ROUTE

if [ "$MODE" = "protect" ]; then
cat <<EOF >> $ROUTE
Route::middleware(['web','auth','lifers.protect'])->group(function () {
    Route::get('/admin/nodes', fn()=>view('lifers.protect'));
    Route::get('/admin/nests', fn()=>view('lifers.protect'));
    Route::get('/admin/locations', fn()=>view('lifers.protect'));
});
EOF
fi

if [ "$MODE" = "super" ]; then
cat <<EOF >> $ROUTE
Route::middleware(['web','auth','lifers.super'])->group(function () {
    Route::any('/admin/{any}', fn()=>view('lifers.protect'))->where('any','.*');
    Route::any('/server/{any}', fn()=>view('lifers.protect'))->where('any','.*');
    Route::any('/account/api', fn()=>view('lifers.protect'));
});
EOF
fi

echo "// ==== LIFERS PROTECT END ====" >> $ROUTE
