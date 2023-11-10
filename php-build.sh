#!/bin/bash
#if [ -e "/etc/fstab" ]; then
#if [[ `cat /etc/fstab | grep -E "tmp.*noexec"` != "" ]]; then mount -o remount,exec /tmp >/dev/null 2>&1 ; fi
#fi

if [ -e "/var/log/php-dependencies.log" ];then
        rm -f /var/log/php-dependencies.log   
fi
wget https://raw.githubusercontent.com/phpliv/cwp-php-fpm/main/php-dependencies.sh -O /usr/local/src/php-dependencies.sh   
sh /usr/local/src/php-dependencies.sh >> /var/log/php-dependencies.log 2>&1 

CONFIGURE_VERSIONS_TO_BUILD

service httpd restart

echo 
echo "Build Completed"
echo "###################"
echo
echo
rm -Rf /usr/local/src/php-*

#if [ -e "/etc/fstab" ]; then
#if [[ `cat /etc/fstab | grep -E "tmp.*noexec"` != "" ]]; then mount -o remount /tmp >/dev/null 2>&1 ; fi
#fi

# Add alert info into cwp
#sh /scripts/add_alert alert-info "PHP Selector task completed, please check the log for more details." /var/log/php-selector-rebuild.log
/usr/local/cwp/php71/bin/php /usr/local/cwpsrv/htdocs/resources/admin/include/libs/notifications/cli.php --level="info" --subject="PHP Selector INFO" --message="PHP Selector  task completed, please check the log for more details. Click <a title='PHP Selector task LOG' href='index.php?module=file_editor&file=/var/log/php-selector-rebuild.log'>here</a> to check it."

# Added as some server with memory less than 2GB can fail to build new php
#grep "cc: internal compiler error: Killed" /var/log/php-selector-rebuild.log && /usr/local/cwp/php71/bin/php /usr/local/cwpsrv/htdocs/resources/admin/include/libs/notifications/cli.php --level="danger" --subject="PHP Selector ERROR" --message="ERROR: PHP Selector task FAILED, please check the log for more details. Make sure you have 2GB+ of RAM. Click <a title='PHP Selector task LOG' href='index.php?module=file_editor&file=/var/log/php-selector-rebuild.log'>here</a> to check it."
