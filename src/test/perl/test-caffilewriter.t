#!/usr/bin/perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/", "$Bin/..", "$Bin/../../perl-LC";
use testapp;
use CAF::FileWriter;
use CAF::Object;
use Test::More tests => 25;

# El ingenioso hidalgo Don Quijote de La Mancha
use constant TEXT => <<EOF;
En un lugar de La Mancha, de cuyo nombre no quiero acordarme
no ha mucho tiempo que vivía un hidalgo de los de adarga antigua...
EOF

use constant FILENAME => "/my/test";

our %opts = ();
our $path;
our $file_changed = 1;
my ($log, $str);


my $this_app = testapp->new ($0, qw (--verbose));

sub init_test
{
    $path = "";
    %opts = ();
}

open ($log, ">", \$str);
$this_app->set_report_logfile ($log);

init_test;
my $fh = CAF::FileWriter->new (FILENAME, mode => 0600);
print $fh TEXT;
ok (*$fh->{save}, "File marked to be saved");
$fh->close();
is ($opts{contents}, TEXT, "The file has the correct contents");
is ($opts{mode}, 0600, "The file is created with the correct permissions");
ok (!*$fh->{save},  "File marked not to be saved after closing");
is ($path, FILENAME, "The correct file is opened");
init_test;
$fh = CAF::FileWriter->new (FILENAME, mode => 0400);
print $fh TEXT;
$fh = "";
is ($opts{contents}, TEXT, "The file is written when the object is destroyed");
is ($opts{mode}, 0400, "The file gets the correct permissions when the object is destroyed");
is ($path, FILENAME, "Correct path opened on object destruction");

init_test;
$fh = CAF::FileWriter->new (FILENAME);
print $fh TEXT;
$fh->cancel;
is (*$fh->{save}, 0, "File marked not to be saved");
$fh->close;
is ($path, "", "No file is opened when cancelling");
ok (!exists ($opts{contents}), "Nothing is written after cancel");
init_test;
$fh = CAF::FileWriter->new (FILENAME, mode => 0600,
			    log => $this_app);
print $fh TEXT;
is ($str, "Opening file " . FILENAME,
    "Correct log message when creating the object");
$fh->close;
is ($opts{contents}, TEXT, "Correct contents written to the logged file");
is ($path, FILENAME, "Correct file opened with log");
my $re =  ".*File " . FILENAME . " was modified"; # 
like($str, qr{$re},
     "Modified file correctly reported");
ok (!exists ($opts{LOG}), "No log information passed to LC::Check::file");
$fh = CAF::FileWriter->new (FILENAME, log => $this_app);
$fh->cancel();
like ($str, qr{Not saving file /}, "Cancel operation correctly logged");
$fh->close();
init_test;
$fh = CAF::FileWriter->open (FILENAME, log => $this_app,
			     backup => "foo",
			     mode => 0400,
			     owner => 100,
			     group => 200);
print $fh TEXT;
$fh->close();
is ($opts{backup}, "foo", "Checking options: correct backup option passed");
is ($opts{mode}, 0400, "Checking options: correct mode passed");
is ($opts{owner}, 100, "Checking options: correct owner passed");
is ($opts{group}, 200, "Checking options: correct group passed");
init_test;
$fh = CAF::FileWriter->new (FILENAME, log => $this_app);
$file_changed = 0;
$re = "File " . FILENAME . " was not modified";
$fh->close();
like($str, qr{$re},
     "Unmodified file correctly reported");

$CAF::Object::NoAction = 1;

init_test;
$fh = CAF::FileWriter->open (FILENAME, log => $this_app,
			     backup => "foo",
			     mode => 0400,
			     owner => 100,
			     group => 200);
print $fh TEXT;
is ("$fh", TEXT, "Stringify works");
like ($fh, qr(En un lugar), "Regexp also works");
$fh->close();
ok(!exists ($opts{contents}), "Nothing is written when NoAction is specified");
