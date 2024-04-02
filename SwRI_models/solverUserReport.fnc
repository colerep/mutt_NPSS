string[] genDynList() {

    #include <queryFunctionsSwRI.fnc>

    void appendEntries() {
        int i, j;
        string n;
        for (i=0; i<oList.entries(); i++) {
            for (j=0; j<sList.entries(); j++) {
              n = oList[i] + "." + sList[j];
              if (exists(n)) {
                dynList.append(n);
              }
            }
        }
    }

    void appendVariable(string n) {
        if (exists(n)) {
            dynList.append(n);
        }
    }

    // outStreamHandle = "cout";
    // variableList = {};

    string dynList[] = { "CASE", "time", "solverReportCounter" };

    string oList[];
    string sList[];
    string sTemp[];

    oList = { "solver" };
    // oList = list("Solver",1);
    sList = { "converged", "iterationCounter", "passCounter", "numJacobians", "numBroydens" };
    appendEntries();


    // Solver Parameters
    // oList=solver.independentNames;
    // Capture all independents
    oList = .list("Independent",1);
    // sList = { "varName", "indepRef", "x" };
    sList = { "x" };
    appendEntries();

    // oList=solver.dependentNames;
    // Capture all dependents
    oList = .list("Dependent",1);
    //sList = { "eq_lhs", "y1", "eq_rhs", "y2", "eq_Ref", "tolerance", "toleranceType", "errorCon", "errorIter" };
    // sList = { "y1", "y2", "tolerance", "errorCon", "errorIter" };
    sList = { "errorCon" };
    appendEntries();

    // oList = {""};
    // sList = {"CASE", "solver.converged"};
    // sTemp = solver.independentNames;
    // for (i=0;i<sTemp.entries();i++) {
    //     sList.append(sTemp[i]+".x");
    // }   

    
    // FluidLinks
    oList = .list("Link",1,"exists(\"Tt\")==1");
    sList = {"Tt","Pt","ht","s","W","Cpt","gamt","rhot","W"};
    // if ( THERMPACKAGE == "REFPROP" ) { sList.append("xt"); }
    appendEntries();

    oList = .list("Port",1,"exists(\"Tt\")==1");
    sList = {"Tt","Pt","ht","s","W","Cpt","gamt","rhot","W"};
    // if ( THERMPACKAGE == "REFPROP" ) { sList.append("xt"); }
    appendEntries();




    // Load Element
    oList = .list("BleedOutPort",1,"exists(\"fracW\")==1");
    sList = { "fracW" }
    appendEntries();

    // Compressors and Turbines
    oList = .list("Compressor",1,"exists(\"PRdes\")==1");
    // sList = { "pwr", "trq", "PR", "PRdes", "Wc", "Nc", "eff", "effDes", "effPoly" };
    sList = { "pwr", "trq", "PR", "PRdes", "Wc", "Nc", "eff", "effDes", "effPoly", "effBase", "PRbase", "WcBase",
        "S_map.alphaMap", "S_map.alphaMapDes", "S_map.effMap", "S_map.effMapDes", "S_map.NcMap", "S_map.NcMapDes", "S_map.PRmap", "S_map.PRmapDes", "S_map.WcMap", "S_map.WcMapDes",
        "S_map.s_effDes", "S_map.s_effRe", "S_map.s_NcDes", "S_map.s_PRdes", "S_map.s_WcDes", "S_map.s_WcRe" };
    appendEntries();

    oList = .list("Turbine",1,"exists(\"PRdes\")==1");
    sList = { "pwr", "trq", "PR", "PRdes", "PRbase", "eff", "effDes", "Np", "Wp", "WpCalc", "S_map.effMap", "S_map.effMapDes", "S_map.NpMap", "S_map.NpMapDes", "S_map.PRmap", "S_map.PRmapDes", "S_map.WpMap", "S_map.WpMapDes", "S_map.s_effDes", "S_map.s_effRe", "S_map.s_NpDes", "S_map.s_PRdes", "S_map.s_WpDes", "S_map.s_WpRe" }
    appendEntries();

    oList = .list("TurbineSwRI2",1,"exists(\"PRdes\")==1");
    sList = { "pwr", "trq", "PR", "PRdes", "PRbase", "eff", "effDes", "Np", "Wp", "WpCalc", "S_map.effMap", "S_map.effMapDes", "S_map.NpMap", "S_map.NpMapDes", "S_map.PRmap", "S_map.PRmapDes", "S_map.WpMap", "S_map.WpMapDes", "S_map.s_effDes", "S_map.s_effRe", "S_map.s_NpDes", "S_map.s_PRdes", "S_map.s_WpDes", "S_map.s_WpRe" }
    appendEntries();


    oList = .list("SwRICompressor",1);
    sList = { "pwr", "trq", "PR", "PRdes", "alpha", "Qdotin", "Qdotin_map", "DP", "DPdes", "eff", "effDes", "isenEff", "isenEffDes", "polyEff", "polyEffDes", "polyEff_map", "polyHead", "polyHeadDes", "polyHead_map" };
    appendEntries();

    oList = .list("Compressor",1);
    sList = { "pwr", "trq", "PR", "PRdes", "alpha", "Qdotin", "Qdotin_map", "DP", "DPdes", "eff", "effDes", "isenEff", "isenEffDes", "polyEff", "polyEffDes", "polyEff_map", "polyHead", "polyHeadDes", "polyHead_map" };
    appendEntries();

    // Load Element
    oList = .list("Element",1,"exists(\"trqLoad\")==1");
    sList = { "pwr", "pwrLoad", "trq", "trqLoad", "Nload", "NR", "dTqT", "pwrDC" }
    appendEntries();

    // Shafts
    oList = .list("Shaft",1,"exists(\"pwrNet\")==1");
    sList = { "pwrIn", "pwrOut", "pwrNet", "trqIn", "trqOut", "trqNet", "Nmech" };
    appendEntries();

    // Heaters
    oList = .list("HeaterSwRI",1);
    sList = { "switchHeat", "coolerMode", "dT", "dTsat", "Q", "hout", "Tout", "x", "pwr" };
    appendEntries();

    // Duct
    oList = .list("Duct",1);
    sList = { "dP", "dPqP", "dPqP_in", "dPqP_dmd", "Q", "Q_in", "Q_dmd" };
    appendEntries();

    oList = .list("DuctSwRI",1);
    sList = { "dP", "dPqP", "dPqP_in", "dPqP_dmd", "Q", "Q_in", "Q_dmd" , "dP_in"};
    appendEntries();


    // // HeatExchangers
    // oList = .list("HeatExchanger",1);
    // sList = { "switchQcalc", "switchQ", "Q", "effect", "cap1", "cap2" };
    // appendEntries();

    // Wall{1,2,SwRI}
    oList = .list("Element",1,"exists(\"Ahx1\")==1");
    sList = { "Ahx1", "Ahx2", "Chx1", "Chx2", "ChxDes1", "ChxDes2", "CpMat", "Qhx1", "Qhx2", "approach_hot", "approach_cold", "LMDT", "TgasPath", "Tmat", "Wdes1", "Wdes2", "dTmatqdt", "effect", "expChx1", "expChx2", "kcDes1", "kcDes2", "massMat", "muDes1", "muDes2" };
    appendEntries();

    oList = .list("CounterHxSwRI",1);
    // sList = { "switchQcalc", "switchQ", "Q", "effect_Cp", "effect_h", "cap1", "cap2" };
    sList = { "switchQ", "switchApproachCalc",
              "effect_Cp", "effect_des", "effect_h",
              "cap1", "cap2", "capMin",
              "approach_des", "approach_hotOut", "approach_hotIn", "approach_min", "minDt",
              "Q_des", "Q", "Qmax1", "Qmax2", "Qmin_h" };
    appendEntries();

    oList = .list("Element",1,"exists(\"effect\")==1");
    sList = { "effect" };
    appendEntries();

    oList = .list("Element",1,"exists(\"effect_Cp\")==1");
    sList = { "effect_Cp" };
    appendEntries();

    oList = .list("Element",1,"exists(\"effect_h\")==1");
    sList = { "effect_h" };
    appendEntries();


    // Postprocessing
    oList = { "Perf" };
    sList = { "pwrNet", "pwrLoad", "Qin", "eff", "effLoad", "effC", "pctC" };
    appendEntries();

    // Postprocessing
    oList = { "PerfCycle", "PerfBlock", "PerfPlant" };
    sList = { "pwrNet", "pwrLoad", "Qin", "eff", "effLoad", "effC", "pctC" };
    appendEntries();

    // Postprocessing
    oList = { "Post" };
    sList = { "systemFluidMass", "systemFluidVol" };
    appendEntries();

    


    oList = .list("Element",1,"exists(\"s_Wp\")==1");
    sList = { "s_Wp" };
    appendEntries();    

    oList = .list("SubElement",1,"exists(\"s_Wp\")==1");
    sList = { "s_Wp" };
    appendEntries();    

    oList = .list("Element",1,"exists(\"s_Qdotin\")==1");
    sList = { "s_Qdotin" };
    appendEntries();

    oList = .list("Element",1,"exists(\"systemFluidVol\")==1");
    sList = { "systemFluidVol", "systemFluidMass" };
    appendEntries();

    // solver
    // oList = { "solver" };
    oList = .list("Solver",1);
    sList = { "converged", "iterationCounter", "passCounter", "numJacobians", "numBroydens", "solverReportCounter" };
    appendEntries();

    // Error Handler
    oList = { "errHandler" };
    sList = { "numErrors", "numWarnings", "numMessages" };
    appendEntries();

    // // Solver Parameters
    // // oList=solver.independentNames;
    // // Capture all independents
    // oList = .list("Independent",1);
    // // sList = { "varName", "indepRef", "x" };
    // sList = { "x" };
    // appendEntries();

    // // oList=solver.dependentNames;
    // // Capture all dependents
    // oList = .list("Dependent",1);
    // //sList = { "eq_lhs", "y1", "eq_rhs", "y2", "eq_Ref", "tolerance", "toleranceType", "errorCon", "errorIter" };
    // sList = { "y1", "y2", "tolerance", "errorCon", "errorIter" };
    // appendEntries();

    // scalars
    //dynList.append( "pctAcetone_in");

    // variableList = dynList;

    // cout << parent.getPathName() << endl;
    // cout << "dynList " << dynList << endl;
    // cout << "variableList " << variableList << endl;

    return dynList;
}

// string[] solverVari = genDynList();

CaseColumnViewer printSolverColumn {
    outStreamHandle = "os_printSolverColumn";
    // outStreamHandle = "cout";
    // variableList = printSolver.variableList;
    // Formatting
    defRealFormat = "?????.?????";
    defSNFormat   = "??.?????E????";
    caseHeaderBody = "";
    caseHeaderVars = {};
    // showHeaders = -1;
    // Include solutions with errors
    showErrors = 1;
    // Mark solutions with errors w/ + or *
    showMarks = 0;
    titleBody = "# " + titleBody;
}

if (exists("os_printSolverColumnSI")) {
    copy("printSolverColumn","printSolverColumnSI");
    printSolverColumnSI { 
        outStreamHandle = "os_printSolverColumnSI";
        // outStreamHandle = "cout";
        unitSystem = "SI";   
    }    
}

// CaseRowViewer printSolverRowSI {
//     outStreamHandle = "os_printSolverRowSI";
//     // Re-use the variable list
//     variableList = printSolver.variableList;
//     // Formatting
//     defRealFormat = "?????.?????";
//     defSNFormat   = "??.?????E????";
//     caseHeaderBody = "";
//     caseHeaderVars = {};
//     showErrors = 0;
//     showMarks = 0;
//     titleBody = "# " + titleBody;
//     unitSystem = "SI";
// }

CaseRowViewer printSolverRow {
    outStreamHandle = "os_printSolverRow";
    // outStreamHandle = "cout";
    // Re-use the variable list
    // variableList = printSolver.variableList;
    // Formatting
    defRealFormat = "?????.?????";
    defSNFormat   = "??.?????E????";
    caseHeaderBody = "";
    caseHeaderVars = {};
    showHeaders = -1;
    // Include solutions with errors
    showErrors = 1;
    // Mark solutions with errors w/ + or *
    showMarks = 0;
    titleBody = "# " + titleBody;
}

if (exists("os_printSolverRowSI")) {
    copy("printSolverRow","printSolverRowSI");
    printSolverRowSI { 
        outStreamHandle = "os_printSolverRowSI";
        // outStreamHandle = "cout";
        unitSystem = "SI";   
    }
}

// void updateVariableList() {

// }

int doPrintSI = 0;
int doPrintRow = 1;
int doPrintColumn = 0;

int solverReportCounter = 0;

void updateSolverVarList() {
    
    string varList[];
    varList = genDynList();
    // cout << varList << endl;

    int i;
    string tempStr[];

    // os_printSolverX.filename = caseDir+"/"+caseName+".x";
    os_printSolverX.reopen();
    tempStr = solver.independentNames;
    for (i=0; i<tempStr.entries(); i++) {
        os_printSolverX << tempStr[i] << " ";
    }
    os_printSolverX << endl;


    // os_printSolverErrorCon.filename = caseDir+"/"+caseName+".errorCon";
    os_printSolverErrorCon.reopen();
    tempStr = solver.dependentNames;
    for (i=0; i<tempStr.entries(); i++) {
        os_printSolverErrorCon << tempStr[i] << " ";
    }
    os_printSolverErrorCon << endl;


    if (exists("printSolverColumn"))    { printSolverColumn.variableList = varList; }
    if (exists("printSolverColumnSI"))  { printSolverColumnSI.variableList = varList; }

    if (exists("printSolverRow"))    { printSolverRow.variableList = varList; }
    if (exists("printSolverRowSI"))  { printSolverRowSI.variableList = varList; }

}

void userReport() {

    if (doSolverDebug) {
    
        solverReportCounter++;
    
        // updateSolverVarList();
    
        if (doPrintColumn) {
            printSolverColumn.update();
            printSolverColumn.display();
        }    
    
        if (doPrintRow) {
            printSolverRow.update();
            printSolverRow.display();
        }
    
        if (doPrintSI) {
            if (doPrintColumn) {
                printSolverColumnSI.update();
                printSolverColumnSI.display();
            }    
            
            if (doPrintRow) {
                printSolverRowSI.update();
                printSolverRowSI.display();
            }
        }
    }
}
