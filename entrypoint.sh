#!/bin/bash
set -e

# 初始化資料夾權限
mkdir -p log tmp public/dist
chown -R docker:docker log tmp public

# 初始化資料庫（如果還沒跑過）
bundle check || bundle install
bundle exec rake db:initial_setup || true
bundle exec rake assets:precompile || true

# 啟動 Web server
exec "$@"