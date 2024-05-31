***********************************************************************
* 			        building a map, consortia			   	          *					  
***********************************************************************
*																	  
*	PURPOSE: file for building a map for webscrapped firms data								  
*																	  
*	OUTLINE: 	PART 1: Install packages		  
*				PART 2: Prepare the data	  
*				PART 3: Draw Map                     											  
*																	  
*	Author:  						    
*	ID variable: 		  					  
*	Requires:  	  										  
*	Creates:  
***********************************************************************
* 	PART 1: 	Install package			  
***********************************************************************
	* install map package
/*
ssc install spmap, replace

ssc install geo2xy, replace     

ssc install palettes, replace        

ssc install colrspace, replace

ssc install schemepack, replace

ssc install geodist, replace

ssc install outreg2, replace
*/

set graph on
set scheme white_tableau
***********************************************************************
* 	PART 2: 	Prepare the data
************************************************************************
*import excel lat & long
import excel "${map_raw}/consortia_adresse_modified_postlocation", firstrow clear

*destring longitude & latitude
destring latitude, generate(new_latitude) 
destring longitude, generate(new_longitude)

*merge with master data to get treatment, takeup & sector
merge 1:m id_plateforme using "${master_final}/consortium_final", keepusing(surveyround treatment take_up subsector_corrige pole gouvernorat)
keep if surveyround == 2
drop _merge

*save .dta
save "${map_output}/coordinates", replace
clear

*merge with harmonize data to get product category
*import excel
import excel "${harmonize}/cepex_produits.xlsx", firstrow clear
save "${harmonize}/cepex_produits.dta", replace

use "${map_output}/coordinates"

merge 1:1 id_plateforme using "${harmonize}/cepex_produits.dta", keepusing(product_hom1_eng product_hom2_eng product_hom3_eng)
drop _merge

*save .dta
save "${map_output}/coordinates", replace
clear

*chose directory
cd "${map_output}"

*transform shape data to .dta
spshape2dta TN_regions, replace saving(tunisia)

*use
use "${map_output}/tunisia", replace

***********************************************************************
* 	PART 3: 	Draw map whole Tunisia
***********************************************************************
{
*initiate PDF
putpdf clear
putpdf begin, pagesize(A3)
putpdf paragraph

putpdf text ("Consortia: Firms Distribution Map"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak
putpdf paragraph, halign(center) 

	
*draw the map whole tunis by treatment
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisia_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisia_treatment.png
putpdf pagebreak

*draw the map whole tunis by take-up
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(take_up) select(keep if treatment == 1) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("consorita firms by take-up", size(*1.2))
graph export map_consortiaTunisia_takeup.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisia_takeup.png
putpdf pagebreak

*draw the map whole tunis by pole
	*pôle d'activités agri-agroalimentaire 2
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(take_up) select(keep if subsector_corrige == 2 & treatment == 1) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Agro consorita firms by take-up", size(*1.2))
graph export map_consortiaTunisiaAggro_takeup.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaAggro_takeup.png
putpdf pagebreak

	*pôle d'activités artisanat 3
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(take_up) select(keep if subsector_corrige == 3 & treatment == 1) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Artisanat consorita firms by take-up", size(*1.2))
graph export map_consortiaTunisiaArtisanat_takeup.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaArtisanat_takeup.png
putpdf pagebreak

	*pôle d'activités cosmétiques 4
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(take_up) select(keep if subsector_corrige == 4 & treatment == 1) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Cosmetics consorita firms by take-up", size(*1.2))
graph export map_consortiaTunisiaCosmetics_takeup.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaCosmetics_takeup.png
putpdf pagebreak

	*pôle d'activités de service conseil, ed 6
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(take_up) select(keep if subsector_corrige == 6 & treatment == 1) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Service consorita firms by take-up", size(*1.2))
graph export map_consortiaTunisiaService_takeup.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaService_takeup.png
putpdf pagebreak

/*
	*pôle de l'énergie durable et développem 8
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(take_up) select(keep if subsector_corrige == 8 & treatment == 1) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Energy consorita firms by take-up", size(*1.2))
graph export map_consortiaTunisiaEnergy_takeup.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaEnergy_takeup.png
putpdf pagebreak
*/

	*pôle d'activités technologies de l'info 9
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(take_up) select(keep if subsector_corrige == 9 & treatment == 1) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("TIC consorita firms by take-up", size(*1.2))
graph export map_consortiaTunisiaInfo_takeup.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaInfo_takeup.png
putpdf pagebreak

***********************************************************************
* 	PART 4: 	Draw map parts of tunisia
***********************************************************************
*transform shape data to .dta
spshape2dta TN_districts, replace saving(tunisia_regions)

*use
use "${map_output}/tunisia_regions", replace

*extract labels that need to be on seperate .dta
preserve

keep _ID _CY _CX dis_en
compress
keep if dis_en == "Tunis 1" | dis_en == "Tunis 2" |  dis_en == "Ariana" | dis_en == "Ben Arous" | dis_en == "Mannouba"
replace _CX = _CX - 0.04 if dis_en=="Tunis 1"  // Tunis1 label
replace _CY = _CY - 0.025 if dis_en=="Tunis 2"  // Tunis 2 label

save tunis_labels, replace

restore

*Tunis
spmap using tunisia_regions_shp if _ID == 1 | _ID == 2 | _ID == 3| _ID == 4 | _ID == 5, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if gouvernorat == 20 | gouvernorat == 10) by(treatment) size(v.Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	label(data(tunis_labels) x(_CX) y(_CY) label(dis_en)) ///
	title("Grand Tunis consorita firms by treatment", size(*1.2))
graph export map_consortiaTunis_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunis_treatment.png
putpdf pagebreak

*Tunis by consorta

*Tunis Agro
spmap using tunisia_regions_shp if _ID == 1 | _ID == 2 | _ID == 3| _ID == 4 | _ID == 5, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if (gouvernorat == 20 | gouvernorat == 10) & subsector_corrige == 2 ) by(treatment) size(v.Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	label(data(tunis_labels) x(_CX) y(_CY) label(dis_en)) ///
	title("Tunis Agro consorita firms by treatment", size(*1.2))
graph export map_consortiaTunis_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunis_treatment.png
putpdf pagebreak

*Tunis Artisanat
spmap using tunisia_regions_shp if _ID == 1 | _ID == 2 | _ID == 3| _ID == 4 | _ID == 5, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if (gouvernorat == 20 | gouvernorat == 10) & subsector_corrige == 3 ) by(treatment) size(v.Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	label(data(tunis_labels) x(_CX) y(_CY) label(dis_en)) ///
	title("Tunis Artisanat consorita firms by treatment", size(*1.2))
graph export map_consortiaTunis_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunis_treatment.png
putpdf pagebreak

*Tunis Cosmétique
spmap using tunisia_regions_shp if _ID == 1 | _ID == 2 | _ID == 3| _ID == 4 | _ID == 5, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if (gouvernorat == 20 | gouvernorat == 10) & subsector_corrige == 4 ) by(treatment) size(v.Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	label(data(tunis_labels) x(_CX) y(_CY) label(dis_en)) ///
	title("Tunis Cometics consorita firms by treatment", size(*1.2))
graph export map_consortiaTunis_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunis_treatment.png
putpdf pagebreak

*Tunis Conseil
spmap using tunisia_regions_shp if _ID == 1 | _ID == 2 | _ID == 3| _ID == 4 | _ID == 5, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if (gouvernorat == 20 | gouvernorat == 10) & subsector_corrige == 6 ) by(treatment) size(v.Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	label(data(tunis_labels) x(_CX) y(_CY) label(dis_en)) ///
	title("Tunis Service consorita firms by treatment", size(*1.2))
graph export map_consortiaTunis_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunis_treatment.png
putpdf pagebreak

*Tunis Energy
spmap using tunisia_regions_shp if _ID == 1 | _ID == 2 | _ID == 3| _ID == 4 | _ID == 5, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if (gouvernorat == 20 | gouvernorat == 10) & subsector_corrige == 8 ) by(treatment) size(v.Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	label(data(tunis_labels) x(_CX) y(_CY) label(dis_en)) ///
	title("Tunis Energy consorita firms by treatment", size(*1.2))
graph export map_consortiaTunis_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunis_treatment.png
putpdf pagebreak

*Tunis TIC
spmap using tunisia_regions_shp if _ID == 1 | _ID == 2 | _ID == 3| _ID == 4 | _ID == 5, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if (gouvernorat == 20 | gouvernorat == 10) & subsector_corrige == 9 ) by(treatment) size(v.Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	label(data(tunis_labels) x(_CX) y(_CY) label(dis_en)) ///
	title("Tunis TIC consorita firms by treatment", size(*1.2))
graph export map_consortiaTunis_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunis_treatment.png
putpdf pagebreak

*Sfax
spmap using tunisia_regions_shp if _ID == 17 | _ID == 18, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if gouvernorat == 30) by(treatment) size(Small ..) legenda(on) legcount) ///
	legend(pos(5) size(*1.8) rowgap(1.2)) ///
	title("Sfax consorita firms by treatment", size(*1.2))
graph export map_consortiaSfax_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaSfax_treatment.png
putpdf pagebreak

*Sousse
spmap using tunisia_regions_shp if _ID == 14, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if gouvernorat == 40) by(treatment) size(Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Sousse consorita firms by treatment", size(*1.2))
graph export map_consortiaSousse_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaSousse_treatment.png
putpdf pagebreak

*Kairaouan
spmap using tunisia_regions_shp if _ID == 19, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if gouvernorat == 31) by(treatment) size(Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Kairaouan consorita firms by treatment", size(*1.2))
graph export map_consortiaKairaouan_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaKairaouan_treatment.png
putpdf pagebreak

*Monastir
spmap using tunisia_regions_shp if _ID == 15, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if gouvernorat == 50) by(treatment) size(Small ..) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Monastir consorita firms by treatment", size(*1.2))
graph export map_consortiaMonastir_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaMonastir_treatment.png
putpdf pagebreak

*Kasserine
spmap using tunisia_regions_shp if _ID == 20, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) ocolor(white ..) select(keep if gouvernorat == 12) by(treatment) size(Small ..) legenda(on) legcount) ///
	legend(pos(5) size(*1.8) rowgap(1.2)) ///
	title("Kasserine consorita firms by treatment", size(*1.2))
graph export map_consortiaKasserine_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaKasserine_treatment.png

putpdf save "consortia_firmsmap", replace

}

***********************************************************************
* 	PART 5: 	Create graphs
***********************************************************************
{
*initiate PDF
putpdf clear
putpdf begin, pagesize(A3)
putpdf paragraph

putpdf text ("Consortia: Firms Distribution Map 2"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak
putpdf paragraph, halign(center)

*draw the map whole tunis by take-up
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisia_treat.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisia_treat.png
putpdf pagebreak

*draw the map whole tunis by pole
	*pôle d'activités agri-agroalimentaire 2
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) select(keep if subsector_corrige == 2) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Agro consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisiaAggro_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaAggro_treatment.png
putpdf pagebreak

	*pôle d'activités artisanat 3
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) select(keep if subsector_corrige == 3) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Artisanat consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisiaArtisanat_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaArtisanat_treatment.png
putpdf pagebreak

	*pôle d'activités cosmétiques 4
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) select(keep if subsector_corrige == 4) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Cosmetics consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisiaCosmetics_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaCosmetics_treatment.png
putpdf pagebreak

	*pôle d'activités de service conseil, ed 6
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) select(keep if subsector_corrige == 6) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Service consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisiaService_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaService_treatment.png
putpdf pagebreak

	*pôle de l'énergie durable et développem 8
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) select(keep if subsector_corrige == 8) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("Energy consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisiaEnergy_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaEnergy_treatment.png
putpdf pagebreak

	*pôle d'activités technologies de l'info 9
spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(treatment) select(keep if subsector_corrige == 9) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("TIC consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisiaInfo_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaInfo_treatment.png
putpdf pagebreak

spmap using tunisia_shp, id(_ID) fcolor(eggshell) point(data("coordinates.dta") xcoord(new_longitude) ycoord(new_latitude) fcolor(red%50 navy%50) size(1.5) ocolor(white ..) osize(*0.5) by(product_hom3_eng) select(keep if subsector_corrige == 9) legenda(on) legcount) ///
	legend(size(*1.8) rowgap(1.2)) ///
	title("TIC consorita firms by treatment", size(*1.2))
graph export map_consortiaTunisiaInfo_treatment.png, replace
putpdf paragraph, halign(center)
putpdf image map_consortiaTunisiaInfo_treatment.png
putpdf pagebreak


putpdf save "consortia_firmsmap2", replace

}

	*products

***********************************************************************
* 	PART 6: 	Calculate distance
***********************************************************************
*load data
use "${map_output}/coordinates", replace

*average pole agro
preserve

drop if pole != 1

forvalues i = 1/`=_N' {
    scalar lat0 = new_latitude[`i']
    scalar lon0 = new_longitude[`i']
    local id = id_plateforme[`i']
    geodist lat0 lon0 new_latitude new_longitude, gen(d`id')

}

egen avgdist_agro = rowtotal(d*)
replace avgdist_agro = avgdist_agro/(_N-1)  // no self distance
replace avgdist_agro = avgdist_agro

sum avgdist_agro

restore


*average pole artisanat
preserve

drop if pole != 2

forvalues i = 1/`=_N' {
    scalar lat0 = new_latitude[`i']
    scalar lon0 = new_longitude[`i']
    local id = id_plateforme[`i']
    geodist lat0 lon0 new_latitude new_longitude, gen(d`id')

}

egen avgdist_artisanat = rowtotal(d*)
replace avgdist_artisanat = avgdist_artisanat/(_N-1)  // no self distance
replace avgdist_artisanat = avgdist_artisanat
sum avgdist_artisanat

restore

*average pole service
preserve

drop if pole != 3

forvalues i = 1/`=_N' {
    scalar lat0 = new_latitude[`i']
    scalar lon0 = new_longitude[`i']
    local id = id_plateforme[`i']
    geodist lat0 lon0 new_latitude new_longitude, gen(d`id')

}

egen avgdist_service = rowtotal(d*)
replace avgdist_service = avgdist_service/(_N-1)  // no self distance
replace avgdist_service = avgdist_service

sum avgdist_service

restore

*average pole TIC
preserve

drop if pole != 4

forvalues i = 1/`=_N' {
    scalar lat0 = new_latitude[`i']
    scalar lon0 = new_longitude[`i']
    local id = id_plateforme[`i']
    geodist lat0 lon0 new_latitude new_longitude, gen(d`id')

}

egen avgdist_TIC = rowtotal(d*)
replace avgdist_TIC = avgdist_TIC/(_N-1)  // no self distance
replace avgdist_TIC = avgdist_TIC

sum avgdist_TIC

restore