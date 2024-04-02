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
parser.add_argument('caseFile', type=str, nargs='+',
                    help='a file to process')

if __name__ == '__main__':
    # caseFile = parser.parse_args('caseFile')
    # print caseFile

    eps = np.finfo(float).eps

    # caseFile = 'rcbcHtr_preheat_700C_1200C/rcbcHtr_preheat_700C_1200C.solver'
    # caseFile = 'test.solver'
    caseFile = 'caseRecompression.solver'
    
    xFile = caseFile + '.x'
    errorFile = caseFile + '.errorCon'
    rowFile = caseFile + '_row.out'
    debugFile = caseFile + '.debug'
    


    doInit = 1
    if True:
        # Read x variables from file
        # xKeys = [ ]
        xF = open(xFile,'r')
        # dfTemp = loadFiles(xFile)
        xKeys = xF.readline().split()
        xF.close()
        xKeys = ["%s.x"%s for s in xKeys]

        # Read errorCon variables from file    
        # errorConKeys = [ ]
        xF = open(errorFile,'r')
        # dfTemp = loadFiles(xFile)
        errorConKeys = xF.readline().split()
        xF.close()
        errorConKeys = ["%s.errorCon"%s for s in errorConKeys]

        # Read row.out into a data frame
        df = loadFiles(rowFile)

        try:
            xF = open(debugFile,'r')
            # dfTemp = loadFiles(xFile)
            debugKeys = xF.readlines()
            xF.close()
            debugKeys = [s.split() for s in debugKeys]
            print debugKeys
        except e:
            print e
            debugKeys = []


        # # loop over variables and plot dataframe
        # dfKeys = [
        #     xKeys,
        #     errorConKeys,
        # ]

        # for j, keys in enumerate(debugKeys): # Multiple figures by line [list of list]
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
                
                # axList[-1].plot(df[k])
                axList[-1].plot(df[k])
                # axList[-1].set_ylim(ymin=1e-5)
                axList[-1].grid(True)
                # plt.legend(loc='upper left')
                plt.legend(k)

            # fig.set_size_inches(11*plotScale, 8.5*plotScale)
            # plt.savefig('%s/post_matrix_%s_%g.png'%(fileDir, '3d', j), dpi=150)



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
                # # df[k].plot(logy=True,ax=ax)
                # ax.plot(zz,logy=True)
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
                
                # axList[-1].plot(df[k])
                axList[-1].plot(df[k])
                # axList[-1].set_ylim(ymin=1e-5)
                axList[-1].grid(True)
                # plt.legend(loc='upper left')
                plt.legend()

            # fig.set_size_inches(11*plotScale, 8.5*plotScale)
            # plt.savefig('%s/post_matrix_%s_%g.png'%(fileDir, '3d', j), dpi=150)

        for j, keys in enumerate([errorConKeys]):
        
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
                # # df[k].plot(logy=True,ax=ax)
                # ax.plot(zz,logy=True)
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
                
                # axList[-1].plot(df[k])
                axList[-1].semilogy(np.abs(df[k])+eps)
                axList[-1].set_ylim(ymin=1e-5)
                axList[-1].grid(True)
                # plt.legend(loc='upper left')
                plt.legend()

            # fig.set_size_inches(11*plotScale, 8.5*plotScale)
            # plt.savefig('%s/post_matrix_%s_%g.png'%(fileDir, '3d', j), dpi=150)


            if doInit:
                plt.show()
            else:
                plt.draw()

            # time.sleep(5)


    print 'Complete', time.ctime()