#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';
use Time::HiRes;

# Start time to measure how long time the script takes to run
my $start = [Time::HiRes::gettimeofday()];

# Print nice error message if Regexp::Common isn't installed
if (system("perl -e 'use Regexp::Common' 2>/dev/null")) {
    print STDERR "Error: please install Regexp::Common: " .
        "su -c 'yum install perl-Regexp-Common'\n";
    # Exit 0 to not block commits due to this
    exit 0;
}
require Regexp::Common;
Regexp::Common->import();
our %RE;

my $debug = @ARGV && $ARGV[0] eq '--debug';
shift if $debug;

my $control_re = '^\s*(?:(?:else *)?if|else|for|foreach|do|while|switch|try|catch)';
my $control_text = "if/else/for/foreach/do/while/switch/try/catch";

my %error_messages = (
    "tabs" => "Using tabs instead of spaces",
    "trailing-ws" => "Trailing whitespace",
    "eol-cr" => "Carriage return at end of line",
    "79-chars" => "Line longer than 79 characters",
    "opening-brace" => "Opening brace '{' not on same line as $control_text",
    "closing-brace" => "Closing brace '}' on the same line as else/catch",
    "no-space-before-brace" => "No space between ')' and opening brace '{'",
    "no-space-after-control" => "No space after $control_text",
    "space-after-left-parenthesis" => "Space after '('",
    "space-before-right-parenthesis" => "Space before ')'",
    "comparison-with-bool-literal" => "Explicit comparison with true/false",
);

my %error_count;

sub check_line;
sub log_issues;

my $checked_lines = 0;

# Loop through every line in the diff
my ($file, $line, $errors_in_file) = ("", 0, 0);
while (<>) {
    # If the line starts with +++ it's a new file
    if (/^\+{3} ([^\t]+)/) {
        $file = $1;
        $line = 0;
        print STDERR "\n" if $errors_in_file;
        $errors_in_file = 0;
    }
    # Fetch the line number
    elsif (/^@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@/) {
        $line = $1;
    }
    # Line starting with ' ' is a context line
    elsif (/^ /) {
        $line++;
    }
    # Only check added lines
    elsif (/^\+(.*)$/) {
        $errors_in_file = check_line($file, $line, $1) || $errors_in_file;
        $checked_lines++;
        $line++;
    }
}

# Construct and report result
my $issues = " none";
my $result = 0;

if ($checked_lines == 0) {
    $issues = " nothing-added";
}

if (keys(%error_count)) {
    $issues = "";
    while (my ($error, $count) = each(%error_count)) {
        $issues .= " $error:$count";
    }
    $result = 1;

    print STDERR <<END
The coding standard that defines the above and other conventions can be read here:
http://kreatvdocs.arrisi.com/trunk/resources/programming_languages/cpp_coding_standard.html

END
}

my $elapsed = Time::HiRes::tv_interval($start);
print "Coding style check completed in $elapsed seconds (issues:$issues)\n";

exit($result);

# Executes the different coding style checks. All checks are run even if a
# previous one fails. When adding new checks, make sure that they don't produce
# false positives.
sub check_line {
    my ($file, $line, $text) = @_;
    my @errors;
    my @errors_in_incubator;

    if ($text =~ /\t/) {
        push(@errors, "tabs");
    }

    if ($text =~ /\s$/) {
        if ($text !~ /\S\r$/) {
            push(@errors, "trailing-ws");
        }

        if ($text =~ /\r$/) {
            push(@errors, "eol-cr");
        }
    }

    if (length($text) >= 80) {
        push(@errors, "79-chars");
    }

    if ($text =~ /^\s*\}\s*(else|catch)/) {
        push(@errors, "closing-brace");
    }

    if ($text =~ /\)\{/) {
        push(@errors, "no-space-before-brace");
    }

    if ($text =~ /$control_re[({]/) {
        push(@errors, "no-space-after-control");
    }

    if ($text =~ /$control_re *\( ./) {
        push(@errors, "space-after-left-parenthesis");
    }

    if ($text =~ / \) *\{/) {
        push(@errors, "space-before-right-parenthesis");
    }

    if ($text =~ /[=!]= *(true|false)|(true|false) *[=!]=/) {
        push(@errors_in_incubator, "comparison-with-bool-literal");
    }

    # Be conservative and skip lines that might contain strings or comments.
    # Also skip a bare "try" keyword since it may be the start of a try/catch
    # in an initializer list.
    if ($text !~ /"|\/\/|try\s*$/) {
        my $parens = qr/$RE{balanced}{-parens=>'()'}/;
        if ($text =~ /$control_re\s*($parens\s*)?$/) {
            push(@errors, "opening-brace");
        }
    }

    if (@errors_in_incubator) {
        log_issues(0, $file, $line, $text, @errors_in_incubator);
    }

    if (@errors) {
        log_issues(1, $file, $line, $text, @errors);
        return 1;
    }

    return 0;
}

# Prints file and line number together with all detected errors for that line
# to stderr. In debug mode also prints the line contents.
sub log_issues {
    my ($is_error, $file, $line, $text, @issues) = @_;
    my $where = "$file:$line";
    my $fh = $is_error ? *STDERR : *STDOUT;

    foreach my $issue (@issues) {
        $error_count{$issue} += 1 if $is_error;
        print $fh "$where: error: ", $error_messages{$issue}, "\n";
    }

    if ($debug) {
        print $fh "  Line: '$text'\n";
    }
}
