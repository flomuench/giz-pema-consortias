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
merge 1:1 id_plateforme using "${master_final}/consortium_final", keepusing(status ca_2021 ca_exp_2021 profit_2021_missing ca_2021_missing ca_exp_2021_missing)


***********************************************************************
* 	PART 2: select variables for export
***********************************************************************
	* export for baseline survey
local baseline_vars "id_plateforme firmname id_admin_correct matricule_fiscale nom_rep position_rep email_pdg email_rep tel_pdg tel_rep list_group ca_check ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020"

	* export for midline survey
local midline_vars "id_plateforme firmname treatment status matricule_fiscale matricule_fisc_incorrect nom_rep position_rep email_pdg email_rep tel_pdg tel_rep list_group comptable_missing profit_2021_missing ca_2021_missing ca_exp_2021_missing"

***********************************************************************
* 	PART 3: export file
***********************************************************************
export excel `midline_vars' using "${ml_output}/midline_sample_info", firstrow(var) replace 
