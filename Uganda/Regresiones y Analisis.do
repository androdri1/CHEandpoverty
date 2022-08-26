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


xxx 

*===============================================================================*
*			       TABLA 4  	/ TABLA A5 si es NoBalanceado					*
*===============================================================================*
cap mat drop results

* 1) Es la regresion base cross-section
reghdfe multid_poor_40 hh_gasto_catastrofico_40 $controles female ,  absorb(  Year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [1,_b[hh_gasto_catastrofico_40], p_value] // Guarda en una matrix los resultados de la regresion

* 2) Es la regresion base longitudinal
reghdfe multid_poor_40 hh_gasto_catastrofico_40 $controles,  absorb(  HHID Year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [2,_b[hh_gasto_catastrofico_40], p_value] // Guarda en una matrix los resultados de la regresion

* 3) Es la regresion de los cuartiles 
reghdfe multid_poor_40 c.hh_gasto_catastrofico_40#i.cuartil i.cuartil $controles,  absorb(  HHID Year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.cuartil#hh_gasto_catastrofico_40]/_se[1b.cuartil#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [31,_b[1b.cuartil#hh_gasto_catastrofico_40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.cuartil#hh_gasto_catastrofico_40]/_se[2.cuartil#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [32,_b[2.cuartil#hh_gasto_catastrofico_40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.cuartil#hh_gasto_catastrofico_40]/_se[3.cuartil#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [33,_b[3.cuartil#hh_gasto_catastrofico_40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.cuartil#hh_gasto_catastrofico_40]/_se[4.cuartil#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [34,_b[4.cuartil#hh_gasto_catastrofico_40], p_value] 	
	
* 4) Es la regresion de rural y urbano
reghdfe multid_poor_40 c.hh_gasto_catastrofico_40#i.urban i.urban $controles,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.urban#hh_gasto_catastrofico_40]/_se[0b.urban#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [41,_b[0b.urban#hh_gasto_catastrofico_40], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.urban#hh_gasto_catastrofico_40]/_se[1.urban#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [42,_b[1.urban#hh_gasto_catastrofico_40], p_value] // Urban
				
* 5) Es la regresion del rezago del gasto catastrofico
reghdfe multid_poor_40 c.hh_gasto_catastrofico_40#i.catastrofico_rezago i.catastrofico_rezago $controles,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.catastrofico_rezago#hh_gasto_catastrofico_40]/_se[0b.catastrofico_rezago#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [51,_b[0b.catastrofico_rezago#hh_gasto_catastrofico_40], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1.catastrofico_rezago#hh_gasto_catastrofico_40]/_se[1.catastrofico_rezago#hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [52,_b[1.catastrofico_rezago#hh_gasto_catastrofico_40], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_40 c.hh_gasto_catastrofico_40 $controles if pobre_rezago==0,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [6,_b[hh_gasto_catastrofico_40], p_value] // Not poor
reghdfe multid_poor_40 c.hh_gasto_catastrofico_40 $controles if pobre_rezago==1,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40]))
	mat results=nullmat(results)\ [7,_b[hh_gasto_catastrofico_40], p_value] // Poor

* 8) Disease Shock (Accident Shock in Malawi)
reghdfe multid_poor_40 c.choque_accidente $controles,  absorb(  HHID Year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[choque_accidente]/_se[choque_accidente]))
	mat results=nullmat(results)\ [8,_b[choque_accidente], p_value] 

* 9) Death Shock. choque_muerte
reghdfe multid_poor_40 c.choque_muerte $controles,  absorb(  HHID Year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[choque_muerte]/_se[choque_muerte]))
	mat results=nullmat(results)\ [9,_b[choque_muerte], p_value] 

* 10) Unemployment Shock. choque_desempleo
	mat results=nullmat(results)\ [10,., .] 

* 11) Share of healthcare expenditures divided by the mean SD
reghdfe multid_poor_40 c.catastrofico_percent_sd $controles,  absorb(  HHID Year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd]))
	mat results=nullmat(results)\ [11,_b[catastrofico_percent_sd], p_value] 

	
sum p_salud if p_salud>0
mat results=nullmat(results)\ [12, r(sd), .] 
	
mat list results	

*===============================================================================*
*							       TABLA A3  (continuous)		  		   		*
*===============================================================================*
cap mat drop results

* 0) 

* 1) Es la regresion de los cuartiles 
reghdfe multid_poor_40 c.catastrofico_percent_sd#i.cuartil i.cuartil $controles,  absorb(  HHID Year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.cuartil#catastrofico_percent_sd]/_se[1b.cuartil#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [31,_b[1b.cuartil#catastrofico_percent_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.cuartil#catastrofico_percent_sd]/_se[2.cuartil#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [32,_b[2.cuartil#catastrofico_percent_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.cuartil#catastrofico_percent_sd]/_se[3.cuartil#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [33,_b[3.cuartil#catastrofico_percent_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.cuartil#catastrofico_percent_sd]/_se[4.cuartil#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [34,_b[4.cuartil#catastrofico_percent_sd], p_value] 	
	
* 4) Es la regresion de rural y urbano
reghdfe multid_poor_40 c.catastrofico_percent_sd#i.urban i.urban $controles,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.urban#catastrofico_percent_sd]/_se[0b.urban#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [41,_b[0b.urban#catastrofico_percent_sd], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.urban#catastrofico_percent_sd]/_se[1.urban#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [42,_b[1.urban#catastrofico_percent_sd], p_value] // Urban
				
* 5) Es la regresion del rezago del gasto catastrofico
reghdfe multid_poor_40 c.catastrofico_percent_sd#i.catastrofico_rezago i.catastrofico_rezago $controles,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.catastrofico_rezago#catastrofico_percent_sd]/_se[0b.catastrofico_rezago#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [51,_b[0b.catastrofico_rezago#catastrofico_percent_sd], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1.catastrofico_rezago#catastrofico_percent_sd]/_se[1.catastrofico_rezago#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [52,_b[1.catastrofico_rezago#catastrofico_percent_sd], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_40 c.catastrofico_percent_sd $controles if pobre_rezago==0,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd]))
	mat results=nullmat(results)\ [6,_b[catastrofico_percent_sd], p_value] // Not poor
reghdfe multid_poor_40 c.catastrofico_percent_sd $controles if pobre_rezago==1,  absorb(  HHID Year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd]))
	mat results=nullmat(results)\ [7,_b[catastrofico_percent_sd], p_value] // Poor
	
	
mat list results	



*===============================================================================*
*							       TABLA A4  (logit)		  		   		*
*===============================================================================*
cap mat drop results

* 1) Es la regresion base cross-section
logit multid_poor_40 hh_gasto_catastrofico_40 $controles female  i.Year
margins, dydx(hh_gasto_catastrofico_40) post
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40])))
	mat results=nullmat(results)\ [1,_b[hh_gasto_catastrofico_40], p_value] // Guarda en una matrix los resultados de la regresion

* 2) Es la regresion base longitudinal
xtlogit multid_poor_40 hh_gasto_catastrofico_40 $controles i.Year, fe 
margins, dydx(hh_gasto_catastrofico_40) post
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40])))
	mat results=nullmat(results)\ [2,_b[hh_gasto_catastrofico_40], p_value] // Guarda en una matrix los resultados de la regresion

* 3) Es la regresion de los cuartiles 
xtlogit multid_poor_40 c.hh_gasto_catastrofico_40#i.cuartil i.cuartil $controles i.Year, fe 
margins, dydx(hh_gasto_catastrofico_40) at (cuartil=(1(1)4)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:1._at]/_se[hh_gasto_catastrofico_40:1._at])))
	mat results=nullmat(results)\ [31,_b[hh_gasto_catastrofico_40:1._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:2._at]/_se[hh_gasto_catastrofico_40:2._at])))
	mat results=nullmat(results)\ [32,_b[hh_gasto_catastrofico_40:2._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:3._at]/_se[hh_gasto_catastrofico_40:3._at])))
	mat results=nullmat(results)\ [33,_b[hh_gasto_catastrofico_40:3._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:4._at]/_se[hh_gasto_catastrofico_40:4._at])))
	mat results=nullmat(results)\ [34,_b[hh_gasto_catastrofico_40:4._at], p_value] 	
	
* 4) Es la regresion de rural y urbano
xtlogit multid_poor_40 c.hh_gasto_catastrofico_40#i.urban i.urban $controles i.Year, fe 
margins, dydx(hh_gasto_catastrofico_40) at (urban=(0(1)1)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:1._at]/_se[hh_gasto_catastrofico_40:1._at])))
	mat results=nullmat(results)\ [41,_b[hh_gasto_catastrofico_40:1._at], p_value] // Rural
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:2._at]/_se[hh_gasto_catastrofico_40:2._at])))
	mat results=nullmat(results)\ [42,_b[hh_gasto_catastrofico_40:2._at], p_value] // Urban
				
* 5) Es la regresion del rezago del gasto catastrofico
xtlogit multid_poor_40 c.hh_gasto_catastrofico_40#i.catastrofico_rezago i.catastrofico_rezago $controles i.Year, fe  
margins, dydx(hh_gasto_catastrofico_40) at (catastrofico_rezago=(0(1)1)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:1._at]/_se[hh_gasto_catastrofico_40:1._at])))
	mat results=nullmat(results)\ [51,_b[hh_gasto_catastrofico_40:1._at], p_value] // CHP No
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40:2._at]/_se[hh_gasto_catastrofico_40:2._at])))
	mat results=nullmat(results)\ [52,_b[hh_gasto_catastrofico_40:2._at], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
xtlogit multid_poor_40 c.hh_gasto_catastrofico_40 $controles i.Year if pobre_rezago==0 , re  
margins, dydx(hh_gasto_catastrofico_40) post
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40])))
	mat results=nullmat(results)\ [6,_b[hh_gasto_catastrofico_40], p_value] // Not poor
xtlogit multid_poor_40 c.hh_gasto_catastrofico_40 $controles i.Year if pobre_rezago==1 , re 
margins, dydx(hh_gasto_catastrofico_40) post
	sca p_value = 2*(1-normal(abs(_b[hh_gasto_catastrofico_40]/_se[hh_gasto_catastrofico_40])))
	mat results=nullmat(results)\ [7,_b[hh_gasto_catastrofico_40], p_value] // Poor

* 8) Disease Shock (Accident Shock in Malawi)
xtlogit multid_poor_40 c.choque_accidente $controles i.Year, fe 
margins, dydx(choque_accidente) post
	sca p_value = 2*(1-normal(abs(_b[choque_accidente]/_se[choque_accidente])))
	mat results=nullmat(results)\ [8,_b[choque_accidente], p_value] 

* 9) Death Shock. choque_muerte
xtlogit multid_poor_40 c.choque_muerte $controles i.Year, fe 
margins, dydx(choque_muerte) post
	sca p_value = 2*(1-normal(abs(_b[choque_muerte]/_se[choque_muerte])))
	mat results=nullmat(results)\ [9,_b[choque_muerte], p_value] 

* 10) Unemployment Shock. choque_desempleo
	mat results=nullmat(results)\ [10,., .] 

* 11) Share of healthcare expenditures divided by the mean SD
xtlogit multid_poor_40 c.catastrofico_percent_sd $controles i.Year, fe 
margins, dydx(catastrofico_percent_sd) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd])))
	mat results=nullmat(results)\ [11,_b[catastrofico_percent_sd], p_value] 

mat list results	
