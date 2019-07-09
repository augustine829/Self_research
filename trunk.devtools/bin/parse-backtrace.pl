#!/usr/bin/perl

######################################################################################################
# Backtrace Log Parser (parse-backtrace.pl)
#
# Usage: perl parse-backtrace.pl -f {inputConfigFile} [-h|help] [-d|-debug] [-v|version]
# 
# Recommend to use launch-parse-backtrace.pl for proper formating of inputConfigFile.
# 
#
# Copyright: 2012 Motorola Mobility Inc.  All rights reserved.
#
#######################################################################################################
#######################################################################################################
# Revision History:
# 7. v4.13 - Update output title to include MOTOROLA CONFIDENTIAL
#
# 6. v4.11 - Don't display address in stack trace if no match is found in corresponding binary.
#            fix file search issue when used on linux.
# 
# 5. v4.09 - Renamed file to parse-backtrace.pl other minor updates
#
# 4. v4.07 - Slight format change for process info display, fix issues with Frame parsing 
#            when there is a token present.
# 
# 3. v4.05 - Added support for detecting RA, display process name, thread name etc.
# 
# 2. v4.03 - Cleanup and enhancements
# 
# 1. v4.01 - backtrace output parser tool for kreatv/KA based on v2.30 of legacy
#            ASTB FE parser tool
#
#######################################################################################################
#require Win32;

use File::Find;
use Data::Dumper;

#version of tool
$version = "4.13";
my $outputFileTitle = "MOTOROLA CONFIDENTIAL - Exception Log Parsing Results";

my $help = 0;
my $INPUT;
my $OUTPUT = "fe_out.htm";  #default value, can be overriden via config file [General]->outputFile

$configFile = 0;

$status = $SUCCESS;
$functionName = "";
$message = "";
$value = "";

$NOFUNCTIONMATCH = "No matching function in .text section";

$SUCCESS = 0;
$FAIL = 1;
$WARNING = 2;

$TRUE = 1;
$FALSE = 0;

#debugging control
$debug =  $FALSE;   #can be turned on via command-line flag '-d'
$debug1 = $FALSE;   #deep debugging, lots of output (not set by command-line args)
$debug2 = $FALSE;   #deep debugging, mostly for new ProvidedXmapSummaryHash logic

#set warning if multiple exception records exist that
#do not reference the same platform
$warningPlatform = $FALSE;

$fatalErrorLogString = 'FER1-'; #used as key in multiple searches

%ConfigHash                 = ();
%RelocHash                  = ();          # meta-data hash containing xmapHash for relocatable application information
%ProvidedXmapSummaryHash    = ();          # meta-data hash containing provided xmap and its text base address
$providedXmapSummaryHashCount = 0;         # global used to maintain items in hash

$IndexPlatformXmap = 0;       # Number of Ram .text lines in platform xmap
%AddressPlatformXmap=();      # Key = Xmap line number, Value = function address
%AddressEndPlatformXmap=();   # Key = Xmap line number, Value = object end address
%OffsetPlatformXmap=();       # Key = Xmap line number, Value = function offset
%GoodlinePlatformXmap=();     # Key = Xmap line number, Value = string from the platform XMAP file              
                              # Number of Ram .text lines in application xmap

%ObjectorAppHash=();

@ObjNamArr = qw(objName objVer textbase database bssbase);

@ProvidedXmapSummaryHashTags = qw(xmap text_start);

#html
$HeaderNum = 0;    #Number of different Headings...this auto increments for every prntHeader(lvl=1),
                   #which is for every different error type
$event_error = ""; #stores event errors as a string

$rom_start_address = 0;
$rom_end_address   = 0;
$ram_start_address = 0; #code ram base address for both monolithic xmap and codesuite TC xmap
$ram_end_address   = 0;

# new description for html output.
$newTitle           = 0;
$nmiTitleFlg        = 0;
@Zero_Array         = ();   #array for Zero register
@Cause_Array        = ();   #array for Cause register


#Globals populated from parsing the config file
@providedXmapsArray = ();
$fatalErrorLogFilename;
$platformXmapfile = "";
$solocationDir = "";
$fatalErrorLogTime = 946684800;

$lastFirmwareVersion = 0;  #used to check that same platform spans all exception records in log file

$lastFW = "";
$currentFW = "";

# other/misc globals
$prev_fname = ""; # when going through the stack avoid printing duplicates.

###--- end global variables


###--- Parse the command line, and check for
###--- existence of config file (default or user-specified one)
$status = &parseArgs( @ARGV );
if($status != $SUCCESS){
    &errorMessage($status, $functionName, $message);
}

###--- Display command-line help and dump sample input config file
if ($help) {
    #display help menu ... note program will "die" in subroutine
    &HelpMenu();
    exit;
}

###--- Display the version
&showVersion;

###--- Display the date
$date = localtime();
printf("\nStarted on $date\n");

###--- Read Configuration File(s) and build the ConfigHash
$status = &LoadConfigFile(\%ConfigHash);
if($status != $SUCCESS){
    &errorMessage($status, $functionName, $message);
}

###--- Validate the config file contents and populate global $fatalErrorLogFilename
&validateConfigFile;

if($debug) {
    #Dump the configuration file contents
    printf("\n--- Dumping the ConfigHash ...\n");
    &printHashOfHashes(\%ConfigHash);
}

###--- Populate the ProvidedXmapsArray from the ConfigHash
&fillProvidedXmapsArray(\%ConfigHash);

###--- Print summary info of config file
&printConfigSummary(\%ConfigHash);


### Print out other input/header information
printf("\n### Output summary ###\n\n");
print "output file is $OUTPUT\n\n";

###--- parse the input fatal error log just for the
###--- relocatable information at the bottom (if a codesuite build)
###--- This builds the helper structure RelocStartAddrHash and populates
###--- the global @expectedXmapsArray


###--- parse the first xmap (TC xmap for codesuite, or just the monolithic xmap
###--- in the case of a monolithic build
printf("\n--- Begin main routine ---\n\n");
&parsePlatformXmapForStartAndEndAddresses;

#open output file; delete current file if already exists
if( -e $OUTPUT) {
    unlink ($OUTPUT);
}
open OUTPUT, ">$OUTPUT" or HelpMenu("ERROR!  Could not create $OUTPUT");
print OUTPUT "<html>\n<head>\n<title>$OUTPUT</title>\n</head>\n\n<body link=blue alink=lightblue vlink=blue>\n\n";

&printCreationSummaryToOutput;

### Call the main routine.
&parseLogAndWriteToOutput();

### add HTML event error information to OUTPUT
&addHtmlEventError();
print OUTPUT "\n</body>\n</html>";
close OUTPUT;

### add HTML table of contents to OUTPUT
&addTableOfContents();

$_ = $OUTPUT;
$OUTPUT =~ s/htm/obj/g;
open OUTPUT, ">$OUTPUT" or die "ERROR! can't open $OUTPUT";

my @unique = keys(%ObjectorAppHash);

foreach (@unique) {
   print OUTPUT "$_\n";
}

print Dumper(\%ObjectorAppHash);

close OUTPUT;

printf("#--------------  END parse-backtrace.pl ------------------- \n");



################
# Sub-Routines #
################

#prints output file heading
#expects the following arguments:
#prntHeader(Text to be printed, Header Level, Link Name, Reference Name)
sub prntHeader
{
    my($text, $level, $link, $reference) = @_;

    #update Header number for all level 1's
    if ($level == 1) {
        $HeaderNum++;
        print "\n$text found, Entry Number: $HeaderNum ...\n";
    }

    #HeaderFormat added with the text will give the completed text..for example: 1 - Sample, [1 - ] being HeaderFormat
    $HeaderFormat = $HeaderNum." - ";

    #first, add reference code so we can link back to this later
    if ($reference ne "") {
        #if a $reference val is given use that for the link name, otherwise use the $text val
        print OUTPUT "<a name=\"$HeaderFormat$reference\"><\/a>";
        #add information to the toc array so it can be linked to later
        push(@toc,$HeaderFormat.$reference);
    }
    else {
        print OUTPUT "<a name=\"$HeaderFormat$text\"><\/a>";
        push(@toc,$HeaderFormat.$text);
    }

    #for level 1 headers we want to include the number ... also update headernum
    if ($level == 1) {
        $text = $HeaderFormat.$text;
    }

    #Finally, print the header text ... print it as a link if that option is specified
    if ($link eq "") {
        print OUTPUT "<p><h$level>$text<\/h$level><\/p>\n\n";
    }
    else {
        print OUTPUT "<a href=\"#$HeaderFormat$link\"><p><h$level>$text<\/h$level><\/p><\/a>\n\n";
    }
}

#prints nmi register stuff
sub prntReg
{
    my ($offset, $register, $value, $link, $reference) = @_;

    #print once (first)
    if ($offset eq "0") {
        print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
        print OUTPUT "<tr><td align=center><b>Register<\/b><\/td><td align=center><b>Value<\/b><\/td><\/tr>\n";
    }

    #if link is specified, add link code
    if ($link eq "") {
        print OUTPUT "<tr><td align=center>$register<\/td>";
    }
    else {
        print OUTPUT "<tr><td align=center><a href=\"#$HeaderNum - $link\">$register<\/a><\/td>";
    }

    #if reference is specified, add reference code...reference must made somewhere inside the row
    if ($reference ne "") {
        print OUTPUT "<td align=center><a name=\"$HeaderNum - $reference\"><\/a>$value<\/td><\/tr>\n";
        push(@toc,"$HeaderNum - $reference"); #every time a reference is made add the name to the table of contents variable
    }
    else {
        #close out the row
        print OUTPUT "<td align=center>$value<\/td><\/tr>\n";
    }

    #print once (last)
    if ($offset eq "10c") {
        print OUTPUT "<\/TABLE>\n\n";
    }
}


#finds cause register information
sub findCauseReg
{
    my ($cause_hex) = @_;

        #strip off leading 0x so hex() function works
        $cause_hex =~ s/^0x//;

        print OUTPUT "<TABLE border=0 cellspacing=3 cellpadding=3>\n";
        print OUTPUT "<tr><td><b>Value:<\/b><\/td><td>0x$cause_hex<\/td><\/tr>\n";
        print OUTPUT "<\/TABLE>\n\n";

        my $cause = hex($cause_hex);

        #exception code (bits 2-6)
        my $exc_code = ($cause & 124) >> 2;

        #put all output in a table
        print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
        print OUTPUT "<tr><td align=center><b>Exception Code<br>Value<\/b><\/td><td align=center><b>Description<\/b><\/td><\/tr>\n";

        print OUTPUT "<tr><td align=center>$exc_code<\/td><td align=center>";
        if ($exc_code==0) {
            print OUTPUT "Interrupt\n";
        }
        elsif ($exc_code==1) {
            print OUTPUT "TLB Modification exception\n";
        }
        elsif ($exc_code==2) {
            print OUTPUT "TLB exception (load or instruction fetch)\n";
        }
        elsif ($exc_code==3) {
            print OUTPUT "TLB exception (store)\n";
        }
        elsif ($exc_code==4) {
            print OUTPUT "Address Error exception (load or instruction fetch)\n";
        }
        elsif ($exc_code==5) {
            print OUTPUT "Address Error exception (store)\n";
        }
        elsif ($exc_code==6) {
            print OUTPUT "Bus Error exception (instruction fetch)\n";
        }
        elsif ($exc_code==7) {
            print OUTPUT "Bus Error exception (data reference: load or store)\n";
        }
        elsif ($exc_code==8) {
            print OUTPUT "System Call exception\n";
        }
        elsif ($exc_code==9) {
            print OUTPUT "Breakpoint exception\n";
        }
        elsif ($exc_code==10) {
            print OUTPUT "Reserved Instruction exception\n";
        }
        elsif ($exc_code==11) {
            print OUTPUT "Coprocessor Unusable exception\n";
        }
        elsif ($exc_code==12) {
            print OUTPUT "Arithmetic Overflow exception\n";
        }
        elsif ($exc_code==13) {
            print OUTPUT "Trap exception\n";
        }
        elsif ($exc_code==15) {
            print OUTPUT "Floating-point exception\n";
        }
        elsif ($exc_code==18) {
            print OUTPUT "Coprocessor 2 exception\n";
        }
        elsif ($exc_code==22) {
            print OUTPUT "MDMX exception (attempt MDMX instruction when SR(MX) not set or no CPU support)\n";
        }
        elsif ($exc_code==23) {
            print OUTPUT "Watch exception\n";
        }
        elsif ($exc_code==24) {
            print OUTPUT "Machine check exception (CPU detected error in the CPU control system)\n";
        }
        elsif ($exc_code==25) {
            print OUTPUT "Thread-related exception\n";
        }
        elsif ($exc_code==26) {
            print OUTPUT "DSP ASE instruction exception (DSP not supported or SR(MMX) isn't set correctly\n";
        }
        elsif ($exc_code==14 or $exc_code==16 or $exc_code==17 or $exc_code==19 or $exc_code==20 or $exc_code==21 or $exc_code==27 or $exc_code==28 or $exc_code==29 or $exc_code==30 or $exc_code==31) {
            print OUTPUT "Reserved\n";
        }
        else {
            print OUTPUT "ERROR, Not Found!\n";
        }

        #end table
        print OUTPUT "<\/td><\/tr>\n<\/TABLE>\n";

        #new table for the ip registers
        print OUTPUT "<br>\n<TABLE border=1 cellspacing=3 cellpadding=3>\n";

        print OUTPUT "<tr><td align=center><b>Name<\/b><\/td><td align=center><b>Value<\/b><\/td><\/tr>\n";
        $tempval = 256;
        for ($i=0;$i<=7;$i++) {
            $IP = ($cause & $tempval) >> (8 + $i);
            print OUTPUT "<tr><td align=center>IP$i<\/td><td align=center>$IP<\/td><\/tr>\n";
            $tempval = $tempval * 2;
        }

        $CE = ($cause & 805306368) >> 28;
        print OUTPUT "<tr><td align=center>CE<\/td><td align=center>$CE<\/td><\/tr>\n";

        $BD = ($cause & 2147483648) >> 31;
        print OUTPUT "<tr><td align=center>BD<\/td><td align=center>$BD<\/td><\/tr>\n";

        #end table
        print OUTPUT "<\/TABLE>\n\n";
    }


#searches the xmap text section for the function call containing the address
#prints line and offset
#note: $address_hex must be a hex number without an 0x

### TODO: pass in XMAP as argument
### Only caller is parseInputFatalErrorLogFile
#--------------------------------------------------------------------------
# findVal
#
# Arguments:
#      0   address_hex to lookup (see if it is in range/found in this file)
#      1   tag name to lookup
#      2   reference to RelocHash
#
# Searches provided xmap to look matches
#--------------------------------------------------------------------------
sub findVal
{
    $status = $SUCCESS;         #assume no match of the address will be found
    $funcName = "findVal";

    my ($address_hex, $name, $relocHashRef) = @_;
    my $fileHandle = 'zz00';
    my $filename;
    my ($startAddr, $endAddr) = 0;
    my $found = $FALSE;
    my $match=0;
    my $done = $FALSE;
    my $savedRelocHashIndex = 0;

    print ("Now Searching for $address_hex\n");

    #converts hex number to decimal
    $address_hex =~ s/0x//;
    $address = hex($address_hex);

    
    #-- open the
    #-- first xmap, namely that of the ThinClient itself. Alternatively, this
    #-- will be reached in the degenerate case where it is a monolithic build

    if( !($found) and !($address==0) ) { # check platform application xmap
        #check to see if address is valid, if not, skip search by not
        #setting the $found flag.
        #For a codesuite build, the TC xmap will always be searched before
        #application xmaps, so skip the range check for an application xmap
        if($debug2) {
            printf("$funcName: SEARCH IN PLATFORM XMAP \n");
            printf("$funcName: Ram startAddr is $ram_start_address\n");
            printf("$funcName: Ram endAddr is $ram_end_address\n");
            printf("$funcName: address is $address\n");
        }
        if ((($address >= $ram_start_address) and ($address <= $ram_end_address)) or
            (($address >= $rom_start_address) and ($address <= $rom_end_address))) {
            $found = $TRUE;
            $startPos = 0;
            $stopPos = $IndexPlatformXmap;
            $currPos = $startPos; #count current line position
            $match = 0;
            while (($match==0) and (($startPos+1)<= $stopPos) ) {
                $currPos = int(($startPos + $stopPos)*.5);
                $hexsearchaddress = sprintf("%x",$address);
                $hexaddresscurpos = sprintf("%x",$AddressPlatformXmap{$currPos});
                $hexaddresscurpos_plus = sprintf("%x",$AddressPlatformXmap{$currPos+1});

                if (($address >= $AddressPlatformXmap{$currPos}) and ($address <= $AddressEndPlatformXmap{$currPos})) {
                    $match = 1;
                    $line_prev=$GoodlinePlatformXmap{$currPos};
                    $address_prev = $AddressPlatformXmap{$currPos};
                    if($debug1) {
                        printf("$funcName: startpos is $startPos\n");
                        printf("$funcName: stoppos is $stopPos\n");
                        printf("$funcName: currpos is $currPos\n");
                        printf("$funcName:***** MATCHLINE PLATFORM *******: $line_prev|$address_prev| \n");
                    }
                }
                elsif ($address >= ($AddressPlatformXmap{$currPos+1})) {
                   if($debug2) {
                        printf("$funcName: startpos is $startPos\n");
                        printf("$funcName: stoppos is $stopPos\n");
                        printf("$funcName: currpos is $currPos\n");
                        printf("$funcName:***** NO MATCH TYPE A *******: $hexsearchaddress|$hexaddresscurpos|$hexaddresscurpos_plus \n");
                   }
                    $startPos = $currPos+1;
                }
                else {
                   if($debug2) {
                        printf("$funcName: startpos is $startPos\n");
                        printf("$funcName: stoppos is $stopPos\n");
                        printf("$funcName: currpos is $currPos\n");
                        printf("$funcName:***** NO MATCH TYPE B *******: $hexsearchaddress|$hexaddresscurpos|$hexaddresscurpos_plus \n");
                   }
                    $stopPos = $currPos;
                }
            }

        }
        # Now search through the xmap information
    }

    #only find and print info if match was successful
    if ($match==1) {

        #format line for better readability

        if($line_prev =~ /([A-Fa-f0-9]{8})-([A-Fa-f0-9]{8})[ ]+....[ ]+([A-Fa-f0-9]{8}) ..:.. [0-9]{1,10}[ ]+(.+)/)
        {
           $fstart = $1;
           $floc = $4;
           $_ = $4;
           $floc = m/(.*)[\\\/](.+)/ ? $2:$floc; 
           $fname = "Can't find $floc.text";

           #ignore match if its on the heap or stack.
           #maybe we shouldn't even add them to the hashmap....
           if($floc =~ m/(\[stack\]|\[heap\])/)
           {
              if($debug1)
              {
                 print "ignore match on [stack] or [heap]\n";
              }

              $match = 0;
              close $fileHandle;
              return($FAIL);
            }

#find -type f -iname libpcl.so | xargs /export/tools/gnutools/gcc-4.1.2-glibc-2.5-V1.1/bin/mipsel-unknown-linux-gnu-objdump -S | grep -B100 -m 1  
#c85c0:
          }
        else
        {
           print "OPS something is wrong when parsing $name type!\n";
        }

        $address_hex = sprintf("%x", $address);
        $offset = sprintf("%x", $address - $address_prev + $OffsetPlatformXmap{$currPos});
    
      $dir = $solocationDir;        
      $file_pattern = $floc;
      $file_pattern = $file_pattern.".text";

      # for shared objects use the offset as a way to search in the file
      if ($file_pattern =~ m/(\.so)/)
      {
      $search_pattern = "$offset";
      }
      # for executables (apps) , use the address directly.
      else
      {
         $search_pattern = "$address_hex";
      }

      # collect shared objects etc that we have attempted to search.
      # used to generate a file so user can generate objectdump
      $ObjectorAppHash{$floc} = $search_pattern;

      print ("added $floc to hashmap\n");
 
      print ("##NEW## address:$address_hex\n");
      $stop_searching = 0;
      $do_backtrace = 0;
      $skip_duplicates = 1;
      if (($name ne "Stack") && ($name ne "Frame")) {
	$do_backtrace = 1;
        $skip_duplicates = 0;
      }

      # if a directory is not specified then skip
      # trying to find symbolic info
      if($dir eq "")
      {
         $stop_searching = 1;
      }

      # search current and sub directory for the file pattern, when found
      # the file will be given to Wanted method so it can search for the particular
      # offset etc.
      find( { wanted => \&Wanted,  
            preprocess => \&Preprocess,
           },  $dir);


        if (($name eq "Stack") || ($name eq "Frame")){

            # only print if we found a match otherwise skip
            
            # maybe this should be configurable?? - maybe some use in displaying 
            # *.so that had a match in case it's in something other than .text section
            # of code.
            if($fname !~ m/$NOFUNCTIONMATCH/)
            {
              #print info in table form
              print OUTPUT "<tr><td align=center>0x$address_hex<\/td><td align=center>0x$offset<\/td><td align=center>$fname<\/td><td align=center>$floc<\/td><\/tr>\n";
            }
        }
        else {
            #print info in table form
            print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
            print OUTPUT "<tr><td><b>Value<\/b<\/td><td>0x$address_hex<\/td><\/tr>\n";
            print OUTPUT "<tr><td><b>Name<\/b><\/td><td>$fname<\/td><\/tr>";
            print OUTPUT "<tr><td><b>Location<\/b><\/td><td>$floc<\/td><\/tr>";
            print OUTPUT "<tr><td><b>Start<\/b><\/td><td>0x$fstart<\/td><\/tr>";
            print OUTPUT "<tr><td><b>Offset<\/b><\/td><td>0x$offset<\/td><\/tr>";
            print OUTPUT "<tr><td colspan=2>To identify the function On your development host run objdump *.so and <br>\n";
            print OUTPUT "grep the output for the calculated offset function to obtain more information <br>\n";
            print OUTPUT "example: cd /export/builds/dcx34xx/rootfs_devel/ <br>\n";
            print OUTPUT " /export/tools/gnutools/latest/bin/mipsel-unknown-linux-gnu-objdump -S lib/$floc | grep -B40 $offset  <br> <\/td><\/tr>\n ";
            print OUTPUT "<\/TABLE>\n\n";
        }

    } #end of if $match==1

    #not a valid address
    #### moved outside to separate function
    else {
        #ignore lack of match in the case of Stack info
        if($name ne "Stack" && $name ne "Frame") {
            $status = $FAIL;
        }
    }#end if-else $found
#-------------------------------------------- 6/7/07 Updated by Jing Cheng  -------------------------------------
    close $fileHandle;

    if($match) {
        $status = $SUCCESS;
    }
    return($status);
} #end findVal

#--------------------------------
# printAddressNotFoundToOutput
#
#--------------------------------
sub printAddressNotFoundToOutput
{
    $funcName = "printAddressNotFoundToOutput";
    my ($address_hex, $tagName) = @_;

    #use hex value
    $address_hex =~ s/0x//;

    print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
    print OUTPUT "<tr><td><b>Address<\/b><\/td><td><b>Function<\/b><\/td><\/tr>\n";
    print OUTPUT "<tr><td>0x$address_hex<\/td><td>Not contained in the .text section of *.so/application<\/td><\/tr>\n";
    print OUTPUT "<\/TABLE>\n\n";
}


#finds status register information
sub findStatusReg
{
    my ($statreg_hex) = @_;

    #strip off 0x if exists...this is required for the hex() function
    $statreg_hex =~ s/0x//;

    print OUTPUT "<TABLE border=0 cellspacing=3 cellpadding=3>\n";
    print OUTPUT "<tr><td><b>Value:<\/b><\/td><td>0x$statreg_hex<\/td><\/tr>\n";
    print OUTPUT "<\/TABLE>\n\n";

    print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
    print OUTPUT "<tr><td align=center><b>Field<\/b><\/td><td align=center><b>Value<\/b><\/td><td align=center><b>Description<\/b><\/td><\/tr>\n";

    #convert to decimal
    $statreg = hex($statreg_hex);

    #gets value of ie field, which is the first bit
    my $ie = $statreg & 1;
    print OUTPUT "<tr><td align=center>ie<\/td><td align=center>$ie<\/td>";
    print OUTPUT "<td>Interrupt Enable <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($ie == 0) {
        print OUTPUT "<i>disable interrupts<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>enables interrupts<\/i><\/td><\/tr>\n";
    }

    #gets value of exl field (2nd bit)
    my $exl = ($statreg & 2) >> 1;
    print OUTPUT "<tr><td align=center>exl<\/td><td align=center>$exl<\/td>";
    print OUTPUT "<td>Exception Level <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($exl == 0) {
        print OUTPUT "<i>normal<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>exception<\/i><br>\n";
    }

    #erl field stuff (4 dec is 100 bin)
    my $erl = ($statreg & 4) >> 2;
    print OUTPUT "<tr><td align=center>erl<\/td><td align=center>$erl<\/td>";
    print OUTPUT "<td>Error Level <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($erl == 0) {
        print OUTPUT "<i>normal<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>error<\/i><\/tr>\n";
    }

    #ksu stuff (24 dec is 11000 bin)
    my $ksu = ($statreg & 24) >> 3;
    print OUTPUT "<tr><td align=center>ksu<\/td><td align=center>$ksu<\/td>";
    print OUTPUT "<td>Mode bits <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($ksu == 0) {
        print OUTPUT "<i>Kernel<\/i><\/td><\/tr>\n";
    }
    elsif ($ksu == 1){
        print OUTPUT "<i>Supervisor<\/i><\/td><\/tr>\n";
    }
    elsif ($ksu == 2){
        print OUTPUT "<i>User<\/i><\/td><\/tr>\n";
    }
    else{
        print OUTPUT "<i>Error! Should not have this value!<\/i><\/td><\/tr>\n";
    }

    #ux stuff
    my $ux = ($statreg & 32) >> 5;
    print OUTPUT "<tr><td align=center>ux<\/td><td align=center>$ux<\/td>";
    print OUTPUT "<td>User Mode addressing and operations <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($ux == 0) {
        print OUTPUT "<i>32-bit<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>64-bit<\/i><\/td><\/tr>\n";
    }

    #sx stuff
    my $sx = ($statreg & 64) >> 6;
    print OUTPUT "<tr><td align=center>sx<\/td><td align=center>$sx<\/td>";
    print OUTPUT "<td>Supervisor Mode addressing and operations <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($sx == 0) {
        print OUTPUT "<i>32-bit<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>64-bit<\/i><\/td><\/tr>\n";
    }

    #kx
    my $kx = ($statreg & 128) >> 7;
    print OUTPUT "<tr><td align=center>kx<\/td><td align=center>$kx<\/td>";
    print OUTPUT "<td>Kernel Mode addressing and operations <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($kx == 0) {
        print OUTPUT "<i>32-bit<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>64-bit<\/i><\/td><\/tr>\n";
    }

    #IM7:0
    my $tempval = 256;
    for ($i=0;$i<=7;$i++) {
        my $im = ($statreg & $tempval) >> ($i + 8);
        print OUTPUT "<tr><td align=center>im$i<\/td><td align=center>$im<\/td>";
        print OUTPUT "<td>Interrupt Mask <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
        if ($im == 0) {
            print OUTPUT "<i>disabled<\/i><\/td><\/tr>\n";
        }
        else {
            print OUTPUT "<i>enabled<\/i><\/td><\/tr>\n";
        }
        $tempval = $tempval * 2;
    }


    #CU3:CU0
    $tempval = 268435456;
    for ($i=0;$i<=3;$i++) {
        my $cu = ($statreg & $tempval) >> (28 + $i);
        print OUTPUT "<tr><td align=center>cu$i<\/td><td align=center>$cu<\/td>";
        if ($cu == 0) {
            print OUTPUT "<td>CP$i <font face=symbol><\/font> <i>unusable<\/i><\/td><\/tr>\n";  #changed font to symbol to use an arrow notation
        }
        else {
            print OUTPUT "<td>CP$i <font face=symbol><\/font> <i>usable<\/i><\/td><\/tr>\n";  #changed font to symbol to use an arrow notation
        }
        $tempval = $tempval*2;
    }

    #Diagnostic Status Field
    print OUTPUT "<tr><td colspan=3 align=center>";
    print OUTPUT "<b>Diagnostic Status Field (DS)<\/b>\n";
    print OUTPUT "<\/td><\/tr>\n";

    #de
    my $de = ($statreg & 65536) >> 16;
    print OUTPUT "<tr><td align=center>de<\/td><td align=center>$de<\/td>";
    print OUTPUT "<td>Cache Parity Errors <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($de == 0) {
        print OUTPUT "<i>parity disabled<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>parity enabled<\/i><\/td><\/tr>\n";
    }

    #ce
    my $ce = ($statreg & 131072) >> 17;
    print OUTPUT "<tr><td align=center>ce<\/td><td align=center>$ce<\/td>";
    print OUTPUT "<td>Create Parity Error for Cache Diagnostics <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($ce == 0) {
        print OUTPUT "<i>not set<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>set<\/i><\/td><\/tr>\n";
    }

    #ch
    my $ch = ($statreg & 262144) >> 18;
    print OUTPUT "<tr><td align=center>ch<\/td><td align=center>$ch<\/td>";
    if ($ch == 0) {
        print OUTPUT "<td>CP0 Condition Bit<\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<td>CP0 Condition Bit\n<\/td><\/tr>\n";
    }

    #nmi
    my $nmi = ($statreg & 524288) >> 19;
    print OUTPUT "<tr><td align=center>sr<\/td><td align=center>$nmi<\/td>";
    print OUTPUT "<td>NMI <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation";
    if ($nmi == 0) {
        print OUTPUT "<i>has not occurred<\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>has occurred<\/td><\/tr>\n";
    }

    #sr
    my $sr = ($statreg & 1048576) >> 20;
    print OUTPUT "<tr><td align=center>sr<\/td><td align=center>$sr<\/td>";
    print OUTPUT "<td>Soft Reset <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation";
    if ($sr == 0) {
        print OUTPUT "<i>has not occurred<\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>has occurred<\/td><\/tr>\n";
    }

    #ts
    my $ts = ($statreg & 2097152) >> 21;
    print OUTPUT "<tr><td align=center>ts<\/td><td align=center>$ts<\/td>";
    print OUTPUT "<td>TLB Shutdown <font face=symbol><\/font> <i>";  #changed font to symbol to use an arrow notation";
    if ($ts == 0) {
        print OUTPUT "did not occur<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "did occur<\/i><br>";
    }

    #bev
    my $bev = ($statreg & 4194304) >> 22;
    print OUTPUT "<tr><td align=center>bev<\/td><td align=center>$bev<\/td>";
    print OUTPUT "<td>Location of TLB Refill and General Exception Vectors <font face=symbol><\/font> <i>";  #changed font to symbol to use an arrow notation";
    if ($bev == 0) {
        print OUTPUT "normal<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "bootstrap<\/i><\/td><\/tr>\n";
    }

    #dme
    my $dme = ($statreg & 16777216) >> 24;
    print OUTPUT "<tr><td align=center>dme<\/td><td align=center>$dme<\/td>";
    print OUTPUT "<td>Debug Mode <font face=symbol><\/font> <i>";  #changed font to symbol to use an arrow notation";
    if ($dme == 0) {
        print OUTPUT "disabled<\/i><br>";
    }
    else {
        print OUTPUT "enabled<\/i><br>";
    }

    #Re
    my $re = ($statreg & 33554432) >> 25;
    print OUTPUT "<tr><td align=center>dme<\/td><td align=center>$dme<\/td>";
    print OUTPUT "<td>Reverse Endianness <font face=symbol><\/font> <i>";  #changed font to symbol to use an arrow notation";
    if ($re == 0) {
        print OUTPUT "disabled<\/i><br>";
    }
    else {
        print OUTPUT "enabled<\/i><br>";
    }

    #fr
    my $fr = ($statreg & 67108864) >> 26;
    print OUTPUT "<tr><td align=center>fr<\/td><td align=center>$fr<\/td>";
    print OUTPUT "<td>Floating-Point Registers <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($fr == 0) {
        print OUTPUT "<i>16 registers<\/i><\/td><\/tr>\n";
    }
    else {
        print OUTPUT "<i>32 registers<\/i><\/td><\/tr>\n";
    }

    #rp
    my $rp = ($statreg & 134217728) >> 27;
    print OUTPUT "<tr><td align=center>fr<\/td><td align=center>$fr<\/td>";
    print OUTPUT "<td>Reduced Power <font face=symbol><\/font> ";  #changed font to symbol to use an arrow notation
    if ($rp == 0) {
        print OUTPUT "disabled<\/i><br>";
    }
    else {
        print OUTPUT "enabled<\/i><br>";
    }

    #end table
    print OUTPUT "<\/table>\n\n";
}



#prints help menu and then dies
#-------------------------------
# HelpMenu
#-------------------------------
sub HelpMenu
{
    my ($string) = @_;
    print "\n";
    &showVersion;
    print "\n--------------------\n";
    print "Program Instructions\n";
    print "--------------------\n";
    print "\n\"perl fe.pl -f <inputConfigFile> [-d|-debug] [-h|-help] [-v|-version]\"\n";
    print "\nOptions:\n\n";
    print "[-d|-debug]\t\t enable printing of debug information\n";
    print "-f <inputConfigFile>\t required input config file\n";
    print "[-h|-help]\t\t print this help message\n";
    print "[-v|-version]\t\t print version\n";
    print "\nexample: \"fe.pl -f input.cfg\"\n\n";
    print "OUTPUT = \"fe_out.htm\"\n";
    print "\nThis message can be displayed by typing \"fe.pl -h\"\n";

    &dumpSampleConfigFile();
}


#--------------------
# printHashOfHashes
#--------------------
sub printHashOfHashes() {

    my $refHashOfHashes = $_[0];
    my $value = 0;
    #Dump the 'hash of hashes'
    print "\nsize of outside hash:  " . keys( %$refHashOfHashes ) . ".\n";
    for my $key1 ( sort keys %$refHashOfHashes ) {
        print "\nkey1: $key1\n";

        #the value at each $key1 is itself another hash
        print "size of current inside hash:  " . keys ( %{$refHashOfHashes->{$key1}} ) . ".\n";
        for my $key2 ( sort keys %{$refHashOfHashes->{$key1}} ) {
            $value = $refHashOfHashes->{ $key1 }->{ $key2};
            printf("\tkey2: $key2 => value: $value\n");
        }
    }
}#end printHashOfHashes


#---------------------------------------------------
# LoadConfigFile
#
# Note: the config file entries get loaded into
# the ConfigHash in lexicographical (sorted) order
# based on the key values, not in the order that
# items are listed in the config file
#---------------------------------------------------
sub LoadConfigFile()
{
    my $hash    = @_[0];
    my $line;
    my $section = '';
    my $tag_info = '';
    my $tag_name = '';
    my $tag_value = '';
    my $comment = '';
    my $bContinuation = 0;  # controls continuation lines

    open(INFILE, $configFile) or die "Could not open config file ". $configFile . "\n";

    while ($line = <INFILE>) {
        $line =~ s/\s*$//;  # remove trailing whitespace

        if ($bContinuation) {
            $line =~ s/\s*\#.*$//;  # remove any trailing comment and preceding whitespace

            if ($line !~ /\|$/)  # check to see if last character is a continuation character
            {
                # This line is not itself continued...
                $bContinuation = 0;
            }

            # Add the contents of this line to the last line.
            $line =~ s/^\s*//;    # remove leading whitespace
            $line =~ s/\|$//;     # remove continuation character (if any)
            $line =~ s/\s*$//;    # remove trailing whitespace

            $hash->{$section}->{lc($tag_name)} .= "\|$line";  # append contents of this line to hash value, separated by a |

        }
        elsif (length($line) > 0) {
            if ($line =~ /^\s*#/){   # Comment
                # Ignore.
            }
            elsif ($line =~ /^\s*(\[\w+\])/){   # Section Name
                $section = lc $1;
                if($debug1) {
                    printf("section is $section\n");
                }
                #TODO: validate section names
                $hash{$section} = {};
            }
            elsif (length($section) > 0)     # Did we find a tag in a section ?
            {
                #
                # Separate the comment from the tag info.
                #
                ($tag_info, $comment) = split(/#/, $line, 2);

                # Separate the tag from the value.
                #
                ($tag_name, $tag_value) = split(/=/, $tag_info, 2);

                #
                # If there is something to process then...
                #
                if (length($tag_name) > 0) {
                    if($debug){
                        print("tag_name is $tag_name\n");
                    }
                    $tag_value =~ s/^\s*//;  # remove leading whitespace from tag value
                    if ($tag_value =~ /\|\s*$/) {
                        # This line is to be continued
                        $bContinuation = 1;
                        $tag_value =~ s/\|\s*$//;  # remove continuation character and any trailing whitespace
                    }
                    $tag_value =~ s/\s*$//; # remove trailing whitespace
                    if($debug){
                        print("tag_value is $tag_value\n");
                    }

                    $hash->{$section}->{lc($tag_name)} = $tag_value;
                }
            }
        }
    } # end: while loop
    close(INFILE);
}#end LoadConfigFile

#----------------------------------------------------------
# errorMessage
#
# Clients invoke as
#     errorStatus($status, $functionName, $value, $message)
#
#
# Arguments:
#
# All are global, and clients redefine/clobber them in
# their context
#
# $status:          $SUCCESS, $WARNING, $FAIL
# $functionName:    name of calling function/subroutine
# $message:         context-specific error message (out-of-range, bad format, etc)
#
#---------------------------------------------------------------------------------
sub errorMessage {
    local $errorStatus = $_[0];
    local $funcName = $_[1];
    local $mesg = $_[2];

    local $errorStr = "";

    local $i = 0;
    if($debug1) {
        foreach $arg (@_) {
            if($debug1) {
                printf("errorMessage: arg $i is $arg\n");
            }
            $i++;
        }
    }

    ### TODO: create an error/log file and append entries
    if($errorStatus == $FAIL) {
        $errorStr = "\nerror in function $funcName: $mesg ... exiting\n";
        #&logMessage($errorStr);
        #die $errorStr;
    }
    elsif($errorStatus == $WARNING) {
        $errorStr = "\nwarning in function $funcName: $mesg ... \n";
        #&logMessage($errorStr);
    }
    else {
        $errorStr = "\nunknown error code, exiting ... \n";
        #&logMessage($errorStr);
        #die $errorStr;
    }
}#end errorMessage


#------------------
# showVersion
#------------------
sub showVersion {
    $messageStr = "Fatal Error Log Parser $version";
    printf("\n----------------------------------------\n");
    printf("%s", $messageStr);
    printf("\n----------------------------------------\n");
} #end showVersion


#------------------------------------------------------
# parseArgs
#
#------------------------------------------------------
sub parseArgs {
    $status = $FAIL;
    $functionName = "parseCmdLine";

    while (@_) {
        $arg = shift (@_);
        if    ($arg eq '-h' || $arg eq '-help' || $arg eq '-?' || $arg eq '?') {    # help
            $help = 1;
        }
        elsif ($arg eq '-d' || $arg eq '-debug' ) {
            $debug      = $TRUE;           # flag diagnostic output
        }
        elsif ($arg eq '-version' || $arg eq '-v' ) {
            &showVersion;
            exit;
        }
        elsif ($arg eq '-f' ) {          # user-specified input xml file
            $configFile = shift (@_);
        }
        else {
            die "Invalid argument $arg; exiting ...";
        }
    }#end while
    if(!$help) {
        if( !(-e $configFile) ) {
            die"\ninput config file '$configFile' does not exist; exiting ...\n";
        }
    }#end if !$help

}#end parseArgs


#------------------------
# addHtmlEventError()
#------------------------
sub addHtmlEventError() {
    if ($event_error ne "") {
        #print event errors
        prntHeader("Event Errors", 1);
        print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=5>\n";
        print OUTPUT $event_error;
        print OUTPUT "<\/TABLE>\n\n";
    }
}


#----------------------------------
# parseLogAndWriteToOutput
#----------------------------------
sub parseLogAndWriteToOutput
{
    $funcName = "parseLogAndWriteToOutput";

    my $type = "exception";       #error type flags, default to exception
    my $stack_section;            #binary value ... 1 if we are currently parsing the stack
    my $frame_section;            #binary value ... 1 if we are currently parsing the frames
    my $firmwareVersion;
    my $new_1;    
    my $new_2;
 
    #open Error Log file
    open INPUT, $INPUT or HelpMenu("ERROR!  Could not open $INPUT");

    my $localtimeUTC = 0;

    print "\nsearching $INPUT ...\n";
    while ($line = <INPUT>) {

        my $currentFirmwareVersion = "";
        if ($line =~ m/(Version:)(^[ ]+)/) {

            $_ = $2; #everything after the match before space
            s/\s//g; #rid of whitespace
            $firmwareVersion = $currentFirmwareVersion = $_;

            #set global $warningPlatform if current and previous exception record do not reference
            #the same platform
            if($lastFirmwareVersion != 0) {
                if($currentFirmwareVersion ne $lastFirmwareVersion) {
                    $currentFW = $currentFirmwareVersion;
                    $lastFW = $lastFirmwareVersion;
                    $warningPlatform = $TRUE;
                }
            }
            $lastFirmwareVersion = $currentFirmwareVersion;
            $firmwareVersion = "KA version " . $firmwareVersion;
        }

        #exception search
        if ($type eq "exception") {

            #<F>Process 751 (diagnostics) [thread 751 (diagnostics)] received signal 11 (Segmentation fault)
            #<F>Process 751 (diagnostics) [thread 751 (diagnostics)] aborted
            #           1    2                    3                  4
            if($line =~ m/Process (\d+) \((\w+)\) \[thread \d+ \((\w+)\)\] (.*$)/)
            {

               my $processID = $1;
               my $processName = $2;
               my $task = $3;
               my $reason = $4;

               #write to output file
               prntHeader("Exception Data", 1);  #print the heading
   
               $localtimeUTC = localtime($fatalErrorLogTime);
               print OUTPUT "\n<h2>Occurred on: $localtimeUTC<\/h2>";

               #print info in table form
               print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
               print OUTPUT "<tr><td><b>PID<\/b<\/td><td>$processID<\/td><\/tr>\n";
               print OUTPUT "<tr><td><b>Status<\/b><\/td><td>$reason<\/td><\/tr>";
               print OUTPUT "<tr><td><b>Process Name<\/b<\/td><td>$processName<\/td><\/tr>\n";
               print OUTPUT "<tr><td><b>Task Name<\/b><\/td><td>$task<\/td><\/tr>";
           }

           # ContentVersion: N/A
           if($line =~ m/ContentVersion: (.*)/)
           {
                  my $contentVersion = $1;
                  print OUTPUT "<tr><td><b>Content Version<\/b><\/td><td>$contentVersion<\/td><\/tr>";
                  print OUTPUT "<\/TABLE>\n\n";
           }

            # <D>build_data.xml: BuildData: Branch:KA1.2_DEV_SigLib Date:20120516 Time:152225 Version:KA1.2-DEV-SigLib Host:ga14-ka-mgia0399-02.am.mot.com User:mgia0399
           if($line =~ m/(BuildData: )(.+)/)
           {
               my @BuildData = split("[ ]+", $2);  # tokenize using spaces and place into an array

               # split again and get the needed build info.
               my $BranchName = (split(/:/, $BuildData[0]))[1];
               my $BuildDate = (split(/:/, $BuildData[1]))[1];
               my $BuildTime = (split(/:/, $BuildData[2]))[1];
               my $BuildVersion = (split(/:/, $BuildData[3]))[1];

               prntHeader("Build Data", 2);
               #print info in table form
               print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
               print OUTPUT "<tr><td><b>Branch<\/b<\/td><td>$BranchName<\/td><\/tr>\n";
               print OUTPUT "<tr><td><b>Date<\/b><\/td><td>$BuildDate<\/td><\/tr>";
               print OUTPUT "<tr><td><b>Time<\/b><\/td><td>$BuildTime<\/td><\/tr>";
               print OUTPUT "<tr><td><b>Version<\/b><\/td><td>$BuildVersion<\/td><\/tr>";
               print OUTPUT "<\/TABLE>\n\n";
           }

            #Print General Purpose Registers. Assume they follow the "boot rom version".
           if ($line =~ m/(Register +[A-Fa-f0-9]{1,2}:)(.+)/)
           {
                # Default MIPS 32 registers
                @GprsRegistersFields = ("zero", " at", " v0", " v1", " a0", " a1", " a2", " a3", " t0", " t1", 
                                         " t2", " t3", " t4", " t5", " t6", " t7", " s0", " s1", " s2", " s3", 
                                         " s4", " s5", " s6", " s7", " t8", " t9", " k0", " k1", " gp", " sp", 
                                         " fp", " ra");
                my @GprsRegisters;
                my $gprsregs_ref = \@GprsRegisters;

                my $parsegprs = 1;

                # loop through the following and load into registers
                # e.g. 
                # <D>Register  0: 00000000 00000001 004c1be0 00000038 004c1c18 779b05bc
                # <D>Register  6: ....
                # etc
                # <D>Register 30: 004ce104 7794bd30
                do
                {
                    chomp($line);
                    if($line =~ /(Register +[A-Fa-f0-9]{1,2}:) +(.+)/)
                    {
                       @tempgprs = split("[ ]+", $2);  # tokenize using spaces and place into an array

                       push @GprsRegisters, @tempgprs;
                       if($debug1)
                       {
                         print "Regs: Added -@tempgprs-total=$#tempgprs\n";
                         print "Regs: @GprsRegisters\n";
                       } 
                    }
                    else
                    {  
                     if($debug1)
                     {
                        print "Regs: Done Parsing..";
                     }
                       $parsegprs = 0;
                    }                  

                }while ($parsegprs && ( $line = <INPUT> ));

                # we,ve got the values, let's populate the table.
                prntHeader("General Purpose Registers", 2);

                print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
                for my $i (0 .. $#GprsRegistersFields)
                {

                    print OUTPUT "<tr><td><b>@GprsRegistersFields[$i]<\/b><\/td><td>@GprsRegisters[$i]<\/td><\/tr>\n";
                    if($debug1)
                    {
                       print "-@GprsRegistersFields[$i]-@GprsRegisters[$i]\n";
                    } 
                }
                
                print OUTPUT "<\/TABLE>\n\n";
               
           }

            #Bad Virtual Address Register
           if ($line =~ m/BadVAddr: 0x([A-Fa-f0-9]{8})/) {
                prntHeader("Bad Virtual Address Register", 2);
                print OUTPUT "<TABLE border=0 cellspacing=3 cellpadding=3>\n";
                print OUTPUT "<tr><td><b>Value:<\/b><\/td><td>$1<\/td><\/tr>\n";
                print OUTPUT "<\/TABLE>\n\n";
           }

           #cause register
           if ($line =~ m/Cause: 0x([A-Fa-f0-9]{8})/) {
                #if ($line =~ m/Cause: (.+$)/) {
                    prntHeader("Cause Register", 2);
                    findCauseReg($1);
                    print OUTPUT "\n";
                #}
           }

           #status register
           if ($line =~ m/Status: 0x([A-Fa-f0-9]{8})/) {
                prntHeader("Status Register", 2);
                findStatusReg($1);
                print OUTPUT "\n";
           }

           #find EPC information
           if ($line =~ m/EPC: 0x([A-Fa-f0-9]{8})/ and $line !~ m/ErrorEPC/) {
                prntHeader("EPC Register", 2);
                print("EPC Register = $1\n");
                $status = findVal($1, "EPC", \%RelocHash);
                if($status != $SUCCESS) {
                    &printAddressNotFoundToOutput($1, "EPC");
                }
                print OUTPUT "\n";
           }

           #find Return Address
           if ($line =~ /RA: 0x([A-Fa-f0-9]{8})/) {
                prntHeader("Return Address (ra) Register", 2);
		print("Return Address (ra = $1) Register\n");
                $status = findVal($1, "Return Address", \%RelocHash);
                if($status != $SUCCESS) {
                    &printAddressNotFoundToOutput($1, "Return Address");
                }
                print OUTPUT "\n";
           }

           #e.g. Frame #11: [0x770b1038] or
           # Frame #0: /usr/lib/libbacktrace.so [0x77d86454]
           if ($line =~ m/Frame #[0-9]{1,3}:.+\[0x([A-Fa-f0-9]{5,8})\]/)
           {
                if (!$frame_section) {
                    print "Parsing frame, this may take a while ...\n";
                    #put info in table form
                    prntHeader("Frame Trace", 2);
                    print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=5>\n";
                    print OUTPUT "<tr><td align=center><b>Frame Value<\/b><\/td><td align=center><b>Offset<\/b><\/td><td align=center><b>Function Name<\/b><\/td><td align=center><b>Shared Obj.<\/b><\/td><\/tr>\n";
                    $frame_section = 1;
                }

                $status = findVal($1, "Frame", \%RelocHash);

           }

            #Stack 0x7fafe8d0: 775bc5a0 7fafe988 77dbc030 004cc832 779b2470 7fafe9d8 00000218 7794bd30
           if ($line =~ m/(Stack 0x[A-Fa-f0-9]{8}: +)(.+)/)
           {
               my @stackData = split("[ ]+", $2);  # tokenize using spaces and place into an array

                #print stack header only once
                if (!$stack_section) {
                    # end frame table
		    if ($frame_section == 1) {
			print OUTPUT "<\/TABLE>\n\n"    
		    }
                    print "Parsing stack, this may take a while ...\n";
                    # put info in table form
                    prntHeader("Stack Search", 2);
                    print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=5>\n";
                    print OUTPUT "<tr><td align=center><b>Stack Value<\/b><\/td><td align=center><b>Offset<\/b><\/td><td align=center><b>Function Name<\/b><\/td><td align=center><b>Shared Obj.<\/b><\/td><\/tr>\n";
                    $stack_section = 1;
                }

                foreach my $stackaddress (@stackData) {

                    print "loop-Now looking at >$stackaddress<\n";
                    #look at xmap to try to find the function
                    $status = findVal($stackaddress, "Stack", \%RelocHash);
                    #TODO: need to call printAddressNotFoundToOutput upon a failure of findVal()
                }

                #The following is from TC legacy leave it in case we have some way
                #of knowing the report is done.
                
                #print stack message after the last stack function has been parsed.
                #The first conditional handles all ThinClient releases from Chester on,
                #and the second handles all old releases up until and including Bala,
                #prior to the fatal error log format changing
                if ( ($line =~ m/$fatalErrorLogString 0x01F0/)   ||
                    ($line =~ m/$fatalErrorLogString 0x00FA/) )    {
                    print OUTPUT "<tr><td colspan=3>For more info on the stack pointer, enter \";stack\" in a serial port window<\/td><\/tr>\n";
                    #end table
                    print OUTPUT "<\/TABLE>\n\n";

                    #reset stack section
                    $stack_section = 0;
                    
                    #reset the type as we have finished this entry.
                    $type = 0;

                    print "... finished parsing stack\n\n";
                }#end if line
            }#end: find stack info
            else
            {
               print "Ignored line - $line\n";
            }

        }#end if type eq exception

    } #end: while ($line = <INPUT>)

close INPUT;
}#end parseLogAndWriteToOutput


#------------------------------------------------------
# addTableOfContents
#------------------------------------------------------
sub addTableOfContents {
    #add the table of contents to the beginning of the output
    @ARGV = $OUTPUT;
    $^I = "bak";
    my $temp = 1;
    while (<>) {

        # replace old title with a new one if applicable
        if (($_ =~ m/ - NMI Exception Data/)) {
            newTitle();

            if ($nmiTitleFlg == 1) { #new title for NMI
                $_ =~ s/ - NMI Exception Data/$newTitle/g;
            }
            print;
        }
        else {
            print;
        }

        #append this information right after the <body> header
        if (m/\<body/ and $temp) {
            print "\n\n<h1>$outputFileTitle<\/h1>\n";
            print "\n\n<h2>Table of Contents<\/h2>\n";
            print "<dl><dl>\n";   #Definition List ... used for indentation
            my $HNum = 0;  #this variable will store the Heading Number
            foreach (@toc) {
                # replace oldtitles with new ones if applicable
                if ((m/ - NMI Exception Data/)) {
                    newTitle();
                    if ($nmiTitleFlg == 1) { # new title for NMI
                        $_ =~ s/ - NMI Exception Data/$newTitle/g;
                    }
                }

                #save of toc entry
                my $LinkTitle = $_;

                #remove heading number and dash
                $LinkTitle =~ s/([0-9]+)\s\-\s//;
                #if the number changed, update tmp and add definition term (first tier)...
                if ($HNum != $1) {
                    $HNum = $1;
                    print "<br><dt><a href=\"#$_\">$_<\/a><br><br>\n";
                }
                else {
                    #...otherwise add Definition Description (it will be indented)
                    print "<dd><a href=\"#$_\">$LinkTitle<\/a><br>\n";
                }
            }
            print "<\/dl><\/dl>\n";
            print "<br><br><hr><br><br>\n\n";
            $temp = 0;

        }

        ARGVOUT,    #print everything to the file
    }#end while

    unlink $OUTPUT.bak;
    print "\noutput saved as $OUTPUT\n";
    print "\n";
}#end addTableOfContents


#---------------------------------------
# parsePlatformXmapForStartAndEndAddresses
#---------------------------------------
sub parsePlatformXmapForStartAndEndAddresses
{
    my $fileHandle = 'fh0001';
    my $filename = $platformXmapfile;
    my $funcName = "parsePlatformXmapForStartAndEndAddresses";
    unless (open($fileHandle, $filename)) {
        printf STDERR ("$funcName: Can't open $filename $!\n");
        die;
    }

    #get constant high and low address values from xmap
    print "searching $filename for start/end addresses\n\n";

    ###--- parse XMAP file for start/end address ranges

    my $go = 1;            #flag to let program know when to stop (go=0)
    my $searchRam = 1;        #flag to let program know when to start to search for the end of ram (1)
    my $linepick;

    while ($line_xmap = <$fileHandle> and $go) {
        #search for start and end addresses
        #search for the end of the ram text section, this will be after all other values have been found
        if ($searchRam) {
            # KA - <D>Memory map: 77181000-77188000 r-xp 00000000 00:0e 5374443    /usr/lib/streamer/libtscommonelements.so
            # <D>Memory map: 00411000-00414000 rw-p 00011000 00:0e 11807460   /usr/bin/serialdiagnostics
            if($line_xmap =~ /([A-Fa-f0-9]{8})-([A-Fa-f0-9]{8})[ ]+....[ ]+([A-Fa-f0-9]{8}) ..:.. [0-9]{1,10}[ ]+(.+)/) {
               
                my @Temp = ($1,$2,$3,$4);
                $_ = $Temp[3];
                my $filename = $Temp[3];
                $filename = m/(.*)[\\\/](.+)/ ? $2:$filename; 
                if($ram_start_address == 0)
                {
                   print "ram_start_address: $Temp[0]\n";
                   $ram_start_address = hex($Temp[0]);
                }
                $ram_prev_address = $Temp[0];
                $linepick = $line_xmap;
                chomp($linepick);

                if($debug1)
                {
                 print "filename=$filename\n";
                 print "0_$Temp[0],1_$Temp[1],2_$Temp[2],3_$Temp[3]\n";
                }

                $IndexPlatformXmap++;   # Count
                if ($IndexPlatformXmap%1000 == 0) {
                        print ".";
                }
                $AddressPlatformXmap{$IndexPlatformXmap}=hex($Temp[0]);   # library address to decimal & store it in a hash, key = line number
                $GoodlinePlatformXmap{$IndexPlatformXmap} = $linepick;            # Store the valid lines in a hash, key = line number
                $OffsetPlatformXmap{$IndexPlatformXmap} = hex($Temp[2]);
                $AddressEndPlatformXmap{$IndexPlatformXmap}=hex($Temp[1]);
                my $AdderssHex = sprintf("%x", $AddressPlatformXmap{$IndexPlatformXmap});
                my $offsetHex = sprintf("%x", $OffsetPlatformXmap{$IndexPlatformXmap}); 
                if($debug1)
                {
                       print ("Index=$IndexPlatformXmap,Address=$AdderssHex,offset=$offsetHex,$GoodlinePlatformXmap{$IndexPlatformXmap}\n");
                }
            }
            #ZBDEBUG
            #.text section not found so it exits the loop.
            #end address will be the last found address in the .text section
            
            $ram_end_address = hex($ram_prev_address);
        }
    }#end while

    print "\n ram_end_address:   $ram_prev_address\n\n";

    close $fileHandle;
}#end parsePlatformXmapForStartAndEndAddresses


#-----------------------------
# validateConfigFile
#-----------------------------
sub validateConfigFile {

    $funcName = "validateConfigFile";
    if($debug1) {
        printf("Hello from $funcName\n");
    }

    my $found = $FALSE;

    $found = &isHeadingFound(\%ConfigHash, '[general]');
    if(!$found) {
        die "$funcName: [General] heading not found in config file; exiting ...\n";
    }
    $found = &isHeadingFound(\%ConfigHash, '[platform]');
    if(!$found) {
        die "$funcName: [Platform] heading not found in config file; exiting ...\n";
    }

    #check if name in config file exists
    my $fileHandle = 'fh0002';
    $fatalErrorLogFilename = $ConfigHash{'[general]'}->{'fatalerrorfile'};
    unless (open($fileHandle, $fatalErrorLogFilename)) {
        print STDERR "$funcName: Can't open $fatalErrorLogFilename $!\n";
        die;
    }
    close $fileHandle;

    #check if outputFile was specified (overrides default fe_out.htm);
    my $outputFilename = $ConfigHash{'[general]'}->{'outputfile'};
    if ($outputFilename ne "") {
        $OUTPUT = $outputFilename;
    }

    # for KA the file name has the time so parse and get it.
    $_ = $fatalErrorLogFilename;
    $fatalErrorLogTime = m/[\.]([0-9]+)$/ ? $1:0;

    #check if outputFile was specified (overrides default fe_out.htm);
    $solocationDir = $ConfigHash{'[general]'}->{'sotopleveldir'};

    #check that a firmware (monolith xmap or ThinClient firmware) was provided
    $platform = $ConfigHash{'[platform]'}->{'xmapfile'};
    unless (open($fileHandle, $platform)) {
        print STDERR "$funcName: Can't open xmap file $platform $!\n";
        die;
    }

    #defer the checking of any relocatable app objects until they are
    #processed later

    close $fileHandle;

    $INPUT = $fatalErrorLogFilename;

}#end validateFatalErrorLog

#-------------------------
# dumpSampleConfigFile
#-------------------------
sub dumpSampleConfigFile {
    printf("\nPrinting sample input config file ...\n");

    printf("\n#---------------------------------------------------");
    printf("\n# Sample Fatal Error Parser input configuration file");
    printf("\n#---------------------------------------------------\n");

    printf("\n#Note: all filenames are entered as DOS-style pathnames\n");

    printf("\n#Provide a [General] heading with name of the fatal error");
    printf("\n#log file in fatalErrorFile tag and optional outputFile tag\n");
    printf("\n[General]\n");
    printf("fatalErrorFile=fatalErrorLog.txt\n");
    printf("\n#Optional: uncomment the outputFile tag setting to define your");
    printf("\n#own output filename, overriding default 'fe_out.htm'\n");
    printf("#outputFile=myFatalErrorOutputFile.htm.");
    printf("\n\n");
    printf("\n#List xmaps here. For monolithic builds, the only object");
    printf("\n#entry is that of the monobuild itself, in the [Platform]");
    printf("\n#heading; for codesuite builds, provide the [Platform] xmapFile,");
    printf("\n#followed by separate [Object<number>] headings for each application");
    printf("\n#xmap. Make sure the object heading numbers are in monotonically");
    printf("\n#increasing order starting with [Object01], [Object02], etc");
    printf("\n#For a codesuite build, you can supply less than the expected");
    printf("\n#number of xmap files for each application object, but the platform");
    printf("\n#at a minimum must be supplied.");
    printf("\n");
    printf("\n[Platform]");
    printf("\nxmapFile=d:\\ThinClient\\tcs_1012.xmap");
    printf("\n");
    printf("\n[Object01]");
    printf("\nxmapFile=d:\\codesuiteApps\\app1.xmap\n");
    printf("\n");
    printf("[Object02]");
    printf("\nxmapFile=d:\\codesuiteApps\\app2.xmap\n");
    printf("\n\n");
}# end dumpSampleConfigFile

#-----------------------------------------------
# fillProvidedXmapsArray
#
# Arguments:
#
# 0  ConfigHash built from parse config file
#
# Build an array of xmap items, making sure the
# xmap of the platform is the first (0th) item
#-----------------------------------------------
sub fillProvidedXmapsArray {
    my $refHashOfHashes = $_[0];
    my $value = 0;
    my $funcName = "fillProvidedXmapsArray";

    for my $key1 ( sort keys %$refHashOfHashes ) {
        if($key1 =~ m/^\[platform\]$/) {
            #the value at each $key1 is itself another hash
            for my $key2 ( sort keys %{$refHashOfHashes->{$key1}} ) {
                $value = $refHashOfHashes->{ $key1 }->{ $key2};
                if ($key2 =~ m/^xmapfile$/) {
                    &addToProvidedXmapsArray($value);
                    #Populate global variable $platformXmapfile
                    $platformXmapfile = $value;
                }
            }
        }
    }#end for

    for my $key1 ( sort keys %$refHashOfHashes ) {
        if($key1 =~ m/^\[object[0-9][0-9]\]$/) {
            #the value at each $key1 is itself another hash
            for my $key2 ( sort keys %{$refHashOfHashes->{$key1}} ) {
                $value = $refHashOfHashes->{ $key1 }->{ $key2};
                if ($key2 =~ m/^xmapfile$/) {
                    &addToProvidedXmapsArray($value);
                }
            }
        }
    }#end for my $key1

}#end fillProvidedXmapsArray

#------------------------------------
# printConfigSummary
#
# Arguments
#
# 0  the ConfigHash
#-------------------------------------
sub printConfigSummary {

    print "\n### Summary of config file entries ###\n\n";
    print "Fatal Error Log   :   $fatalErrorLogFilename\n";
    print "Platform xmap     :   $platformXmapfile\n";

    my $refHashOfHashes = $_[0];
    my $foundAppObj = $FALSE;

    #Dump the 'hash of hashes'
    for my $key1 ( sort keys %$refHashOfHashes ) {
	    if($key1 =~ m/^\[object[0-9][0-9]\]$/) {
		if(! ($foundAppObj) ) {
		    printf("Application xmaps :\n");
		    $foundAppObj = $TRUE;
		}
		#the value at each $key1 is itself another hash
		for my $key2 ( sort keys %{$refHashOfHashes->{$key1}} ) {
		    $value = $refHashOfHashes->{ $key1 }->{ $key2};
		    if($key2 =~ m/^xmapfile$/) {
			print "$value\n";
		    }
		}
	    }
    }#end for key1
    print "\n";

}#end printConfigSummary


#---------------------------------------------
# addToProvidedXmapsArray
#
# As the providedXmapsArray is built from
# the xmapFile entries provided by the user
# in the config file; the user has to supply
# "up front" all xmap files for all exception
# records.
#--------------------------------------------
sub addToProvidedXmapsArray {
    my $item = $_[0];
    my $funcName = "addToProvidedXmapsArray";

    my $count = 0;
    my $found = $FALSE;

    #add entry if array is empty
    if(@providedXmapsArray == 0) {
        if($debug1) {
            printf("$funcName: array is empty, pushing item $item onto array\n");
        }
        push(@providedXmapsArray, $item);
        addToProvidedXmapSummaryHash(\%ProvidedXmapSummaryHash, $item, "");
    }
    else { #array is not empty
        #check that provided xmaps are not duplicated
        for(; $count <= @providedXmapsArray; $count++) {
            if ($item eq $providedXmapsArray[$count]) {
                $found = $TRUE;
                last;
            }
        }#end for
        if (!($found)) {
            #add the item to both the array and to the
            #providedXmapSummaryHash; the latter structure,
            #initially provide a textBaseAddr of empty string
            if($debug1) {
                printf("$funcName: array is not empty, pushing item $item onto array\n");
            }
            push(@providedXmapsArray, $item);
            addToProvidedXmapSummaryHash(\%ProvidedXmapSummaryHash, $item, "");
        }
    }#end if-else

    if($debug1) {
        #Dump the ProvidedXmapSummaryHash
        printf("About to return from $funcName; dumping the ProvidedXmapSummaryHash so far ...\n");
        &printHashOfHashes(\%ProvidedXmapSummaryHash);
        print "\n";
    }

}#end addToProvidedXmapsArray


###---------------------------------------
### printCreationSummaryToOutput
###---------------------------------------
sub printCreationSummaryToOutput {
    prntHeader("Creation Information", 2);
    print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
    print OUTPUT "<tr><td>Filename<\/b<\/td><td>$OUTPUT<\/td><\/tr>\n";
    print OUTPUT "<tr><td>Creation date<\/b<\/td><td>$date<\/td><\/tr>\n";
    print OUTPUT "<tr><td>Created by parse-backtrace.pl version<\/b<\/td><td>$version<\/td><\/tr>\n";
    print OUTPUT "<tr><td>Using input config file<\/td><td>$configFile<\/td><\/tr>\n";
    print OUTPUT "<tr><td>Using input fatal error log<\/td><td>$fatalErrorLogFilename<\/td><\/tr>\n";
    print OUTPUT "<\/TABLE>\n\n";
}#end printCreationSummaryToOutput

#-------------------------------------------
# printXmapSummaryToOutput
#
#
# Arguments:
# 0  @expectedXmapsArray
# 1  %ProvidedXmapSummaryHash
#
# Walk these two structures at the same
# time, creating the "XMAP File Summary"
# section prepended to each exception record
# listing in the HTML output
#--------------------------------------------
sub printXmapSummaryToOutput {
    my $refProvidedHash  = $_[0];
    my @expectedArrCopy  = $_[1];

    my $funcName = "printXmapSummaryToOutput";

    prntHeader("XMAP File Summary", 2);
    print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
    print OUTPUT "<tr><td><b>Expected XMAP for Object<\/b<\/td><td><b>Provided XMAP<\/td><td><b>Object base address<\/b<\/td><\/tr>\n";

    my $count = 0;
    my $providedXmapName;
    my $providedXmapTextBaseAddr;

    if($debug) {
        print "Top of $funcName: dumping the providedXmapsArray...\n";
        foreach $xmapEntry (@providedXmapsArray) {
            printf("$xmapEntry\n");
        }
        print "Top of $funcName: dumping the ProvidedXmapSummaryHash...\n";
        &printHashOfHashes($refProvidedHash);
        &printHashOfHashes(\%ProvidedXmapSummaryHash);
    }

    while ($count < @expectedXmapsArray) {
        if($count >= @providedXmapsArray) {
            $providedXmapName = "NONE SPECIFIED";
            $providedXmapTextBaseAddr = "";
        }
        else {
            $providedXmapName = $refProvidedHash->{$count}->{$ProvidedXmapSummaryHashTags[0]};
            $providedXmapTextBaseAddr = $refProvidedHash->{$count}->{$ProvidedXmapSummaryHashTags[1]};
        }
        print OUTPUT "<tr><td>@expectedXmapsArray[$count]<\/td><td>$providedXmapName<\/td><td>0x$providedXmapTextBaseAddr<\/td><\/tr>\n";

        $count++;
    }#end while
    print OUTPUT "<\/TABLE>\n\n";
}#end printXmapSummaryToOutput


#-----------------------------------------
# addToProvidedXmapSummaryHash()
#
#-----------------------------------------
sub addToProvidedXmapSummaryHash() {
    my $hashRef    = $_[0];
    my $providedXmapName = $_[1];
    my $providedXmapTextBaseAddr = $_[2];
    my $count = $providedXmapSummaryHashCount; #increment global value

    $hashRef->{$count}->{$ProvidedXmapSummaryHashTags[0]} = $providedXmapName;
    $hashRef->{$count}->{$ProvidedXmapSummaryHashTags[1]} = $providedXmapTextBaseAddr;

    $providedXmapSummaryHashCount++;

    if($debug2) {
        #Dump the ProvidedXmapSummaryHash
        printf("\n--- Dumping the ProvidedXmapSummaryHash ---\n");
        &printHashOfHashes($hashRef);
    }
}#end addToProvidedXmapSummaryHash

#-----------------------------------
# isHeadingFound
# returns $TRUE is found, $FALSE ow
#-----------------------------------
sub isHeadingFound {
    my $refHashOfHashes = $_[0];
    my $heading = $_[1];
    my $funcName = "isHeadingFound";

    local $found = $FALSE;

    for my $key1 ( sort keys %$refHashOfHashes ) {
        if ($heading eq $key1) {
            $found = $TRUE;
            last; #works like 'break' in C
        }
    }
    return ($found);
}



###---------------------------------------
### printFirmwareWarningToOutput
###---------------------------------------
sub printFirmwareWarningToOutput {

    my $lastVersion    = $_[0];
    my $currentVersion = $_[1];

    prntHeader("WARNING", 2);

    print OUTPUT "<TABLE border=1 cellspacing=3 cellpadding=3>\n";
    my $message = "This reset log contains records of type EVENT, EXCEPTION, or NMI EXCEPTION from different platform versions.";
    print OUTPUT "<tr><td COLSPAN=2><b>$message</\b><\/td><\/tr>\n";
    print OUTPUT "<tr><td>Previous record platform<\/td><td>Current record platform<\/td><\/tr>\n";
    print OUTPUT "<tr><td>$lastVersion<\/td><td>$currentVersion<\/td><\/tr>\n";
    $message = "Your results may not be reliable.";
    $message .= "&nbspFor best results, provide a log file with exception records for only one platform version.";
    print OUTPUT "<tr><td COLSPAN=2>$message<\/td><\/tr>\n";

    print OUTPUT "<\/TABLE>\n\n";
}#end printFirmwareWarningToOutput


###---------------------------------------
### printFirmwareWarningToConsole
###---------------------------------------
sub printFirmwareWarningToConsole {

    my $lastVersion    = $_[0];
    my $currentVersion = $_[1];

    chomp($lastVersion);
    chomp($currentVersion);

    my $message = "\n--- WARNING ---\n\n";
    $message .= "This reset log contains records of type EVENT, EXCEPTION, or NMI EXCEPTION from different platform versions.\n";
    $message .= "Previous record platform version: $lastVersion\n";
    $message .= "Current record platform version: $currentVersion\n\n";
    $message .= "Your results may not be reliable.\n";
    $message .= "For best results, provide a log file with exception records for only one platform version.\n";
    $message .= "\n--- END WARNING ---\n\n";
    print "$message\n";

}#end printFirmwareWarningToConsole


sub Wanted {

  #note that find operates as follows
  # 1. $File::Find::dir = /some/path/
  # 2. $_ = foo.ext
  # 3. $File::Find::name = /some/path/foo.ext

  my $file = $File::Find::name;
  my $curline = "";
  my $functionName = "NONE";
  my $functionLine = "NONE";
  my $last_function_pos = 0;
  my $cur_function_pos = 0;
  my $backtracelines = 0;
  my $functionoffset = 0;
  my $skiptooffset= 0;
  my $linecount = 0;
  my $do_smartsearch = 1; 
  my $do_search = 0;
  my $end_search = 0;
  my $found_offset = 0;
  my $bare_filename = $_;

  if($^O eq "MSWin32")
  {
     $file =~ s,/,\\,g;
  }


  return unless -f $file;
  return unless $_ eq $file_pattern;

  open F, $file or print "couldn't open $file\n" && return;

  my $offsetinDecformat = hex($search_pattern);

  # indicate no match to start with.
  $fname = $NOFUNCTIONMATCH;

  # go through each line in the file
  while ($curline = <F>) {
       if ($do_search == 0)
       {
          # only start looking for function when .text section is seen
          if($curline =~ m/Disassembly of section \.text:/)
          {
             $do_search = 1;
          } 
          else
          {
             next;
          }
       }

   #store the name of the function and the location in the file
   #for latter backtrace.
       if (($curline =~ m/([A-Fa-f0-9]{8}) (<.+>):/) && ($do_search == 1))
       {
          $functionoffset = hex($1);
          $functionName = $2;
          $functionLine = $curline;
          $last_function_pos = $cur_function_pos;
          $cur_function_pos = tell F;
          $backtracelines = 0;

          # mark where you were in stream before searching the rest of the file

          # $search_pattern is really the offset into the function we are looking for
          if($functionoffset > $offsetinDecformat)
          {
            #we may have been overzealous, go back to last found function and search
             if ($jumptopos > 0) 
             {
                seek F, $last_function_pos, 0;
                $do_smartsearch = 0;
             }
             else
             {
                print "Quit looking because function offset is larger than input\n";
                last;
             }
          }
          elsif ($do_smartsearch == 1) 
          {
             #fuzzy logic
             # keep trying to get within 8K bytes of the target line
             # estimate number of lines between offset and multiply by an
             # a very low estimate of the number of bytes per line
             $jumptopos = (($offsetinDecformat - $functionoffset)/4) * 32;
             if($jumptopos > 18432)
             {
                #jumpto but backoff a bit to find function header
                $jumptopos = $jumptopos + $cur_function_pos - 8192;
                seek F, $jumptopos, 0;
             }
          }
       }

       $backtracelines++;

       if (($curline =~ m/ ($search_pattern):/) && ($do_search == 1))
       {
          $found_offset = tell F;
          seek F, $cur_function_pos, 0;

          #fuzzy logic, if this number is greater than 256 then either
          #this function is big or our fuzzy smart search missed the
          #start of the function when jumping and $cur_function_pos doesn't
          #contain the function point for this offset so go back and
          #search again, this should happen rarely...
          if((($offsetinDecformat - $functionoffset)/4) > 256 && ($do_smartsearch == 1))
          {
             $do_smartsearch = 0;
             $end_search = 0;
          }
          else
          {  
             $fname = $functionName;
             $fname =~ s/\<//g;
             $fname =~ s/\>//g;

             $end_search = 1;

               #for stack trace skip over duplicate function names in a sequence
               if(($fname eq $prev_fname) && ($skip_duplicates == 1))
               {
                  $fname = $NOFUNCTIONMATCH;
               }
               else
               {
                   print "-----------------------------------------------------------\n";               
                   print "Lib: $floc\n";
                   print "function: $functionLine";
                   print "offset: $search_pattern\n";

                   $prev_fname = $fname;

                   if(($cur_function_pos > 0) && ($do_backtrace == 1))
                   {
                      while ($curline = <F>) 
                      {
                         if($backtracelines-- < 200)
                         {
                            print "$curline";
                         }
             
                         if($curline =~ m/ ($search_pattern):/)
                         {
                             last;
                         }
                      }# end while ($curline = <F>)
                   }
               }#end else not duplicate
          } #end else

        }# end we found a match

        if($end_search)
        {
            last;
        }

  }#end while more lines in file

  $stop_searching = 1;

  close F;
}

sub  Preprocess {

   if($stop_searching)
   {
      return;
   }
   return @_;
}

#
# This sub-routine is used to find new titles for output file
#
sub newTitle
{
    my $line = $`;
    my $orgTitle = $&;
    my $HdNum = 0;
    my $ZeroFlg = 0;
    my $CauseFlg = 0;
    my $causeVal = 0;
    my $execCode = 0;

    $line =~ s/<a name="//;                # find HeaderNum
    $HdNum = $line;
    $ZeroFlg = $Zero_Array[$HdNum];
    $CauseFlg = $Cause_Array[$HdNum];

    $causeVal = hex($CauseFlg);
    #exception code (bits 2-6)
    $execCode = ($causeVal & 124) >> 2;

    if ($_ =~ m/ - NMI Exception Data/) {
        if ($ZeroFlg eq "00000001" ) { #ZeroReg = 1
            $newTitle = " - Bootcode Exception";
            $nmiTitleFlg = 1;
        }
        elsif ($ZeroFlg eq "ABADDEED") {
            $newTitle = " - Bootcode Event";
            $nmiTitleFlg = 1;
        }
        elsif ($execCode == 0) { #CauseReg execCode == 0
            $newTitle = " - NMI Exception Data - Watchdog Timeout";
            $nmiTitleFlg = 1;
        }
        else {
            $newTitle = " - NMI Exception Data - Double Exception";
            $nmiTitleFlg = 1;
        }
    } # end of " - NMI Exception Data"
    else {
            $newTitle = " - Exception Data";
            $nmiTitleFlg = 1;
    }

} # end of "sub NewTitle"
