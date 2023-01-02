************************************************************************
* 			Consortium - master merge									  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible, merge & analysis survey 
*            & pii data related to consoritum program Tunisia
*  
*	OUTLINE: 	PART I: PII data   
*					PART 1: combine pii data from regis, bl, ml, el  
*					PART 2: integrate pii updates         
*
*				PART II: Analysis data					  
*					Part 3: append regis + bl, ml, el									
*					Part 4: integrate take-up data
*
*	Author:  		Florian Münch				    
*	ID variable: 	id_plateforme (panel unit id), surveyround (panel time id)
*	Requires: consortia_bl_pii.dta	consortia_regis_pii.dta										  
*	Creates:  contact_info_master.dta, consortium_raw.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
	                                  
***********************************************************************
* 	PART 1: merge & append to create master data set (pii)
***********************************************************************
	* merge registration with baseline data
use "${regis_final}/consortia_regis_pii", clear
				
		* merge 1:1 based on project id_plateforme
merge 1:1 id_plateforme using "${bl_raw}/consortia_bl_pii"

			*drop unselected firms from registration
drop if _merge<3


/*
		* merge 1:1  with midline
merge 1:1 id_plateforme using "${ml_raw}/consortia_ml_pii"


		* merge 1:1 with endline
merge 1:1 id_plateforme using "${el_raw}/consortia_el_pii"

*/

	* save as Consortium_contact_info_master
save "${master_gdrive}/contact_info_master", replace

/*
***********************************************************************
* 	PART2: integrate and replace contact updates (pii)
***********************************************************************
*Note: the Update_file.xlsx be downloaded from teams, renamed and uploaded again in 6-master

clear
import excel "${master_gdrive}/Update_file.xlsx", sheet("update_entreprises") firstrow clear

merge 1:1 id_plateforme using "${master_gdrive}/contact_info_master"
drop _merge
duplicates drop 
save "${master_gdrive}/contact_info_master", replace


*/

***********************************************************************
********************* II: Analysis data *******************************
***********************************************************************	

***********************************************************************
* 	PART 3: merge to create analysis data set (analysis data)
***********************************************************************
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
save "${master_raw}/consortium_raw", replace

***********************************************************************
* 	PART 4: append analysis data set with midline & endline
***********************************************************************

/*
	* append registration +  baseline data with midline
append using "${midline_final/ml_final}

	* append with endline
append using "${endline_final/el_final}"
*/


***********************************************************************
* 	PART 5: merge with participation data (THIS CODE NEEDS TO BE UPDATED ONCE MIDLINE DATA HAS BEEN COLLECTED)
***********************************************************************
*Note: here should the Présence des ateliers.xlsx be downloaded from teams, renamed and uploaded again in 6-master
		*  import participation data
import excel "${master_gdrive}/presence_ateliers.xlsx", firstrow clear

		* remove blank lines
drop if id_plateforme==.

		* select take-up variables
keep id_plateforme Webinaire_de_lancement Rencontre1_Atelier1 Rencontre1_Atelier2 Rencontre2_Atelier1 Rencontre2_Atelier2 Rencontre3_Atelier1 Rencontre3_Atelier2

		* merge to analysis data
merge 1:1 id_plateforme using "${master_raw}/consortium_raw", force
drop _merge
order Webinaire_de_lancement Rencontre1_Atelier1 Rencontre1_Atelier2 Rencontre2_Atelier1 Rencontre2_Atelier2 Rencontre3_Atelier1 Rencontre3_Atelier2, last

    * save as consortium_database
save "${master_raw}/consortium_raw", replace