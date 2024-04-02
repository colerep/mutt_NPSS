
// I/O
// addUnitPref("R","K");
// addUnitPref("psia","MPa");
addUnitPref("R","C");
addUnitPref("dR","dC");
addUnitPref("psia","bar");
addUnitPref("hp","MW");
// addUnitPref("Btu","J");
addUnitPref("Btu/sec","MW");
addUnitPref("in2","m2");
addUnitPref("in","m");


//OutFileStream os_printClosedBrayton {filename = "cout"; }
OutFileStream os_debug {filename = caseDir+"/"+caseName+"_debug.out"; }
OutFileStream os_printColumn {filename = caseDir+"/"+caseName+"_column.out"; }
OutFileStream os_printColumnSI {filename = caseDir+"/"+caseName+"_columnSI.out"; }
OutFileStream os_printRow {filename = caseDir+"/"+caseName+"_row.out"; }
OutFileStream os_printRowSI {filename = caseDir+"/"+caseName+"_rowSI.out"; }

OutFileStream os_solver {filename = "solver.rpt"; }

#include <$MODEL_TOP/data/printVariables.view>;
#include <$MODEL_TOP/data/myReport.fnc>;
// #include <pageView.view>;

// OutFileStream os_printColumnGE {filename = caseDir+"/"+caseName+"_columnGE.out"; }
// OutFileStream os_printColumnGE_SI {filename = caseDir+"/"+caseName+"_columnGE_SI.out"; }
// OutFileStream os_printRowGE {filename = caseDir+"/"+caseName+"_rowGE.out"; }
// OutFileStream os_printRowGE_SI {filename = caseDir+"/"+caseName+"_rowGE_SI.out"; }

// #include <printClosedBraytonGE.view>;

//// Model Set Functions //// 
void updateColumnViewers() {
  cout << "printColumn.update();" << endl;
  printColumn.update();
  printColumnSI.update();
}

void updateRowViewers() {
  cout << "printRow.update();" << endl;
  printRow.update();
  printRowSI.update();
}

void updateViewers() {
  updateColumnViewers();
  updateRowViewers();
}


void displayColumnViewers() {
  cout << "printColumn.display();" << endl;
  printColumn.display();
  printColumnSI.display();
}

void displayRowViewers() {
  cout << "printRow.display();" << endl;
  printRow.display();
  printRowSI.display();
}

void displayViewers() {
  displayColumnViewers();
  displayRowViewers();
}


void dumpSolverIndep() {
  string solverList[];
  solverList = .list("Solver",1);
  int i;
  for (i=0;i<solverList.entries();i++) {
    cout << endl << "*** " << solverList[i] << endl;
    cout << solverList[i]->indepStats();
    cout << endl;
    cout << solverList[i]->depStats();
  }
}

void dumpSolverSettings() {
  string s[];
  s = .list("Solver",1);
  cout << "** Solvers: " << s << endl;
  int i;
  for (i=0;i<s.entries();i++) {
    cout << "** Solver " << s[i] << endl << endl;
    cout << s[i]+".independentNames: " << endl << s[i]->independentNames << endl;
    cout << s[i]+".dependentNames: " << endl << s[i]->dependentNames << endl;

    cout << s[i]+".preExecutionSequence: " << endl << s[i]->preExecutionSequence << endl;
    cout << s[i]+".executionSequence: " << endl << s[i]->executionSequence << endl;
    cout << s[i]+".postExecutionSequence: " << endl << s[i]->postExecutionSequence << endl;

  }
}

int isConverged() {
  int isC;
  isC = 1;
  cout << "Case " << CASE << " Solution finished, solver.converged = " << solver.converged << " iterationCounter = " << solver.iterationCounter << endl;
  string solverList[];
  solverList = .list("Solver",1);
  int i;
  cout << "Case " << CASE << " Solution finished" << endl;
  for (i=0;i<solverList.entries();i++) {
    cout << "\t" << solverList[i];
    cout << " converged = " << solverList[i]->converged;
    cout << " iterationCounter = " << solverList[i]->iterationCounter;
    cout << " passCounter = " << solverList[i]->passCounter << endl;
    isC *= solverList[i]->converged;
    }
  return isC;
}
