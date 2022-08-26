*****************************************************
/*
Nombre:

ODS project

Date Created:19-06-2020
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


*glo folder="C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Malawi\Stata"
glo folder="D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Malawi\Stata\"


* Notas:
*  1. 
***************************************************************

*--- Unión de los micro datos por años
/*
Nota: 
Pega las distintas bases que hay por año.
*/

*do "$folder\1.Union\Union de años\code\Unión Panel Corto.do" // Solo dos años (10 y 13)
//   ---- > Obsoleto

do "$folder\1.Union\Union de años\code\Unión.do" // Los tres años


/*
Nota:
Aqui se constuyen todas las variables de gastos para todos los años.
*/
do "$folder\2.Gasto Catastrofico\code\gasto_catastrofico.do"
do "$folder\2.Gasto Catastrofico\code\Otros_gastos.do"

*--- Aqui se generan los indicadores de IPM

do "$folder\3. IPM\code\Calculo\2010\IPM_2010.do"
do "$folder\3. IPM\code\Calculo\2013\IPM_2013.do"
do "$folder\3. IPM\code\Calculo\2016\IPM_2016.do"

/*
Nota: Estos do file construyen las variables de gasto por hogar y dejan solo una persona por hogar, el jefe.

*/

do "$folder\3. IPM\code\Preparación\Malawi_data_prep_2010.do"
do "$folder\3. IPM\code\Preparación\Malawi_data_prep_2013.do"
do "$folder\3. IPM\code\Preparación\Malawi_data_prep_2016.do"


*--- Luego se unen las bases de datos; esto permitirá tener versiones balanceadas
*    y no balanceadas
//Primero se balancea
do "$folder\4.Balancear\code\1_Balanceado_Malawi_Pcorto.do"
do "$folder\4.Balancear\code\2_IPM_Balanceado_Pcorto.do"

do "$folder\4.Balancear\code\1_Balanceado_Malawi.do"
do "$folder\4.Balancear\code\2_IPM_Balanceado.do"

*--- Finalmente, las regresiones para presentar en el artículo están en
* Las bases finales de trabajo son: 
*     * IPM_${BAS}Balanceado{$pc}  $pc \in {"","_pc"} , $BAS \in {"","No"}
*     * IPM_${BAS}Balanceado_super{$pc}  $pc \in {"","_pc"} , $BAS \in {"","No"}
* En realidad, en la versión final SOLO se usa el panel corto
do "$folder\5. Analisis\code\Regresiones y Analisis.do" // Versión de 20220731
do "$folder\5. Analisis\code\Para Tablas.do"            // Algunas cosas aún aplican, de lo que no son regresiones


