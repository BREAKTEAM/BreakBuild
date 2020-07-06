#!/bin/bash
#######################################################
# URAVPS - Script install Lemp in Centos 7
# Author: thelawbreaker - URAVPS
# To install type: chmod +x uravps.sh && ./uravps.sh
#######################################################
uravps_vers="1.0.2"
phpmyadmin_version="5.2.0" # Released 2020-03-21.
script_resource="https://resource.uravps.com"
low_ram='262144' # 256MB

yum -y install gawk bc wget lsof

clear
printf "=========================================================================\n"
printf "                           URA VPS                                       \n"
printf "                     Check parameter of server                           \n"
printf "=========================================================================\n"

cpu_name=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
cpu_cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
cpu_freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
server_ram_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
server_ram_mb=`echo "scale=0;$server_ram_total/1024" | bc`
server_hdd=$( df -h | awk 'NR==2 {print $2}' )
server_swap_total=$(awk '/SwapTotal/ {print $2}' /proc/meminfo)
server_swap_mb=`echo "scale=0;$server_swap_total/1024" | bc`
server_ip=$(curl ipinfo.io/ip)

printf "=========================================================================\n"
printf "Result \n"
printf "=========================================================================\n"
echo "CPU        : $cpu_name"
echo "CPU core   : $cpu_cores"
echo "Core speed : $cpu_freq MHz"
echo "Total RAM  : $server_ram_mb MB"
echo "Swap       : $server_swap_mb MB"
echo "Disk       : $server_hdd GB"
echo "IP         : $server_ip"
printf "=========================================================================\n"
printf "=========================================================================\n"

if [ $server_ram_total -lt $low_ram ]; then
	echo -e "Warning: Ram is slow \n (it nhat 256MB) \n"
	echo "Exit..."
	exit
fi
sleep 3

clear
printf "=========================================================================\n"
printf "                           URA VPS                                       \n"
printf "Preparing to install...                                                  \n"
printf "=========================================================================\n"

printf "You want using PHP version??\n"
prompt="Enter selection [1-3]: \n"
php_version="7.4"; # Default PHP 7.1
options=("PHP 7.4" "PHP 7.2" "PHP 7.1")
PS3="$prompt"
select opt in "${options[@]}"; do

    case "$REPLY" in
    1) php_version="7.4"; break;;
    2) php_version="7.2"; break;;
    3) php_version="7.1"; break;;
    $(( ${#options[@]}+1 )) ) printf "\nSetup PHP 7.4\n"; break;;
    *) printf "Invalid, the system will install by default PHP 7.4\n"; break;;
    esac

done

printf "\Enter the default domain (www/non-www) [ENTER]: "
read server_name
if [ "$server_name" = "" ]; then
	server_name="uravps.com"
	echo "Invalid, domain default = uravps.com"
fi

printf "\nEnter the port manager [ENTER]: "
read admin_port
if [ "$admin_port" == "" ] || [ "$admin_port" == "2411" ] || [ $admin_port == "7777" ] || [ $admin_port -lt 2000 ] || [ $admin_port -gt 9999 ] || [ $(lsof -i -P | grep ":$admin_port " | wc -l) != "0" ]; then
	admin_port="1408"
	echo "Port invalid, port default: 1408"
	echo
fi

printf "=========================================================================\n"
printf "                            URA VPS                                      \n"
printf "Preparation is complete                                                  \n"
printf "=========================================================================\n"


timedatectl set-timezone Asia/Ho_Chi_Minh
ntpdate time.apple.com

if [ -s /etc/selinux/config ]; then
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
fi
setenforce 0

# Install EPEL + Remi Repo
yum -y install epel-release yum-utils
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

# Install Nginx Repo
rpm -Uvh $script_resource/nginx-1.18.0-1.el7.ngx.x86_64.rpm

# Install MariaDB Repo
curl -sS $script_resource/mariadb_repo_setup | sudo bash

systemctl stop  saslauthd.service
systemctl disable saslauthd.service

yum -y remove mysql* php* httpd* sendmail* postfix* rsyslog*
yum clean all
yum -y update

clear
printf "=========================================================================\n"
printf "                           URAVPS                                        \n"
printf "Start the installation...                                                \n"
printf "=========================================================================\n"
sleep 3

# Install Nginx, PHP-FPM and modules

# Enable Remi Repo
yum-config-manager --enable remi

if [ "$php_version" = "7.4" ]; then
	yum-config-manager --enable remi-php74
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli php-pecl-zip
elif [ "$php_version" = "7.2" ]; then
	yum-config-manager --enable remi-php72
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli php-pecl-zip
elif [ "$php_version" = "7.1" ]; then
	yum-config-manager --enable remi-php71
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-opcache php-cli
else
	yum -y install nginx php-fpm php-common php-gd php-mysqlnd php-pdo php-xml php-mbstring php-mcrypt php-curl php-devel php-cli gcc
fi

# Install MariaDB
yum -y install MariaDB-server MariaDB-client

# Install Others
yum -y install exim syslog-ng syslog-ng-libdbi cronie iptables-services fail2ban unzip zip nano openssl ntpdate

clear
printf "=========================================================================\n"
printf "                           URAPVS                                        \n"
printf "Start configuration...                                                   \n"
printf "=========================================================================\n"
sleep 3

# Autostart
systemctl enable nginx.service
systemctl enable php-fpm.service
systemctl enable mysql.service # Failed to execute operation: No such file or directory
systemctl enable fail2ban.service

# Disable firewalld and install iptables
systemctl mask firewalld
systemctl enable iptables
systemctl enable ip6tables
systemctl stop firewalld
systemctl start iptables
systemctl start ip6tables

#systemctl start  exim.service
#systemctl start  syslog-ng.service

mkdir -p /home/$server_name/public_html
mkdir /home/$server_name/private_html
mkdir /home/$server_name/logs
chmod 777 /home/$server_name/logs

mkdir -p /var/log/nginx
chown -R nginx:nginx /var/log/nginx
chown -R nginx:nginx /var/lib/php/session

wget -q $script_resource/index.html -O /home/$server_name/public_html/index.html

systemctl start nginx.service
systemctl start php-fpm.service
systemctl start mysql.service

# PHP #
phplowmem='2097152'
check_phplowmem=$(expr $server_ram_total \< $phplowmem)
max_children=`echo "scale=0;$server_ram_mb*0.4/30" | bc`
if [ "$check_phplowmem" == "1" ]; then
	lessphpmem=y
fi

if [[ "$lessphpmem" = [yY] ]]; then
	# echo -e "\nCopying php-fpm-min.conf /etc/php-fpm.d/www.conf\n"
	wget -q $script_resource/php-fpm-min.conf -O /etc/php-fpm.conf
	wget -q $script_resource/www-min.conf -O /etc/php-fpm.d/www.conf
else
	# echo -e "\nCopying php-fpm.conf /etc/php-fpm.d/www.conf\n"
	wget -q $script_resource/php-fpm.conf -O /etc/php-fpm.conf
	wget -q $script_resource/www.conf -O /etc/php-fpm.d/www.conf
fi # lessphpmem

sed -i "s/server_name_here/$server_name/g" /etc/php-fpm.conf
sed -i "s/server_name_here/$server_name/g" /etc/php-fpm.d/www.conf
sed -i "s/max_children_here/$max_children/g" /etc/php-fpm.d/www.conf

# dynamic PHP memory_limit calculation
if [[ "$server_ram_total" -le '262144' ]]; then
	php_memorylimit='48M'
	php_uploadlimit='48M'
	php_realpathlimit='256k'
	php_realpathttl='14400'
elif [[ "$server_ram_total" -gt '262144' && "$server_ram_total" -le '393216' ]]; then
	php_memorylimit='96M'
	php_uploadlimit='96M'
	php_realpathlimit='320k'
	php_realpathttl='21600'
elif [[ "$server_ram_total" -gt '393216' && "$server_ram_total" -le '524288' ]]; then
	php_memorylimit='128M'
	php_uploadlimit='128M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '524288' && "$server_ram_total" -le '1049576' ]]; then
	php_memorylimit='160M'
	php_uploadlimit='160M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '1049576' && "$server_ram_total" -le '2097152' ]]; then
	php_memorylimit='256M'
	php_uploadlimit='256M'
	php_realpathlimit='384k'
	php_realpathttl='28800'
elif [[ "$server_ram_total" -gt '2097152' && "$server_ram_total" -le '3145728' ]]; then
	php_memorylimit='320M'
	php_uploadlimit='320M'
	php_realpathlimit='512k'
	php_realpathttl='43200'
elif [[ "$server_ram_total" -gt '3145728' && "$server_ram_total" -le '4194304' ]]; then
	php_memorylimit='512M'
	php_uploadlimit='512M'
	php_realpathlimit='512k'
	php_realpathttl='43200'
elif [[ "$server_ram_total" -gt '4194304' ]]; then
	php_memorylimit='800M'
	php_uploadlimit='800M'
	php_realpathlimit='640k'
	php_realpathttl='86400'
fi

cat > "/etc/php.d/00-uravps-custom.ini" <<END
date.timezone = Asia/Ho_Chi_Minh
max_execution_time = 180
short_open_tag = On
realpath_cache_size = $php_realpathlimit
realpath_cache_ttl = $php_realpathttl
memory_limit = $php_memorylimit
upload_max_filesize = $php_uploadlimit
post_max_size = $php_uploadlimit
expose_php = Off
mail.add_x_header = Off
max_input_nesting_level = 128
max_input_vars = 2000
mysqlnd.net_cmd_buffer_size = 16384
always_populate_raw_post_data=-1
disable_functions=shell_exec
END

# Zend Opcache
opcache_path='opcache.so' #Default for PHP 5.5 and newer

if [ "$php_version" = "5.4" ]; then
	cd /usr/local/src
	wget http://pecl.php.net/get/ZendOpcache
	tar xvfz ZendOpcache
	cd zendopcache-7.*
	phpize
	php_config_path=`which php-config`
	./configure --with-php-config=$php_config_path
	make
	make install
	rm -rf /usr/local/src/zendopcache*
	rm -f ZendOpcache
	opcache_path=`find / -name 'opcache.so'`
fi

wget -q https://raw.github.com/amnuts/opcache-gui/master/index.php -O /home/$server_name/private_html/op.php
cat > /etc/php.d/*opcache*.ini <<END
zend_extension=$opcache_path
opcache.enable=1
opcache.enable_cli=1
opcache.memory_consumption=128
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=4000
opcache.max_wasted_percentage=5
opcache.use_cwd=1
opcache.validate_timestamps=1
opcache.revalidate_freq=60
opcache.fast_shutdown=1
opcache.blacklist_filename=/etc/php.d/opcache-default.blacklist
END

cat > /etc/php.d/opcache-default.blacklist <<END
/home/*/public_html/wp-content/plugins/backwpup/*
/home/*/public_html/wp-content/plugins/duplicator/*
/home/*/public_html/wp-content/plugins/updraftplus/*
/home/$server_name/private_html/
END

systemctl restart php-fpm.service

# Nginx #
cat > "/etc/nginx/nginx.conf" <<END

user  nginx;
worker_processes  $cpu_cores;
worker_rlimit_nofile 260000;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
	worker_connections  2048;
	accept_mutex off;
	accept_mutex_delay 200ms;
	use epoll;
	#multi_accept on;
}

http {
	include       /etc/nginx/mime.types;
	default_type  application/octet-stream;

	log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
	              '\$status \$body_bytes_sent "\$http_referer" '
	              '"\$http_user_agent" "\$http_x_forwarded_for"';

	#Disable IFRAME
	add_header X-Frame-Options SAMEORIGIN;

	#Prevent Cross-site scripting (XSS) attacks
	add_header X-XSS-Protection "1; mode=block";

	#Prevent MIME-sniffing
	add_header X-Content-Type-Options nosniff;

	access_log  off;
	sendfile on;
	tcp_nopush on;
	tcp_nodelay off;
	types_hash_max_size 2048;
	server_tokens off;
	server_names_hash_bucket_size 128;
	client_max_body_size 0;
	client_body_buffer_size 256k;
	client_body_in_file_only off;
	client_body_timeout 60s;
	client_header_buffer_size 256k;
	client_header_timeout  20s;
	large_client_header_buffers 8 256k;
	keepalive_timeout 10;
	keepalive_disable msie6;
	reset_timedout_connection on;
	send_timeout 60s;

	gzip on;
	gzip_static on;
	gzip_disable "msie6";
	gzip_vary on;
	gzip_proxied any;
	gzip_comp_level 6;
	gzip_buffers 16 8k;
	gzip_http_version 1.1;
	gzip_types text/plain text/css application/json text/javascript application/javascript text/xml application/xml application/xml+rss;

	include /etc/nginx/conf.d/*.conf;
}
END

cat > "/usr/share/nginx/html/403.html" <<END
<html>
<head><title>403 Forbidden</title></head>
<body bgcolor="white">
<center><h1>403 Forbidden</h1></center>
<hr><center>URAPVS</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

cat > "/usr/share/nginx/html/404.html" <<END
<html>
<head><title>404 Not Found</title></head>
<body bgcolor="white">
<center><h1>404 Not Found</h1></center>
<hr><center>URAPVS</center>
</body>
</html>
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
<!-- a padding to disable MSIE and Chrome friendly error page -->
END

rm -rf /etc/nginx/conf.d/*
> /etc/nginx/conf.d/default.conf

server_name_alias="www.$server_name"
if [[ $server_name == *www* ]]; then
    server_name_alias=${server_name/www./''}
fi

cat > "/etc/nginx/conf.d/$server_name.conf" <<END
server {
	listen 80;

	server_name $server_name_alias;
	rewrite ^(.*) http://$server_name\$1 permanent;
}

server {
	listen 80 default_server;

	# access_log off;
	access_log /home/$server_name/logs/access.log;
	# error_log off;
    	error_log /home/$server_name/logs/error.log;

    	root /home/$server_name/public_html;
	index index.php index.html index.htm;
    	server_name $server_name;

    	location / {
		try_files \$uri \$uri/ /index.php?\$args;
	}

	# Custom configuration
	include /home/$server_name/public_html/*.conf;

    	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        	include /etc/nginx/fastcgi_params;
        	fastcgi_pass 127.0.0.1:9000;
        	fastcgi_index index.php;
		fastcgi_connect_timeout 1000;
		fastcgi_send_timeout 1000;
		fastcgi_read_timeout 1000;
		fastcgi_buffer_size 256k;
		fastcgi_buffers 4 256k;
		fastcgi_busy_buffers_size 256k;
		fastcgi_temp_file_write_size 256k;
		fastcgi_intercept_errors on;
        	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    	}

	location /nginx_status {
  		stub_status on;
  		access_log   off;
		allow 127.0.0.1;
		allow $server_ip;
		deny all;
	}

	location /php_status {
		fastcgi_pass 127.0.0.1:9000;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME  \$document_root\$fastcgi_script_name;
		include /etc/nginx/fastcgi_params;
		allow 127.0.0.1;
		allow $server_ip;
		deny all;
    	}

	location ~ /\. {
		deny all;
	}

        location = /favicon.ico {
                log_not_found off;
                access_log off;
        }

	location = /robots.txt {
		allow all;
		log_not_found off;
		access_log off;
	}

	location ~* \.(3gp|gif|jpg|jpeg|png|ico|wmv|avi|asf|asx|mpg|mpeg|mp4|pls|mp3|mid|wav|swf|flv|exe|zip|tar|rar|gz|tgz|bz2|uha|7z|doc|docx|xls|xlsx|pdf|iso|eot|svg|ttf|woff)$ {
	        gzip_static off;
		add_header Pragma public;
		add_header Cache-Control "public, must-revalidate, proxy-revalidate";
		access_log off;
		expires 30d;
		break;
        }

        location ~* \.(txt|js|css)$ {
	        add_header Pragma public;
		add_header Cache-Control "public, must-revalidate, proxy-revalidate";
		access_log off;
		expires 30d;
		break;
        }
}

server {
	listen $admin_port;

 	access_log off;
	log_not_found off;
 	error_log /home/$server_name/logs/nginx_error.log;

    	root /home/$server_name/private_html;
	index index.php index.html index.htm;
    	server_name $server_name;

	auth_basic "Restricted";
	auth_basic_user_file /home/$server_name/private_html/uravps/.htpasswd;

     	location / {
		autoindex on;
		try_files \$uri \$uri/ /index.php;
	}

    	location ~ \.php$ {
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
        	include /etc/nginx/fastcgi_params;
        	fastcgi_pass 127.0.0.1:9000;
        	fastcgi_index index.php;
		fastcgi_connect_timeout 1000;
		fastcgi_send_timeout 1000;
		fastcgi_read_timeout 1000;
		fastcgi_buffer_size 256k;
		fastcgi_buffers 4 256k;
		fastcgi_busy_buffers_size 256k;
		fastcgi_temp_file_write_size 256k;
		fastcgi_intercept_errors on;
        	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    	}

	location ~ /\. {
		deny all;
	}
}
END

cat >> "/etc/security/limits.conf" <<END
* soft nofile 262144
* hard nofile 262144
nginx soft nofile 262144
nginx hard nofile 262144
nobody soft nofile 262144
nobody hard nofile 262144
root soft nofile 262144
root hard nofile 262144
END

ulimit -n 262144

systemctl restart nginx.service

# MariaDB #
# set /etc/my.cnf templates from Centmin Mod
cp /etc/my.cnf /etc/my.cnf-original

if [[ "$(expr $server_ram_total \<= 2099000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-min.cnf file to /etc/my.cnf\n"
	wget -q $script_resource/my-mdb10-min.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \> 2100001)" = "1" && "$(expr $server_ram_total \<= 4190000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10.cnf file to /etc/my.cnf\n"
	wget -q $script_resource/my-mdb10.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 4190001)" = "1" && "$(expr $server_ram_total \<= 8199999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-4gb.cnf file to /etc/my.cnf\n"
	wget -q $script_resource/my-mdb10-4gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 8200000)" = "1" && "$(expr $server_ram_total \<= 15999999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-8gb.cnf file to /etc/my.cnf\n"
	wget -q $script_resource/my-mdb10-8gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 16000000)" = "1" && "$(expr $server_ram_total \<= 31999999)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-16gb.cnf file to /etc/my.cnf\n"
	wget -q $script_resource/my-mdb10-16gb.cnf -O /etc/my.cnf
fi

if [[ "$(expr $server_ram_total \>= 32000000)" = "1" ]]; then
	# echo -e "\nCopying MariaDB my-mdb10-32gb.cnf file to /etc/my.cnf\n"
	wget -q $script_resource/my-mdb10-32gb.cnf -O /etc/my.cnf
fi

sed -i "s/server_name_here/$server_name/g" /etc/my.cnf

rm -f /var/lib/mysql/ib_logfile0
rm -f /var/lib/mysql/ib_logfile1
rm -f /var/lib/mysql/ibdata1

clear
printf "=========================================================================\n"
printf "                           URAVPS                                        \n"
printf "MariaDB configuration...                                                 \n"
printf "=========================================================================\n"
# Random password for MySQL root account
root_password=`date |md5sum |cut -c '14-30'`
sleep 1
# Random password for MySQL admin account
admin_password=`date |md5sum |cut -c '14-30'`
'/usr/bin/mysqladmin' -u root password "$root_password"
mysql -u root -p"$root_password" -e "GRANT ALL PRIVILEGES ON *.* TO 'admin'@'localhost' IDENTIFIED BY '$admin_password' WITH GRANT OPTION;"
mysql -u root -p"$root_password" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost')"
mysql -u root -p"$root_password" -e "DELETE FROM mysql.user WHERE User=''"
mysql -u root -p"$root_password" -e "DROP User '';"
mysql -u root -p"$root_password" -e "DROP DATABASE test"
mysql -u root -p"$root_password" -e "FLUSH PRIVILEGES"

cat > "/root/.my.cnf" <<END
[client]
user=root
password=$root_password
END
chmod 600 /root/.my.cnf

# Fix MariaDB 10
systemctl stop mysql.service

wget -q $script_resource/mariadb10_3tables.sql1
mv mariadb10_3tables.sql1 mariadb10_3tables.sql

rm -rf /var/lib/mysql/mysql/gtid_slave_pos.ibd
rm -rf /var/lib/mysql/mysql/innodb_table_stats.ibd
rm -rf /var/lib/mysql/mysql/innodb_index_stats.ibd

systemctl start mysql.service

mysql -e "ALTER TABLE mysql.gtid_slave_pos DISCARD TABLESPACE;" 2> /dev/null
mysql -e "ALTER TABLE mysql.innodb_table_stats DISCARD TABLESPACE;" 2> /dev/null
mysql -e "ALTER TABLE mysql.innodb_index_stats DISCARD TABLESPACE;" 2> /dev/null

mysql mysql < mariadb10_3tables.sql

systemctl restart mysql.service
mysql_upgrade --force mysql
rm -f mariadb10_3tables.sql

if [ "$1" = "wordpress" ]; then
	clear
	printf "=========================================================================\n"
	printf "                           URAVPS                                        \n"
	printf "Setup wordpress...                                                       \n"
	printf "=========================================================================\n"
	cd /home/$server_name/public_html/
	rm -f index.html
	# Generate wordpress database
	wordpress_password=`date |md5sum |cut -c '1-15'`
	mysql -u root -p"$root_password" -e "CREATE DATABASE wordpress;GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost IDENTIFIED BY '$wordpress_password';FLUSH PRIVILEGES;"

	# Download latest WordPress and uncompress
	wget https://wordpress.org/latest.tar.gz
	tar zxf latest.tar.gz
	mv wordpress/* ./

	# Grab Salt Keys
	wget -O /tmp/wp.keys https://api.wordpress.org/secret-key/1.1/salt/

	# Butcher our wp-config.php file
	sed -e "s/database_name_here/wordpress/" -e "s/username_here/wordpress/" -e "s/password_here/"$wordpress_password"/" wp-config-sample.php > wp-config.php
	sed -i '/#@-/r /tmp/wp.keys' wp-config.php
	sed -i "/#@+/,/#@-/d" wp-config.php

	# Tidy up
	rm -rf wordpress latest.tar.gz /tmp/wp.keys wp wp-config-sample.php
fi

clear
printf "=========================================================================\n"
printf "                           URAVPS                                        \n"
printf "Configuration successful...                                              \n"
printf "=========================================================================\n"
# URAVPS Script Admin
cd /home/$server_name/private_html/
wget -q $script_resource/administrator.zip
unzip -q administrator.zip && rm -f administrator.zip
mv -f administrator/* .
rm -rf administrator
printf "admin:$(openssl passwd -apr1 $admin_password)\n" > /home/$server_name/private_html/uravps/.htpasswd
sed -i "s/rootpassword/$root_password/g" /home/$server_name/private_html/uravps/SQLManager.php

# Server Info
mkdir /home/$server_name/private_html/serverinfo/
cd /home/$server_name/private_html/serverinfo/
wget -q $script_resource/serverinfo.zip
unzip -q serverinfo.zip && rm -f serverinfo.zip

# phpMyAdmin
mkdir /home/$server_name/private_html/phpmyadmin/
cd /home/$server_name/private_html/phpmyadmin/
wget -q https://files.phpmyadmin.net/phpMyAdmin/$phpmyadmin_version/phpMyAdmin-$phpmyadmin_version-english.zip
unzip -q phpMyAdmin-$phpmyadmin_version-english.zip
mv -f phpMyAdmin-$phpmyadmin_version-english/* .
rm -rf phpMyAdmin-$phpmyadmin_version-english*

# eXtplorer File Manager
mkdir /home/$server_name/private_html/filemanager/
cd /home/$server_name/private_html/filemanager/
wget --no-check-certificate -q https://extplorer.net/attachments/download/74/eXtplorer_2.1.10.zip # Note ID 74
unzip -q eXtplorer_$extplorer_version.zip && rm -f eXtplorer_$extplorer_version.zip
cat > "/home/$server_name/private_html/filemanager/config/.htusers.php" <<END
<?php
        if( !defined( '_JEXEC' ) && !defined( '_VALID_MOS' ) ) die( 'Restricted access' );
        \$GLOBALS["users"]=array(
        array('admin','$(echo -n "$admin_password" | md5sum | awk '{print $1}')','/home','http://localhost','1','','7',1),
);
?>

# Log Rotation
cat > "/etc/logrotate.d/nginx" <<END
/home/*/logs/access.log /home/*/logs/error.log /home/*/logs/nginx_error.log {
	create 640 nginx nginx
        daily
        missingok
        rotate 5
        maxage 7
        compress
        delaycompress
        notifempty
        sharedscripts
        postrotate
                [ -f /var/run/nginx.pid ] && kill -USR1 \`cat /var/run/nginx.pid\`
        endscript
	su nginx nginx
}
END
cat > "/etc/logrotate.d/php-fpm" <<END
/home/*/logs/php-fpm*.log {
        daily
        compress
        maxage 7
        missingok
        notifempty
        sharedscripts
        delaycompress
        postrotate
            /bin/kill -SIGUSR1 \`cat /var/run/php-fpm/php-fpm.pid 2>/dev/null\` 2>/dev/null || true
        endscript
}
END
cat > "/etc/logrotate.d/mysql" <<END
/home/*/logs/mysql*.log {
        create 640 mysql mysql
        notifempty
        daily
        rotate 3
        maxage 7
        missingok
        compress
        postrotate
        # just if mysqld is really running
        if test -x /usr/bin/mysqladmin && \
           /usr/bin/mysqladmin ping &>/dev/null
        then
           /usr/bin/mysqladmin flush-logs
        fi
        endscript
	su mysql mysql
}
END

# Change port SSH
sed -i 's/#Port 22/Port 2411/g' /etc/ssh/sshd_config

cat > "/etc/fail2ban/jail.local" <<END
[ssh-iptables]
enabled  = true
filter   = sshd
action   = iptables[name=SSH, port=2411, protocol=tcp]
logpath  = /var/log/secure
maxretry = 3
bantime = 3600

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
action = iptables[name=NoAuthFailures, port=$admin_port, protocol=tcp]
logpath = /home/$server_name/logs/nginx_error.log
maxretry = 3
bantime = 3600
END

systemctl start fail2ban.service

# Open port
if [ -f /etc/sysconfig/iptables ]; then
systemctl start  iptables.service
iptables -I INPUT -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -p tcp --dport 25 -j ACCEPT
iptables -I INPUT -p tcp --dport 443 -j ACCEPT
iptables -I INPUT -p tcp --dport 465 -j ACCEPT
iptables -I INPUT -p tcp --dport 587 -j ACCEPT
iptables -I INPUT -p tcp --dport $admin_port -j ACCEPT
iptables -I INPUT -p tcp --dport 2411 -j ACCEPT
service iptables save
fi

mkdir -p /var/lib/php/session
chown -R nginx:nginx /var/lib/php
chown nginx:nginx /home/$server_name
chown -R nginx:nginx /home/*/public_html
chown -R nginx:nginx /home/*/private_html

rm -f /root/install
echo -n "cd /home" >> /root/.bashrc

mkdir -p /etc/uravps/

cat > "/etc/uravps/scripts.conf" <<END
uravps_vers="$uravps_vers"
server_name="$server_name"
server_ip="$server_ip"
admin_port="$admin_port"
resource_url="$script_resource"
mariadb_root_password="$root_password"
END
chmod 600 /etc/uravps/scripts.conf

clear
printf "=========================================================================\n"
printf "Adding menu... \n"
printf "=========================================================================\n"

wget -q $script_resource/uravps -O /bin/uravps && chmod +x /bin/uravps
mkdir /etc/uravps/menu/
cd /etc/uravps/menu/
wget -q $script_resource/uravps_menu.zip
unzip -q uravps_menu.zip && rm -f uravps_menu.zip
mv -f /etc/uravps/menu/uravps_menu/* /etc/uravps/menu/
chmod +x /etc/uravps/menu/*

clear
cat > "/root/uravps.txt" <<END
=========================================================================
                                  URAVPS
                           MANAGE VPS INFORMATION
=========================================================================
Command access URAVPS scripts: uravps

Domain default: http://$server_name/ or http://$server_ip/

URAVPS Script Admin:	http://$server_name:$admin_port/ or http://$server_ip:$admin_port/
File Manager:		http://$server_name:$admin_port/filemanager/ or http://$server_ip:$admin_port/filemanager/
phpMyAdmin:		http://$server_name:$admin_port/phpmyadmin/ or http://$server_ip:$admin_port/phpmyadmin/
Server Info:		http://$server_name:$admin_port/serverinfo/ or http://$server_ip:$admin_port/serverinfo/
PHP OPcache:		http://$server_name:$admin_port/op.php or http://$server_ip:$admin_port/op.php

Username: admin
Password: $admin_password

Support team: https://uravps.com
END

chmod 600 /root/uravps.txt

if [ "$1" = "wordpress" ]; then
	printf "=========================================================================\n"
	printf "                           URAVPS                                        \n"
	printf "Install successful URAVPS Script + WordPress! \n"
	printf "=========================================================================\n"
	printf "Access http://$server_name \n or http://$server_ip to config Wordpress   \n"
else
	printf "=========================================================================\n"
	printf "Scripts URAVPS install complete.. \n"
	printf "=========================================================================\n"
	printf "Infomation VPS                                                           \n"
	printf "=========================================================================\n"
	printf "Domain default: http://$server_name/ or http://$server_ip/\n"
fi

printf "=========================================================================\n"
printf "URAVPS Script Admin: http://$server_name:$admin_port/ \n or http://$server_ip:$admin_port/\n\n"
printf "File Manager: http://$server_name:$admin_port/filemanager/ \n or http://$server_ip:$admin_port/filemanager/\n\n"
printf "phpMyAdmin: http://$server_name:$admin_port/phpmyadmin/ \n or http://$server_ip:$admin_port/phpmyadmin/\n\n"
printf "Server Info: http://$server_name:$admin_port/serverinfo/ \n or http://$server_ip:$admin_port/serverinfo/\n\n"
printf "PHP OPcache: http://$server_name:$admin_port/op.php \n or http://$server_ip:$admin_port/op.php\n"
printf "=========================================================================\n"
printf " Info login:                                                             \n"
printf " Username: admin                                                         \n"
printf " Password: $admin_password                                               \n"
printf "=========================================================================\n"
printf "/root/uravps.txt                                                         \n"
printf "=========================================================================\n"
printf "***Warning: SSH port change to 2411                                      \n"
printf "=========================================================================\n"
printf "Command manager server    \"uravps\".                                    \n"
printf "Support team: https://uravps.com                                         \n"
printf "=========================================================================\n"
printf "Reboot server....                                                      \n\n"
sleep 3
reboot
exit
