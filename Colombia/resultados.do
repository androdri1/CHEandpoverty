****************************************************************
* resultados.do realiza la primera versión de regresiones de Colombia 
* ODS project
*
* Date Created: 20200802
* Name Created: GC
* Last modified: 
*
* Notas:
*  1. 
***************************************************************


global dtain "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/ELCA/Stata/IPM/d1"



use  "$dtain/dta/IPMbalanceado.dta",replace

gen region_1=region if ola==2013
drop region
bys llave: egen region=max(region_1)
drop region_1

replace region=0 if missing(region)
label define region_label 1 "Atlantico" 2 "Oriental" 3 "Central" 4 "Pacifica" 5 "Bogotá" 6 "Atlantica Media" 7 "Cundi-Boyacense" 8 "Eje-Cafetero" 9 "Centro-Oriente" 0 "No responde" 
label values region region_label





**************** numero de niños por hogar ******************
gen niños=1 if edad<12
bys llave ola: egen nniños = sum(niños),missing
replace nniños=0 if missing(nniños)
drop niños



**************** numero de ancianos por hogar ******************
gen ancianos=1 if edad>65
bys llave ola: egen nmayores = sum(ancianos),missing
replace nmayores=0 if missing(nmayores)
drop ancianos
bys ola: sum nmayores

**************** urbano/rural ******************


label defin Urban 1 "Urbano" 2 "Rural"
label values zona Urban
*______________________*
*                      *
*     Missings         *
*______________________*

gen edad1=edad if orden==1
replace edad1=0 if missing(edad1)
bys llave ola: egen edad_jefehogar = max(edad1)
drop edad1


gen genero=sexo if orden==1
replace genero=sexo if orden==1 & genero==.
tab genero ola if orden==1,m

bys llave ola: egen genero_jefehogar = max(genero)
sort genero_jefehogar
label defin genero_jefehogar_label 1 "Femenino" 2 "Masculino"
label values genero_jefehogar genero_jefehogar_label
drop genero


tostring ola, generate(year1)
encode year1, generate(year2)
drop year1 
rename year2 year


gen edad2=edad_jefehogar*edad_jefehogar



*______________________*
*                      *
*  Enefermedades       *
*______________________* 

* al menos un miembro del hogar tiene problemas trombosis 

bys ola llave: egen trombosis_hogar=max(trombosis)

replace trombosis_hogar=0 if missing(trombosis_hogar)
replace trombosis_hogar=0 if trombosis_hogar==2|trombosis_hogar==8

* al menos un miembro del hogar tiene problemas ataq_corazon
 
bys ola llave: egen ataq_corazon_hogar=max(ataq_corazon)

replace ataq_corazon_hogar=0 if missing(ataq_corazon_hogar)
replace ataq_corazon_hogar=0 if ataq_corazon_hogar==2|ataq_corazon_hogar==8


* al menos un miembro del hogar tiene problemas enf_corazon
 
bys ola llave: egen enf_corazon_hogar=max(enf_corazon)

replace enf_corazon_hogar=0 if missing(enf_corazon_hogar)
replace enf_corazon_hogar=0 if enf_corazon_hogar==2|enf_corazon_hogar==8


* al menos un miembro del hogar tiene problemas hipertenso
 
bys ola llave: egen hiperteso_hogar=max(hipertenso)

replace hiperteso_hogar=0 if missing(hiperteso_hogar)
replace hiperteso_hogar=0 if hiperteso_hogar==2|hiperteso_hogar==8
replace hiperteso_hogar=1 if hiperteso_hogar==3


* al menos un miembro del hogar tiene problemas asma
 
bys ola llave: egen asma_hogar=max(asma)

replace asma_hogar=0 if missing(asma_hogar)
replace asma_hogar=0 if asma_hogar==2|asma_hogar==8



* al menos un miembro del hogar tiene problemas tuberculosis
 
bys ola llave: egen tuberculosis_hogar=max(tuberculosis)
replace tuberculosis_hogar=0 if missing(tuberculosis_hogar)
replace tuberculosis_hogar=0 if tuberculosis_hogar==2|tuberculosis_hogar==8



* al menos un miembro del hogar tiene problemas enfisema
 
bys ola llave: egen enfisema_hogar=max(enfisema)
replace enfisema_hogar=0 if missing(enfisema_hogar)
replace enfisema_hogar=0 if enfisema_hogar==2|enfisema_hogar==8

* al menos un miembro del hogar tiene problemas diabetes
 
bys ola llave: egen diabetes_hogar=max(diabetes)
replace diabetes_hogar=0 if missing(diabetes_hogar)
replace diabetes_hogar=0 if diabetes_hogar==2|diabetes_hogar==8
replace diabetes_hogar=1 if diabetes_hogar==3

* al menos un miembro del hogar tiene problemas ulcera
 
bys ola llave: egen ulcera_hogar=max(ulcera)
replace ulcera_hogar=0 if missing(ulcera_hogar)
replace ulcera_hogar=0 if ulcera_hogar==2|ulcera_hogar==8


* al menos un miembro del hogar tiene problemas epilepsia
 
bys ola llave: egen epilepsia_hogar=max(epilepsia)
replace epilepsia_hogar=0 if missing(epilepsia_hogar)
replace epilepsia_hogar=0 if epilepsia_hogar==2|epilepsia_hogar==8


* al menos un miembro del hogar tiene problemas cancer
 
bys ola llave: egen cancer_hogar=max(cancer)
replace cancer_hogar=0 if missing(cancer_hogar)
replace cancer_hogar=0 if cancer_hogar==2|cancer_hogar==8


egen enfermedad_hogar=rowtotal(trombosis_hogar ataq_corazon_hogar enf_corazon_hogar hiperteso_hogar asma_hogar tuberculosis_hogar enfisema_hogar diabetes_hogar ulcera_hogar epilepsia_hogar cancer_hogar)

*______________________*
*                      *
*  Choques             *
*______________________* 



* Enfermedad 

gen enfermedad=(tuvo_choque1==1)
bys llave ola: egen shockenfermedad=max(enfermedad)

* Desempleo

gen desempleo=(tuvo_choque5==1|tuvo_choque6==1)
bys llave ola: egen shockdesempleo=max(desempleo)

* Muerte

gen muerte=(tuvo_choque2==1|tuvo_choque3==1)
bys llave ola: egen shockmuerte=max(muerte)
**************************************

*______________________*
*                      *
*     Regresion        *
*______________________*



/*
Pesos
*/

* sample_weight  Peso de la encuesta


/*
Construir los cuartiles de gastos
*/


bys ola: egen  quart= xtile(gasto_total), n(4)


/*
Definir los controles
*/

glo controles = "edad_jefehogar  i.genero_jefehogar nniños nmayores "  

replace catastrofico10=0 if missing(catastrofico10)
replace catastrofico20=0 if missing(catastrofico20)
replace catastrofico30=0 if missing(catastrofico30)
replace catastrofico40=0 if missing(catastrofico40)
 
gen year_1=1 if ola==2013
replace year_1=2 if ola==2016
 
 
 ** Rezagos 
 
 
  forval i=10(10)60{
 	bys llave_n16: gen pobreza`i'_rezago=multid_poor_`i'[_n-1]
gsort llave_n16 - ola
bys llave_n16: carryforward pobreza`i'_rezago, replace	
gsort llave_n16  ola
bys llave_n16: carryforward pobreza`i'_rezago, replace
replace pobreza`i'_rezago=multid_poor_`i' if pobreza`i'_rezago==.	
 }
 local i=26
 
  	bys llave_n16: gen pobreza`i'_rezago=multid_poor_`i'[_n-1]
gsort llave_n16 - ola
bys llave_n16: carryforward pobreza`i'_rezago, replace	
gsort llave_n16  ola
bys llave_n16: carryforward pobreza`i'_rezago, replace
replace pobreza`i'_rezago=multid_poor_`i' if pobreza`i'_rezago==.	
 
 bys ola : gen cuartil = quart[_n-1]
gsort - ola
bys llave_n16 : carryforward cuartil, replace	

gsort ola  llave_n16 
bys llave_n16: carryforward cuartil, replace
replace cuartil=quart if cuartil==.
 
 
 
 forval i=10(10)40{
 	bys llave_n16: gen catastrofico`i'_rezago=catastrofico`i'[_n-1]
gsort llave_n16 - ola
bys llave_n16: carryforward catastrofico`i'_rezago, replace	
gsort llave_n16  ola
bys llave_n16: carryforward catastrofico`i'_rezago, replace
replace catastrofico`i'_rezago=catastrofico`i' if catastrofico`i'_rezago==.	
 }
 
 
 bys llave_n16: gen Urban=zona[_n-1]
gsort llave_n16 - ola
bys llave_n16: carryforward Urban, replace	
gsort llave_n16  ola
bys llave_n16: carryforward Urban, replace
replace Urban=zona if Urban==.

gen catastrofico_percent=gsalud/(gasto_total-galimentos)
replace catastrofico_percent=0 if missing(catastrofico_percent)
 ***** Multid_poor

preserve 

keep if orden==1
keep multid_poor_26 llave_n16  ola catastrofico*

bys llave_n16: gen rep=_N
keep if rep==2
reshape wide  multid_poor_26 catastrofico* , i(llave_n16) j(ola)

local i=26

	gen super_pobreza_`i'=1 if multid_poor_`i'2013==1 & multid_poor_`i'2016==0
replace super_pobreza_`i'=2 if multid_poor_`i'2013==0 & multid_poor_`i'2016==1
replace super_pobreza_`i'=4 if multid_poor_`i'2013==1 & multid_poor_`i'2016==1 
replace super_pobreza_`i'=0 if multid_poor_`i'2013==0 & multid_poor_`i'2016==0 

reshape long  multid_poor_26 catastrofico40 catastrofico20 catastrofico30 catastrofico10, i(llave_n16) j(ola)
local i=26
la var super_pobreza_`i' "Umbral `i' de pobreza"
la def super_pobreza_`i' 0 "Ningún Año" /// 
								1 "Solo SURVEY 1" ///
								2 "Solo SURVEY 2" ///
								4 "Todos los SURVEY" ///

la val super_pobreza_`i' super_pobreza_`i'

bys catastrofico10: tab super_pobreza_26


restore

 
 *___________________________*
*                           *
*     Tablas del Journal    *
*___________________________*

local i=26
local k=40
keep if orden==1
gen n=1
bys llave : egen hh_n=sum(n)
keep if hh_n==2
xtset llave ola,format(%tg)
 
 gen catrastrofico_original=catastrofico_percent
 gen catastrofico_original_sd=catrastrofico_original/0.160
 sum catastrofico_percent
 replace catastrofico_percent=catastrofico_percent/r(sd)
 replace catastrofico_percent=0 if missing(catastrofico_percent)
global covar "catastrofico`k' c.catastrofico`k'#i.Urban c.catastrofico`k'#i.catastrofico`k'_rezago c.catastrofico`k'#i.cuartil shockdesempleo shockenfermedad shockmuerte catastrofico_percent"



foreach var in $covar {

reghdfe multid_poor_`i' `var' $controles,  absorb(llave_n16 ola) vce(cluster region)
}

reg multid_poor_`i' catastrofico`k' $controles, vce( cluster region)
 
 reghdfe multid_poor_`i' catastrofico`k' $controles if pobreza`i'_rezago==0,  absorb( llave_n16 ola) vce(cluster region)
 
 reghdfe multid_poor_`i' catastrofico`k' $controles if pobreza`i'_rezago==1,  absorb( llave_n16 ola) vce(cluster region) 
 
/* Para hacer el plot de los coeficiente */


global results "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/Regresiones/code/results"


** Headcount of muldimentional poverty



xtset llave year,format(%tg)
gen d_multid_poor_26=multid_poor_26-pobreza26_rezago 
gen d_catastrofico_percent=catastrofico_original_sd-L.catastrofico_original_sd

lpoly d_multid_poor_26 d_catastrofico_percent, gen(xhat yhat) se(sehat) noscatter

   * Replace 1.965 by the critical tstat
   * upper bound, control:
   g ub = yhat + 1.965*sehat
   * lower bound, control:
   g lb = yhat - 1.965*sehat
   
   
   
   twoway (line yhat xhat, lcolor(dknavy) lwidth(thick)) ///
   || (line ub xhat, lcolor(black) lpattern(dash)) ///
   || (line lb xhat, lcolor(black) lpattern(dash)) ///
   , ytitle("{&Delta} Probability of headcount multidimensional poverty", size(med)) xtitle("{&Delta} Share of catastrophic expenditure ", size(large)) legend(off) ///
   graphregion(color(white)) ///
   xlabel(-6(2)6, labc(black) format(%9.2f)) ///
    ylabel(-0.4(.1)0.2, labc(black) format(%9.2f)) xscale(lstyle(none)) yline(0, lcolor(black))
 
graph export "${results}/grafica_headcount_COL.pdf", as(pdf) replace fontface("Times New Roman")



** Deprivation score
drop xhat yhat sehat ub lb
xtset llave year,format(%tg)
gen d_cens_c_vector_40 =cens_c_vector_40 -L.cens_c_vector_40 

lpoly d_cens_c_vector_40 d_catastrofico_percent, gen(xhat yhat) se(sehat) noscatter

   * Replace 1.965 by the critical tstat
   * upper bound, control:
   g ub = yhat + 1.965*sehat
   * lower bound, control:
   g lb = yhat - 1.965*sehat
   
   
   twoway (line yhat xhat, lcolor(dknavy) lwidth(thick)) ///
   || (line ub xhat, lcolor(black) lpattern(dash)) ///
   || (line lb xhat, lcolor(black) lpattern(dash)) ///
   , ytitle("{&Delta} Deprivation score", size(large)) xtitle("{&Delta} Share of catastrophic expenditure ", size(large)) legend(off) ///
   graphregion(color(white)) ///
   xlabel(-6(2)6, labc(black) format(%9.2f)) ///
    ylabel(-0.16(.05)0.1, labc(black) format(%9.2f)) xscale(lstyle(none)) yline(0, lcolor(black)) 
	   

 
graph export "${results}/grafica_deprivation_score_COL.pdf", as(pdf) replace fontface("Times New Roman")



**** Hacer los efectos heterogeneos como variable continua



* 1. Cuartiles 
 reghdfe multid_poor_26 c.catastrofico_percent#i.cuartil  $controles if pobreza40_rezago==0,  absorb( llave_n16 ola) vce(cluster region)

* 2. Rural y Urbano

 reghdfe multid_poor_26 c.catastrofico_percent#i.Urban  $controles if pobreza40_rezago==0,  absorb( llave_n16 ola) vce(cluster region)

 
* 3. Rezago del gasto catastrofico

 reghdfe multid_poor_26 c.catastrofico_percent#i.catastrofico40_rezago  $controles if pobreza40_rezago==0,  absorb( llave_n16 ola) vce(cluster region)
 
* 4. Rezago de la pobreza
 
 reghdfe multid_poor_26 catastrofico_percent $controles if pobreza40_rezago==0,  absorb( llave_n16 ola) vce(cluster region)
 
 reghdfe multid_poor_26 catastrofico_percent $controles if pobreza40_rezago==1,  absorb( llave_n16 ola) vce(cluster region) 


recode Urban (1=1) (2=0)
************************************************************************************

 
 *===============================================================================*
*			       TABLA 4  	/ TABLA A5 si es NoBalanceado					*
*===============================================================================*

cap mat drop results

* 1) Es la regresion base cross-section
reghdfe multid_poor_26 catastrofico40 $controles  ,  absorb(  year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [1,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 2) Es la regresion base longitudinal
reghdfe multid_poor_26 catastrofico40 $controles,  absorb(  llave year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [2,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 3) Es la regresion de los quartes 
reghdfe multid_poor_26 c.catastrofico40#i.quart i.quart $controles,  absorb(  llave_n16 year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.quart#catastrofico40]/_se[1b.quart#catastrofico40]))
	mat results=nullmat(results)\ [31,_b[1b.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.quart#catastrofico40]/_se[2.quart#catastrofico40]))
	mat results=nullmat(results)\ [32,_b[2.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.quart#catastrofico40]/_se[3.quart#catastrofico40]))
	mat results=nullmat(results)\ [33,_b[3.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.quart#catastrofico40]/_se[4.quart#catastrofico40]))
	mat results=nullmat(results)\ [34,_b[4.quart#catastrofico40], p_value] 	
	
* 4) Es la regresion de rural y Urbano
reghdfe multid_poor_26 c.catastrofico40#i.Urban i.Urban $controles,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.Urban#catastrofico40]/_se[0b.Urban#catastrofico40]))
	mat results=nullmat(results)\ [41,_b[0b.Urban#catastrofico40], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.Urban#catastrofico40]/_se[1.Urban#catastrofico40]))
	mat results=nullmat(results)\ [42,_b[1.Urban#catastrofico40], p_value] // Urban
				
* 5) Es la regresion del rezago del gasto catastrofico40
reghdfe multid_poor_26 c.catastrofico40#i.catastrofico40_rezago i.catastrofico40_rezago $controles,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.catastrofico40_rezago#c.catastrofico40]/_se[0b.catastrofico40_rezago#catastrofico40]))
	mat results=nullmat(results)\ [51,_b[0b.catastrofico40_rezago#c.catastrofico40], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1.catastrofico40_rezago#c.catastrofico40]/_se[1.catastrofico40_rezago#catastrofico40]))
	mat results=nullmat(results)\ [52,_b[1.catastrofico40_rezago#c.catastrofico40], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_26 c.catastrofico40 $controles if pobreza26_rezago ==0,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [6,_b[catastrofico40], p_value] // Not poor
reghdfe multid_poor_26 c.catastrofico40 $controles if pobreza26_rezago ==1,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [7,_b[catastrofico40], p_value] // Poor

* 8) Disease Shock (Accident Shock in Malawi)
reghdfe multid_poor_26 c.shockenfermedad $controles,  absorb(  llave year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[shockenfermedad]/_se[shockenfermedad]))
	mat results=nullmat(results)\ [8,_b[shockenfermedad], p_value] 

* 9) Death Shock. choque_muerte
reghdfe multid_poor_26 c.shockmuerte $controles,  absorb(  llave year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[shockmuerte]/_se[shockmuerte]))
	mat results=nullmat(results)\ [9,_b[shockmuerte], p_value] 

* 10) Unemployment Shock. choque_desempleo
reghdfe multid_poor_26 c.shockdesempleo $controles,  absorb(  llave year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[shockdesempleo]/_se[shockdesempleo]))
	mat results=nullmat(results)\ [10,_b[shockdesempleo], p_value] 

* 11) Share of healthcare expenditures divided by the mean SD
reghdfe multid_poor_26 c.catastrofico_original_sd $controles,  absorb(  llave year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_original_sd]/_se[catastrofico_original_sd]))
	mat results=nullmat(results)\ [11,_b[catastrofico_original_sd], p_value] 

	
sum catrastrofico_original if catrastrofico_original>0
mat results=nullmat(results)\ [12, r(sd), .] 
	
mat list results	
 

 
 
 
*===============================================================================*
*							       TABLA A3  (continuous)		  		   		*
*===============================================================================*
cap mat drop results

* 0) 

* 1) Es la regresion de los quartes 
reghdfe multid_poor_26 c.catastrofico_original_sd#i.quart i.quart $controles,  absorb(  llave year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.quart#catastrofico_original_sd]/_se[1b.quart#catastrofico_original_sd]))
	mat results=nullmat(results)\ [31,_b[1b.quart#catastrofico_original_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.quart#catastrofico_original_sd]/_se[2.quart#catastrofico_original_sd]))
	mat results=nullmat(results)\ [32,_b[2.quart#catastrofico_original_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.quart#catastrofico_original_sd]/_se[3.quart#catastrofico_original_sd]))
	mat results=nullmat(results)\ [33,_b[3.quart#catastrofico_original_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.quart#catastrofico_original_sd]/_se[4.quart#catastrofico_original_sd]))
	mat results=nullmat(results)\ [34,_b[4.quart#catastrofico_original_sd], p_value] 	
	
* 4) Es la regresion de rural y Urbano
reghdfe multid_poor_26 c.catastrofico_original_sd#i.Urban i.Urban $controles,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.Urban#catastrofico_original_sd]/_se[0b.Urban#catastrofico_original_sd]))
	mat results=nullmat(results)\ [41,_b[0b.Urban#catastrofico_original_sd], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.Urban#catastrofico_original_sd]/_se[1.Urban#catastrofico_original_sd]))
	mat results=nullmat(results)\ [42,_b[1.Urban#catastrofico_original_sd], p_value] // Urban
				
* 5) Es la regresion del rezago del gasto catastrofico40
reghdfe multid_poor_26 c.catastrofico_original_sd#i.catastrofico40_rezago  i.catastrofico40_rezago  $controles,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.catastrofico40_rezago#catastrofico_original_sd]/_se[0b.catastrofico40_rezago #catastrofico_original_sd]))
	mat results=nullmat(results)\ [51,_b[0b.catastrofico40_rezago#catastrofico_original_sd], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1.catastrofico40_rezago#catastrofico_original_sd]/_se[1.catastrofico40_rezago #catastrofico_original_sd]))
	mat results=nullmat(results)\ [52,_b[1.catastrofico40_rezago #catastrofico_original_sd], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_26 c.catastrofico_original_sd $controles if pobreza26_rezago ==0,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_original_sd]/_se[catastrofico_original_sd]))
	mat results=nullmat(results)\ [6,_b[catastrofico_original_sd], p_value] // Not poor
reghdfe multid_poor_26 c.catastrofico_original_sd $controles if pobreza26_rezago ==1,  absorb(  llave year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico_original_sd]/_se[catastrofico_original_sd]))
	mat results=nullmat(results)\ [7,_b[catastrofico_original_sd], p_value] // Poor
	
	
mat list results	

 
 
 
*===============================================================================*
*							       TABLA A4  (logit)		  		   		*
*===============================================================================*
cap mat drop results

* 1) Es la regresion base cross-section
logit multid_poor_26 catastrofico40 $controles   i.year
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [1,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 2) Es la regresion base longitudinal
xtlogit multid_poor_26 catastrofico40 $controles i.year, fe 
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [2,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 3) Es la regresion de los quartes 
xtlogit multid_poor_26 c.catastrofico40#i.quart i.quart $controles i.year, fe 
margins, dydx(catastrofico40) at (quart=(1(1)4)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [31,_b[catastrofico40:1._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [32,_b[catastrofico40:2._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:3._at]/_se[catastrofico40:3._at])))
	mat results=nullmat(results)\ [33,_b[catastrofico40:3._at], p_value] 
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:4._at]/_se[catastrofico40:4._at])))
	mat results=nullmat(results)\ [34,_b[catastrofico40:4._at], p_value] 	
	
* 4) Es la regresion de rural y Urbano
xtlogit multid_poor_26 c.catastrofico40#i.Urban i.Urban $controles i.year, fe 
margins, dydx(catastrofico40) at (Urban=(0(1)1)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [41,_b[catastrofico40:1._at], p_value] // Rural
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [42,_b[catastrofico40:2._at], p_value] // Urban
				
* 5) Es la regresion del rezago del gasto catastrofico40
xtlogit multid_poor_26 c.catastrofico40#i.catastrofico40_rezago  i.catastrofico40_rezago  $controles i.year, fe  
margins, dydx(catastrofico40) at (catastrofico40_rezago =(0(1)1)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [51,_b[catastrofico40:1._at], p_value] // CHP No
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [52,_b[catastrofico40:2._at], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
xtlogit multid_poor_26 c.catastrofico40 $controles i.year if pobreza26_rezago ==0 , re  
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [6,_b[catastrofico40], p_value] // Not poor
xtlogit multid_poor_26 c.catastrofico40 $controles i.year if pobreza26_rezago ==1 , re 
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [7,_b[catastrofico40], p_value] // Poor

* 8) Disease Shock (Accident Shock in Malawi)
xtlogit multid_poor_26 c.shockenfermedad $controles i.year, fe 
margins, dydx(shockenfermedad) post
	sca p_value = 2*(1-normal(abs(_b[shockenfermedad]/_se[shockenfermedad])))
	mat results=nullmat(results)\ [8,_b[shockenfermedad], p_value] 

* 9) Death Shock. choque_muerte
xtlogit multid_poor_26 c.shockmuerte $controles i.year, fe 
margins, dydx(shockmuerte) post
	sca p_value = 2*(1-normal(abs(_b[shockmuerte]/_se[shockmuerte])))
	mat results=nullmat(results)\ [9,_b[shockmuerte], p_value] 

* 10) Unemployment Shock. choque_desempleo
xtlogit multid_poor_26 c.shockdesempleo $controles i.year, fe 
margins, dydx(shockdesempleo) post
	sca p_value = 2*(1-normal(abs(_b[shockdesempleo]/_se[shockdesempleo])))
	mat results=nullmat(results)\ [10,_b[shockdesempleo], p_value] 

* 11) Share of healthcare expenditures divided by the mean SD
xtlogit multid_poor_26 c.catastrofico_original_sd $controles i.year, fe 
margins, dydx(catastrofico_original_sd) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico_original_sd]/_se[catastrofico_original_sd])))
	mat results=nullmat(results)\ [11,_b[catastrofico_original_sd], p_value] 

mat list results	

 
 
 
 
 
 
 


