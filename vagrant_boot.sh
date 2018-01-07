#########################################################
# Supported version:
# PHP_VERSION = "5.6", "7.0", "7.1"
# MYSQL_VERSION = "5.6", "5.7"
#########################################################

# Variables
PHP_VERSION="7.0"
MYSQL_VERSION="5.7"
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

# Repositories
echo -e "\n--- Adding repositories... ---\n"
apt-add-repository ppa:ondrej/php >> /vagrant/vagrant_build.log 2>&1
add-apt-repository ppa:ondrej/php5-oldstable >> /vagrant/vagrant_build.log 2>&1
add-apt-repository 'deb http://archive.ubuntu.com/ubuntu trusty universe' >> /vagrant/vagrant_build.log 2>&1

echo -e "\n--- Updating packages list... ---\n"
apt-get update >> /vagrant/vagrant_build.log 2>&1

echo -e "\n--- Upgrading system... ---\n"
apt-get -y upgrade >> /vagrant/vagrant_build.log 2>&1

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
apt-get install -y php$PHP_VERSION-cli php$PHP_VERSION-cgi php$PHP_VERSION-curl php$PHP_VERSION-xml php$PHP_VERSION-zip php$PHP_VERSION-gd php$PHP_VERSION-mysql php$PHP_VERSION-mbstring php$PHP_VERSION-mcrypt php$PHP_VERSION-common php$PHP_VERSION-intl php$PHP_VERSION-xsl php$PHP_VERSION-json php$PHP_VERSION-sqlite3 php$PHP_VERSION-xdebug >> /vagrant/vagrant_build.log 2>&1
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
curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - >> /vagrant/vagrant_build.log
apt-get install -y nodejs >> /vagrant/vagrant_build.log

# Installing javascript components
echo -e "\n--- Installing javascript components ---\n"
npm install -g gulp bower yarn >> /vagrant/vagrant_build.log 2>&1
