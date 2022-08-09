***********************************************************************
* 			Consortium - master merge									  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible, merge & analysis survey 
*            & pii data related to consoritum program Tunisia
*  
*	OUTLINE: 	PART 1:   
*				PART 2: 	  
*				PART 3:               
*																	  
*																	  
*	Author:  						    
*	ID variable: 	id_plateforme			  					  
*	Requires: consortia_bl_pii.dta	consortia_regis_pii.dta										  
*	Creates:  contact_info_master.dta			                                  
***********************************************************************
* 	PART 1: merge & append to create master data set (pii)
***********************************************************************
	* merge registration with baseline data
use "${regis_final}/consortia_regis_pii", clear
		
		* change directory to baseline folder for merge with baseline_final
cd "$bl_raw"

tostring id_plateforme, gen(id_plateforme2) format(%15.0f)
        drop id_plateforme
        ren id_plateforme2 id_plateforme
		
		* merge 1:1 based on project id_plateforme
merge 1:1 id_plateforme using consortia_bl_pii


drop _merge

/*
	* append registration +  baseline data with midline
cd "$midline_final"
append using ml_final


	* append with endline
cd "$endline_final"
append using el_final
*/

***********************************************************************
* 	PART 2: save as Consortium_contact_info_master
***********************************************************************
cd "$master_gdrive"
save "contact_info_master", replace

/*
***********************************************************************
* 	PART 3: integrate and replace contact updates
***********************************************************************
*Note: here should the Update_file.xlsx be downloaded from teams, renamed and uploaded again in 6-master

clear
import excel "${master_gdrive}/Update_file.xlsx", sheet("update_entreprises") firstrow clear

merge 1:1 id_plateforme using contact_info_master
drop _merge
duplicates drop 
save "contact_info_master", replace
*/
***********************************************************************
* 	PART 4: merge to create analysis data set
***********************************************************************
		* change directory to master folder for merge with regis + baseline (final)
cd "$master_raw"

	* merge registration with baseline data

clear 

use "${regis_final}/regis_final", clear
drop treatment /* as it's just missing values in the registration data & in case we keep it then it will replace the data in the using file when merged*/

merge 1:1 id_plateforme using "${bl_final}/bl_final"

keep if _merge==3 /* companies that were eligible and answered on the registration + baseline surveys */
drop _merge

    * create panel ID
gen surveyround=1
 
    * save as consortium_database

save "consortium_database_raw", replace

***********************************************************************
* 	PART 5: append analysis data set with midline & endline
***********************************************************************


/*
	* append registration +  baseline data with midline
cd "$midline_final"
append using ml_final


	* append with endline
cd "$endline_final"
append using el_final
*/


***********************************************************************
* 	PART 6: merge with participation data
***********************************************************************

*Note: here should the Présence des ateliers.xlsx be downloaded from teams, renamed and uploaded again in 6-master

* 1st merge with Groupe Agri-Agro:
clear 
import excel "${master_gdrive}/suivi_consortium.xlsx", sheet("Groupe Agri-Agro") firstrow clear
keep id_plateforme Gouvernorat GroupeAgroRencontre10905 GroupeAgroRencontre11005 Réponsequestionnaire GroupeAgroRencontre22405
merge 1:1 id_plateforme using "${master_raw}/consortium_database_raw", force
drop _merge
order GroupeAgroRencontre10905 GroupeAgroRencontre11005 Réponsequestionnaire GroupeAgroRencontre22405, last
    * save as consortium_database

save "consortium_database_raw", replace


* 2nd merge with Groupe Artisanat:
clear 
import excel "${master_gdrive}/suivi_consortium.xlsx", sheet("Groupe Artisanat") firstrow clear
rename I GroupeArtisanatRencontre2
keep id_plateforme Gouvernorat GroupeArtisanatRencontre1 GroupeArtisanatRencontre2
merge 1:1 id_plateforme using "${master_raw}/consortium_database_raw", force
drop _merge
order GroupeArtisanatRencontre1 GroupeArtisanatRencontre2, last
    
    * save as consortium_database

save "consortium_database_raw", replace


* 3d merge with Groupe Services:
clear 
import excel "${master_gdrive}/suivi_consortium.xlsx", sheet("Groupe Services") firstrow clear
rename I GroupeServicesRencontre2
rename GroupeServicesRencontre11 GroupeServicesRencontre1
keep id_plateforme Gouvernorat GroupeServicesRencontre1 GroupeServicesRencontre2
merge 1:1 id_plateforme using "${master_raw}/consortium_database_raw", force
drop _merge
order GroupeServicesRencontre1 GroupeServicesRencontre2, last
    
    * save as consortium_database

save "consortium_database_raw", replace

* 4th merge with Groupe TIC:
clear 
import excel "${master_gdrive}/suivi_consortium.xlsx", sheet("Groupe TIC") firstrow clear
keep id_plateforme Gouvernorat GroupeTICRencontre11205 GroupeTICRencontre11305
merge 1:1 id_plateforme using "${master_raw}/consortium_database_raw", force
drop _merge
order GroupeTICRencontre11205 GroupeTICRencontre11305, last
    
    * save as consortium_database

save "consortium_database_raw", replace


* 5th merge with Webinaire:
clear 
import excel "${master_gdrive}/suivi_consortium.xlsx", sheet("Webinaire") firstrow clear
keep id_plateforme Gouvernorat PrésenceWebinairedelancement Commentaires
merge 1:1 id_plateforme using "${master_raw}/consortium_database_raw", force
drop _merge
order PrésenceWebinairedelancement Commentaires, last
order treatment    
    * save as consortium_database

save "consortium_database_raw", replace
