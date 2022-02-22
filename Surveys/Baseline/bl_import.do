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

gen survey_type = "online"

rename BP exp_avant21_2
rename BT exp_pays_principal2

rename Jattestequetouteslesinform attest
rename DA attest2

save "temp_bl_raw", replace

/* --------------------------------------------------------------------
	PART 1.2: Import raw data from CATI survey
----------------------------------------------------------------------*/		
/*
import excel "${bl_raw}/bl_raw_cati.xlsx", sheet("Feuil1") firstrow clear

drop if Id_plateforme==.

gen survey_type = "phone"

rename BR exp_avant21_2
rename BV exp_pays_principal2

rename Jattestequetouteslesinform attest
rename DC attest2

append using temp_bl_raw, force

*/
***********************************************************************
* 	PART 2: save 						
***********************************************************************
erase temp_bl_raw.dta

cd "$bl_raw"
save "bl_raw", replace


