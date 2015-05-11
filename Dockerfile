FROM ubuntu:14.04

MAINTAINER Netlify

################################################################################
#
# Dependencies
#
################################################################################

RUN apt-get -y update && \
    apt-get install -y git-core build-essential g++ libssl-dev curl wget \
                      apache2-utils libxml2-dev libxslt-dev python-setuptools \
                      mercurial bzr imagemagick libmagickwand-dev python2.7-dev \
                      advancecomp gifsicle jpegoptim libjpeg-progs optipng \
                      pngcrush fontconfig fontconfig-config libfontconfig1 \
                      gawk libreadline6-dev libyaml-dev libsqlite3-dev sqlite3 \
                      autoconf libgdbm-dev libncurses5-dev automake bison libffi-dev \
                      gobject-introspection gtk-doc-tools libglib2.0-dev \
                      libjpeg-turbo8-dev libpng12-dev libwebp-dev libtiff5-dev \
                      libexif-dev swig && \
    apt-get clean


################################################################################
#
# Libvips
#
################################################################################

WORKDIR /tmp
ENV LIBVIPS_VERSION_MAJOR 7
ENV LIBVIPS_VERSION_MINOR 42
ENV LIBVIPS_VERSION_PATCH 3
ENV LIBVIPS_VERSION $LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR.$LIBVIPS_VERSION_PATCH
RUN \
  curl -O http://www.vips.ecs.soton.ac.uk/supported/$LIBVIPS_VERSION_MAJOR.$LIBVIPS_VERSION_MINOR/vips-$LIBVIPS_VERSION.tar.gz && \
  tar zvxf vips-$LIBVIPS_VERSION.tar.gz && \
  cd vips-$LIBVIPS_VERSION && \
  ./configure --enable-debug=no --enable-docs=no --without-python --without-orc --without-fftw --without-gsf $1 && \
  make && \
  make install && \
  ldconfig

WORKDIR /

################################################################################
#
# Locale and UTF-8
#
################################################################################

# Set a default language
RUN echo 'Acquire::Languages {"none";};' > /etc/apt/apt.conf.d/60language && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
    locale-gen en_US.UTF-8 && update-locale en_US.UTF-8

ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

################################################################################
#
# User
#
################################################################################

RUN adduser --system --disabled-password --uid 2500 --quiet buildbot --home /opt/buildhome

################################################################################
#
# Ruby
#
################################################################################

USER buildbot
RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3 && \
    curl -L https://get.rvm.io | bash -s stable --with-gems="bundler" --autolibs=read-fail

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN $HOME/.rvm/bin/rvm install 2.1.2 && $HOME/.rvm/bin/rvm install 2.2.1 && \
    $HOME/.rvm/bin/rvm use 2.1.2 --default && $HOME/.rvm/bin/rvm cleanup all

ENV PATH /usr/local/rvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
USER root

################################################################################
#
# Node.js
#
################################################################################

RUN git clone https://github.com/creationix/nvm.git /.nvm && \
    echo ". /.nvm/nvm.sh" >> /etc/bash.bashrc

# Install node.js
RUN /bin/bash -c '. /.nvm/nvm.sh && nvm install v0.10.29 && nvm use v0.10.29 && \
    npm install -g sm && npm install -g grunt-cli && npm install -g bower'

RUN /bin/bash -c '. /.nvm/nvm.sh && nvm install v0.12.2 && nvm use v0.12.2 && \
    nvm alias default v0.12.2 && npm install -g sm && npm install -g grunt-cli && \
    npm install -g bower'


################################################################################
#
# Python
#
################################################################################

RUN easy_install virtualenv

USER buildbot
    RUN virtualenv -p python2.7 --no-site-packages /opt/buildhome/python2.7 && \
    /bin/bash -c 'source /opt/buildhome/python2.7/bin/activate'

USER root

# Cleanup
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER buildbot
