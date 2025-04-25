# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `build/dockerfile_writer.rb --env development --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile`

# 使用 Canvas 官方推薦 base image
ARG RUBY=3.3
FROM instructure/ruby-passenger:$RUBY
LABEL maintainer="instructure"

# 設定環境變數
ENV APP_HOME /usr/src/app
ENV RAILS_ENV=development
ENV NODE_MAJOR=20
ENV GEM_HOME=/home/docker/.gem/$RUBY
ENV PATH=${APP_HOME}/bin:$GEM_HOME/bin:$PATH
ENV BUNDLE_APP_CONFIG=/home/docker/.bundle
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR $APP_HOME

# 複製 Canvas LMS 原始碼
COPY . .
# 🚨 安裝所有 gem（這步驟目前缺少！）
RUN bundle config set --local path 'vendor/bundle' \
 && bundle install
USER root

# 安裝 Node.js、Yarn、Postgres Client 等
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      nodejs \
      yarn \
      libxmlsec1-dev \
      python3-lxml \
      python-is-python3 \
      libicu-dev \
      libidn11-dev \
      parallel \
      postgresql-client \
      unzip \
      pbzip2 \
      fontforge \
      git \
      build-essential \
 && rm -rf /var/lib/apt/lists/*

# 安裝 bundler 與 bundler-multilock
RUN gem install bundler --no-document -v 2.5.10 \
 && bundle plugin install bundler-multilock \
 && npm install -g npm@9.8.1 && npm cache clean --force

# 啟用 corepack 並啟動 yarn@1
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable && corepack prepare yarn@1.19.1 --activate

# 確保所有 Canvas LMS 所需資料夾都存在
RUN mkdir -p \
    .yardoc \
    app/stylesheets/brandable_css_brands \
    app/views/info \
    config/locales/generated \
    log \
    node_modules \
    packages/js-utils/es \
    packages/js-utils/lib \
    packages/js-utils/node_modules \
    pacts \
    public/dist \
    public/doc/api \
    public/javascripts/translations \
    reports \
    tmp \
 && mkdir -p /home/docker/.bundle /home/docker/.cache/yarn /home/docker/.gem \
 && chown -R docker:docker /home/docker

USER docker

# Railway 使用 3000 埠口作為 HTTP 入口
EXPOSE 3000

# 使用 Puma 啟動 Rails Server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]