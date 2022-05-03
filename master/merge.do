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
*	Creates:  contact_info.dta			                                  
***********************************************************************
* 	PART 1: merge & append to create master data set (pii)
***********************************************************************
	* merge registration with baseline data
use "${regis_final}/consortia_regis_pii", clear
		
		* change directory to baseline folder for merge with baseline_final
cd "$bl_raw"

		* merge 1:1 based on project id fxxx
merge 1:1 id using consortia_bl_pii
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
* 	PART 2: save as Consortium_database
***********************************************************************
cd "$master_gdrive"
save "consortium_database_raw", replace


