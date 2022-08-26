****************************************************************
* Analisis_1.do Analiza la población de los que tuvieron cambios en la pobreza
* ODS project
*
* Date Created:  20210517
* Name Created:  GC
* Last modified: 20210820
*
* Notas:
*  1. Este dofile construye las tablas de las estimaciones del gasto catastrofico
*	  con la pobreza multidimensional. Además, se construye las tablas para observar
*	  el patrón del gastos de los hogares en India. 
*
***************************************************************

clear all
clear matrix
clear mata
set more off
set maxvar 10000
set mem 500m
cap log close
pause off


*===============================================================================*
*							       PATHS         						   		*
*===============================================================================*

if  "`c(username)'"=="gustavoco36"{
	gl dta "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/" // Ruta de mi computador
}
else{
	gl dta "D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\" // Ruta de mi computador
}


global workingfolder_in "$dta/Datos/India/Code"
global results "$workingfolder_in/Regresion/results"

* Nota [20210517 GC]: Activo el código Xttrans2

do "$workingfolder_in/xttrans.do"


*===============================================================================*
*									DATA								   		*
*===============================================================================*

use "$workingfolder_in/IPM/data/IPMbalanceado_final.dta",replace

*** Reorganizo los controles 
tostring IDHH, replace
** Hogar 
destring IDHH, replace  

* Edad
gen edad1=RO5 if RO4==1
replace edad1=0 if missing(edad1)
bys SURVEY  IDHH: egen edad_jefehogar = max(edad1)
drop edad1

* Sexo
gen genero=RO3 if RO4==1
bys SURVEY  IDHH: egen genero_jefehogar = max(genero)
replace genero_jefehogar = RO3 if missing(genero_jefehogar)
sort genero_jefehogar
label defin genero_jefehogar_label 1 "Masculino" 2 "Femenino"
label values genero_jefehogar genero_jefehogar_label
drop genero
bys SURVEY: tab genero_jefehogar	

gen female = genero_jefehogar==2

* URBAN4o/Rural 
gen URBAN4o=URBAN4==0
gen rural=URBAN4==1


gen p_salud=gsalud/gtotal
replace p_salud=0 if missing(p_salud)
gen catastrofico_percent_sd=p_salud /0.16 // Se usa un único estándar para todos los países

* Defino los controles
global controles "edad_jefehogar hhninos i.quart hhadulmayor ED6 "	


*** Balancear los hogares del panel
/*
bys IDHH: egen id_balanceado=sum(_N)
drop if id_balanceado==1
*/

* Defino el panel
xtset IDHH SURVEY,format(%tg)

forval i=10(10)60{
	egen id_cambio_`i'=rowtotal(multid_poor_`i' pobreza`i'_rezago) if SURVEY==2
	}
forval i=10(10)60{
	bys IDHH: egen hh_id_cambio_`i'=max(id_cambio_`i')
	}
tab1 id_cambio* if RO4==1,m
bys SURVEY: tab1 id_cambio*,m

* Estadisticas descriptivas 
*bys SURVEY: fsum $covs  if RO4==1


*** Dummy de los hogares que residen en el Sur de India
gen south=(STATEID==28|STATEID==29|STATEID==32|STATEID==33) if SURVEY==1
replace south=(STATEID2==728|STATEID2==729|STATEID2==732|STATEID2==733) if SURVEY==2


*******************************************************************************

bys IDHH : gen tot = _N
gen att= tot==1 if SURVEY==1

est drop _all


reg att edad_jefehogar hhninos hhadulmayor female URBAN4o i.quart , r
	est store r1
	estadd ysumm
reg att catastrofico40 edad_jefehogar hhninos hhadulmayor female URBAN4o i.quart , r
	est store r2
reg att multid_poor_40 edad_jefehogar hhninos hhadulmayor female URBAN4o i.quart , r
	est store r3
	
esttab r1 r2 r3 , se star(* .1 ** .05 *** .01) stats(ymean r2 N)
esttab r1 r2 r3 using "$workingfolder_out\determinatesIndia.csv" , se star(* .1 ** .05 *** .01) stats(ymean r2 N) replace
