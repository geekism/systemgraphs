# systemgraphs

Install depends ...

Debian:

    rrdtool
    librrdp-perl
    apache2
    libapache2-mod-perl2
    librrd8
    librrds-perl
    php-rrd
    librrdtool-oo-perl

CentOS:

    rrdtool-perl-1.3.8-10.el6.x86_64
    rrdtool-1.3.8-10.el6.x86_64
    httpd
    epel-release
    httpd-tools
    php-cgi

First inside your web directory...

    git clone https://github.com/geekism/systemgraphs.git
    cd systemgraphs

Once saved. we will have to set some variables. so it works correctly..

    nano net.pl
    nano mem.pl
    nano net.pl

Then look for these lines:

    my $rrd = '/var/lib/rrd';
    my $img = '/var/www/html/';

You can leave most of these alone, but $img must be set to the same directory net.pl, mem.pl, cpu.pl is in.

Then we'll need to edit the interface in index.pl..

    nano index.pl

Then change:

    &ProcessInterface("wlp3s0", "virtual network");

To something:

    &ProcessInterface("whatever0", "virtual network");

Then we'll have to install the crontab:

     crontab -e
     */5 * * * * /var/www/html/init >/dev/null 2>&1 && chown -R apache.apache /var/www/htmlnewgraphs/*.png


Or issue this command:

    (crontab -l 2>/dev/null; echo "*/5 * * * * /var/www/html/init >/dev/null 2>&1") | crontab -

Now for the apache configuration side of this..

    sudo yum install php-cgi        (sudo apt install libapache2-mod-perl2)
    cd /etc/httpd/conf.d/           (cd /etc/apache2/sites-enabled/)
    sudo nano 000-default.conf      (sudo nano 000-default.conf)

Now paste into 000-default.conf:

     <VirtualHost *:80>
         DocumentRoot "/var/www/html"
         ServerName justla.me
         ServerAlias justla.me
        <Directory /var/www/html>
            Options Indexes FollowSymLinks +ExecCGI
            AddHandler cgi-script .cgi
            AddHandler cgi-script .pl
            AllowOverride All
            Order allow,deny
            Allow from all
        </Directory>
     </VirtualHost>

Add the modules to 000-default.conf

Debian:

    LoadModule cgid_module /usr/lib/apache2/modules/mod_cgid.so
    LoadModule cgi_module /usr/lib/apache2/modules/mod_cgi.so

CentOS:

    Nothing to add

Now lets create .htaccess

	cd /var/www/html
	nano .htaccess

	DirectoryIndex index.html index.cgi index.pl
	AddHandler cgi-script .cgi
	AddHandler cgi-script .pl
	Options +ExecCGI

Or paste the below, From "cat" to "EOF". That part is VERY important.

    cat >/var/www/html/.htaccess<<EOF
        DirectoryIndex index.html index.cgi index.pl
        AddHandler cgi-script .cgi
        AddHandler cgi-script .pl
        Options +ExecCGI
    EOF

Save and issue: chown -R www-data.www-data .

	service httpd restart (service apache2 restart)

Wait 1 hour and check to see if the graphs are updating


