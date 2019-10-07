################################################################
# Supported version:
# PHP_VERSION = "5.6", "7.0", "7.1", "7.2", "7.3", "7.4"
# MYSQL_VERSION = "5.6", "5.7"
# NODE_VERSION = "4", "5", "6", "7", "8", "9", "10", "11", "12"
################################################################

# Variables
PHP_VERSION="7.2"
MYSQL_VERSION="5.7"
NODE_VERSION="12"
DB_PASSWD_ROOT="root"

VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www/app"
  ServerName localhost
  <Directory "/var/www/app">
	AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

XDEBUG=$(cat <<EOF
xdebug.remote_enable=1
xdebug.remote_host=0.0.0.0
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.idekey="PHPSTORM"
EOF
)

MYSQL_CONF=$(cat <<EOF
[mysqld]
bind-address = 0.0.0.0
EOF
)

# Repositories
echo -e "\n--- Adding repositories... ---\n"
apt-add-repository ppa:ondrej/php >> /vagrant/vagrant_build.log 2>&1
add-apt-repository ppa:ondrej/php5-oldstable >> /vagrant/vagrant_build.log 2>&1
add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe' >> /vagrant/vagrant_build.log 2>&1

echo -e "\n--- Updating packages list... ---\n"
apt-get update >> /vagrant/vagrant_build.log 2>&1

# Installing and configuration MySQL
echo -e "\n--- Installing and configuration MySQL version: $MYSQL_VERSION... ---\n"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_PASSWD_ROOT"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_PASSWD_ROOT"

if [ $MYSQL_VERSION = "5.6" ]
then
	apt-get -y install mysql-server-$MYSQL_VERSION >> /vagrant/vagrant_build.log 2>&1
elif [ $MYSQL_VERSION = "5.7" ]
then
	apt-get -y install mysql-server >> /vagrant/vagrant_build.log 2>&1
fi

service mysql start

echo "${MYSQL_CONF}" >> /etc/mysql/my.cnf
mysql -uroot -p$DB_PASSWD_ROOT -e "CREATE USER 'root'@'%' IDENTIFIED BY '$DB_PASSWD_ROOT';" >> /vagrant/vagrant_build_mysql.log 2>&1
mysql -uroot -p$DB_PASSWD_ROOT -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';" >> /vagrant/vagrant_build_mysql.log 2>&1

service mysql restart

# Installing and configuration Apache2
echo -e "\n--- Installing and configuration Apache2... ---\n"
apt-get install -y apache2 >> /vagrant/vagrant_build.log 2>&1
a2enmod rewrite >> /vagrant/vagrant_build.log 2>&1

# Configuration VirtualHost
echo -e "\n--- Configuration VirtualHost ... ---\n"
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default.conf

service apache2 restart

# Installing and configuration PHP
echo -e "\n--- Installing and configuration PHP version: $PHP_VERSION... ---\n"
apt-get install -y php$PHP_VERSION >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-cli >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-cgi >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-curl >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-xml >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-zip >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-gd >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-mysql >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-mbstring >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-common >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-intl >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-xsl >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-json >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-sqlite3 >> /vagrant/vagrant_build.log 2>&1
apt-get install -y php$PHP_VERSION-xdebug >> /vagrant/vagrant_build.log 2>&1
echo "${XDEBUG}" >> /etc/php/$PHP_VERSION/cli/conf.d/20-xdebug.ini

service apache2 restart

# Installing Composer
echo -e "\n--- Installing Composer... ---\n"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" >> /vagrant/vagrant_build.log 2>&1
php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" >> /vagrant/vagrant_build.log 2>&1
php composer-setup.php --install-dir=/usr/local/bin --filename=composer >> /vagrant/vagrant_build.log 2>&1
php -r "unlink('composer-setup.php');" >> /vagrant/vagrant_build.log 2>&1

# Installing Node
echo -e "\n--- Installing and configuration Node.js... ---\n"
curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash - >> /vagrant/vagrant_build.log
apt-get install -y nodejs >> /vagrant/vagrant_build.log 2>&1

# Installing javascript components
echo -e "\n--- Installing javascript components ---\n"
npm install -g gulp bower yarn >> /vagrant/vagrant_build.log 2>&1

# Installing mailhog components
echo -e "\n--- Installing Mailhog... ---\n"
wget https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64 >> /vagrant/vagrant_build.log 2>&1
cp MailHog_linux_amd64 /usr/local/bin/mailhog >> /vagrant/vagrant_build.log 2>&1
chmod +x /usr/local/bin/mailhog >> /vagrant/vagrant_build.log 2>&1

tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=Mailhog
After=network.target
[Service]
User=vagrant
ExecStart=/usr/bin/env /usr/local/bin/mailhog > /dev/null 2>&1 &
[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable mailhog
service mailhog restart
