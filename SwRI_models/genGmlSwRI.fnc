/* ******
Name: genGmlSwRI
Version: 0.12
Date: 10/2015
Author: Aaron McClung <amcclung@swri.org>


Disclaimer:
This is a work in progress and IT MAY NOT SHOW THE COMPLETE MODEL. This script can only the parts of the model which it knows how to show. See Capabilities below for more details.


Description:
This script uses the NPSS list function to query the current model and generates a network diagram. The output is a network graph using Graph Modeling Language (GML).

For information on the GML dialect used, see: http://docs.yworks.com/yfiles/doc/developers-guide/gml.html

The current usage or work flow is to (1) create the GML file by running your model with this script loaded, (2) load the GML into yEd ( https://www.yworks.com/en/products/yfiles/yed/ ), (3) use the Hierarchical layout to arrange the model visualization, (4) manually edit the visualization as required, and (5) export the visualization to a png or pdf.

To maintain grouping within elements and assemblies, select grouping, and choose "Layout Groups" for Layering Strategy in the Hierarchical layout dialog.

Alternate GML parsers are available, but have not been tested with this script.


Capabilities:
This script can accommodate the following objects:

1. Assemblies
    a. Aliased FluidPort links
2. Elements
    a. Ports
3. Fluid/Fuel/Shaft Links
4. Solvers
    a. Solver Independent Variables (at any level)
    b. Solver Dependent Variables (at any level)


Verbosity:
The variable VERBOSE can be used to control the level of detail in the GML output. The following verbosity levels include:

0. Base:
    * Assemblies,
    * Solvers,
    * Elements,
    * Sub-elements,
    * Ports (within elements),
    * Internal and external links between ports
1. Add:
    * Selected variable output in Links
2. Add:
    * Selected variable output in Elements and Solvers
3. Add:
    * Tables
4. Add:
    * Independent and Dependent Variables
    * Links to active Solver independent and dependent variables
    * Additional variable output in Solvers

The higher the verbosity, the more information is provided, and the more "interpretation" may be required to follow the model layout.

Usage:
The following code snippet will create a diagram for the 4 defined verbosity levels. Output will be case.XXXXXX.Y.gml where X=CASE and Y=VERBOSE.

If included at the end of the run, it will generate 4 files representing the last case. If the "Generate GML diagram" section is included inside a run loop, it will generate 4 files for each CASE evaluated.

// ---- START SNIPPET ---- //

// Configure Flow Network Diagram
#define GENGML 1
#include <SwRIgenGML.v11.fnc>

// Generate GML diagram
if ( $GENGML ) {
    int i;
    for (i=0; i<5; i++) {
        gml.VERBOSE = i; // 0 = Do not print variable list, 1 = Print variable list
        gml.setGmlFile( strFmt("case.%06d.%01d.gml", CASE, gml.VERBOSE) );
        gml.genVerboseGml( gml.VERBOSE );

        // close output stream
        gml.os_gml.close();
    }
}
// ----  END  SNIPPET ---- //

****** */

#ifndef __GENGML__
#define __GENGML__

// See user manual for how to utilize system calls.
#include <InterpIncludes.ncp>
#include <System.fnc>


VariableContainer gml {

  Option switchUnits {
    allowedValues = { "US", "SI" };
  }

  string VERSION = "gml_v12";

  string gmlFile = "case.gml";
  int VERBOSE = FALSE;
  int DEBUG = TRUE;

  int tLevel = 0;


  void variableChanged( string name, any oldVal ) {

    if ( name == "switchUnits") {
      if ( switchUnits == "LHS" ) {
        unitPref.toSI = 0;
      } else {
        unitPref.toSI = 1;
      }
    }
  }


  VariableContainer elemAttr {

    // To add attributes for reporting, create a sring array in the following format:
    // sring _Elementtype[] = { "attr1", "attr2", ..., "attrN" };

    string _Assembly[];
    string _Bleed[] = { "Qhx", "Wref", "WrefName" };
    string _Burner[] = { "Qhx", "Wfuel", "WfuelError", "dPqP", "eff",  "switchBurn" };
    string _Compressor[] = { "PR", "PRdes", "PRbase", "eff", "effDes", "effBase", "Wc", "Nc", "pwr", "trq" };
    string _Duct[] = { "dP", "dPqP", "dPqP_dmd", "Q", "Q_dmd", "switchDP","switchQ" };
    string _FlowStartEnd[] = { "Tt", "Pt", "W", "ht", "switchSolveSet" };
    string _Table[] = { "getIndependentNames()", "getDependentNames()", "a_rtn", "s_rtn", "printExtrap", "extrapHighIsError", "extrapIsError", "extrapLowIsError" };
    string _Turbine[] = { "PR", "PRdes", "PRbase", "eff", "effDes", "effBase", "Wp", "Np", "pwr", "trq" };
    string _Shaft[] = { "Nmech", "inertia", "pwrIn", "pwrOut", "pwrNet", "trqIn", "trqOut", "trqNet" };
    string _Socket[] = { "allowedValues", "child.isA()" };
    string _Heater[] = { "switchHeat", "dT", "dTsat", "Q", "hout", "Tout", "coolerMode", "Tamb", "pwr" };
    string _HeatExchanger[] = { "switchQcalc", "switchQ", "Q", "effect", "cap1", "cap2" };
    string _Independent[] = { "varName", "indepRef", "x" };
    string _Dependent[] = { "eq_lhs", "y1", "eq_rhs", "y2", "eq_Ref", "yRef", "tolerance", "toleranceType", "errorCon", "errorIter" };
    string _Integrator[] = { "eq_lhs", "y1", "eq_rhs", "y2", "eq_Ref", "yRef", "tolerance", "toleranceType", "errorCon", "errorIter" };
    string _Solver_3[] = { "preExecutionSequence", "executionSequence", "postExecutionSequence", "independentNames", "independentValues", "dependentNames" };
    string _Solver[] = { "converged", "convergenceLimit", "convergenceRatio", "passType", "iterationCounter", "numBroydens", "numJacobians",  "passCounter", "perturbationCounter",
              "lastPerturbationPass" };
    string _TurbinePRmap_GE[] = {"s_Wp", "effMap", "effMapDes", "NpMap", "NpMapDes", "PRmap", "PRmapDes", "WpMap", "WpMapDes", "s_effDes", "s_effRe", "s_NpDes", "s_PRdes", "s_WpDes", "s_WpRe" };

    string _Perf[] = { "pwr", "pwrNet", "pwrLoad", "Qin", "eff", "effLoad", "effC", "pctC" };

  }

  VariableContainer unitPref {

    int toSI = 0;
    string _US[], _SI[];

    void setUnitPref(string us, string si) {
      // check for existing us entry
      int i;
      if (_US.contains(us)) {
        i = _US.index(us);
        _SI[i] = si;
      } else {
        // Add preference
        _US.append(us);
        _SI.append(si);
      }
    }

    string getUnitPref(string us) {
      int i;
      if (toSI) {
        if ( _US.contains(us) ) {
          i = _US.index(us);
          return _SI[i];
        } else {
          // return the us string if preference does not exist
          // cerr << "Warning: no conversion preference defined for " << us << endl;
          return us;
        }  
      } else {
        return us;
      }
    }

    // // default preferences

    setUnitPref("R", "C");
    setUnitPref("psia", "bar");
    setUnitPref("ft3/sec", "m3/sec");
    setUnitPref("lbm/sec", "kg/sec");
    setUnitPref("ft3/lbm", "m3/kg");
    setUnitPref("lbm/ft3", "kg/ft3");
    setUnitPref("Btu/lbm", "kJ/kg");
    setUnitPref("Btu/(lbm*R)", "kJ/(kg*K)");
    setUnitPref("lbf/ft2", "bar");
    setUnitPref("ft*lbf", "N*m");
    setUnitPref("hp", "kW");
    setUnitPref("Btu/sec", "kJ/sec");
    setUnitPref("Btu/(sec*in2*R)", "kJ/(sec*m2*K)");
    setUnitPref("in2", "m2");
    setUnitPref("dR", "dC");
    setUnitPref("none", "none");
    setUnitPref("", "none");
    setUnitPref("rpm", "rpm");
    setUnitPref("slug*ft2", "kg*m2");

  }

    


  //   string[] getElement(string name) {
  //     string s[];
  //     if exists(name) {
  //       return name->value;
  //     } else {
  //       return s;
  //     }
  //   }

  //   FunctVariable elemTypes {
  //     setFunction = "setElemTypes";
  //     getFunction = "getElemTypes";
  //   }

  //   void setElemTypes() {
  //   }
  //   string[] getElemTypes() {
  //     list("Variable",0,"getDataType()==\"string[]\"");
  //   }
  // }


  // Define I/O Stream
  OutFileStream os_gml {filename = gmlFile; }
  OutFileStream debugStream {filename = "gml.debug"; }

  VariableContainer node {

      // List of variables to print
      string varList[];

      // Variable Declaration
      string id = "";
      varList.append("id");

      string label = "";
      varList.append("label");

      string isGroup = "";
      varList.append("isGroup");

      string gid = "";
      varList.append("gid");

      // Set default values
      void setDefault() {
          id = "";
          label = "";
          isGroup = "0";
          gid = "";
      }

      // Set Values for Element
      void setAssembly ( string id_in, string label_in, string gid_in ) {
          setDefault();

          id = id_in;
          label = label_in;
          isGroup = "1";
          gid = gid_in;

          graphics.setAssembly();
          LabelGraphics.setAssembly(label_in);
      }

      // Set Values for Element
      void setElement ( string id_in, string label_in, string gid_in ) {
          setDefault();

          id = id_in;
          label = label_in;
          isGroup = "1";
          gid = gid_in;

          graphics.setElement();
          LabelGraphics.setElement(label_in);
      }

      // Set Values for Port
      void setPort(string id_in, string label_in, string gid_in) {
          setDefault();

          id = id_in;
          label = label_in;
          isGroup = "0";
          gid = gid_in;

          graphics.setPort();
          LabelGraphics.setPort(label_in);
      }

      // Set Values for Link
      void setLink(string id_in, string label_in, string gid_in) {
          setDefault();

          id = id_in;
          label = label_in;
          isGroup = "0";
          gid = gid_in;

          graphics.setLink();
          LabelGraphics.setLink(label_in);
      }

      // Set Values for Text
      void setText(string id_in, string label_in, string gid_in) {
          setDefault();

          id = id_in;
          label = label_in;
          isGroup = "0";
          gid = gid_in;

          graphics.setText();
          LabelGraphics.setText(label_in);
      }

      void setColor( string color ) {
          setLineColor(color);
          setTextColor(color);
      }

      void setLineColor( string color ) {
          graphics.outline = color;
          graphics.color = color;
      }

      void setTextColor( string color ) {
          LabelGraphics.color = color;
      }

      string print() {
          string out;
          int i;

          // Create a list from all variables, will include default NPSS variables in list.
          // string varList[] = parent.list("Variable",0);
          // cout << varList << endl;

          out = "";
          out.append(ntab(tLevel));
          out.append("node [\n");
          tLevel++;
          for (i=0; i<varList.entries(); i++) {
              out.append(ntab(tLevel));
              // cout << "gml: " << varList[i] << endl;
              if (varList[i]->getDataType() == "string") {
                  out.append(varList[i]->getName() + " \"" + evalExpr( varList[i] ) + "\"\n");
              } else {
                  out.append(varList[i]->getName() + " " + toStr(evalExpr( varList[i] )) + "\n");
              }
          }

          // Add graphics
          out.append(graphics.print());

          // Add LabelGraphics
          out.append(LabelGraphics.print());

          // Close
          out.append(ntab(tLevel));
          out.append("]\n");
          tLevel--;

          return out;
      }

      VariableContainer graphics {

          // List of variables to print
          string varList[];

          // Variable Declaration
          string type = "rectangle";
          varList.append("type");

          string fill = "#FFFFFF";
          varList.append("fill");

          string outline = "#000000";
          varList.append("outline");

          string outlineStyle = "line";
          varList.append("outlineStyle");

          string color = "#000000";
          varList.append("color");

          string group = "1";
          // varList.append("group");

          string closed = "0";
          varList.append("closed");

          int autoResize = 1;
          varList.append("autoResize");

          int considerLabels = 1;
          varList.append("considerLabels");

          int hasOutline = 1;
          varList.append("hasOutline");

          int w = 30;
          varList.append("w");

          int h = 30;
          varList.append("h");

          // Set default values
          void setDefault() {
              type = "rectangle";
              fill = "#FFFFFF";
              outline = "#000000";
              outlineStyle = "line";
              color = "#000000";
              group = "0";
              closed = "0";
              autoResize = 1;
              considerLabels  = 0;
              hasOutline = 1;
              w = 30;
              h = 30;
          }

          // Set Values for Element
          void setAssembly() {
              setDefault();
              group = "1";
              considerLabels  = 1;
              outlineStyle = "dashed";
          }

          // Set Values for Element
          void setElement() {
              setDefault();
              group = "1";
              considerLabels  = 1;
          }

          // Set Values for Port
          void setPort() {
              setDefault();
              outline = "#000000";
          }

          // Set Values for Link
          void setLink() {
              setDefault();
              outline = "#000000";
              type = "roundrectangle";
          }

          // Set Values for Text
          void setText() {
              setDefault();
              hasOutline = 0;
              autoResize = 0;
              considerLabels  = 1;
              w = 1;
              h = 1;
          }

          string print() {
              string out;
              int i;

              // Create a list from all variables, will include default NPSS variables in list.
              // string varList[] = parent.list("Variable",0);
              // cout << varList << endl;

              out = "";
              out.append(ntab(tLevel));
              out.append("graphics [\n");
              tLevel++;
              for (i=0; i<varList.entries(); i++) {
                  out.append(ntab(tLevel));
                  if (varList[i]->getDataType() == "string") {
                      out.append(varList[i]->getName() + " \"" + evalExpr( varList[i] ) + "\"\n");
                  } else {
                      out.append(varList[i]->getName() + " " + toStr(evalExpr( varList[i] )) + "\n");
                  }
              }
              out.append(ntab(tLevel));
              out.append("]\n");
              tLevel--;

              return out;
          }
      }

      VariableContainer LabelGraphics {

          // List of variables to print
          string varList[];

          // Variable Declaration
          string text = "";
          varList.append("text");

          string fill = "#FFFFFF";
          //varList.append("fill");

          real fontSize = 12;
          varList.append("fontSize");

          string fontStyle = "plain";
          varList.append("fontStyle");

          string fontName = "Dialog";
          varList.append("fontName");

          string alignment = "center";
          varList.append("alignment");

          string autoSizePolicy = "content";
          varList.append("autoSizePolicy");

          string anchor = "c";
          varList.append("anchor");

          real borderDistance = 0.0;
          varList.append("borderDistance");

          string color = "#000000";
          varList.append("color");

          // Set default values
          void setDefault() {
              text = "";
              fill = "#FFFFFF";
              fontSize = 12;
              fontStyle = "plain";
              fontName = "Dialog";
              alignment = "center";
              autoSizePolicy = "content";
              anchor = "c";
              borderDistance = 0.0;
              color = "#000000";
          }

          // Set Values for Element
          void setAssembly(string text_in) {
              setDefault();

              text = text_in;
              fill = "#EEEEEE";
              fontSize = 12;
              fontStyle = "bold";
              fontName = "Dialog";
              alignment = "right";
              autoSizePolicy = "node_width";
              anchor = "t";
              borderDistance = 0.0;
          }

          // Set Values for Element
          void setElement(string text_in) {
              setDefault();

              text = text_in;
              fill = "#EEEEEE";
              fontSize = 12;
              fontStyle = "bold";
              fontName = "Dialog";
              alignment = "right";
              autoSizePolicy = "node_width";
              anchor = "t";
              borderDistance = 0.0;
          }

          void setPort(string text_in) {
              setDefault();
              text = text_in;
              anchor = "n";
          }

          void setLink(string text_in) {
              setDefault();
              text = text_in;
              anchor = "n";
          }

          void setText(string text_in) {
              setDefault();
              text = text_in;
              anchor = "c";
          }


          string print() {
              string out;
              int i;

              // Create a list from all variables, will include default NPSS variables in list.
              // string varList[] = parent.list("Variable",0);
              // cout << varList << endl;

              out = "";
              out.append(ntab(tLevel));
              out.append("LabelGraphics [\n");
              tLevel++;
              for (i=0; i<varList.entries(); i++) {
                  out.append(ntab(tLevel));
                  if (varList[i]->getDataType() == "string") {
                      out.append(varList[i]->getName() + " \"" + evalExpr( varList[i] ) + "\"\n");
                  } else {
                      out.append(varList[i]->getName() + " " + toStr(evalExpr( varList[i] )) + "\n");
                  }
              }
              out.append(ntab(tLevel));
              out.append("]\n");
              tLevel--;

              return out;
          }
      }
  }




  VariableContainer edge {

      // List of variables to print
      string varList[];

      // Variable Declaration
      string source = "";
      varList.append("source");

      string target = "";
      varList.append("target");

      string label = "";
      varList.append("label");

      // Set default values
      void setDefault() {
          source = "";
          target = "";
          label = "";
          graphics.width = 2;
          graphics.fill = "#000000";
          graphics.targetArrow = "standard";
          graphics.style = "line";
          LabelGraphics.text = "";
      }

      void setLink(string source_in, string target_in) {
          setDefault();
          source = source_in;
          target = target_in;
      }

      void setColor( string color ) {
        graphics.fill = color;
      }

      void setLabel( string str ) {
          LabelGraphics.text = str;
      }

      void setStyle( string style ) {
        graphics.style = style;
      }

      void setWidth( int w ) {
        graphics.width = w;
      }

      string print() {
          string out;
          int i;

          // Create a list from all variables, will include default NPSS variables in list.
          // string varList[] = parent.list("Variable",0);
          // cout << varList << endl;

          out = "";
          out.append(ntab(tLevel));
          out.append("edge [\n");
          tLevel++;
          for (i=0; i<varList.entries(); i++) {
              out.append(ntab(tLevel));
              if (varList[i]->getDataType() == "string") {
                  out.append(varList[i]->getName() + " \"" + evalExpr( varList[i] ) + "\"\n");
              } else {
                  out.append(varList[i]->getName() + " " + toStr(evalExpr( varList[i] )) + "\n");
              }
          }

          // Add graphics
          out.append(graphics.print());

          // Add LabelGraphics
          out.append(LabelGraphics.print());

          // Close
          out.append(ntab(tLevel));
          out.append("]\n");
          tLevel--;

          return out;
      }

      VariableContainer graphics {

        // List of variables to print
        string varList[];

        int width = 2;
        varList.append("width");

        // Variable Declaration
        string fill = "#000000";
        varList.append("fill");

        string targetArrow = "standard";
        varList.append("targetArrow");

        string style = "line";
        varList.append("style");

        string print() {
          string out;
          int i;

          // Create a list from all variables, will include default NPSS variables in list.
          // string varList[] = parent.list("Variable",0);
          // cout << varList << endl;

          out = "";
          out.append(ntab(tLevel));
          out.append("graphics [\n");
          tLevel++;
          for (i=0; i<varList.entries(); i++) {
              out.append(ntab(tLevel));
              if (varList[i]->getDataType() == "string") {
                  out.append(varList[i]->getName() + " \"" + evalExpr( varList[i] ) + "\"\n");
              } else {
                  out.append(varList[i]->getName() + " " + toStr(evalExpr( varList[i] )) + "\n");
              }
          }
          out.append(ntab(tLevel));
          out.append("]\n");
          tLevel--;

          return out;
        }
      }

      VariableContainer LabelGraphics {

          // List of variables to print
          string varList[];

          // Variable Declaration
          string text = "";
          varList.append("text");

          string model = "CENTERED";
          varList.append("model");

          real fontSize = 12;
          varList.append("fontSize");

          string fontStyle = "plain";
          varList.append("fontStyle");

          string fontName = "Dialog";
          varList.append("fontName");

          string alignment = "center";
          varList.append("alignment");

          string autoSizePolicy = "content";
          varList.append("autoSizePolicy");

          string anchor = "c";
          varList.append("anchor");

          real borderDistance = 0.0;
          varList.append("borderDistance");

          string color = "#000000";
          varList.append("color");

          // Set default values
          void setDefault() {
              text = "";
              fill = "#FFFFFF";
              fontSize = 12;
              fontStyle = "plain";
              fontName = "Dialog";
              alignment = "center";
              autoSizePolicy = "content";
              anchor = "c";
              borderDistance = 0.0;
              color = "#000000";
          }

          void setText(string text_in) {
              setDefault();
              text = text_in;
          }


          string print() {
              string out;
              int i;

              // Create a list from all variables, will include default NPSS variables in list.
              // string varList[] = parent.list("Variable",0);
              // cout << varList << endl;

              out = "";
              out.append(ntab(tLevel));
              out.append("LabelGraphics [\n");
              tLevel++;
              for (i=0; i<varList.entries(); i++) {
                  out.append(ntab(tLevel));
                  // cout << "gml: " << varList[i] << endl;
                  if (varList[i]->getDataType() == "string") {
                      out.append(varList[i]->getName() + " \"" + evalExpr( varList[i] ) + "\"\n");
                  } else {
                      out.append(varList[i]->getName() + " " + toStr(evalExpr( varList[i] )) + "\n");
                  }
              }
              out.append(ntab(tLevel));
              out.append("]\n");
              tLevel--;

              return out;
          }
      }
  }

  string printVc( string Vc ) {
          string out;
          string varList[];
          int i;

          for (i=0;i<Vc->varList.entries();i++) {
              varList.append(Vc + "." + Vc->varList[i]);
          }

          out = "";
          out.append(ntab(tLevel));
          out.append(Vc + " [\n");
          tLevel++;
          for (i=0; i<varList.entries(); i++) {
              out.append(ntab(tLevel));
              // cout << "gml: " << varList[i] << endl;
              if (varList[i]->getDataType() == "string") {
                  out.append(varList[i]->getName() + " \"" + evalExpr( varList[i] ) + "\"\n");
              } else {
                  out.append(varList[i]->getName() + " " + toStr(evalExpr( varList[i] )) + "\n");
              }
          }

          out.append(ntab(tLevel));
          out.append("]\n");
          tLevel--;

          return out;
      }

  // Colormap
  //
  // References:
  //    http://stackoverflow.com/questions/12875486/what-is-the-algorithm-to-create-colors-for-a-heatmap
  //    http://www.rapidtables.com/convert/color/hsl-to-rgb.htm
  //    http://www.rapidtables.com/convert/color/how-rgb-to-hex.htm
  //    http://www.andrewnoske.com/wiki/Code_-_heatmaps_and_color_gradients
  //    http://colorbrewer2.org/
  //
  real cMinValue, cMaxValue, cRange;
  string cVar, cObj;
  cMinValue = 0;
  cMaxValue = 1;
  cRange = cMaxValue - cMinValue;
  cVar = "Tt";
  cObj = "FluidPort";

  void createColorKey() {

      int nLevels = 4;
      int i,j;
      real level;
      string lineColor;

      node.setElement( "Key", "Legend: " + cVar, "." );
      os_gml << node.print();

      for ( i=0; i<nLevels; i++ ) {
        level = cMinValue + i*cRange/(nLevels-1);
        lineColor = getHeatMapColor(level);
        node.setElement( toStr(level)+"a", "", "Key" );
        node.setLineColor(lineColor);
        node.graphics.w = 0;
        node.graphics.h = 0;
        os_gml << node.print();
        node.setElement( toStr(level)+"b", "", "Key" );
        node.setLineColor(lineColor);
        os_gml << node.print();
        edge.setLink(toStr(level)+"a", toStr(level)+"b");
        edge.setColor(lineColor);
        edge.setLabel(toStr(level));
        os_gml << edge.print();
      }

  }

  void getColorRange( string name, string objType, string varName ) {
    string pList[];
    int j;
    real thisValue;

    pList = name->list(objType,1);
    if ( pList.entries() > 1 ) {
        j = 0;
        if ( pList[j]->exists(varName+"."+"value") ) {
          thisValue = (pList[j]+"."+varName)->value;
          cMinValue = thisValue;
          cMaxValue = thisValue;
        }
    }

    for (j = 0; j<pList.entries(); j++) {
      if ( pList[j]->exists(varName+"."+"value") ) {
          thisValue = (pList[j]+"."+varName)->value;
          // cout << pList[j]+"."+varName << " " << thisValue << " " << endl;
          if ( thisValue < cMinValue ) {
              cMinValue = thisValue;
          } else if ( thisValue > cMaxValue ) {
              cMaxValue = thisValue;
          }
      }
    }
    cRange = cMaxValue - cMinValue;
    if ( cRange < 0.0001 ) {
        cRange = 1.0;
        cMinValue -= cRange/2.0;
    }
  }

  string getHeatMapColor(real value) {
    // Adapted from: http://www.andrewnoske.com/wiki/Code_-_heatmaps_and_color_gradients
    int NUM_COLORS;
    NUM_COLORS = 4;
    int color[][] = { {0,0,1}, {0,1,0}, {1,1,0}, {1,0,0} };
    // A static array of 4 colors:  (blue,   green,  yellow,  red) using {r,g,b} for each.

    int idx1;            // |-- Our desired color will be between these two indexes in "color".
    int idx2;           // |
    real fractBetween;  // Fraction between "idx1" and "idx2" where our value is.

    real level;
    int red, green, blue;
    string RGB;

    // Color Level from 0 to 1
    level = (value - cMinValue)/cRange;

    if (level <= 0) {
      // accounts for an input <=0
      idx1 = 0;
      idx2 = idx1;
      fractBetween = 0;
    } else if(level >= 1)  {
      // accounts for an input >=0
      idx1 = NUM_COLORS-1;
      idx2 = idx1;
      fractBetween = 0;
    } else {
      level = level * (NUM_COLORS-1);        // Will multiply level by 3.
      idx1  = floor(level);                  // Our desired color will be after this index.
      idx2  = idx1+1;                        // ... and before this index (inclusive).
      fractBetween = level - idx1;    // Distance between the two indexes (0-1).
    }

    red   = ((color[idx2][0] - color[idx1][0])*fractBetween + color[idx1][0])*255;
    green = ((color[idx2][1] - color[idx1][1])*fractBetween + color[idx1][1])*255;
    blue  = ((color[idx2][2] - color[idx1][2])*fractBetween + color[idx1][2])*255;

    /*
    cout << "value: " << value << " level: " << level/(NUM_COLORS-1) << endl;
    cout << "idx1: " << idx1 << " idx2: " << idx2 << " fractBetween: " << fractBetween << endl;
    cout << "red: " << red << " green: " << green << " blue: " << blue << endl;
    */

    RGB = "#" + toStr(red,"X02") + toStr(green,"X02") + toStr(blue,"X02");
    return RGB;
    }

  /*
  cout << endl;
  cout << getHeatMapColor(-0.1) << endl;
  cout << endl;
  cout << getHeatMapColor(0.0) << endl;
  cout << endl;
  cout << getHeatMapColor(0.2) << endl;
  cout << getHeatMapColor(0.2) << endl;
  cout << endl;
  cout << getHeatMapColor(1.0/3.0) << endl;
  cout << endl;
  cout << getHeatMapColor(0.5) << endl;
  cout << endl;
  cout << getHeatMapColor(2.0/3.0) << endl;
  cout << endl;
  cout << getHeatMapColor(1.0) << endl;
  cout << endl;
  cout << getHeatMapColor(1.1) << endl;
  cout << endl;
  */

  // GML Defaults
  int applyGraphics = 1;
  int fontSize = 12; // Standard
  string fontStyle = "plain";
  real variableFscale = 1.0;
  string textColor = "#000000"; // Black
  string lineColor = "#000000"; // Black
  string fillColor = "#FFFFFF"; // White
  // string labelFillColor = "#DDDDDD"; // lightgray
  string labelFillColor = "#EEEEEE"; // lightgray
  string nodeType = "rectangle"; // rectangle, roundrectangle
  string targetArrow = "standard";

  string outlineStyle = "line"; // dashed

  // User defined variable list
  string variableList[] = { };
  int showSolverLinks = 0;

  string nodeList[];

  // Utility functions

  void ifDebug ( string text ) {
    if ( DEBUG ) {
      debugStream << "gml: " << text << endl;
    }
  }

  string[] str2array( string in ) {
    string out[];
    out.append(in);
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

  // GML File Utilities

  // Set the file name to write to
  void setGmlFile( string filename ){
    gmlFile = filename;
    ifDebug( "gmlFile:\"" + gmlFile + "\"" );
    os_gml.filename = gmlFile;
    ifDebug( "os_gml.filename:\"" + os_gml.filename + "\"" );
  }

  // Create the GML header and open graph
  void createHeader() {
    // Header information
    os_gml << "creator \"npss genGML\"" << endl;
    os_gml << "version 0.1" << endl;
    // Open graph
    tLevel = 0;
    os_gml << ntab(tLevel) << "graph [" << endl;
    tLevel++;
    os_gml << ntab(tLevel) << "hierarchic 1" << endl;
    os_gml << ntab(tLevel) << "directed 1" << endl;

    /*
    // Label is based on top level variables
    os_gml << ntab(1) << "\tlabel=\"";
    os_gml << " USER: " << .USER << ";";
    os_gml << " VERSION: " << .VERSION << ";";
    os_gml << " date: " << .date << ";";
    os_gml << " timeOfDay: " << .timeOfDay << ";";
    os_gml << " title: " << .title << ";";
    os_gml << " description: " << .description << ";";
    os_gml << " MODELNAME: " << .MODELNAME << ";";
    os_gml << " ThermoPackage: " << .THERMPACKAGE << ";";
    os_gml << " CASE: " << .CASE << ";";
    os_gml << "\"" << endl;
    os_gml << ntab(1) << "\tlabelloc=top; labeljust=center;" << endl;
    */

  }

  // close the graph created in the header
  void createFooter() {
    // Close the graph
    os_gml << ntab(tLevel) << "]" << endl;
  }

  // Split a string on "." and return parent "Name" and child "Port"
  // Examples:
  //  { "F030", "Tt" } = getNamePort( "F030.Tt" )
  //  { "Asm10.F030", "Tt" } = getNamePort( "Asm10.F030.Tt" )
  string getNamePort( string var ) {

    // Split the string at "."
    string temp[];
    temp = split(var, ".");

    // Cancatonate name
    string name;
    name = temp[0];
    int i;
    for (i=1; i<temp.entries()-1; i++) {
      append(name, ".");
      append(name, temp[i]);
    }

    // Port
    string port = temp[temp.entries()-1];

    // return value
    string v[];
    v.append(name);
    v.append(port);
    return v;
  }

  // Split a string on "." and return parent "Name"
  // Examples:
  //  "F030" = getN( "F030.Tt" )
  //  "Asm10.F030" = getN( "Asm10.F030.Tt" )
  string getN( string var ) {

    // Split the string at "."
    string temp[];
    temp = split(var, ".");

    // Cancatonate name
    string name;
    name = temp[0];
    int i;
    for (i=1; i<temp.entries()-1; i++) {
      append( name, ".");
      append( name, temp[i]);
    }

    return name;
  }

  // Split a string on "." and return the child "Port"
  // Examples:
  //  "Tt" = getP( "F030.Tt" )
  //  "Tt" = getP( "Asm10.F030.Tt" )
  string getP( string var ) {

    // Split the string at "."
    string temp[];
    temp = split(var, ".");

    // Port
    string port = temp[temp.entries()-1];

    // return value
    return port;
  }

  void createInternalPortsBak( string name, int mapFluidPort ) {

    int j;
    string tname;
    string port;
    string flList[];
    string fuList[];
    string shList[];
    // string pList[];
    string label;

    int in[];
    int out[];

    flList = name->list("FluidPort",0);
    // cout << name << ": " << flList << endl;
    for (j = 0; j<flList.entries(); j++) {
      tname = flList[j];
      port = getP(tname);
      lineColor = "#0000FF";
      // fontSize = fontSize*0.5

      //label = tname->isA();
      //label = label + ": " + tname->getPathName();
      label = tname->getPathName();
      node.setPort(tname->getPathName(), label, name->getPathName());
      node.setColor(lineColor);
      os_gml << node.print();
    }

    // Assembly fluid port connections are defined somewhere else ???//

    if ( mapFluidPort ) {

      in = arrayFindString(flList, "_I");
      //cout << "DBG in = " << in << endl;
      out = arrayFindString(flList, "_O");
      //cout << "DBG out = " << out << endl;
      string source;
      string target;
      lineColor = "#000FF";
      if ( ( out.entries() > 0 ) & ( in.entries() > 0 ) ) {
        if ( in.entries() == out.entries() ) {
          // Assume 1:1 match
          for (j=0; j<out.entries(); j++) {
            source = flList[in[j]]->getPathName();
            target = flList[out[j]]->getPathName();
            //cout << "source " << source << " target " << target << " end " << endl;
            // createGmlEdge(source, target, "" );
            edge.setLink(source, target);
            edge.setColor(lineColor);
            os_gml << edge.print();
          }
        }
        else if ( in.entries() > out.entries() ) {
          // Assume a Join or Merge
          for (j=0; j<in.entries(); j++) {
            //cout << "source " << flList[in[j]]->getPathName() << " dest " << flList[out[0]]->getPathName() << " end " << endl;
            //createGmlEdge(flList[in[j]]->getPathName(), flList[out[0]]->getPathName(), "" );
            edge.setLink(flList[in[j]]->getPathName(), flList[out[0]]->getPathName());
            edge.setColor(lineColor);
            os_gml << edge.print();
          }
        }
        else if ( in.entries() < out.entries() ) {
          // Assume a Split
          for (j=0; j<out.entries(); j++) {
            //cout << "source " << flList[in[0]]->getPathName() << " dest " << flList[out[j]]->getPathName() << " end " << endl;
            //createGmlEdge(flList[in[0]]->getPathName(), flList[out[j]]->getPathName(), "" );
            edge.setLink(flList[in[0]]->getPathName(), flList[out[j]]->getPathName());
            edge.setColor(lineColor);
            os_gml << edge.print();
          }
        }
      }

    }

    fuList = name->list("FuelPort",0);
    // cout << name << ": " << fuList << endl;
    for (j = 0; j<fuList.entries(); j++) {
      tname = fuList[j];
      port = getP(tname);
      node.setPort(tname->getPathName(), tname->getName(), name->getPathName());
      node.setColor("#005555");
      os_gml << node.print();
    }


    shList = name->list("ShaftPort",0);
    // cout << name << ": " << shList << endl;
    for (j = 0; j<shList.entries(); j++) {
      tname = shList[j];
      port = getP(tname);
      node.setPort(tname->getPathName(), tname->getName(), name->getPathName());
      node.setColor("#00FFFF");
      os_gml << node.print();
    }

    // Default line color
    lineColor = "#000000";

  }

  void createInternalPorts( string name, int mapFluidPort ) {

    int j;
    string tname;
    string port;
    string flList[];
    //string fuList[];
    //string shList[];
    string pList[];
    string pType;
    string label;
    string lineType;

    int in[];
    int out[];

    pList = name->list("Port",0);
    for (j = 0; j<pList.entries(); j++) {

      pType = pList[j]->isA();

      lineType = "line"; // "line", "dashed", "dotted"

      if ( ( pType.index("Fluid") > -1 ) ) {
          textColor = "#0000FF";
          lineColor = getHeatMapColor((pList[j]+"."+cVar)->value);
          // cout << pList[j] << " " << cVar << " " << (pList[j]+"."+cVar)->value << " " << lineColor << endl;
      } else if ( ( pType.index("Bleed") > -1 ) ) {
          textColor = "#0000FF";
          lineColor = getHeatMapColor((pList[j]+"."+cVar)->value);
          //lineType = "dashed"; // "line", "dashed", "dotted"
      } else if ( ( pType.index("Fuel") > -1 ) ) {
          textColor = "#005555";
          lineColor = "#005555";
      } else if ( ( pType.index("Shaft") > -1 ) ) {
          textColor = "#00FFFF";
          lineColor = "#00FFFF";
          lineType = "dashed"; // "line", "dashed", "dotted"
      }

      tname = pList[j];
      port = getP(tname);
      // fontSize = fontSize*0.5

      //label = tname->isA();
      //label = label + ": " + tname->getPathName();
      label = tname->getName();
      node.setPort(tname->getPathName(), label, name->getPathName());
      node.setLineColor(lineColor);
      node.setTextColor(textColor);
      os_gml << node.print();
    }


    // Assembly fluid port connections are defined somewhere else ???//

    // Link internal fluid ports
    // Revisit for complex fluidports, bleedin and bleedout ports

    if ( mapFluidPort ) {

      flList = name->list("FluidPort",0);
      //flList.append( name->list("BleedInPort",0) );
      //flList.append( name->list("BleedOutPort",0) );

      in = arrayFindString(flList, "_I");
      //in = name->list("FluidInputPort",0);
      //in.append( name->list("BleedInPort",0) );
      //cout << "DBG in = " << in << endl;

      out = arrayFindString(flList, "_O");
      //out = name->list("FluidOutputPort",0);
      //out.append( name->list("BleedOutPort",0) );
      //cout << "DBG out = " << out << endl;

      string source;
      string target;
      textColor = "#000FF";
      if ( ( out.entries() > 0 ) & ( in.entries() > 0 ) ) {
        if ( in.entries() == out.entries() ) {
          // Assume 1:1 match
          for (j=0; j<out.entries(); j++) {
            source = flList[in[j]]->getPathName();
            lineColor = getHeatMapColor((source+"."+cVar)->value);
            target = flList[out[j]]->getPathName();
            //cout << "source " << source << " target " << target << " end " << endl;
            // createGmlEdge(source, target, "" );
            edge.setLink(source, target);
            edge.setColor(lineColor);
            os_gml << edge.print();
          }
        }
        else if ( in.entries() > out.entries() ) {
          // Assume a Join or Merge
          for (j=0; j<in.entries(); j++) {
            //cout << "source " << flList[in[j]]->getPathName() << " dest " << flList[out[0]]->getPathName() << " end " << endl;
            //createGmlEdge(flList[in[j]]->getPathName(), flList[out[0]]->getPathName(), "" );
            edge.setLink(flList[in[j]]->getPathName(), flList[out[0]]->getPathName());
            lineColor = getHeatMapColor((flList[in[j]]->getPathName()+"."+cVar)->value);
            edge.setColor(lineColor);
            os_gml << edge.print();
          }
        }
        else if ( in.entries() < out.entries() ) {
          // Assume a Split
          for (j=0; j<out.entries(); j++) {
            //cout << "source " << flList[in[0]]->getPathName() << " dest " << flList[out[j]]->getPathName() << " end " << endl;
            //createGmlEdge(flList[in[0]]->getPathName(), flList[out[j]]->getPathName(), "" );
            edge.setLink(flList[in[0]]->getPathName(), flList[out[j]]->getPathName());
            lineColor = getHeatMapColor((flList[in[0]]->getPathName()+"."+cVar)->value);
            edge.setColor(lineColor);
            os_gml << edge.print();
          }
        }
      }

    }


  }

  void createAssemblies(string names[]) {
    int i;
    for (i=0; i<names.entries(); i++) {
      node.setAssembly( names[i]->getPathName(), names[i]->getPathName(), names[i]->getParentName() );
      os_gml << node.print();
      createInternalPorts(names[i], 0);
    }
  }

  void createElements(string names[]) {
    int i;
    int j;

    string tempName;
    string outList[];
    string ltype;
    string label;

    for (i=0; i<names.entries(); i++) {
      // Only local name, not path name in label
      // node.setElement( names[i]->getPathName(), names[i]->isA() + ": " + names[i]->getName(), names[i]->getParentName() );
      node.setElement( names[i]->getPathName(), names[i]->getName() + endl + names[i]->isA(), names[i]->getParentName() );
      os_gml << node.print();
      // Check element type
      ltype = names[i]->isA();
      // cout << "ltype " << ltype << endl;
      if ( ltype.index("Assembly") > -1 ) {
        createInternalPorts(names[i], 0);
      } else {
        createInternalPorts(names[i], 1);
      }

      if ( VERBOSE > 1 ) {

          if ( ltype == "Socket" ) {
              if ( names[i]->child.isA() == "Table" ) {
                  ltype = "Table";
              } else {
                ltype = names[i]->child.isA();
              }
          } else if ( ltype == "Element" ) { 
              ltype = names[i]->getName();
          }
          outList = {};

          tempName = "elemAttr._"+ltype;
          if ( exists(tempName) ) {
            outList.append(tempName->value);
          }

          for (j=0;j<=VERBOSE;j++) {
            tempName = "elemAttr._"+ltype+"_"+toStr(j);
            if ( exists(tempName) ) {
              outList.append(tempName->value);
            } 
          }

         

          // Variables
          label = "";
          label = queryAttr( names[i], outList, "\r" );
          node.setText(names[i]->getPathName()+".outList", label, names[i]->getPathName());
          os_gml << node.print();
      }
    }
  }

  void createLinks(string names[]) {

    int i;
    string temp[];
    string fname;
    string tname;
    string label;
    string outList[];
    string station;
    string style;
    for (i=0; i<names.entries(); i++) {

      style = "line";

      // AMM: Debug for Eric
      // cout << "DEBUG: createLinks(), names[i]: " << station << " isA(): " << station->iaA() << endl;

      // AMM: could be removed and reverted to names[i]
      station = names[i];

      // convert element.port to "element":"port"

      // From
      fname = names[i]->getP1Name();
      //cout << " * fname = " << fname << endl;
      string fromE = getN(fname);
      //cout << " * fromE = " << fromE << endl;
      string fromP = getP(fname);
      //cout << " * fromP = " << fromP << endl;

      // To
      tname = names[i]->getP2Name();
      //cout << " * tname = " << tname << endl;
      string toE = getN(tname);
      //cout << " * toE = " << toE << endl;
      string toP = getP(tname);
      //cout << " * toP = " << toP << endl;


      // Check link type
      string ltype = tname->isA();
      //cout << " * isA():" << ltype << endl;
      if ( ltype.index("Fluid") > -1 || ltype.index("Bleed") > -1 ) {
        //createFluidStation( stationList );
        textColor = "#0000FF";
        lineColor = getHeatMapColor((tname+"."+cVar)->value);
        outList = { "Tt", "Pt", "W", "ht", "s", "Cpt" };
        if ( THERMPACKAGE == "REFPROP" ) {
            outList.append( "comp" );
            // outList.append( "compFluids" ); // needs to be stripped of "
            outList.append( "rhot" );
            outList.append( "xt" );
        }
      } else if ( ltype.index("Shaft") > -1 ) {
        //createShaftStation( stationList );
        lineColor = "#00FFFF";
        textColor = lineColor;
        //outList = { "dNqdt", "fracLoss", "HPX", "inertia", "inertiaSum", "Nmech", "pwrIn", "pwrNet", "pwrOut", "switchDes", "trqIn", "trqNet", "trqOut"};
        outList = { "inertia", "Nmech", "pwr", "trq"};
        style = "dashed";
      } else if ( ltype.index("Fuel") > -1 ) {
        //createFuelStation( stationList );
        lineColor = "#005555";
        textColor = lineColor;
        outList = {"Wfuel"};
      } else {
        // Black
        lineColor = "#000000";
        textColor = lineColor;
        outList = {};
      }

      // Create Station Node
      nodeType = "roundrectangle";
      label = names[i]->isA();

      //label = label + ": " + names[i]->getPathName();
      label = label + ": " + names[i]->getName();
      node.setLink(names[i]->getPathName(), label, names[i]->getParentName());
      node.setLineColor(lineColor);
      node.setTextColor(textColor);
      os_gml << node.print();

      // Create Edge(s)
      edge.setLink(fname, station);
      edge.setColor(lineColor);
      edge.setStyle(style);
      os_gml << edge.print();
      edge.setLink(station, tname);
      edge.setColor(lineColor);
      edge.setStyle(style);
      os_gml << edge.print();

      if ( VERBOSE > 0 ) {
        // Variables
        label = queryAttr( names[i], outList, "\r" );
        node.setText(names[i]->getPathName()+".outList", label, names[i]->getPathName());
        // node.setColor(linkColor);
        os_gml << node.print();
      }

    }
  }

  void getVar( string composite ) {
    string temp[] = split( composite, ".");
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



  void printFluidPortLinks(string names[]) {
    int i;
    string[] s;
    for (i=0; i<names.entries(); i++) {
      // cout << "\n** FluidPort" << endl;
      // cout << " name = " << names[i] << endl;
      // cout << " isLinkedTo = " << names[i]->isLinkedTo() << endl;
      // cout << " getLinkName = " << names[i]->getLinkName() << endl;
      // cout << " getLinkedPortName = " << names[i]->getLinkedPortName() << endl;
      s.append("** FluidPort");
      s.append(" name = " + names[i] );
      s.append(" isLinkedTo = " + names[i]->isLinkedTo() );
      s.append(" getLinkName = " + names[i]->getLinkName() );
      s.append(" getLinkedPortName = " + names[i]->getLinkedPortName() );
      ifDebug( toStr( s ) );
    }
  }


  void printShaftPortLinks(string names[]) {
    int i;
    for (i=0; i<names.entries(); i++) {
      // cout << "\n** ShaftPort" << endl;
      // cout << " name = " << names[i] << endl;
      // cout << " isLinkedTo = " << names[i]->isLinkedTo() << endl;
      // cout << " getLinkName = " << names[i]->getLinkName() << endl;
      // cout << " getLinkedPortName = " << names[i]->getLinkedPortName() << endl;
      s.append("** ShaftPort");
      s.append(" name = " + names[i] );
      s.append(" isLinkedTo = " + names[i]->isLinkedTo() );
      s.append(" getLinkName = " + names[i]->getLinkName() );
      s.append(" getLinkedPortName = " + names[i]->getLinkedPortName() );
      ifDebug( toStr( s ) );
    }
  }

  void genGml() {

    cout << "genGml { filename = " << os_gml.filename << " } " << endl;

    // Reset variables
    nodeList = {};

    createHeader();

    int recur = 1;
    int i;
    int j;


    // Assemblies
    // string[] asmList[];
    // asmList = .list("Assembly",recur);
    // cout << "asmList: " << asmList << endl;
    // createAssemblies(asmList);

    getColorRange( ".", cObj, cVar );
    createColorKey();


    // Elements
    string[] elemList[];
    // elemList = solverSequence;
    // elemList.append( .list("Element",recur) );
    elemList = .list("Element",recur);
    // cout << "elemList: " << elemList << endl;
    createElements(elemList);

    elemList = .list("Subelement",recur);
    // cout << "elemList: " << elemList << endl;
    createElements(elemList);

    if ( VERBOSE > 2 ) {
        elemList = .list("Table",recur);
        // cout << "elemList: " << elemList << endl;
        createElements(elemList);
    }

    // Stations - replaced by internal ports
    // string staList[];
    // staList = .list("Link",recur);
    //cout << staList << endl;
    //list("Link",TRUE);
    //createDotStations(staList);


    // Fluid/Fuel/Shaft Links
    string linkList[];
    linkList = .list("Link",recur);
    // cout << "linkList: " << linkList << endl;
    createLinks(linkList);


    // Resolve Aliased FluidPort links
    string source;
    string target;

    string[] aliasFIPlist[] = .list("Alias",1,"isA() == \"FluidInputPort\"");
    for (j=0; j<aliasFIPlist.entries(); j++) {
        source = aliasFIPlist[j]->getPathName();
        target = getModelName(aliasFIPlist[j])->getPathName();

        edge.setLink(source, target);
        lineColor = getHeatMapColor((source+"."+cVar)->value);
        edge.setColor(lineColor);
        os_gml << edge.print();
    }

    string[] aliasFOPlist[] = .list("Alias",1,"isA() == \"FluidOutputPort\"");
    for (j=0; j<aliasFOPlist.entries(); j++) {
        target = aliasFOPlist[j]->getPathName();
        source = getModelName(aliasFOPlist[j])->getPathName();
        edge.setLink(source, target);
        lineColor = getHeatMapColor((source+"."+cVar)->value);
        edge.setColor(lineColor);
        os_gml << edge.print();
    }


    // Solvers is still a work in progress
    string tempList[];
    string[] solverList[];

    solverList = .list("Solver",1);
    createElements(solverList);

    if (VERBOSE > 3) {

        tempList = .list("Independent",1);
        createElements(tempList);

        tempList = .list("Dependent",1);
        createElements(tempList);

        for (j=0; j<solverList.entries(); j++) {
            tempList = solverList[j]->independentNames;
            /* for (i=0; i<tempList.entries();i++) {
                tempList[i] = solverList[j]+"."+tempList[i];
                cout << tempList[i] << endl;
            } */
            // createElements(tempList);
            lineColor = "#00FF00";
            for (i=0; i<tempList.entries();i++) {
                // createGmlEdge(solverList[j], tempList[i], "" );
                edge.setLink(solverList[j], tempList[i]);
                edge.setColor(lineColor);
                os_gml << edge.print();
            }

            tempList = solverList[j]->dependentNames;
            lineColor = "#FF0000";
            for (i=0; i<tempList.entries();i++) {
                // createGmlEdge(solverList[j], tempList[i], "" );
                edge.setLink(solverList[j], tempList[i]);
                edge.setColor(lineColor);
                os_gml << edge.print();
            }

        }
        lineColor = "#000000";
    }

    // Header information
    i=0;
    string names[] = { "" };
    string outList[] = { "USER", "date", "timeOfDay", "VERSION", "THERMPACKAGE", "gml.VERSION" };
    string label = "";
    label = queryAttr( names[i], outList, "\r" );
    node.setText( names[i]->getPathName()+".outList", label, names[i]->getPathName() );
    os_gml << node.print();

    createFooter();

    ifDebug("os_gml.filename:\"" + os_gml.filename + "\"" );

  }

  void genVerboseGml(int verbose) {
    ifDebug("genVerboseGml(" + toStr(verbose) + ")" );
    VERBOSE = verbose;
    genGml();
  }

  void create( string filename, int verbose, int doRun ) {
    // Check for filename = ""
    if ( filename.length() > 0 ) { setGmlFile(filename); }
    // Generate graphviz input
    genVerboseDot( verbose );
    // Execute Dot to create flow network
    if ( doRun ) { runDot(); }
  }

  string ntab( int num ) {
    string tabs;
    int i;
    tabs="";
    for (i=0; i<num; i++) {
      // tabs.append("\t");
      tabs = tabs + "\t";
    }
    return tabs;
  }

  int[] arrayFindString( string inputList[], string searchFor ) {
    int indexList[] = {};
    int i;
    string tempStr;
    for ( i=0; i<inputList.entries(); i++ ) {
      tempStr = inputList[i];
      if (tempStr.index(searchFor) > -1) {
        indexList.append(i);
      }
    }
    return indexList;
  }

  string append( string str1, string str2 ) {
      str1 = str1 + str2;
      return str1;
  }

  string[] split( string Input, string Search ) {
      string out[] = {};
      int i;
      int i0 = 0;
      int i1 = 0;

      // cout << "** Input: " << Input << " Search: " << Search << endl;
      // Does Input contain Search?
      i1 = Input.index(Search, i0);
      // cout << i0 << " " << i1 << endl;

      while ( i1 > -1 ) {
          // cout <<
          out.append( Input.substr(i0,i1-i0) );
          // cout << "** Output: " << out << endl;
          // Does truncated Input contain Search?
          i0 = i1+1;
          i1 = Input.index(Search, i0);
          // cout << i0 << " " << i1 << endl;
      }
      // Capture last entry
      if ( Input.length() > i0+1 ){
        i1 = Input.length();
        out.append( Input.substr(i0,i1-i0) );
      }
      // cout << "** Output: " << out << endl;

      return out;
  }

      string queryAttr( string Obj, string Attr[], string sep ) {
        string out;
        int i;
        string n;
        string lhs, rhs;
        out = "";
        for ( i = 0; i < Attr.entries(); i++ ) {
            n = Obj + "." + Attr[i];
            if ( exists(n) ) {
              out.append( Attr[i] );
              out.append( "\t=\t" );
              // cout << "gml: " << n << endl;
              if ( n->getDataType() == "string") {
                out.append( "'"+toStr(evalExpr(n))+"'" );
              // } else if (exists(n+".units") ) {
              } else if ( n->getDataType() == "real") {
                lhs = n->units;
                if ( lhs != "") {
                  rhs = unitPref.getUnitPref(lhs);
                  out.append(toStr(convertUnits(n,rhs)));
                  out.append(" ["+rhs+"]");
                } else {
                  out.append( toStr(evalExpr(n)) ); 
                  out.append(" ["+n->units+"]");  
                }
              } else if (exists(n+".units") ) {
                out.append( toStr(evalExpr(n)) ); 
                out.append(" ["+n->units+"]");
              } else {
                out.append( toStr(evalExpr(n)) ); 
              }
              // out.append( toStr(evalExpr(n)) );
              // if ( n.index("(") < 0 ) {
              //     out.append(" ["+n->units+"]");
              // }
              out.append(sep);
            } else {
              // cerr << "WARNING: Variable '" << n << "' does not exist" << endl;
            }
        }
        // Replace " with '
        while ( out.index("\"") > -1 ) {
            out.replace("\"","'");
        }
        // Replace , with ;\n
        while ( out.index(",") > -1 ) {
            out.replace(",",";\n");
        }
        // Replace ; with , to form ,\n
        while ( out.index(";") > -1 ) {
            out.replace(";",",");
        }
        return out;
    }

    string queryAttrOld( string Obj, string Attr[], string sep ) {
        string out;
        int i;
        string n;
        out = "";
        for ( i = 0; i < Attr.entries(); i++ ) {
            n = Obj + "." + Attr[i];
            if ( exists(n) ) {
              out.append( Attr[i] );
              out.append( "\t=\t" );
              out.append( toStr(evalExpr(n)) );
              if ( n.index("(") < 0 ) {
                  out.append(" ["+n->units+"]");
              }
              out.append(sep);
            } else {
              // cerr << "WARNING: Variable '" << n << "' does not exist" << endl;
            }
        }
        // Replace " with '
        while ( out.index("\"") > -1 ) {
            out.replace("\"","'");
        }
        // Replace , with ;\n
        while ( out.index(",") > -1 ) {
            out.replace(",",";\n");
        }
        // Replace ; with , to form ,\n
        while ( out.index(";") > -1 ) {
            out.replace(";",",");
        }
        return out;
    }

}

void saveFlowSheet(int verbose) {
    gml.VERBOSE = verbose;
    gml.setGmlFile( strFmt("case.%06d.%01d.gml", CASE, gml.VERBOSE) );
    gml.genVerboseGml( gml.VERBOSE );
    // close output stream
    gml.os_gml.close();
}

void saveFlowSheets() {
    int i;
    for (i=0; i<5; i++) {
        saveFlowSheet(i);
    }
}

#endif

/*

create top level list off assemblies
Move local search to createDotAssembly
1. createDotAssembly checks local assembly list against list of completed assemblies
2. if not in completed list, call createDotAssembly on new assembly
3. once asse,bly is copmleted, add that assembly to list of completed assemblies, move back up a level
4. repeate

 */
