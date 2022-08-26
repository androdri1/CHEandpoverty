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

***Working Folder Path ***
*glo dta="C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Nigeria\Stata"
glo dta="D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Nigeria\Stata\"

global workingfolder_in "${dta}/3.IPM/export"
global workingfolder_out "${dta}/5. Analisis/export" 
 
***Log file***
log using "$workingfolder_out\Regresiones.log", replace
**********************************************************************
use "$workingfolder_in/IPM_NoBalanceado_super", clear 
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

*******************************************************************************

bys HHID : gen tot = _N
tab tot
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
esttab r1 r2 r3 using "$workingfolder_out\determinatesNigeria.csv" , se star(* .1 ** .05 *** .01) stats(ymean r2 N) replace


