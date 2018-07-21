# systemgraphs

First inside your web directory...

    git clone https://github.com/geekism/systemgraphs.git
    cd systemgraphs

once saved. we will have to set some variables. so it works correctly..

    nano system.pl

Then look for these lines:

 my $rrd = '/var/lib/rrd';
 my $img = '/srv/justla.me/graphs/';
 my $rrdtool = '/usr/bin/rrdtool';

You can leave most of these alone, but $img must be set to the same directory system.pl is in.

Then we'll need to edit the interface in index.pl..

    nano index.pl

change 'venet0' to 'something0'

OR use this command

    sed -i 's/venet0/wlp3s0/' system.pl

Then we'll have to install the crontab:

     crontab -e
     */5 * * * * perl /srv/justla.me/newgraphs/system.pl >> /srv/justla.me/newgraphs/collection.log 2>&1 && chown -R apache.apache /srv/justla.me/newgraphs/*.png

Now for the apache configuration side of this..

    sudo yum install php-cgi
    cd /etc/httpd/conf.d/
    nano 000-default.conf

and paste in

     <VirtualHost *:80>
         DocumentRoot "/srv/justla.me/"
         ServerName justla.me
         ServerAlias justla.me
        <Directory /srv/justla.me/>
            Options Indexes FollowSymLinks +ExecCGI
            #AddHandler cgi-script .cgi .pl
            AllowOverride All
            Order allow,deny
            Allow from all
        </Directory>
    </VirtualHost>

After all this

	service httpd restart

wait 1 hour and check to see if the graphs are updating


