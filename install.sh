#!/bin/bash

function mem.pl() {
echo -ne "Writing: /var/www/html/mem.pl ... "
cat >/var/www/html/mem.pl<<'EOF'
#!/usr/bin/perl
use RRDs;
my $rrdtool = '/usr/bin/rrdtool';
my $rrd = '/var/lib/rrd';
my $img = '/var/www/html/';

my $mem = `free -b |grep Mem`;
my $swap = `free -b |grep Swap |cut -c19-29 |sed 's/ //g'`;
my @mema = split(/\s+/, $mem);
my $buffers = $mema[5];
my $cached = $mema[6];
$mem = $mema[2] - $buffers - $cached;
chomp($swap);

if (! -e "$rrd/mem.rrd") {
	print "creating rrd database for memory usage...\n";
	system("$rrdtool create $rrd/mem.rrd -s 300"
		." DS:mem:GAUGE:600:0:U"
		." DS:buf:GAUGE:600:0:U"
		." DS:cache:GAUGE:600:0:U"
		." DS:swap:GAUGE:600:0:U"
		." RRA:AVERAGE:0.5:1:576"
		." RRA:AVERAGE:0.5:6:672"
		." RRA:AVERAGE:0.5:24:732"
		." RRA:AVERAGE:0.5:144:1460");
}

#`$rrdtool update $rrd/mem.rrd -t mem:buf:cache:swap N:$mem:$buffers:$cached:$swap`;
RRDs::update "$rrd/mem.rrd",
		"-t", "mem:buf:cache:swap",
		"N:$mem:$buffers:$cached:$swap";
&CreateGraph("day");
&CreateGraph("week");
&CreateGraph("month"); 
&CreateGraph("year");

sub CreateGraph {

	system("$rrdtool graph $img/mem-$_[0].png"
		." -s \"-1$_[0]\""
		." -t \"memory usage over the last $_[0]\""
		." --lazy"
		." -h 80 -w 600"
		." -l 0"
		." -a PNG"
		." -v \"bytes\""
		." -b 1024"
		." DEF:mem=$rrd/mem.rrd:mem:AVERAGE"
		." DEF:buf=$rrd/mem.rrd:buf:AVERAGE"
		." DEF:cache=$rrd/mem.rrd:cache:AVERAGE"
		." DEF:swap=$rrd/mem.rrd:swap:AVERAGE"
		." CDEF:total=mem,swap,buf,cache,+,+,+"
		." CDEF:res=mem,buf,cache,+,+"
		." AREA:mem#FFCC66:\"Physical Memory Usage\""
		." STACK:buf#FF9999:\"Buffers\""
		." STACK:cache#FF0099:\"Cache\""
		." STACK:swap#FF9900:\"Swap Memory Usage\\n\""
		." GPRINT:mem:MAX:\"Residental  Max\\: %5.1lf %s\""
		." GPRINT:mem:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:mem:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:buf:MAX:\"Buffers     Max\\: %5.1lf %s\""
		." GPRINT:buf:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:buf:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:cache:MAX:\"Cache       Max\\: %5.1lf %s\""
		." GPRINT:cache:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:cache:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:swap:MAX:\"Swap        Max\\: %5.1lf %s\""
		." GPRINT:swap:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:swap:LAST:\" Current\\: %5.1lf %s\\n\""
		." GPRINT:total:MAX:\"Total       Max\\: %5.1lf %s\""
		." GPRINT:total:AVERAGE:\" Avg\\: %5.1lf %s\""
		." GPRINT:total:LAST:\" Current\\: %5.1lf %s\\n\""
		." LINE1:res#CC9966"
		." LINE1:total#CC6600 > /dev/null");
}
print "memory -> free: $mem buffers: $buffers cached: $cached swap: $swap\n";
EOF
chmod a+x /var/www/html/mem.pl
echo "${OK}"
}

function cpu.pl() {
echo -ne "Writing: /var/www/html/cpu.pl ... "
cat >/var/www/html/cpu.pl<<'EOF'
#!/usr/bin/perl

use RRDs;

my $rrdlog = '/var/lib/rrd/';
my $graphs = '/var/www/html/';

updatecpudata();
updatecpugraph('day');
updatecpugraph('week');
updatecpugraph('month');
updatecpugraph('year');

sub updatecpugraph {
        my $period    = $_[0];

        RRDs::graph ("$graphs/cpu-$period.png",
                "--start", "-1$period", "-aPNG", "-i", "-z",
                "--alt-y-grid", "-w 600", "-h 80", "-l 0", "-r",
                "-t cpu usage per $period",
                "-v perecent",
                "DEF:user=$rrdlog/cpu.rrd:user:AVERAGE",
                "DEF:system=$rrdlog/cpu.rrd:system:AVERAGE",
                "DEF:idle=$rrdlog/cpu.rrd:idle:AVERAGE",
                "DEF:io=$rrdlog/cpu.rrd:io:AVERAGE",
                "DEF:irq=$rrdlog/cpu.rrd:irq:AVERAGE",
                "CDEF:total=user,system,idle,io,irq,+,+,+,+",
                "CDEF:userpct=100,user,total,/,*",
                "CDEF:systempct=100,system,total,/,*",
                "CDEF:iopct=100,io,total,/,*",
                "CDEF:irqpct=100,irq,total,/,*",
                "AREA:userpct#0000FF:user cpu usage\\j",
                "STACK:systempct#FF0000:system cpu usage\\j",
                "STACK:iopct#FFFF00:iowait cpu usage\\j",
                "STACK:irqpct#00FFFF:irq cpu usage\\j",
                "GPRINT:userpct:MAX:maximal user cpu\\:%3.2lf%%",
                "GPRINT:userpct:AVERAGE:average user cpu\\:%3.2lf%%",
                "GPRINT:userpct:LAST:current user cpu\\:%3.2lf%%\\j",
                "GPRINT:systempct:MAX:maximal system cpu\\:%3.2lf%%",
                "GPRINT:systempct:AVERAGE:average system cpu\\:%3.2lf%%",
                "GPRINT:systempct:LAST:current system cpu\\:%3.2lf%%\\j",
                "GPRINT:iopct:MAX:maximal iowait cpu\\:%3.2lf%%",
                "GPRINT:iopct:AVERAGE:average iowait cpu\\:%3.2lf%%",
                "GPRINT:iopct:LAST:current iowait cpu\\:%3.2lf%%\\j",
                "GPRINT:irqpct:MAX:maximal irq cpu\\:%3.2lf%%",
                "GPRINT:irqpct:AVERAGE:average irq cpu\\:%3.2lf%%",
                "GPRINT:irqpct:LAST:current irq cpu\\:%3.2lf%%\\j");
        $ERROR = RRDs::error;
        print "Error in RRD::graph for cpu: $ERROR\n" if $ERROR;
}

sub updatecpudata {
        if ( ! -e "$rrdlog/cpu.rrd") {
                print "Creating cpu.rrd";
                RRDs::create ("$rrdlog/cpu.rrd", "--step=60",
                        "DS:user:COUNTER:600:0:U",
                        "DS:system:COUNTER:600:0:U",
                        "DS:idle:COUNTER:600:0:U",
                        "DS:io:COUNTER:600:0:U",
                        "DS:irq:COUNTER:600:0:U",
                        "RRA:AVERAGE:0.5:1:576",
                        "RRA:AVERAGE:0.5:6:672",
                        "RRA:AVERAGE:0.5:24:732",
                        "RRA:AVERAGE:0.5:144:1460");
                $ERROR = RRDs::error;
                print "Error in RRD::create for cpu: $ERROR\n" if $ERROR;
        }

        my ($cpu, $user, $nice, $system, $idle, $io, $irq, $softirq);

        open STAT, "/proc/stat";
        while(<STAT>) {
                chomp;
                /^cpu\s/ or next;
                ($cpu, $user, $nice, $system, $idle, $io, $irq, $softirq) = split /\s+/;
                last;
        }
        close STAT;
        $user += $nice;
        $irq  += $softirq;

        RRDs::update ("$rrdlog/cpu.rrd",
                "-t", "user:system:idle:io:irq", 
                "N:$user:$system:$idle:$io:$irq");
        $ERROR = RRDs::error;
        print "Error in RRD::update for cpu: $ERROR\n" if $ERROR;

print "cpu -> user: $user system: $system idle: $idle iowait: $io irq: $irq\n";
}

EOF
chmod a+x /var/www/html/cpu.pl
echo "${OK}"
}

function net.pl() {
	echo -ne "Writing: /var/www/html/net.pl ... "
cat >/var/www/html/net.pl<<'EOF'
#!/usr/bin/perl
use RRDs;
my $rrd = '/var/lib/rrd/';
my $img = '/var/www/html/';
&ProcessInterface("wlp3s0", "virtual network");

sub ProcessInterface
{

	my $in = `/sbin/ifconfig $_[0] | grep RX | grep bytes|cut -d" " -f14`;
	my $out = `/sbin/ifconfig $_[0] | grep TX | grep bytes|cut -d" " -f14`;
	chomp($in);
	chomp($out);

	print "$_[0] traffic in, out: $in, $out\n";
	if (! -e "$rrd/$_[0].rrd")
	{
		print "creating rrd database for $_[0] interface...\n";
		RRDs::create "$rrd/$_[0].rrd",
			"-s", "300",
			"DS:in:DERIVE:600:0:U",
			"DS:out:DERIVE:600:0:U",
			"RRA:AVERAGE:0.5:1:576",
			"RRA:MAX:0.5:1:576",
			"RRA:AVERAGE:0.5:6:672",
			"RRA:MAX:0.5:6:672",
			"RRA:AVERAGE:0.5:24:732",
			"RRA:MAX:0.5:24:732",
			"RRA:AVERAGE:0.5:144:1460",
			"RRA:MAX:0.5:144:1460";
		# check for database creation error
		if ($ERROR = RRDs::error) { print "$0: unable to create $rrd/$_[0].rrd: $ERROR\n"; }
	}

	# insert values into rrd
	RRDs::update "$rrd/$_[0].rrd",
		"-t", "in:out",
		"N:$in:$out";
	if ($ERROR = RRDs::error) { print "$0: unable to insert data into $rrd/$_[0].rrd: $ERROR\n"; }
	&CreateGraph($_[0], "day", $_[1]);
	&CreateGraph($_[0], "week", $_[1]);
	&CreateGraph($_[0], "month", $_[1]); 
	&CreateGraph($_[0], "year", $_[1]);
}

sub CreateGraph
{
	RRDs::graph "$img/$_[0]-$_[1].png",
		"-s -1$_[1]",
		"-t traffic on $_[0] :: $_[2]",
		"--lazy",
		"-h", "80", "-w", "600",
		"-l 0",
		"-a", "PNG",
		"-v bytes/sec",
		"--slope-mode",
		"--color", "BACK#ffffff",
		"--color", "CANVAS#ffffff",
		"--font", "LEGEND:7",
		"DEF:in=$rrd/$_[0].rrd:in:AVERAGE",
		"DEF:maxin=$rrd/$_[0].rrd:in:MAX",
		"DEF:out=$rrd/$_[0].rrd:out:AVERAGE",
		"DEF:maxout=$rrd/$_[0].rrd:out:MAX",
		"CDEF:out_neg=out,-1,*",
		"CDEF:maxout_neg=maxout,-1,*",
		"AREA:in#32CD32:Incoming",
		"LINE1:maxin#336600",
		"GPRINT:in:MAX:  Max\\: %6.1lf %s",
		"GPRINT:in:AVERAGE: Avg\\: %6.1lf %S",
		"GPRINT:in:LAST: Current\\: %6.1lf %SBytes/sec\\n",
		"AREA:out_neg#4169E1:Outgoing",
		"LINE1:maxout_neg#0033CC",
		"GPRINT:maxout:MAX:  Max\\: %6.1lf %S",
		"GPRINT:out:AVERAGE: Avg\\: %6.1lf %S",
		"GPRINT:out:LAST: Current\\: %6.1lf %SBytes/sec\\n",
		"HRULE:0#000000";
	if ($ERROR = RRDs::error) { print "$0: unable to generate $_[0] graph: $ERROR\n"; }

EOF
chmod a+x /var/www/html/net.pl
echo "${OK}"
}

function index.pl() {
echo -ne "Writing: /var/www/html/index.pl ... "
cat >/var/www/html/index.pl<<'EOF'
#!/usr/bin/perl
my @graphs;
my ($name, $descr);
push (@graphs, "venet0");
my $svrname = $ENV{'SERVER_NAME'};
my @values = split(/&/, $ENV{'QUERY_STRING'});
foreach my $i (@values) {
	($varname, $mydata) = split(/=/, $i);
	if ($varname eq 'trend') { $name = $mydata; }
}

if ($name eq '') { $descr = "summary"; } else { $descr = "$name"; }

print "Content-type: text/html;\n\n";
print <<END
<html>
<head>
  <TITLE>$svrname network traffic :: $descr</TITLE>
  <META HTTP-EQUIV="Refresh" CONTENT="600">
  <META HTTP-EQUIV="Cache-Control" content="no-cache">
  <META HTTP-EQUIV="Pragma" CONTENT="no-cache">
  <style>
	body { topMargin: 5; align: center; background: #000; color: #fefefe; font-family: Tahoma, Arial, Helvetica, Sans-Serif; font-size: 0.900em; font-color: #242424; }
	a { color: #ffa200; text-decoration: none; }
	a:hover { text-decoration: underline bold; color: #242424; }
	table { margin: auto; width: 70%; border-collapse: separate; border:solid white 1px; border-radius:9px; -moz-border-radius:9px; padding-left: 10px; padding-right: 10px; background: #242424; border: 1px solid #fff; white-space: pre-line; }
	td.main { color: #fff; background: #242424; font-size: 0.900em; padding-top: 3px; padding-bottom: 3px; white-space: pre-line; }
	td.main a { color:#ffa200; font-size: 0.900em; }
	td.main a:hover { background: #242424; color: #fff; font-weight: bold; }
	td { background: #242424; color: #fff; }
	tr.main td { padding-top: 2px; padding-bottom: 2px; vertical-align: top; padding-left: 10px; padding-right: 10px; white-space: pre-line; }
	pre { font-family: monospace; width: 100%; border: 1px dashed #454545; !important; }
	p { text-align: center; }

  </style>
</head>

<a href="javascript:history.go(-1)"><span class='header'>$svrname $type $descr</span></a>
<br><br>
END
;

if ($name eq '') {
	print "Daily Graphs (5 minute averages and maximums)";
	print "<br>";
	foreach $graph (@graphs) {
		print "<a href='?trend=cpu'><img src='cpu-day.png' border='1'></a><br><br>";
		print "<a href='?trend=mem'><img src='mem-day.png' border='1'></a><br><br>";
		print "<a href='?trend=$graph'><img src='$graph-day.png' border='1'></a><br><br>";
		print "<br>";
	}
} elsif ($name eq 'memory') {
print <<END
        Daily Graph (5 minute averages and maximums)<br>
        <img src='$name-day.png'><br>
        Weekly Graph (30 minute averages and maximums)<br>
        <img src='$name-week.png'><br>
        Monthly Graph (2 hour averages and maximums)<br>
        <img src='$name-month.png'><br>
        Yearly Graph (12 hour averages and maximums)<br>
        <img src='$name-year.png'>
END
;
} elsif ($name eq 'cpu') {
print <<END
	Daily Graph (5 minute averages and maximums)<br>
	<img src='$name-day.png'><br>
	Weekly Graph (30 minute averages and maximums)<br>
	<img src='$name-week.png'><br>
	Monthly Graph (2 hour averages and maximums)<br>
	<img src='$name-month.png'><br>
	Yearly Graph (12 hour averages and maximums)<br>
	<img src='$name-year.png'>
END
;
} else {
print <<END
	Daily Graph (5 minute averages and maximums)<br>
	<img src='$name-day.png'><br>
	Weekly Graph (30 minute averages and maximums)<br>
	<img src='$name-week.png'><br>
	Monthly Graph (2 hour averages and maximums)<br>
	<img src='$name-month.png'><br>
	Yearly Graph (12 hour averages and maximums)<br>
	<img src='$name-year.png'>
END
;
}

print <<END
<br><br>
</body>
</html>
END
;

EOF
chmod a+x /var/www/html/index.pl
echo "${OK}"
}

function config() {
echo -ne "Configuration: init.sh, crontab, system binaries, graph.conf, .htaccess ... "
mkdir -p /var/lib/rrd
mkdir -p /var/www/html
cat >/var/www/html/init<<'EOL'
/var/www/html/net.pl >/dev/null 2>&1
/var/www/html/cpu.pl >/dev/null 2>&1
/var/www/html/mem.pl >/dev/null 2>&1
EOL
apt -y install rrdtool librrdp-perl apache2 libapache2-mod-perl2 librrd8 librrds-perl php-rrd librrdtool-oo-perl >/dev/null 2>&1
cd /var/www/html
cat >.htaccess<<'CGI'
DirectoryIndex index.html index.cgi index.pl
AddHandler cgi-script .cgi
AddHandler cgi-script .pl
Options +ExecCGI
CGI
(crontab -l 2>/dev/null; echo "*/5 * * * * /var/www/html/init >/dev/null 2>&1") | crontab -
cat >>/etc/apache2/sites-enabled/000-default.conf<<'CNF'
Alias /system /var/www/html/
<VirtualHost *:80>
        ServerName system.justla.me
        DocumentRoot "/var/www/html"
        <Directory "/var/www/html/">
                Options +FollowSymLinks +ExecCGI
                AllowOverride All AuthConfig
                Order allow,deny
                Allow from all
        </Directory>
</VirtualHost>
CNF
rm /var/www/html/index.html
echo "${OK}"
}

function finishup() {
	OLDIFACE=$(grep 'virtual network' net.pl)
	INTERFACES=$(netstat -i|grep -Ev "^Iface|^Kernel|^lo"|cut -d' ' -f1)
	echo -e "System Interfaces:\n${INTERFACES}"
	echo "Currently Graphing: ${OLDIFACE}"
	read -p "What interface will you be Graphing? " answer
	sed -i 's/wlp3s0/'"$answer"'/' net.pl
}

OK=$(echo -e "[ \e[0;32mDONE\e[00m ]")
config
net.pl
mem.pl
cpu.pl
index.pl
finishup