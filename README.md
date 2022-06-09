## Samba 4 AD container
A simple domain controller using Samba 

### Credits
Some parts are collected from:
* https://github.com/Osirium/docker-samba-ad-dc
* https://github.com/myrjola/docker-samba-ad-dc

Created based on https://hub.docker.com/r/militellovinx/samba-ad and https://github.com/vmilitello/samba-ad

### Setting up Samba as an Active Directory Domain Controller
https://wiki.samba.org/index.php/Setting_up_Samba_as_an_Active_Directory_Domain_Controller

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
> It's better if `/usr/lib/samba/` and `/var/lib/krb5kdc/` are mounted using docker volumes to avoid permissions issues

### Examples

#### Plain docker
```
mkdir ~/tmp/krb-conf
mkdir ~/tmp/smb-conf
touch /tmp/krb-conf/krb5.conf

docker volume create samba4ad-smb-data-ubuntu
docker volume create samba4ad-krb-data-ubuntu

docker run -it --rm \
-e SAMBA_ADMIN_PASSWORD=...secr3t... \
-e SAMBA_DOMAIN=local \
-e SAMBA_REALM=local.patodiaz.io \
-e LDAP_ALLOW_INSECURE=true \
--mount type=bind,source=$HOME/tmp/krb-conf/krb5.conf,target=/etc/krb5.conf \
--mount type=bind,source=$HOME/tmp/smb-conf,target=/etc/samba \
--mount type=volume,source=samba4ad-smb-data-ubuntu,target=/var/lib/samba \
--mount type=volume,source=samba4ad-krb-data-ubuntu,target=/var/lib/krb5kdc \
-p 389:389 \
--name smb4ad \
padiazg/samba4dc:ubuntu
```

For details how to store data in directories, containers etc. please check the Docker documentation for details.

#### Docker compose

Get the `docker-compose.yaml` [file from the github repo](https://github.com/padiazg/ubuntu-samba-ad-container/blob/master/docker-compose.yaml).

```yaml
version: '3'
services:
  samba:
    image: padiazg/samba4dc:ubuntu
    privileged: true
    environment:
      - SAMBA_DOMAIN=local
      - SAMBA_REALM=local.patodiaz.io
      - SAMBA_ADMIN_PASSWORD=secr3t* 
      - LDAP_ALLOW_INSECURE=true
    volumes:
      - ~/tmp/smb-conf:/etc/samba
      - ~/tmp/krb-conf/krb5.conf:/etc/krb5.conf
      - samba4ad-smb-data:/var/lib/samba
      - samba4ad-krb-data:/var/lib/krb5kdc
    ports:
      # - "53:53"     # dns
      - "389:389"     # ldap
      # - "88:88"     # kdc
      # - "135:135"   # rpc
      # - "139:139"   # smbd
      # - "445:445"   # smbd
      # - "464:464"   # kdc
      - "3268:3268"   # ldap
      - "3269:3269"   # ldap 

volumes:
  samba4ad-smb-data:
  samba4ad-krb-data:
```
then run it
```bash
mkdir ~/tmp/krb-conf
mkdir ~/tmp/smb-conf
touch /tmp/krb-conf/krb5.conf

docker-compose up -d
```

Watch the logs via `docker-compose logs -f`.

## Test it

### List all objects in domain
```bash
ldapsearch -x -W \
  -D "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -b dc=local,dc=patodiaz,dc=io
```
### All groups
```bash
ldapsearch -x -W \
  -D "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -b dc=local,dc=patodiaz,dc=io \
  "(objectClass=group)"
```
### All UOs
```bash
ldapsearch -x -W \
  -D "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -b dc=local,dc=patodiaz,dc=io \
  "(objectClass=organizationalUnit)"
```
### List all Groups and OUs
```bash
ldapsearch -x -W \
  -D "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -b dc=local,dc=patodiaz,dc=io \
  "(|(objectClass=organizationalUnit)(objectClass=Group))"
```
### Create a group
First we create group.ldif file
```ldif
dn: CN=team-a,CN=Users,DC=local,DC=patodiaz,DC=io
objectClass: top
objectClass: group
cn: team-a
gidNumber: 678
```
Then we create the group using this file
```bash
ldapadd -cxWD "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
-f group.ldif
```
Check the group was created
```bash
ldapsearch -xWD "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -b dc=local,dc=patodiaz,dc=io "(&(objectClass=group)(CN=TeamA))"
```
### Create an user
Let's create a file named jhon.ldif
```ldif
dn: CN=Jhon,CN=Users,DC=local,DC=patodiaz,DC=io
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: user
cn: Jhon
uid: jhon
uidNumber: 16859
gidNumber: 100
homeDirectory: /home/jhon
loginShell: /bin/bash
gecos: jhon
userPassword: {crypt}x
```
Create the user
```bash
ldapadd -xWD "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -f jhon.ldif
```
Check that the user was created
```bash
ldapsearch -xWD "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -b dc=local,dc=patodiaz,dc=io \
  "(&(objectClass=user)(CN=Jhon))"
```
Add a user to a group
add-to-group.ldif
```ldif
dn: CN=dbagrp,CN=Builtin,DC=local,DC=patodiaz,DC=io
changetype: modify
add: member
member: CN=Adam,CN=Users,DC=local,DC=patodiaz,DC=io
```
Add the user to the group
```bash
ldapmodify -xWD "cn=Administrator,cn=Users,dc=local,dc=patodiaz,dc=io" \
  -f add-to-group.ldif
```
