## Samba 4 AD container
A simple domain controller using Samba 

### Credits
Some parts are collected from:
* https://github.com/Osirium/docker-samba-ad-dc
* https://github.com/myrjola/docker-samba-ad-dc
* https://wiki.samba.org/index.php/Samba,_Active_Directory_%26_LDAP

Created based on https://hub.docker.com/r/militellovinx/samba-ad and https://github.com/vmilitello/samba-ad


### Usage
Quick and dirty, without any config and thrown away when terminated:
```
docker run -it --rm \
    --privileged \
    -e SAMBA_ADMIN_PASSWORD=...secr3t... \
    -e SAMBA_DOMAIN=local \
    -e SAMBA_REALM=local.patodiaz.io \
    -e LDAP_ALLOW_INSECURE=true \
    -p 389:389 \
    --name smb4ad \
    padiazg/samba4dc:ubuntu
```

### Environment variables

Environment variables are controlling the way how this image behaves therefore please check this list an explanation:

| Variabale | Explanation | Default |
| --- | --- | --- |
| `SAMBA_DOMAIN` | The domain name used for Samba AD | `SAMDOM` |
| `SAMBA_REALM` | The realm for authentication (eg. Kerberos) | `SAMDOM.EXAMPLE.COM` |
| `LDAP_ALLOW_INSECURE` | Allow insecure LDAP setup, by using unecrypted password. *Please use only in debug and non productive setups.* | `false` |
| `SAMBA_ADMIN_PASSWORD` | The samba admin user password  | set to `$(pwgen -cny 10 1)` |
| `KERBEROS_PASSWORD` | The kerberos password  | set to `$(pwgen -cny 10 1)` |


### Use existing data

Using (or reusing data) is done by providing
* `/etc/samba/smb.conf`
* `/etc/krb5.conf`
* `/usr/lib/samba/`
* `/var/lib/krb5kdc/`

as volumes to the docker container.
It's better if `/usr/lib/samba/` and `/var/lib/krb5kdc/` are mounted using docker volumes to avoid permissions issues

### Examples

#### Plain docker
```
mkdir ~/tmp/krb-conf
mkdir ~/tmp/smb-conf
touch /tmp/krb-conf/krb5.conf

docker run -it --rm \
-e SAMBA_ADMIN_PASSWORD=...secr3t... \
-e SAMBA_DOMAIN=local \
-e SAMBA_REALM=local.patodiaz.io \
-e LDAP_ALLOW_INSECURE=true \
--mount type=bind,source=$HOME/tmp/krb-conf/krb5.conf,target=/etc/krb5.conf \
--mount type=bind,source=$HOME/tmp/smb-conf,target=/etc/samba \
--mount type=volume,source=samba4ad-krb-data-ubuntu,target=/var/lib/krb5kdc \
--mount type=volume,source=samba4ad-smb-data-ubuntu,target=/var/lib/samba \
-p 389:389 \
--name smb4ad \
padiazg/samba4dc:ubuntu
```

For details how to store data in directories, containers etc. please check the Docker documentation for details.

#### Docker compose

Get the `docker-compose.yaml` [file from the github repo](https://github.com/tkaefer/alpine-samba-ad-container/blob/master/docker-compose.yaml).

```bash
mkdir ~/tmp/krb-conf
mkdir ~/tmp/smb-conf
touch /tmp/krb-conf/krb5.conf

docker-compose up -d
```

Watch the logs via `docker-compose logs -f`.
