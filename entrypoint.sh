#!/bin/bash
set -e

# 初始化資料夾權限
mkdir -p log tmp public/dist
chown -R docker:docker log tmp public

# 初始化資料庫（如果還沒跑過）
echo "📦 檢查 Bundler..."
bundle check || bundle install

echo "🔧 初始化資料庫..."
bundle exec rake db:initial_setup || true

echo "🎨 編譯 assets..."
bundle exec rake assets:precompile || true

echo "🚀 啟動伺服器..."
exec "$@"