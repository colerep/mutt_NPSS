import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

import CoolProp.CoolProp as CP
import numpy as np

CP.set_config_string(CP.ALTERNATIVE_REFPROP_PATH,'c:\\Program Files (x86)\\REFPROP\\')

def saveNpss2VarTable(outFile, i1Name, i1Var, i2Name, i2Var, depName, depVar, interp='lagrange2', extrap='lagrange2', printExtrap=0):

	strTemp = '\nTable %s ( real %s, real %s ) {\n'%(depName, i1Name, i2Name)
	outFile.writelines( strTemp )

	for i1, i2, dep in zip(i1Var, i2Var, depVar):
		outFile.writelines('\t%s = %g {\n'%(i1Name, i1[0]))
		
		# strTemp = '\t\t// %s = %s\n'%(i1Name, np.array2string(i1,max_line_width=100,separator=',').replace('[','{').replace(']','}'))
		# outFile.writelines( strTemp )
		
		strTemp = '\t\t%s = %s\n'%(i2Name, np.array2string(i2,max_line_width=1e12,separator=',').replace('[','{').replace(']','}'))
		outFile.writelines( strTemp )
		
		strTemp = '\t\t%s = %s\n'%(depName, np.array2string(dep,max_line_width=1e12,separator=',').replace('[','{').replace(']','}'))
		outFile.writelines( strTemp )
		# outFile.writelines('}\n')
		strTemp = '\t}\n'
		outFile.writelines( strTemp )

	outFile.write( '\t%s = \"%s\";\n'%('interp', interp))
	outFile.write( '\t%s = \"%s\";\n'%('extrap', extrap))
	outFile.write( '\t%s = %i;\n'%('printExtrap', printExtrap))

	strTemp = '}\n'
	outFile.writelines( strTemp )

if __name__ == '__main__':

	FLUID = 'REFPROP::CO2'

	PtConv = 6894.76 # 1 psia to Pa
	TtConv = 0.555556 # 1 R to K
	htConv = 2326.0 # 1 Btu/lbm to J/kg
	sConv = 4186.8 # 1 Btu/(lbm*R) to J/(kg*K)
	rhoConv = 16.01846 # 1 lbm/ft3 to kg/m3
	CptConv = 4186.8 # Btu/(lbm*R) to J/kg/K
	muConv = 1.48816 # getUnitsFactor("lbm/(ft*sec)","Pa*sec");
	kConv = 6230.64 # getUnitsFactor("Btu/(sec*ft*R)","W/(m*K)");

	P0 = 101325 # Pa, 14.696 psia
	T0 = 288.15 # C, 518.67 Rankine, 288.15 K

	rho0 = CP.PropsSI('D','T',T0,'P',P0,FLUID)
	h0 = CP.PropsSI('HMASS','T',T0,'P',P0,FLUID)
	s0 = CP.PropsSI('SMASS','T',T0,'P',P0,FLUID)

	# Set starting enthalpy
	Thigh = 800.15  # K

	Plow = 35.0e5  # Pa
	Phigh = 250.0e5  # Pa

	hLow = CP.PropsSI('HMASS', 'P', Plow, 'Q', 0, FLUID)
	hHigh = CP.PropsSI('HMASS', 'T', Thigh, 'P', Plow, FLUID)

	
	Tlow = CP.PropsSI('T', 'H', hLow, 'P', Plow, FLUID)


	# NPSS English units converted to CoolProp SI
	npts = 750
	Pvec = np.logspace(np.log10(Plow), np.log10(Phigh), npts)
	Tvec = np.linspace(Tlow, Thigh, npts)

	# Mesh
	Pmesh, Tmesh = np.meshgrid(Pvec,Tvec)

	print 'CP Complete'

	fptName = 'CO2_h_T_py_n%i.fpt'%(npts)


	with open(fptName,'w') as outFile:
		tableName = 'h_T'
		depName = tableName
		depMesh = CP.PropsSI('HMASS','T',Tmesh.ravel(),'P',Pmesh.ravel(),FLUID).reshape(Pmesh.shape)
		depMesh = (depMesh)/ htConv
		saveNpss2VarTable(outFile, 'Tt', (Tmesh)/TtConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print tableName
