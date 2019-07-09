/*
 *--------------------------------------------------------------------
 *
 * main.cpp --
 *
 * Copyright (c) 2000 Kreatel Communications AB
 *
 *--------------------------------------------------------------------
 */

#include "Parser.h"
#include "Print.h"
#include <iostream>
#include <locale>
#include <string>

// --------------------------------------------------------------------
// Anropsformat:
// 1. workFlex2000 infil utfil
// 2. workFlex2000 infil utfil
// 3. workFlex2000 help, skriver ut en instruktioner på skärmen.
// ---------------------------------------------------------------------

int main(int argc, char* argv[])
{
  TParser* parser = NULL;
	TPrint* print = NULL;
  
  try {
    if (argc == 2 && std::string(argv[1]) != "help") {
      parser = new TParser(argv[1]);
    }
    else {
      std::cout << argv[0] << std::endl;
      std::cout << "----------------------------------------------------------"
                << std::endl;
      std::cout << "Daniel Helmers's Worktime Hack" << std::endl;
      std::cout << "Flex time additions by Jonas Nilsson and Marcus Gustafsson"
                << std::endl;
      std::cout << "WorkFlex2000 upgrade by Kalle Pettersson" << std::endl;
      std::cout << "Hacked by Hallon" << std::endl;
      std::cout << "Ported to Linux and Motorola adapted by Thojo"
                << std::endl;
      std::cout << "Hacked by Olov"
                << std::endl << std::endl;
      std::cout << "Use one of the following ways to start the program:"
                << std::endl;
      std::cout << "0. " << argv[0]
                << " -, input from stdin and prints the result to the screen."
                << std::endl;
      std::cout << "1. " << argv[0]
                << " infile, prints the result to the screen."
                << std::endl;
      std::cout << "2. " << argv[0]
                << " infile > outfile, "
                << "prints the result to specified file." << std::endl;
      std::cout << "3. " << argv[0]
                << " help, get this information." << std::endl << std::endl;

      std::cout << "Infile example:" << std::endl << std::endl;
      std::cout << "namn = Foo Barsson" << std::endl;
      std::cout << "år = 2008" << std::endl;
      std::cout << "månad = 04" << std::endl;
      std::cout << "inflex = 1:23" << std::endl;
      std::cout << "komptidsuttag = 0:00" << std::endl;
      std::cout << "ingående komptid = 0:00" << std::endl;
      std::cout << "ingående övertid1 = 0:00" << std::endl;
      std::cout << "ingående övertid2 = 0:00" << std::endl;
      std::cout << "övertid i pengar = nej" << std::endl;
      std::cout << "2008-04-01 tis 8:30-16:20  <type> <project> <comment>" << std::endl; 
      std::cout << "..." << std::endl << std::endl;

      std::cout << "Holidays should be marked with 'röd' as the weekday" << std::endl << std::endl;
      
      std::cout << "Types are: " << std::endl;
      std::cout << "h\thalf day" << std::endl;
      std::cout << "n\tnormal" << std::endl;
      std::cout << "p\tleave of absence" << std::endl;
      std::cout << "r\ttravel" << std::endl;
      std::cout << "s\tvacation" << std::endl;
      std::cout << "sj\tsick leave" << std::endl;
      std::cout << "ö1\tovertime type 1" << std::endl;
      std::cout << "ö2\tovertime type 2" << std::endl << std::endl;
      
      std::cout << "Motorolas arbetstidsregler:" << std::endl;
      std::cout << "* 7,5 timmars arbetsdag (08:30-17:00)." << std::endl;
      std::cout << "* Övertid av typ 1 på vardagar 06-20 "
                << "(månadslön / 94 per timme)." << std::endl;
      std::cout << "* Övertid av typ 2 övrig tid (månadslön / 72 per timme)."
                << std::endl;
      std::cout << "* Övertid endast som fulla halvtimmar "
                << "(workflex bryr sig inte om det)." << std::endl;
      std::cout << "* Restidsersättning endast inom Sverige och endast"
                << std::endl
                << "  om man har rätt till övertidsersättning." << std::endl;
      std::cout << "* Restidsersättning av typ 1 måndag 06:00 till "
                << "fredag 18:00 och endast " << std::endl
                << "  utanför ordinarie arbetstid (månadslön / 240 per timme)."
                << std::endl;
      std::cout << "* Restidsersättning av type 2 övrig tid "
                << "(månadslön / 190 per timme)." << std::endl;
      std::cout << "* Restid endast hela halvtimmar. Max 6 timmar av typ "
                << "1 per kalenderdygn." << std::endl;
      std::cout << "* Workflex hanterar fn ej olika restidstyper."
                << std::endl;
      return 0;
    }  
    parser->GetHeader();
    parser->GetTimeReport();
    
    print = new TPrint(parser->GetRecord(), std::cout);
    //print->PrintTable();
    print->PrintDaySummary();
    print->PrintProjectDaySummary();
    print->PrintSummary();
  }
  catch(TVerboseException& e) {
    std::cout << "workflex error: " << e.GetText() << std::endl;
  }
  if (parser != NULL) {
    delete parser;
  }
	if (print != NULL) {
    delete print;
  }
  return 0;
}
