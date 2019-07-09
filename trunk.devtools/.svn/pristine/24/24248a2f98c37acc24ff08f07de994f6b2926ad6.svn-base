#!/usr/bin/perl

##########################################################################################
#
# Copyright: 2012 Motorola Mobility Inc.  All rights reserved.
# 
# create a configuration file for parse-backtrace.pl to parse backtrace output.
##########################################################################################

use File::Find;

$exceptiondir = $ARGV[0]; #get dir from input
$sotextlocation = $ARGV[1]; #get dir from input
$file_pattern = "backtrace";

print "about to call find to locate $file_pattern\n";
$stop_searching = 0;

# find any backtrace* file in the given directory and process
find( { wanted => \&Wanted,  
      preprocess => \&Preprocess,
      no_chdir => 1,
     },  $exceptiondir);

sub Wanted {

   #note that find operates as follows
   #1.  $File::Find::dir = /some/path/
   # 2. $_ = foo.ext
   # 3. $File::Find::name = /some/path/foo.ext
   
   my $file = $File::Find::name;

   if($^O eq "MSWin32")
   {
      $file =~ s,/,\\,g;
   }

   $regsfile = $file;
   return unless ($stop_searching == 0);
   return unless -f $file;
   return unless $_ =~ m/$file_pattern.[0-9]+/;

   # execlude the file patterns below which could also start with same
   # file_pattern
   return unless !($_ =~ m/\.(cfg|log|htm|gz|obj)$/);
   
   
   $mapsfile = $regsfile;
   
   $htmoutput = $regsfile;
   $htmoutput .= "_parsed.htm";
   
   $configfile = $regsfile;
   $configfile .= ".cfg";
   
   $txtoutput = $regsfile;
   $txtoutput .= "_parsed.log";

   print "fatalErrorFile=$regsfile\n";
   print "xmapFile=$mapsfile\n";
   print "outputFile=$htmoutput\n";
   print "configfile=$configfile\n";
   
   open OUTPUT, ">$configfile" or die ("ERROR!  Could not create $configfile");
   
   print OUTPUT "# Automatically Generated Config File\n";
   print OUTPUT "#---------------------------------------------------\n";
   print OUTPUT "## Fatal Error Parser input configuration file\n";
   print OUTPUT "##---------------------------------------------------\n";
   print OUTPUT "[General]\n";
   print OUTPUT "fatalErrorFile=$regsfile\n";
   print OUTPUT "outputFile=$htmoutput\n";
   print OUTPUT "sotopleveldir=$sotextlocation\n";
   if($^O eq "MSWin32")
   {
      print OUTPUT "gnutools=C:\\MinGW\\bin\n";
   }
   print OUTPUT "[Platform]\n";
   print OUTPUT "xmapFile=$mapsfile\n";
   print OUTPUT "#---------------------------------------------------\n";
   
   open OUTPUT;
   
   
   # we have constructed the configuration file, now execute the parser
   # script.
   system "perl parse-backtrace.pl -f $configfile > $txtoutput";
   #system "$htmoutput";

   #$stop_searching = 1;

}

sub  Preprocess {

   if($stop_searching)
   {
      return;
   }
   return @_;
}

