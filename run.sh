#!/bin/bash

echo -ne '#                         (5%)\r'

sudo apt -y install squid
sudo systemctl start squid
sudo systemctl enable squid
sudo apt -y install apache2-utils
sudo touch /etc/squid/passwd
sudo sudo chown proxy /etc/squid/passwd
sudo htpasswd -b -c /etc/squid/passwd $2 $3

echo -ne '#####                     (33%)\r'

cd "/etc/squid/"

CONFIG_FILE="squid.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "/etc/squid/$CONFIG_FILE does not exist.";
    exit 1;
fi

CHECK_INSTALLED1=$(grep -w 'http_access allow auth_users' $CONFIG_FILE)
CHECK_INSTALLED2=$(grep -w '#http_access allow localhost' $CONFIG_FILE)

[ -n "$CHECK_INSTALLED1" ] && { echo "Proxy server already installed."; exit 1; }
[ -n "$CHECK_INSTALLED2" ] && { echo "Proxy server already installed."; exit 1; }

echo -ne '#############             (50%)\r'

AUTH_CONFIG="auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Basic Authentication
auth_param basic credentialsttl 2 hours
acl auth_users proxy_auth REQUIRED
http_access allow auth_users"

{
    awk -v AUTH_CONFIG="$AUTH_CONFIG" '1;/settings for each scheme/{ print AUTH_CONFIG; }' $CONFIG_FILE > temp
    cat temp > $CONFIG_FILE
    rm -f temp
} &> /dev/null

echo -ne '###################       (66%)\r'

{
    sed -i 's/http_access allow localhost/#http_access allow localhost/g' $CONFIG_FILE
    sed '/acl localnet src 128\.199\.113\.87 /a #should be allowed' $CONFIG_FILE
} &> /dev/null

echo -ne '#####################     (70%)\r'

{
    awk -v IP_Address=$1 '1;/should be allowed/{print "acl localnet src " IP_Address}' $CONFIG_FILE > temp
    cat temp > $CONFIG_FILE
    rm -f temp

    PORT="2564"
    sed -i 's/http_port 3128/http_port '`echo $PORT`'/g' $CONFIG_FILE
} &> /dev/null

echo -ne '#######################   (90%)\r'

sudo systemctl restart squid
sudo ufw allow $PORT
echo -ne '##########################(100%)\r'

echo "Success! Proxy IP: $1:$PORT , Username=${2} | Password=${3}"