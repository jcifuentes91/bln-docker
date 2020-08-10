FROM php:7.1.16-apache
MAINTAINER Javier Cifuentes <jcifuentes91@hotmail.com>

ENV APACHE_DOCUMENT_ROOT /var/www/repos
ADD docker /var/www/repos
COPY docker/conf/php-development.ini /usr/local/etc/php/
RUN a2enmod rewrite
RUN a2enmod headers
RUN a2enmod ssl

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

#Install dependencies
RUN apt-get update
RUN apt-get install -my zip unzip curl wget gnupg libpng-dev libssl-dev libcurl4-openssl-dev nano gcc make libc-dev pkg-config
#Install gd with jpeg support
RUN apt-get install -y libmcrypt-dev
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# Install Packages
RUN docker-php-ext-install mysqli pdo pdo_mysql curl zip
# Install composer
RUN curl -sS https://getcomposer.org/installer | php && \
 mv composer.phar /usr/local/bin/composer

# Install Node.js
RUN apt-get install -y iputils-ping net-tools vim-tiny less 
# Install WKHTMLTOPDF
RUN apt-get install -y wkhtmltopdf
RUN cd ~ \
    && wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz \
    && tar vxf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz \
    && cp wkhtmltox/bin/wk* /usr/local/bin/

#RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
#  apt-get install -y nodejs

# Install npm
#RUN apt-get install -y npm

WORKDIR /var/www/repos

RUN pecl install redis-4.0.1 \
    && pecl install --nodeps mcrypt-snapshot \
    && pecl install --nodeps mailparse \
    && pecl install xdebug-2.6.0 \
    && docker-php-ext-enable redis xdebug

RUN apt-get update && apt-get install -y zlib1g-dev libicu-dev g++ liberation-fonts 
RUN docker-php-ext-configure intl
RUN docker-php-ext-install intl

COPY docker/conf/php-development.ini /usr/local/etc/php/php.ini
COPY docker/conf/ssl/bln.local.conf  /etc/apache2/sites-available/bln.local.conf
COPY docker/conf/ssl/api.localbln.conf  /etc/apache2/sites-available/api.localbln.conf
COPY docker/conf/ssl/devel-blnsoftware.com.conf  /etc/apache2/sites-available/devel-blnsoftware.com.conf

RUN a2ensite bln.local
RUN a2ensite api.localbln
RUN a2ensite devel-blnsoftware.com