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
frame create consortium_analysis, replace
frame change consortium_analysis
use "${master_final}/consortium_final", clear

frame create consortium_pii, replace
frame change consortium_pii

use "${master_final}/consortium_pii_final", clear

frame change consortium_analysis

frlink m:1 id_plateforme, frame(consortium_pii [take_up_per])


* variables required from analysis data
	* take-up,

***********************************************************************
* 	PART 2: select variables for export
***********************************************************************
	* export for baseline survey
local baseline_vars "id_plateforme firmname id_admin_correct matricule_fiscale nom_rep position_rep email_pdg email_rep tel_pdg tel_rep list_group ca_check ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020"

	* export for midline survey
local midline_vars "id_plateforme firmname treatment formation id_admin_correct matricule_fiscale nom_rep position_rep email_pdg email_rep tel_pdg tel_rep list_group ca_check_bl comptable_missing"

***********************************************************************
* 	PART 3: export file
***********************************************************************
export excel `midline_vars' using "${ml_final}/midline_sample_info", firstrow(var) replace 
