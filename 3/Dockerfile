FROM ubuntu:20.04
ENV TZ=Asia/Seoul MYVERSION=1.0.0 NICK=cloudneta
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
FROM ubuntu:20.04
    sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list && \
    sed -i 's/security.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list && \
    apt-get update && apt-get install -y apache2 figlet && \
    echo "$NICK Web Server $MYVERSION<br>" > /var/www/html/index.html && \
    echo "<pre>" >> /var/www/html/index.html && \
    figlet AEWS Study >> /var/www/html/index.html && \
    echo "</pre>" >> /var/www/html/index.html
EXPOSE 80
CMD ["usr/sbin/apache2ctl", "-DFOREGROUND"]
