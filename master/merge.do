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
* 	PART 4: merge & append to create analysis data set
***********************************************************************
		* change directory to master folder for merge with regis + baseline (final)
cd "$master_raw"

	* merge registration with baseline data

clear 

use "${regis_final}/regis_final", clear

merge 1:1 id_plateforme using "${bl_final}/bl_final"

keep if _merge==3
drop _merge

    * save as ecommerce_database

save "consortium_database_raw", replace

/*
	* append registration +  baseline data with midline
cd "$midline_final"
append using ml_final


	* append with endline
cd "$endline_final"
append using el_final


***********************************************************************
* 	PART 5: merge with participation data
***********************************************************************

*Note: here should the Suivi_mise_en_oeuvre_consortium.xlsx be downloaded from teams, legend deleted, renamed and uploaded again in 6-master
clear 
import excel "${master_gdrive}/Suivi_consortium.xlsx", sheet("Suivi_formation") firstrow clear
keep id_plateforme groupe module1 module2 module3 module4 module5
drop if id_plateforme== ""
drop if id_plateforme== "id_plateforme"
drop _merge
encode id_plateforme, generate(id_plateforme2)
drop id_plateforme
rename id_plateforme2 id_plateforme
merge 1:1 id_plateforme using "${master_raw}/consortium_database_raw"

    * save as ecommerce_database

save "consortium_database_raw", replace

***********************************************************************
* 	PART 6: 
***********************************************************************



