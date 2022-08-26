****************************************************************
* calculo IPM .do
* Este dofile hace el calculo del IPM balanceado de México, pero sin la privación de internet
*  
* ODS project
*
* Date Created: 20200728
* Name Created: GC
* Last modified: 
*
* Notas:
*  1. Donde se elimina el indicador de internet y en la dimensión de servicios se agrega el indicador de bienes.
*     La dimensión de calidad de vida se reemplaza por el peso de (1/15), así los pesos dan un valor del 100%
***************************************************************


clear
clear matrix
clear mata
set more off
set maxvar 10000
set mem 500m
cap log close
pause off

***Working Folder Path ***


global dtain "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/Mexico/Stata/Gastos/d1/dta"
global workingfolder_in "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/Mexico/Stata"
cap log close



***Log file***

log using "$workingfolder_in/IPM/balanceado/d1/log/IPM.log", replace 

*______________________*
*                      *
*      Data            *
*______________________* 

use "$dtain/castastroficobalanceado.dta", replace


* Construimos un filtro que identifica a las observaciones que tienen información en todos los indicadores relevantes 

drop sampl_mis
egen sampl_mis = rmiss(hh_d_water  hh_acceso hh_asegura  hh_schooling hh_attendance  hh_rezago hh_desempleo hh_formalidad hh_trabing hh_hacin hh_materi  hh_bienes hh_cooking hh_electri hh_sanea)
tab sampl_mis , m 


*** Filtramos que todos los individuos tengan toda la información de las privaciones

gen sample_weight = fac_libc 

keep if sampl_mis==0 


*** Se vuelve a re-balancear los datos 
drop npanel
bysort pid_link: gen npanel =_N
tabulate npanel
keep if npanel==3
xtset,clear
xtset pid_link year,format(%tg)
spbalance



**********************************************************************************
*************************** TASAS DE PRIVACIÓN NO CENSURADAS *********************
**********************************************************************************

global indicators hh_d_water  hh_acceso hh_asegura  hh_schooling hh_attendance  hh_rezago hh_desempleo hh_formalidad hh_trabing hh_hacin hh_materi  hh_bienes hh_cooking hh_electri hh_sanea  

/*fsum $indicators if year==2002
fsum $indicators if year==2006
fsum $indicators if year==2012

mdesc $indicators
*/

br folio year 

foreach var in $indicators {
	gen	NC_H_`var' = 0
	lab var NC_H_`var'  "Tasa de privación no censurada: % personas privadas en"
	
}


foreach var in $indicators {
	foreach year in 02 06 12 {
	sum    `var' [iw = sample_weight] if year==20`year'
	replace	NC_H_`var' = r(mean)*100 if year==20`year'
	}	
}



sum NC_H_* , sep (30)


**********************************************************************************
************************** DEFINIMOS LOS PESOS/PONDERACIONES**********************
**************** Definimos el vector 'w' de los pesos de los indicadores *********


** Recordar que la suma de los pesos debe ser igual a 1 o 100%

// DIMENSION SALUD
foreach var in hh_d_water hh_acceso hh_asegura {
	gen w_`var' = 1/15 
	}

// DIMENSION EDUCACION

foreach var in hh_schooling hh_attendance  hh_rezago {
	gen w_`var' = 1/15 
	}

// DIMENSION TRABAJO
foreach var in hh_desempleo hh_formalidad hh_trabing {
	gen w_`var' = 1/15 
	}


// DIMENSION CALIDAD VIVIENDA
foreach var in hh_hacin hh_materi  hh_cooking {
	gen w_`var' = 1/15
	}

// DIMENSION SERVICIOS
foreach var in hh_sanea  hh_electri  hh_bienes {
	gen w_`var' = 1/15
	}


egen wsum = rsum(w_*) 
bys year: sum  wsum 


**********************************************************************************
******************** MATRIZ DE PRIVACION PONDERADA *******************************
**********************************************************************************

** El siguiente comando multiplica la matriz de privaciOn por el peso de cada indicador. 

foreach var in $indicators {
	gen	g0_w_`var' = `var' * w_`var'
	lab var g0_w_`var' "Privación ponderada de `var'"	
}


**********************************************************************************
*****************   VECTOR DE PRIVACION ******************************************
**********************************************************************************

** Generamos el vector ponderado de privacion individual, 'c'
 
egen	c_vector = rowtotal(g0_w_*)
lab var c_vector "Vector de privación individual"
tab	    c_vector year [aw = sample_weight], m




**********************************************************************************
********************************* IDENTIFICACION *********************************
**********************************************************************************

** Usamos diferentes líneas de pobreza (i.e. diferentes valores de 'k')

forvalue k = 1(1)100 {
	gen	multid_poor_`k' = (c_vector >= `k'/100)
	lab var multid_poor_`k' "Identificación de pobreza con k=`k'%"
	}
	
sort year	
by year: sum multid_poor_* [aw = sample_weight], sep(20)


**********************************************************************************
**************** VECTOR DE PRIVACION CENSURADO ***********************************
**********************************************************************************

** Generamos el vector ponderado y censurado de privacion individual, 'c(k)'

forvalue k = 1(1)100 {
	gen	cens_c_vector_`k' = c_vector 
	replace cens_c_vector_`k' = 0 if multid_poor_`k'==0 
	}

br folio year c_vector cens_c_vector_*

/*

Al aplicar el comando 'sumarize' se obtiene la media del vector de identificacion la proporcion indvidual de privacion promedio y el vector c censurado, para cualquier valor de k.

Con esto se obtiene la Tasa de Incidencia de Pobreza Multidimensional (H), la Intensidad de la Pobreza entre los Pobres (A), y la Tasa de Pobreza Ajustada (M0 o IPM), respectivamente.
*/


forvalue k = 1(1)100 {

	gen a_`k'=0
	}


forvalue k = 1(1)100 {
	foreach year in 02 06 12 {
	sum cens_c_vector_`k' if multid_poor_`k'==1 & year==20`year' [aw = sample_weight], sep(15)
	replace a_`k'= r(mean) if year==20`year'
	sum a_`k'
	}
}
sort year
by year: sum  a_* [aw = sample_weight], sep(20)


forvalue k = 1(1)100 {
	gen M0_`k'= 0
}	

forvalue k = 1(1)100 {
	foreach year in 02 06 12 {
	sum cens_c_vector_`k' if year==20`year' [aw = sample_weight], sep(15)
	replace M0_`k'= r(mean) if year==20`year'
	sum M0_`k'
	}
}	

sort year
by year: sum  cens_c_vector_* [aw = sample_weight], sep(20)



******************************************
/*( ELEGIMOS AHORA UN VALOR PARTICULAR DE 'k' )*/
local k = 26
******************************************

******************************************
*** MATRIZ DE PRIVACION CENSURADA
*****************************************

foreach var in $indicators   {
	gen	g0_`k'_`var' = `var'
	replace g0_`k'_`var' = 0 if multid_poor_`k'==0
}

*******************************************
* HEADCOUNT/INCIDENCE OF MULTIDIMENSIONAL POVERTY FOR CHOSEN k
*******************************************
gen H =0

foreach year in 02 06 12   {
local k = 26
fsum	multid_poor_`k' [aw = sample_weight] if year==20`year'
replace	H = r(mean)*100 if year==20`year'
lab var H "Incidencia (H): % Poblacion que es multidimensionalmente pobre"
}
by year: sum H [aw = sample_weight]

*********************************************
* Intensidad k
*********************************************

gen A =0

foreach year in 02 06 12   {
local k = 26
fsum	cens_c_vector_`k' [aw = sample_weight] if multid_poor_`k'==1 & year==20`year'
replace	A = r(mean)*100 if year==20`year'
lab var A  "Intensidad(A): Promedio % de privaciones ponderadas"
}


by year: sum A [aw = sample_weight]



***********************************************
* IPM k
***********************************************


gen MPI =0

foreach year in 02 06 12   {
local k = 21
fsum	cens_c_vector_`k' [aw = sample_weight] if year==20`year'
replace	MPI = r(mean) if year==20`year'
lab var MPI  "Adjusted Headcount Ratio (MPI = H*A): Range 0 to 1"
}


by year: sum MPI A H [aw = sample_weight]


save "$workingfolder_in/IPM/balanceado/d1/dta/IPMbalanceado.dta",replace




 


