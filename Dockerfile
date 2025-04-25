# GENERATED FILE, DO NOT MODIFY!
# To update this file please edit the relevant template and run the generation
# task `build/dockerfile_writer.rb --env development --compose-file docker-compose.yml,docker-compose.override.yml --in build/Dockerfile.template --out Dockerfile`

# 使用 Canvas 官方推薦 base image
ARG RUBY=3.3
FROM instructure/ruby-passenger:$RUBY
LABEL maintainer="instructure"

ENV APP_HOME=/usr/src/app
ENV RAILS_ENV=development
ENV NODE_MAJOR=20
ENV GEM_HOME=/home/docker/.gem/$RUBY
ENV PATH=${APP_HOME}/bin:$GEM_HOME/bin:$PATH
ENV BUNDLE_APP_CONFIG=/home/docker/.bundle
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0

WORKDIR $APP_HOME
COPY . .

USER root

# 安裝系統套件與 Node.js/Yarn/PostgreSQL client
RUN mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
 && curl -fsSL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /etc/apt/keyrings/yarn.gpg \
 && echo "deb [signed-by=/etc/apt/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
 && apt-get update -qq \
 && apt-get install -y --no-install-recommends \
      nodejs yarn \
      libxmlsec1-dev \
      python3-lxml python-is-python3 \
      libicu-dev libidn11-dev \
      parallel postgresql-client \
      unzip pbzip2 fontforge \
      git build-essential \
 && rm -rf /var/lib/apt/lists/*

# 安裝 bundler 與 plugin
RUN gem install bundler --no-document -v 2.5.10 \
 && bundle plugin install bundler-multilock \
 && npm install -g npm@9.8.1 \
 && npm cache clean --force \
 && corepack enable \
 && corepack prepare yarn@1.19.1 --activate

# 安裝 Gem 並變更權限
RUN bundle config set --local path 'vendor/bundle/ruby/3.3.0' \
 && bundle install --jobs 4 --retry 3 \
 && chown -R docker:docker /usr/src/app/vendor/bundle

# 建立必要目錄
RUN mkdir -p \
    .yardoc app/stylesheets/brandable_css_brands app/views/info \
    config/locales/generated log node_modules \
    packages/js-utils/{es,lib,node_modules} \
    pacts public/{dist,doc/api} public/javascripts/translations \
    reports tmp /home/docker/.bundle /home/docker/.cache/yarn /home/docker/.gem \
 && chown -R docker:docker /home/docker

USER docker
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]