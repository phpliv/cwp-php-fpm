#!/bin/bash
if [[ `rpm -qa| grep -i screen` == "" ]]; then yum -y install screen ; fi
if [[ `rpm -qa| grep wget` == "" ]]; then yum -y install wget; fi
yum -y --enablerepo=epel install gcc make gcc-c++ cpp kernel-headers.x86_64 libxml2 libxml2-devel autoconf bison git checkinstall openssl-devel bzip2 bzip2-devel libjpeg-devel libpng libpng-devel freetype freetype-devel openldap-devel postgresql-devel aspell-devel net-snmp-devel libxslt-devel libc-client-devel libicu-devel gmp-devel curl-devel libmcrypt-devel pcre-devel sqlite-devel db4-devel enchant-devel libXpm-devel readline-devel libedit-devel recode-devel libtidy-devel libtool-ltdl-devel flex libjpeg-turbo-devel libcurl-devel krb5-devel krb5-libs expat-devel oniguruma oniguruma-devel --skip-broken

# Cmake
if [ -e "/usr/bin/cmake" ];then
	if [ ! -e "/usr/bin/cmake3" ];then
		ln -s /usr/bin/cmake /usr/bin/cmake3
	fi
fi

yum -y install libxml2 libxml2-devel
yum -y install mysql-devel
#webp requirements
yum -y --enablerepo=epel install libvpx libvpx-devel libwebp libwebp-devel
yum -y --enablerepo=epel install libargon2 libargon2-devel
echo
echo "Install Completed"
echo "###############################"
echo

rm -f /usr/local/src/php-dependencies.sh

