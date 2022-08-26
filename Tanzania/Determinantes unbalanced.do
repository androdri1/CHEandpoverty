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
glo BAS="No"	// No balanceado

***Working Folder Path ***
*glo dta="C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Tanzania\Stata"
glo dta="D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Tanzania\Stata"

global workingfolder_in "${dta}/3.IPM\export" 
global workingfolder_out "${dta}/5. Analisis\export" 

***Log file***
log using "$workingfolder_out/Regresiones.log", replace
**********************************************************************
use "$workingfolder_in/IPM_${BAS}Balanceado_super", clear 


rename hhniño_ NumNiños
rename hhadulto_mayor NumAdultoMayor
gen female=1 if Sex==2
replace female=0 if female==.
sort hhid year
gen mipeso= hh_weight
 
lab var total_gasto "Gastos totales del hogar"
lab var hh_Gasto_Salud_ "Gastos de salud del hogar"
lab var urban_ "Sector Urbano"
lab var age_ "Edad de los individuos"
lab var Sex_ "Sexo del Jefe"
lab var NumNiños "Nº. Niños por hogar"
lab var NumAdultoMayor "Nº. Mayores por hogar"
lab var year "Año"

global indicators hh_d_water_ hh_d_toilet_ hh_d_school hh_attend_  hh_rezago_  hh_desempl_  hh_childlab_  hh_hacin_ hh_materials_  hh_d_assets_  hh_electricity_   
fsum $indicators
 
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

bys year: egen  quart= xtile(hh_total_gasto_), n(4)  // Crea cuartiles de gasto

gen p_salud=hh_Gasto_Salud_/hh_total_gasto_
replace p_salud=0 if missing(p_salud)

rename y2_hhid HHID

sort HHID year
bys HHID : gen wave=_n
xtset HHID wave 
gen catastrofico_percent_sd=p_salud /0.16 // Se usa un único estándar para todos los países
gen d_catastrofico_percent=catastrofico_percent_sd-L.catastrofico_percent_sd

rename age_ age

// Dejar todos los controles en un global, para que no esten reescribiendo las cosas
// age, sex, education level of the household head, region and area of residence
glo controles = "age  NumNiños NumAdultoMayor" // female i.region_  

 xttrans gasto_catastrofico_40
 xttrans multid_poor_40
 
 forvalue k = 1(1)100 {
	gen	gc_`k' = (hh_Gasto_Salud_/(hh_gasto_total_SA))>=`k'/100 if hh_gasto_total_SA_>0 & hh_gasto_total_SA_ !=. & hh_Gasto_Salud_ !=.
	}
sum gc_*



forvalues k=20(10)40{	
	bys year: sum cens_c_vector_`k' if multid_poor_`k'_==1 [aw=mipeso]
}	



forvalues i=10(10)40{
	bys year: tab multid_poor_`i'_	
}




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

rename hh_desempl_ choque_desempleo

rename year Year


*******************************************************************************
bys HHID : gen tot = _N
tab tot if wave==1 // 9.6% droput rate
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
esttab r1 r2 r3 using "$workingfolder_out\determinatesTanzania.csv" , se star(* .1 ** .05 *** .01) stats(ymean r2 N) replace


