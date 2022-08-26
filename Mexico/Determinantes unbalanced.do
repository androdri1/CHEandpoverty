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

***Working Folder Path ***
*global folder "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico"
global folder "D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Mexico"


global dtain "$folder\Stata\IPM\balanceado\d0\dta"

global results "$folder/Stata/IPM/balanceado/d1/code/results"



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

gen female = genero_jefehogar==1

gen Urban = estrato==1

*******************************************************************************
xtset pid_link year

cap drop tot att
bys pid_link : gen tot = _N
tab tot

xx
gen att= tot==1 | tot==2 if year==1


est drop _all

reg att edad_jefehogar nniños nmayores female Urban i.quart , r
	est store r1
	estadd ysumm
reg att catastrofico40 edad_jefehogar nniños nmayores female Urban i.quart , r
	est store r2
reg att multid_poor_26 edad_jefehogar nniños nmayores female Urban i.quart , r
	est store r3
	
esttab r1 r2 r3 , se star(* .1 ** .05 *** .01) stats(ymean r2 N)
esttab r1 r2 r3 using "$workingfolder_out\determinatesMexico.csv" , se star(* .1 ** .05 *** .01) stats(ymean r2 N) replace



  
  
 
 
 
 
 
 
 
 