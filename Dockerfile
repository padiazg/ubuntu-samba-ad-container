FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive 
ENV TZ=Etc/UTC
RUN apt update \
    && apt upgrade -y \
    && apt install -y \
    pwgen \
    samba \
    winbind \
    smbclient \
    krb5-config \
    krb5-kdc \
    expect \
    supervisor \
    rsyslog 

ADD kdb5_util_create.expect kdb5_util_create.expect
ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

EXPOSE 22 53 389 88 135 139 445 464 3268 3269
ENTRYPOINT ["/entrypoint.sh"]
CMD ["app:start"]