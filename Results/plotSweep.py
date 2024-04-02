# plotSweep.py

# Numerical
import pandas as pd
import numpy as np
import scipy

# Plotting
import matplotlib
import matplotlib.pyplot as plt
import seaborn as sns

# Fluid Properties
import CoolProp.CoolProp as CP
import CoolProp
# CP.set_config_string(CP.ALTERNATIVE_REFPROP_PATH, 'c:/REFPROP')

from CoolProp.Plots import PropertyPlot

# Units
from pint import UnitRegistry
ureg = UnitRegistry()
Q_ = ureg.Quantity

# Command Line Arguments
import argparse
parser = argparse.ArgumentParser(description='Process some data.')
parser.add_argument('-rowFile', help='CSV File with Data', type=str, default='case_rowSI.out')
parser.add_argument('-loadData', help='Load Data from file', action='store_true', default=False)
parser.add_argument('-doPlots', help='Create Plots', action='store_true', default=False)
parser.add_argument('-plotPh', help='Create Plots', action='store_true', default=False)

# Driver
if __name__ == "__main__":

    fluid='REFPROP::CO2'

    # Parse command line arguments
    args = parser.parse_args()


    # Load Data
    if args.loadData:

        # Read Data File
        dfData = pd.read_csv(args.rowFile, delim_whitespace=True, skiprows=2, na_values=["-1.#IND0"])

    if args.doPlots:

        plt.figure()
        plt.scatter(dfData['Stats.pwrGross'],dfData['Stats.Qout'])
        plt.xlabel('Gross Power [kW]')
        plt.ylabel('Heat Rejection [kW]')
        plt.grid()


        varList = [
            'Stats.pwrGross',
            'Stats.Qout',
            'HX1.Fl_O.Tt',
            'FS_MembraneExit.Fl_O.W'
        ]
        sns.pairplot(dfData[varList])


        plt.figure()
        ax = plt.subplot(3,1,1)
        x = np.arange(1,5)
        elementList = [ "HX{}".format(i) for i in x]
        y = dfData[[e+'.Q' for e in elementList ]]
        y.T.plot.bar(ax=ax)
        plt.ylabel('[kW]')

        ax = plt.subplot(3,1,2)
        # x = np.arange(1,5)
        # elementList = [ "HX{}".format(i) for i in x]
        y = dfData[[e+'.Fl_I.Tt' for e in elementList ]]
        y.T.plot.bar(ax=ax)
        plt.ylabel('[C]')

        ax = plt.subplot(3,1,3)
        # x = np.arange(1,5)
        # elementList = [ "HX{}".format(i) for i in x]
        y = dfData[[e+'.Fl_O.Tt' for e in elementList ]]
        y.T.plot.bar(ax=ax)
        plt.ylabel('[C]')

        plt.gcf().set_size_inches(8.5,11)
        plt.tight_layout()


        plt.figure()
        ax = plt.subplot(3,1,1)
        x = np.arange(1,4)
        elementList = [ "Cmp{}".format(i) for i in x]
        y = dfData[[e+'.pwr' for e in elementList ]]
        y.T.plot.bar(ax=ax)
        plt.ylabel('[kW]')

        ax = plt.subplot(3,1,2)
        # x = np.arange(1,5)
        # elementList = [ "HX{}".format(i) for i in x]
        y = dfData[[e+'.PR' for e in elementList ]]
        y.T.plot.bar(ax=ax)
        plt.ylabel('[-]')

        ax = plt.subplot(3,1,3)
        # x = np.arange(1,5)
        # elementList = [ "HX{}".format(i) for i in x]
        y = dfData[[e+'.Fl_O.Pt' for e in elementList ]]
        y.T.plot.bar(ax=ax)
        plt.ylabel('[bar]')


        plt.gcf().set_size_inches(8.5,11)
        plt.tight_layout()

    if args.plotPh:

        # plt.figure()

        # http://www.coolprop.org/apidoc/CoolProp.Plots.Plots.html

        # Create Base PH plot using coolprop
        ph_plot = PropertyPlot(fluid, 'ph', unit_system='EUR', tp_limits='NONE') #  
    
        # Add Quality Isolines (Plot the Dome)
        ph_plot.calc_isolines(CoolProp.iQ, num=11)

        # Configure isoline properties
        # ph_plot.props[CoolProp.iT]['color'] = 'green'
        # ph_plot.props[CoolProp.iT]['lw'] = '0.5'

        # Add Temperature Isolines
        ph_plot.calc_isolines(CoolProp.iT, iso_range=[0, 650], num=int(650/50+1))
            
        if True:
            # -- Add labels to temperature Isolines - Hack for Now
            # Get Isoline Temperatures, note that the isoline object stores in base SI units (K for Temp) 
            prop_iso = Q_([iso.value for iso in ph_plot.__dict__['_isolines'][CoolProp.iT]], 'degK').to('degC')
            # Set the plot y value to add labels at
            prop_y = Q_(np.ones(np.shape(prop_iso))*125, 'bar')
            # Calculate x value given a property pair H(TP)
            prop_x = CP.PropsSI('H', 'T', prop_iso.ravel().to('K').magnitude, 'P', prop_y.ravel().to('Pa').magnitude, fluid)
            # Add base SI units to x-value 
            prop_x = Q_(prop_x, 'J/kg')
            
            # Create Text String for labels
            prop_s = ['{:.0f} [{}]'.format(i.to('degC').magnitude, 'C') for i in prop_iso]

            # Rotation
            if False:

                # Does not factor in limits or aspect ratio of plot
                prop_y1 = Q_(np.ones(np.shape(prop_iso))*120, 'bar')
                prop_x1 = CP.PropsSI('H', 'T', prop_iso.ravel().to('K').magnitude, 'P', prop_y1.ravel().to('Pa').magnitude, fluid)
                prop_x1 = Q_(prop_x1, 'J/kg')
                rotation = np.arctan((prop_y1-prop_y).to('bar').magnitude / (prop_x1-prop_x).to('kJ/kg').magnitude) * 180/pi
            else:
                # Set constant rotation value
                rotation = np.ones(np.shape(prop_iso))*90

            # Add Text to Plot for every iSkip isolines
            iSkip=2
            # FOrmat the Bounding box, otherwise bbox=None
            bbox = dict( boxstyle="round", fc=(1,1,1), ec=(0.5,0.5,0.5) )
            # Loop over entries and add text to plot (text only takes scalers, not vectors)
            # Convert to plot coordinates
            for x, y, t, r in zip(prop_x[::iSkip].to('kJ/kg').magnitude,prop_y[::iSkip].to('bar').magnitude,prop_s[::iSkip],rotation[::iSkip]):
                print(x,y,t, r)
                plt.text(x, y, t, ha='center', va='center', rotation=r, fontsize='x-small', bbox=bbox)

        # More Isolines

        # Configure isoline properties
        ph_plot.props[CoolProp.iDmass]['color'] = 'green'
        ph_plot.props[CoolProp.iDmass]['lw'] = '0.5'
        # '-', '--', '-.', ':', 'None', ' ', '', 'solid', 'dashed', 'dashdot', 'dotted'
        ph_plot.props[CoolProp.iDmass]['ls'] = 'dashed'

        # Add Temperature Isolines
        ph_plot.calc_isolines(CoolProp.iDmass, iso_range=[0.1, 1000], num=21)

        if True:
            # -- Add labels to temperature Isolines - Hack for Now
            # Get Isoline Temperatures, note that the isoline object stores in base SI units (K for Temp) 
            prop_iso = Q_([iso.value for iso in ph_plot.__dict__['_isolines'][CoolProp.iDmass]], 'kg/m**3')
            # Set the plot y value to add labels at
            prop_y = Q_(np.ones(np.shape(prop_iso))*140, 'bar')
            # Calculate x value given a property pair H(TP)
            prop_x = CP.PropsSI('H', 'Dmass', prop_iso.ravel().to('kg/m**3').magnitude, 'P', prop_y.ravel().to('Pa').magnitude, fluid)
            # Add base SI units to x-value 
            prop_x = Q_(prop_x, 'J/kg').to('kJ/kg')
            
            # Create Text String for labels
            prop_s = ['{:.0f} [{}]'.format(i.to('kg/m**3').magnitude, 'kg/m3') for i in prop_iso]

            # Rotation
            if False:

                # Does not factor in limits or aspect ratio of plot
                prop_y1 = Q_(np.ones(np.shape(prop_iso))*120, 'bar')
                prop_x1 = CP.PropsSI('H', 'T', prop_iso.ravel().to('K').magnitude, 'P', prop_y1.ravel().to('Pa').magnitude, fluid)
                prop_x1 = Q_(prop_x1, 'J/kg')
                rotation = np.arctan((prop_y1-prop_y).to('bar').magnitude / (prop_x1-prop_x).to('kJ/kg').magnitude) * 180/pi
            else:
                # Set constant rotation value
                rotation = np.ones(np.shape(prop_iso))*90

            idx = prop_x.to('kJ/kg') > Q_(1100, 'kJ/kg')
            prop_x[idx] = Q_(1100, 'kJ/kg')
            prop_y[idx] = Q_(CP.PropsSI('P', 'Dmass', prop_iso[idx].ravel().to('kg/m**3').magnitude, 'H', prop_x[idx].ravel().to('J/kg').magnitude, fluid), 'Pa')
            rotation[idx] = 0


            # Add Text to Plot for every iSkip isolines
            iSkip=2
            # FOrmat the Bounding box, otherwise bbox=None
            bbox = dict( boxstyle="round", fc=(1,1,1), ec=(0.5,0.5,0.5) )
            # Loop over entries and add text to plot (text only takes scalers, not vectors)
            # Convert to plot coordinates
            for x, y, t, r in zip(prop_x[::iSkip].to('kJ/kg').magnitude,prop_y[::iSkip].to('bar').magnitude,prop_s[::iSkip],rotation[::iSkip]):
                print(x,y,t, r)
                plt.text(x, y, t, ha='center', va='center', rotation=r, fontsize='x-small', bbox=bbox)


        # Additional iso-lines
        # ph_plot.props[CoolProp.iSmass]['color'] = 'green'
        # ph_plot.props[CoolProp.iSmass]['lw'] = '0.5'
        # ph_plot.calc_isolines(CoolProp.iSmass, num=15)
        ph_plot.show()

        plt.gcf().set_size_inches(8.5,11)

        # executionSequence = [ "FS_MembraneExit", "Pipe0", "HX1", "Pipe1", "Cmp1", "Pipe2", "HX2", "Pipe3", "Cmp2", "Pipe4", "HX3", "Pipe5", "Cmp3", "Pipe6", "HX4", "FE_Storage", "Gen", "Sh", "Stats" ]
        elementList = [ "TsPump", "Sunshot", "Valve1", "Valve2", "Heater", "Cooler", "Looppipe"] #, "FE_Storage" ]
        Pt_List = [e+'.Fl_O.Pt' for e in elementList ]
        Tt_List = [e+'.Fl_O.Tt' for e in elementList ]
        ht_List = [e+'.Fl_O.ht' for e in elementList ]

        h = dfData[ht_List]
        p = dfData[Pt_List]
        t = dfData[Tt_List]

        P = Q_(p.values, 'bar')
        T = Q_(t.values, 'degC')

        # Test
        # P = Q_([1, 100], 'bar')
        # T = Q_([600, 20], 'degC')



        # Compute H wrt Coolprop Reference State using T and P
        # WARNING: This will fail if you have two=phase state points
        H = CP.PropsSI('H', 'T', T.ravel().to('K').magnitude, 'P', P.ravel().to('Pa').magnitude, fluid)
        # Todo: Check Output units for h, kJ/kg or J/kg?
        H = np.reshape(H,T.shape) * ureg.J / ureg.kg
    

        plt.scatter(H.to('kJ/kg').magnitude, P.to('bar').magnitude)

        for x, y in zip(H.to('kJ/kg').magnitude, P.to('bar').magnitude):
            plt.plot(x, y)

        plt.yscale('linear')
        plt.ylim([-10,150])
        plt.xlim([-10,1250])
        

        
        # ts_plot = PropertyPlot(fluid, 'Ts', tp_limits='ORC')
        # ts_plot.calc_isolines(CoolProp.iQ, num=6)
        # ts_plot.show()



    if False:
        # Save Figures
        for i in plt.get_fignums():
            plt.figure(i).savefig('plots_{:03}.png'.format(i))