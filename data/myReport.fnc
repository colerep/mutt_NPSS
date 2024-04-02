void myReport() {
    // Reporting
    if ( 1 ) {
      #include <queryFunctionsSwRI.fnc>
      string sList[];
      string oList[];
      string sep = ",\r\n\t";
      string pre = "debug: ";

      int recur = 1;

      // Fluid Link Properties
      sep = ", ";
      oList = .list("Link",recur,"exists(\"Tt\")==1");
      sList = { "Tt", "Pt", "W" }
      if ( THERMPACKAGE == "REFPROP" ) {
        sList.append( "comp" );
        // sList.append( "compFluids" ); // needs to be stripped of "
        sList.append( "rhot" );
        sList.append( "xt" );
		//sList.append( "Xt" );
      }
      cout << printObjAttr( oList, sList, sep, pre );

      oList = .list("Port",1,"exists(\"Tt\")==1");
      sList = {"Tt","Pt","ht","W"};
      if ( THERMPACKAGE == "REFPROP" ) {
        sList.append( "comp" );
        // sList.append( "compFluids" ); // needs to be stripped of "
        sList.append( "rhot" );
        sList.append( "xt" );
      }
      cout << printObjAttr( oList, sList, sep, pre );

      // Compressor and Turbine Elements
      oList = .list("Element",recur,"exists(\"PRdes\")==1");
      sList = { "pwr", "trq", "PR", "PRdes" }
      cout << printObjAttr( oList, sList, sep, pre );

      // Heaters
      oList = .list("HeaterSwRI",1);
      sList = { "switchHeat", "dT", "dTsat", "Q", "hout", "Tout", "coolerMode", "Tamb", "pwr" };
      cout << printObjAttr( oList, sList, sep, pre );

      // HeatExchangers
      oList = .list("HeatExchanger",recur);
      sList = { "switchQcalc", "switchQ", "Q", "effect", "cap1", "cap2" };
      cout << printObjAttr( oList, sList, sep, pre );

      // HeatExchangers
      oList = .list("CounterHxSwRI",recur);
      sList = {
        "switchQ", "switchApproachCalc",
        "effect_Cp", "effect_des", "effect_h",
        "cap1", "cap2", "capMin",
        "approach_des", "approach_hotOut", "approach_hotIn", "approach_min", "minDt",
        "Q_des", "Q", "Qmax1", "Qmax2", "Qmin_h"
      };
	  
	  oList = .list("CounterHxSwRI_OD",1);
      sList = { 
	    "switchQ", "switchApproachCalc",
        "effect_Cp", "effect_des", "effect_h",
        "cap1", "cap2", "capMin",
        "approach_des", "approach_hotOut", "approach_hotIn", "approach_min", "minDt",
        "Q_des", "Q", "Qmax1", "Qmax2", "Qmin_h",
		"nNodes", "hAratio",
		"LMTD","UA","NTU"};
			  
			  
      cout << printObjAttr( oList, sList, sep, pre );

      // Shaft Element
      oList = .list("Element",recur,"exists(\"trqIn\")==1");
      sList = { "pwrIn", "pwrOut", "pwrNet", "trqIn", "trqOut", "trqNet" }
      cout << printObjAttr( oList, sList, sep, pre );

      // Performance Element
      oList = .list("Element",recur,"exists(\"effC\")==1");
      // sList = { "pwrNet", "Qin", "eff", "effC" }
      sList = { "pwrNet", "Qin", "Xt", "eff", "effC", "pctC", "eff2"};
      cout << printObjAttr( oList, sList, sep, pre );

      // solver
      oList = { "solver" };
      sList = { "converged", "iterationCounter", "passCounter" };
      cout << printObjAttr( oList, sList, sep, pre );

      // Error Handler
      oList = { "errHandler" };
      sList = { "numErrors", "numWarnings", "numMessages" };
      cout << printObjAttr( oList, sList, sep, pre );

      // Power Element
      oList = .list("Link",0,"exists(\"pwr\")");
      sList = { "pwr" }
      cout << printObjAttr( oList, sList, sep, pre );

    }
}

