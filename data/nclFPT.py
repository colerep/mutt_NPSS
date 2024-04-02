import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

import CoolProp.CoolProp as CP
import numpy as np

# CP.set_config_string(CP.ALTERNATIVE_REFPROP_PATH,'c:\\Program Files (x86)\\REFPROP\\')

def saveNpss2VarTable(outFile, i1Name, i1Var, i2Name, i2Var, depName, depVar, interp='lagrange2', extrap='lagrange2', printExtrap=0):

	strTemp = '\nTable %s ( real %s, real %s ) {\n'%(depName, i1Name, i2Name)
	outFile.writelines(strTemp)

	for i1, i2, dep in zip(i1Var, i2Var, depVar):
		outFile.writelines('\t{:s} = {:g} {{\n'.format(i1Name, i1[0]))
		
		# strTemp = '\t\t// %s = %s\n'%(i1Name, np.array2string(i1,max_line_width=100,separator=',').replace('[','{').replace(']','}'))
		# outFile.writelines( strTemp )
		
		strTemp = '\t\t{:s} = {:s}\n'.format(i2Name, np.array2string(i2, max_line_width=1e12, separator=',').replace('[', '{').replace(']', '}'))
		outFile.writelines(strTemp)
		
		strTemp = '\t\t{:s} = {:s}\n'.format(depName, np.array2string(dep, max_line_width=1e12, separator=',').replace('[', '{').replace(']', '}'))
		outFile.writelines(strTemp)
		# outFile.writelines('}\n')
		strTemp = '\t}\n'
		outFile.writelines(strTemp)

	outFile.write('\t{:s} = \"{:s}\";\n'.format('interp', interp))
	outFile.write('\t{:s} = \"{:s}\";\n'.format('extrap', extrap))
	outFile.write('\t{:s} = {};\n'.format('printExtrap', printExtrap))

	strTemp = '}}\n'
	outFile.writelines(strTemp)


if __name__ == '__main__':

	FLUID = 'REFPROP::CO2'

	PtConv = 6894.76  # 1 psia to Pa
	TtConv = 0.555556  # 1 R to K
	htConv = 2326.0  # 1 Btu/lbm to J/kg
	rhoConv = 16.01846  # 1 lbm/ft3 to kg/m3
	CptConv = 4186.8  # Btu/(lbm*R) to J/kg/K
	sConv = 4186.8   # Btu/(lbm*R) to J/kg/K
	muConv = 1.48816  # getUnitsFactor("lbm/(ft*sec)","Pa*sec");
	kConv = 6230.64  # getUnitsFactor("Btu/(sec*ft*R)","W/(m*K)");
	vConv = 0.3048  # 1 ft/s to m/s

	P0 = 101325  # Pa, 14.696 psia
	T0 = 288.15  # C, 518.67 Rankine, 288.15 K

	rho0 = CP.PropsSI('D', 'T', T0, 'P', P0, FLUID)
	h0 = CP.PropsSI('HMASS', 'T', T0, 'P', P0, FLUID)
	s0 = CP.PropsSI('SMASS', 'T', T0, 'P', P0, FLUID)

	quality = CP.PropsSI('Q', 'T', T0, 'P', P0, FLUID)
	print(quality)

	#Set starting enthalpy
	Tlow = 273.15  # K
	Thigh = 1100.15  # K
	Tmin = 217  # K

	Plow = 68948  # Pa
	Phigh = 2.76e6  # Pa

	hLow = CP.PropsSI('HMASS', 'T', Tmin, 'Q', 0, FLUID)
	hHigh = CP.PropsSI('HMASS', 'T', Thigh, 'P', Plow, FLUID)

	print(hLow/1e3)
	print(hHigh/1e3)


	# NPSS English units converted to CoolProp SI
	npts = 500
	Pvec = np.logspace(np.log10(Plow),np.log10(Phigh),npts)
	hVec = np.linspace(hLow, hHigh, npts)

	# Mesh
	Pmesh, hMesh = np.meshgrid(Pvec,hVec)

	print('CP Complete')

	fptName = 'CO2_n{}.fpt'.format(npts)

	with open(fptName,'w') as outFile:

		outFile.write('''description = "CO2_hP.fpt Fluid Property Table";

indeps = {"ht","Pt"};		// Thermodynamic Property = f(Tt,Pt)
hTindeps = {"Tt","Pt"};		// Table containing:   ht = f(Tt,Pt)
sTindeps = {"Tt","Pt"};		// Table containing:	s = f(Tt,Pt)
ThIndeps = {"ht","Pt"};		// Table containing: 	T = f(ht,Pt)
shIndeps = {"ht","Pt"};		// Table containing:	s = f(ht,Pt)
TsIndeps = {"s","Pt"};		// Table containing: 	T = f(s ,Pt)
hsIndeps = {"s","Pt"};		// Table containing:   ht = f(s ,Pt)
''')

		tableName = 'x'
		depName = tableName
		depMesh = CP.PropsSI('Q', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		saveNpss2VarTable(outFile, 'ht', hMesh / htConv, 'Pt', Pmesh / PtConv, depName, depMesh)
		print(tableName)

		tableName = 'rho'
		depName = tableName
		depMesh = CP.PropsSI('D', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		depMesh = depMesh / rhoConv
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		tableName = 'Cp'
		depName = tableName
		depMesh = CP.PropsSI('CPMASS', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		depMesh = depMesh / CptConv
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		tableName = 'Cv'
		depName = tableName
		depMesh = CP.PropsSI('CVMASS', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		depMesh = depMesh / CptConv
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		tableName = 'Pr'
		depName = tableName
		depMesh = CP.PropsSI('Prandtl', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		saveNpss2VarTable(outFile, 'ht', hMesh / htConv, 'Pt', Pmesh / PtConv, depName, depMesh)
		print(tableName)

		# Cpt / Cvt
		tableName = 'gam'
		depName = tableName
		depMesh = CP.PropsSI('CPMASS', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape) / CP.PropsSI('CVMASS', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		tableName = 'mu'
		depName = tableName
		depMesh = CP.PropsSI('V', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		depMesh = depMesh / muConv
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		tableName = 'k'
		depName = tableName
		depMesh = CP.PropsSI('L','H',hMesh.ravel(),'P',Pmesh.ravel(),FLUID).reshape(Pmesh.shape)
		depMesh = depMesh / kConv
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		tableName = 'T_h'
		depName = tableName
		depMesh = CP.PropsSI('T','H',hMesh.ravel(),'P',Pmesh.ravel(),FLUID).reshape(Pmesh.shape)
		depMesh = depMesh / TtConv
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		tableName = 's_h'
		depName = tableName
		depMesh = CP.PropsSI('SMASS','H',hMesh.ravel(),'P',Pmesh.ravel(),FLUID).reshape(Pmesh.shape)
		depMesh = (depMesh)/ sConv
		saveNpss2VarTable(outFile, 'ht', hMesh/htConv, 'Pt', Pmesh/PtConv, depName, depMesh)
		print(tableName)

		# tableName = 'sound'
		# depName = tableName
		# depMesh = CP.PropsSI('speed_of_sound', 'H', hMesh.ravel(), 'P', Pmesh.ravel(), FLUID).reshape(Pmesh.shape)
		# depMesh = (depMesh) / vConv
		# saveNpss2VarTable(outFile, 'ht', (hMesh - h0) / htConv, 'Pt', Pmesh / PtConv, depName, depMesh)
		# print tableName

		outFile.write('''
real h_s ( real s, real Pt ) {
    real ht = 0; // Note: Seed value should be in range of computed enthalpy values
    real s1;

    SecantSolver htSolver {
        description = "Adjust ht to find ";
        maxDx = 100;
        // tolerance = 1.E-4;  // tolPs
        tolerance = 1e-8;
        perturbSize = 1;
        maxIters = 200;
    } 

    // ht = s_h.evalYXiter(s,Pt);
    // Seed using inverse lookup
    // ht = s_h.evalYX(s,Pt);
    // ht = 0; // Note: Seed value should be in range of computed enthalpy values
    htSolver.initialize(ht);
    do {
        s1 = s_h(ht,Pt);
        ht = htSolver.iterate( s1 - s );
        // cout << "htSecant " << ht << " " << s1 << " " << s << " " << s1 - s << endl;
    } while ( ! ( htSolver.isConverged() || htSolver.errorFound() ) );

    return ht;
}

real T_s ( real s, real Pt ) {
    real ht = 0;

    ht = h_s(s, Pt);

    return T_h(ht,Pt);
}


real h_T ( real Tt, real Pt ) {
    real ht = 0; // Note: Seed value should be in range of computed enthalpy values
    real Tt1;

    SecantSolver htSolver {
        description = "Adjust ht to find ";
        maxDx = 100;
        // tolerance = 1.E-4;  // tolPs
        tolerance = 1e-8;
        perturbSize = 1;
        maxIters = 200;
    } 

    // ht = s_h.evalYXiter(s,Pt);
    // Seed using inverse lookup
    // ht = s_h.evalYX(s,Pt);
    // ht = 0; // Note: Seed value should be in range of computed enthalpy values
    htSolver.initialize(ht);
    do {
        Tt1 = T_h(ht,Pt);
        ht = htSolver.iterate( Tt1 - Tt );
        // cout << "htSecant " << ht << " " << Tt1 << " " << Tt << " " << Tt1 - Tt << endl;
    } while ( ! ( htSolver.isConverged() || htSolver.errorFound() ) );

    return ht;
}


real s_T ( real Tt, real Pt ) {
    real ht = 0;

    ht = h_T(Tt, Pt);

    return s_h(ht,Pt);
}
''')

	print('Save Table Complete')

	if False:

		fig = plt.figure(1)
		plt.clf()

		ax = fig.add_subplot(221, projection='3d')

		sc = ax.scatter(hMesh/1e3, Pmesh/1e5, rhoMesh, c=rhoMesh)
		plt.colorbar(sc)

		ax = fig.add_subplot(222, projection='3d')
		sc = ax.plot_wireframe(hMesh/1e3, Pmesh/1e5, sMesh)
		# plt.colorbar(sc)

		ax = fig.add_subplot(223, projection='3d')
		sc = ax.plot_wireframe(hMesh/1e3, Pmesh/1e5, Tmesh)
		# plt.colorbar(sc)

		ax = fig.add_subplot(224)
		sc = ax.contour(hMesh/1e3, Pmesh/1e5, Tmesh,20)

		plt.show()

		print('Plot Complete')