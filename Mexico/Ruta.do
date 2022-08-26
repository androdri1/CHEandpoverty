***************************************************************
* Ruta.do Corre todos los do para obtener los resultados
*  
* ODS project
*
* Date Created: 20201022
* Name Created: GC
* Last modified: 
*
* Notas:
*  1. 
***************************************************************



*--- Unión de los micro datos
/*
Nota: 
Este do hace la unión de todos los datos, y me construye los dtas cross-sectional 
para cada ola
*/

do "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/Micro dato/d1/code/merge.do"

*--- Construcción de indicadores de privación

/*
Nota:
Esta sección del do, construye las privaciones de cada indicador.
*/

*-- Primera ola (2002)

do "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/IPM/2002/d1/code/Indicadores 2002.do"


*-- Segunda ola (2006)

do "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/IPM/2006/d1/code/Indicadores 2006.do"

*-- Tercera ola (2012)

do "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/IPM/2012/d1/code/Indicadores 2012.do"


*--- Unión de las tres olas y construyo los datos panel balanceado 

/*
Nota: Este do se va a construir el panel balanceado, y para dejar 
los datos listo para iniciar con su respectivo análisis.
*/

do "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/Balanceado/d1/code/balanceado.do"


*--- Creación de gastos y gastos catastroficos

do "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/Gastos/d1/code/catastrofico balanceado.do"


*--- Creación IPM 


do "/Users/gustavoco36/Dropbox/Investigaciones/Proyectos/Proyecto ODS/Datos/Mexico/Stata/IPM/balanceado/d2/code/calculo IPM.do"













