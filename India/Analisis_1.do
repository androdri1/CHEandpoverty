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

* URBAN4o/Rural 
gen URBAN4o=URBAN4==0
gen rural=URBAN4==1


gen p_salud=gsalud/gtotal
replace p_salud=0 if missing(p_salud)
gen catastrofico_percent_sd=p_salud /0.16 // Se usa un único estándar para todos los países

* Defino los controles
global controles "edad_jefehogar hhninos i.quart hhadulmayor ED6 "	


*** Balancear los hogares del panel

bys IDHH: egen id_balanceado=sum(_N)
drop if id_balanceado==1

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
bys SURVEY: fsum $covs  if RO4==1


*** Dummy de los hogares que residen en el Sur de India
gen south=(STATEID==28|STATEID==29|STATEID==32|STATEID==33) if SURVEY==1
replace south=(STATEID2==728|STATEID2==729|STATEID2==732|STATEID2==733) if SURVEY==2

*===============================================================================*
*									XTTRANS								   		*
*===============================================================================*

* Indicadores 

global indicators  hh_attend hh_d_school hh_rezago hh_electricity hh_cooking hh_materials hh_d_assets hh_d_water hh_d_sanitation hh_insurance hh_diversityjob hh_land hh_livestock 

* Nota [20210517 GC]: Construyo los tex para mirar los cambios de las variables 
*                     a través del panel. Con un K=40% para India. 

local k=40
foreach var in $indicators   {
	xttrans2 `var' if hh_id_cambio_`k'!=2
	matrix table_`var' = r(table)
    outtable  using "$workingfolder_in/Regresion/results/`var'",mat(table_`var') replace 
}


*===============================================================================*
*									REGRESIONES							   		*
*===============================================================================*

* Nota [20210517 GC]: Construyo las tablas de las estimaciones del Gasto Catastrofico. 

* Regresion 1

lab var south "Sur de India"
forval k=10(10)40{
	preserve
	keep if RO4==1

	forval  i=10(10)60 {
		lab var catastrofico`k'  "Gastos catastróficos en salud al `k'\%"
		lab var multid_poor_`i'  "K=`i'\%"

		reghdfe multid_poor_`i' catastrofico`k' south if hh_id_cambio_`i'!=2,  absorb(  SURVEY IDHH) vce(cluster  STATEID)

		eststo m`i'_si, title("K=`i'\%")
				estadd local IDHH 	"$\checkmark$"
				estadd local SURVEY "$\checkmark$"
				local sing: di %15.0fc `sing'

			
		lab var multid_poor_`i'  "K=`i'%"
	}

	esttab m* using "${results}/rsouth`k'.tex", 			///
		   replace  label								///
		   drop(_cons)			///
		   mlabels(,titles)			///
		   starlevels(* 0.10 ** 0.05 *** 0.01) 										///
		   stats(IDHH SURVEY N, 	///
		   labels("Houselhold's FE" "Time's FE" "Observations" 					///
				  )	fmt(%15.0fc)) 													///
				b(3) se(3)  ///
			   title("Resultados del gasto catastrofico en salud con un K=`k'\%`'"\label{rsouth`k'})	   
	restore 

}

* Regresion 2

lab var south "Sur de India [1=Sí]"
forval k=10(10)40{
	preserve
	keep if RO4==1

	forval  i=10(10)60 {
		lab var catastrofico`k'  "GC al `k'\%"
lab var multid_poor_`i'  "K=`i'\%"

reghdfe multid_poor_`i' c.catastrofico`k'##c.south if hh_id_cambio_`i'!=2,  absorb(  SURVEY IDHH) vce(cluster  STATEID)

eststo m`i'_si, title("K=`i'\%")
		estadd local IDHH 	"$\checkmark$"
		estadd local SURVEY "$\checkmark$"
		local sing: di %15.0fc `sing'

	
lab var multid_poor_`i'  "K=`i'%"


}

esttab m* using "${results}/rsouth`k'_interaccion.tex", 			///
	   replace  label								///
	   keep(catastrofico`k' south c.catastrofico`k'#c.south)			///
	   mlabels(,titles)			///
	   starlevels(* 0.10 ** 0.05 *** 0.01) 										///
	   stats(IDHH SURVEY N, 	///
	   labels("Houselhold's FE" "Time's FE" "Observations" 					///
			  )	fmt(%15.0fc)) 													///
	   	    b(3) se(3)  ///
		   title("Resultados del gasto catastrofico en salud con un K=`k'\%`'"\label{rsouth`k'}) 
		   
restore 

}

gen gc_sd=catastrofico_percent/0.16


 
 *===============================================================================*
*			       TABLA 4  	/ TABLA A5 si es NoBalanceado					*
*===============================================================================*

cap mat drop results

* 1) Es la regresion base cross-section
reghdfe multid_poor_40 catastrofico40 $controles rural ,  absorb(  SURVEY) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [1,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 2) Es la regresion base longitudinal
reghdfe multid_poor_40 catastrofico40 $controles,  absorb(  IDHH SURVEY) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [2,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 3) Es la regresion de los quartes 
reghdfe multid_poor_40 c.catastrofico40#i.quart i.quart $controles,  absorb(  IDHH SURVEY) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.quart#catastrofico40]/_se[1b.quart#catastrofico40]))
	mat results=nullmat(results)\ [31,_b[1b.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.quart#catastrofico40]/_se[2.quart#catastrofico40]))
	mat results=nullmat(results)\ [32,_b[2.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.quart#catastrofico40]/_se[3.quart#catastrofico40]))
	mat results=nullmat(results)\ [33,_b[3.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.quart#catastrofico40]/_se[4.quart#catastrofico40]))
	mat results=nullmat(results)\ [34,_b[4.quart#catastrofico40], p_value] 	
	
* 4) Es la regresion de rural y URBAN4o
reghdfe multid_poor_40 c.catastrofico40#i.URBAN4 i.URBAN4 $controles,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.URBAN4#catastrofico40]/_se[0b.URBAN4#catastrofico40]))
	mat results=nullmat(results)\ [41,_b[0b.URBAN4#catastrofico40], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.URBAN4#catastrofico40]/_se[1.URBAN4#catastrofico40]))
	mat results=nullmat(results)\ [42,_b[1.URBAN4#catastrofico40], p_value] // URBAN4
				
* 5) Es la regresion del rezago del gasto catastrofico40
reghdfe multid_poor_40 c.catastrofico40#i.catastrofico40_rezago i.catastrofico40_rezago $controles,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.catastrofico40_rezago#c.catastrofico40]/_se[0b.catastrofico40_rezago#catastrofico40]))
	mat results=nullmat(results)\ [51,_b[0b.catastrofico40_rezago#c.catastrofico40], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1.catastrofico40_rezago#c.catastrofico40]/_se[1.catastrofico40_rezago#catastrofico40]))
	mat results=nullmat(results)\ [52,_b[1.catastrofico40_rezago#c.catastrofico40], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_40 c.catastrofico40 $controles if pobreza40_rezago ==0,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [6,_b[catastrofico40], p_value] // Not poor
reghdfe multid_poor_40 c.catastrofico40 $controles if pobreza40_rezago ==1,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [7,_b[catastrofico40], p_value] // Poor

* 8) Disease Shock (Accident Shock in Malawi)
reghdfe multid_poor_40 c.hh_disease $controles,  absorb(  IDHH SURVEY) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[hh_disease]/_se[hh_disease]))
	mat results=nullmat(results)\ [8,_b[hh_disease], p_value] 

* 9) Death Shock. choque_muerte

	mat results=nullmat(results)\ [9,., .] 

* 10) Unemployment Shock. choque_desempleo

	mat results=nullmat(results)\ [10,., .] 

* 11) Share of healthcare expenditures divided by the mean SD
reghdfe multid_poor_40 c.catastrofico_percent_sd $controles,  absorb(  IDHH SURVEY) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd]))
	mat results=nullmat(results)\ [11,_b[catastrofico_percent_sd], p_value] 

	
sum p_salud 
mat results=nullmat(results)\ [12, r(sd), .] 
	
mat list results	
 

 
 
 
*===============================================================================*
*							       TABLA A3  (continuous)		  		   		*
*===============================================================================*
cap mat drop results

* 0) 

* 1) Es la regresion de los quartes 
reghdfe multid_poor_40 c.catastrofico_percent_sd#i.quart i.quart $controles rural,  absorb(  IDHH SURVEY) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.quart#catastrofico_percent_sd]/_se[1b.quart#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [31,_b[1b.quart#catastrofico_percent_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.quart#catastrofico_percent_sd]/_se[2.quart#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [32,_b[2.quart#catastrofico_percent_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.quart#catastrofico_percent_sd]/_se[3.quart#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [33,_b[3.quart#catastrofico_percent_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.quart#catastrofico_percent_sd]/_se[4.quart#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [34,_b[4.quart#catastrofico_percent_sd], p_value] 	
	
* 4) Es la regresion de rural y URBAN4o
reghdfe multid_poor_40 c.catastrofico_percent_sd#i.URBAN4 i.URBAN4 $controles,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.URBAN4#catastrofico_percent_sd]/_se[0b.URBAN4#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [41,_b[0b.URBAN4#catastrofico_percent_sd], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.URBAN4#catastrofico_percent_sd]/_se[1.URBAN4#catastrofico_percent_sd]))
	mat results=nullmat(results)\ [42,_b[1.URBAN4#catastrofico_percent_sd], p_value] // URBAN4
				
* 5) Es la regresion del rezago del gasto catastrofico40
reghdfe multid_poor_40 c.catastrofico_percent_sd#i.catastrofico40_rezago  i.catastrofico40_rezago  $controles,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.catastrofico40_rezago#catastrofico_percent_sd]/_se[0b.catastrofico40_rezago #catastrofico_percent_sd]))
	mat results=nullmat(results)\ [51,_b[0b.catastrofico40_rezago#catastrofico_percent_sd], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1.catastrofico40_rezago#catastrofico_percent_sd]/_se[1.catastrofico40_rezago #catastrofico_percent_sd]))
	mat results=nullmat(results)\ [52,_b[1.catastrofico40_rezago #catastrofico_percent_sd], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_40 c.catastrofico_percent_sd $controles if pobreza40_rezago ==0,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd]))
	mat results=nullmat(results)\ [6,_b[catastrofico_percent_sd], p_value] // Not poor
reghdfe multid_poor_40 c.catastrofico_percent_sd $controles if pobreza40_rezago ==1,  absorb(  IDHH SURVEY ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd]))
	mat results=nullmat(results)\ [7,_b[catastrofico_percent_sd], p_value] // Poor
	
	
mat list results	

 
 
 
*===============================================================================*
*							       TABLA A4  (logit)		  		   		*
*===============================================================================*
cap mat drop results

* 1) Es la regresion base cross-section
logit multid_poor_40 catastrofico40 $controles   i.SURVEY
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [1,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 2) Es la regresion base longitudinal
xtlogit multid_poor_40 catastrofico40 $controles i.SURVEY, fe 
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [2,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 3) Es la regresion de los quartes 
xtlogit multid_poor_40 c.catastrofico40#i.quart i.quart $controles i.SURVEY, fe 
margins, dydx(catastrofico40) at (quart=(1(1)4)) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [31,_b[catastrofico40:1._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [32,_b[catastrofico40:2._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:3._at]/_se[catastrofico40:3._at])))
	mat results=nullmat(results)\ [33,_b[catastrofico40:3._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:4._at]/_se[catastrofico40:4._at])))
	mat results=nullmat(results)\ [34,_b[catastrofico40:4._at], p_value] 	
	
* 4) Es la regresion de rural y URBAN4o
xtlogit multid_poor_40 c.catastrofico40#i.rural  $controles i.SURVEY, fe 
margins, dydx(catastrofico40) at (rural=(0(1)1)) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [41,_b[catastrofico40:1._at], p_value] // Rural
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [42,_b[catastrofico40:2._at], p_value] // URBAN4
				
* 5) Es la regresion del rezago del gasto catastrofico40
xtlogit multid_poor_40 c.catastrofico40#i.catastrofico40_rezago   $controles i.SURVEY, fe  
margins, dydx(catastrofico40) at (catastrofico40_rezago =(0(1)1)) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [51,_b[catastrofico40:1._at], p_value] // CHP No
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [52,_b[catastrofico40:2._at], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
xtlogit multid_poor_40 c.catastrofico40 $controles i.SURVEY if pobreza40_rezago ==0 , re  
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [6,_b[catastrofico40], p_value] // Not poor
xtlogit multid_poor_40 c.catastrofico40 $controles i.SURVEY if pobreza40_rezago ==1 , re 
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [7,_b[catastrofico40], p_value] // Poor

* 8) Disease Shock (Accident Shock in Malawi)
xtlogit multid_poor_40 c.hh_disease $controles i.SURVEY, fe 
margins, dydx(hh_disease) post
	sca p_value = 2*(1-normal(abs(_b[hh_disease]/_se[hh_disease])))
	mat results=nullmat(results)\ [8,_b[hh_disease], p_value] 

* 9) Death Shock. choque_muerte

	mat results=nullmat(results)\ [9,., .] 

* 10) Unemployment Shock. choque_desempleo

	mat results=nullmat(results)\ [10,., .] 

* 11) Share of healthcare expenditures divided by the mean SD
xtlogit multid_poor_40 c.catastrofico_percent_sd $controles i.SURVEY, fe 
margins, dydx(catastrofico_percent_sd) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico_percent_sd]/_se[catastrofico_percent_sd])))
	mat results=nullmat(results)\ [11,_b[catastrofico_percent_sd], p_value] 

mat list results	

 
 
 
 













































*===============================================================================*
*								GASTOS DEL HOGAR						   		*
*===============================================================================*

** Defino la distribución de la encuesta.

svyset PSUID, strata(STATEID) weight(el_peso) vce(linearized) singleunit(certainty)

** Tabla 1: Esta tabla va a contener los gastos de vivienda, escolares, alimentos,
**			salud, otros (los gastos que se encuentra por fuera de la canasta familiar)
**			y total. Además, se realiza la desagregación por el gasto catastrofico y 
** 			se analiza si sus diferencias de medias son estadisticamente significativa. 
**			Los resultados equivalen para los hogares de la ola 1 (2005).

local i=40


	preserve
keep if SURVEY==1 & hh_id_cambio_`i'!=2
	mat balance=J(6,10,.)
	mat significancia=J(6,10,0)

global covs " gvivienda gotros gescolar gsalud  galimentos gtotal"
	
	tokenize ${covs}
	forvalues j=1(1)6{

        svy: mean ``j''
		estat sd
        matrix balance[`j',1]=r(mean)
		matrix balance[`j',2]=r(sd)
		svy: mean ``j'', over(catastrofico40) 
		estat sd
		matrix balance [`j',3]=r(mean)[1,2] 
		matrix balance [`j',4]=r(sd)[1,2]
		matrix balance [`j',5]=r(mean)[1,1] 
		matrix balance [`j',6]= r(sd)[1,1]
		svy: mean ``j'', over(catastrofico40) 
		lincom  _b[c.``j''@1.catastrofico40] - _b[c.``j''@0bn.catastrofico40]
        matrix balance[`j',7]=r(estimate)
		matrix balance[`j',8]= r(se)
		matrix balance[`j',9]=r(p) 
		matrix significancia[`j',7]=(r(p)<0.1)+(r(p)<0.05)+(r(p)<0.01)

		matlist balance
		matlist significancia
	}

frmttable using "${results}/cambios_tabla1.tex", replace sdec(2)				/// 
		statmat(balance) substat(1) annotate(significancia) asymbol(*,**,***)	///										///
		ctitles("", "Muestra completa", "GC: Sí", "GC: No", "Diferencia",	///
			"p-valor")									///
		rtitles("Gastos de vivienda"\ "" \"Gastos otros"\ "" \ "Gastos escolares" \ "" \ "Gastos de salud"	///
	        \ "" \ "Gastos de alimentación"\""\"Gasto total")	tex fragment

restore	


** Tabla 2: Esta tabla va a contener los gastos de vivienda, escolares, alimentos,
**			salud, otros (los gastos que se encuentra por fuera de la canasta familiar)
**			y total. Además, se realiza la desagregación por el gasto catastrofico y 
** 			se analiza si sus diferencias de medias son estadisticamente significativa. 
**			Los resultados equivalen para los hogares de la ola 2 (2011).


local i=40
	preserve
keep if SURVEY==2 &hh_id_cambio_`i'!=2
	mat balance=J(6,10,.)
	mat significancia=J(6,10,0)

global covs " gvivienda gotros gescolar gsalud  galimentos gtotal"
	
	tokenize ${covs}
	forvalues j=1(1)6{

        svy: mean ``j''
		estat sd
        matrix balance[`j',1]=r(mean)
		matrix balance[`j',2]=r(sd)
		svy: mean ``j'', over(catastrofico40) 
		estat sd
		matrix balance [`j',3]=r(mean)[1,2] 
		matrix balance [`j',4]=r(sd)[1,2]
		matrix balance [`j',5]=r(mean)[1,1]
		matrix balance [`j',6]= r(sd)[1,1]
		svy: mean ``j'', over(catastrofico40) 
		lincom  _b[c.``j''@1.catastrofico40] - _b[c.``j''@0bn.catastrofico40]
        matrix balance[`j',7]=r(estimate)
		matrix balance[`j',8]= r(se)
		matrix balance[`j',9]=r(p) 
		matrix significancia[`j',7]=(r(p)<0.1)+(r(p)<0.05)+(r(p)<0.01)

		matlist balance
		matlist significancia
	}

frmttable using "${results}/cambios_tabla2.tex", replace sdec(2)				/// 
		statmat(balance) substat(1) annotate(significancia) asymbol(*,**,***)	///										///
		ctitles("", "Muestra completa", "GC: Sí", "GC: No", "Diferencia",	///
			"p-valor")									///
		rtitles("Gastos de vivienda"\ "" \"Gastos otros"\ "" \ "Gastos escolares" \ "" \ "Gastos de salud"	///
	        \ "" \ "Gastos de alimentación"\""\"Gasto total")	tex fragment

restore	


** Tabla 3: Esta tabla va a contener la proporción de la desagregación del gasto de 
** 			salud. Además, se realiza la desagregación por el gasto catastrofico y 
** 			se analiza si sus diferencias de medias son estadisticamente significativa. 
**			Los resultados equivalen para los hogares de la ola 1 (2005).

local i=40
preserve
keep if SURVEY==1& hh_id_cambio_`i'!=2


gen out_patient_percent=(CO33/(gsalud))*100
gen in_patient_percent=(CO34/(gsalud))*100
gen therapeutic_percent=(CO46/(gsalud))*100


	mat balance=J(3,10,.)
	mat significancia=J(3,10,0)

global covs "out_patient_percent in_patient_percent therapeutic_percent"
	
	tokenize ${covs}
	forvalues j=1(1)3{

        svy: mean ``j''
		estat sd
        matrix balance[`j',1]=r(mean)
		matrix balance[`j',2]=r(sd)
		svy: mean ``j'', over(catastrofico40) 
		estat sd
		matrix balance [`j',3]=r(mean)[1,2] 
		matrix balance [`j',4]=r(sd)[1,2]
		matrix balance [`j',5]=r(mean)[1,1] 
		matrix balance [`j',6]= r(sd)[1,1]
		svy: mean ``j'', over(catastrofico40) 
		lincom  _b[c.``j''@1.catastrofico40] - _b[c.``j''@0bn.catastrofico40]
        matrix balance[`j',7]=r(estimate)
		matrix balance[`j',8]= r(se)
		matrix balance[`j',9]=r(p) 
		matrix significancia[`j',7]=(r(p)<0.1)+(r(p)<0.05)+(r(p)<0.01)

		matlist balance
		matlist significancia
	}

frmttable using "${results}/cambios_perc_salud_1.tex", replace sdec(3)				/// 
		statmat(balance) substat(1) annotate(significancia) asymbol(*,**,***)	///										///
		ctitles("", "Muestra completa", "GC: Sí", "GC: No", "Diferencia",	///
			"p-valor")									///
		rtitles(" (\%) Medical out-patient"\ "" \"(\%) Medical in-patient"\ "" \ "(\%) Therapeutic app")	tex fragment

restore	


** Tabla 4: Esta tabla va a contener la proporción de la desagregación del gasto de 
** 			salud. Además, se realiza la desagregación por el gasto catastrofico y 
** 			se analiza si sus diferencias de medias son estadisticamente significativa. 
**			Los resultados equivalen para los hogares de la ola 2 (2011).

local i=40
preserve
keep if SURVEY==2& hh_id_cambio_`i'!=2


gen out_patient_percent=(CO33/(gsalud))*100
gen in_patient_percent=(CO34/(gsalud))*100
gen therapeutic_percent=(CO46/(gsalud))*100


	mat balance=J(3,10,.)
	mat significancia=J(3,10,0)

global covs "out_patient_percent in_patient_percent therapeutic_percent"
	
	tokenize ${covs}
	forvalues j=1(1)3{

        svy: mean ``j''
		estat sd
        matrix balance[`j',1]=r(mean)
		matrix balance[`j',2]=r(sd)
		svy: mean ``j'', over(catastrofico40) 
		estat sd
		matrix balance [`j',3]=r(mean)[1,2] 
		matrix balance [`j',4]=r(sd)[1,2]
		matrix balance [`j',5]=r(mean)[1,1] 
		matrix balance [`j',6]= r(sd)[1,1]
		svy: mean ``j'', over(catastrofico40) 
		lincom  _b[c.``j''@1.catastrofico40] - _b[c.``j''@0bn.catastrofico40]
        matrix balance[`j',7]=r(estimate)
		matrix balance[`j',8]= r(se)
		matrix balance[`j',9]=r(p) 
		matrix significancia[`j',7]=(r(p)<0.1)+(r(p)<0.05)+(r(p)<0.01)

		matlist balance
		matlist significancia
	}

frmttable using "${results}/cambios_perc_salud_2.tex", replace sdec(3)				/// 
		statmat(balance) substat(1) annotate(significancia) asymbol(*,**,***)	///										///
		ctitles("", "Muestra completa", "GC: Sí", "GC: No", "Diferencia",	///
			"p-valor")									///
		rtitles(" (\%) Medical out-patient"\ "" \"(\%) Medical in-patient"\ "" \ "(\%) Therapeutic app")	tex fragment

restore	

** Tabla 5: Esta tabla va a contener las estadisticas descriptivas de los 
**			hogares con cambios en el estado de la pobreza. 


local i=40


preserve
keep if SURVEY==1&  hh_id_cambio_`i'!=2
	mat balance=J(6,10,.)
	mat significancia=J(6,10,0)

global covs "edad_jefehogar hhsize hhninos hhadulmayor ED6 URBAN4"
	
	tokenize ${covs}
	forvalues j=1(1)6{

        svy: mean ``j''
		estat sd
        matrix balance[`j',1]=r(mean)
		matrix balance[`j',2]=r(sd)
		svy: mean ``j'', over(catastrofico40) 
		estat sd
		matrix balance [`j',3]=r(mean)[1,2] // tratados
		matrix balance [`j',4]=r(sd)[1,2]
		matrix balance [`j',5]=r(mean)[1,1] // no tratados
		matrix balance [`j',6]=r(sd)[1,1]
		svy: mean ``j'', over(catastrofico40) 
		lincom  _b[c.``j''@1.catastrofico40] - _b[c.``j''@0bn.catastrofico40]
        matrix balance[`j',7]=r(estimate)
		matrix balance[`j',8]=r(se)
		matrix balance[`j',9]=r(p) 
		matrix significancia[`j',7]=(r(p)<0.1)+(r(p)<0.05)+(r(p)<0.01)

		matlist balance
		matlist significancia
	}

frmttable using "${results}/descriptiva_1.tex", replace sdec(2)				/// 
		statmat(balance) substat(1) annotate(significancia) asymbol(*,**,***)	///										///
		ctitles("", "Muestra completa", "GC: Sí", "GC: No", "Diferencia",	///
			"p-valor")									///
		rtitles("Edad jefe del hogar"\ "" \"Tamaño del hogar"\ "" \ "Número de niños por hogar" \ "" \ "Número de adultos mayores por hogar"	///
	        \ "" \ "Años de escolaridad del jefe del hogar"\ "" \ "URBAN4o")	tex fragment

restore
