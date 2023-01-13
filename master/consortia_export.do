***********************************************************************
* 			consortia master do files: export list with contact info  
***********************************************************************
*																	  
*	PURPOSE: export most important information for survey institute or political partners				  
*																	  
*	OUTLINE: 	PART 1: link analysis with pii data	  
*				PART 2: select variables for export	  
*				PART 3: export file
*																	  
*	Author:  	Florian Münch							    
*	ID variable: id_plateforme surveyround		  					  
*	Requires:  	 contact_info_master.dta, consortia_raw.dta			  
*	Creates:     consortia_list.xlsx
***********************************************************************
* 	PART 1:    link analysis with pii data	  
***********************************************************************
	* variable required in pii data from analysis: take-up
use "${master_final}/consortium_pii_final", clear
drop if id_plateforme==.
merge 1:1 id_plateforme using "${master_final}/consortia_final", keepusing(id_plateforme status ca_2021 ca_exp_2021 profit_2021_missing ca_2021_missing ca_exp_2021_missing)


   /* 
   Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                               176  (_merge==3)
    -----------------------------------------
*/

***********************************************************************
* 	PART 2: select variables for export
***********************************************************************
	* export for baseline survey
local baseline_vars "id_plateforme firmname id_admin_correct matricule_fiscale nom_rep position_rep email_pdg email_rep tel_pdg tel_rep list_group ca_check ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020"

	* export for midline survey
*local midline_vars "id_plateforme ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position ident_base_respondent ident_nouveau_personne id_ident id_ident2 firmname_change ident_repondent_position comptable_email comptable_numero Numero1 Numero2 List_group comptable_missing profit_2021_missing ca_2021_missing ca_exp_2021_missing"

***********************************************************************
* 	PART 3: export file
***********************************************************************
export excel `midline_vars' using "${ml_output}/midline_sample_info", firstrow(var) replace 
