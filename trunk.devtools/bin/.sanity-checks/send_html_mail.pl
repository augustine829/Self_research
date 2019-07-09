#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use MIME::Lite;

@ARGV == 3 or die("Not enough arguments");

my ($to, $from, $subject) = @ARGV;
my $body = do { local $/; <STDIN> };

my $msg = MIME::Lite->new(
    To => $to,
    From => $from,
    Subject => $subject,
    Type => 'text/html',
    Data => qq{<body><pre>$body</pre></body>}
    );
$msg->send();
