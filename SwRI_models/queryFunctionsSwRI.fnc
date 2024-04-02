/* ******
Name: SwRIqueryFunctions

Version: 0.10
Date: 10/23/2014
Author: Aaron McClung <amcclung@swri.org>

Version: 0.11
Date: 09/18/2015
Author: Aaron McClung <amcclung@swri.org>

Description: Add listContains and listSearch

A set of functions to print or query model states

Usage:

To Do:

1. Expand documentation

****** */

#ifndef __queryFunctionsSwRI__
#define __queryFunctionsSwRI__

// Solver information
void printAttr( string Obj, string Attr[] ) {
  int i;
  string n;
  for ( i = 0; i < Attr.entries(); i++ ) {
    n = Obj + "." + Attr[i];
    if (exists(n)) {
      cout << n << " = " << evalExpr(n) << endl;
    } else {
      cout << n << " = " << "DNE" << endl;
    }
  }
}

// Solver information
string printObjAttr( string Obj[], string Attr[], string sep, string pre ) {
  string out;
  int o;
  int a;
  string n;
  string l;
  string v;

  // Initialize
  out = "";
  for ( o = 0; o < Obj.entries(); o++ ) {
    l = pre + Obj[o] + " {";
    for ( a = 0; a < Attr.entries(); a++ ) {
      n = Obj[o] + "." + Attr[a];
      v = "-";
      if (exists(n)) {
        v = toStr(evalExpr(n));
      } else {
        v = "DNE";
      }

      l = l + " " + Attr[a] + " = " + v + sep;
    }
    l += " }";
    out.append(l);
    out.append("\n");
  }
  return out;
}

// Solver information
string printObjAttrUnits( string Obj[], string Attr[], string Units[], string sep, string pre ) {
  string out;
  int o;
  int a;
  string n;
  string l;
  string v;

  // Initialize
  out = "";
  for ( o = 0; o < Obj.entries(); o++ ) {
    l = pre + Obj[o] + " {";
    for ( a = 0; a < Attr.entries(); a++ ) {
      n = Obj[o] + "." + Attr[a];
      v = "-";
      if (exists(n+".units")) {
        if ( (n->units == "none") || (n->units == "" ) ) {
          v = toStr(evalExpr(n));
        } else {
          v = toStr( convertUnits(n,Units[a]) );
        }
        // v+=" ["+Units[a]+"]";
      } else if (exists(n)) {
        v = toStr(evalExpr(n));
      } else {
        v = "DNE";
      }

      l = l + " " + Attr[a] + " = " + v + sep;
    }
    l += " }";
    out.append(l);
    out.append("\n");
  }
  return out;
}

int listContains( string thisList[], string target ) {
  int i;
  for (i=0; i<thisList.entries(); i++) {
    // cout << "Check" << thisList[i] << " " << target << endl;
    if ( thisList[i] == target ) {
      return 1;
    }
  }
  return 0;
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

void prettyPrintList( string thisList[] ) {
    int o;
    cout << "{" << endl;
    for ( o = 0; o < thisList.entries(); o++ ) {
        cout << "\t" << thisList[o] << "," << endl;
    }
    cout << "}" << endl;
}

#endif
