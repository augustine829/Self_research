#!/usr/bin/perl

#Setup and print Version Number for Event Log Parser
$VersionNumber = "v03.06";
$VersionDate = "Oct. 26, 2015";
$VersionNumberString = "EventLogParser: $VersionNumber - Modified on: $VersionDate";
print $VersionNumberString;
print "\r\n";

#Start Main Program
    use File::Basename;
    # DEBUG FLAGS (0 = disabled, 1 = enabled)
    $print_got_here = 0;
    $print_event_block = 0;
    $FATAL_PLATFORM_START_SECS = 120;

    # Process each file in the command line (wildcards are acceptable)
    foreach (@ARGV){
        # Open the current Event Log input file to be parsed
        open(INFILE, "$_") || die("Couldn't open input file: $_");
        open(PRE_PARSE_FILE, "$_") || die("Couldn't open input file: $_");

        my $filename = "$_";

        # Get rid of ".txt" if it exists at the end of the file name
        my $htmcsvfilename = $filename;
        $htmcsvfilename =~ s/\.txt$//i;

        # Get the base file name and directory
        $base = basename($htmcsvfilename);
        $dir = dirname($htmcsvfilename);

        # Prepend file name with "parsed_" and append .htm to end
        my $htmfilename = $dir . '/' . 'parsed_' . $base . '.htm';

        # Prepend file name with "parsed_" and append .csv to end
        my $csvfilename = $dir . '/' . 'parsed_' . $base . '.csv';

        # Open up our two output files (.htm, and .csv)
        open MYHTMFILE, ">", $htmfilename || die("Couldn't open output file: $htmfilename");
        open MYCSVFILE, ">", $csvfilename || die("Couldn't open output file: $csvfilename");

        print MYHTMFILE "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\">";
        print MYHTMFILE "<html>";
        print MYHTMFILE "<head>";
        print MYHTMFILE "<META http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">";
        print MYHTMFILE "</head>";

        print MYHTMFILE "<h2 align=\"center\">";
        print MYHTMFILE "<strong>Event Log Parser ($VersionNumber)</strong>";
        print MYHTMFILE "</h2>";

        # Print the current event file name being processed and header
        print MYHTMFILE "<h3 align=\"left\">";
        print MYHTMFILE "<strong>File: $_</strong>";
        print MYHTMFILE "</h3>";

        print MYHTMFILE "<h4 align=\"left\">";
        print MYHTMFILE "<strong>Parsed Events</strong>";
        print MYHTMFILE "</h4>";

        # Clear final summary information
        # Fatal Event Counter (reboot and non reboot by Process) to be used in final summary
        $process_fatal_counter_summary = 0;

        # Non Fatal Event Counter (by Reason) to be used in final summary
        $reason_non_fatal_counter_summary = 0;

        # Arrays for fatal with reboot and fatal without reboot event Process Names to be used in final summary
        undef(%process_fatal_reboot_array_summary);
        undef(%process_fatal_no_reboot_array_summary);

        # Array for non fatal event Reasons to be used in final summary
        undef(%reason_non_fatal_array_summary);

        # Array reflecting which eventlog entries are Platform Fatal Event entries
        undef(%fatal_platform_reboot_array);

        # Array reflecting which eventlog entries should be skipped
        undef(%event_entry_skip_array);

        # Call multi event variable initialization
        reset_multi_event_vars();

        undef(%event_block);
        undef(%all_keys);
        $on_a_line_inside_event_block = 0;

        # Array for fatal event (reboot and non reboot) Process Names that are used in event table display. It gets reset for each new input file.
        $process_fatal_reboot_counter = 0;
        $process_fatal_no_reboot_counter = 0;
        undef(%process_fatal_reboot_array);
        undef(%process_fatal_no_reboot_array);

        # Array for Non fatal event reasons that are used in event table display.  It gets reset for each new input file.
        $reason_non_fatal_counter = 0;
        undef(%reason_non_fatal_array);

        # Create my main event table class template to be used below for Event Log Entries
        print MYHTMFILE "<style type=\"text/css\">";
        print MYHTMFILE "table.myMainEventTable {border-collapse:collapse; font-family: sans-serif; font-size:12px;}";
        print MYHTMFILE "table.myMainEventTable td, table.myMainEventTable th";
        print MYHTMFILE "{border:1px solid black; padding:5px;}";
        print MYHTMFILE "</style>";
        print MYHTMFILE "<body>";

        # Create main event log table, and print its header
        print MYHTMFILE "<table class = \"myMainEventTable\">";
        print MYHTMFILE "<tr>";
        print MYHTMFILE "<th> TimeStamp </th>";
        print MYHTMFILE "<th> Process </th>";
        print MYHTMFILE "<th> Fatal/Non Fatal </th>";
        print MYHTMFILE "<th> Reason </th>";
        print MYHTMFILE "<th> Backtrace </th>";
        print MYHTMFILE "<th> Epilog </th>";
        print MYHTMFILE "<th> Branch </th>";
        print MYHTMFILE "</tr>";

        if ($print_event_block) {
            print MYHTMFILE "* Processing event file line by line....";
            print MYHTMFILE "<br/><br/>";
        }

        # Loop through and pre parse all lines in the eventlog file creating the fatal_platform_reboot_array and event_entry_skip_array
        $PreParse = 1;
        $CurrentEventEntryNumber = 0;
        $CurrentFatalEventEntryNumber = 0;
        $EntryNumberToGoBackTo = 0;
        $RestartFromStartOfParseFile = 1;

        # Check if we need to restart from the beginning (1st entry) of the file
        while ($RestartFromStartOfParseFile) {
            $RestartFromStartOfParseFile = 0;
            # Get the next line of the file (could be first line if file was closed and then opened just prior)
            while ($line = <PRE_PARSE_FILE>) {
                if ($line =~ /\s*([^\:\=]+)[\:\=]/i) {
                    $all_keys{$1} = $1;
                }

                # Check if we are currently inside the actual event block processing its lines
                if ($on_a_line_inside_event_block) {
                    process_one_line_of_event_block();

                    if ($line =~ /^\s*End Event/i) {
                        # Check if we processed the complete event block and need to got back to a certain event number.
                        if ($RestartFromStartOfParseFile != 0) {
                            close(PRE_PARSE_FILE);
                            open(PRE_PARSE_FILE, "$_") || die("Couldn't open pre parse file: $_");
                            undef(%all_keys);
                            $on_a_line_inside_event_block = 0;
                            break;
                        }
                    }
                }

                # Check if we made it to the first line of an event block
                elsif ($line =~ /^\s*Event Index\:\s*(\d+)/i) {
                    $on_a_line_inside_event_block = 1;

                    # initialize some fields that were added after parser has been fielded
                    initialization_new_fields_backwards_compatibility();

                    # Print debug information
                    if ($print_got_here) {
                        print MYHTMFILE "* DEBUG: Reached EVENT BLOCK START...";
                        print MYHTMFILE "<br/><br/>";
                    }
                    $event_block{"EVENT_INDEX"} = $1;
                }
            } # while ($line = <PRE_PARSE_FILE>)
        } # while (RestartFromStartOfParseFile)

        # Loop through all lines in the eventlog file
        $PreParse = 0;
        $CurrentEventEntryNumber = 0;

        # Get the next line of the file (could be first line if file was opened just prior)
        while ($line = <INFILE>) {
            if ($line =~ /\s*([^\:\=]+)[\:\=]/i) {
                $all_keys{$1} = $1;
            }

            # Check if we are currently inside the actual event block processing its lines
            if ($on_a_line_inside_event_block) {
                process_one_line_of_event_block();
            }

            # Check if we made it to the first line of an event block
            elsif ($line =~ /^\s*Event Index\:\s*(\d+)/i) {
                $on_a_line_inside_event_block = 1;

                # initialize some fields that were added after parser has been fielded
                initialization_new_fields_backwards_compatibility();

                # Print debug information
                if ($print_got_here) {
                    print MYHTMFILE "* DEBUG: Reached EVENT BLOCK START...";
                    print MYHTMFILE "<br/><br/>";
                }
                $event_block{"EVENT_INDEX"} = $1;
            }
        } # while ($line = <INFILE>)

        # check if we are ending the eventlog with a stored fatal event.  If so, print it out.
        if ($fatal_event_seen ne "N/A") {
          if ($print_got_here) {
              print MYHTMFILE "* DEBUG: Ending Log With a Fatal Event, so print out fatal event";
              print MYHTMFILE "<br/><br/>";
          }

          # print the fatal event data using saved off fatal variables
          print_previous_fatal_reboot_event_data();
        }
        # check if we are ending the eventlog with a reboot type requested.  If so, print it out.
        elsif ($reboot_type_request_seen ne "N/A") {
          if ($print_got_here) {
              print MYHTMFILE "* DEBUG: Ending Log With a Reboot Type Requested, so print out RTR";
              print MYHTMFILE "<br/><br/>";
          }

          # print the reboot type requested data using saved off RTR variables
          print_previous_reboot_type_requested_data();
        }

        if (($process_fatal_reboot_counter == 0) && ($reason_non_fatal_counter == 0) && ($process_fatal_no_reboot_counter == 0)) {
            print MYHTMFILE "<tr>";
            print MYHTMFILE "<td><font color = black>\"N/A\"</font></td>";
            print MYHTMFILE "<td><font color = black>\"N/A\"</font></td>";
            print MYHTMFILE "<td><font color = black>\"N/A\"</font></td>";
            print MYHTMFILE "<td><font color = black>\"N/A\"</font></td>";
            print MYHTMFILE "<td><font color = black>\"N/A\"</font></td>";
            print MYHTMFILE "<td><font color = black>\"N/A\"</font></td>";
            print MYHTMFILE "<td><font color = black>\"N/A\"</font></td>";
            print MYCSVFILE "$_";
            print MYCSVFILE ",N/A, N/A, N/A, N/A, N/A, N/A, N/A\n";
            print MYHTMFILE "</tr>";
        }
        else {
            $process_fatal_counter_summary += $process_fatal_reboot_counter;
            $process_fatal_counter_summary += $process_fatal_no_reboot_counter;
            $reason_non_fatal_counter_summary += $reason_non_fatal_counter;
        }

        # End the main event log table since we are done with all events in file
        print MYHTMFILE "</table>";

        # Close current input file
        close(INFILE);

        # Print Summary table for current input file
        print_summary_tables_data();

        print MYHTMFILE "</body>";
        print MYHTMFILE "</html>";

        # Close output files
        close (MYCSVFILE);
        close (MYHTMFILE);
    } # foreach (@ARGV)

#End Main Program


sub initialization_new_fields_backwards_compatibility() {
    # Will only have an effect if the eventlog file event does not have this field or
    # this field has a possibility of being empty.
    $event_block{"EpiLogFile"} = "N/A";
    $event_block{"RebootTypeRequested"} = "N/A";
    $event_block{"ApplicationRestartReason"} = "N/A";
    $event_block{"BacktraceFile"} = "N/A";
}


# Save data to be used when a fatal event occurs, followed by: a Valid Startup Type, an Application Stopped, or neither (file end reached).
sub save_previous_fatal_event_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to save_previous_fatal_event_data";
        print MYHTMFILE "<br/><br/>";
    }

    # Save off all fatal event data to be printed after a valid Startup Type is processed
    $fatal_process = $event_block{"ProcessName"};
    $fatal_branch = $branch;
    $fatal_backtrace = $event_block{"BacktraceFile"};
    $fatal_localtimeUTC = $localtimeUTC;
    $fatal_epilog = $event_block{"EpiLogFile"};
    $fatal_event_seen = $event_seen_first;
}


sub save_previous_reboot_type_request_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to save_previous_reboot_type_request_data";
        print MYHTMFILE "<br/><br/>";
    }

    # Save off all reboot type request data to be printed after a valid Startup Type is processed
    $reboot_type_request_process = $event_block{"ProcessName"};
    $reboot_type_request_branch = $branch;
    $reboot_type_request_backtrace = $event_block{"BacktraceFile"};
    $reboot_type_request_localtimeUTC = $localtimeUTC;
    $reboot_type_request_epilog = $event_block{"EpiLogFile"};
    $reboot_type_request_requested_type = $event_block{"RebootTypeRequested"};
    $reboot_type_request_peer_process_name = $event_block{"PeerProcessName"};
    $reboot_type_request_seen = $event_seen_first;
}


# non fatals that don't reboot the box have a green background
sub print_non_fatal_no_reboot_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_non_fatal_no_reboot_data";
        print MYHTMFILE "<br/><br/>";
    }

    print MYHTMFILE "<tr>";
    print MYCSVFILE "$_";
    print MYHTMFILE "<td><font color = black>$localtimeUTC</font></td>";
    print MYCSVFILE ",$localtimeUTC";
    print MYHTMFILE "<td><font color = black>$process_name</font></td>";
    print MYCSVFILE ",$process_name";

    print MYHTMFILE "<td bgcolor=#00ff00><font color=black>";
    print MYHTMFILE "Non Fatal";
    print MYCSVFILE ",Non Fatal";
    print MYHTMFILE "</font></td>";

    if ($print_param eq "ApplicationRestart") {
        print MYHTMFILE "<td bgcolor=#00ff00><font color=black>";
        print MYHTMFILE "App Restart - $event_block{\"ApplicationRestartReason\"}";
        print MYCSVFILE ",App Restart - $event_block{\"ApplicationRestartReason\"}";
        print MYHTMFILE "</font></td>";
    }
    elsif (($print_param eq "StartupType") ||
           ($print_param eq "ReloadStartPage")) {
        print MYHTMFILE "<td bgcolor=#00ff00><font color=black>";
        print MYHTMFILE "$reason";
        print MYCSVFILE ",$reason";
        print MYHTMFILE "</font></td>";
    }
    else {
        print MYHTMFILE "<td bgcolor=#00ff00><font color=black>";
        print MYHTMFILE "N/A";
        print MYCSVFILE "N/A";
        print MYHTMFILE "</font></td>";
    }
    print MYHTMFILE "<td><font color = black>$backtrace</font></td>";
    print MYCSVFILE ",$backtrace";
    print MYHTMFILE "<td><font color = black>$epilog</font></td>";
    print MYCSVFILE ",$epilog";
    print MYHTMFILE "<td><font color = black>$branch</font></td>";
    print MYCSVFILE ",$branch\n";
    print MYHTMFILE "</tr>";

    # Take register information, starting with "RST=", out before adding into summary array.
    $reasontemp = $reason;
    $reasontemp =~ s/(.*) RST=.*/$1/;
    $reason_non_fatal_array{$reasontemp}++;
    $reason_non_fatal_array_summary{$reasontemp}++;
    $reason_non_fatal_counter++;
}


# platform fatals that don't reboot the box have a yellow background
sub print_platform_fatal_no_reboot_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_platform_fatal_no_reboot_data";
        print MYHTMFILE "<br/><br/>";
    }

    print MYHTMFILE "<tr>";
    print MYCSVFILE "$_";
    print MYHTMFILE "<td><font color = black>$localtimeUTC</font></td>";
    print MYCSVFILE ",$localtimeUTC";
    print MYHTMFILE "<td><font color = black>$process_name</font></td>";
    print MYCSVFILE ",$process_name";

    print MYHTMFILE "<td bgcolor=yellow><font color=black>";
    print MYHTMFILE "Fatal";
    print MYCSVFILE ",Fatal";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td bgcolor=yellow><font color=black>";
    print MYHTMFILE "$reason";
    print MYCSVFILE ",$reason";
    print MYHTMFILE "</font></td>";

    print MYHTMFILE "<td><font color = black>$backtrace</font></td>";
    print MYCSVFILE ",$backtrace";
    print MYHTMFILE "<td><font color = black>$epilog</font></td>";
    print MYCSVFILE ",$epilog";
    print MYHTMFILE "<td><font color = black>$branch</font></td>";
    print MYCSVFILE ",$branch\n";
    print MYHTMFILE "</tr>";

    $process_fatal_no_reboot_array{$process_name}++;
    $process_fatal_no_reboot_array_summary{$process_name}++;
    $process_fatal_no_reboot_counter++;
}


# platform fatals that reboot the box have a red background
sub print_platform_fatal_reboot_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_platform_fatal_reboot_data";
        print MYHTMFILE "<br/><br/>";
    }

    print MYHTMFILE "<tr>";
    print MYCSVFILE "$_";
    print MYHTMFILE "<td><font color = black>$localtimeUTC</font></td>";
    print MYCSVFILE ",$localtimeUTC";
    print MYHTMFILE "<td><font color = black>$process_name</font></td>";
    print MYCSVFILE ",$process_name";

    print MYHTMFILE "<td bgcolor=red><font color=black>";
    print MYHTMFILE "Fatal";
    print MYCSVFILE ",Fatal";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td bgcolor=red><font color=black>";
    print MYHTMFILE "$reason";
    print MYCSVFILE ",$reason";
    print MYHTMFILE "</font></td>";

    print MYHTMFILE "<td><font color = black>$backtrace</font></td>";
    print MYCSVFILE ",$backtrace";
    print MYHTMFILE "<td><font color = black>$epilog</font></td>";
    print MYCSVFILE ",$epilog";
    print MYHTMFILE "<td><font color = black>$branch</font></td>";
    print MYCSVFILE ",$branch\n";
    print MYHTMFILE "</tr>";

    $process_fatal_reboot_array{$process_name}++;
    $process_fatal_reboot_array_summary{$process_name}++;
    $process_fatal_reboot_counter++;
}


# application fatals that don't reboot the box have a yellow background
sub print_application_fatal_no_reboot_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_application_fatal_no_reboot_data";
        print MYHTMFILE "<br/><br/>";
    }

    print MYHTMFILE "<tr>";
    print MYCSVFILE "$_";
    print MYHTMFILE "<td><font color = black>$localtimeUTC</font></td>";
    print MYCSVFILE ",$localtimeUTC";
    print MYHTMFILE "<td><font color = black>$process_name</font></td>";
    print MYCSVFILE ",$process_name";
    print MYHTMFILE "<td bgcolor=yellow><font color=black>";
    print MYHTMFILE "Fatal";
    print MYCSVFILE ",Fatal";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td bgcolor=yellow><font color=black>";
    print MYHTMFILE "App Restart - $event_block{\"ApplicationRestartReason\"}";
    print MYCSVFILE ",App Restart - $event_block{\"ApplicationRestartReason\"}";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td><font color = black>$backtrace</font></td>";
    print MYCSVFILE ",$backtrace";
    print MYHTMFILE "<td><font color = black>$epilog</font></td>";
    print MYCSVFILE ",$epilog";
    print MYHTMFILE "<td><font color = black>$branch</font></td>";
    print MYCSVFILE ",$branch\n";
    print MYHTMFILE "</tr>";

    $process_fatal_no_reboot_array{$process_name}++;
    $process_fatal_no_reboot_array_summary{$process_name}++;
    $process_fatal_no_reboot_counter++;
}


# Print the data that has been saved off when a previous fatal reboot event occurred
sub print_previous_fatal_reboot_event_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_previous_fatal_reboot_event_data";
        print MYHTMFILE "<br/><br/>";
    }

    # Print the previously saved fatal event information (Always Platform Restart)
    print MYHTMFILE "<tr>";
    print MYCSVFILE "$_";
    print MYHTMFILE "<td><font color = black>$fatal_localtimeUTC</font></td>";
    print MYCSVFILE ",$fatal_localtimeUTC";
    print MYHTMFILE "<td><font color = black>$fatal_process</font></td>";
    print MYCSVFILE ",$fatal_process";
    print MYHTMFILE "<td bgcolor=red><font color=black>";
    print MYHTMFILE "Fatal";
    print MYCSVFILE ",Fatal";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td bgcolor=red><font color=black>";
    print MYHTMFILE "Platform Reset";
    print MYCSVFILE ",Platform Reset";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td><font color = black>$fatal_backtrace</font></td>";
    print MYCSVFILE ",$fatal_backtrace";
    print MYHTMFILE "<td><font color = black>$fatal_epilog</font></td>";
    print MYCSVFILE ",$fatal_epilog";
    print MYHTMFILE "<td><font color = black>$fatal_branch</font></td>";
    print MYCSVFILE ",$fatal_branch\n";
    print MYHTMFILE "</tr>";

    $process_fatal_reboot_array{$fatal_process}++;
    $process_fatal_reboot_array_summary{$fatal_process}++;
    $process_fatal_reboot_counter++;
}


sub print_previous_reboot_type_request_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_previous_reboot_type_request_data";
        print MYHTMFILE "<br/><br/>";
    }

    print MYHTMFILE "<tr>";
    print MYCSVFILE "$_";
    print MYHTMFILE "<td><font color = black>$reboot_type_request_localtimeUTC</font></td>";
    print MYCSVFILE ",$reboot_type_request_localtimeUTC";
    print MYHTMFILE "<td><font color = black>$reboot_type_request_process</font></td>";
    print MYCSVFILE ",$reboot_type_request_process";
    print MYHTMFILE "<td bgcolor=#00ff00><font color=black>";
    print MYHTMFILE "Non Fatal";
    print MYCSVFILE ",Non Fatal";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td bgcolor=#00ff00><font color=black>";
    print MYHTMFILE "Reboot Type Requested: <b>$reboot_type_request_requested_type</b> by $reboot_type_request_peer_process_name";
    print MYCSVFILE ",Reboot Type Requested: $reboot_type_request_requested_type by $reboot_type_request_peer_process_name";
    print MYHTMFILE "</font></td>";
    print MYHTMFILE "<td><font color = black>$reboot_type_request_backtrace</font></td>";
    print MYCSVFILE ",$reboot_type_request_backtrace";
    print MYHTMFILE "<td><font color = black>$reboot_type_request_epilog</font></td>";
    print MYCSVFILE ",$reboot_type_request_epilog";
    print MYHTMFILE "<td><font color = black>$reboot_type_request_branch</font></td>";
    print MYCSVFILE ",$reboot_type_request_branch\n";
    print MYHTMFILE "</tr>";

    # Take register information, starting with "RST=", out before adding into summary array.
    $reboot_type_request_requested_type_temp = $reboot_type_request_requested_type;
    $reboot_type_request_requested_type_temp =~ s/(.*) RST=.*/$1/;
    $reason_non_fatal_array{$reboot_type_request_requested_type_temp}++;
    $reason_non_fatal_array_summary{$reboot_type_request_requested_type_temp}++;
    $reason_non_fatal_counter++;
}


sub print_event_table_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_event_table_data, reason is: $reason";
        print MYHTMFILE "<br/><br/>";
    }

    # Check if we are in a special case where we got a fatal event (streamer crash), but the box does not reboot.
    if ($reason eq "Streamer Crash with no reboot") {
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Fatal Event crash with no reboot";
            print MYHTMFILE "<br/><br/>";
        }

        # Print the platform fatal information structure
        print_platform_fatal_no_reboot_data();
    }
    # Check if we are in a special case where we got a fatal event, but the box does not reboot.
    elsif ($reason eq "Fatal Event with no reboot") {
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Fatal Event crash with no reboot";
            print MYHTMFILE "<br/><br/>";
        }

        # Print the platform fatal information structure
        print_platform_fatal_no_reboot_data();
    }
    # Check if we had a fatal application restart and we haven't already seen a fatal event nor Reboot Type Request, nor a ApplicationRestartReason
    elsif (($reason =~ m/^Application Restart/ && $event_seen_first eq "N/A") &&
          ($event_block{"ApplicationRestartReason"} eq "N/A")) {
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: No reason provided.  Fatal Application Restart, Restart Reason is Application Crash";
            print MYHTMFILE "<br/><br/>";
        }

        # since no ApplicationRestartReason provided, make it a Fatal Application Crash
        $event_block{"ApplicationRestartReason"} = "Application Crash";
        $process_name = $event_block{"ApplicationName"};

        # Print the application fatal information structure
        print_application_fatal_no_reboot_data();
    }
    # Check if we had a fatal application restart and we haven't already seen a fatal event nor Reboot Type Request
    elsif (($reason =~ m/^Application Restart/ && $event_seen_first eq "N/A") &&
          ($event_block{"ApplicationRestartReason"} =~ m/^PingTimeout/) ||
          ($event_block{"ApplicationRestartReason"} =~ m/^OutOfMemory/)) {
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: reason is Fatal Application Restart, Restart Reason is Ping TO or OOM";
            print MYHTMFILE "<br/><br/>";
        }

        $process_name = $event_block{"ApplicationName"};

        # Print the application fatal information structure
        print_application_fatal_no_reboot_data();
    }
    # Check if we had a non fatal application restart and we haven't already seen a fatal event nor Reboot Type Request
    elsif (($reason =~ m/^Application Restart/ && $event_seen_first eq "N/A") &&
           ($event_block{"ApplicationRestartReason"} =~ m/^CodeUpdate/) ||
           ($event_block{"ApplicationRestartReason"} =~ m/^ExternalActor/)) {
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: reason is Non Fatal Application Restart, Restart Reason is Code Update or ExternalActor";
            print MYHTMFILE "<br/><br/>";
        }

        $process_name = $event_block{"ApplicationName"};

        # Print the non fatal information
        $print_param = "ApplicationRestart";
        print_non_fatal_no_reboot_data();
    }
    # check if the reason STARTS WITH one of the following valid Startup Types
    elsif (($reason =~ m/^Software Reset/) ||
           ($reason =~ m/^Reset Level/) ||
           ($reason =~ m/^Power On/) ||
           ($reason =~ m/^Power Failure/) ||
           ($reason =~ m/^Watchdog Timeout/) ||
           ($reason =~ m/^Software Initiated/) ||
           ($reason =~ m/^Front Panel/) ||
           ($reason =~ m/^Temperature Error/) ||
           ($reason =~ m/^Voltage Error/) ||
           ($reason =~ m/^Kernel Panic/) ||
           ($reason =~ m/^Security Master/) ||
           ($reason =~ m/^Platform Failure/)) {

        # check if we had a fatal event prior
        if ($fatal_event_seen ne "N/A") {
          # print the fatal event data using saved off fatal variables
          print_previous_fatal_reboot_event_data();
        }
        # check if we had a Reboot Type Request prior
        elsif ($reboot_type_request_seen ne "N/A") {
          # print the reboot type request data using saved off RTR variables
          print_previous_reboot_type_request_data();
        }

        # determine if Startup Type entry should be printed
        if ((($reason =~ m/^Software Initiated/) || ($reason =~ m/^Power On/)) && ($event_seen_first ne "N/A")) {
            # Skip this entry, and do not print it!
            if ($print_got_here) {
                print MYHTMFILE "* DEBUG: Startup type being skipped";
                print MYHTMFILE "<br/><br/>";
            }
        }
        elsif (($reason =~ m/^Watchdog Timeout/) ||
               ($reason =~ m/^Platform Failure/) ||
               ($reason =~ m/^Security Master/) ||
               ($reason =~ m/^Kernel Panic/)) {
            if ($print_got_here) {
                print MYHTMFILE "* DEBUG: Startup type is Fatal";
                print MYHTMFILE "<br/><br/>";
            }
            # Print the platform fatal information
            print_platform_fatal_reboot_data();
        }
        else {
            if ($print_got_here) {
                print MYHTMFILE "* DEBUG: Startup type is Non Fatal";
                print MYHTMFILE "<br/><br/>";
            }
            # Print the non fatal information
            $print_param = "StartupType";
            print_non_fatal_no_reboot_data();
        }
    }

    # clean up multi event variables since the fatal or Reboot Type Request, if one existed, was just displayed from code above
    reset_multi_event_vars();
}


sub print_summary_tables_data() {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to print_summary_tables_data";
        print MYHTMFILE "<br/><br/>";
    }

    # Print summary heading
    print MYHTMFILE "<br/><br/>";
    print MYHTMFILE "<h4 align=\"left\">";
    print MYHTMFILE "<strong>Summary (Fatal and Non Fatal Events)</strong>";
    print MYHTMFILE "</h4>";

    # Create fatal event summary table...
    print MYHTMFILE "<table align=\"left\" border=\"1\" style=\"width: 45%;\" font size=\"6\">";
    print MYHTMFILE "<tr>";
    print MYHTMFILE "<th> <font size = 2px>Process </font></th>";
    print MYHTMFILE "<th> <font size = 2px># of Fatal Events </font></th>";
    print MYHTMFILE "</tr>";

    # Fill in fatal event summary table fields
    if ($process_fatal_counter_summary != 0) {
        # Fill summary table fields for platform fatals
        foreach $key (sort(keys(%process_fatal_reboot_array_summary))) {
            print MYHTMFILE "<tr>";
            print MYHTMFILE "<td><font color=black><font size = 2px><center>";
            print MYHTMFILE "$key";
            print MYHTMFILE "</center></font></td>";
            print MYHTMFILE "<td bgcolor=red><font color=black><font size = 2px><center>";
            print MYHTMFILE "$process_fatal_reboot_array_summary{$key}";
            print MYHTMFILE "</center></font></td>";
            print MYHTMFILE "</tr>";
        }

        # Fill summary table fields for application fatals
        foreach $key (sort(keys(%process_fatal_no_reboot_array_summary))) {
            print MYHTMFILE "<tr>";
            print MYHTMFILE "<td><font color=black><font size = 2px><center>";
            print MYHTMFILE "$key";
            print MYHTMFILE "</center></font></td>";
            print MYHTMFILE "<td bgcolor=yellow><font color=black><font size = 2px><center>";
            print MYHTMFILE "$process_fatal_no_reboot_array_summary{$key}";
            print MYHTMFILE "</center></font></td>";
            print MYHTMFILE "</tr>";
        }
    }
    else {
        print MYHTMFILE "<tr>";
        print MYHTMFILE "<td><font color = black><center><font size = 2px>N/A</font></center></td>";
        print MYHTMFILE "<td><font color = black><center><font size = 2px>0</font></center></td>";
        print MYHTMFILE "</tr>";
    }

    # End fatal event summary table here
    print MYHTMFILE "</table>";

    # Create non fatal event summary table...
    print MYHTMFILE "<table align=\"right\" border=\"1\" style=\"width: 45%;\">";
    print MYHTMFILE "<tr>";
    print MYHTMFILE "<th> <font size = 2px>Reason </font></th>";
    print MYHTMFILE "<th> <font size = 2px># of Non Fatal Events </font></th>";
    print MYHTMFILE "</tr>";

    # Fill in non fatal event summary table fields
    if ($reason_non_fatal_counter_summary != 0) {
        # Fill summary table fields
        foreach $key (sort(keys(%reason_non_fatal_array_summary))) {
            print MYHTMFILE "<tr>";
            print MYHTMFILE "<td font color=black><font size = 2px><center>";
            print MYHTMFILE "$key";
            print MYHTMFILE "</center></font></td>";
            print MYHTMFILE "<td bgcolor=#00FF00><font color=black><font size = 2px><center>";
            print MYHTMFILE "$reason_non_fatal_array_summary{$key}";
            print MYHTMFILE "</center></font></td>";
            print MYHTMFILE "</tr>";
        }
    }
    else {
        print MYHTMFILE "<tr>";
        print MYHTMFILE "<td><font color = black><center><font size = 2px>N/A</font></center></td>";
        print MYHTMFILE "<td><font color = black><center><font size = 2px>0</font></center></td>";
        print MYHTMFILE "</tr>";
    }

    # End fatal event summary table here
    print MYHTMFILE "</table>";

    print MYHTMFILE "<div style=\"clear:both;\"> </div>";
}


# This subroutine will be used by the preparser
sub process_complete_event_block_preparse() {
    # Print debug information
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to process_complete_event_block_preparse";
        print MYHTMFILE "<br/><br/>";
    }

    # Increase index of our current entry being processed
    $CurrentEventEntryNumber++;

    # Clear flag
    $RestartFromStartOfParseFile = 0;

    # Skip entries until we get back to the one we want to start processing
    if ($EntryNumberToGoBackTo != 0) {
        if ($EntryNumberToGoBackTo != $CurrentEventEntryNumber) {
            return;
        }
        else {
            $EntryNumberToGoBackTo = 0;
        }
    }

    # Setup our local time based on UTC time
    $utc_timestamp = $event_block{"UtcTimeStamp"};
    if ($utc_timestamp == 0) {
        $localtimeUTC = "N/A";
    }
    else {
        $localtimeUTC = localtime($utc_timestamp);
    }

    # Reset event block flag since we are no longer in event block and then interpret collected data here for complete event block...
    $on_a_line_inside_event_block = 0;

    # We received a fatal event
    if ($event_block{"EntryType"} =~ /^fatal event/i) {
        # Print debug information
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Made it to fatal event in preparse";
            print MYHTMFILE "<br/><br/>";
        }

        # Make sure we haven't seen a Fatal Event yet, otherwise skip entry
        if ($CurrentFatalEventEntryNumber == 0) {
            $CurrentFatalEventEntryNumber = $CurrentEventEntryNumber;
            $CurrentFatalEventTime = $utc_timestamp;
            $CurrentFatalProcessName = $event_block{"ProcessName"};
        }
    }

    # We received a "stopped"
    elsif (($event_block{"EntryType"} =~ /^event/i) &&
            ($event_block{"ApplicationState"} =~ /^stopped/i)) {
        if ($CurrentFatalEventEntryNumber != 0) {
            if ($CurrentEventEntryNumber == $CurrentFatalEventEntryNumber + 1) {
                # Compare Process Name of Fatal to ApplicationName of stopped event
                if (($CurrentFatalProcessName =~ /$event_block{"ApplicationName"}/i) ||
                    ($event_block{"ApplicationName"} =~ /$CurrentFatalProcessName/i)) {

                    # Add entry to skip array because we already got a fatal for this entry
                    $event_entry_skip_array{$CurrentEventEntryNumber} = 1;

                    # Non reboot case
                    # Print debug information
                    if ($print_got_here) {
                       print MYHTMFILE "* DEBUG: Non Reboot Fatal error has been processed, via Application Stopped Event";
                        print MYHTMFILE "<br/><br/>";
                    }

                    $EntryNumberToGoBackTo = $CurrentEventEntryNumber + 1;
                    $RestartFromStartOfParseFile = 1;
                    $CurrentEventEntryNumber = 0;
                    $CurrentFatalEventEntryNumber = 0;
                }
            }
        }
    }

    # We received a "platform start"
    elsif ($event_block{"EntryType"} =~ /^platform start/i) {
        if ($CurrentFatalEventEntryNumber != 0) {
            # Print debug information
            if ($print_got_here) {
                print MYHTMFILE "* DEBUG: Made it to Platform start in preparse";
                print MYHTMFILE "<br/><br/>";
            }

            # Get the difference between when we got Fatal Event and Platform Start
            $DiffInSeconds = $utc_timestamp - $CurrentFatalEventTime;

            # Check if this entry is within 2 minutes of the Fatal Event
            if ($DiffInSeconds <= $FATAL_PLATFORM_START_SECS) {
                # Reboot case
                if ($print_got_here) {
                    print MYHTMFILE "* DEBUG: Reboot Fatal error has been processed, via Platform Start Event";
                    print MYHTMFILE "<br/><br/>";
                }

                # Set the value reflecting that Event Number Entry is a Platform Fatal Event
                $fatal_platform_reboot_array{$CurrentFatalEventEntryNumber} = 1;
                $CurrentFatalEventEntryNumber = 0;
                $CurrentFatalEventTime = 0;
            }
            else {
                # Non reboot case
                if ($print_got_here) {
                    print MYHTMFILE "* DEBUG: Non Reboot Fatal error has been processed, via Platform Start Event";
                    print MYHTMFILE "<br/><br/>";
                }
                $EntryNumberToGoBackTo = $CurrentFatalEventEntryNumber + 1;
                $RestartFromStartOfParseFile = 1;
                $CurrentEventEntryNumber = 0;
                $CurrentFatalEventEntryNumber = 0;
            }
        }
    }
}


# This subroutine will process all the information we gathered for each line in the event block
sub process_complete_event_block() {
    # Print debug information
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to process_complete_event_block";
        print MYHTMFILE "<br/><br/>";
    }

    # increase index of our current entry being processed.
    $CurrentEventEntryNumber++;

    # check skip array to see if we need to skip this entry
    if ($event_entry_skip_array{$CurrentEventEntryNumber} == 1) {
        if ($print_got_here) {
            print MYHTMFILE "* In process_complete_event_block, skipping Event Entry: $CurrentEventEntryNumber";
            print MYHTMFILE "<br/><br/>";
        }
        return;
    }

    # Setup our local time based on UTC time
    $utc_timestamp = $event_block{"UtcTimeStamp"};
    if ($utc_timestamp == 0) {
        $localtimeUTC = "N/A";
    }
    else {
        $localtimeUTC = localtime($utc_timestamp);
    }

    # Reset event block flag since we are no longer in event block and then interpret collected data here for complete event block...
    $on_a_line_inside_event_block = 0;

    # We received a Reboot Type Requested request
    if (($event_block{"EntryType"} =~ /^event/i) &&
        ($event_block{"RebootTypeRequested"} ne "N/A")) {

        # Print debug information
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Made it to Event, RebootTypeRequested";
            print MYHTMFILE "<br/><br/>";
        }
            
        # Check if any event has been seen already, and if not, Reboot Type Request has been seen, so save that info, otherwise skip entry.
        if ($event_seen_first eq "N/A") {
          $event_seen_first = "RebootTypeRequested";
          $reason = "Reboot Type Requested";

          #save Reboot Type Request data to be used once we receive a valid startup type
          save_previous_reboot_type_request_data();
        }
    }

    # We received a fatal event
    elsif ($event_block{"EntryType"} =~ /^fatal event/i) {
        # Print debug information
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Made it to fatal event";
            print MYHTMFILE "<br/><br/>";
        }

        # Setup $special_case variable
        $streamer_special_case = 0;
        if ($process_name eq "streamer") {
            $streamer_special_case = 1;
        }

        # Check if streamer special case.  i.e. streamer crash, but the box does not reboot
        if (($event_seen_first eq "N/A") && ($streamer_special_case)) {
            $reason = "Streamer Crash with no reboot";

            # Print the data for this event block, $reason must be setup prior to call
            print_event_table_data();
        }

        # Check if there is a Fatal Event special case.   i.e. crash, but the box does not reboot
        elsif (($event_seen_first eq "N/A") && ($fatal_platform_reboot_array{$CurrentEventEntryNumber} != 1)) {
            $reason = "Fatal Event with no reboot";

            if ($print_got_here) {
                print MYHTMFILE "* In process_complete_event_block, Special Case (no reboot Fatal Event) on Event Entry: $CurrentEventEntryNumber";
                print MYHTMFILE "<br/><br/>";
            }

            # Print the data for this event block, $reason must be setup prior to call
            print_event_table_data();
        }

        # Check if any event has been seen already, and if not, fatal event has been seen, so save that info., otherwise skip entry.
        elsif ($event_seen_first eq "N/A") {
            $event_seen_first = "fatal event";
            $reason = "Platform Reset";

            #save fatal event data to be used later
            save_previous_fatal_event_data();
        } 
    }

    # We received an Application State stopped
    elsif (($event_block{"EntryType"} =~ /^event/i) &&
            ($event_block{"ApplicationState"} =~ /^stopped/i)) {

        # Print debug information
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Made it to Event, Application State stopped";
            print MYHTMFILE "<br/><br/>";
        }

        # Check if any event has been seen already, and if not, we can print the Application Restart info., otherwise skip entry.
        if ($event_seen_first eq "N/A") {
          $reason = "Application Restart";

          # Print the data for this event block, $reason must be setup prior to call
          print_event_table_data();
        }
    }

    # We got a browser reload page request
    elsif (($event_block{"EntryType"} =~ /event/i) &&
           ($event_block{"Browser"} =~ /reloadstartpage/i)) {

        # Print debug information
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Made it to Event, Browser reload start page";
            print MYHTMFILE "<br/><br/>";
        }

        $reason = $event_block{"Browser"} . " - " . $event_block{"Reason"};
        $print_param = $event_block{"Browser"};
        print_non_fatal_no_reboot_data();
    }

    # If we are going to go into the print_event_table_data function, $reason must be setup prior to call
    # Entry Type contains "platform start"
    elsif ($event_block{"EntryType"} =~ /^platform start/i) {
        # Print debug information
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Made it to Platform start";
            print MYHTMFILE "<br/><br/>";
        }

        # Set reason to whatever Platform Startup Type is and print data
        $reason = $event_block{"PlatformStartupType"};

        # Print the data for this event block
        print_event_table_data();
    }
    else {
        # Print debug information
        if ($print_got_here) {
            print MYHTMFILE "* DEBUG: Made it to event block ignored";
            print MYHTMFILE "<br/><br/>";
        }
    }

    # clean up single event variables
    reset_single_event_vars();

    # Now throw away the collected event block information...
    undef(%event_block);
}


# This subroutine gathers info. for the current event block line. Data will be processed when complete event block has been processed.
sub process_one_line_of_event_block() {
    # Print debug information
    if ($print_event_block) {
        print MYHTMFILE "* $line";
        print MYHTMFILE "<br/><br/>";
    }

    # Take out carriage return in each line for .csv file building
    $line =~ s/\r//g;

    # Replace all commas in each line with ; for .csv file building
    $line =~ s/,/;/g;

    # Get what is to the left of : or = and what is to the right.  $1 is to left, $2 is to right (i.e. 1363284459)
    if ($line =~ /\s*([^\:\=]+)[\:\=]\s*(.*)$/) {
        # This is a shortcut that just collects data using the original key in the Log...
        $event_block{$1} = $2;
    }

    # Checks the current lines data for matches...
    if ($line =~ /^\s*End Event/i) {
        if ($PreParse) {
            process_complete_event_block_preparse();
        }
        else {
            process_complete_event_block();
        }
    }
    elsif ($line =~ /^\s*Entry Type\:\s*(.+)$/i) {
        $event_block{"EntryType"} = $1;
    }
    elsif ($line =~ /^\s*Build Information\:\s*(.+)$/i) {
        $event_block{"BuildInformation"} = $1;
        $line =~ m/Branch\:(\S+)/;
        $branch = $1;
    }
    elsif ($line =~ /^\s*UTC Time Stamp\:\s*(.+)$/i) {
        $event_block{"UtcTimeStamp"} = $1;
    }
    elsif ($line =~ /^\s*Platform Startup Type\:\s*(.+)$/i) {
        $event_block{"PlatformStartupType"} = $1;
    }
    elsif ($line =~ /^\s*Elapsed Time Since Platform Start\:\s*(.+)$/i) {
        $event_block{"ElapsedTimeSincePlatformStart"} = $1;
    }
    elsif ($line =~ /^\s*Process Name\:\s*(.+)$/i) {
        $event_block{"ProcessName"} = $1;
        $process_name = $1;
    }
    elsif ($line =~ /^\s*Process ID\:\s*(.+)$/i) {
        $event_block{"ProcessId"} = $1;
    }
    elsif ($line =~ /^\s*Task ID\:\s*(.+)$/i) {
        $event_block{"TaskId"} = $1;
    }
    elsif ($line =~ /^\s*IIP Content Version\:\s*(.+)$/i) {
        $event_block{"IIPContentVersion"} = $1;
    }
    elsif ($line =~ /^\s*File Name\:\s*(.+)$/i) {
        $event_block{"FileName"} = $1;
    }
    elsif ($line =~ /^\s*Line Number\:\s*(.+)$/i) {
        $event_block{"LineNumber"} = $1;
    }
    elsif ($line =~ /^\s*Backtrace File\:\s*(.+)$/i) {
        $event_block{"BacktraceFile"} = $1;
        $backtrace = $1;
    }
    elsif ($line =~ /^\s*Data Items\:\s*(.+)$/i) {
        $event_block{"DataItems"} = $1;
    }
    elsif ($line =~ /^\s*ApplicationId\=\s*(.+)$/i) {
        $event_block{"ApplicationId"} = $1;
    }
    elsif ($line =~ /^\s*ApplicationName\=\s*(.+)$/i) {
        $event_block{"ApplicationName"} = $1;
     }
    elsif ($line =~ /^\s*ApplicationState\=\s*(.+)$/i) {
        $event_block{"ApplicationState"} = $1;
    }
    elsif ($line =~ /^\s*Reason\=\s*(.+)$/i) {
        $event_block{"ApplicationRestartReason"} = $1;
    }
    elsif ($line =~ /^\s*EpiLog File\:\s*(.+)$/i) {
        $event_block{"EpiLogFile"} = $1;
        $epilog = $1;
    }
    elsif ($line =~ /^\s*PeerProcessName\:\s*(.+)$/i) {
        $event_block{"PeerProcessName"} = $1;
    }
    elsif ($line =~ /^\s*RebootTypeRequested\:\s*(.+)$/i) {
        $event_block{"RebootTypeRequested"} = $1;
    }
}


# Initialize the single event variables used for saving data (this data is only persistent for one event block)...
sub reset_single_event_vars {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to reset_single_event_vars";
        print MYHTMFILE "<br/><br/>";
    }

    $reason = "UNKNOWN";
    $backtrace = "N/A";
    $epilog = "N/A";
    $branch = "";
    $process_name = "N/A";
    $utc_timestamp = "N/A";
}


# Initialize the variables used for saving multi event data (this data could be persistent for multiple event blocks)...
sub reset_multi_event_vars {
    if ($print_got_here) {
        print MYHTMFILE "* DEBUG: Made it to reset_multi_event_vars";
        print MYHTMFILE "<br/><br/>";
    }

    $event_seen_first = "N/A";
    $reboot_type_request_seen = "N/A";
    $fatal_event_seen = "N/A";

    if ($reset_single_event_vars != 0) {
      reset_single_event_vars();
    }
}
