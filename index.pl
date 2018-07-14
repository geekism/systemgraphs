#!/usr/bin/perl -w
# black (black@justla.me)
# https://justla.me/

use warnings;

my @graphs;
my ($name, $descr, $type, $interface);
my $interface = 'wlp3s0';
push (@graphs, "wlp3s0");
my $svrname = "darksoul.justla.me";

my @values = split(/&/, $ENV{'QUERY_STRING'});
foreach my $i (@values) {
	($varname, $mydata) = split(/=/, $i);
	if ($varname eq 'trend') { $name = $mydata; }
}

if ($name eq '') { $type = "system"; $descr = ":: summary";
} elsif ($name eq 'cpu') { $type = "cpu"; $descr = ":: details";
} elsif ($name eq 'mem') { $type = "memory"; $descr = ":: details";
} elsif ($name eq $interface) { $type = 'network traffic :: '; $descr = 'details';
}

print "Content-type: text/html;\n\n";
print <<END
<html>
<head>
  <TITLE>$svrname $type $descr</TITLE>
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
	.header { font-size: 16pt; font-weight: 900; }
   </style>
</head>
<body>
<a href="/"><span class='header'>$svrname $type $descr</span></a>
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
