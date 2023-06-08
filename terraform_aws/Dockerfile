FROM alpine:3.14
# Добавить группу и пользователя www-data
# RUN adduser -S www-data -G www-data && addgroup www-data root
RUN apk add --no-cache mysql-client
RUN mkdir -p /var/www/html/ && chmod 777 /var/www/html/
# # Установить зависимости для WP-CLI
RUN apk add --no-cache \
        less \
        php7 \
        php7-curl \
        php7-json \
        php7-mbstring \
        php7-mysqli \
        php7-phar \
        php7-openssl \
        php7-dom \
        php7-xml \
        php7-xmlwriter \
        php7-simplexml
# # Скачать и установить WP-CLI
RUN wget -O /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp
# Вынесенные скрипты
COPY scripts/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh /usr/local/bin/setup.sh

# USER www-data 
# Установить entrypoint на setup-db-wp.sh
ENTRYPOINT ["/usr/local/bin/setup.sh"]

