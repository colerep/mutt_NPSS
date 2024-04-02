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

## Set font size
# font = {'family' : 'normal',
#         'weight' : 'normal',
#         'size'   : 8}
# matplotlib.rc('font', **font)

#import seaborn as sns

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


import argparse

parser = argparse.ArgumentParser(description='Process some data.')
# parser.add_argument('-C', type=str, nargs='+', help='file(s) to process')
parser.add_argument('-C', type=str, help='file(s) to process')
parser.add_argument('-D', type=str, help='file(s) to process')
parser.add_argument('-converged', action='store_true', default=False)

if __name__ == '__main__':
    args = parser.parse_args()
    # print caseFile
    # print args.caseFile

    eps = np.finfo(float).eps

    plotScale = 1.5;

    # caseFile = 'rcbcHtr_preheat_700C_1200C/rcbcHtr_preheat_700C_1200C.solver'
    # caseFile = 'test.solver'
    # caseFile = 'caseRecompression.solver'
    caseFile = args.C
    debugFile = args.D
    if not debugFile:
        debugFile = caseFile + '.debug'
    print debugFile

    xFile = caseFile + '.x'
    errorFile = caseFile + '.errorCon'
    # debugFile = caseFile + '.debug'
    rowFile = caseFile + '_row.out'

    doInit = 1
    if True:

        # Read solver data frame
        df = loadFiles(rowFile)
        if args.converged:
            df = df[ df['solver.converged'] == 1 ]

        if True:
            xVar = 'CASE'
            x = df[xVar].values
        else:
            x = df.index.values


        # df = pd.read_csv(rowFile, delim_whitespace=True, skiprows=2)
        # # Remove NaN's
        # # data['dir'] = d
        # df['file'] = rowFile
        # df.dropna(inplace=True)

        # Read x variables from file
        # xKeys = [ ]
        xF = open(xFile,'r')
        # dfTemp = loadFiles(xFile)
        xKeys = xF.readline().split()
        xF.close()
        xKeys = ["%s.x"%s for s in xKeys]
        xKeys = [['CASE', 'solver.converged']] + xKeys

        # Read errorCon variables from file    
        # errorKeys = [ ]
        xF = open(errorFile,'r')
        # dfTemp = loadFiles(xFile)
        errorKeys = xF.readline().split()
        xF.close()
        errorKeys = ["%s.errorCon"%s for s in errorKeys]
        errorKeys = [['CASE', 'solver.converged']] + errorKeys

        if os.path.exists(debugFile):
            xF = open(debugFile,'r')
            # dfTemp = loadFiles(xFile)
            debugKeys = xF.readlines()
            xF.close()
            debugKeys = [s.split() for s in debugKeys]
            print debugKeys
        # except e:
        #     print e
        else:
            print debugFile, " does not exist"
            debugKeys = []


        # # loop over variables and plot dataframe
        # dfKeys = [
        #     xKeys,
        #     errorKeys,
        # ]

        # for j, keys in enumerate(debugKeys): # Multiple figures by line [list of list]
        if len(debugKeys):
            for j, keys in enumerate([debugKeys]): # Multiple lines by plot [list of list of list]
            
                fig = plt.figure(4001+j)
                plt.clf()

                # 2d
                # ax = plt.subplot(1,1,1)
                # ax.scatter(xr, yr, c=zr)
                
                # 3d
                # nk = len(dDict.keys())
                nk = len(keys)
                nr, nc = ceil(nk**0.5),round(nk**0.5)

                axList = []
                plt.subplots_adjust(top=0.925, bottom=0.075, left=0.075, right=0.925, hspace=0.3, wspace=0.3)
                for i, k in enumerate(keys):
                    # ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1)
                    # zz = df[k]
                    # # df[k].plot(logy=True,ax=ax)
                    # ax.plot(zz,logy=True)
                    # ax.scatter(x,zz)
                    # sm = getScalarMap(zz[~np.isnan(zz)].ravel(),cmap=cm.jet)
                    # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap)
                    # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap,facecolors=sm.to_rgba(zz))
                    # collec.set_facecolors(sm.to_rgba(np.nan_to_num(zz).flatten()))
                    # collec.set_facecolors(sm.to_rgba(zz.flatten()))
                    # plt.colorbar(sm)
                    # ax.set_xlabel(xVar)
                    # ax.set_ylabel(yVar)
                    # ax.set_zlabel(k)
                    # ax.set_title(k)
                    # ax.view_init(30,-140)
                    # axes.append(ax)

                    if len(axList) > 0:
                        axList.append(plt.subplot(nr,nc,i+1,sharex=axList[0]))
                    else:
                        axList.append(plt.subplot(nr,nc,i+1))
                    
                    # axList[-1].plot(x,df[k])
                    axList[-1].plot(x,df[k])
                    # axList[-1].set_ylim(ymin=1e-5)
                    axList[-1].grid(True)
                    # plt.legend(loc='upper left')
                    if type(k) is list:
                        plt.legend(k,fontsize='x-small')
                    else:
                        plt.legend(fontsize='x-small')

                # fig.set_size_inches(11*plotScale, 8.5*plotScale)
                plt.savefig('%s.png'%(debugFile), dpi=150)



        for j, keys in enumerate([xKeys]):
        
            fig = plt.figure(2001+j)
            plt.clf()

            # 2d
            # ax = plt.subplot(1,1,1)
            # ax.scatter(xr, yr, c=zr)
            
            # 3d
            # nk = len(dDict.keys())
            nk = len(keys)
            nr, nc = ceil(nk**0.5),round(nk**0.5)

            axList = []
            plt.subplots_adjust(top=0.925, bottom=0.075, left=0.075, right=0.925, hspace=0.3, wspace=0.3)
            for i, k in enumerate(keys):
                # ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1)
                # zz = df[k]
                # # df[k].plot(x,logy=True,ax=ax)
                # ax.plot(x,zz,logy=True)
                # ax.scatter(x,zz)
                # sm = getScalarMap(zz[~np.isnan(zz)].ravel(),cmap=cm.jet)
                # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap)
                # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap,facecolors=sm.to_rgba(zz))
                # collec.set_facecolors(sm.to_rgba(np.nan_to_num(zz).flatten()))
                # collec.set_facecolors(sm.to_rgba(zz.flatten()))
                # plt.colorbar(sm)
                # ax.set_xlabel(xVar)
                # ax.set_ylabel(yVar)
                # ax.set_zlabel(k)
                # ax.set_title(k)
                # ax.view_init(30,-140)
                # axes.append(ax)

                if len(axList) > 0:
                    axList.append(plt.subplot(nr,nc,i+1,sharex=axList[0]))
                else:
                    axList.append(plt.subplot(nr,nc,i+1))
                
                # axList[-1].plot(x,df[k])
                axList[-1].plot(x,df[k])
                # axList[-1].set_ylim(ymin=1e-5)
                axList[-1].grid(True)
                # plt.legend(loc='upper left')
                if type(k) is list:
                    plt.legend(k,fontsize='x-small')
                else:
                    plt.legend(fontsize='x-small')

            # fig.set_size_inches(11*plotScale, 8.5*plotScale)
            plt.savefig('%s.png'%(xFile), dpi=150)

        for j, keys in enumerate([errorKeys]):
        
            fig = plt.figure(3001+j)
            plt.clf()

            # 2d
            # ax = plt.subplot(1,1,1)
            # ax.scatter(xr, yr, c=zr)
            
            # 3d
            # nk = len(dDict.keys())
            nk = len(keys)
            nr, nc = ceil(nk**0.5),round(nk**0.5)

            axList = []
            plt.subplots_adjust(top=0.925, bottom=0.075, left=0.075, right=0.925, hspace=0.3, wspace=0.3)
            for i, k in enumerate(keys):
                # ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1)
                # zz = df[k]
                # # df[k].plot(x,logy=True,ax=ax)
                # ax.plot(x,zz,logy=True)
                # ax.scatter(zz)
                # sm = getScalarMap(zz[~np.isnan(zz)].ravel(),cmap=cm.jet)
                # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap)
                # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap,facecolors=sm.to_rgba(zz))
                # collec.set_facecolors(sm.to_rgba(np.nan_to_num(zz).flatten()))
                # collec.set_facecolors(sm.to_rgba(zz.flatten()))
                # plt.colorbar(sm)
                # ax.set_xlabel(xVar)
                # ax.set_ylabel(yVar)
                # ax.set_zlabel(k)
                # ax.set_title(k)
                # ax.view_init(30,-140)
                # axes.append(ax)

                if len(axList) > 0:
                    axList.append(plt.subplot(nr,nc,i+1,sharex=axList[0]))
                else:
                    axList.append(plt.subplot(nr,nc,i+1))
                
                # axList[-1].plot(x,df[k])
                axList[-1].semilogy(np.abs(df[k])+eps)
                axList[-1].set_ylim(ymin=1e-5)
                axList[-1].grid(True)
                # plt.legend(loc='upper left')
                if type(k) is list:
                    plt.legend(k,fontsize='x-small')
                else:
                    plt.legend(fontsize='x-small')

            # fig.set_size_inches(11*plotScale, 8.5*plotScale)
            plt.savefig('%s.png'%(errorFile), dpi=150)


            if doInit:
                plt.show()
            else:
                plt.draw()

            # time.sleep(5)


    print 'Complete', time.ctime()