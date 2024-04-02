/*
  plot 'data2.dat' u 1:2:($3-$1):($4-$2) w vector, '' u ($3+$1)/2.:($4+$2)/2.:5 with labels offset char 2,char 2
*/

/* ******
   Name: stateDiagramSwRI
   Version: 0.10
   Date: 10/10/2014
   Author: Aaron McClung <amcclung@swri.org>

   Description:
   This function uses list to query the current model and generate state diagrams using gnuplot.

   Usage:


   ****** */

#ifndef __stateDiagramsSwRI__
#define __stateDiagramsSwRI__

// See user manual for how to utilize system calls.
#include <System.fnc>

VariableContainer stateDiagrams {

  // * Container Initialization * //

  // Temporary Flow Station used to query fluid properties
  FlowStation FStemp;
  // Default comp
  string comp="CO2";

  real Pcrit, Tref, Pref;

  void setComp(string comp) {
    parent.comp = comp;
    FStemp.comp = comp;
    Pcrit = 1069.9869;
    // cout << "Debug: Pcrit = " << Pcrit << endl;

    Tref = 77;
    Pref = 0.145038;
  }
  setComp(comp);

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
  string dataDir = "./";
  string domeDatFile = dataDir + comp + ".dome";
  string gnsFilesToRun[];

  // Add contours?
  int cPh = TRUE;
  int cTs = TRUE;

  // Runtime Options
  int VERBOSE = FALSE;
  int DEBUG = FALSE;

  // Define I/O Stream
  OutFileStream os_gns  {filename = gnsScript; }
  OutFileStream os_dat  {filename = elementDatFile; }
  OutFileStream os_dome {filename = domeDatFile; }

  int vaporDomeNs = 50;

  // List of elements to diagram
  string elist[];
  string alist[];

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
    // domeDatFile = casename + ".dome.dat";
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
      if (sys.fileExists(dataDir+comp+".PT.PhLabels")) {
	os_gns << "load '"<< dataDir+comp+".PT.PhLabels" << "'" << endl;
      }
      // Rho
      if (sys.fileExists(dataDir+comp+".PRho.PhLabels")) {
	os_gns << "load '"<< dataDir+comp+".PRho.labels" << "'" << endl;
      }
    }

    // Plot
    //os_gns << "plot '" << os_dat.filename << "u Pt:h:(column(Pt+1)-column(Pt)):(column(h+1)-column(h)) w vector" << "\n";
    //    os_gns << "plot '" << os_dat.filename << "' " << "u h:Pt:(column(h+1)-column(h)):(column(Pt+1)-column(Pt)) w vector title '', '' u (column(h+1)+column(h))/2.:(column(Pt+1)+column(Pt))/2.:1  with labels offset char 0,char 0 title ''" << "\n";

    os_gns << "plot \\" << endl;

    // Vapor Dome
    //cout << " check for " << dataDir+comp+".dome" << endl;
    if (sys.fileExists(dataDir+comp+".dome")) {
      os_gns << "\t'" << dataDir+comp+".dome" << "' " << "u 'hSatL':'PtSatL' w l lw 2 title 'Saturated Liquid', \\" <<  endl;
      os_gns << "\t'' " << "u 'hSatV':'PtSatV' w l lw 2 title 'Saturated Vapor'";
      os_gns << ", \\" << endl;
    }

    // Contour Lines
    // if (cPh) {
    //cout << " check for " << dataDir+comp+".PT.TsContour" << endl;
    if ( sys.fileExists(dataDir+comp+".PT.PhContour") ) {
      os_gns << "\t'" << dataDir+comp+".PT.PhContour" << "' u \"ht\":\"Pt\" w l title 'Tt'";
      os_gns << ", \\" << endl;
    }
    // if ( sys.fileExists("contour.ph.rhot.dat") ) {
    // os_gns << ", \\" << endl;
    // os_gns << "\t'contour.ph.rhot.dat' u 1:2 w l title 'Constant Rhot'";
    // }
    // }


    os_gns << "\t'" << os_dat.filename << "' " << "u h:Pt:(column(h+1)-column(h)):(column(Pt+1)-column(Pt)) w vector lw 2 lc 'red' title '', \\" << endl;
    os_gns << "\t'' u (column(h+1)+column(h))/2.:(column(Pt+1)+column(Pt))/2.:1  with labels offset char 1,char 1 title ''";

    os_gns << endl;

  }

  void createGnuplotTsDiagram() {
    os_gns << "Tt=4; s=8;" << "\n";
    os_gns << "set xlabel 'Entropy (" << evalExpr( elist[0]+".Fl_I.s.units") << ")'" << "\n";
    os_gns << "set ylabel 'Temperature (" << evalExpr( elist[0]+".Fl_I.Tt.units") << ")'" << "\n";
    //os_gns << "set log y" << "\n";

    // Contour Labels
    if (cTs) {
      if (sys.fileExists(dataDir+comp+".PT.TsLabels")) {
	os_gns << "load '"<< dataDir+comp+".PT.TsLabels" << "'" << endl;
      }
      // Rho
      if (sys.fileExists(dataDir+comp+".PRho.TsLabels")) {
	os_gns << "load '"<< dataDir+comp+".PRho.labels" << "'" << endl;
      }
    }


    // Plot
    os_gns << "plot \\" << endl;

    // Vapor Dome
    //cout << " check for " << dataDir+comp+".dome" << endl;
    if (sys.fileExists(dataDir+comp+".dome")) {
      os_gns << "\t'" << dataDir+comp+".dome" << "' " << "u 'sSatL':'TtSatL' w l lw 2 title 'Saturated Liquid', \\" <<  endl;
      os_gns << "\t'' " << "u 'sSatV':'TtSatV' w l lw 2 title 'Saturated Vapor'";
      os_gns << ", \\" << endl;
    }

    // Contour Lines
    if (cTs) {
      //cout << " check for " << dataDir+comp+".PT.TsContour" << endl;
      if ( sys.fileExists(dataDir+comp+".PT.TsContour") ) {
	os_gns << "\t'" << dataDir+comp+".PT.TsContour" << "' u \"s\":\"Tt\" w l title 'Pt'";
	os_gns << ", \\" << endl;
      }
    }

    os_gns << "\t'" << os_dat.filename << "' " << "u s:Tt:(column(s+1)-column(s)):(column(Tt+1)-column(Tt)) w vector lw 2 lc 'red' title '', \\" << endl;
    os_gns << "\t'' u (column(s+1)+column(s))/2.:(column(Tt+1)+column(Tt))/2.:1  with labels offset char 1,char 1 title ''";
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

  void removeAsm() {
    // cerr << "* Found Assemblies : " << alist << endl;
    int j;
    // cerr << "* elist : " << elist << endl;
    for (j=0;j<alist.entries();j++) {
      elist.remove(alist[j]);
    }
    // cerr << "* elist : " << elist << endl;
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
    // if (comp.length() > 0) {
    //   vaporDome(comp,vaporDomeNs);
    // }

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

  void vaporDome(string comp, int ns) {

    os_dome.filename = dataDir+comp+".dome";
    // Set working fluid
    FStemp.comp=comp;
    // cout << "Debug: comp = " << FStemp.comp << endl;

    // Reference properties

    // Critical Point Properties
    real Pcrit, Tcrit, hCrit, Tref;
    Pcrit = FStemp.Pcrit;
    Tcrit = FStemp.Tcrit;
    hCrit = FStemp.hCrit;
    cout << "Debug: Tcrit, Pcrit, hCrit = " << Tcrit << ", " << Pcrit << "," << hCrit << endl;

    Tref = FStemp.Tref;
    FStemp.setTotalTP(Tref,Pcrit);

    // Vapor and liquid dome properties
    real x, Pt, Tt, hSatL, hSatV, sSatL, sSatV, TtSatL, TtSatV, rhoSatL, rhoSatV, dp;
    int n;

    // int ns;
    // ns = 3;

    // Header
    os_dome << "# Vapor Dome for  " << FStemp.comp << endl;
    os_dome << "n" << " PtSatL" << " PtSatV" << " TtSatL" << " TtSatV" << " hSatL" << " hSatV" << " sSatL" << " sSatV" << " rhoSatL" << " rhoSatV" << endl;

    // sample spacing // 1e-3 is added so refprop will resolve L and V properties just below critical point.
    dp = (Pcrit - 1e-3 - FStemp.Pref)/(ns-1);
    Tref = FStemp.Tref;
    cout << "Debug: dp = " << dp << endl;
    errHandler.clear();
    for (n=0; n<ns; n++) {
      Pt=FStemp.Pref + dp*n;

      // Set conditions to Pt and Tref, use build in functions to find properties at SatL_Pt and SatV_Pt
      FStemp.setTotalTP(Tref,Pt);

      // Saturated Liquid
      // Check for case below tripple point, REFPROP.Ptp is not accessible in the flowstation
      //if ( FStemp.TtSat > FStemp.TtMelt ) {
      //cout << "Debug: Pt, FStemp.TtSat, FStemp.TtMelt " << Pt << ", " << FStemp.TtSat << ", " << FStemp.TtMelt << endl;
      cout << "Debug: Pt, FStemp.TtSat " << Pt << ", " << FStemp.TtSat << endl;
      FStemp.setTotalTP(Tref,Pt);
      hSatL = FStemp.hSatL_Pt;
      sSatL = FStemp.sSatL_Pt;
      rhoSatL = FStemp.rhoSatL_Pt;

      FStemp.setTotal_hP(hSatL,Pt);
      TtSatL = FStemp.Tt;

      // // Check Warnings/Errors for REFPROP convergence errors & discard the point
      // cout << "satL " << errHandler.getESIs() << endl;
      // if ( ( errHandler.numWarnings > 0 ) || ( errHandler.numErrors > 0 ) ) {
      // 	hSatL = NaN;
      // 	sSatL = NaN;
      //   TtSatL = NaN;
      // 	rhoSatL = NaN;
      // 	errHandler.clear();
      // }

      // Saturated Vapor
      FStemp.setTotalTP(Tref,Pt);
      hSatV = FStemp.hSatV_Pt;
      sSatV = FStemp.sSatV_Pt;
      rhoSatV = FStemp.rhoSatV_Pt;

      FStemp.setTotal_hP(hSatV,Pt);
      TtSatV = FStemp.TtSat;

      // // Check Warnings/Errors for REFPROP convergence errors & discard the point
      // cout << "satV " << errHandler.getESIs() << endl;
      // if ( ( errHandler.numWarnings > 0 ) || ( errHandler.numErrors > 0 ) ) {
      // 	hSatV = NaN;
      // 	sSatV = NaN;
      //   TtSatV = NaN;
      // 	rhoSatV = NaN;
      // 	errHandler.clear();
      // }

      if ( ( errHandler.numWarnings == 0 ) && ( errHandler.numErrors == 0 ) ) {
	os_dome << n << " " << Pt << " " << Pt << " " << TtSatL << " " << TtSatV << " " << hSatL << " " << hSatV << " " << sSatL << " " << sSatV << " " << rhoSatL << " " << rhoSatV << endl;
      }
      errHandler.clear();

    }

  }

  void PhContourPT(string comp, real Pt_sweep[], real Tt_sweep[] ) {
    // Set working fluid
    FStemp.comp=comp;

    OutFileStream os_phblock;
    os_phblock.filename = dataDir+comp+".PT.PhContour";
    OutFileStream os_phlabel;
    os_phlabel.filename = dataDir+comp+".PT.PhLabels";

    real dP;
    real dT;

    int i, j;

    // Properties
    real x, Pt, ht, s, Tt, rhot, PtSat, xt;

    // Header
    os_phblock << "# property table for " << FStemp.comp << endl;
    os_phblock << "ht" << " Pt" << " Tt" << " s" << " rhot" << " xt" << endl;

    for ( i=0; i<Tt_sweep.entries(); i++) {
      Tt = Tt_sweep[i];
      // cout << Tt << " " << T0 << " " << dT << " " << dT*j << endl;
      for (j=0; j<Pt_sweep.entries(); j++) {
	Pt = Pt_sweep[j];
	if ( j< Pt_sweep.entries()-1) {
	  dP = Pt_sweep[j+1] - Pt_sweep[j];
	}

        //FStemp.setTotal_hP(ht,Pt);

	// Set pressure, reference temperaure
	FStemp.setTotalTP(Tt,Pref);

        // Check for case below tripple point, REFPROP.Ptp is not accessible in the flowstation
        if ( Pt < FStemp.PtMelt ) {
	  FStemp.setTotalTP(Tt,Pt);
	  ht   = FStemp.ht;
	  s    = FStemp.s;
	  rhot = FStemp.rhot;
	  Tt   = FStemp.Tt;
	  xt   = FStemp.xt;
	  if ( ht != NaN ) {
	    os_phblock << ht << " " << Pt << " " << Tt << " " << s << " " << rhot << " " << xt << endl;
	  }

	  //
	  if ( (Tt < FStemp.Tcrit) && ( Pt < FStemp.Pcrit )) {
	    // Will we step across the dome?
	    if ( ( Pt < FStemp.PtSat ) && ( Pt+dP > FStemp.PtSat ) ) {
	      PtSat = FStemp.PtSat;
	      // saturated vapor
	      FStemp.setTotal_xP(1.0,PtSat);
	      ht   = FStemp.ht;
	      s    = FStemp.s;
	      rhot = FStemp.rhot;
	      Tt   = FStemp.Tt;
	      xt   = FStemp.xt;
	      os_phblock << ht << " " << PtSat << " " << Tt << " " << s << " " << rhot << " " << xt << endl;

	      // saturated liquid
	      FStemp.setTotal_xP(0.0,PtSat);
	      ht   = FStemp.ht;
	      s    = FStemp.s;
	      rhot = FStemp.rhot;
	      Tt   = FStemp.Tt;
	      xt   = FStemp.xt;
	      os_phblock << ht << " " << PtSat << " " << Tt << " " << s << " " << rhot << " " << xt << endl;
	    }
	  }
        }
      }
      os_phblock << endl;
      os_phlabel << "set label " << " \"" << Tt << "\" at " << ht << "," << Pt << " rotate by 90" << endl;
    }
  }


  void TsContourPT(string comp, real Pt_sweep[], real Tt_sweep[] ) {
    // Set working fluid
    FStemp.comp=comp;

    OutFileStream os_phblock;
    os_phblock.filename = dataDir+comp+".PT.TsContour";
    OutFileStream os_tslabel;
    os_tslabel.filename = dataDir+comp+".PT.TsLabels";

    real dT;

    int i, j;

    // Properties
    real x, Pt, ht, s, Tt, rhot, PtSat, TtSat, xt;

    // Header
    os_phblock << "# property table for " << FStemp.comp << endl;
    os_phblock << "ht" << " Pt" << " Tt" << " s" << " rhot" << " xt" << endl;

    for (j=0; j<Pt_sweep.entries(); j++) {

      Pt = Pt_sweep[j];

      // cout << "Pt " << Pt << " " << j << endl;

      for ( i=0; i<Tt_sweep.entries(); i++) {

	Tt = Tt_sweep[i];
	if ( i< Tt_sweep.entries()-1) {
	  dT = Tt_sweep[i+1] - Tt_sweep[i];
	}
	// cout << "Tt " << Tt << " " << i << endl;

	//FStemp.setTotal_hP(ht,Pt);
	FStemp.setTotalTP( Tt, Pref );

	// Check for case below tripple point, REFPROP.Ptp is not accessible in the flowstation
	if ( Pt < FStemp.PtMelt ) {
	  FStemp.setTotalTP(Tt,Pt);
	  ht   = FStemp.ht;
	  s    = FStemp.s;
	  rhot = FStemp.rhot;
	  Tt   = FStemp.Tt;
	  xt   = FStemp.xt;
	  if ( ht != NaN ) {
	    os_phblock << ht << " " << Pt << " " << Tt << " " << s << " " << rhot << " " << xt << endl;
	  }

	  //
	  if ( (Tt < FStemp.Tcrit) && ( Pt < FStemp.Pcrit )) {
	    if ( ( Tt < FStemp.TtSat ) && ( Tt+dT > FStemp.TtSat ) ) {
	      TtSat = FStemp.TtSat;
	      // saturated liquid
	      FStemp.setTotal_xT(0.0,TtSat);
	      ht   = FStemp.ht;
	      s    = FStemp.s;
	      rhot = FStemp.rhot;
	      Pt   = FStemp.Pt;
	      xt   = FStemp.xt;
	      os_phblock << ht << " " << Pt << " " << TtSat << " " << s << " " << rhot << " " << xt << endl;

	      // saturated vapor
	      FStemp.setTotal_xT(1.0,TtSat);
	      ht   = FStemp.ht;
	      s    = FStemp.s;
	      rhot = FStemp.rhot;
	      Pt   = FStemp.Pt;
	      xt   = FStemp.xt;
	      os_phblock << ht << " " << Pt << " " << TtSat << " " << s << " " << rhot << " " << xt << endl;
	    }
	  }
	}
      }
      os_phblock << endl;
      os_tslabel << "set label " << " \"" << Pt << "\" at " << s << "," << Tt << " rotate by 90" << endl;

    }

    /*
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
    */

  }


  void squarePh(string comp, real P0, real P1, int np, real h0, real h1, int nh ) {
    // Set working fluid
    FStemp.comp=comp;

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
    os_phblock << "# ht" << " Pt" << " Tt" << " s" << " rhot" << endl;

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

  void squareTs(string comp, real T0, real T1, int nt, real s0, real s1, int ns ) {
    // Set working fluid
    FStemp.comp=comp;

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
    os_tsblock << "# ht" << " Pt" << " Tt" << " s" << " rhot" << endl;

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
