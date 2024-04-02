import numpy as np
from numpy import sin, cos, pi
from skimage import measure
import matplotlib.pyplot as plt
import matplotlib.colors as colors
import matplotlib.cm as cmx
from mpl_toolkits.mplot3d import Axes3D
import scipy


def filterDataSet(dfC):
    dfM = dfC
    # Mask values where Compressors are not feasable
    # dfC.where( dfC['Cmp.Cmp.alpha'] < -59 )
    dfM = dfM.mask( (dfM['Cmp.Cmp.alpha'] < -59) )
    dfM = dfM.mask( (dfM['Cmp.Cmp.alpha'] > 9) )
    dfM = dfM.mask( (dfM['ReCmp.Cmp.alpha'] < -59) )
    dfM = dfM.mask( (dfM['ReCmp.Cmp.alpha'] > 9) )
    print "Filtering on Compressor alpha"
    return dfM

def getScalarMap(vol, cmap='jet'):
    jet = cm = plt.get_cmap('jet') 
    cNorm  = colors.Normalize(vmin=vol.min(), vmax=vol.max())
    # scalarMap = cmx.ScalarMappable(norm=cNorm, cmap=jet)
    scalarMap = cmx.ScalarMappable(norm=cNorm)
    scalarMap._A = [] # for plt.colormap(scalarMap)
    # print scalarMap.get_clim()
    return scalarMap

def myMarching(x, y, z, vol, level):
    from skimage import measure
    # vertsIJK, faces = measure.marching_cubes_classic(vol, level)
    vertsIJK, faces, _, values = measure.marching_cubes_lewiner(vol, level)
    # print "vertsIJK", shape(vertsIJK)

    
    #  Coordinate space
    # i, j, k = np.arange(len(x)), np.arange(len(y)), np.arange(len(z))
    i, j, k = [np.arange(n) for n in x.shape]
    I, J, K = np.meshgrid(i,j,k)

    vertsXYZ = np.zeros_like(vertsIJK)
    IJK = np.stack([I.ravel(), J.ravel(), K.ravel()],axis=1)
    
    # https://docs.scipy.org/doc/scipy-0.16.1/reference/generated/scipy.interpolate.RegularGridInterpolator.html
    from scipy.interpolate import RegularGridInterpolator
    # X = scipy.interpolate.griddata(IJK, x.ravel(), vertsIJK)
    # Y = scipy.interpolate.griddata(IJK, y.ravel(), vertsIJK)
    # Z = scipy.interpolate.griddata(IJK, z.ravel(), vertsIJK)
    # print "x", shape(x)
    # print "i", shape(i)
    # print "j", shape(j)
    # print "k", shape(k)

    # # print zip(i,j,k)
    # for r in vertsIJK:
    # 	print r

    	
    xFun = RegularGridInterpolator((i,j,k), x)
    X = xFun(vertsIJK)

    yFun = RegularGridInterpolator((i,j,k), y)
    Y = yFun(vertsIJK)

    zFun = RegularGridInterpolator((i,j,k), z)
    Z = zFun(vertsIJK)

    vertsXYZ[:,0] = X.ravel()
    vertsXYZ[:,1] = Y.ravel()
    vertsXYZ[:,2] = Z.ravel()

    return vertsXYZ, faces, values


def myMarchingVect(x, y, z, vol, level, xTol=1, yTol=1, zTol=1):

    # dfC['xVar'] = np.round(dfC[xVar] / xTol ) * xTol
    # dfC['yVar'] = np.round(dfC[yVar] / yTol ) * yTol
    # dfC['zVar'] = np.round(dfC[zVar] / zTol ) * zTol

    # sh = [unique(z).shape[0],unique(y).shape[0],unique(x).shape[0]]
    sh = [  
            unique(np.round(z/zTol)*zTol).shape[0],
            unique(np.round(y/yTol)*yTol).shape[0],
            unique(np.round(x/xTol)*xTol).shape[0]
            ]

    # print "z", unique(np.round(z/zTol)*zTol)
    # print "y", unique(np.round(y/yTol)*yTol)
    # print "x", unique(np.round(x/xTol)*xTol)


    # X, Y, Z = np.meshgrid(np.unique(x),np.unique(y),np.unique(z))
    X = x.reshape(sh)
    Y = y.reshape(sh)
    Z = z.reshape(sh)
    VOL = vol.reshape(sh)

    vertsXYZ, faces, values = myMarching(X, Y, Z, VOL, level)
    return vertsXYZ, faces, values


def tolValue(xVar, xTol):
    return np.round(xVar/xTol)*xTol

def reduce3Dto2D(df,xVar,yVar,zVar,xTol=1E-4,yTol=1E-4):
    # Turn sweep over PHIGH, PLOW, splitfrac into an array

    xVals = np.sort(np.unique(np.round(df[xVar].values/xTol)*xTol))
    yVals = np.sort(np.unique(np.round(df[yVar].values/yTol)*yTol))

    print 'Debug xVals', xVals
    print 'Debug yVals', yVals

    [X, Y] = np.meshgrid(xVals, yVals)
    Z = np.zeros_like(X).flatten()
    Zindex = np.zeros_like(X).flatten()
    # zVarMax = np.zeros_like(X).flatten()

    for i, [x, y] in enumerate(zip(X.ravel(), Y.ravel())):
        mX = (np.round(df[xVar].values/xTol)*xTol == x)
        mY = (np.round(df[yVar].values/yTol)*yTol == y)
        mask = mX * mY
        mask = mask.reshape(np.shape(df[zVar]))
        # print mask

        # try:
        # print shape(df[zVar]), shape(mask)
        Zindex[i] = df[zVar].where(mask).idxmax()
        # except:
            # Zindex[i] = np.nan

        # try:
        Z[i] = df[zVar].where(mask).max()
        # except:
            # Z[i] = np.nan

    Zindex = Zindex.reshape(X.shape)
    Z = Z.reshape(X.shape)

    # print X
    # print Y
    # print Z
    # print Zindex

    return X, Y, Z, Zindex



if __name__ == '__main__':

    if True:

        # xVar = ['Split.BldOutReCmp.fracW']
        # xTol = 0.01
        # yVar = ['Perf.pwrLoad']
        # yTol = 0.1
        # zVar = ['Cmp.Fl_I.Pt']
        # zTol = 0.1

        xVar = ['Perf.pwrLoad']
        xTol = 0.1
        yVar = ['Cmp.Cmp.Fl_I.Pt']
        yTol = 1.0
        zVar = ['Split.BldOutReCmp.fracW']
        zTol = 0.01

        cVar = ['Perf.eff']
        # cVar = ['Trb.Trb.Fl_I.Pt']
        # cVar = ['HxHigh.Hx.Fl_I1.Tt']


        # for v, t in zip([xVar, yVar, zVar], [xTol, yTol, zTol])
        dfC['xVar'] = np.round(dfC[xVar] / xTol ) * xTol
        dfC['yVar'] = np.round(dfC[yVar] / yTol ) * yTol
        dfC['zVar'] = np.round(dfC[zVar] / zTol ) * zTol

        dfC.drop_duplicates(subset=['xVar', 'yVar', 'zVar'], inplace=True)
        dfC.set_index([range(len(dfC))],inplace=True)
        dfC = dfC.sort_values(xVar).sort_values(yVar).sort_values(zVar)

        # dfM = filterDataSet(dfC)
        dfM = dfC


        # plt.figure(10)
        # plt.clf()
        # plt.scatter(df[xVar],df[yVar],edgecolors=None,c=df[cVar])

        # plt.figure(11)
        # plt.clf()
        # ax = plt.subplot(1,1,1,projection='3d')
        # for df in frames:
        #     ax.scatter(df[xVar],df[yVar],df[zVar],c=df[cVar])
        # # plt.colorbar()

        plt.figure(12)
        plt.clf()
        ax = plt.subplot(1,1,1,projection='3d')
        sm = getScalarMap(dfC[cVar])
        c = sm.to_rgba(dfC[cVar].values)
        c = dfC[cVar[0]].values
        sc = ax.scatter(dfC[xVar],dfC[yVar],dfC[zVar],c=c,cmap=sm.get_cmap())
        # plt.colorbar(sc)
        plt.show()
        # ax.plot_wireframe(dfC[xVar],dfC[yVar],dfC[zVar])
        # ax.plot3D(dfC[xVar],dfC[yVar],dfC[zVar])

        plt.figure(13)
        plt.clf()
        ax = plt.subplot(1,1,1,projection='3d')
        sm = getScalarMap(dfM[cVar])
        c = sm.to_rgba(dfM[cVar].values)
        c = dfM[cVar[0]].values
        sc = ax.scatter(dfM[xVar],dfM[yVar],dfM[zVar],c=c,cmap=sm.get_cmap())
        # plt.colorbar(sc)
        plt.show()





    if True:


        from skimage import measure
        # # vol = array(zip())
        # x = dfC['xVar']
        vol = dfM[[xVar[0], yVar[0], zVar[0]]].values
        # verts, faces = measure.marching_cubes_classic(vol, 0, spacing=(0.1, 0.1, 0.1))


        # plt.figure(13)
        # plt.clf()
        # dfM = frames[0]
        # for i, fr in enumerate(frames[1:]):
        #     dfM = pd.merge(dfM, fr, how='outer')
        # ax = plt.subplot(1,1,1,projection='3d')
        # ax.scatter(dfC[xVar],dfC[yVar],dfC[zVar],c=dfC[cVar])



    if True:


        myPlots = [
                    [
                    'Perf.eff',
                    ],
                    # [
                    # 'Cmp.Cmp.isenEff',
                    # 'ReCmp.Cmp.isenEff',
                    # 'Trb.Trb.eff',
                    # ],
                    # [
                    # 'Trb.Trb.Fl_I.Pt',
                    # 'Trb.Trb.Fl_I.W',
                    # ],
                    # [
                    # 'Trb.Trb.Fl_I.Tt',
                    # 'Cmp.Cmp.Fl_I.Tt',
                    # 'HxHigh.Hx.Fl_I1.Tt',
                    # 'HxLow.Hx.Fl_I1.Tt',
                    # ],
                    [
                    'Post.systemFluidMass'
                    ],
                    ['Cmp.Cmp.alpha',],
                    ['ReCmp.Cmp.alpha',],
                    ['Post.systemFluidMass',],
                    ['solver.converged',],
                    # zVar
                ]

        x = dfC[xVar].values
        y = dfC[yVar].values
        z = dfC[zVar].values
        cc = dfC[cVar].values

    if True:

        nLevels = 5
        ptAlpha = 0.8
        surfAlpha = 0.5

        for f, channels in enumerate(myPlots):
            plt.figure(100+f)
            nr = ceil(sqrt(len(channels)))
            nc = ceil(len(channels)*1.0/nr)
            axList = []

            for i, ch in enumerate(channels):
                if len(axList) > 0:
                    axList.append(plt.subplot(nr,nc,i+1,sharex=axList[0], projection='3d'))
                else:
                    axList.append(plt.subplot(nr,nc,i+1,projection='3d'))

                c = dfM[ch].values
                sm = getScalarMap(c)

                sM = 1/(cc.max() - cc)

                axList[-1].scatter(x, y, z, c=c, s=sM, alpha=ptAlpha, cmap=sm.get_cmap())
                cb = plt.colorbar(sm)
                cb.set_label('Scater '+ch)

                Levels = np.linspace(np.nanmin(c), np.nanmax(c), nLevels+2)[1:-1]
                # Levels = Levels[1:-1]
                for l in Levels:
                    # print "processing level", l
                    verts, faces, values = myMarchingVect(x, y, z, c, l, xTol=xTol, yTol=yTol, zTol=zTol)

                    collec = axList[-1].plot_trisurf(verts[:, 0], verts[:,1], faces, verts[:, 2], alpha=surfAlpha, cmap=sm.get_cmap())
                    collec.set_facecolor(sm.to_rgba(values*0+l))

                cb1 = plt.colorbar(sm, ticks=Levels)
                cb1.set_label('Iso-Surface '+ch)


                axList[-1].set_xlabel(xVar[0])
                axList[-1].set_ylabel(yVar[0])
                axList[-1].set_zlabel(zVar[0])
                # plt.legend(loc='upper left')
                plt.legend()
                plt.grid()
                        

            fig = plt.gcf()
            fig.set_size_inches(11*1.5, 8.5*1.5)
            # fig.savefig('test2png.png', dpi=100)
            plt.savefig('composite_3d_%05g.png'%(f), dpi=150)

        plt.show()

    if True:

        

        # myPlots = [
        #             [
        #             'Perf.eff',
        #             ],
        #             [
        #             'Cmp.Cmp.isenEff',
        #             'ReCmp.Cmp.isenEff',
        #             'Trb.Trb.eff',
        #             ],
        #             [
        #             'Trb.Fl_I.Pt',
        #             'Trb.Fl_I.W',
        #             ],
        #             [
        #             'HxHigh.Fl_I1.Tt',
        #             'HxLow.Fl_I1.Tt',
        #             # 'HxHigh.Hx.approach_hot',
        #             # 'HxLow.Hx.approach_hot',
        #             # 'HxHigh.Hx.approach_cold',
        #             # 'HxLow.Hx.approach_cold',
        #             ],
        #         ]

        # x = dfC[xVar].values
        # y = dfC[yVar].values
        # z = dfC[zVar].values
        # cc = dfC[cVar].values

        nLevels = 5
        ptAlpha = 0.8
        surfAlpha = 0.5

        X, Y, Z, Zindex = reduce3Dto2D(dfM, xVar, yVar, cVar, xTol=xTol, yTol=yTol)
        for f, channels in enumerate(myPlots):
            plt.figure(200+f)
            nr = ceil(sqrt(len(channels)))
            nc = ceil(len(channels)*1.0/nr)
            axList = []

            for i, ch in enumerate(channels):
                if len(axList) > 0:
                    axList.append(plt.subplot(nr,nc,i+1,sharex=axList[0]))
                else:
                    axList.append(plt.subplot(nr,nc,i+1))

                c = dfC[ch].values
                sm = getScalarMap(c)

                Z2 = dfC.iloc[Zindex.flatten().tolist()][ch].values.reshape(X.shape)
                axList[-1].contourf(X,Y,Z2,21,cmap=sm.get_cmap())
                cb = plt.colorbar(sm)
                cb.set_label(ch)


                # sM = 1/(cc.max() - cc)

                # axList[-1].scatter(x, y, z, c=c, s=sM, alpha=ptAlpha)
                # cb = plt.colorbar(sm)
                # cb.set_label('Scater '+ch)

                # Levels = np.linspace(c.min(), c.max(), nLevels+2)[1:-1]
                # # Levels = Levels[1:-1]
                # for l in Levels:
                #     # print "processing level", l
                #     verts, faces, values = myMarchingVect(x, y, z, c, l, xTol=xTol, yTol=yTol, zTol=zTol)

                #     collec = axList[-1].plot_trisurf(verts[:, 0], verts[:,1], faces, verts[:, 2], alpha=surfAlpha)
                #     collec.set_facecolor(sm.to_rgba(values*0+l))

                # cb1 = plt.colorbar(sm, ticks=Levels)
                # cb1.set_label('Iso-Surface '+ch)


                axList[-1].set_xlabel(xVar[0])
                axList[-1].set_ylabel(yVar[0])
                # axList[-1].set_zlabel(zVar[0])
                # plt.legend(loc='upper left')
                plt.legend()
                plt.grid()
                        

            plt.show()
            fig = plt.gcf()
            fig.set_size_inches(11*1.5, 8.5*1.5)
            # fig.savefig('test2png.png', dpi=100)
            plt.savefig('composite_2d_contour_%05g.png'%(f), dpi=150)        


            plt.figure(300+f)
            nr = ceil(sqrt(len(channels)))
            nc = ceil(len(channels)*1.0/nr)
            axList = []

            for i, ch in enumerate(channels):
                if len(axList) > 0:
                    axList.append(plt.subplot(nr,nc,i+1,sharex=axList[0],projection='3d'))
                else:
                    axList.append(plt.subplot(nr,nc,i+1,projection='3d'))

                c = dfC[ch].values
                sm = getScalarMap(c)

                Z2 = dfC.iloc[Zindex.flatten().tolist()][ch].values.reshape(X.shape)
                collec = axList[-1].plot_surface(X,Y,Z2,cmap=sm.get_cmap())
                # ,color=sm.to_rgba(Z2.flatten())
                collec.set_facecolor(sm.to_rgba(Z2.flatten()))
                cb = plt.colorbar(sm)
                cb.set_label(ch)


                # sM = 1/(cc.max() - cc)

                # axList[-1].scatter(x, y, z, c=c, s=sM, alpha=ptAlpha)
                # cb = plt.colorbar(sm)
                # cb.set_label('Scater '+ch)

                # Levels = np.linspace(c.min(), c.max(), nLevels+2)[1:-1]
                # # Levels = Levels[1:-1]
                # for l in Levels:
                #     # print "processing level", l
                #     verts, faces, values = myMarchingVect(x, y, z, c, l, xTol=xTol, yTol=yTol, zTol=zTol)

                #     collec = axList[-1].plot_trisurf(verts[:, 0], verts[:,1], faces, verts[:, 2], alpha=surfAlpha)
                #     collec.set_facecolor(sm.to_rgba(values*0+l))

                # cb1 = plt.colorbar(sm, ticks=Levels)
                # cb1.set_label('Iso-Surface '+ch)


                axList[-1].set_xlabel(xVar[0])
                axList[-1].set_ylabel(yVar[0])
                # axList[-1].set_zlabel(zVar[0])
                # plt.legend(loc='upper left')
                plt.legend()
                plt.grid()
                        

            plt.show()
            fig = plt.gcf()
            fig.set_size_inches(11*1.5, 8.5*1.5)
            # fig.savefig('test2png.png', dpi=100)
            plt.savefig('composite_2d_surf_%05g.png'%(f), dpi=150)        