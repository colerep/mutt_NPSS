# Numerical Packages
import numpy as np
import pandas as pd

# Plotting
import matplotlib.pyplot as plt
import matplotlib.cm as cm
import matplotlib.colors as colors
from mpl_toolkits.mplot3d import Axes3D



def plotVars(df, varNames, fignum=None, c=None, color=None, normed=True, alpha=0.5):
    
    fig = plt.figure(fignum)
    # plt.clf()
    nrow = len(varNames.keys())
    ncol = 2
    for i,(k,v) in enumerate(varNames.items()):
        plt.subplot(nrow,ncol,2*(i+1)-1)
        if v:
            # plt.plot(df[v],label=k)
            plt.scatter(df.index, df[v].values,color=color, label=k)
            plt.title(k)

        plt.subplot(nrow,ncol,2*(i+1))
        if v:
            plt.hist(df[v].values,label=k, color=color, normed=normed, alpha=alpha)



def plotVars2(df, varNames, varLabels, fignum=None, c=None, color=None, normed=True, alpha=0.5):
    fig = plt.figure(fignum)
    f = plt.gcf()
    axes = f.get_axes()
    newPlot = True
    if (len(axes) == 0):
        newPlot = True
    # plt.clf()
    nrow = len(varNames)
    ncol = 2
    for i,(k,v) in enumerate(zip(varLabels, varNames)):
        if v:
            if newPlot:
                ax = plt.subplot(nrow,ncol,2*(i+1)-1)
            else:
                ax=axes[2*(i+1)-2]
            # plt.plot(df[v],label=k)
            ax.scatter(df.index, df[v].values,color=color, label=k)
            ax.set_title(k)

            if newPlot:
                ax = plt.subplot(nrow,ncol,2*(i+1))
            else:
                ax=axes[2*(i+1)-1]
            ax.hist(df[v].values,label=k, color=color, normed=normed, alpha=alpha)


def plot_var_scatter(ax, df, v, k=None, color=None, alpha=0.5 ):
    if not k:
        k = v
    ax.scatter(df.index, df[v].values,color=color, label=k, alpha=alpha)

def plot_var_hist(ax, df, v, k=None, color=None, normed=True, alpha=0.5 ):
    if not k:
        k = v
    ax.hist(df[v].values,label=k, color=color, normed=normed, alpha=alpha)

# Plot All Test points using Order Tracking Peak Hold
# def plot_page( df, varNames, varLabels=None, figs=[], axes=[], dim=[1, 4], debug=False, colFunc=[plot_var_scatter, plot_var_hist] ):

#     # ncol = int( round( sqrt( size(points) ) ) )
#     # nrow = int( ceil( size(points)/ ncol ) )
        
#     ncol = len(colFunc) # dim[0]
#     nrow = dim[1]
#     npage = int( ceil( size(varNames) / (nrow) ) )

#     print "varNames", len(varNames), nrow, npage
#     print "colFunc", len(colFunc), ncol

#     if not varLabels:
#         varLabels = varNames

#     if len(figs) < npage:
#         figs =  [plt.figure() for f in range(npage)]
#         axes = []
#         for fig in figs:
#             # Set figure active 
#             print fig.number
#             plt.figure(fig.number)
#             # Add subplots
#             axes.append(plt.subplots(nrows=nrow,ncols=ncol, sharex='col'))

#     return figs, axes




#     for fig in figs:

#         for 



#     # if debug > 5: print "Num Points ", size(points), " nrow ", nrow, " ncol ", ncol, " npage ", npage

#     # if not figs:
#     #     figs=[]

#     ## Plot each test point
#     pointCounter = -1
#     for np, v in enumerate(varNames):
    
#         pointCounter += 1

#         # Container to track figures
#         #fig = []
#         #nf = 0

#         ## 
#         #nf = nf + int( pointCounter / (nrow * ncol) )
#         #fig = plt.figure(nf); 
#         if remainder( pointCounter , (nrow * ncol) ) == 0: 
#             fig = figs[]
#             figs.append(fig)
#         plt.subplots_adjust(wspace=0.5,hspace=0.5)
#         fig.set_size_inches(8.5,11.43,forward=True)
#         ax = plt.subplot( nrow, ncol, mod(pointCounter,(nrow * ncol))+1 )
#         axPage = plt.subplots(nrows=nrow, ncols=ncol, sharex='col')
#         for axRow in axPage:
#             for i, axCol in enumerate(axRow):


#         # Plots



#         # Put a legend to the right of the current axis
#         #ax.legend(loc='center left', bbox_to_anchor=(-0.1, 0.5),frameon=false)
#         ax.legend(loc='upper right',frameon=False)
#         ax.grid(True)

#     show_gui = True
#     if show_gui :
#         plt.show(block=False)
#     else:
#         for n in plt.get_fignums():
#             plt.close(n)





def display_cmap(cmap):
    plt.imshow(np.linspace(0, 100, 256)[None, :],  aspect=25,    interpolation='nearest', cmap=cmap)
    plt.axis('off')

def histc(x,c,cbins=5, bins=5,_palette='jet',alpha=0.5):

    cl = np.linspace(c.min(),c.max(),cbins+1)
    # print cl, c.min(), c.max(), len(cl)
    hx = []
    hc = []
    weights = []
    for b in range(cbins):
        m = c.between(cl[b],cl[b+1])
        hx.append(x[m].values)
        hc.append((cl[b:b+1].mean()-c.min())/(c.max()-c.min()))
        weights.append( np.repeat((x.max()-x.min())/len(x),len(x[m])) )

    cmap = cm.get_cmap(_palette)
    color = cmap(hc)
    bottom = np.repeat(x.min(),bins)
    stacked = False
    #histtype = 'barstacked'
    histtype = 'bar'
    weights = None

    plt.hist(hx,bins=bins,histtype=histtype,stacked=stacked,color=color,alpha=alpha,weights=weights,bottom=bottom, normed=True)
    #plt.scatter(x,x,c=c,cmap=cmap,alpha=0.25)

    return hx, hc

def histy2(x,c,cbins=10, bins=5,_palette='jet',alpha=0.5):
    ax1 = plt.gca()
    ax2 = ax1.twinx()

    # if c == None:
    #     hx = x
    #     color=None

    # else:
    cl = np.linspace(c.min(),c.max(),cbins+1)
    # print cl, c.min(), c.max(), len(cl)
    hx = []
    hc = []
    weights = []
    for b in range(cbins):
        m = c.between(cl[b],cl[b+1])
        hx.append(x[m].values)
        hc.append((cl[b:b+1].mean()-c.min())/(c.max()-c.min()))
        weights.append( np.repeat((x.max()-x.min())/len(x),len(x[m])) )

    cmap = cm.get_cmap(_palette)
    color = cmap(hc)
    bottom = np.repeat(x.min(),bins)
    stacked = True
    #histtype = 'barstacked'
    histtype = 'bar'
    weights = None

    # ax2.hist(hx,bins=bins,histtype=histtype,stacked=stacked,color=color,alpha=alpha,weights=weights,bottom=bottom, normed=True)
    ax2.hist(hx,10,histtype='bar',stacked=True,color=color,alpha=alpha)
    #plt.scatter(x,x,c=c,cmap=cmap,alpha=0.25)

    return hx, hc


def plot_matrix(df, varNames=None, x_vars=None, y_vars=None, args=None, hue=None, _palette="jet", marker='.', alpha=0.5):

    # Setup Figure
    #plt.figure()
    if x_vars == None:
        if varNames == None:
            varNames = list(df.columns)
        x_vars = varNames
    if y_vars == None:
        y_vars = varNames

    figsize = None
    fig, axes = plt.subplots(len(y_vars), len(x_vars),
        figsize=figsize,
        sharex="col", sharey="row",
        squeeze=False)

    # Colors
    cmap = cm.get_cmap(_palette)
    if hue:
        c = df[hue]
    else:
        c = None

    for i, y_var in enumerate(y_vars):
        for j, x_var in enumerate(x_vars):

            # Set current axis
            ax = axes[i, j]
            plt.sca(ax)

            # Plots
            if x_var == y_var:
                # Am I on a diagonal?
                h = df[x_var]
                #plt.hist(h,bottom=h.min(),weights=np.repeat((h.max()-h.min())/len(h),len(h)))
                histy2(h,c)

            else:
                # Everything else
                plt.scatter(df[x_var], df[y_var],
                     label=None, c=c, cmap=cmap, marker=marker, alpha=alpha)

            if i == (len(y_vars)-1):
                ax.set_xlabel(x_var)
                plt.setp(ax.get_xticklabels(), rotation=90)
                plt.xlim([df[x_var].min(), df[x_var].max()])

            if j == 0:
                ax.set_ylabel(y_var)
                plt.ylim([df[y_var].min(), df[y_var].max()])

    fig.subplots_adjust(wspace=0.3, hspace=0.3)
    #plt.tight_layout()

def plot_matrix2(df, varNames, args=None, hue=None, _palette="RdBu_d"):

    if True:

        # cmap = cm.get_cmap('Spectral') # Colour map (there are many others)

        #pd.tools.plotting.scatter_matrix(df[varNames],grid=True)
        # Colors, see: http://stackoverflow.com/questions/28034424/pandas-scatter-matrix-plot-categorical-variables
        # http://matplotlib.org/examples/shapes_and_collections/scatter_demo.html
        # Colormaps: https://m.reddit.com/r/Python/comments/3qiaj7/diverging_from_black_colormap/
        my_cmap=matplotlib.colors.LinearSegmentedColormap.from_list('mycmap', ['#FF0000', '#0000FF'])
        #display_cmap(my_cmap)

        # See http://stackoverflow.com/questions/25741214/how-to-use-colormaps-to-color-plots-of-pandas-dataframes
        cmap = cm.get_cmap('Spectral')
        cmap = cm.get_cmap('cubehelix')
        cmap = cm.get_cmap('jet')
        # cmap = my_cmap
        # cmap = None
        axArr = pd.tools.plotting.scatter_matrix(df[varNames],grid=True,c=df['Perf.eff'], cmap=cmap, edgecolor='k')

        #fig.tight_layout()
        plt.subplots_adjust(hspace=0.2,wspace=0.2)

        ni, nj = axArr.shape
        for i in range(ni):
            for j in range(nj):
                # print i, j, axArr[i][j]
                ax = axArr[i][j]

                # turn on grid
                ax.grid(True)

                # Axis must be visible for grid to be visible
                ax.yaxis.set_visible(True)
                ax.xaxis.set_visible(True)

                # For all rows but the bottom, clear x-axis labels
                if i < (ni-1):
                    ax.set_xticklabels([])
                    ax.set_xlabel("")

                # For all columns but the left, clear y-axis labels
                if j > 0:
                    ax.set_yticklabels([])
                    ax.set_ylabel("")

                #ax.relim()      # make sure all the data fits
                #ax.autoscale()  # auto-scale
                # for k,v in ax.spines.items():
                #     ax.spines[k].set_visible(False)



        plt.draw()
        plt.show()

        return axArr



# def plotUniqueLine(df, varNames, varLabels, fignum=None, c=None, color=None, normed=True, alpha=0.5):
def plotUniqueLine(df, x_vars=None, y_vars=None, l_vars=None, args=None, hue=None, _palette="jet", marker='.', alpha=0.5):
    # Marker reference http://matplotlib.org/examples/lines_bars_and_markers/marker_reference.html
    import itertools
    from matplotlib.lines import Line2D
    markers = itertools.cycle(Line2D.filled_markers)

    l_values = df[l_vars].unique()

    for l in l_values:
        labelText = "{} = {}".format(l_vars,l)
        x = df[df[l_vars]==l][x_vars].values
        y = df[df[l_vars]==l][y_vars].values
        plt.plot(x,y,marker=markers.next(),label=labelText)
    plt.grid(True)
    plt.legend(loc=0)
    plt.xlabel(x_vars)
    plt.ylabel(y_vars)

