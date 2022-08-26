****************************************************************
* resultados.do realiza la primera versión de regresiones de India 
* ODS project
*
* Date Created: 20210517
* Name Created: GC
* Last modified: 
*
* Notas:
*  1. 
***************************************************************
clear
clear matrix
clear mata
set more off
set maxvar 10000
set mem 500m
cap log close
pause off

global workingfolder_in "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/India/Code"


use "$workingfolder_in/IPM/data/IPMbalanceado.dta",replace
keep if RO4==1
destring IDHH, replace        

bys IDHH: egen id_balanceado=sum(_N)
drop if id_balanceado==1
xtset , clear
xtset IDHH SURVEY,format(%tg)



*______________________*
*                      *
*     Regresion        *
*______________________*


* Enfermerdad *

egen disease=anycount(MB3 MB4 MB5 MB6 MB7 MB8 MB9 MB10 MB11 MB12 MB13 MB14 MB15), values(2)

gen cataract=(MB3==2)

global covar "MB3 MB4 MB5 MB6 MB7 MB8 MB9 MB10 MB11 MB12 MB13 MB14 MB15"

/*
MB3             int     %7.0f      MB3        EQ14 9.3 Cataract
MB4             int     %7.0f      MB4        EQ14 9.4 Tuberculosis
MB5             int     %7.0f      MB5        EQ14 9.5 High BP
MB6             int     %7.0f      MB6        EQ14 9.6 Heart disease
MB7             int     %7.0f      MB7        EQ14 9.7 Diabetes
MB8             int     %7.0f      MB8        EQ14 9.8 Leprosy
MB9             int     %7.0f      MB9        EQ14 9.9 Cancer
MB10            int     %7.0f      MB10       EQ14 9.10 Asthma
MB11            int     %7.0f      MB11       EQ14 9.11 Polio
MB12            int     %7.0f      MB12       EQ14 9.12 Paralysis
MB13            int     %7.0f      MB13       EQ14 9.13 Epilepsy
MB14            int     %7.0f      MB14       EQ14 9.14 Mental illness
MB15            int     %7.0f      MB15       EQ14 9.15 STD or AIDS
*/


foreach var in $covar {
	gen NB_`var'=(`var'==2)
}

replace disease=1 if disease>0

bys HHBASE SURVEY: egen hh_disease=max(disease)

* Muerte *

replace FH4C = FH4CM if SURVEY==1

gen death=(FH4C==0)
bys HHBASE SURVEY: egen hh_death=max(death)


/*
Pesos
*/

* el_peso  Peso de la encuesta


/*
Construir los cuartiles de gastos
*/


bys SURVEY: egen quart= xtile(gtotal), n(4)


/*
Definir los controles
*/


replace catastrofico10=0 if missing(catastrofico10)
replace catastrofico20=0 if missing(catastrofico20)
replace catastrofico30=0 if missing(catastrofico30)
replace catastrofico40=0 if missing(catastrofico40)
 
gen catastrofico_percent=gsalud/(gtotal-galimentos)
replace catastrofico_percent=0 if missing(catastrofico_percent)



*===============================================================================*
*								Estimaciones del GC						   		*
*===============================================================================*


*______________________*
*                      *
*     Catastroficos    *
*______________________*


*** Tabla 1: Gastos catastofricos a nivel panel

global results "$workingfolder_in/Regresion/results"



destring IDHH, replace        
 xtset HHBASE SURVEY,format(%tg)
 sum catastrofico_percent
 replace catastrofico_percent=catastrofico_percent/r(sd)
replace catastrofico_percent=0 if missing(catastrofico_percent)




forval  i=10(10)40 {
 preserve
 estimates clear 	
lab var catastrofico`i'  "`i'%"	

 forval k=10(10)60{
lab var multid_poor_`k'  "K=`k'%"
reghdfe multid_poor_`k' catastrofico`i',  absorb(IDHH  SURVEY) vce(cluster  STATEID)
eststo m`k', title("K=`k'\%")
		estadd local IDHH 	"$\checkmark$"
		estadd local SURVEY "$\checkmark$"
		local sing: di %15.0fc `sing'
}
		
esttab m* using "${results}/regresion_catastrofico_`i'.tex", 			///
	   replace label															///
	   drop(_cons)			///
	   mlabels(,titles)															///
	   starlevels(* 0.10 ** 0.05 *** 0.01) 										///
	   stats(IDHH SURVEY N, 	///
	   labels("Houselhold's FE" "Time's FE" "Observations" 					///
			  )	fmt(%15.0fc)) 													///
	   	   booktabs  b(3) se(3)  ///
		   title("Resultados del gasto catastrófico en salud al `i'\%`'"\label{tab:pobrezacatastrofico`i'})  ///
		   rename(catastrofico`i' CE `i'%)
		   
restore 

}









*______________________*
*                      *
*     Cuartiles        *
*______________________*




forval k=10(10)40{
lab var catastrofico`k'  "Gastos catastróficos en salud al `k'%"

local i=10

lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.quart,  absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_cuartiles_`k'",tex replace  nocons label addtex( FE Región,Sí, EF Año, Sí)  bdec(3) sdec(3)

forval  i=20(10)60 {
	
lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.quart,  absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_cuartiles_`k'", tex append  nocons label addtex(FE Región,Sí, EF Año, Sí)  bdec(3) sdec(3)

}
}


*______________________*
*                      *
*     rural/urbano     *
*______________________*

forval k=10(10)40{
lab var catastrofico`k'  "Gastos catastróficos en salud al `k'%"

local i=10

lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.URBAN4,  absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_zona_`k'",tex replace  nocons label addtex( EF Región,Sí, EF Año, Sí)  bdec(3) sdec(3)

forval  i=20(10)60 {
	
lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.URBAN4,  absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_zona_`k'", tex append  nocons label addtex(EF Región,Sí, EF Año, Sí)  bdec(3) sdec(3)

}
}


/*
Por indicador y GC
*/

global indicators  hh_attend hh_d_school hh_rezago hh_electricity hh_cooking hh_materials hh_d_assets hh_d_water hh_d_sanitation hh_insurance hh_diversityjob hh_land hh_livestock
	
lab var  hh_livestock "hh_livestock"
lab var  hh_land "hh_land"
lab var  hh_d_sanitation "hh_d_sanitation"
foreach var in $indicators   {
local i=10

reghdfe `var' catastrofico`i',  absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_`var'",tex replace  nocons label addtex( FE Región,Sí, EF Hogar, Sí) 

forval  i=20(10)40 {

reghdfe `var' catastrofico`i',  absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_`var'", tex append  nocons label addtex(FE Región,Sí, EF Hogar, Sí) 

}
}


/*
Por indicador censusaradas y GC
*/

global indicators  hh_attend hh_d_school hh_rezago hh_electricity hh_cooking hh_materials hh_d_assets hh_d_water hh_d_sanitation hh_insurance hh_diversityjob hh_land hh_livestock 
	
foreach var in $indicators   {
	
forval  i=10(10)40 {
local k=10
lab var catastrofico`i'  "Gastos catastróficos en salud al `i'%"
lab var g0_`k'_`var'  "K=`k'%"
reghdfe g0_`k'_`var' catastrofico`i', absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_g0_`i'_`var'",tex(fragment) replace  nocons label addtex( FE Región,Sí, EF Hogar, Sí) 

forval  k=20(10)60 {
lab var catastrofico`i'  "Gastos catastróficos en salud al `i'%"
lab var g0_`k'_`var'  "K=`k'%"
reghdfe g0_`k'_`var' catastrofico`i',  absorb(STATEID SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_g0_`i'_`var'", tex(fragment) append  nocons label addtex(FE Región,Sí, EF Hogar, Sí) 

}
}
}


*______________________*
*                      *
*     Interacciones    *
*______________________*

**** Cuartiles 

bys HHBASE : gen cuartil = quart[_n-1]
gsort HHBASE - SURVEY
bys HHBASE: carryforward cuartil, replace	

gsort HHBASE  SURVEY
bys HHBASE: carryforward cuartil, replace
replace cuartil=quart if cuartil==.

forval k=10(10)40{
lab var catastrofico`k'  "Gastos catastróficos en salud al `k'%"

local i=10

lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.cuartil,  absorb(STATEID  SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_cuartiles_`k'_interacion",tex replace  nocons label addtex( FE Región,Sí, EF Hogar, Sí)   bdec(3) sdec(3)

forval  i=20(10)60 {
	
lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.cuartil,  absorb(STATEID  SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_cuartiles_`k'_interacion", tex append  nocons label addtex(FE Región,Sí, EF Año, Sí)  bdec(3) sdec(3)

}
}

**** Rural/Urbano
bys HHBASE: gen Urban=URBAN4[_n-1]
gsort HHBASE - SURVEY
bys HHBASE: carryforward Urban, replace	
gsort HHBASE  SURVEY
bys HHBASE: carryforward Urban, replace
replace Urban=URBAN4 if Urban==.


forval k=10(10)40{
lab var catastrofico`k'  "Gastos catastróficos en salud al `k'%"

local i=10

lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.Urban,  absorb(STATEID  SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_zona_`k'_interacion",tex replace  nocons label addtex( FE Región,Sí, EF Hogar, Sí) 

forval  i=20(10)60 {
	
lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.Urban,  absorb(STATEID  SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_zona_`k'_interacion", tex append  nocons label addtex(FE Región,Sí, EF Hogar, Sí) 

}
}

*** Catastrofico 
 forval i=10(10)40{
 	bys HHBASE: gen catastrofico`i'_rezago=catastrofico`i'[_n-1]
gsort HHBASE - SURVEY
bys HHBASE: carryforward catastrofico`i'_rezago, replace	
gsort HHBASE  SURVEY
bys HHBASE: carryforward catastrofico`i'_rezago, replace
replace catastrofico`i'_rezago=catastrofico`i' if catastrofico`i'_rezago==.	
 }

 forval k=10(10)40{
lab var catastrofico`k'  "Gastos catastróficos en salud al `k'%"

local i=10

lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.catastrofico`k'_rezago,  absorb(STATEID  SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_catastrofico_`k'_interacion",tex replace  nocons label addtex( FE Región,Sí, EF Hogar, Sí) 

forval  i=20(10)60 {
	
lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' c.catastrofico`k'#i.catastrofico`k'_rezago,  absorb(STATEID  SURVEY) vce(cluster STATEID)

outreg2 using "${results}/regresion_catastrofico_`k'_interacion", tex append  nocons label addtex(FE Región,Sí, EF Hogar, Sí) 

}
}


*** Pobreza 
 forval i=10(10)60{
 	bys HHBASE: gen pobreza`i'_rezago=multid_poor_`i'[_n-1]
gsort HHBASE - SURVEY
bys HHBASE: carryforward pobreza`i'_rezago, replace	
gsort HHBASE  SURVEY
bys HHBASE: carryforward pobreza`i'_rezago, replace
replace pobreza`i'_rezago=multid_poor_`i' if pobreza`i'_rezago==.	
 }

 
	


 forval k=10(10)60{
 	preserve
 estimates clear 	
 local i=10	
lab var multid_poor_`k'  "K=`k'%"
lab var catastrofico`i'  "`i'%"	
gen catastrofico_si_`i'_`k'=catastrofico`i' if pobreza`k'_rezago==1
gen catastrofico_no_`i'_`k'=catastrofico`i' if pobreza`k'_rezago==0
lab var catastrofico_si_`i'_`k' "Sí: Pobreza [t-1] x GC `i'\%"
lab var catastrofico_no_`i'_`k' "No: Pobreza [t-1] x GC `i'\%"

reghdfe multid_poor_`k' c.catastrofico_si_`i'_`k',  absorb(IDHH SURVEY) vce(cluster STATEID)

eststo m`i'_si, title("K=`k'\%")
		estadd local IDHH 	"$\checkmark$"
		estadd local SURVEY "$\checkmark$"
		local sing: di %15.0fc `sing'

reghdfe multid_poor_`k' c.catastrofico_no_`i'_`k',  absorb(IDHH SURVEY) vce(cluster STATEID)

eststo m`i'_no, title("K=`k'\%")
		estadd local IDHH 	"$\checkmark$"
		estadd local SURVEY "$\checkmark$"
		local sing: di %15.0fc `sing'

forval  i=20(10)40 {
lab var catastrofico`i'  "`i'%"	
lab var multid_poor_`k'  "K=`k'%"
gen catastrofico_si_`i'_`k'=catastrofico`i' if pobreza`k'_rezago==1
gen catastrofico_no_`i'_`k'=catastrofico`i' if pobreza`k'_rezago==0
lab var catastrofico_si_`i'_`k' "Sí: Pobreza [t-1] x GC `i'\%"
lab var catastrofico_no_`i'_`k' "No: Pobreza [t-1] x GC `i'\%"

reghdfe multid_poor_`k' c.catastrofico_si_`i'_`k',  absorb(IDHH SURVEY) vce(cluster STATEID)

eststo m`i'_si, title("K=`k'\%")
		estadd local IDHH 	"$\checkmark$"
		estadd local SURVEY "$\checkmark$"
		local sing: di %15.0fc `sing'

reghdfe multid_poor_`k' c.catastrofico_no_`i'_`k',  absorb(IDHH SURVEY) vce(cluster STATEID)

eststo m`i'_no, title("K=`k'\%")
		estadd local IDHH 	"$\checkmark$"
		estadd local SURVEY "$\checkmark$"
		local sing: di %15.0fc `sing'

}

esttab m* using "${results}/regresion_pobreza_`k'_interacion.tex", 			///
	   replace  															///
	   drop(_cons)			///
	   mlabels(,titles)															///
	   starlevels(* 0.10 ** 0.05 *** 0.01) 										///
	   stats(IDHH SURVEY N, 	///
	   labels("Houselhold's FE" "Time's FE" "Observations" 					///
			  )	fmt(%15.0fc)) 													///
	   	    b(3) se(3)  ///
		   title("Resultados del gasto catastrofico con un K=`k'\%`'"\label{pobrezarezago`k'})	   
restore 

}

		



*______________________*
*                      *
*     Ola 2005         *
*______________________*

preserve 
forval k=10(10)40{
lab var catastrofico`k'  "Gastos catastróficos en salud al `k'%"
keep if SURVEY==1
local i=10

lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' catastrofico`k',  absorb(STATEID) vce(cluster STATEID)

outreg2 using "${results}/catastrofico_`k'",tex(fragment) replace keep(catastrofico`k') nocons label addtex( FE Región,Sí) 

forval  i=20(10)60 {
	
lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' catastrofico`k' , absorb(STATEID ) vce(cluster STATEID)

outreg2 using "${results}/catastrofico_`k'", tex(fragment) append keep(catastrofico`k') nocons label addtex(FE Región,Sí) 

}
}
restore


*______________________*
*                      *
*     Ola 2012         *
*______________________*


*** Catastroficos

preserve 
forval k=10(10)40{
lab var catastrofico`k'  "Gastos catastróficos en salud al `k'%"
keep if SURVEY==2
local i=10

lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' catastrofico`k', absorb(STATEID) vce(cluster STATEID)

outreg2 using "${results}/catastrofico_`k'_2011",tex(fragment) replace keep(catastrofico`k') nocons label addtex( FE Región,Sí) 

forval  i=20(10)60 {
	
lab var multid_poor_`i'  "K=`i'%"

reghdfe multid_poor_`i' catastrofico`k' , absorb(STATEID) vce(cluster STATEID)

outreg2 using "${results}/catastrofico_`k'_2011", tex(fragment) append keep(catastrofico`k') nocons label addtex(FE Región,Sí) 

}
}
restore







***** Multid_poor

preserve 


keep multid_poor_40 HHBASE  SURVEY catastrofico*

bys HHBASE: gen rep=_N
keep if rep==2
reshape wide  multid_poor_40 catastrofico*, i(HHBASE) j(SURVEY)

local i=40

	gen super_pobreza_`i'=1 if multid_poor_`i'1==1 & multid_poor_`i'2==0
replace super_pobreza_`i'=2 if multid_poor_`i'1==0 & multid_poor_`i'2==1
replace super_pobreza_`i'=4 if multid_poor_`i'1==1 & multid_poor_`i'2==1 
replace super_pobreza_`i'=0 if multid_poor_`i'1==0 & multid_poor_`i'2==0 


la var super_pobreza_`i' "Umbral `i' de pobreza"
la def super_pobreza_`i' 0 "Ningún Año" /// 
								1 "Solo SURVEY 1" ///
								2 "Solo SURVEY 2" ///
								4 "Todos los SURVEY" ///

la val super_pobreza_`i' super_pobreza_`i'

reshape long  multid_poor_40 catastrofico40 catastrofico10 catastrofico20 catastrofico30 , i(HHBASE) j(SURVEY)

bys catastrofico30: tab super_pobreza_40,m


restore






