***********************************************************************
* 			baseline consortias experiment import					  *
***********************************************************************
*																	   
*	PURPOSE: import the baseline survey data provided by the survey 
*   institute
*																	  
*	OUTLINE:														  
*	1)	import contact list as Excel or CSV														  
*	2)	save the contact list as dta file in intermediate folder
*																	 																      *
*	Author: Teo Firpo  														  

*	ID variable: id_plateforme			  									  
*	Requires: bl_raw.xlsx	
*	Creates: bl_raw.dta							  
*																	  
***********************************************************************
* 	PART 1: import the list of surveyed firms as Excel				  										  *
***********************************************************************

/* --------------------------------------------------------------------
	PART 1.1: Import raw data of online survey
----------------------------------------------------------------------*/		

cd "$bl_raw"
import excel "${bl_raw}/bl_raw.xlsx", sheet("Feuil1") firstrow clear

/* --------------------------------------------------------------------
	PART 1.2: *select PII data, seperate it from raw data and merge with
	existing master file- UNGREEN ONLY WHEN REAL DATA IS IN*
----------------------------------------------------------------------*/	

*keep id_plateforme comptable_email comptable_numero Numero1 Numero2

*cd "$consortia_master"
*save "add_contact_data", replace

*use "$consortia_master/add_contact_data", clear

*merge 1:m id_plateforme using "$consortia_master/consortia_master_data"

*keep if _merge==3

*drop _merge

*erase 
***********************************************************************
* 	PART 2: re-importing raw data and now dropping PII data						
***********************************************************************

*cd "$bl_raw"
*import excel "${bl_raw}/bl_raw.xlsx", sheet("Feuil1") firstrow clear
drop comptable_email comptable_numero Numero1 Numero2
save "bl_raw", replace

