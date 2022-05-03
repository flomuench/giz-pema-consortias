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
************************************************************************

/* --------------------------------------------------------------------
	PART 1.1: Import raw data of online survey
----------------------------------------------------------------------*/		

cd "$bl_raw"
import excel "${bl_raw}/bl_raw.xlsx", sheet("Feuil1") firstrow clear
drop if id_plateforme==.
/* --------------------------------------------------------------------
	PART 1.2: *select PII data, seperate it from raw data and merge with
	existing master file- ONLY HAS TO BE DONE ONCE*
----------------------------------------------------------------------*/	
/*
keep id_plateforme nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2
gen survey_round =2
cd "$consortia_master"
save "add_contact_data", replace
use "$consortia_master/consortia_master_data",clear
drop _merge
merge 1:m id_plateforme using "$consortia_master/add_contact_data", force

save "consortia_master_data",replace
*/


***********************************************************************
* 	PART 2:  create + save bl_pii file	  			
***********************************************************************
	* put all pii variables into a local
local pii id_plateforme nom_rep NOM_ENTREPRISE nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2

	* save as stata master data
preserve
keep `pii'

    * transform byte variable of nom_rep into string to match the baseline data

tostring nom_rep, gen(nom_rep2) format(%15.0f)
        drop nom_rep
        ren nom_rep2 nom_rep
		
save "consortia_bl_pii", replace
restore

	* export the pii data as new consortia_master_data 
export excel `pii' using consortia_bl_pii, firstrow(var) replace

***********************************************************************
* 	PART 3:  save a de-identified final analysis file	
***********************************************************************
	* change directory to final folder
cd "$bl_final"

	* drop all pii
drop `pii'

***********************************************************************
* 	PART 4: re-importing raw data 					
***********************************************************************

cd "$bl_raw"
save "bl_raw", replace

