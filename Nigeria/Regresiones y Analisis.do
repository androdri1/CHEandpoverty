*****************************************************
/*
Nombre:Regresiones y Analisis

ODS project

Date Created:17-10-2020
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
*glo BAS="No"	// No balanceado

***Working Folder Path ***
*glo dta="C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Nigeria\Stata"
glo dta="D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Nigeria\Stata\"

global workingfolder_in "${dta}/3.IPM/export"
global workingfolder_out "${dta}/5. Analisis/export" 
 
***Log file***
log using "$workingfolder_out\Regresiones.log", replace
**********************************************************************
use "$workingfolder_in/IPM_${BAS}Balanceado_super", clear 
replace year=14 if year==15 
xtset hhid year, delta(2)

rename hhniño NumNiños
rename hhadulto_mayor NumAdultoMayor
gen female=1 if Sex==2
replace female=0 if female==.
sort hhid year
gen mipeso= wt_w1_w2_w3_15

replace age_=. if age_==999
rename age_ age
 
lab var hh_total_gasto_ "Gastos totales del hogar"
lab var hh_Gasto_Salud_ "Gastos de salud del hogar"
lab var urban_ "Sector Urbano"
lab var age_ "Edad de los individuos"
lab var Sex_ "Sexo del Jefe"
lab var NumNiños "Nº. Niños por hogar"
lab var NumAdultoMayor "Nº. Mayores por hogar"
lab var year "Año"

global indicators hh_d_water_ hh_d_toilet_ hh_d_school hh_attend_  hh_rezago_  hh_desempl_  hh_childlab_  hh_hacin_ hh_materials_  hh_d_assets_  hh_electricity_ hh_access_  
bys year hh_gasto_catastrofico_40:fsum $indicators
foreach var in $indicators {
	xttrans `var'
}
bys year: tabstat $indicators
local k=40
tabstat multid_poor_`k'_ [aw = sample_weight], by(year) 
tabstat cens_c_vector_`k' [aw = sample_weight] if multid_poor_`k'_==1, by(year)
tabstat cens_c_vector_`k' [aw = sample_weight], by(year)
 
lab var hh_d_water_ "Agua Potable"
lab var hh_d_toilet_ "Saneamiento"
lab var hh_access_ "Acceso a Salud"
lab var hh_d_school_ "Suficientes Años de escolaridad"
lab var hh_attend_	"Niños estudiando"
lab var hh_rezago_ "Rezago Escolar"
lab var hh_desempl_ "Desempleo"
lab var hh_childlab_ "Trabajo Infantil"
lab var hh_hacin_ "Hacinamiento"
lab var hh_materials_ "Materiales del Hogar"
lab var hh_d_assets_ "Activos Hogar"
lab var hh_electricity_ "Electricidad"

replace urban=0 if urban==1
replace urban=1 if urban==2

bys year: egen  quart= xtile(hh_total_gasto_), n(4)   // Crea cuartiles de gasto

gen p_salud=hh_Gasto_Salud_/hh_gasto_total_SA_
replace p_salud=0 if missing(p_salud)

xtset hhid wave 
gen catastrofico_percent_sd=p_salud /0.16 // Se usa un único estándar para todos los países
gen d_catastrofico_percent=catastrofico_percent_sd-L.catastrofico_percent_sd


// Dejar todos los controles en un global, para que no esten reescribiendo las cosas
// age, sex, education level of the household head, region and area of residence
glo controles = "age  NumNiños NumAdultoMayor" // female years_schooling_
 
 xttrans gasto_catastrofico_40
 xttrans multid_poor_40
 
 forvalue k = 1(1)100 {
	gen	hh_gc_`k' = (hh_Gasto_Salud_/(hh_gasto_total_SA_))>=`k'/100 if hh_gasto_total_SA_>0 & hh_gasto_total_SA_ !=. & hh_Gasto_Salud_ !=.
	}
sum hh_gc_*

 forvalue k = 10(10)40 {
 forvalue i = 10(10)40 {
 	display `k' `i'
 reg multid_poor_`k'_ hh_gasto_catastrofico_`i'_, vce(cluster hhid)
 }
 }
 
 

* Variables necesarias para los efectos heterog´neeos 
xtset hhid wave 
gen cuartil=L.quart
sort hhid cuartil
by hhid: carryforward cuartil, replace	
xtset hhid wave
xtset
gen urban=L.urban_
sort hhid urban
by hhid: carryforward urban, replace	
xtset
gen catastrofico_rezago=L.hh_gasto_catastrofico_40
sort hhid catastrofico_rezago
by hhid: carryforward catastrofico_rezago, replace	
xtset
gen pobre_rezago=L.multid_poor_40
sort hhid pobre_rezago
by hhid: carryforward pobre_rezago, replace	

rename hh_gasto_catastrofico_40_ hh_gasto_catastrofico_40
rename year Year
gen  HHID = hhid

xxx 
 
/////////////////////////////////////////////////////Analisis gráfico///////////////////////////////////////////////////
if 1==0 {

	foreach var in $indicators{
		xttrans `var'
	}
	forvalues k=10(10)40{
		forvalues i=10(10)60{
		display `i'
		display `k'
	bys hh_gasto_catastrofico_`k'_: tab super_pobreza_`i'
		}
	}

	preserve
	cap mat drop results
	forval i=5(1)95 {
	quietly  xtreg multid_poor_40 hh_gc_`i' $controles, fe cluster(hhid)
	sca b_yas = _b[ hh_gc_`i' ]
	sca se_yas = _se[ hh_gc_`i' ]
	mat results=nullmat(results)\ [`i',b_yas, se_yas] // Guarda en una matrix los resultados de la regresion
	}
	svmat results
	keep results*
	drop if results1==.
	rename results1 id
	rename results2 beta_time
	rename results3 se_time

	lab var id "Catastrophic expenditure threshold"

	gen se_uptime= beta_time+se_time*1.645
	gen se_lowtime= beta_time-se_time*1.645
	lab var se_uptime "Upper 90% CI"
	lab var se_lowtime "Lower 90% CI"

	tw (rcap se_uptime se_lowtime id) (scatter beta_time id ), ///
	legend(off)  ///
	xtitle("Catastrophic expenditure threshold ") ///
	scheme(Plotplainblind)

	graph export "$workingfolder_out\Umbral", as(png) name("Graph")
	restore

}


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

