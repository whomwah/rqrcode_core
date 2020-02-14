FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common && \
    apt-add-repository ppa:brightbox/ruby-ng && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      autoconf \
      bison \
      build-essential \
      ca-certificates \
      curl \
      default-jre-headless \
      git \
      imagemagick \
      libcurl4-openssl-dev \
      libffi-dev \
      libmagickcore-dev \
      libmagickwand-dev \
      libmysqlclient-dev \
      libreadline-dev \
      libssl-dev \
      libxml2-dev \
      libxslt1-dev \
      mysql-client \
      openssh-client \
      python-dev \
      ruby-build \
      ruby1.8 \
      ruby1.8-dev \
      subversion \
      tzdata \
      unzip \
      zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN echo 'gem: --no-rdoc --no-ri' >> /etc/gemrc && \
    gem install -v 1.17.3 bundler

WORKDIR /app/
ADD . /app/
RUN bundle install

CMD bundle exec rake -T
