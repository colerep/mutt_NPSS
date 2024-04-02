# Notes
# 
# 3d rendering
# https://plot.ly/python/isosurfaces-with-marching-cubes/
# https://stackoverflow.com/questions/6030098/how-to-display-a-3d-plot-of-a-3d-array-isosurface-in-matplotlib-mplot3d-or-simil
# https://www.google.com/search?q=python+3d+isosurface&rlz=1C1CHFX_enUS712US712&oq=python+3d+isosurface&aqs=chrome..69i57j69i65l3j69i60l2.4981j0j7&sourceid=chrome&ie=UTF-8


import os
import glob
import fnmatch
import numpy as np

import timeit
def toc(tic, label=""):
    _toc = timeit.default_timer() - tic
    print 'Toc {} (s): {}'.format(_toc, label)
    return _toc

# Plotting
import matplotlib
# matplotlib.use('Qt4Agg') # 340 (s)
# matplotlib.use('TkAgg') # 320 (s) # 22 (s) hue = None
# matplotlib.use('GTKAgg') # Not Supported
# matplotlib.use('WXAgg') #
# matplotlib.use('GTKCairo') # Not supported
print matplotlib.get_backend()

import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as colors
import matplotlib.cm as cmx

import numpy as np
import pandas as pd

#import seaborn as sns

from myDataFramePlots import *

def loadFiles(files):
    frames = []
    for f in [files]:
        print "Loading ", f
        try:
            # Load file
            data = pd.read_csv(f, delim_whitespace=True, skiprows=2)
            # Remove NaN's
            # data['dir'] = d
            data['file'] = f
            frames.append(data.dropna())
        except:
            None

    # Concatnate data frame
    df = pd.concat(frames)
    # Update index
    df.set_index([range(len(df))],inplace=True)

    df.describe()

    return df


def processData2D(df,xVar,yVar,zVar,xTol=1E-4,yTol=1E-4):
    # Turn sweep over PHIGH, PLOW, splitfrac into an array

    xVals = np.sort(np.unique(round(df[xVar]/xTol)*xTol))
    yVals = np.sort(np.unique(round(df[yVar]/yTol)*yTol))

    print 'Debug xVals', xVals
    print 'Debug yVals', yVals

    [X, Y] = np.meshgrid(xVals, yVals)
    Zindex = np.zeros_like(X).flatten()
    # zVarMax = np.zeros_like(X).flatten()

    for i, [x, y] in enumerate(zip(X.ravel(), Y.ravel())):
        # Zindex[i] = df[df['Cmp.Cmp.Fl_I.Pt']==x ]['Perf.effPlant'].idxmax()
        # Zindex[i] = df[(df['Cmp.Cmp.Fl_I.Pt']==x) & (df['Trb.Fl_I.Pt']==y) ][['Perf.effPlant']].idxmax()
        # try: 
        # idx = df[(df[xVar]==x) & (df[yVar]==y) ][[zVar]].idxmax()
        # print df[ (abs(df[xVar]-x)<=0.0001) & (abs(df[yVar]-y)/y<=0.0001) ]
        print x, y
        dfTemp = df[ (abs(df[xVar]-x)<=xTol) & (abs(df[yVar]-y)/y<=yTol) ]
        if dfTemp.shape[0] > 0:
            idx = dfTemp[[zVar]].idxmax()
        else:
            idx = np.nan
        Zindex[i] = idx
        # except:
        # idx = np.nan
        # zVarMax[i] = df[df['Cmp.Cmp.Fl_I.Pt']==x ]['Perf.effPlant'].max()
        # zVarMax[i] = df[(df[xVar]==x) & (df[yVar]==y) ][[zVar]].max()

    Zindex = Zindex.reshape(X.shape)
    # zVarMax = zVarMax.reshape(X.shape)

    dfMask = df.iloc[Zindex.ravel()]

    return dfMask, X, Y

def processData1D(df,xVar,yVar,zVar):
    # Turn sweep over PHIGH, PLOW, splitfrac into an array

    xVals = np.sort(np.unique(df[xVar]))
    yVals = np.sort(np.unique(df[yVar]))
    print 'Debug xVals', xVals
    print 'Debug yVals', yVals

    [X] = np.meshgrid(xVals)
    Zindex = np.zeros_like(X).flatten()
    # zVarMax = np.zeros_like(X).flatten()

    for i, [x] in enumerate(X.ravel()):
        # Zindex[i] = df[df['Cmp.Cmp.Fl_I.Pt']==x ]['Perf.effPlant'].idxmax()
        # Zindex[i] = df[(df['Cmp.Cmp.Fl_I.Pt']==x) & (df['Trb.Fl_I.Pt']==y) ][['Perf.effPlant']].idxmax()
        # try: 
        # idx = df[(df[xVar]==x) & (df[yVar]==y) ][[zVar]].idxmax()
        # print df[ (abs(df[xVar]-x)<=0.0001) & (abs(df[yVar]-y)/y<=0.0001) ]
        print x
        idx = df[ (abs(df[xVar]-x)<=0.0001) ][[zVar]].idxmax()
        Zindex[i] = idx
        # except:
        # idx = np.nan
        # zVarMax[i] = df[df['Cmp.Cmp.Fl_I.Pt']==x ]['Perf.effPlant'].max()
        # zVarMax[i] = df[(df[xVar]==x) & (df[yVar]==y) ][[zVar]].max()

    Zindex = Zindex.reshape(X.shape)
    # zVarMax = zVarMax.reshape(X.shape)

    dfMask = df.iloc[Zindex.ravel()]

    return dfMask, X

if __name__ == '__main__':

    # files = [
    #   'sweep_700C_rowSI.out',
    #   'sweepV1_700_rowSI.out',
    #   'sweepV2_700_rowSI.out',
    #   'sweep_700C_nopreheat_rowSI.out',
    #   'sweepV1_700_nopreheat_rowSI.out',
    #   'sweepV2_700_nopreheat_rowSI.out'
    # ]
    # files = [
    #   'runCheck/rcbcTest_rowSI.out',
    #   'runCheck3/rcbcTest_rowSI.out',
    #   'runCheck4/rcbcTest_nopreheat_rowSI.out',
    #   ]
    # files = glob.glob('scratchCase_dp151hx25.case/scratch*[90]_rowSI.out')
    # files = glob.glob('scratchCase01hx/scratch*_rowSI.out')
    
    fileDir = 'scratchCase01hx'
    # fileDir = 'scratchCase_dp151hx.case'
    # fileDir = 'scratchCase01'
    # fileDir = 'scratchCase_dp151hx25.case'
    # fileDir = 'scratchCase_dp151hx30.case'
    # fileDir = 'scratchCase_dp151hx40.case'
    # fileDir = 'scratchCase_dp151hx50.case'

    #files = glob.glob('%s/scratch*_rowSI.out'%(fileDir))

    files = [ ]
    fileDir = 'rcbcSweep_700C_900C'
    files += glob.glob('%s/*_rowSI.out'%(fileDir))
    # fileDir = 'post_700C'
    # files = [ 'sweep_700C_rowSI.out' ]

    # files = [files[0:3]]

    # cols = [
    #     'file',
    #     'CASE', 
    #     'Trb.Fl_I.Tt', 
    #     'Trb.Fl_I.Pt', 
    #     'Trb.Fl_I.W', 
    #     'Trb.effDes', 
    #     'Cmp.Fl_I.Tt', 
    #     'Cmp.Fl_I.Pt', 
    #     'Cmp.effDes',
    #     'Split.BldOutReCmp.fracW', 
    #     # 'PerfPlant.eff', 
    #     # 'PerfBlock.eff', 
    #     # 'PerfPlant.pwrNet', 
    #     'Perf.eff', 
    #     'Perf.pwrNet', 
    #     'Perf.pwrLoad', 
    #     # 'Heater.Htr.Q', 
    #     # 'Heater.HxAirCO2.Q', 
    #     # 'Heater.Htr.Fl_O.Tt', 
    #     # 'Heater.HxAirCO2.Fl_I1.Tt', 
    #     # 'Heater.HxAirCO2.Fl_O1.Tt', 
    #     # 'Heater.HxAirCO2.Fl_O1.Pt', 
    #     # 'Heater.HxAirCO2.Fl_O1.W', 
    #     # 'Heater.HxAirCO2.Fl_I2.Tt', 
    #     # 'Heater.HxAirCO2.Fl_O2.Tt', 
    #     # 'Heater.HxAirCO2.Fl_O2.Pt', 
    #     # 'Heater.HxAirCO2.Fl_O2.W', 
    #     # 'Heater.HxAir.effect_des', 
    #     # 'Heater.HxAir.Fl_I1.W', 
    #     # 'Heater.HxAir.Fl_I2.W',
    #     'HxHigh.effect_h', 
    #     'HxLow.effect_h', 
    #     'Heater.HxAir.effect_h',
    #     'Heater.HxAirCO2.effect_h',
    #     'HxHigh.approach_min', 
    #     'HxLow.approach_min', 
    #     ]

    # varList = [
    #     'Perf.pwrLoad', 
    #     'Perf.eff', 
    #     'Cmp.Fl_I.Pt', 
    #     'Trb.Fl_I.Pt', 
    #     'Split.BldOutReCmp.fracW',
    #     ]

    xVar = 'Perf.pwrLoad'
    yVar = 'Cmp.Fl_I.Pt'
    # yVar = 'Trb.Fl_I.Pt'
    zVar = 'Split.BldOutReCmp.fracW'
    cVar = 'Perf.eff'

    if True:
        print "Loading files", files
        frames = []
        maxFrames = []
        for f in files:
            df = loadFiles(f)
            frames.append(df)

    if True:

        dfC = pd.concat(frames, axis=0)
        # dfC.dropna(inplace=True)
        dfC.set_index([range(len(dfC))],inplace=True)
        print "Loading Complete"

    if True:
        dfC.drop_duplicates(subset=[xVar, yVar, zVar], inplace=True)
        dfC.dropna(inplace=True)
        dfC.set_index([range(len(dfC))],inplace=True)
        dfC = dfC.sort_values(xVar).sort_values(yVar).sort_values(zVar)
        print "Removing duplicates"



# import fnmatch
# def PSItoBAR(inVal):
#     return inVal / 14.5

# cols = fnmatch.filter(dfC.columns, '*.Pt')
# dfC[cols] = dfC[cols].apply(PSItoBAR)

# def RtoC(inVal):
#     return inVal*0.555556 - 273.15

# cols = fnmatch.filter(dfC.columns, '*.Tt')
# dfC[cols] = dfC[cols].apply(RtoC)

# cols = fnmatch.filter(dfC.columns, '*.W')
# dfC[cols] = dfC[cols]/2.2
