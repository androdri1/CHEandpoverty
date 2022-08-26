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


*glo folder="C:\Users\jujog\Dropbox\Proyecto ODS\Datos\Tanzania\Stata"
glo folder="D:\Paul.Rodriguez\Dropbox\Salud Colombia\Proyecto ODS\Datos\Tanzania\Stata"


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

do "$folder\1. Union por Años\code\Union Año a Año\Año2008.do"
do "$folder\1. Union por Años\code\Union Año a Año\Año2010.do"
do "$folder\1. Union por Años\code\Union Año a Año\Año2012.do"
do "$folder\1. Union por Años\code\Union Año a Año\Año2014.do"

/*
Nota:
Aqui se constuyen todas las variables de gastos para todos los años.
*/
do "$folder\2. Gasto Catastrófico\code\GastoC.do"

*--- Aqui se generan los indicadores de IPM
do "$folder\3.IPM\code\Preparación\2010\data_prep_personas_10.do"
do "$folder\3.IPM\code\Preparación\2012\data_prep_personas_12 mp.do"
do "$folder\3.IPM\code\Preparación\2015\data_prep_personas_15.do"

*--- SI se quiere hacer el IPM por año se utilizan estos. --- Paul: todavia no se bien que hacen

do "$folder\3.IPM\code\Calculo\2008\IPM_08.do"
do "$folder\3.IPM\code\Calculo\2010\IPM_10.do"
do "$folder\3.IPM\code\Calculo\2012\IPM_12.do"

*--- Luego se unen las bases de datos; esto permitirá tener versiones balanceadas
*    y no balanceadas
//Primero se balancea. Desde: data_prep_10, data_prep_12, data_prep_15
do "$folder\4.Balancear\code\1 UnirAnios.do"       // Produce data_prep_completa
do "$folder\4.Balancear\code\2 IPM_Balanceado.do"  // IPM_Balanceado_super , IPM_NoBalanceado_super


*--- Finalmente, las regresiones para presentar en el artículo están en
* El default es el panel balanceado, y el no balanceado se usa como un robustness
// Input: IPM_Balanceado_super
do "$folder\5. Analisis\code\Regresiones y Analisis.do" 


