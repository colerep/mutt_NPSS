/* ******
Name: parseTable
Version: 0.01
Date: 10/2015
Author: Aaron McClung <amcclung@swri.org>


Disclaimer:
Standard disclaimers for a work in progress.

Description: 
This script will parse a table (or set of tables) and return a string in the following format

"iVar1Name iVar2Name iVarNName dVar1Name dVar2Name ... dVarNName
iVar1[1]  iVar2[1]  iVarN[1]  dVar1[1]  dVar2[1]  ... dVarN[1]
iVar1[1]  iVar2[1]  iVar3[2]  dVar1[2]  dVar2[2]  ... dVarN[2]
iVar1[1]  iVar2[1]  iVar3[3]  dVar1[3]  dVar2[3]  ... dVarN[3]

iVar1[1]  iVar2[2]  iVarN[1]  dVar1[1]  dVar2[1]  ... dVarN[1]
iVar1[1]  iVar2[2]  iVar3[2]  dVar1[2]  dVar2[2]  ... dVarN[2]
iVar1[1]  iVar2[2]  iVar3[3]  dVar1[3]  dVar2[3]  ... dVarN[3]

iVar1[1]  iVar2[3]  iVarN[1]  dVar1[1]  dVar2[1]  ... dVarN[1]
iVar1[1]  iVar2[3]  iVar3[2]  dVar1[2]  dVar2[2]  ... dVarN[2]
iVar1[1]  iVar2[3]  iVar3[3]  dVar1[3]  dVar2[3]  ... dVarN[3]


iVar1[2]  iVar2[1]  iVarN[1]  dVar1[1]  dVar2[1]  ... dVarN[1]
iVar1[2]  iVar2[1]  iVar3[2]  dVar1[2]  dVar2[2]  ... dVarN[2]
iVar1[2]  iVar2[1]  iVar3[3]  dVar1[3]  dVar2[3]  ... dVarN[3]

iVar1[1]  iVar2[2]  iVarN[1]  dVar1[1]  dVar2[1]  ... dVarN[1]
iVar1[1]  iVar2[2]  iVar3[2]  dVar1[2]  dVar2[2]  ... dVarN[2]
iVar1[1]  iVar2[2]  iVar3[3]  dVar1[3]  dVar2[3]  ... dVarN[3]

iVar1[1]  iVar2[3]  iVarN[1]  dVar1[1]  dVar2[1]  ... dVarN[1]
iVar1[1]  iVar2[3]  iVar3[2]  dVar1[2]  dVar2[2]  ... dVarN[2]
iVar1[1]  iVar2[3]  iVar3[3]  dVar1[3]  dVar2[3]  ... dVarN[3]
"

This output format can be plotted as lines or surfaces using GnuPlot. If the data is not square, gnuplot will default to lines, if the data is square it will plot a surface. 

See http://www.gnuplot.info/ for details and usage. 


set contour
splot 'filename.dat' index 0 u "dVar1Name":"dVar2Name":"dVar3Name" lc "#BBBBBB" lt 2 w l t ""


Capabilities:


Usage:

 
****** */

#ifndef __parseTable__
#define __parseTable__

VariableContainer parseTable {

    int listContains( string thisList[], string target ) {
      int i;
      for (i=0; i<thisList.entries(); i++) {
        // cout << "Check" << thisList[i] << " " << target << endl;
        if ( thisList[i] == target ) {
          return i;
        }
      }
      return -1;
    }

    string[] listSearch( string thisList[], string target ) {
      int i;
      string out[] = {};
      string s;
      for (i=0; i<thisList.entries(); i++) {
        
        s = thisList[i];
        if ( s.index(target) > -1 ) {
            out.append(thisList[i]);
        }
      }
      return out;
    }

    // Assume all the tables have the same independent variables
    string parseTables( string tableNames[] ) {
        
        // Return string
        string outStr;
        
        // text representation of table using display()
        string tableStr;
        
        // split table string by \n
        string tableList[];
        
        // List of names
        string independentNames[];
        int independentTables[];
        int nInd;
        string dependentNames[];
        int dependentTables[];
        int nDep;
        
        // variables contained in the table
        string varList[];
        
        // Temps
        string line;
        string strTemp, evalStr;
        string sTemp[] = {};
        int i, j, k;
        real val;
        
        //string tableName;
        
        // Loop over tables
        for (k=0; k<tableNames.entries(); k++) {
            
            //tableName = tableNames[k];
            
            // get and declare Independent Variables
            sTemp = tableNames[k]->getIndependentNames();
            for (j=0;j<sTemp.entries();j++) {
                // Add independents if not already in list
                if ( listContains( independentNames, sTemp[j] ) < 0 ) {
                    independentNames.append(sTemp[j]);
                    independentTables.append(k);
                }
            }
            
            
            // get and declare Dependent Variables
            sTemp = tableNames[k]->getDependentNames();
            for (j=0;j<sTemp.entries();j++) {
                // Add dependents
                // Add independents if not already in list
                if ( listContains( dependentNames, sTemp[j] ) < 0 ) {
                    dependentNames.append(sTemp[j]);
                    dependentTables.append(k);
                }
            }
            
        }
        
        nInd = independentNames.entries();
        nDep = dependentNames.entries();
        
        // Declare a local variable of the same name as the independents, type real[]
        for (i=0; i<independentNames.entries(); i++) {
            // Assume real variables
            create("Variable","real[]", independentNames[i]);
            varList.append(independentNames[i]);
        }
        
        // Declare a local variable of the same name as the dependents, type real[]
        for (i=0; i<dependentNames.entries(); i++) {
            // Assume real variables
            create("Variable","real[]", dependentNames[i]);
            varList.append(dependentNames[i]);
        }
            
        // Debug
        // cout << "independentNames: " << independentNames << endl;
        // cout << "independentTables: " << independentTables << endl;
        
        // Debug
        // cout << "dependentNames: " << dependentNames << endl;
        // cout << "dependentTables: " << dependentTables << endl;
        
        // Output Header
        
        // List of variables
        outStr = "";
        // concatanate independent names
        for (i=0; i<independentNames.entries(); i++ ) {
            outStr.append(independentNames[i] + " ");
        }
        // concatanate dependent names
        for (i=0; i<dependentNames.entries(); i++ ) {
            outStr.append(dependentNames[i] + " ");
        }
        outStr.append("\n");
        
        // Debug
        // cout << "outStr: " << outStr << endl;
        
            
        // Get Table representation for first table
        tableStr = tableNames[0]->display();
        
        // Split on new lines
        tableList = tableStr.split("\n");
        // Debug
        // cout << " tableList: " << tableList << endl;

        int braceCount = 0;
        // Debug
        // cout << "braceCount: " << braceCount << endl;
        
        // parse over table and sub-tables
        for (i=1; i<tableList.entries(); i++) {
            
            // grab the current line in a temporary variable
            line = tableList[i];
            // Debug
            // cout << "line: " << line << endl;
            // check for a {
            if ( line.index("{") > -1 ) {
                // Increment counter for started entry
                braceCount++;
                // Debug
                // cout << "braceCount: " << braceCount << endl;
                // check for a }
                if ( line.index("}") > -1 ) {
                    // We have a complete independent or dependent variable in the format: X = { 1, 2, 3 }
                    
                    // decrement counter for a complete entry
                    braceCount--;
                    // Debug
                    // cout << "braceCount: " << braceCount << endl;
                    
                    // Debug
                    // cout << "parseString: " << line << endl;
                    
                    // Evaluate the line
                    parseString(line);
                } else if ( line.index("=") > -1 ) {
                    // we have a partial independent variable: X = 1 {
                    
                    // Modify for evaluation
                    evalStr = line;
                    while ( evalStr.index(" ") > -1 ) {
                        evalStr.replace(" ","");
                    }
                    evalStr.replace("{",");");
                    evalStr.replace("=",".append(");
                    
                    // Debug
                    // cout << "parseString: " << evalStr << endl;
                    
                    // Evaluate the modified line
                    parseString(evalStr);
                }
            } else if ( line.index("}") > -1 ) {
                // cout << " Close Brace, " << braceCount << " " << nInd-1 << endl;
                // Append block (sub-table) to outStr
                if ( braceCount == nInd-1 ) {
                    // cout << " Print Subtable " << endl;
                    // Loop over the length of the last dependent
                    for (k=0; k<dependentNames[0]->entries(); k++) {
                        
                        // query another table based on independent values
                        //evalStr = tableNames[dependentTables[j]];
                        //evalStr.append("( ");
                        evalStr = "( ";
                    
                        // print last value for 0 to n-1 independents
                        for (j=0;j<nInd-1;j++) {
                            outStr.append( toStr( independentNames[j]->getMember(independentNames[j]->entries()-1) ) + ", " );
                            evalStr.append( toStr( independentNames[j]->getMember(independentNames[j]->entries()-1) ) + ", " );
                            
                        }
                        
                        // the n'th independent is an array of same length as the dependent variables
                        // print the k'th member for the last independent array
                        outStr.append( toStr( independentNames[nInd-1]->getMember(k) ) + ", " );
                        evalStr.append( toStr( independentNames[nInd-1]->getMember(k) ) + " )");
                        
                        // print the k'th member for the dependent arrays
                        for (j=0;j<nDep;j++) {
                            if ( dependentTables[j] == 0 ) {
                                outStr.append( toStr( dependentNames[j]->getMember(k) ) + ", " );
                            } else {
                                
                                // cout << "evalStr: " << tableNames[dependentTables[j]] + evalStr << endl;
                                val = evalExpr( tableNames[dependentTables[j]] + evalStr );
                                outStr.append( toStr(val) + ", " );
                            }
                            
                        }
                        
                        // end of line
                        outStr.append("\n");
                    }
                    // end of block
                    outStr.append("\n");
                } else {
                    // end of Index
                    outStr.append("\n");
                }
                
                // decrement counter for a complete entry
                braceCount--;
                // Debug
                // cout << "braceCount: " << braceCount << endl;
                
                
            }
            
            
                    
        }
        
        // Debug
        // cout << "outStr: " << outStr << endl;
        
        /*
        cout << "varList: " << varList << endl;
        for (i=0; i<varList.entries(); i++) {
            cout << varList[i] << ": " << varList[i]->value << endl;
        }
        */
        
        // cout << "Declared variables: " << list("Variable",0) << endl;
        return outStr;
    }

}
