FROM ruby:2.6.4-buster

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND noninteractive

# Configure apt and install packages
RUN apt-get update \
  && apt-get --no-install-recommends -y install --no-install-recommends apt-utils dialog 2>&1 \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee \
      /etc/apt/sources.list.d/yarn.list \
  # Install vim, git, process tools, lsb-release
  && apt-get update \
  && apt-get remove -y cmdtest \
  && apt-get install --no-install-recommends -y \
  vim \
  git \
  locales \
  procps \
  lsb-release \
  libterm-readline-gnu-perl \
  # Install ruby
  && apt-get install --no-install-recommends -y \
  ruby \
  ruby-dev \
  build-essential \
  libsqlite3-dev \
  zlib1g-dev \
  libxml2 \
  # Install nodejs
  && apt-get install --no-install-recommends -y nodejs yarn \
  # Install gems
  && gem install \
  rake \
  foreman \
  bundler \
  rails \
  # Set up locale
  && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
  && echo "en_GB.UTF-8 UTF-8" >> /etc/locale.gen \
  && /usr/sbin/locale-gen \
  && mkdir /workspace \
  && echo \
  # Clean up
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND readline
ENV RAILS_ENV production

COPY . /workspace
WORKDIR /workspace

RUN yarn install \
    && bundle install --without="development test"

CMD /usr/local/bundle/bin/bundle exec rails db:migrate \
      && /usr/local/bundle/bin/foreman start


