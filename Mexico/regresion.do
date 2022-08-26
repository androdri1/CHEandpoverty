****************************************************************
* regresion.do realiza la segunda version de la regresion en Mexico
*  
* ODS project
*
* Date Created: 20200709
* Name Created: GC
* Last modified: 20200721
*
* Notas:
*  1. 
***************************************************************

global dtain "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/IPM/balanceado/d0/dta"



use "$dtain/IPMbalanceado.dta", replace


egen cronico=rowtotal(ec01a ec01b ec01c ec01d ec01e ec01f ec01g ec01h_1 ec01i_1), missing

gen edadcronico=1 if cronico>0 & edad>=65&edad!=.
replace edadcronico=0 if missing(edadcronico)
bys folio year: egen crononico65 = sum(edadcronico),missing

mean crononico65 [aw=fac_libc], over( catastrofico40 year)


tab   crononico65 catastrofico40 [aw=fac_libc],row


sort edad
br edad crononico65 edadcronico folio catastrofico40
replace crononico65=2 if crononico65>2

********* niños con enfermedades ***********
recode esn01 (1 2 =0) (3 4 5=1)
bys folio year: egen enfermedadniño = sum(esn01),missing
replace enfermedadniño=3 if enfermedadniño>3
tab enfermedadniño,m


replace ls14=1 if ls14==2
replace ls14=1 if ls14==98
replace ls14=4 if ls14==5
replace ls14=6 if ls14==7 |ls14==8


label define ls14_label 1 "Preescolar" 3 "Primaria" 4 "Secundaria" 6 "Preparatoria" 9 "Profesional" 10 "Posgrado"
label values ls14 ls14_label
gen region=1 if ent==20|ent==30|ent==31|ent==28|ent==4|ent==7|ent==12

replace region=2 if ent==9|ent==15|ent==17|ent==21|ent==11|ent==13|ent==22|ent==24|ent==29
replace region=3 if ent==16|ent==14|ent==11|ent==6|ent==18|ent==32
replace region=4 if ent==2|ent==3|ent==25|ent==26
replace region=5 if ent==5|ent==10|ent==19

label define region_label 1 "Sur-Sureste" 2 "Centro" 3 "Centro-Occidente" 4 "Noroeste" 5 "Noreste" 
label values region region_label

label defin estrato_label 1 "Localidad con más de 100,000 habs." 2 "Localidad con entre 15,000 y 100,000 habs." 3 "Localidad con entre 2,500 y 15,000 habs." 4 "Localidad con menos de 2,500 habs."

label values estrato estrato_label


label defin ls04_label 1 "Masculino" 3 "Femenino"
label values ls04 ls04_label




**************** numero de niños por hogar ******************
gen niños=1 if edad_miembros<12
bys folio year: egen nniños = sum(niños),missing
replace nniños=0 if missing(nniños)
br edad_miembros year nniños folio ls
drop niños



**************** numero de ancianos por hogar ******************
gen ancianos=1 if edad_miembros>65
bys folio year: egen nmayores = sum(ancianos),missing
replace nmayores=0 if missing(nmayores)
drop ancianos
bys year: sum nmayores

**************** estratoo/rural ******************
replace estrato=1 if estrato==2
replace estrato=3 if estrato==4
tab estrato,m

label defin rural_label 1 "estratoo" 3 "Rural"
label values estrato rural_label
*______________________*
*                      *
*     Missings         *
*______________________*

gen edad1=edad_miembros if ls=="01"
replace edad1=0 if missing(edad1)
bys folio year: egen edad_jefehogar = max(edad1)
drop edad1


replace thi01=3 if thi01==2
gen genero=thi01 if ls=="01"
replace genero=ls04 if ls=="01" & genero==.
tab genero year if ls=="01",m



bys folio year: egen genero_jefehogar = max(genero)
sort genero_jefehogar
label defin genero_jefehogar_label 1 "Femenino" 3 "Masculino"
label values genero_jefehogar genero_jefehogar_label
drop genero



tostring year, generate(year1)
encode year1, generate(year2)
drop year1 year
rename year2 year


gen edad2=edad_jefehogar*edad_jefehogar



*egen quart=xtile(gtotal), n(4) by(year)
*______________________*
*                      *
*   Choques.           *
*______________________* 


label define shocks_label 1 "Sí" 3 "No"


lookfor se01a se01b se01c se01d se01e

/*
Shock muerte
*/

tab se02aa_2

gen shockmuerte=1 if year==1 & (se02aa_2==2002|se02aa_2==2001)
replace shockmuerte=1 if year==2 & (se02aa_2==2006|se02aa_2==2005)
replace shockmuerte=1 if year==3 & (se02aa_2==2009|se02aa_2==2010|se02aa_2==2011|se02aa_2==2012)
replace shockmuerte=0 if missing(shockmuerte)

tab shockmuerte year,m

gen shockmuerte1=1 if year==1 & (se02ab_2==2002|se02ab_2==2001)
replace shockmuerte1=1 if year==2 & (se02ab_2==2006|se02ab_2==2005)
replace shockmuerte1=1 if year==3 & (se02ab_2==2009|se02ab_2==2010|se02ab_2==2011|se02ab_2==2012)
replace shockmuerte1=0 if missing(shockmuerte1)

tab shockmuerte1 year,m

gen shockmuerte2=1 if year==1 & (se02ac_2==2002|se02ac_2==2001)
replace shockmuerte2=1 if year==2 & (se02ac_2==2006|se02ac_2==2005)
replace shockmuerte2=1 if year==3 & (se02ac_2==2009|se02ac_2==2010|se02ac_2==2011|se02ac_2==2012)
replace shockmuerte2=0 if missing(shockmuerte2)

tab shockmuerte2 year,m

egen nshockmuerte=rowtotal(shockmuerte shockmuerte1 shockmuerte2)
tab nshockmuerte year,m

drop shockmuerte1 shockmuerte2

label define shocks_labelm 1 "Shock muerte" 3 "No"

label values shockmuerte shocks_labelm

/*
Shock enfermedad
*/

tab se02ba_2

gen shockenfermedad=1 if year==1 & (se02ba_2==2002|se02ba_2==2001)
replace shockenfermedad=1 if year==2 & (se02ba_2==2006|se02ba_2==2005)
replace shockenfermedad=1 if year==3 & (se02ba_2==2009|se02ba_2==2010|se02ba_2==2011|se02ba_2==2012)
replace shockenfermedad=0 if missing(shockenfermedad)

tab shockenfermedad year,m

gen shockenfermedad1=1 if year==1 & (se02bb_2==2002|se02bb_2==2001)
replace shockenfermedad1=1 if year==2 & (se02bb_2==2006|se02bb_2==2005)
replace shockenfermedad1=1 if year==3 & (se02bb_2==2009|se02bb_2==2010|se02bb_2==2011|se02bb_2==2012)
replace shockenfermedad1=0 if missing(shockenfermedad1)

tab shockenfermedad1 year,m

gen shockenfermedad2=1 if year==1 & (se02bc_2==2002|se02bc_2==2001)
replace shockenfermedad2=1 if year==2 & (se02bc_2==2006|se02bc_2==2005)
replace shockenfermedad2=1 if year==3 & (se02bc_2==2009|se02bc_2==2010|se02bc_2==2011|se02bc_2==2012)
replace shockenfermedad2=0 if missing(shockenfermedad2)

tab shockenfermedad2 year,m

egen nshockenfermedad=rowtotal(shockenfermedad shockenfermedad1 shockenfermedad2)
tab nshockenfermedad year,m

drop shockenfermedad1 shockenfermedad2

label define shocks_labele 1 "Shock enfermedad" 3 "No"

label values shockenfermedad shocks_labele

/*
Shock desempleo
*/

tab se02ca_2

gen shockdesempleo=1 if year==1 & (se02ca_2==2002|se02ca_2==2001)
replace shockdesempleo=1 if year==2 & (se02ca_2==2006|se02ca_2==2005)
replace shockdesempleo=1 if year==3 & (se02ca_2==2009|se02ca_2==2010|se02ca_2==2011|se02ca_2==2012)
replace shockdesempleo=0 if missing(shockdesempleo)

tab shockdesempleo year,m

gen shockdesempleo1=1 if year==1 & (se02cb_2==2002|se02cb_2==2001)
replace shockdesempleo1=1 if year==2 & (se02cb_2==2006|se02cb_2==2005)
replace shockdesempleo1=1 if year==3 & (se02cb_2==2009|se02cb_2==2010|se02cb_2==2011|se02cb_2==2012)
replace shockdesempleo1=0 if missing(shockdesempleo1)

tab shockdesempleo1 year,m

gen shockdesempleo2=1 if year==1 & (se02cc_2==2002|se02cc_2==2001)
replace shockdesempleo2=1 if year==2 & (se02cc_2==2006|se02cc_2==2005)
replace shockdesempleo2=1 if year==3 & (se02cc_2==2009|se02cc_2==2010|se02cc_2==2011|se02cc_2==2012)
replace shockdesempleo2=0 if missing(shockdesempleo2)

tab shockdesempleo2 year,m

egen nshockdesempleo=rowtotal(shockdesempleo shockdesempleo1 shockdesempleo2)
tab nshockdesempleo year,m




gen catastrofico4010=(gsalud/(gtotal-galimentos))>0.1 if gtotal>0&gtotal!=.&gsalud!=.&gsalud>0&galimentos!=.&galimentos>0


gen catastrofico4020=(gsalud/(gtotal-galimentos))>0.2 if gtotal>0&gtotal!=.&gsalud!=.&gsalud>0&galimentos!=.&galimentos>0
 

gen catastrofico4030=(gsalud/(gtotal-galimentos))>0.3 if gtotal>0&gtotal!=.&gsalud!=.&gsalud>0&galimentos!=.&galimentos>0 


gen catastrofico4040=(gsalud/(gtotal-galimentos))>0.4 if gtotal>0&gtotal!=.&gsalud!=.&gsalud>0&galimentos!=.&galimentos>0
 
 
replace catastrofico4010=0 if missing(catastrofico4010)
replace catastrofico4020=0 if missing(catastrofico4020)
replace catastrofico4030=0 if missing(catastrofico4030)  
replace catastrofico4040=0 if missing(catastrofico4040)


/*
Pesos
*/

gen mipeso= fac_libc if year==1
bys pid_link: egen elpeso = max(mipeso)

/*
Rezagos
*/

replace catastrofico401 =0 if missing(catastrofico401 )
replace gtotal=0 if missing(gtotal)
replace gsalud=0 if missing(gsalud)


/*
Nombres 
*/




/*
Definir los controles
*/

glo controles = "edad_jefehogar  i.genero_jefehogar nniños nmayores"  
global results "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/Mexico/Stata/IPM/balanceado/d1/code/results"



  
 *___________________________*
*                           *
*     Tablas del Journal    *
*___________________________*
 
gen catastrofico40_original_sd=gsalud/(gtotal-galimentos) 
gen catastrofico40_original=catastrofico40_original_sd
gen catastrofico40_original_sd=catastrofico40_original/0.16


sum catastrofico40_original_sd 
replace catastrofico40_original_sd=catastrofico40_original_sd/r(sd) 
replace catastrofico40_original_sd=0 if missing(catastrofico40_original_sd)

local i=26
xtset pid_link year,format(%tg)
global covar "catastrofico40 c.catastrofico40#i.L.quart c.catastrofico40#i.L.estrato c.catastrofico40#i.L.catastrofico40  shockdesempleo shockenfermedad shockmuerte catastrofico40_original_sd"

preserve
keep if ls=="01"
foreach var in $covar {
sort    pid_link year
reghdfe multid_poor_`i' `var' $controles,  absorb(folio year) vce(cluster region)
}
sort    pid_link year
reghdfe multid_poor_`i' c.catastrofico40 $controles if L.multid_poor_`i'==0,  absorb( folio year) vce(cluster region)
reghdfe multid_poor_`i' c.catastrofico40 $controles if L.multid_poor_`i'==1,  absorb( folio year) vce(cluster region)

reg multid_poor_`i' catastrofico40 $controles, vce( cluster region)
restore 
 
*** Efectos heterogeneos como variable continua 

local i=26
xtset pid_link year,format(%tg)
global covar "c.catastrofico40_original_sd#i.L.quart c.catastrofico40_original_sd#i.L.estrato c.catastrofico40_original_sd#i.L.catastrofico40 "

preserve
keep if ls=="01"
foreach var in $covar {
sort    pid_link year
reghdfe multid_poor_`i' `var' $controles,  absorb(folio year) vce(cluster region)
}
sort    pid_link year
reghdfe multid_poor_`i' c.catastrofico40_original_sd $controles if L.multid_poor_`i'==0,  absorb( folio year) vce(cluster region)
reghdfe multid_poor_`i' c.catastrofico40_original_sd $controles if L.multid_poor_`i'==1,  absorb( folio year) vce(cluster region)
restore 
 
 recode estrato (1=1) (3=0)

 
 *===============================================================================*
*			       TABLA 4  	/ TABLA A5 si es NoBalanceado					*
*===============================================================================*
preserve 
keep if npanel>1
cap mat drop results

* 1) Es la regresion base cross-section
reghdfe multid_poor_26 catastrofico40 $controles  ,  absorb(  year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [1,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 2) Es la regresion base longitudinal
reghdfe multid_poor_26 catastrofico40 $controles,  absorb(  folio year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [2,_b[catastrofico40], p_value] // Guarda en una matrix los resultados de la regresion

* 3) Es la regresion de los quartes 
reghdfe multid_poor_26 c.catastrofico40#i.quart i.quart $controles,  absorb(  folio year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.quart#catastrofico40]/_se[1b.quart#catastrofico40]))
	mat results=nullmat(results)\ [31,_b[1b.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.quart#catastrofico40]/_se[2.quart#catastrofico40]))
	mat results=nullmat(results)\ [32,_b[2.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.quart#catastrofico40]/_se[3.quart#catastrofico40]))
	mat results=nullmat(results)\ [33,_b[3.quart#catastrofico40], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.quart#catastrofico40]/_se[4.quart#catastrofico40]))
	mat results=nullmat(results)\ [34,_b[4.quart#catastrofico40], p_value] 	
	
* 4) Es la regresion de rural y estratoo
reghdfe multid_poor_26 c.catastrofico40#i.estrato i.estrato $controles,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.estrato#catastrofico40]/_se[0b.estrato#catastrofico40]))
	mat results=nullmat(results)\ [41,_b[0b.estrato#catastrofico40], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.estrato#catastrofico40]/_se[1.estrato#catastrofico40]))
	mat results=nullmat(results)\ [42,_b[1.estrato#catastrofico40], p_value] // estrato
				
* 5) Es la regresion del rezago del gasto catastrofico40
reghdfe multid_poor_26 c.catastrofico40#i.L.catastrofico40 i.L.catastrofico40 $controles,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0bL.catastrofico40#c.catastrofico40]/_se[0bL.catastrofico40#catastrofico40]))
	mat results=nullmat(results)\ [51,_b[0bL.catastrofico40#c.catastrofico40], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1L.catastrofico40#c.catastrofico40]/_se[1L.catastrofico40#catastrofico40]))
	mat results=nullmat(results)\ [52,_b[1L.catastrofico40#c.catastrofico40], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_26 c.catastrofico40 $controles if L.multid_poor_26==0,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [6,_b[catastrofico40], p_value] // Not poor
reghdfe multid_poor_26 c.catastrofico40 $controles if L.multid_poor_26==1,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40]/_se[catastrofico40]))
	mat results=nullmat(results)\ [7,_b[catastrofico40], p_value] // Poor

* 8) Disease Shock (Accident Shock in Malawi)
reghdfe multid_poor_26 c.shockenfermedad $controles,  absorb(  folio year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[shockenfermedad]/_se[shockenfermedad]))
	mat results=nullmat(results)\ [8,_b[shockenfermedad], p_value] 

* 9) Death Shock. choque_muerte
reghdfe multid_poor_26 c.shockmuerte $controles,  absorb(  folio year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[shockmuerte]/_se[shockmuerte]))
	mat results=nullmat(results)\ [9,_b[shockmuerte], p_value] 

* 10) Unemployment Shock. choque_desempleo
reghdfe multid_poor_26 c.shockdesempleo $controles,  absorb(  folio year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[shockdesempleo]/_se[shockdesempleo]))
	mat results=nullmat(results)\ [10,_b[shockdesempleo], p_value] 

* 11) Share of healthcare expenditures divided by the mean SD
reghdfe multid_poor_26 c.catastrofico40_original_sd $controles,  absorb(  folio year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40_original_sd]/_se[catastrofico40_original_sd]))
	mat results=nullmat(results)\ [11,_b[catastrofico40_original_sd], p_value] 

	
sum catastrofico40_original if catastrofico40_original>0
mat results=nullmat(results)\ [12, r(sd), .] 
	
mat list results	
 
restore 
 
 keep if npanel==3
 
*===============================================================================*
*							       TABLA A3  (continuous)		  		   		*
*===============================================================================*
cap mat drop results

* 0) 

* 1) Es la regresion de los quartes 
reghdfe multid_poor_26 c.catastrofico40_original_sd#i.quart i.quart $controles,  absorb(  folio year) vce( r)
	sca p_value = 2*ttail(e(df_r),abs(_b[1b.quart#catastrofico40_original_sd]/_se[1b.quart#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [31,_b[1b.quart#catastrofico40_original_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[2.quart#catastrofico40_original_sd]/_se[2.quart#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [32,_b[2.quart#catastrofico40_original_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[3.quart#catastrofico40_original_sd]/_se[3.quart#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [33,_b[3.quart#catastrofico40_original_sd], p_value] 
	sca p_value = 2*ttail(e(df_r),abs(_b[4.quart#catastrofico40_original_sd]/_se[4.quart#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [34,_b[4.quart#catastrofico40_original_sd], p_value] 	
	
* 4) Es la regresion de rural y estratoo
reghdfe multid_poor_26 c.catastrofico40_original_sd#i.estrato i.estrato $controles,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0b.estrato#catastrofico40_original_sd]/_se[0b.estrato#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [41,_b[0b.estrato#catastrofico40_original_sd], p_value] // Rural
	sca p_value = 2*ttail(e(df_r),abs(_b[1.estrato#catastrofico40_original_sd]/_se[1.estrato#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [42,_b[1.estrato#catastrofico40_original_sd], p_value] // estrato
				
* 5) Es la regresion del rezago del gasto catastrofico40
reghdfe multid_poor_26 c.catastrofico40_original_sd#i.L.catastrofico40 i.L.catastrofico40 $controles,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[0bL.catastrofico40#catastrofico40_original_sd]/_se[0bL.catastrofico40#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [51,_b[0bL.catastrofico40#catastrofico40_original_sd], p_value] // CHP No
	sca p_value = 2*ttail(e(df_r),abs(_b[1L.catastrofico40#catastrofico40_original_sd]/_se[1L.catastrofico40#catastrofico40_original_sd]))
	mat results=nullmat(results)\ [52,_b[1L.catastrofico40#catastrofico40_original_sd], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
reghdfe multid_poor_26 c.catastrofico40_original_sd$controles if L.multid_poor_26==0,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40_original_sd]/_se[catastrofico40_original_sd]))
	mat results=nullmat(results)\ [6,_b[catastrofico40_original_sd], p_value] // Not poor
reghdfe multid_poor_26 c.catastrofico40_original_sd$controles if L.multid_poor_26==1,  absorb(  folio year ) vce( r) 
	sca p_value = 2*ttail(e(df_r),abs(_b[catastrofico40_original_sd]/_se[catastrofico40_original_sd]))
	mat results=nullmat(results)\ [7,_b[catastrofico40_original_sd], p_value] // Poor
	
	
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
	
* 4) Es la regresion de rural y estratoo
xtlogit multid_poor_26 c.catastrofico40#i.estrato i.estrato $controles i.year, fe 
margins, dydx(catastrofico40) at (estrato=(0(1)1)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [41,_b[catastrofico40:1._at], p_value] // Rural
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [42,_b[catastrofico40:2._at], p_value] // estrato
				
* 5) Es la regresion del rezago del gasto catastrofico40
xtlogit multid_poor_26 c.catastrofico40#i.L.catastrofico40 i.L.catastrofico40 $controles i.year, fe  
margins, dydx(catastrofico40) at (L.catastrofico40=(0(1)1)) vsquish post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:1._at]/_se[catastrofico40:1._at])))
	mat results=nullmat(results)\ [51,_b[catastrofico40:1._at], p_value] // CHP No
	sca p_value = 2*(1-normal(abs(_b[catastrofico40:2._at]/_se[catastrofico40:2._at])))
	mat results=nullmat(results)\ [52,_b[catastrofico40:2._at], p_value] // CHP Yes

				
* 6&7) Es la regresion del rezago de la pobreza; no con interacciones, sino con una restricción
xtlogit multid_poor_26 c.catastrofico40 $controles i.year if L.multid_poor_26==0 , re  
margins, dydx(catastrofico40) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40]/_se[catastrofico40])))
	mat results=nullmat(results)\ [6,_b[catastrofico40], p_value] // Not poor
xtlogit multid_poor_26 c.catastrofico40 $controles i.year if L.multid_poor_26==1 , re 
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
xtlogit multid_poor_26 c.catastrofico40_original_sd$controles i.year, fe 
margins, dydx(catastrofico40_original_sd) post
	sca p_value = 2*(1-normal(abs(_b[catastrofico40_original_sd]/_se[catastrofico40_original_sd])))
	mat results=nullmat(results)\ [11,_b[catastrofico40_original_sd], p_value] 

mat list results	

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 