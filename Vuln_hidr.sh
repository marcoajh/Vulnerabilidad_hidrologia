#
#
#Modelo de vulnerabilidad a inundaciones o escazes
#
#Criterios sociales
#población - Densidad de población (Hab/ha)
##Habitantes por hectárea en cada AGEB
r.stats -lan AGEBp | 
gawk '{printf "%i %s %.4f\n", $1, "=", ($2/($3*0.0001))}' > /home/marco/CVM_SIG/Shells/dens_ageb.rec
r.reclass i=AGEBp o=dens_ageb r=/home/marco/CVM_SIG/Shells/dens_ageb.rec --o
r.mapcalc 'dens_ageb = dens_ageb' --o
r.statistics base=CHA cover=dens_ageb method=sum output=pob_cue --o
##Habitantes en cada cuenca
r.stats -l pob_cue |
gawk '{printf "%i %s %.0f\n", $1, "=", $2}' > /home/marco/CVM_SIG/Shells/pob_cue.rec
r.reclass i=CHA o=pob_cuenca r=/home/marco/CVM_SIG/Shells/pob_cue.rec --o
r.mapcalc 'pob_cuenca = pob_cuenca' --o
g.remove type=raster name=pob_cue -f
#función de valor de Densidad de poblacion por cuenca
r.stats -lan CHA,pob_cuenca | 
gawk '{printf "%i %s %.4f\n", $1, "=", ($3/($4*0.0000000001))}' > /home/marco/CVM_SIG/Shells/sc_pob.rec
r.reclass input=CHA output=sc_Pob rules=/home/marco/CVM_SIG/Shells/sc_pob.rec --o
r.mapcalc 'sc_Pob = sc_Pob*0.000001' --o
MIN=`r.stats -1n sc_Pob | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n sc_Pob | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "sc_Pob = (sc_Pob - "$MIN")/("$MAX" - "$MIN")" --o
#r.mapcalc 'sc_Pob = if(sc_Pob<=0.0625,0.0625,if(sc_Pob<=0.125,0.125,if(sc_Pob<=0.25,0.25,if(sc_Pob<=0.5,0.5,1.00))))' --o
r.colors map=sc_Pob color=rainbow
#Categorización de la función de valor
r.mapcalc 'sc_Pob_5c = if(sc_Pob==0.0625,1,if(sc_Pob==0.125,2,if(sc_Pob==0.25,3,if(sc_Pob==0.5,4,5))))' --o
r.colors map=sc_Pob_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr

#Marginación
r.reclass input=CHA output=sc_Marg rules=/home/marco/CVM_SIG/Shells/sc_marg.rec --o
#Función de valor
r.mapcalc 'sc_Marg = if(sc_Marg==1,0.0625,if(sc_Marg==2,0.125,if(sc_Marg==3,0.25,if(sc_Marg==4,0.5,1.00))))' --o
r.colors map=sc_Marg color=rainbow
#Categorización de la función de valor
r.mapcalc 'sc_Marg_5c = if(sc_Marg==0.0625,1,if(sc_Marg==0.125,2,if(sc_Marg==0.25,3,if(sc_Marg==0.5,4,5))))' --o
r.colors map=sc_Marg_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr
#
#
#Índice de importancia económica (antes Unidades económicas)
#ALONSO-Sergio Flores
r.import input=/media/DATA/CVM_SIG/Indice_Importancia_Economica/IIE.tif output=IIE --o
r.null map=IIE null=0
r.colors map=IIE color=rainbow
r.mapcalc 'IIE = if(AGEB_edos>0,IIE,null())' --o
r.mapcalc 'IIE = int(IIE*100)' --o
r.statistics base=CHA cover=IIE output=CHA_IIE method=max --o
#r.mapcalc 'CHA_IIE = CHA_IIE*0.1' --o
r.colors map=CHA_IIE color=rainbow
r.stats -ln CHA_IIE |
gawk '{printf "%i %s %i\n", $1, "=", $2}' > sc_Uec.rec
r.reclass input=CHA output=sc_Uec rules=/home/marco/CVM_SIG/Shells/sc_Uec.rec --o
r.mapcalc 'sc_Uec = sc_Uec*0.1' --o
MIN=`r.stats -1n sc_Uec | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n sc_Uec | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "sc_Uec = (sc_Uec - "$MIN")/("$MAX" - "$MIN")" --o
r.colors map=sc_Uec color=rainbow
#Categorización de la función de valor
r.mapcalc 'sc_Uec_5c = if(sc_Uec<=0.0625,1,if(sc_Uec<=0.125,2,if(sc_Uec<=0.25,3,if(sc_Uec<=0.5,4,5))))' --o
r.colors map=sc_Uec_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr
#
#
#Combinación de criterios sociales
r.mapcalc 'c_soc = (sc_Pob*0.59363)+(sc_Marg*0.24931)+(sc_Uec*0.15706)' --o
#Normalización
MIN=`r.stats -1n c_soc | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n c_soc | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "c_soc = (c_soc - "$MIN")/("$MAX" - "$MIN")" --o
r.colors map=c_soc color=rainbow
#Categorización del mapa de criterios sociales
r.mapcalc 'c_soc_5c = if(c_soc<=0.0625,1,if(c_soc<=0.125,2,if(c_soc<=0.25,3,if(c_soc<=0.5,4,5))))' --o
r.colors map=c_soc_5c rules=/home/marco/CVM_SIG/Shells/color_vuln.clr
#
#Criterios de infraestructura
#
#Red
r.reclass input=CHA output=sc_Red rules=/home/marco/CVM_SIG/Shells/sc_red.rec --o
r.mapcalc 'sc_Red = sc_Red*0.000001' --o
r.colors map=sc_Red color=rainbow
#
#Categorización de la función de valor
r.mapcalc 'sc_Red_5c = if(sc_Red<=0.0625,1,if(sc_Red<=0.125,2,if(sc_Red<=0.25,3,if(sc_Red<=0.5,4,5))))' --o
r.colors map=sc_Red_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr
#
#Pozos
#EDITH
#r.reclass input=CHA output=Caudal_p rules=/home/marco/CVM_SIG/Shells/sc_caudalp.rec --o
#r.mapcalc 'Caudal_p = Caudal_p*0.000001' --o
r.reclass input=CHA output=Num_p rules=/home/marco/CVM_SIG/Shells/sc_nump.rec --o
r.mapcalc 'Num_p = Num_p*0.000001' --o
#Categorización de la función de valor
#r.mapcalc 'Num_p_5c = if(Num_p<=0.0625,1,if(Num_p<=0.125,2,if(Num_p<=0.25,3,if(Num_p<=0.5,4,5))))' --o
#
#Falta conseguir datos para caudal de pozos
#
#Combinación del subcriterio Pozos
#r.mapcalc 'sc_Pozos = (Caudal_p*0.5) + (Num_p*0.5)' --o
r.mapcalc 'sc_Pozos = Num_p' --o
#Normalización
MIN=`r.stats -1n sc_Pozos | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n sc_Pozos | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "sc_Pozos = (sc_Pozos - "$MIN")/("$MAX" - "$MIN")" --o
r.colors map=sc_Pozos color=rainbow
#
#Categorización de la función de valor
r.mapcalc 'sc_Pozos_5c = if(sc_Pozos<=0.0625,1,if(sc_Pozos<=0.125,2,if(sc_Pozos<=0.25,3,if(sc_Pozos<=0.5,4,5))))' --o
r.colors map=sc_Pozos_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr
#
#
#
#Tratamiento
#EDITH
#Combinación del subcriterio Tratamiento
r.reclass input=CHA output=Caudal_t rules=/home/marco/CVM_SIG/Shells/sc_caudalt.rec --o
r.mapcalc 'Caudal_t = Caudal_t*0.000001' --o
r.reclass input=CHA output=Num_t rules=/home/marco/CVM_SIG/Shells/sc_numt.rec --o
r.mapcalc 'Num_t = Num_t*0.000001' --o
#
r.mapcalc 'sc_Trat =  (Caudal_t*0.5) + (Num_t*0.5)' --o
#Normalización
MIN=`r.stats -1n sc_Trat | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n sc_Trat | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "sc_Trat = (sc_Trat - "$MIN")/("$MAX" - "$MIN")" --o
r.colors map=sc_Trat color=rainbow
#
#Categorización de la función de valor
r.mapcalc 'sc_Trat_5c = if(sc_Trat<=0.0625,1,if(sc_Trat<=0.125,2,if(sc_Trat<=0.25,3,if(sc_Trat<=0.5,4,5))))' --o
r.colors map=sc_Trat_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr
#
#
#Combinación de criterios de infraestructura
r.mapcalc 'c_infra = (sc_Pozos*0.59363)+(sc_Red*0.15706)+(sc_Trat*0.24931)' --o
#Normalización
MIN=`r.stats -1n c_infra | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n c_infra | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "c_infra = (c_infra - "$MIN")/("$MAX" - "$MIN")" --o
r.colors map=c_infra color=rainbow
#
#Categorización del mapa del criterio infraestructura
r.mapcalc 'c_infra_5c = if(c_infra<=0.0625,1,if(c_infra<=0.125,2,if(c_infra<=0.25,3,if(c_infra<=0.5,4,5))))' --o
r.colors map=c_infra_5c rules=/home/marco/CVM_SIG/Shells/color_vuln.clr
#
#
#Criterios de urbanización
#Percolación
r.reclass input=CHA output=sc_Perc rules=/home/marco/CVM_SIG/Shells/sc_perc.rec --o
r.mapcalc 'sc_Perc = 1-(sc_Perc*0.000001)' --o
r.colors map=sc_Perc color=rainbow
#
#Categorización de la función de valor
r.mapcalc 'sc_Perc_5c = if(sc_Perc<=0.0625,1,if(sc_Perc<=0.125,2,if(sc_Perc<=0.25,3,if(sc_Perc<=0.5,4,5))))' --o
r.colors map=sc_Perc_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr
#
#Área urbana
r.reclass input=CHA output=sc_Urb rules=/home/marco/CVM_SIG/Shells/sc_urb.rec --o
r.mapcalc 'sc_Urb = sc_Urb*0.000001' --o
r.colors map=sc_Urb color=rainbow
#
#Categorización de la función de valor
r.mapcalc 'sc_Urb_5c = if(sc_Urb<=0.0625,1,if(sc_Urb<=0.125,2,if(sc_Urb<=0.25,3,if(sc_Urb<=0.5,4,5))))' --o
r.colors map=sc_Urb_5c rules=/home/marco/CVM_SIG/Shells/color_fv.clr
#
#
#Combinación de criterios de Urbanización
r.mapcalc 'c_Urba = (sc_Perc*0.25)+(sc_Urb*0.75)' --o
#Normalización
MIN=`r.stats -1n c_Urba | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n c_Urba | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "c_Urba = (c_Urba - "$MIN")/("$MAX" - "$MIN")" --o
r.colors map=c_Urba color=rainbow
#
#Categorización del mapa del criterio Urbanización
r.mapcalc 'c_Urba_5c = if(c_Urba<=0.0625,1,if(c_Urba<=0.125,2,if(c_Urba<=0.25,3,if(c_Urba<=0.5,4,5))))' --o
r.colors map=c_Urba_5c rules=/home/marco/CVM_SIG/Shells/color_vuln.clr
#
#
#
#Combinación general
#
r.mapcalc 'Vuln_hidro = (c_soc*0.41260)+(c_infra*0.32748)+(c_Urba*0.25992)' --o
#Normalización
MIN=`r.stats -1n Vuln_hidro | gawk 'NR==1 { MIN=$1; next }  $1 < MIN { MIN=$1 } END{ print MIN }'`
MAX=`r.stats -1n Vuln_hidro | gawk 'NR==1 { MAX=$1; next } $1 > MAX { MAX=$1 } END{ print MAX }'`
r.mapcalc "Vuln_hidro = (Vuln_hidro "$MIN")/("$MAX" - "$MIN")" --o
#Normalización
r.colors map=Vuln_hidro color=rainbow
#Categorización del mapa de vulnerabilidad
r.mapcalc 'Vuln_hidro_5c = if(Vuln_hidro<=0.0625,1,if(Vuln_hidro<=0.125,2,if(Vuln_hidro<=0.25,3,if(Vuln_hidro<=0.5,4,5))))' --o
r.colors map=Vuln_hidro_5c rules=/home/marco/CVM_SIG/Shells/color_vuln.clr
#
#
#
#
