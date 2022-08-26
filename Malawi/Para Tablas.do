clear
clear matrix
clear mata
set more off
set maxvar 30000
set mem 500m
cap log close
pause off

*glo folder="C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Malawi\Stata"
glo folder="D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Malawi\Stata\"

*** Trabajar con la balanceado ***
glo BAS=""		// Balanceado
*glo BAS="No"	// No balanceado

***Working Folder Path ***
global workingfolder_in  "$folder\4. Balancear\export" 
global workingfolder_out "$folder\5. Analisis\export" 
***Log file***
log using "$workingfolder_out\Regresiones.log", replace
**********************************************************************
use "$workingfolder_in\IPM_${BAS}Balanceado_super", clear 

sort HHID year
bys HHID: gen wave=_n
xtset HHID wave

rename multid_poor_*_ multid_poor_*

rename hh_b03 Sex
rename hhniño NumNiños
rename hhadulto_mayor NumAdultoMayor
replace salud=0 if salud==.
gen female=1 if Sex==2
replace female=0 if female==.
rename year Year

replace region=F.region if Year==2010
gen mipeso= hh_wgt
gen age2=age*age
 
lab var total_gasto "Gastos totales del hogar"
lab var salud "Gastos de salud del hogar"
lab var region "Región donde reside el hogar"
lab var reside "Sector Urbano"
lab var age "Edad de los individuos"
lab var Sex "Sexo del Jefe"
lab var NumNiños "Nº. Niños por hogar"
lab var NumAdultoMayor "Nº. Mayores por hogar"
lab var Year "Año"

global indicators  multid_poor_40 hh_d_water_ hh_d_toilet_ hh_access_ hh_d_school_ hh_attend_ hh_rezago_  hh_desempl_  hh_childlab_  hh_hacin hh_materials  hh_d_assets_ hh_electricity 
 
lab var hh_d_water "Agua Potable"
lab var hh_d_toilet "Saneamiento"
lab var hh_access "Acceso a Salud"
lab var hh_d_school "Suficientes Años de escolaridad"
lab var hh_attend	"Niños estudiando"
lab var hh_rezago "Rezago Escolar"
lab var hh_desempl "Desempleo"
lab var hh_childlab "Trabajo Infantil"
lab var hh_hacin "Hacinamiento"
lab var hh_materials "Materiales del Hogar"
lab var hh_d_assets "Activos Hogar"
lab var hh_electricity "Electricidad"

bys Year: egen  quart= xtile(hh_total_gasto), n(4) 
gen p_salud=salud/hh_gasto_total_SA
sum p_salud
return list
replace p_salud=p_salud/r(sd)
replace p_salud=0 if missing(p_salud)


sort HHID Year
foreach var in reside quart multid_poor_10 multid_poor_20 multid_poor_30 multid_poor_40 multid_poor_50 multid_poor_60 hh_gasto_catastrofico_10 hh_gasto_catastrofico_20 hh_gasto_catastrofico_30 hh_gasto_catastrofico_40{

bys HHID: gen l`var'=`var'[_n-1]
gsort HHID - Year
bys HHID: carryforward l`var', replace	
gsort HHID  Year
bys HHID: carryforward l`var', replace
}

/*drop hh_c01-hh_w15
drop hh_a22_1-hh_g05916_mes
drop hh_b10a-hh_e59_1b
drop hh_a16-hh_u04c1102
drop hh_f01_1a-hh_t12_oth
*/
glo controles = "age age2 i.region female reside NumNiños NumAdultoMayor choque_desempleo choque_accidente choque_muerte" 
 // Dejar todos los controles en un global, para que no esten reescribiendo las cosas
 xttrans gasto_catastrofico_40
 xttrans multid_poor_40

 forvalue k = 1(1)100 {
	gen	gc_`k' = (salud/(gasto_total_SA))>=`k'/100 if gasto_total_SA>0 & gasto_total_SA !=. & salud !=.
	}

	gen Hospitalizado=hh_d13
	replace Hospitalizado=0 if Hospitalizado==2 | Hospitalizado ==.
	
	gen Enfermo_trabajo=hh_e15 if hh_e15==2
	replace Enfermo_trabajo=1 if Enfermo_trabajo==2
	replace Enfermo_trabajo=0 if hh_e15==.
 forvalue k = 10(10)60 {	
tab multid_poor_`k'
}
 e
///////////////////Para tablas bonitas////////////////////////
cd "$workingfolder_out\Regresiones reghdfe\"

xtset HHID wave	
forval i=10(10)60 {
	preserve
	eststo: reghdfe multid_poor_`i' gasto_catastrofico_40 $controles, absorb(HHID Year)  vce(cluster HHID)
	eststo: reghdfe multid_poor_`i' c.gasto_catastrofico_40#i.L.quart i.L.quart  $controles, absorb(HHID Year)  vce(cluster HHID)
	esttab using Parte1_Tablas`i'.tex, label replace booktabs ///
	title(Regresión Pobreza al `i'%)
	discard
	restore
}

forval i=10(10)60 {
	disp in red "Corte poor: `i'"
	preserve
	eststo: reghdfe multid_poor_`i' c.gasto_catastrofico_40#i.reside reside $controles, absorb(HHID Year)  vce(cluster HHID)
	eststo: reghdfe multid_poor_`i' c.gasto_catastrofico_40#i.L.gasto_catastrofico_40  L.gasto_catastrofico_40 $controles, absorb(HHID Year)  vce(cluster HHID) 
	eststo: reghdfe multid_poor_`i' i.L.multid_poor_`i'#c.gasto_catastrofico_40 L.multid_poor_`i' $controles, absorb(HHID Year)  vce(cluster HHID)
	esttab using Parte2_Tablas`i'.tex, label replace booktabs ///
	title(Regresión2 Pobreza al `i'%)
	discard
	restore
}
/////////////////////////////////////////////Para el Excel/////////////////////////////////////////////////

global indicators hh_d_water_ hh_d_toilet_ hh_access_ hh_d_school_ hh_attend_ hh_rezago_  hh_desempl_  hh_childlab_  hh_hacin_ hh_materials_ hh_d_assets_ hh_electricity_  
forval k=10(10)40{
	preserve
	forval i=10(10)60 {
		quietly reghdfe multid_poor_`i' hh_gasto_catastrofico_`k' $controles, absorb(HHID Year)  vce(cluster HHID)
		sca b_catastrofico1 = _b[hh_gasto_catastrofico_`k']
		sca p_value_catastrofico1 = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_`k']/_se[hh_gasto_catastrofico_`k']))

		quietly reghdfe multid_poor_`i' c.hh_gasto_catastrofico_`k'#i.lreside $controles, absorb(HHID Year)  vce(cluster HHID)
		sca b_urban1 = _b[1b.lreside#c.hh_gasto_catastrofico_`k']
		sca p_value_urban1 = 2*ttail(e(df_r),abs(_b[1b.lreside#c.hh_gasto_catastrofico_`k']/_se[1b.lreside#c.hh_gasto_catastrofico_`k']))
		sca b_urban2 = _b[2.lreside#c.hh_gasto_catastrofico_`k']
		sca p_value_urban2 = 2*ttail(e(df_r),abs(_b[2.lreside#c.hh_gasto_catastrofico_`k']/_se[2.lreside#c.hh_gasto_catastrofico_`k']))
		 
		quietly reghdfe multid_poor_`i' c.hh_gasto_catastrofico_`k'#i.lquart $controles, absorb(HHID Year)  vce(cluster HHID)
		sca b_quarter1 = _b[1b.lquart#c.hh_gasto_catastrofico_`k']
		sca p_value_quarter1 = 2*ttail(e(df_r),abs(_b[1b.lquart#c.hh_gasto_catastrofico_`k']/_se[1b.lquart#c.hh_gasto_catastrofico_`k']))
		sca b_quarter2 = _b[2.lquart#c.hh_gasto_catastrofico_`k']
		sca p_value_quarter2 = 2*ttail(e(df_r),abs(_b[2.lquart#c.hh_gasto_catastrofico_`k']/_se[2.lquart#c.hh_gasto_catastrofico_`k']))
		sca b_quarter3 = _b[3.lquart#c.hh_gasto_catastrofico_`k']
		sca p_value_quarter3 = 2*ttail(e(df_r),abs(_b[3.lquart#c.hh_gasto_catastrofico_`k']/_se[3.lquart#c.hh_gasto_catastrofico_`k']))
		sca b_quarter4 = _b[4.lquart#c.hh_gasto_catastrofico_`k']
		sca p_value_quarter4 = 2*ttail(e(df_r),abs(_b[4.lquart#c.hh_gasto_catastrofico_`k']/_se[4.lquart#c.hh_gasto_catastrofico_`k']))

		quietly reghdfe multid_poor_`i' c.hh_gasto_catastrofico_`k'#i.lhh_gasto_catastrofico_`k'  lhh_gasto_catastrofico_`k' $controles, absorb(HHID Year)  vce(cluster HHID) 
		sca b_lag1 = _b[ 0b.lhh_gasto_catastrofico_`k'#c.hh_gasto_catastrofico_`k']	
		sca p_value_lag1 = 2*ttail(e(df_r),abs(_b[0b.lhh_gasto_catastrofico_`k'#c.hh_gasto_catastrofico_`k']/_se[0b.lhh_gasto_catastrofico_`k'#c.hh_gasto_catastrofico_`k']))
		sca b_lag2 = _b[ 1.lhh_gasto_catastrofico_`k'#c.hh_gasto_catastrofico_`k']	
		sca p_value_lag2 = 2*ttail(e(df_r),abs(_b[1.lhh_gasto_catastrofico_`k'#c.hh_gasto_catastrofico_`k']/_se[1.lhh_gasto_catastrofico_`k'#c.hh_gasto_catastrofico_`k']))

		quietly reghdfe multid_poor_`i' c.hh_gasto_catastrofico_`k' $controles  if lmultid_poor_`i'==0, absorb(HHID Year)  vce(cluster HHID)
		sca b_pobre1 = _b[hh_gasto_catastrofico_`k']	
		sca p_value_pobre1 = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_`k']/_se[hh_gasto_catastrofico_`k']))
		quietly reghdfe multid_poor_`i' c.hh_gasto_catastrofico_`k' $controles  if lmultid_poor_`i'==1, absorb(HHID Year)  vce(cluster HHID)
		sca b_pobre2 = _b[hh_gasto_catastrofico_`k']	
		sca p_value_pobre2 = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_`k']/_se[hh_gasto_catastrofico_`k']))

		quietly  reghdfe multid_poor_`i' hh_gasto_catastrofico_`k' p_salud choque_desempleo choque_accidente choque_muerte, absorb(HHID Year)  vce(cluster HHID)
		sca b_salud = _b[p_salud]	
		sca p_value_salud = 2*ttail(e(df_r),abs(_b[p_salud]/_se[p_salud]))
		sca b_accidente = _b[choque_accidente]	
		sca p_value_accidente = 2*ttail(e(df_r),abs(_b[choque_accidente]/_se[choque_accidente]))
		sca b_muerte = _b[choque_muerte]	
		sca p_value_muerte = 2*ttail(e(df_r),abs(_b[choque_accidente]/_se[choque_accidente]))
		sca b_desempleo = _b[choque_desempleo]	
		sca p_value_desempleo = 2*ttail(e(df_r),abs(_b[choque_desempleo]/_se[choque_desempleo]))

		mat results_`i'=nullmat(results)\ [b_catastrofico1, p_value_catastrofico1, b_quarter1, p_value_quarter1, b_quarter2, p_value_quarter2, b_quarter3, p_value_quarter3, b_quarter4, p_value_quarter4, b_urban1, p_value_urban1, b_urban2, p_value_urban2, b_lag1, p_value_lag1, b_lag2, p_value_lag2, b_pobre1, p_value_pobre1, b_pobre2, p_value_pobre2, b_salud, p_value_salud, b_accidente, p_value_accidente, b_muerte, p_value_muerte, b_desempleo, p_value_desempleo] // Guarda en una matrix los resultados de la regresion

	}
	svmat results_10
	svmat results_20
	svmat results_30
	svmat results_40
	svmat results_50
	svmat results_60

	keep results_*
	keep in 1

	gen HHID=1
	reshape long results_10 results_20 results_30 results_40 results_50 results_60, i(HHID) j(Independientes)
	export excel using "$workingfolder_out\Regresiones reghdfe\Resultados_`k'.xls", firstrow(variables) replace
	restore
}
/////////////////////////////////////////////////////////////////////////gasto catastrofico indicadores////////////////////////////////////////////////////////////
restore
preserve
global indicators hh_d_water hh_d_toilet hh_access hh_d_school hh_attend hh_rezago hh_desempl hh_childlab  hh_hacin hh_materials hh_d_assets hh_electricity  

foreach var in $indicators   {
forval  i=10(10)40 {
quietly  reghdfe `var' hh_gasto_catastrofico_`i'  $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_yas_`i' = _b[hh_gasto_catastrofico_`i']
sca p_value_`i' = 2*ttail(e(df_r),abs(_b[hh_gasto_catastrofico_`i' ]/_se[hh_gasto_catastrofico_`i' ]))
mat results_`var'_`i'=nullmat(results_`var')\ [b_yas_`i', p_value_`i'] // Guarda en una matrix los resultados de la regresion
}
forval  i=10(10)40 {
   svmat results_`var'_`i'
cap mat drop results_`var'_`i'
}
}

//mat results_`i'=nullmat(results)\ [`i', b_hh_d_water_, p_value_hh_d_water_, b_hh_d_toilet_, p_value_hh_d_toilet_, b_hh_access_, p_value_hh_access_,  b_hh_d_school_, p_value_hh_d_school_, b_hh_attend_, p_value_hh_attend_, b_hh_rezago_, p_value_hh_rezago_,  b_hh_desempl_, p_value_hh_desempl_,  b_hh_childlab_, p_value_hh_childlab_,  b_hh_hacin_, p_value_hh_hacin_, b_hh_materials_, p_value_hh_materials_,  b_hh_d_assets_, p_value_hh_d_assets_, b_hh_electricity_, p_value_hh_electricity_] // Guarda en una matrix los resultados de la regresion

keep results_*
keep in 1

gen HHID=1
reshape long results_hh_d_water_ results_hh_d_toilet_ results_hh_access_ results_hh_d_school_ results_hh_attend_ results_hh_rezago_ results_hh_desempl_  results_hh_childlab_ results_hh_hacin_ results_hh_materials_ results_hh_d_assets_ results_hh_electricity_, i(HHID) j(Independientes)

export excel using "$workingfolder_out\Regresiones reghdfe\Resultados_Indicadores.xls", firstrow(variables) replace


/////Con los censurados////

global indicators2 g0_w_hh_d_water g0_w_hh_access g0_w_hh_d_toilet g0_w_hh_d_school g0_w_hh_attend g0_w_hh_rezago g0_w_hh_desempl g0_w_hh_childlab g0_w_hh_hacin g0_w_hh_materials g0_w_hh_d_assets g0_w_hh_electricity

foreach var in $indicators2   {
forval  i=10(10)60 {
quietly  reghdfe `var' gc_`i'  $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_yas_`i' = _b[gc_`i']
sca p_value_`i' = 2*ttail(e(df_r),abs(_b[gc_`i']/_se[gc_`i']))
mat results_`var'_`i'=nullmat(results_`var')\ [b_yas_`i', p_value_`i'] // Guarda en una matrix los resultados de la regresion
}
forval  i=10(10)60 {
   svmat results_`var'_`i'
cap mat drop results_`var'_`i'
}
}

//mat results_`i'=nullmat(results)\ [`i', b_hh_d_water_, p_value_hh_d_water_, b_hh_d_toilet_, p_value_hh_d_toilet_, b_hh_access_, p_value_hh_access_,  b_hh_d_school_, p_value_hh_d_school_, b_hh_attend_, p_value_hh_attend_, b_hh_rezago_, p_value_hh_rezago_,  b_hh_desempl_, p_value_hh_desempl_,  b_hh_childlab_, p_value_hh_childlab_,  b_hh_hacin_, p_value_hh_hacin_, b_hh_materials_, p_value_hh_materials_,  b_hh_d_assets_, p_value_hh_d_assets_, b_hh_electricity_, p_value_hh_electricity_] // Guarda en una matrix los resultados de la regresion

keep results_*
keep in 1

gen HHID=1
reshape long results_g0_w_hh_d_water_ results_g0_w_hh_d_toilet_ results_g0_w_hh_access_ results_g0_w_hh_d_school_ results_g0_w_hh_attend_ results_g0_w_hh_rezago_ results_g0_w_hh_desempl_  results_g0_w_hh_childlab_ results_g0_w_hh_hacin_ results_g0_w_hh_materials_ results_g0_w_hh_d_assets_ results_g0_w_hh_electricity_, i(HHID) j(Independientes)

export excel using "$workingfolder_out\Regresiones reghdfe\Resultados_Indicadores_Cens.xls", firstrow(variables) replace

/////////////////////////////////////////////////////////////////////c vector//////////////////////////////////////////////////////////////////////
restore
preserve
glo controles = "age i.region female i.L.quart reside NumNiños NumAdultoMayor"  // Dejar todos los controles en un global, para que no 
global indicators hh_d_water_ hh_d_toilet_ hh_access_ hh_d_school_ hh_attend_ hh_rezago_  hh_desempl_  hh_childlab_  hh_hacin_ hh_materials_ hh_d_assets_ hh_electricity_  

cap mat drop results
sort  HHID Year
gen perc_Salud=(salud/total_gasto)*100
gen perc_total_SA=(salud/gasto_total_SA)*100

gen razon=perc_Salud/perc_total_SA
forvalues k=10(10)40{
	foreach var in razon hh_gasto_catastrofico_`k' choque_accidente choque_muerte choque_desempleo{
quietly reghdfe c_vector `var', absorb(HHID Year)  vce(cluster HHID)
	sca b_`var'= _b[`var']	
	sca p_value_`var' = 2*ttail(e(df_r),abs(_b[`var']/_se[`var']))
}
}
mat results =nullmat(results)\ [b_razon, p_value_razon, b_hh_gasto_catastrofico_10, p_value_hh_gasto_catastrofico_10, b_hh_gasto_catastrofico_20, p_value_hh_gasto_catastrofico_20, b_hh_gasto_catastrofico_30, p_value_hh_gasto_catastrofico_30,  b_hh_gasto_catastrofico_40, p_value_hh_gasto_catastrofico_40, b_choque_accidente, p_value_choque_accidente, b_choque_muerte, p_value_choque_muerte, b_choque_desempleo, p_value_choque_desempleo] // Guarda en una matrix los resultados de la regresion

svmat results
keep results*
keep in 1

gen HHID=1
reshape long results, i(HHID) j(Independientes)
export excel using "$workingfolder_out\Regresiones reghdfe\ResultadosVector.xls", firstrow(variables) replace

////////////////////////////////////////////////////////////////////////////////HOSPITALIZACION///////////////////////////////////////////////////////////////////////////////
preserve
forval i=10(10)60 {
quietly reghdfe multid_poor_`i' Hospitalizado $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_hospi1 = _b[Hospitalizado]
sca p_value_hospi1 = 2*ttail(e(df_r),abs(_b[Hospitalizado]/_se[Hospitalizado]))
 
quietly reghdfe multid_poor_`i' c.Hospitalizado#i.L.quart $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_quarter1 = _b[1bL.quart#c.Hospitalizado]
sca p_value_quarter1 = 2*ttail(e(df_r),abs(_b[1bL.quart#c.Hospitalizado]/_se[1bL.quart#c.Hospitalizado]))
sca b_quarter2 = _b[2L.quart#c.Hospitalizado]
sca p_value_quarter2 = 2*ttail(e(df_r),abs(_b[2L.quart#c.Hospitalizado]/_se[2L.quart#c.Hospitalizado]))
sca b_quarter3 = _b[3L.quart#c.Hospitalizado]
sca p_value_quarter3 = 2*ttail(e(df_r),abs(_b[3L.quart#c.Hospitalizado]/_se[3L.quart#c.Hospitalizado]))
sca b_quarter4 = _b[4L.quart#c.Hospitalizado]
sca p_value_quarter4 = 2*ttail(e(df_r),abs(_b[4L.quart#c.Hospitalizado]/_se[4L.quart#c.Hospitalizado]))

quietly reghdfe multid_poor_`i' c.Hospitalizado#i.reside $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_urban1 = _b[1b.reside#c.Hospitalizado]
sca p_value_urban1 = 2*ttail(e(df_r),abs(_b[1b.reside#c.Hospitalizado]/_se[1b.reside#c.Hospitalizado]))
sca b_urban2 = _b[2.reside#c.Hospitalizado]
sca p_value_urban2 = 2*ttail(e(df_r),abs(_b[2.reside#c.Hospitalizado]/_se[2.reside#c.Hospitalizado]))

quietly  reghdfe multid_poor_`i' c.Hospitalizado#i.L.Hospitalizado  L.Hospitalizado $controles, absorb(HHID Year)  vce(cluster HHID) 
sca b_lag1 = _b[ 0bL.Hospitalizado#c.Hospitalizado]	
sca p_value_lag1 = 2*ttail(e(df_r),abs(_b[0bL.Hospitalizado#c.Hospitalizado]/_se[0bL.Hospitalizado#c.Hospitalizado]))
sca b_lag2 = _b[ 1L.Hospitalizado#c.Hospitalizado]	
sca p_value_lag2 = 2*ttail(e(df_r),abs(_b[1L.Hospitalizado#c.Hospitalizado]/_se[1L.Hospitalizado#c.Hospitalizado]))

quietly  reghdfe multid_poor_`i' i.L.multid_poor_`i'#c.Hospitalizado L.multid_poor_`i' $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_pobre1 = _b[ 0bL.multid_poor_`i'#c.Hospitalizado]	
sca p_value_pobre1 = 2*ttail(e(df_r),abs(_b[0bL.multid_poor_`i'#c.Hospitalizado]/_se[0bL.multid_poor_`i'#c.Hospitalizado]))
sca b_pobre2 = _b[ 1L.multid_poor_`i'#c.Hospitalizado]	
sca p_value_pobre2 = 2*ttail(e(df_r),abs(_b[1L.multid_poor_`i'#c.Hospitalizado]/_se[1L..multid_poor_`i'#c.Hospitalizado]))

quietly  reghdfe multid_poor_`i' Hospitalizado salud choque_desempleo choque_accidente choque_muerte, absorb(HHID Year)  vce(cluster HHID)
sca b_salud = _b[salud]	
sca p_value_salud = 2*ttail(e(df_r),abs(_b[salud]/_se[salud]))
sca b_accidente = _b[choque_accidente]	
sca p_value_accidente = 2*ttail(e(df_r),abs(_b[choque_accidente]/_se[choque_accidente]))
sca b_muerte = _b[choque_muerte]	
sca p_value_muerte = 2*ttail(e(df_r),abs(_b[choque_accidente]/_se[choque_accidente]))
sca b_desempleo = _b[choque_desempleo]	
sca p_value_desempleo = 2*ttail(e(df_r),abs(_b[choque_desempleo]/_se[choque_desempleo]))

mat results_`i'=nullmat(results)\ [b_hospi1, p_value_hospi1, b_quarter1, p_value_quarter1, b_quarter2, p_value_quarter2, b_quarter3, p_value_quarter3, b_quarter4, p_value_quarter4, b_urban1, p_value_urban1, b_urban2, p_value_urban2, b_lag1, p_value_lag1, b_lag2, p_value_lag2, b_pobre1, p_value_pobre1, b_pobre2, p_value_pobre2, b_salud, p_value_salud, b_accidente, p_value_accidente, b_muerte, p_value_muerte, b_desempleo, p_value_desempleo] // Guarda en una matrix los resultados de la regresion
}
svmat results_10
svmat results_20
svmat results_30
svmat results_40
svmat results_50
svmat results_60

keep results_*
keep in 1

gen HHID=1
reshape long results_10 results_20 results_30 results_40 results_50 results_60, i(HHID) j(Independientes)
export excel using "$workingfolder_out\Regresiones reghdfe\Resultados_Hospi.xls", firstrow(variables) replace
restore

/////////////////////////////Reporte Enfermos///////////////////////////////
preserve
forval i=10(10)60 {
quietly reghdfe multid_poor_`i' Enfermo_trabajo $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_illwork1 = _b[Enfermo_trabajo]
sca p_value_illwork1 = 2*ttail(e(df_r),abs(_b[Enfermo_trabajo]/_se[Enfermo_trabajo]))
 
quietly reghdfe multid_poor_`i' c.Enfermo_trabajo#i.L.quart $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_quarter1 = _b[1bL.quart#c.Enfermo_trabajo]
sca p_value_quarter1 = 2*ttail(e(df_r),abs(_b[1bL.quart#c.Enfermo_trabajo]/_se[1bL.quart#c.Enfermo_trabajo]))
sca b_quarter2 = _b[2L.quart#c.Enfermo_trabajo]
sca p_value_quarter2 = 2*ttail(e(df_r),abs(_b[2L.quart#c.Enfermo_trabajo]/_se[2L.quart#c.Enfermo_trabajo]))
sca b_quarter3 = _b[3L.quart#c.Enfermo_trabajo]
sca p_value_quarter3 = 2*ttail(e(df_r),abs(_b[3L.quart#c.Enfermo_trabajo]/_se[3L.quart#c.Enfermo_trabajo]))
sca b_quarter4 = _b[4L.quart#c.Enfermo_trabajo]
sca p_value_quarter4 = 2*ttail(e(df_r),abs(_b[4L.quart#c.Enfermo_trabajo]/_se[4L.quart#c.Enfermo_trabajo]))

quietly reghdfe multid_poor_`i' c.Enfermo_trabajo#i.reside $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_urban1 = _b[1b.reside#c.Enfermo_trabajo]
sca p_value_urban1 = 2*ttail(e(df_r),abs(_b[1b.reside#c.Enfermo_trabajo]/_se[1b.reside#c.Enfermo_trabajo]))
sca b_urban2 = _b[2.reside#c.Enfermo_trabajo]
sca p_value_urban2 = 2*ttail(e(df_r),abs(_b[2.reside#c.Enfermo_trabajo]/_se[2.reside#c.Enfermo_trabajo]))

quietly  reghdfe multid_poor_`i' c.Enfermo_trabajo#i.L.Enfermo_trabajo  L.Enfermo_trabajo $controles, absorb(HHID Year)  vce(cluster HHID) 
sca b_lag1 = _b[ 0bL.Enfermo_trabajo#c.Enfermo_trabajo]	
sca p_value_lag1 = 2*ttail(e(df_r),abs(_b[0bL.Enfermo_trabajo#c.Enfermo_trabajo]/_se[0bL.Enfermo_trabajo#c.Enfermo_trabajo]))
sca b_lag2 = _b[ 1L.Enfermo_trabajo#c.Enfermo_trabajo]	
sca p_value_lag2 = 2*ttail(e(df_r),abs(_b[1L.Enfermo_trabajo#c.Enfermo_trabajo]/_se[1L.Enfermo_trabajo#c.Enfermo_trabajo]))

quietly  reghdfe multid_poor_`i' i.L.multid_poor_`i'#c.Enfermo_trabajo L.multid_poor_`i' $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_pobre1 = _b[ 0bL.multid_poor_`i'#c.Enfermo_trabajo]	
sca p_value_pobre1 = 2*ttail(e(df_r),abs(_b[0bL.multid_poor_`i'#c.Enfermo_trabajo]/_se[0bL.multid_poor_`i'#c.Enfermo_trabajo]))
sca b_pobre2 = _b[ 1L.multid_poor_`i'#c.Enfermo_trabajo]	
sca p_value_pobre2 = 2*ttail(e(df_r),abs(_b[1L.multid_poor_`i'#c.Enfermo_trabajo]/_se[1L..multid_poor_`i'#c.Enfermo_trabajo]))

quietly  reghdfe multid_poor_`i' Enfermo_trabajo p_salud choque_desempleo choque_accidente choque_muerte, absorb(HHID Year)  vce(cluster HHID)
sca b_salud = _b[salud]	
sca p_value_salud = 2*ttail(e(df_r),abs(_b[salud]/_se[salud]))
sca b_accidente = _b[choque_accidente]	
sca p_value_accidente = 2*ttail(e(df_r),abs(_b[choque_accidente]/_se[choque_accidente]))
sca b_muerte = _b[choque_muerte]	
sca p_value_muerte = 2*ttail(e(df_r),abs(_b[choque_accidente]/_se[choque_accidente]))
sca b_desempleo = _b[choque_desempleo]	
sca p_value_desempleo = 2*ttail(e(df_r),abs(_b[choque_desempleo]/_se[choque_desempleo]))

mat results_`i'=nullmat(results)\ [b_illwork1, p_value_illwork1, b_quarter1, p_value_quarter1, b_quarter2, p_value_quarter2, b_quarter3, p_value_quarter3, b_quarter4, p_value_quarter4, b_urban1, p_value_urban1, b_urban2, p_value_urban2, b_lag1, p_value_lag1, b_lag2, p_value_lag2, b_pobre1, p_value_pobre1, b_pobre2, p_value_pobre2, b_salud, p_value_salud, b_accidente, p_value_accidente, b_muerte, p_value_muerte, b_desempleo, p_value_desempleo] // Guarda en una matrix los resultados de la regresion
}
svmat results_10
svmat results_20
svmat results_30
svmat results_40
svmat results_50
svmat results_60

keep results_*
keep in 1

gen HHID=1
reshape long results_10 results_20 results_30 results_40 results_50 results_60, i(HHID) j(Independientes)
export excel using "$workingfolder_out\Regresiones reghdfe\Resultados_illwork.xls", firstrow(variables) replace
restore

/////////////////////////////////////////////////////////////////////////Hospitalizacion indicadores////////////////////////////////////////////////////////////
restore
preserve
global indicators hh_d_water hh_d_toilet hh_access hh_d_school hh_attend hh_rezago hh_desempl hh_childlab  hh_hacin hh_materials hh_d_assets hh_electricity  

foreach var in $indicators   {
quietly  reghdfe `var' Hospitalizado  $controles, absorb(HHID Year)  vce(cluster HHID)
sca b_yas_`i' = _b[Hospitalizado]
sca p_value_`i' = 2*ttail(e(df_r),abs(_b[gc_`i']/_se[gc_`i']))
mat results_`var'_`i'=nullmat(results_`var')\ [b_yas_`i', p_value_`i'] // Guarda en una matrix los resultados de la regresion
}
forval  i=10(10)60 {
   svmat results_`var'_`i'
cap mat drop results_`var'_`i'
}

//mat results_`i'=nullmat(results)\ [`i', b_hh_d_water_, p_value_hh_d_water_, b_hh_d_toilet_, p_value_hh_d_toilet_, b_hh_access_, p_value_hh_access_,  b_hh_d_school_, p_value_hh_d_school_, b_hh_attend_, p_value_hh_attend_, b_hh_rezago_, p_value_hh_rezago_,  b_hh_desempl_, p_value_hh_desempl_,  b_hh_childlab_, p_value_hh_childlab_,  b_hh_hacin_, p_value_hh_hacin_, b_hh_materials_, p_value_hh_materials_,  b_hh_d_assets_, p_value_hh_d_assets_, b_hh_electricity_, p_value_hh_electricity_] // Guarda en una matrix los resultados de la regresion

keep results_*
keep in 1

gen HHID=1
reshape long results_hh_d_water_ results_hh_d_toilet_ results_hh_access_ results_hh_d_school_ results_hh_attend_ results_hh_rezago_ results_hh_desempl_  results_hh_childlab_	 results_hh_hacin_ results_hh_materials_ results_hh_d_assets_ results_hh_electricity_, i(HHID) j(Independientes)

export excel using "$workingfolder_out\Regresiones reghdfe\Resultados_Indicadores.xls", firstrow(variables) replace





















