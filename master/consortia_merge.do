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
drop _merge

		* add treatment status after bl randomization
merge 1:1 id_plateforme using "${bl_final}/bl_final", keepusing(treatment)



		* merge 1:1  with midline
*merge 1:1 id_plateforme using "${ml_raw}/consortia_ml_pii"

/*
		* merge 1:1 with endline
merge 1:1 id_plateforme using "${el_raw}/consortia_el_pii"

*/

	* save as Consortium_contact_info_master
save "${master_raw}/consortium_pii_raw", replace

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
use "${regis_final}/regis_final", clear
drop treatment /* as it's just missing values in the registration data & in case we keep it then it will replace the data in the using file when merged*/

merge 1:1 id_plateforme using "${bl_final}/bl_final"

keep if _merge==3 /* companies that were eligible and answered on the registration + baseline surveys */
drop _merge

    * create panel ID
gen surveyround=1
lab def round  1 "baseline" 2 "midline" 3 "endline"
lab val surveyround round
 
    * save as consortium_database
save "${master_raw}/consortium_raw", replace

***********************************************************************
* 	PART 4: append analysis data set with midline & endline
***********************************************************************


	* append registration +  baseline data with midline
*append using "${midline_final/ml_final}

/*	* append with endline
append using "${endline_final/el_final}"
*/


***********************************************************************
* 	PART 5: merge with participation data (THIS CODE NEEDS TO BE UPDATED ONCE MIDLINE DATA HAS BEEN COLLECTED)
***********************************************************************
*Note: here should the Présence des ateliers.xlsx be downloaded from teams, renamed and uploaded again in 6-master
		*  import participation data
preserve
import excel "${implementation}/presence_ateliers.xlsx", firstrow clear

		* remove blank lines
drop if id_plateforme==.

		* select take-up variables
keep id_plateforme Webinairedelancement Rencontre1Atelier1 Rencontre1Atelier2 Rencontre2Atelier1 Rencontre2Atelier2 Rencontre3Atelier1 Rencontre3Atelier2 EventCOMESA Rencontre456 Atelierconsititutionjuridique Situationdelentreprise

		* save
save "${implementation}/take_up", replace
restore

		* merge to analysis data
merge 1:1 id_plateforme using "${implementation}/take_up", force
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                            91
        from master                        91  (_merge==1)
        from using                          0  (_merge==2)

    Matched                                85  (_merge==3)
    -----------------------------------------
*/
drop _merge
order Webinairedelancement Rencontre1Atelier1 Rencontre1Atelier2 Rencontre2Atelier1 Rencontre2Atelier2 Rencontre3Atelier1 Rencontre3Atelier2 EventCOMESA Rencontre456 Atelierconsititutionjuridique Situationdelentreprise, last

    * save as consortium_database
save "${master_raw}/consortium_raw", replace
