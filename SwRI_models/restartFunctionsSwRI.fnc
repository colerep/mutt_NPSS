//-----------------------------------------------------------------------------
//  Filename:   restartFunctionsSwRI.fnc
//  Author:     Aaron McClung
//  Version:    0.1
//  Date:       2015.10.26
// 
//  Description: 
//      Functions to save and reload the active independent variables.
//      Typically used to minimize waiting for the model to solve while 
//      doing model development, or to restart the model from a known 
//      previous solution. 
//      
//  Revisions:
//      v0.1 2015.10.26
//      - Initial version compiled 
//---------------------------------------------------------------------------

#ifndef __RESTARTFUNCTIONS_SwRI__
#define __RESTARTFUNCTIONS_SwRI__

// See user manual for how to utilize system calls.
#include <InterpIncludes.ncp>
#include <System.fnc>

VariableContainer Restart {

    string restartFile = "restart.dat";
    // restartFile = "cout";

	// Define I/O Stream
	OutFileStream os_restart {filename = restartFile; }
		
    // Save independent variables
    void saveSolverIndependents( string thisSolver ) {

        //os_restart.filename=thisSolver+".restart";
        string strList[] = thisSolver->independentNames;
        int i;
        
        for (i=0;i<strList.entries();i++) {
            os_restart << toStr(strList[i]->varName)->getPathName() << " = " << strList[i]->x << ";" << endl;
        }
        os_restart.close();
    }

    void saveIndependents( string restartFile ) {

		os_restart.filename = restartFile;
        os_restart.precision = 20;
    
        // save all independent variable values from the top level
        string indList[];
        string varName, parVarName;
        
        indList = .list("Independent");
        
        /*
        // Information and debug
        for (i=0; i<indList.entries(); i++) {
            varName = indList[i]->varName;
            parVarName = indList[i]->getParentName() + "." + varName;
            cout << indList[i] << " " << varName << " " << exists(varName) << " " << parVarName << " " << exists(parVarName) << " " << parVarName->value << endl;
        }
        */
        
        os_restart << "// " << USER << " " << VERSION << " " << date << " " << timeOfDay << endl;
        os_restart << "// CASE = " << CASE << endl;
        
        string outName;
        real outValue;
        int i;
        for (i=0; i<indList.entries(); i++) {
            outName = "";
            varName = indList[i]->varName;
            parVarName = indList[i]->getParentName() + "." + varName;
            
            if ( exists( indList[i]->getParentName() + "." + varName ) ) {
                // Check for variable independent/dependent level
                outName = indList[i]->getParentName() + "." + varName;
            } else if ( exists( (indList[i]->getParentName())->getParentName() + "." + varName ) ) {
                outName = (indList[i]->getParentName())->getParentName() + "." + varName;
            } else if ( exists( varName ) ) {
                outName = varName;
            } else {
                cout << "//Warning: " << varName << " in " << indList[i] << " can not be resolved" << endl;
            }
            
            if ( exists( outName+".value" ) ) {
                os_restart << outName << " = " << outName->value << ";" ;
            } else {
                os_restart << " // " << outName << " = " << toStr(outName) << ";" ;
            }
            os_restart << " // " << indList[i] << " " << varName << endl;
        
        }
        os_restart.close();
    }
    
    int loadIndependents( string restartFile ) {
        if ( sys.fileExists( restartFile ) ) {
            parseFile(restartFile);
            return 1;
        } else {
			cout << "WARNING: Restart file \"" << restartFile << "\" not Found" << endl;
		}
        return 0;
    }
}

int saveIndependents( string restartFile ) {
    Restart.saveIndependents( restartFile );
    return 1;
}

int loadIndependents( string restartFile ) {
    return Restart.loadIndependents( restartFile );
}
#endif