#!/bin/bash

mkdir -p /state /var/log/z-push
touch /var/log/z-push/z-push-error.log /var/log/z-push/z-push.log

chown -R zpush:zpush /state /opt/zpush /var/log/z-push

cp /etc/supervisord.conf.dist /etc/supervisord.conf
[ "$DEBUG" = 1 ] && sed -i "|z-push-error.log|z-push-error.log /var/log/z-push/z-push.log|" /etc/supervisord.conf

[ ! -f "/config/config.php" ] && sed -e "s/define('BACKEND_PROVIDER', '')/define('BACKEND_PROVIDER', 'BackendIMAP')/" \
    -e "s|define('STATE_DIR', '/var/lib/z-push/')|define('STATE_DIR', '/state/')|" \
    -e "s|define('TIMEZONE', '')|define('TIMEZONE', '"$TIMEZONE"')|" /opt/zpush/config.php.dist > /config/config.php
#    -e "s|define('LOGFILEDIR', '/var/log/z-push/')|define('LOGFILEDIR', '/data/logs/')|" \

[ ! -f "/config/imap.php" ] && sed -e "s/define('IMAP_SERVER', 'localhost')/define('IMAP_SERVER', '"$IMAP_SERVER"')/" \
    -e "s/define('IMAP_PORT', 143)/define('IMAP_PORT', '"$IMAP_PORT"')/" \
    -e "s|define('IMAP_OPTIONS', '/notls/norsh')|define('IMAP_OPTIONS', '/tls/norsh/novalidate-cert')|" \
    -e "s/define('IMAP_SMTP_METHOD', 'mail')/define('IMAP_SMTP_METHOD', 'smtp')/" \
    -e "s|imap_smtp_params = array()|imap_smtp_params = array('host' => '"$SMTP_SERVER"', 'port' => '"$SMTP_PORT"', 'auth' => true, 'username' => 'imap_username', 'password' => 'imap_password', 'verify_peer_name' => false, 'verify_peer' => false, 'allow_self_signed' => true)|" \
    -e "s/define('IMAP_FOLDER_CONFIGURED', false)/define('IMAP_FOLDER_CONFIGURED', true)/" /opt/zpush/backend/imap/config.php.dist > /config/imap.php

cat >> /opt/zpush/config.php << 'END'
<?php
require '/config/config.php';
END

cat >> /opt/zpush/backend/imap/config.php << 'END'
<?php
require '/config/imap.php';
END

# setting up logrotate
echo -e "/var/log/z-push/z-push.log\n{\n  compress\n  copytruncate\n  delaycompress\n rotate 7\n  daily\n}" > /etc/logrotate.d/z-pushlog
echo -e "/var/log/z-push/z-push.log\n{\n  compress\n  copytruncate\n  delaycompress\n rotate 4\n  weekly\n}" > /etc/logrotate.d/z-push-errorlog

echo "*************************BEGIN* config.php *BEGIN******************************"
echo "==============================================================================="
cat /config/config.php
echo "***************************END* config.php *END********************************"
echo "==============================================================================="

echo "*************************BEGIN* imap.php *BEGIN******************************"
echo "==============================================================================="
cat /config/imap.php
echo "***************************END* imap.php *END********************************"
echo "==============================================================================="

# run application
echo "Starting supervisord..."
/usr/bin/supervisord -c /etc/supervisord.conf
