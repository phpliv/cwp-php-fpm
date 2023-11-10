#!/bin/bash -x
arch=$(uname -m)
if [[ $arch == "x86_64" ]]; then
        platform="x86-64"
        libdir=/usr/lib64
else
        platform="x86"
        libdir=/usr/lib
fi


version=7.0.33

# Run pre requirements
if [ -e "/usr/local/cwp/.conf/php-fpm_conf/php70_pre.conf" ];then
        sh /usr/local/cwp/.conf/php-fpm_conf/php70_pre.conf 2>&1
fi

# PHP Sources
PHPDOWNLOADVERCWP=`wget -q -S --spider "http://static.cdn-cwp.com/files/php/php-$version.tar.gz" -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}'`
PHPDOWNLOADVERMUSEUM=`wget -q -S --spider "https://museum.php.net/php7/php-$version.tar.gz" -O - 2>&1 | sed -ne '/Content-Length/{s/.*: //;p}'`

# Check if on CWP source file exist (redirect gives code 200 always)
if [ -z "$PHPDOWNLOADVERCWP" ];then
        PHPDOWNLOADVERCWP=0
fi

# Check if file size is over 8MB
if [ $PHPDOWNLOADVERCWP -ge 8000000 ];then
        phpsource="http://static.cdn-cwp.com/files/php/php-$version.tar.gz"
elif [ $PHPDOWNLOADVERMUSEUM -ge 8000000 ];then
        phpsource="https://museum.php.net/php7/php-$version.tar.gz"
else
    	echo "Failed to Download PHP version $version!"
        exit 1
fi

ioncube="http://static.cdn-cwp.com/files/php/ioncube_loaders_lin_$platform.tar.gz"

test -h /usr/local/src/php-build || rm -rf /usr/local/src/php-build
mkdir -p /usr/local/src/php-build
cd /usr/local/src/php-build

wget -q $phpsource
wget  $ioncube

tar -xvf php-$version.tar.gz
cd php-$version/

chmod +x /usr/local/cwp/.conf/php-fpm_conf/php70.conf
sh /usr/local/cwp/.conf/php-fpm_conf/php70.conf 2>&1

#make clean 2>&1

if [ -e "/usr/bin/nproc" ];then
        make -j `/usr/bin/nproc` 2>&1
else
    	make 2>&1
fi

make install 2>&1

#Production PHP.ini
mkdir -p /opt/alt/php-fpm70/usr/php
mkdir -p /opt/alt/php-fpm70/usr/php/php.d
rsync php.ini-production /opt/alt/php-fpm70/usr/php/php.ini

# fix php.ini
sed -i "s/^short_open_tag.*/short_open_tag = On/g" /opt/alt/php-fpm70/usr/php/php.ini
sed -i "s/^;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g" /opt/alt/php-fpm70/usr/php/php.ini
sed -i "s/.*mail.add_x_header.*/mail.add_x_header = On/" /opt/alt/php-fpm70/usr/php/php.ini
sed -i "s@.*mail.log.*@mail.log = /usr/local/apache/logs/phpmail.log@" /opt/alt/php-fpm70/usr/php/php.ini

# ioncube installer
if [ -e "/usr/local/php/php.d/ioncube.ini" ]; then
        echo 'zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.0.so' > /opt/alt/php-fpm70/usr/php/php.d/ioncube.ini
fi

# PHP-FPM Conf
mkdir /opt/alt/php-fpm70/usr/var/sockets/
mkdir /opt/alt/php-fpm70/usr/etc/php-fpm.d/
mkdir /opt/alt/php-fpm70/usr/etc/php-fpm.d/users/
echo "include=/opt/alt/php-fpm70/usr/etc/php-fpm.d/users/*.conf" > /opt/alt/php-fpm70/usr/etc/php-fpm.d/users.conf
echo "include=/opt/alt/php-fpm70/usr/etc/php-fpm.d/*.conf" > /opt/alt/php-fpm70/usr/etc/php-fpm.conf

cat > /opt/alt/php-fpm70/usr/etc/php-fpm.d/cwpsvc.conf <<EOF
[cwpsvc]
listen = /opt/alt/php-fpm70/usr/var/sockets/cwpsvc.sock
listen.owner = cwpsvc
listen.group = cwpsvc
listen.mode = 0640
user = cwpsvc
group = cwpsvc
;request_slowlog_timeout = 5s
;slowlog = /opt/alt/php-fpm70/usr/var/log/php-fpm-slowlog-cwpsvc.log
listen.allowed_clients = 127.0.0.1
pm = ondemand
pm.max_children = 25
pm.process_idle_timeout = 15s
;listen.backlog = -1
request_terminate_timeout = 0s
rlimit_files = 131072
rlimit_core = unlimited
catch_workers_output = yes
env[HOSTNAME] = \$HOSTNAME
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
env[PATH] = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EOF

cp sapi/fpm/php-fpm.service /usr/lib/systemd/system/php-fpm70.service
sed -i "s/\${exec_prefix}/\/opt\/alt\/php-fpm70\/usr/g" /usr/lib/systemd/system/php-fpm70.service
sed -i "s/\${prefix}/\/opt\/alt\/php-fpm70\/usr/g" /usr/lib/systemd/system/php-fpm70.service
/bin/systemctl daemon-reload
systemctl enable php-fpm70

if [ ! -e "/usr/local/apache/conf.d/php-fpm.conf" ];then
cat > /usr/local/apache/conf.d/php-fpm.conf <<EOF
<IfModule !proxy_fcgi_module>
	LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
</IfModule>
EOF
fi

# Clean all
test -h /usr/local/src/php-build || rm -rf /usr/local/src/php-build

# Run Additional scripts
if [ -e "/usr/local/cwp/.conf/php-fpm_conf/php70_external.conf" ];then
        sh /usr/local/cwp/.conf/php-fpm_conf/php70_external.conf 2>&1
fi

# CSF Firewall
if [ -e "/etc/csf/csf.pignore" ];then
grep php-fpm70 /etc/csf/csf.pignore || echo "exe:/opt/alt/php-fpm70/usr/sbin/php-fpm" >> /etc/csf/csf.pignore
fi

# Monit
if [ -e "/etc/monit.d" ];then
 if [ ! -e "/etc/monit.d/php-fpm70" ];then
  cp /usr/local/cwpsrv/htdocs/resources/conf/monit.d/php-fpm70 /etc/monit.d/ 2> /dev/null
  monit reload
 fi
fi

systemctl restart php-fpm70
