kernel	category	datatype	integer_support	params	MINI	SMALL	MEDIUM	LARGE	EXTRALARGE
correlation	datamining	float	FALSE	M N	28 32	80 100	240 260	1200 1400	2600 3000
covariance	datamining	float	FALSE	M N	28 32	80 100	240 260	1200 1400	2600 3000
2mm	linear-algebra/kernels	float	FALSE	NI NJ NK NL	16 18 22 24	40 50 70 80	180 190 210 220	800 900 1100 1200	1600 1800 2200 2400
3mm	linear-algebra/kernels	float	FALSE	NI NJ NK NL NM	16 18 20 22 24	40 50 60 70 80	180 190 200 210 220	800 900 1000 1100 1200	1600 1800 2000 2200 2400
atax	linear-algebra/kernels	float	FALSE	M N	38 42	116 124	390 410	1900 2100	1800 2200
bicg	linear-algebra/kernels	float	FALSE	M N	38 42	116 124	390 410	1900 2100	1800 2200
doitgen	linear-algebra/kernels	float	FALSE	NQ NR NP	8 10 12	20 25 30	40 50 60	140 150 160	220 250 270
mvt	linear-algebra/kernels	float	FALSE	N	40	120	400	2000	4000
gemm	linear-algebra/blas	float	FALSE	NI NJ NK	20 25 30	60 70 80	200 220 240	1000 1100 1200	2000 2300 2600
gemver	linear-algebra/blas	float	FALSE	N	40	120	400	2000	4000
gesummv	linear-algebra/blas	float	FALSE	N	30	90	250	1300	2800
symm	linear-algebra/blas	float	FALSE	M N	20 30	60 80	200 240	1000 1200	2000 2600
syr2k	linear-algebra/blas	float	FALSE	M N	20 30	60 80	200 240	1000 1200	2000 2600
syrk	linear-algebra/blas	float	FALSE	M N	20 30	60 80	200 240	1000 1200	2000 2600
trmm	linear-algebra/blas	float	FALSE	M N	20 30	60 80	200 240	1000 1200	2000 2600
cholesky	linear-algebra/solvers	float	FALSE	N	40	120	400	2000	4000
durbin	linear-algebra/solvers	float	FALSE	N	40	120	400	2000	4000
gramschmidt	linear-algebra/solvers	float	FALSE	M N	20 30	60 80	200 240	1000 1200	2000 2600
lu	linear-algebra/solvers	float	FALSE	N	40	120	400	2000	4000
ludcmp	linear-algebra/solvers	float	FALSE	N	40	120	400	1000	4000
trisolv	linear-algebra/solvers	float	FALSE	N	40	120	400	2000	4000
deriche	medley	float	FALSE	W H	64 64	192 128	720 480	4096 2160	7680 4320
floyd-warshall	medley	float	TRUE	N	60	180	500	2800	5600
nussinov	medley	float	TRUE	N	60	180	500	2500	5500
adi	stencils	float	FALSE	TSTEPS N	20 20	40 60	100 200	500 1000	1000 2000
fdtd-1d	stencils	float	FALSE	TSTEPS N	20 30	40 80 	100 40	500 2000	800000 50000
fdtd-2d	stencils	float	FALSE	TMAX NX NY	20 20 30	40 60 80	100 200 240	500 1000 1200	1000 2000 2600
heat-1d	stencils	float	FALSE	TSTEPS M N	20 2 100	40 2 200	100 2 400	500 2 2000	200000 2 50000
heat-2d	stencils	float	FALSE	TSTEPS M N	20 2 10	40 2 20	100 2 40	500 2 120	8000 2 3000
heat-3d	stencils	float	FALSE	TSTEPS N	20 10	40 20	100 40	500 120	1000 200
jacobi-1d	stencils	float	FALSE	TSTEPS N	20 30	40 120	100 400	500 2000	1000 4000
jacobi-2d	stencils	float	FALSE	TSTEPS N	20 30	40 90	100 250	500 1300	1000 2800
seidel-2d	stencils	float	FALSE	TSTEPS N	20 40	40 120	100 400	500 2000	1000 4000
3d7pt	stencils	float	FALSE	TSTEPS M N	20 2 10	40 2 20	200 2 40	1000 2 120	2000 2 200
3d27pt	stencils	float	FALSE	TSTEPS M N	20 2 10	40 2 20	100 2 40	500 2 120	1000 2 200