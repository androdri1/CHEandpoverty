****************************************************************
* Ruta.do Se corre todos los do-files de India
*
* Date Created: 20210510
* Name Created: GC
* Last modified: 
*
* Notas:
*  1. 
***************************************************************


*** Unión del panel, construcción de gastos y balanceado

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/India/Code/Panel/Code/balanceado_2.do"


*** Construcción de privaciones de la pobreza multidimensional 

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/India/Code/IPM/Code/privaciones.do"

*** Construcción de tablas de diferencias de gastos en lo hogares de India



do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/India/Code/Gastos/d0/code/Tablas.do"

e

*** Construcción de IPM 

do "/Users/gustavoco36/Dropbox/Proyecto ODS/Datos/India/Code/IPM/Code/calculo IPM.do"
