### BreakBuild Readme

BreakBuild is a free collection (simple & secure) of shell scripts deployment of
LEMP (Linux, Nginx, MySQL and PHP) for Centos

Have you considered upgrading from shared hosting to a VPS or dedicated
server but held off by the costly control panel licenses, or the fear of
managing a Linux server? Now you can leave those worries behind!

BreakBuild scripts automate configuration of servers for web hosting,
so your websites can be online within minutes! Ideal for those who
prefer hosting sites on their own server without resorting to expensive
and bloated control panels.

The following are installed:-

-   Nginx
-   MariaDB  (Percona, PostgreSQL comming soon)
-   PHP-FPM + commonly used PHP modules
-   Postfix mail server (securely configured to be outgoing only)
-   Zend OPcache
-   EXtplorer 
#### Features
- Installation information is simple.
- Using Nginx repo instead of compile from source as other scripts makes installing Nginx faster, later upgrading is also a lot easier.
- Replace MySQL with MariaDB to keep up with the trend (this is an improved version of MySQL, which works similarly but for higher performance than MySQL, and the latest version of CentOS 7 officially supports MariaDB).
- Option to use PHP version 7.1 (latest), PHP 7.0, PHP 5.6 installation.
- There is an eXtplorer File Manager.
- Automatically install the Zend Opcache module and can monitor status on the web.
- Automatic update for Nginx, PHP, MariaDB.
- Monitor status server on the web, can use mobile access anywhere.
- Change the default SSH port from 22 to 2411 SSH Brute Force Attack, with Fail2ban block IP immediately if the wrong login 3 times.
#### Install
git clone https://github.com/BREAKTEAM/BreakBuild && cd BreakBuild && chmod +x breakbuild.sh && ./breakbuild.sh
- Command : breakteam
