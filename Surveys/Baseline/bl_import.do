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
preserve
/* --------------------------------------------------------------------
	PART 1.2: *select PII data, seperate it from raw data and merge with
	existing master file- ONLY HAS TO BE DONE ONCE*
----------------------------------------------------------------------*/	

keep id_plateforme nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2
gen survey_round =2
cd "$consortia_master"
save "add_contact_data", replace
use "$consortia_master/consortia_master_data",clear
drop _merge
merge 1:m id_plateforme using "$consortia_master/add_contact_data"

save "consortia_master_data",replace
*/
***********************************************************************
* 	PART 2: re-importing raw data and now dropping PII data						
***********************************************************************

restore
drop nom_rep NOM_ENTREPRISE nom_entr2 ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2
	* drop if id_plateforme is missing

cd "$bl_raw"
save "bl_raw", replace

