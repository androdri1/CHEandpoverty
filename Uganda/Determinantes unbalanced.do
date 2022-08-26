*****************************************************
/*
Nombre:Regresiones y Analisis

ODS project

Date Created:09-07-2020
Name Created: JuanG -> PaulR
Last Modified: 01-08-2022

Notas:
*/
clear
clear matrix
clear mata
set more off
set maxvar 30000
set mem 500m
cap log close
pause off


*** Trabajar con la balanceado ***
glo BAS=""		// Balanceado
glo BAS="No"	// No balanceado

***Working Folder Path ***
*glo dta="C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Uganda\Stata"
glo dta="D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Uganda\Stata"

global workingfolder_in "${dta}/4. IPM/d0 IPM con Balanceado/dta" 

global workingfolder_out "${dta}/5. Analisis Posterior/d0 Analisis IPM Balanceado/dta" 

***Log file***
log using "$workingfolder_out/Regresiones.log", replace
**********************************************************************
use "$workingfolder_in/IPM_${BAS}Balanceado_super", clear 
format PID %20.0g
recode region_ (0=1) (1=1) (2=2) (3=3) (4=4)
rename h2q3_ Sex
rename hh_niño_ NumNiños
rename hh_adulto_mayor_ NumAdultoMayor
replace Salud_=0 if Salud==.
keep if h2q4_==1
gen female=1 if Sex==2
replace female=0 if female==.
gen choque_accidente=1 if h16q01110_==1 | h16q01111_==1 
gen choque_muerte=1 if h16q01112_==1 | h16q01113_==1
replace choque_accidente=0 if choque_accidente==.
replace choque_muerte=0 if choque_muerte==.

gen mipeso= wgt_ if Año==9
bys PID: egen elpeso = max(mipeso)
la def Año 9 "2009" ///
		   10 "2010" ///
		   11 "2011", replace 
la val Año Año

forvalues	k=10(10)60{
	gen gasto_catastrofico_`k'=1 if per_gasto_>=`k'/100 
	replace gasto_catastrofico_`k'=0 if gasto_catastrofico_`k'==.
	tab gasto_catastrofico_`k' [aw=wgt], m
}
forvalues k=10(10)60{
		la var gasto_catastrofico_`k' "Gasto Catastrofico al `k'%"
la def gasto_catastrofico_`k' 0 "No tiene gasto catastrófico" ///
						  1 "Tiene gasto Catastrófico"
la val gasto_catastrofico_`k' gasto_catastrofico_`k'
}
	
 
la var h16q01110_ "Accidente serio Head"
la var h16q01111_ "Accidente serio Otro miembro" 
la var h16q01112_ "Muerte Income Earner"
la var h16q01113_ "Muerte Otro miembro"
 
lab var total_gasto_ "Gastos totales del hogar"
lab var Salud_ "Gastos de salud del hogar"
lab var region_ "Región donde reside el hogar"
lab var urban_ "Sector Urbano"
lab var age_ "Edad de los individuos"
lab var Sex "Sexo del Jefe"
lab var NumNiños "Nº. Niños por hogar"
lab var NumAdultoMayor "Nº. Mayores por hogar"
lab var Año "Año"

global indicators  multid_poor_40 hh_d_water_ hh_d_toilet_ hh_access_ hh_d_school_ hh_attend_ hh_rezago_  hh_desempl_  hh_childlab_  hh_hacin hh_materials  hh_d_assets_ hh_electricity  
lab var hh_d_water_ "Agua Potable"
lab var hh_d_toilet_ "Saneamiento"
lab var hh_access_ "Acceso a Salud"
lab var hh_d_school_ "Suficientes Años de escolaridad"
lab var hh_attend_	"Niños estudiando"
lab var hh_rezago_ "Rezago Escolar"
lab var hh_desempl_ "Desempleo"
lab var hh_childlab_ "Trabajo Infantil"
lab var hh_hacin "Hacinamiento"
lab var hh_materials "Materiales del Hogar"
lab var hh_d_assets_ "Activos Hogar"
lab var hh_electricity "Electricidad"

bys Año: egen  quart= xtile(total_gasto_), n(4)   // Crea cuartiles de gasto


gen p_salud=Salud_/total_gasto_
replace p_salud=0 if missing(p_salud)

destring HHID, replace
sort HHID Año
bys HHID : gen wave=_n
xtset HHID wave 
gen catastrofico_percent_sd=p_salud /0.16 // Se usa un único estándar para todos los países
gen d_catastrofico_percent=catastrofico_percent_sd-L.catastrofico_percent_sd


// Dejar todos los controles en un global, para que no esten reescribiendo las cosas
// age, sex, education level of the household head, region and area of residence
glo controles = "age  NumNiños NumAdultoMayor" // female i.region_  


* Variables necesarias para los efectos heterog´neeos 
gen hh_gasto_catastrofico_40=gasto_catastrofico_40

xtset HHID wave 
gen cuartil=L.quart
sort HHID cuartil
by HHID: carryforward cuartil, replace	
xtset HHID wave
xtset
gen urban=L.urban_
sort HHID urban
by HHID: carryforward urban, replace	
xtset
gen catastrofico_rezago=L.hh_gasto_catastrofico_40
sort HHID catastrofico_rezago
by HHID: carryforward catastrofico_rezago, replace	
xtset
gen pobre_rezago=L.multid_poor_40
sort HHID pobre_rezago
by HHID: carryforward pobre_rezago, replace	

rename Año Year



*******************************************************************************
drop if wave==4
bys HHID : gen tot = _N
tab tot if wave==1 // 14.3% droput rate
gen att= tot==1 | tot==2 if wave==1


est drop _all

reg att age NumNiños NumAdultoMayor female urban_ i.quart , r
	est store r1
	estadd ysumm
reg att hh_gasto_catastrofico_40 age NumNiños NumAdultoMayor female urban_ i.quart , r
	est store r2
reg att multid_poor_40 age NumNiños NumAdultoMayor female urban_ i.quart , r
	est store r3
	
esttab r1 r2 r3 , se star(* .1 ** .05 *** .01) stats(ymean r2 N)
esttab r1 r2 r3 using "$workingfolder_out\determinatesUganda.csv" , se star(* .1 ** .05 *** .01) stats(ymean r2 N) replace


