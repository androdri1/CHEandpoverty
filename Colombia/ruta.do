***************************************************************
* Ruta.do Corre todos los do para obtener los resultados
*  
* ODS project
*
* Date Created: 20201202
* Name Created: GC
* Last modified: 20210414
*
* Notas:
*  1. 
***************************************************************

*--- Construye los gastos del hogar

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/Gastos/d0/code/gastos.do"


*--- Unión de los micro datos
/*
Nota: 
Este do hace la unión de todos los datos, y me construye los dtas cross-sectional 
para cada ola
*/


do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/Micro dato/d0/code/micro data.do"

*--- Construcción de indicadores de privación

/*
Nota:
Esta sección del do, construye las privaciones de cada indicador.
*/

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/IPM/d1/code/privacion13.do"

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/IPM/d1/code/privacion16.do"

*--- Unión de las dos olas y construyo los datos panel balanceado 

/*
Nota: Este do se va a construir el panel balanceado, y para dejar 
los datos listo para iniciar con su respectivo análisis.
*/

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/Micro dato/d0/code/balanceado.do"


*--- Corrige los años escolares de los individuos 

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/IPM/d1/code/yeareducation.do"

*--- Construye los gastos catastroficos de los hogares

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/Gastos/d0/code/catastrofico.do"


*--- Construye el IPM


do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/ELCA/Stata/IPM/d1/code/calculo IPM.do"
