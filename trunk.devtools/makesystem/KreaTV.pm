# Copyright (c) 2008-2015 ARRIS Enterprises, Inc. All rights reserved.
#
# This program is confidential and proprietary to ARRIS Enterprises, Inc.
# (ARRIS), and may not be copied, reproduced, modified, disclosed to others,
# published or used, in whole or in part, without the express prior written
# permission of ARRIS.

use strict;
use warnings FATAL => 'all';

use Config;
my $pointer_size = $Config{ptrsize};

package KreaTV;

sub error {
    my $message = shift;
    my $func = shift;

    print STDERR "Error: $message\n";
    if (defined($func)) {
        &$func();
    }
    exit 1;
}

sub warning {
    my $message = shift;
    print "Warning: $message\n";
}

sub command_error {
    my $command = shift;
    my $context = shift;

    error("$command failed at @{$context}[1] line @{$context}[2]");
}

sub system {
    my $command = shift;

    if (system($command)) {
        my @context = caller;
        command_error($command, \@context);
    }
}

sub backticks {
    my $command = shift;

    if (wantarray) {
        my @output = `$command`;
        if ($?) {
            my @context = caller;
            command_error($command, \@context);
        }
        return @output;
    }
    else {
        my $output = `$command`;
        if ($?) {
            my @context = caller;
            command_error($command, \@context);
        }
        return $output;
    }
}

sub replace_in_file {
    my $file = shift;
    my $regexp = shift;
    my $replace = shift;

    my $data = backticks("cat $file");

    if (ref($replace) eq "CODE") {
        $data =~ s!$regexp!$replace->()!ge;
    }
    else {
        $data =~ s!$regexp!$replace!g;
    }

    open(FILE, "> $file");
    print FILE $data;
    close FILE;
}

sub read_file_content {
    my ($path, $encoding) = @_;

    $encoding ||= "raw";
    my @context = caller;
    open FILE, "<:$encoding", $path
        or command_error("read_file_content", \@context);
    return do { local $/; <FILE> };
}

sub write_file_content {
    my ($path, $content, $encoding) = @_;

    $encoding ||= "raw";
    my @context = caller;
    open FILE, ">:$encoding", $path
        or command_error("write_file_content", \@context);
    print FILE $content or command_error("write_file_content", \@context);
    close FILE;
}

# Perform lstat(2) with subsecond resolution timestamps. This function is
# mainly useful when the Time::HiRes module isn't available.
#
# The return value is a hash with struct stat fields (without the "st_" prefix)
# as keys; see man page stat(2).
sub lstat {
    my ($path) = @_;

    require "syscall.ph";
    die "KreaTV::lstat is only implemented for 64-bit systems, sorry"
        if $pointer_size != 8;

    my $size_of_struct_stat = 144;
    my $result = "x" x $size_of_struct_stat;
    syscall(&SYS_lstat, $path, $result) == 0 or die "$!: $path";
    my ($dev, $ino, $nlink, $mode, $uid, $gid, $_padding, $rdev, $size,
        $blksize, $blocks, $atim_s, $atim_ns, $mtim_s, $mtim_ns, $ctim_s,
        $ctim_ns) = unpack("QQQLLLLQqqqQQQQQQ", $result);
    return {
        atime => sprintf("%d.%09d", $atim_s, $atim_ns),
        blksize => $blksize,
        blocks => $blocks,
        ctime => sprintf("%d.%09d", $ctim_s, $ctim_ns),
        dev => $dev,
        gid => $gid,
        ino => $ino,
        mode => $mode,
        mtime => sprintf("%d.%09d", $mtim_s, $mtim_ns),
        nlink => $nlink,
        rdev => $rdev,
        size => $size,
        uid => $uid,
    };
}

sub require_module {
    my ($module_name, $package_name) = @_;
    unless (eval "require $module_name; $module_name->import(); 1;") {
        KreaTV::error(
            "Please install the Perl module $module_name (package name"
            . " \"$package_name\" in RPM-based distributions)");
    }
}

1;
