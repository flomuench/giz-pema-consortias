***********************************************************************
* 	Main regressions - Adminstrative data
***********************************************************************
*																	   
*	PURPOSE: Create a database for RNE
*	OUTLINE:														  
*
*																
*	Author:  	Florian Muench			         													      
*	ID variable: 	id (example: f101)			  			
*	  Requires: ad_final.dta 	  										  
*	  Creates:  ad_final.dta										  							  
***********************************************************************
* 	PART:  set the stage - technicalities	
***********************************************************************
 	* import the data 
use "${aqe_master_analysis}/aqe_database_final", clear
merge m:1 id using "${aqe_master}/pii/aqe_master_data", keepusing(matricule_fiscale_correct nom_entreprise)
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                               642  (_merge==3)
    -----------------------------------------
*/
local treatment id treatment strata take_up_sum2 take_up
local heterogeneity bl_size sector certification_status
keep `treatment'  `heterogeneity' nom_entreprise matricule_fiscale_correct
drop if certification_status==.
duplicates drop
save "${aqe_master}/pii/list_rct", replace
