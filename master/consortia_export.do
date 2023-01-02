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
* variables required from analysis data
	* take-up

***********************************************************************
* 	PART 2: select variables for export
***********************************************************************
local list_vars "id_plateforme surveyround "

***********************************************************************
* 	PART 3: export file
***********************************************************************
export excel `list_vars' using "${master_output}/consortia_list.xlsx", firstrow(var) replace keepcellfmt