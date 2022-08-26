*****************************************************
/*
Nombre:Regresiones y Analisis

ODS project

Date Created:17-10-2020
Name Created: JuanG -> PaulR
Last Modified: 29-07-2022

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
if  "`c(username)'"=="gustavoco36"{
	gl dta "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/Malawi/Stata" // Ruta de mi computador
}
if "`c(username)'"=="jujog"{
	gl dta "C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Malawi\Stata" //  Ruta de ustedes 
}
if "`c(username)'"=="paul.rodriguez"{
	gl dta "D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Malawi\Stata\" 
}



global workingfolder_in "${dta}/4. Balancear/export"
global workingfolder_out "${dta}/5. Analisis/export" 

***Log file***
**********************************************************************
use "${workingfolder_in}/IPM_NoBalanceado_super_pc", clear  // Este es el que se uso finalmente
*use "${workingfolder_in}/IPM_NoBalanceado_super", clear 

bys HHID : gen tot = _N
gen att= tot==1 if year==2010

rename hh_b03 Sex
rename hhniño NumNiños
rename hhadulto_mayor NumAdultoMayor
replace salud=0 if salud==.
gen female=1 if Sex==2
replace female=0 if female==.
rename year Year
sort HHID Year
replace region=F.region if Year==2010
gen mipeso= hh_wgt

xtile quart = hh_total_gasto, nq(4)  // Crea cuartiles de gasto
gen p_salud=hh_salud/hh_total_gasto
replace p_salud=0 if missing(p_salud)


est drop _all

reg att age NumNiños NumAdultoMayor female reside i.quart , r
	est store r1
	estadd ysumm
reg att hh_gasto_catastrofico_40 age NumNiños NumAdultoMayor female reside i.quart , r
	est store r2
reg att multid_poor_40 age NumNiños NumAdultoMayor female reside i.quart , r
	est store r3
	
esttab r1 r2 r3 , se star(* .1 ** .05 *** .01) stats(ymean r2 N)
esttab r1 r2 r3 using "$workingfolder_out\determinatesMalawi.csv" , se star(* .1 ** .05 *** .01) stats(ymean r2 N) replace


