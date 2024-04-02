/*
  plot 'data2.dat' u 1:2:($3-$1):($4-$2) w vector, '' u ($3+$1)/2.:($4+$2)/2.:5 with labels offset char 2,char 2
*/

/* ******
   Name: genDiagram 
   Version: 0.10
   Date: 10/10/2014
   Author: Aaron McClung <amcclung@swri.org>

   Description: 
   This function uses list to query the current model and generate a flow network diagram. The function output is a graphviz input file (default is case.gv), which can then be processed with dot to create a visualization of the flow network. 

   If dot is installed, the case.gv can be used to generate a png using the following:
   > dot -Tpng -O case.gv

   Usage:

   // Configure Flow Network Diagram
   #define genDiagram 1
   #include <SwRIgenDiagram.fnc>

   ... Model Definition ...

   // Generate Flow Network Diagram for current case setup w/ variable list
   // dot.create( "filename.gv", Verbose, Execute)
   if ( $genDiagram ) { dot.create( strFmt("airBrayton.%06d.pre.gv", CASE), 1, 1); }

   Is equivalent to:

   // Generate Flow Network Diagram for current case setup w/ variable list
   if ( $genDiagram ) {
   dot.setGnsFile( strFmt("airBrayton.%06d.pre.gv", CASE) );
   dot.genVerboseDot(1); // 0 = Do not print variable list, 1 = Print variable list
   dot.runDot();
   }

   To Do:
   1. Add element type to element name
   2. Clean variable listing mechanism, add hooks for variables by element type

   ****** */

#ifndef __genDiagram__
#define __genDiagram__ 

// See user manual for how to utilize system calls.  
#include <System.fnc>

VariableContainer genDiagram {

  // * Container Initialization * //
  
  // Temporary Flow Station used to query fluid properties
  FlowStation FStemp;

  // ** Configure Gnuplot to use as plotting runtime ** //

  // Execute Gnuplot
  int doRun = TRUE;
  
  // Specify Executable
  string gnuplotBin = "gnuplot.exe";
  // Gnuplot Terminals used to save graphics
  string gnuplotOutType[] = { "png", "svg" }; // "pdf" works but creates raster graphics under cygwin
  // Terminal options for saved graphics
  string gnuplotOutOptions[] = { "small", "" }; // "pdf" works but creates raster graphics under cygwin

  
  // Files for saving scripts and output
  string basename = "gnuplot";
  string casename = strFmt("%s.%06d",basename,CASE);
  string gnsScript = casename + ".gns";
  string elementDatFile = casename + ".elements.dat";
  string domeDatFile = casename + ".dome.dat";
  string gnsFilesToRun[];

  // Add contours?
  int cPh = FALSE;
  int cTs = FALSE;

  // Runtime Options
  int VERBOSE = FALSE;
  int DEBUG = FALSE;
    
  // Define I/O Stream
  OutFileStream os_gns  {filename = gnsScript; }
  OutFileStream os_dat  {filename = elementDatFile; }
  OutFileStream os_dome {filename = domeDatFile; }

  string comp;
  int vaporDomeNs = 50;
  
  // List of elements to diagram
  string elist[];

  // Update and generate plots for this case
  void update() {
    updateFileNames();
    gnsFilesToRun = {};
    genDiagram();
  }

  void updateFileNames() {
    casename = strFmt("%s.%06d",basename,CASE);
    setGnsFile(casename + ".gns");
    elementDatFile = casename + ".elements.dat";
    os_dat.filename = elementDatFile;
    domeDatFile = casename + ".dome.dat";
    // os_dome.filename = domeDatFile;
  }
  
  void ifDebug ( string text ) {
    if ( DEBUG ) {
      cout << "gnuplot: " << text << endl;
    }
  } 
  
  // ** File Utilities ** //
  void setGnsFile( string filename ){
    gnsScript = filename;    
    ifDebug( "gnsScript:\"" + gnsScript + "\"" );
    os_gns.filename = gnsScript;
    ifDebug( "os_gns.filename:\"" + os_gns.filename + "\"" );
  }
  
  void setOutType( string type[], string options[] ){
    gnuplotOutType = type;
    gnuplotOutOptions = options;
  }

  void setgnuplotBin( string filename ){
    gnuplotBin = filename;
  }

  // Create the graphviz header including label, leave graph open
  void createGnuplotHeader() {
    os_gns << "# Header" << "\n";
  }
  
  // close the graph created in the header
  void createGnuplotFooter() {
    os_gns << "# Footer" << "\n";
  }

  void setGnuplotTerm(string Term, string outFile, string Options, int replot) {
    os_gns << "set output '" << outFile << "." << Term << "'" << "\n";
    os_gns << "set term " << Term << "\n";
    if (replot) {
      os_gns << "replot" << "\n";
    }
  }
  
  string getName( string var ) {
    temp = var.split(".");
    string v = temp[temp.entries()-1];
    return v;
  }

  void getVar( string composite ) {
    string temp[] = composite.split(".");
    if ( temp.entries() > 1 ) {
      return getVar( temp[0], temp[1] );
    } else {
      return FALSE; 
    }
  }

  void getVar( string obj, string var ) {
    string evalString = strFmt("%s.%s", obj, var);
    return evalExpr( evalString );
  }

  void createGnuplotPhDiagram() {
    os_gns << "Pt=2; h=6;" << "\n";
    os_gns << "set xlabel 'Enthalpy (" << evalExpr( elist[0]+".Fl_I.ht.units") << ")'" << "\n";
    os_gns << "set ylabel 'Pressure (" << evalExpr( elist[0]+".Fl_I.Pt.units") << ")'" << "\n";
    os_gns << "set log y" << "\n";
    
    // Contour Labels
    if (cPh) {
      if (sys.fileExists("contour.ph.Tt.labels") || sys.fileExists("contour.ph.rhot.labels") ) {
	os_gns << "l '<cat ";
	if (sys.fileExists("contour.ph.Tt.labels")) {
	  os_gns << " contour.ph.Tt.labels";
	}
	if (sys.fileExists("contour.ph.rhot.labels")) {
	  os_gns << " contour.ph.rhot.labels";
	}
	os_gns << "'" << endl;
      }
    }

    // Plot
    //os_gns << "plot '" << os_dat.filename << "u Pt:h:(column(Pt+1)-column(Pt)):(column(h+1)-column(h)) w vector" << "\n";
    //    os_gns << "plot '" << os_dat.filename << "' " << "u h:Pt:(column(h+1)-column(h)):(column(Pt+1)-column(Pt)) w vector title '', '' u (column(h+1)+column(h))/2.:(column(Pt+1)+column(Pt))/2.:1  with labels offset char 0,char 0 title ''" << "\n";
    os_gns << "plot \\" << endl;
    os_gns << "\t'" << os_dat.filename << "' " << "u h:Pt:(column(h+1)-column(h)):(column(Pt+1)-column(Pt)) w vector title '', \\" << endl;
    os_gns << "\t'' u (column(h+1)+column(h))/2.:(column(Pt+1)+column(Pt))/2.:1  with labels offset char 1,char 1 title ''";

    // Vapor Dome
    if (sys.fileExists(os_dome.filename)) {
      os_gns << ", \\" << endl;
      os_gns << "\t'" << os_dome.filename << "' " << "u h:Pt w l lw 2 title 'Saturated Liquid', \\" <<  endl;
      os_gns << "\t'' " << "u h+1:Pt w l lw 2 title 'Saturated Vapor'";
    }
    
    // Contour Lines
    if (cPh) {
      if ( sys.fileExists("contour.ph.Tt.dat") ) {
	os_gns << ", \\" << endl;
	os_gns << "\t'contour.ph.Tt.dat' u 1:2 w l title 'Constant Tt'";
      }    
      if ( sys.fileExists("contour.ph.rhot.dat") ) {
	os_gns << ", \\" << endl;
	os_gns << "\t'contour.ph.rhot.dat' u 1:2 w l title 'Constant Rhot'";
      }
    }
    os_gns << endl;

  }

  void createGnuplotTsDiagram() {
    os_gns << "Tt=4; s=8;" << "\n";
    os_gns << "set xlabel 'Entropy (" << evalExpr( elist[0]+".Fl_I.s.units") << ")'" << "\n";
    os_gns << "set ylabel 'Temperature (" << evalExpr( elist[0]+".Fl_I.Tt.units") << ")'" << "\n";
    //os_gns << "set log y" << "\n";
    
    // Contour Labels
    if (cTs) {
      if (sys.fileExists("contour.ts.Pt.labels") || sys.fileExists("contour.ts.rhot.labels") ) {
	os_gns << "l '<cat ";
	if (sys.fileExists("contour.ts.Pt.labels")) {
	  os_gns << " contour.ts.Pt.labels";
	}
	if (sys.fileExists("contour.ts.rhot.labels")) {
	  os_gns << " contour.ts.rhot.labels";
	}
	os_gns << "'" << endl;
      }
    }

    // Plot
    os_gns << "plot \\" << endl;
    os_gns << "\t'" << os_dat.filename << "' " << "u s:Tt:(column(s+1)-column(s)):(column(Tt+1)-column(Tt)) w vector title '', \\" << endl;
    os_gns << "\t'' u (column(s+1)+column(s))/2.:(column(Tt+1)+column(Tt))/2.:1  with labels offset char 1,char 1 title ''";

    // Vapor Dome
    if (sys.fileExists(os_dome.filename)) {
      os_gns << ", \\" << endl;
      os_gns << "\t'" << os_dome.filename << "' " << "u s:Tt w l lw 2 title 'Saturated Liquid', \\" <<  endl;
      os_gns << "\t'' " << "u s+1:Tt w l lw 2 title 'Saturated Vapor'";
    }

    // Contour Lines
    if (cTs) {
      if ( sys.fileExists("contour.ts.Pt.dat") ) {
	os_gns << ", \\" << endl;
	os_gns << "\t'contour.ts.Pt.dat' u 1:2 w l title 'Constant Tt'";
      }    
      if ( sys.fileExists("contour.ts.rhot.dat") ) {
	os_gns << ", \\" << endl;
	os_gns << "\t'contour.ts.rhot.dat' u 1:2 w l title 'Constant Rhot'";
      }
    }
    os_gns << endl;

  }

  /*
    void createGnuplotTsDiagram() {
    os_gns << "Tt=4; s=8;" << "\n";
    os_gns << "set xlabel 'Entropy (" << evalExpr( elist[0]+".Fl_I.s.units") << ")'" << "\n";
    os_gns << "set ylabel 'Temperature (" << evalExpr( elist[0]+".Fl_I.Tt.units") << ")'" << "\n";

    os_gns << "unset log y" << "\n";

    os_gns << "plot \\" << endl;
    os_gns << "\t'" << os_dat.filename << "' " << "u s:Tt:(column(s+1)-column(s)):(column(Tt+1)-column(Tt)) w vector title '', '' u (column(s+1)+column(s))/2.:(column(Tt+1)+column(Tt))/2.:1  with labels offset char 1,char 1 title '', \\" << endl;
    os_gns << "\t'" << os_dome.filename << "' " << "u s:Tt w l title 'Saturated Liquid', \\" <<  endl;
    os_gns << "\t'' " << "u s+1:Tt w l title 'Saturated Vapor'" <<  endl;
    }
  */

  /*
  void printElemFluidPortValues(string names[]) {
    int n;
    int v;
    int p;
  
    string varlist[] = {"Pt", "Tt", "ht", "s", "rhot"};
    string portlist[] = {"Fl_I", "Fl_O"};

    string var;

    // List of variables
    for (n=0; n<names.entries(); n++) {
      os_dat << "# " << names[n] << "\t";
      for (v=0; v<varlist.entries(); v++) {
	for (p=0; p<portlist.entries(); p++) {
	  var = names[n] + "." + portlist[p] + "." + varlist[v];
	  os_dat << var << " ";
	  //os_dat << evalExpr(var) << "\t";
	} // portlist
      } // varlist
      os_dat << "\n";
    }

    // List of Values
    for (n=0; n<names.entries(); n++) {
      os_dat << names[n] << "\t";
      for (v=0; v<varlist.entries(); v++) {
	for (p=0; p<portlist.entries(); p++) {
	  var = names[n] + "." + portlist[p] + "." + varlist[v];
	  //os_dat << var << " ";
	  os_dat << evalExpr(var) << "\t";
	} // portlist
      } // varlist
      os_dat << "\n";
    }

  }
  */

  void printElemFluidPortValues(string names[]) {
    int n;
    int v;
    int p;
    
    string varlist[] = {"Pt", "Tt", "ht", "s", "rhot"};
    string portlist[] = {"Fl_I", "Fl_O"};
    string inputList[];
    string outputList[];

    string var;

    /* 
    // Create header with list of variables
    for (n=0; n<names.entries(); n++) {
      os_dat << "# " << names[n] << "\t";
      for (v=0; v<varlist.entries(); v++) {
	for (p=0; p<portlist.entries(); p++) {
	  var = names[n] + "." + portlist[p] + "." + varlist[v];
	  os_dat << var << " ";
	  //os_dat << evalExpr(var) << "\t";
	} // portlist
      } // varlist
      os_dat << "\n";
    }

    */
    
    // Create Table with List of Values
    for (n=0; n<names.entries(); n++) {
      inputList = names[n]->list("FluidInputPort");
      //cout << "FluidInputPort" << "[" << inputList.entries() << "] : " << inputList << endl;
      
      outputList = names[n]->list("FluidOutputPort");
      //cout << "FluidOutputPort" << "[" << outputList.entries() << "] : " << outputList << endl;
			    
      // Check for at least one input and at least one output FluidPort
      if ( (inputList.entries() > 0) && (outputList.entries() > 0 ) ) {

	// We have a winner
	int i, o;
		
	// Check for More Inputs than Outputs
	if ( inputList.entries() < outputList.entries() ) {
	  // Copy the first input to match the remaining outputs
	  for (i=inputList.entries(); i<outputList.entries(); i++) {
	    inputList.append(inputList[0]);
	  }
	}

	// Check for More Outputs than Inputs
	if ( inputList.entries() > outputList.entries() ) {
	  // Copy the first output to match the remaining inputs
	  for (i=outputList.entries(); i<inputList.entries(); i++) {
	    outputList.append(outputList[0]);
	  }
	}
	
	// Write input -> output pair to file
	for (p=0; p<inputList.entries(); p++) {
	  
	  for (i=0; i<2; i++) {
	  
	    // Start the row
	    if (i) {
	      os_dat << names[n] << "\t";
	    } else {
	      os_dat << "# " << names[n] << "\t";
	    }
	    
	    for (v=0; v<varlist.entries(); v++) {
	      	      
	      // Input
	      //var = names[n] + "." + inputList[p] + "." + varlist[v];
	      var = inputList[p] + "." + varlist[v];
	      if (i) {
		os_dat << evalExpr(var) << "\t";
	      } else {
		os_dat << var << "\t";
	      }
	      
	      // Output
	      // var = names[n] + "." + outputList[p] + "." + varlist[v];
	      var = outputList[p] + "." + varlist[v];
	      if (i) {
		os_dat << evalExpr(var) << "\t";
	      } else {
		os_dat << var << "\t";
	      }
	      
	    } // varlist

	    // Close the Row
	    os_dat << "\n";

	  }
	} // portlist

      }
    }

  }

  
  void genElist() {
    // Elements with Fl_I and Fl_O
    // elist = .list("Element",0,"exists(\"Fl_I\")==1 && exists(\"Fl_O\")==1");
    elist = .list("Element");
  }
  
  void setElist(string in[]) {
    // Elements with Fl_I and Fl_O
    elist = in;
  }


  void genDiagram() {
    // Calculate Vapor Dome and save to file
    if (comp.length() > 0) {
      vaporDome(comp,vaporDomeNs);
    }

    // Write element conditions at I/O FluidStations 
    printElemFluidPortValues( elist );

    // P-h Diagram
    genDiagramPh();
    
    // T-s Diagram
    genDiagramTs();

    if ( doRun ) {
      runGnsFiles();
    }
  }

  
  void genDiagramPh() {
    setGnsFile( casename + ".Ph.gns" );
    cout << "genDiagram { filename = " << os_gns.filename << " } " << endl;
    createGnuplotPhDiagram();
    gnsFilesToRun.append( gnsScript );    
  }

  void genDiagramTs() {
    setGnsFile( casename + ".Ts.gns" );
    cout << "genDiagram { filename = " << os_gns.filename << " } " << endl;
    createGnuplotTsDiagram();
    gnsFilesToRun.append( gnsScript );
  }

  
  void genVerboseGnuplot(int verbose) {
    VERBOSE = verbose;
    genDiagram();
  }

  void runGnsFiles() {
    if ( gnsFilesToRun.entries() > 0 ) {
      int i;
      for (i=0; i<gnsFilesToRun.entries(); i++) {
	setGnsFile("eval.gns");
	cout << "genDiagram { filename = " << os_gns.filename << " } " << endl;
	os_gns << "load '" << gnsFilesToRun[i] << "'" << endl;
	evalGns( gnsFilesToRun[i] );
      }
    }
  }
  
  void evalGns(string outFile) {
    // Call gnuplot executable for current gv output file
    int o;
    string Term, Option;
    for (o=0; o < gnuplotOutType.entries(); o++ ) {
      Term = gnuplotOutType[o];
      Option = gnuplotOutOptions[o];
      setGnuplotTerm(Term,outFile,Option,1);
    }
    if ( doRun ) {
      runGns(gnsScript);
    }
  }

  void runGns(string gnsFile) {
    string command = gnuplotBin + " < " + gnsFile;
    ifDebug( "command:\"" + command + "\"" );
    // See page  in the user manual for system calls.  
    int status = sys.system( command );
    ifDebug( "status:\"" + toStr(status) + "\"" );
  }
  
  void create( string filename, int verbose, int doRun ) {
    // Check for filename = ""
    if ( filename.length() > 0 ) { setGnsFile(filename); }
    // Generate graphviz input
    genVerboseGnuplot( verbose );
    // Execute Gnuplot to create flow network
    if ( doRun ) { runGnuplot(); }
  }

  void vaporDome(string Fluid, int ns) {
    
    // Set working fluid
    FStemp.comp=Fluid;
    cout << "Debug: Fluid = " << FStemp.comp << endl;
    
    // Critical Point Properties
    real Pcrit = FStemp.Pcrit;
    cout << "Debug: Pcrit = " << Pcrit << endl;
    real Tcrit = FStemp.Tcrit;
    cout << "Debug: Tcrit = " << Tcrit << endl;
    FStemp.setTotalTP(Tcrit,Pcrit);
    real htcrit = FStemp.ht;
    cout << "Debug: htcrit = " << htcrit << endl;
    real scrit = FStemp.s;
    cout << "Debug: scrit = " << scrit << endl;
    real rhocrit = FStemp.rhot;
    cout << "Debug: rhocrit = " << rhocrit << endl;

    real x, p, h0, h1, s0, s1, T0, T1, rho0, rho1, dp;
    int n;

    // int ns;
    // ns = 3;

    // Header
    os_dome << "# Vapor Dome for  " << FStemp.comp << endl;
    os_dome << "# " << "n" << " " << "p" << " " << "p" << " " << "T0" << " " << "T1" << " " << "h0" << " " << "h1" << " " << "s0" << " " << "s1" << "rho0" << " " << "rho1" << endl;
    
    // sample spacing
    dp = (Pcrit - 1.)/(ns-1);
    cout << "Debug: dp = " << dp << endl;
    for (n=0; n<ns-1; n++) {
      p=1.0 + dp*n;
      // Saturated Liquid
      FStemp.setTotal_xP(0.0, p);
      // Check for case below tripple point, REFPROP.Ptp is not accessible in the flowstation
      if ( FStemp.TtSat > FStemp.TtMelt ) {
        h0 = FStemp.ht;
        s0 = FStemp.s;
        T0 = FStemp.Tt;
        rho0 = FStemp.rhot;
      } else {
        h0 = NaN;
        s0 = NaN;
        T0 = FStemp.Tt;
        rho0 = NaN;
      }
      // Saturated Vapor
      FStemp.setTotal_xP(1.0, p);
      h1 = FStemp.ht;
      s1 = FStemp.s;
      T1 = FStemp.Tt;
      rho1 = FStemp.rhot;

      os_dome << n << " " << p << " " << p << " " << T0 << " " << T1 << " " << h0 << " " << h1 << " " << s0 << " " << s1 << " " << rho0 << " " << rho1 << endl;
    }
    // Add Critical Point
    // os_dome << n << " " << Pcrit << " " << htcrit << " " << htcrit << " " << scrit << " " << scrit << endl;
    p = Pcrit;
    T0 = Tcrit;
    T1 = T0;
    h0 = htcrit;
    h1 = h0;
    s0 = scrit;
    s1 = s0;
    rho0 = rhocrit;
    rho1 = rho0;
    os_dome << n << " " << p << " " << p << " " << T0 << " " << T1 << " " << h0 << " " << h1 << " " << s0 << " " << s1 << " " << rho0 << " " << rho1 << endl;
          
  }

  void squarePh(string Fluid, real P0, real P1, int np, real h0, real h1, int nh ) {
    // Set working fluid
    FStemp.comp=Fluid;

    OutFileStream os_phblock  {filename = "contour.ph.data.dat"; }

    //
    real ldP, dh;
    ldP = (log10(P1) - log10(P0))/(np-1.);
    //real dP;
    //dP = (P1 - P0)/(np-1.);
    
    dh = (h1 - h0)/(nh-1.);

    int i, j;

    // Properties
    real x, Pt, ht, s, Tt, rhot;

    // Header
    os_phblock << "# property table for " << FStemp.comp << endl;
    os_phblock << "# ht" << " " << "Pt" << " " << "Tt" << " " << "s" << " " << "rhot" << endl;
    
    for ( i=0; i<nh; i++) {
      ht = h0 + dh*i;
      cout << ht << " " << h0 << " " << dh << " " << dh*j << endl;
      for (j=0; j<np; j++) {
	// log scale
	Pt = 10.0**(log10(P0) + ldP*j);
	//Pt = P0 + dP*j;
	//cout << Pt << " " << P0 << " " << dP << " " << dP*j << endl;
	//cout << Pt << " " << P0 << " " << ldP << " " << ldP*j << endl;
	
	FStemp.setTotal_hP(ht,Pt);

	// Check for case below tripple point, REFPROP.Ptp is not accessible in the flowstation
	if ( FStemp.TtSat > FStemp.TtMelt ) {
	  ht   = FStemp.ht;
	  s    = FStemp.s;
	  rhot = FStemp.rhot;
	  Tt   = FStemp.Tt;
	} else {
	  ht   = NaN;
	  s    = NaN;
	  rhot = NaN;
	  Tt   = FStemp.Tt;
	  
	}
	
	os_phblock << ht << " " << Pt << " " << Tt << " " << s << " " << rhot << endl;
      }
      os_phblock << endl;
    }

    OutFileStream os_tgns  {filename = "contour.ph.data.gns"; }
    
    os_tgns << "set contour" << endl;
    os_tgns << "unset surface" << endl;
    os_tgns << "set table 'contour.ph.Tt.dat'" << endl;
    os_tgns << "splot 'contour.ph.data.dat' u 1:2:3  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='Tt=' -v center=1 contour.ph.Tt.dat > contour.ph.Tt.labels" << endl;
    os_tgns << endl;
    os_tgns << "set table 'contour.ph.s.dat'" << endl;
    os_tgns << "splot 'contour.ph.data.dat' u 1:2:4  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='s=' -v center=1 contour.ph.s.dat > contour.ph.s.labels" << endl;
    os_tgns << endl;
    os_tgns << "set table 'contour.ph.rhot.dat'" << endl;
    os_tgns << "splot 'contour.ph.data.dat' u 1:2:5  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='rhot=' -v center=1 contour.ph.rhot.dat > contour.ph.rhot.labels" << endl;

    // TS Diagram
    os_tgns << "set table 'contour.ts.Pt.dat'" << endl;
    os_tgns << "splot 'contour.ph.data.dat' u 4:3:2  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='Pt=' -v center=1 contour.ts.Pt.dat > contour.ts.Pt.labels" << endl;
    os_tgns << endl;
    os_tgns << "set table 'contour.ts.h.dat'" << endl;
    os_tgns << "splot 'contour.ph.data.dat' u 4:3:1  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='h=' -v center=1 contour.ts.h.dat > contour.ts.h.labels" << endl;
    os_tgns << endl;
    os_tgns << "set table 'contour.ts.rhot.dat'" << endl;
    os_tgns << "splot 'contour.ph.data.dat' u 4:3:5  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='rhot=' -v center=1 contour.ts.rhot.dat > contour.ts.rhot.labels" << endl;

    if ( doRun ) {
      runGns( os_tgns.filename );
    }

  }

  void squareTs(string Fluid, real T0, real T1, int nt, real s0, real s1, int ns ) {
    // Set working fluid
    FStemp.comp=Fluid;

    OutFileStream os_tsblock  {filename = "contour.ts.data.dat"; }

    // Log Scale
    //real ldT;
    //ldT = (log10(T1) - log10(T0))/(nt-1.);
    real dT;
    dT = (T1 - T0)/(nt-1.);
    real ds;    
    ds = (s1 - s0)/(ns-1.);

    int i, j;

    // Properties
    real x, Pt, ht, s, Tt, rhot;

    // Header
    os_tsblock << "# property table for " << FStemp.comp << endl;
    os_tsblock << "# ht" << " " << "Pt" << " " << "Tt" << " " << "s" << " " << "rhot" << endl;
    
    for ( i=0; i<ns; i++) {
      s = s0 + ds*i;
      cout << ht << " " << s0 << " " << ds << " " << ds*j << endl;
      for (j=0; j<nt; j++) {
	// log scale
	//Tt = 10.0**(log10(T0) + ldT*j);
	Tt = T0 + dT*j;
	//cout << Tt << " " << T0 << " " << dT << " " << dT*j << endl;
	//cout << Tt << " " << T0 << " " << ldT << " " << ldT*j << endl;
	
	FStemp.setTotal_sT(s,Tt);

	// Check for case below tripple point, REFPROP.Ptp is not accessible in the flowstation
	if ( FStemp.TtSat > FStemp.TtMelt ) {
	  ht   = FStemp.ht;
	  s    = FStemp.s;
	  rhot = FStemp.rhot;
	  Pt   = FStemp.Pt;
	} else {
	  ht   = NaN;
	  s    = NaN;
	  rhot = NaN;
	  Pt   = FStemp.Pt;
	  
	}
	
	os_tsblock << ht << " " << Pt << " " << Tt << " " << s << " " << rhot << endl;
      }
      os_tsblock << endl;
    }

    OutFileStream os_tgns  {filename = "contour.ts.data.gns"; }
    
    os_tgns << "set contour" << endl;
    os_tgns << "unset surface" << endl;
    os_tgns << "set table 'contour.ts.Pt.dat'" << endl;
    os_tgns << "splot 'contour.ts.data.dat' u 4:3:2  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='Pt=' -v center=1 contour.ts.Pt.dat > contour.ts.Pt.labels" << endl;
    os_tgns << endl;
    os_tgns << "set table 'contour.ts.h.dat'" << endl;
    os_tgns << "splot 'contour.ts.data.dat' u 4:3:1  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='h=' -v center=1 contour.ts.s.dat > contour.ts.h.labels" << endl;
    os_tgns << endl;
    os_tgns << "set table 'contour.ts.rhot.dat'" << endl;
    os_tgns << "splot 'contour.ts.data.dat' u 4:3:5  w l" << endl;
    os_tgns << "unset table" << endl;
    os_tgns << "!./label_contours_v2.awk -v slabel='rhot=' -v center=1 contour.ts.rhot.dat > contour.ts.rhot.labels" << endl;

    if ( doRun ) {
      runGns( os_tgns.filename );
    }

  } 
  
  
}
#endif
