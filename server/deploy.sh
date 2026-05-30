#!/bin/bash
# Деплой сервера на VPS 194.85.251.132

SERVER="root@194.85.251.132"
REMOTE_DIR="/opt/space-hitchhikers-server"

echo "📦 Копируем файлы на сервер..."
ssh $SERVER "mkdir -p $REMOTE_DIR"
scp package.json server.js $SERVER:$REMOTE_DIR/

echo "📥 Устанавливаем зависимости..."
ssh $SERVER "cd $REMOTE_DIR && npm install --production"

echo "🔄 Перезапускаем сервис..."
ssh $SERVER "cd $REMOTE_DIR && pm2 delete space-server 2>/dev/null; pm2 start server.js --name space-server && pm2 save"

echo "✅ Готово! Сервер запущен на ws://194.85.251.132:8765"
