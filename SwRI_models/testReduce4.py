def calcExergy(ht, s, href=-1.4705100e+05, sref=-1.2202811e+03, TtRef=3.4938580e+01+273.15):
    # href=-1.4705100e+05, sref=-1.2202811e+03, TtRef=3.4938580e+01+273.15
    # href=-198627.0, sref=-1393.20381, TtRef=34.972559999999994+273.15
    exergy = (ht - href) - TtRef*(s-sref)
    return exergy

def calcHxLoss(hxName,df):
    dfTemp[hxName+'.exLoss'] = 0
    for s in ['Fl_I', 'Fl_O']:
        for n in [ 1, 2 ]:
            name = hxName+"."+s+'%g'%(n)
            dfTemp[hxName+'.exLoss'] += dfTemp[name+'.W'] * calcExergy(dfTemp[name+'.ht'], dfTemp[name+'.s'])
    return df


def updateView(axes):
    ax = axes[0]
    el, az = ax.elev, ax.azim
    for ax in axes[1:]:
        ax.view_init(el,az)
    plt.draw()

def getScalarMap(vol, cmap='jet'):
    jet = cm = plt.get_cmap('jet') 
    cNorm  = colors.Normalize(vmin=vol.min(), vmax=vol.max())
    # scalarMap = cmx.ScalarMappable(norm=cNorm, cmap=jet)
    scalarMap = cmx.ScalarMappable(norm=cNorm)
    scalarMap._A = [] # for plt.colormap(scalarMap)
    # print scalarMap.get_clim()
    return scalarMap


def filterDataSet(dfC):
    dfM = dfC
    # Mask values where Compressor IGV angles are out of bounds

    # print "Filtering on Compressor alpha"
    # dfC.where( dfC['Cmp.Cmp.alpha'] < -59 )
    # dfM = dfM.mask( (dfM['Cmp.Cmp.alpha'] < -59) )
    # dfM = dfM.mask( (dfM['Cmp.Cmp.alpha'] > 9) )
    # dfM = dfM.mask( (dfM['ReCmp.Cmp.alpha'] < -59) )
    # dfM = dfM.mask( (dfM['ReCmp.Cmp.alpha'] > 9) )
    # dfM = dfM.mask( (dfM['Perf.eff'] < 0) )

    print "Filtering on Solver Converged"
    dfM = dfM.mask( (dfM['solver.converged'] < 1) )

    # print "Filtering on pwrLoad"
    # dfM = dfM.mask( (dfM['Perf.pwrLoad'] < 100) )

    
    return dfM


def reduce3Dto2D(df,xVar,yVar,zVar,xTol=1E-4,yTol=1E-4,dfKeys=[None]):
    # Turn sweep over PHIGH, PLOW, splitfrac into an array

    xVals = np.sort(np.unique(np.round(df[xVar].values/xTol)*xTol))
    yVals = np.sort(np.unique(np.round(df[yVar].values/yTol)*yTol))

    # print 'Debug xVals', xVals
    # print 'Debug yVals', yVals

    [X, Y] = np.meshgrid(xVals, yVals)
    Z = np.zeros_like(X).flatten()
    Zindex = np.zeros_like(X).flatten()
    # zVarMax = np.zeros_like(X).flatten()

    # for x in X.ravel():
    #     print 'x ', x

    # for y in Y.ravel():
    #     print 'y ', y

    dd = pd.DataFrame()

    dDict = {}
    for k in dfKeys:
        dDict[k] = (np.empty_like(X) * np.nan).flatten()


    for i, [x, y] in enumerate(zip(X.ravel(), Y.ravel())):
        # print i, x, y

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

        # print Zindex[i]
        if not np.isnan(Zindex[i]):
            dd = pd.DataFrame.append(dd,df.loc[[Zindex[i]]])
            for k in dfKeys:
                dDict[k][i] = df.loc[Zindex[i]][k]


        # Add dict with variables of interest

    Zindex = Zindex.reshape(X.shape)
    Z = Z.reshape(X.shape)
    Z[Z==-10] = np.nan

    for k in dfKeys:
        dDict[k] = dDict[k].reshape(shape(X))

    # // Addindex to a nanrow
    # Zindex[np.isnan(Zindex)] = df[df.isna()].index[0]

    # print X
    # print Y
    # print Z
    # print Zindex

    return X, Y, Z, Zindex, dd, dDict


if __name__ == '__main__':


    plotScale = 1.25

    # Define the sweep variables
    xVar = ['Trb.Fl_I.Pt']
    xTol = 1.0
    yVar = ['Cmp.Fl_I.Pt']
    yTol = 1.0
    zVar = ['Split.BldOutReCmp.fracW']
    zTol = 0.01

    # Performance metrics
    cVar = ['Perf.eff']
    # cVar = ['Trb.Fl_I.Pt']
    # cVar = ['HxHigh.Fl_I1.Tt']


    # for v, t in zip([xVar, yVar, zVar], [xTol, yTol, zTol])
    dfC['xVar'] = np.round(dfC[xVar] / xTol ) * xTol
    dfC['yVar'] = np.round(dfC[yVar] / yTol ) * yTol
    dfC['zVar'] = np.round(dfC[zVar] / zTol ) * zTol

    dfC.drop_duplicates(subset=['xVar', 'yVar', 'zVar'], inplace=True)
    dfC.set_index([range(len(dfC))],inplace=True)

    # Sorted array
    dfS = dfC.sort_values([zVar[0], yVar[0], xVar[0]])

    # Filtered arrat 
    dfM = filterDataSet(dfS)

    # dfM = calcHxLoss('HxHigh.Hx',dfM)
    # dfM = calcHxLoss('HxLow.Hx',dfM)

    # Calculate Exergy loss
    hxName = 'HxHigh'
    dfM[hxName+'.exLoss'] = 0
    for s in ['Fl_I', 'Fl_O']:
        for n in [ 1, 2 ]:
            name = hxName+"."+s+'%g'%(n)
            dfM[hxName+'.exLoss'] += dfM[name+'.W'] * calcExergy(dfM[name+'.ht'], dfM[name+'.s'])
        
    # Calculate Exergy loss
    hxName = 'HxLow'
    dfM[hxName+'.exLoss'] = 0
    for s in ['Fl_I', 'Fl_O']:
        for n in [ 1, 2 ]:
            name = hxName+"."+s+'%g'%(n)
            dfM[hxName+'.exLoss'] += dfM[name+'.W'] * calcExergy(dfM[name+'.ht'], dfM[name+'.s'])

    # Calculate Exergy loss
    hxName = 'Heater.HxAirCO2'
    dfM[hxName+'.exLoss'] = 0
    for s in ['Fl_I', 'Fl_O']:
        for n in [ 1, 2 ]:
            name = hxName+"."+s+'%g'%(n)
            dfM[hxName+'.exLoss'] += dfM[name+'.W'] * calcExergy(dfM[name+'.ht'], dfM[name+'.s'])

    # Calculate Exergy loss
    hxName = 'Heater.HxAir'
    dfM[hxName+'.exLoss'] = 0
    for s in ['Fl_I', 'Fl_O']:
        for n in [ 1, 2 ]:
            name = hxName+"."+s+'%g'%(n)
            dfM[hxName+'.exLoss'] += dfM[name+'.W'] * calcExergy(dfM[name+'.ht'], dfM[name+'.s'])


    # Copy key values back over
    for v in ['xVar', 'yVar', xVar, yVar, zVar]:
        dfM[v] = dfS[v]

    dfKeys = [
        [
            'Perf.eff',
            'PerfPlant.eff',
            # 'Perf.pwrNet', 
            'Perf.pwrLoad', 
            'Trb.Fl_I.Tt',
            # 'Trb.Fl_I.Pt', 
            'Trb.Fl_I.W',
            'Split.BldOutReCmp.fracW',
            'Heater.Fl_I.Tt',
        ],
        [
            'Trb.eff', 
            'Cmp.eff',
            'ReCmp.eff',
        ],
        [
            'HxHigh.Fl_I1.Tt',
            'HxHigh.approach_min',
            'HxHigh.exLoss',
            'HxLow.Fl_I1.Tt',
            'HxLow.approach_min', 
            'HxLow.exLoss',
        ], 
        [
            'Heater.Htr.Q', 
            'Heater.HxAirCO2.Q', 
            'Heater.Htr.Fl_O.Tt', 
        ],
        [
            'Heater.HxAirCO2.effect_des', 
            'Heater.HxAirCO2.Fl_I1.Tt', 
            'Heater.HxAirCO2.Fl_O1.Tt', 
            'Heater.HxAirCO2.Fl_I2.Tt', 
            'Heater.HxAirCO2.Fl_O2.Tt', 
            'Heater.HxAirCO2.exLoss',
            'Heater.HxAirCO2.approach_min',
            
        ],
        [
            'Heater.HxAir.effect_des', 
            'Heater.HxAir.Fl_I1.W', 
            'Heater.HxAir.Fl_I2.W',
            'Heater.HxAir.exLoss',
            'Heater.HxAir.approach_min',
        ],
        ]

    xr, yr, zr, ir, dd, dDict = reduce3Dto2D(dfM, xVar, yVar, cVar, xTol, yTol, 
            dfKeys = xVar + yVar + zVar + cVar + [item for items in dfKeys for item in items])




    fig = plt.figure(199)
    plt.clf()
    
    # 3d
    ax = plt.subplot(2,1,1,projection='3d')

    ax.scatter(dfS[xVar], dfS[yVar], dfS[zVar], c=dfS[zVar].values.flatten())
    sm = getScalarMap(dfS[zVar].values.flatten())
    plt.colorbar(sm,label=zVar[0])
    ax.set_xlabel(xVar)
    ax.set_ylabel(yVar)
    ax.set_zlabel(zVar)
    ax.set_title('Raw Design Sweep - Independents')
    ax.view_init(30,-140)

    ax = plt.subplot(2,1,2,projection='3d')

    ax.scatter(dfM[xVar], dfM[yVar], dfM[zVar], c=dfM[zVar].values.flatten())
    sm = getScalarMap(dfM[zVar].values.flatten())
    plt.colorbar(sm, label=zVar[0])
    ax.set_xlabel(xVar)
    ax.set_ylabel(yVar)
    ax.set_zlabel(zVar)
    ax.set_title('Masked Design Sweep - Independents')
    ax.view_init(30,-140)

    fig.set_size_inches(11*plotScale, 8.5*plotScale)
    plt.savefig('%s/post_%s.png'%(fileDir, 'designVars'), dpi=150)

    fig = plt.figure(200)
    plt.clf()
    
    # 3d
    ax = plt.subplot(2,1,1,projection='3d')

    ax.scatter(dfS[xVar], dfS[yVar], dfS[cVar], c=dfS[cVar].values.flatten())
    sm = getScalarMap(dfS[cVar].values.flatten())
    plt.colorbar(sm)
    ax.set_xlabel(xVar)
    ax.set_ylabel(yVar)
    ax.set_zlabel(cVar)
    ax.set_title('Raw Design Sweep - '+cVar[0])
    ax.view_init(30,-140)

    ax = plt.subplot(2,1,2,projection='3d')

    ax.scatter(dfM[xVar], dfM[yVar], dfM[cVar], c=dfM[cVar].values.flatten())
    sm = getScalarMap(dfM[cVar].values.flatten())
    plt.colorbar(sm)
    ax.set_xlabel(xVar)
    ax.set_ylabel(yVar)
    ax.set_zlabel(cVar)
    ax.set_title('Masked Design Sweep - '+cVar[0])
    ax.view_init(30,-140)

    fig.set_size_inches(11*plotScale, 8.5*plotScale)
    plt.savefig('%s/post_%s.png'%(fileDir, cVar[0]+'_scatter1'), dpi=150)


    fig = plt.figure(201)
    plt.clf()

    # 2d
    # ax = plt.subplot(1,1,1)
    # ax.scatter(xr, yr, c=zr)

    # 3d
    ax = plt.subplot(1,1,1,projection='3d')
    ax.scatter(xr, yr, zr, c=zr.ravel())
    sm = getScalarMap(zr[~np.isnan(zr)].ravel(),cmap=cm.jet)
    # collec = ax.plot_surface(xr, yr, zr,cmap=sm.cmap)
    collec = ax.plot_surface(xr, yr, zr,cmap=sm.cmap,facecolors=sm.to_rgba(zr))
    # collec.set_facecolors(sm.to_rgba(np.nan_to_num(zr).flatten()))
    # collec.set_facecolors(sm.to_rgba(zr.flatten()))
    plt.colorbar(sm)
    ax.set_xlabel(xVar)
    ax.set_ylabel(yVar)
    ax.set_zlabel(cVar)
    ax.set_title(cVar)
    ax.view_init(30,-140)

    fig.set_size_inches(11*plotScale, 8.5*plotScale)
    plt.savefig('%s/post_%s.png'%(fileDir, cVar[0]+'_surface'), dpi=150)


    fig = plt.figure(202)
    plt.clf()

    # 2d
    # ax = plt.subplot(1,1,1)
    # ax.scatter(dd[xVar], dd[yVar], c=dd[cVar])
    
    # 3d
    ax = plt.subplot(1,1,1,projection='3d')
    # ax.scatter(xr, yr, zd, c=zd.ravel())

    ax.scatter(dd[xVar], dd[yVar], dd[cVar], c=dd[cVar].values.flatten())
    sm = getScalarMap(dd[cVar].values.flatten())
    # collec = ax.plot_wireframe(dd[xVar], dd[yVar], dd[cVar], cmap=sm.cmap, facecolors=sm.to_rgba(dd[cVar].values.flatten()))
    # collec.set_facecolor(sm.to_rgba(dd[cVar].values.flatten()))
    plt.colorbar(sm)
    ax.set_xlabel(xVar)
    ax.set_ylabel(yVar)
    ax.set_zlabel(cVar)
    ax.set_title(cVar)
    ax.view_init(30,-140)



    # plt.figure(203)
    # ax = plt.subplot(1,1,1)
    # ax.scatter(dfM.loc[ir.flatten()][xVar], dfM.loc[ir.flatten()][yVar], c=dfM.loc[ir.flatten()][cVar])
    # # collec = ax.plot_surface(xr, yr, zr)
    # # sm = getScalarMap(zr.ravel())
    # # collec.set_facecolor(sm.to_rgba(zr.ravel()))
    
    fig.set_size_inches(11*plotScale, 8.5*plotScale)
    plt.savefig('%s/post_%s.png'%(fileDir, cVar[0]+'_scatter2'), dpi=150)
    plt.show()


    for j, keys in enumerate(dfKeys):
    
        fig = plt.figure(2001+j)
        plt.clf()

        # 2d
        # ax = plt.subplot(1,1,1)
        # ax.scatter(xr, yr, c=zr)
        
        # 3d
        # nk = len(dDict.keys())
        nk = len(keys)

        axes = []
        plt.subplots_adjust(top=0.925, bottom=0.075, left=0.075, right=0.925, hspace=0.3, wspace=0.3)
        for i, k in enumerate(keys):
            ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1,projection='3d')
            zz = dDict[k]
            ax.scatter(xr, yr, zz, c=zz.ravel())
            sm = getScalarMap(zz[~np.isnan(zz)].ravel(),cmap=cm.jet)
            # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap)
            collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap,facecolors=sm.to_rgba(zz))
            # collec.set_facecolors(sm.to_rgba(np.nan_to_num(zz).flatten()))
            # collec.set_facecolors(sm.to_rgba(zz.flatten()))
            plt.colorbar(sm)
            ax.set_xlabel(xVar)
            ax.set_ylabel(yVar)
            ax.set_zlabel(k)
            ax.set_title(k)
            ax.view_init(30,-140)
            axes.append(ax)

        fig.set_size_inches(11*plotScale, 8.5*plotScale)
        plt.savefig('%s/post_matrix_%s_%g.png'%(fileDir, '3d', j), dpi=150)

    for j, keys in enumerate(dfKeys):
    
        fig = plt.figure(3001+j)
        plt.clf()

        # 2d
        # ax = plt.subplot(1,1,1)
        # ax.scatter(xr, yr, c=zr)
        
        # 3d
        # nk = len(dDict.keys())
        nk = len(keys)

        axes = []
        plt.subplots_adjust(top=0.925, bottom=0.075, left=0.075, right=0.925, hspace=0.3, wspace=0.3)
        for i, k in enumerate(keys):
            # ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1,projection='3d')
            ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1)
            zz = dDict[k]
            sm = getScalarMap(zz[~np.isnan(zz)].ravel(),cmap=cm.jet)
            ax.scatter(xr, yr, marker='+', color=sm.to_rgba(zz.ravel()))
            # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap)
            plt.contourf(xr, yr, zz, 21, cmap=sm.cmap)
            # collec.set_facecolors(sm.to_rgba(np.nan_to_num(zz).flatten()))
            # collec.set_facecolors(sm.to_rgba(zz.flatten()))
            plt.colorbar(sm)
            ax.set_xlabel(xVar)
            ax.set_ylabel(yVar)
            # ax.set_zlabel(zVar)
            ax.set_title(k)
            # ax.view_init(30,-140)
            axes.append(ax)

        fig.set_size_inches(11*plotScale, 8.5*plotScale)
        plt.savefig('%s/post_matrix_%s_%g.png'%(fileDir, 'contour', j), dpi=150)

        


    # fig = plt.figure(3001)
    # plt.clf()

    # # 2d
    # # ax = plt.subplot(1,1,1)
    # # ax.scatter(xr, yr, c=zr)

    # # 3d
    # # nk = len(dDict.keys())
    # nk = len(dfKeys)

    # axes = []
    # plt.subplots_adjust(top=0.925, bottom=0.075, left=0.075, right=0.925, hspace=0.3, wspace=0.3)
    # for i, k in enumerate(dfKeys):
    #     # ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1,projection='3d')
    #     ax = plt.subplot(ceil(nk**0.5),round(nk**0.5),i+1)
    #     zz = dDict[k]
    #     sm = getScalarMap(zz[~np.isnan(zz)].ravel(),cmap=cm.jet)
    #     ax.scatter(xr, yr, marker='+', color=sm.to_rgba(zz.ravel()))
    #     # collec = ax.plot_surface(xr, yr, zz,cmap=sm.cmap)
    #     plt.contourf(xr, yr, zz, 21, cmap=sm.cmap)
    #     # collec.set_facecolors(sm.to_rgba(np.nan_to_num(zz).flatten()))
    #     # collec.set_facecolors(sm.to_rgba(zz.flatten()))
    #     plt.colorbar(sm)
    #     ax.set_xlabel(xVar)
    #     ax.set_ylabel(yVar)
    #     # ax.set_zlabel(zVar)
    #     ax.set_title(k)
    #     # ax.view_init(30,-140)
    #     axes.append(ax)

    # fig.set_size_inches(11*plotScale, 8.5*plotScale)
    # plt.savefig('%s/post_matrix_%s.png'%(fileDir, 'contour'), dpi=150)

    plt.show()


