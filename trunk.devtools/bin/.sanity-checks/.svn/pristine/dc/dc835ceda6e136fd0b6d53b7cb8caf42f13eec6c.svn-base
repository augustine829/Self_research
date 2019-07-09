#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

my $baseurl = "http://svn.arrisi.com/skip-sanity-check_report.php";

my $checked = 0;
my %issues;
my %ignored;

my ($first, $last);

while (<>) {
    if (/^([0-9- :]{19})/) {
        $first ||= $1;
        $last = $1;
    }
    if (/Sanity check: /) {
        if (/Ignoring commit: (.*)/) {
            $ignored{$1} += 1;
        }
        elsif (/\(issues: (.*)\)/) {
            $checked += 1;
            foreach (split(/ /, $1)) {
                my ($issue, $count) = split(/:/);
                $issues{$issue} += 1;
            }
        }
    }
}

# Print header
print <<END;
Coding style report
===================
END

if (!$first) {
    print "Nothing to report.\n";
    exit 0;
}

# Count total number of commits
my $total = $checked;
foreach (values(%ignored)) {
    $total += $_;
}
my $checkedpc = $total != 0 ? int($checked / $total * 100) : 0;

# Print summary
print <<END;
A total of $total commits were done between $first - $last.
Out of these $checked ($checkedpc%) commits were checked for coding style issues.

Issues detected (percent of checked)
====================================
END

# Print issue list
foreach my $issue (sort({$issues{$b} <=> $issues{$a}} keys(%issues))) {
    my $count = $issues{$issue};
    print "$issue" . "." x (31 - length($issue)) . ": ";
    printf "%4d (", $count;
    printf "%2d%%)\n", int($count/$checked * 100);
}

# Print ignore reasons
print <<END;

Reasons for not checking commits (percent of total)
===================================================
END

foreach my $reason (sort({$ignored{$b} <=> $ignored{$a}} keys(%ignored))) {
    my $count = $ignored{$reason};
    print "$reason" . "." x (23 - length($reason)) . ": ";
    printf "%3d (", $count;
    printf "%2d%%)\n", int($count/$total * 100);
}

sub url_encode {
    my $param = shift;
    $param =~ s/ /%20/g;
    $param =~ s/:/%3A/g;
    return $param;
}

print "\nMore details\n============\n";
print "For a list of commits with SKIP_SANITY_CHECK, go to:\n";
print "$baseurl?from=" . url_encode($first) . "&to=" . url_encode($last) . "\n";
