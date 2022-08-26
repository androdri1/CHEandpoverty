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


***Working Folder Path ***
*global dta "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/ELCA"
global dta "D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\ELCA"

global dtain "$dta/Stata/IPM/d1"
global workingfolder_out "$dta\Stata\Regresiones\code\results" 
 
 
use  "$dtain/dta/IPMNobalanceado.dta",replace

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

gen female =  genero_jefehogar==1
 
*******************************************************************************
cap drop tot att
bys llaveper : gen tot = _N
gen att= tot==1 if ola==2013

     

est drop _all

reg att edad_jefehogar nniños nmayores female Urban i.quart , r
	est store r1
	estadd ysumm
reg att catastrofico40 edad_jefehogar nniños nmayores female Urban i.quart , r
	est store r2
reg att multid_poor_26 edad_jefehogar nniños nmayores female Urban i.quart , r
	est store r3
	
esttab r1 r2 r3 , se star(* .1 ** .05 *** .01) stats(ymean r2 N)
esttab r1 r2 r3 using "$workingfolder_out\determinatesColombia.csv" , se star(* .1 ** .05 *** .01) stats(ymean r2 N) replace


