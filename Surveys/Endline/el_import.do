***********************************************************************
* 			endline consortias experiment import					  *
***********************************************************************
*																	   
*	PURPOSE: import the endline survey data provided by the survey 
*   institute
*																	  
*	OUTLINE:														  
*	1)	import contact list as Excel or CSV		
*   2)  seperate PII data												  
*	3)	save the contact list as dta file in intermediate folder
*																	 					
*	Author: Kais Jomaa , Amira Bouziri , Eya Hanefi	 														  

*	ID variable: id_plateforme			  									  
*	Requires: el_raw.xlsx	
*	Creates: el_intermediate.dta							  
*																	  
***********************************************************************
* 	PART 1: import the list of surveyed firms as Excel				  										  *
************************************************************************
import excel "${el_raw}/el_raw.xlsx", firstrow clear

	* keep only lines with observations (deletes further unintended lines)
sum Id
keep in 1/`r(N)'

    *rename variables in line with codebook 
rename Id id_plateforme 

***********************************************************************
* 	PART 2:  create + save bl_pii file	  			
***********************************************************************
	* remove variables that already existin in pii
drop ident_base_respondent

	* rename variables to indicate el as origin
local el_changes ident_nouveau_personne firmname_change ident_repondent_position
foreach var of local el_changes {
	rename `var' `var'_el
}

	* rename list_group to specify surveyround for pii data
rename List_group List_group_el

	* put all pii variables into a local
local pii id_plateforme ident_nouveau_personne_el id_admin id_ident id_ident2 firmname_change_el ident_repondent_position_el comptable_email comptable_numero  List_group_el

	* change format of accountant email to text for merge with master_pii
tostring comptable_email, replace


	* save as stata master data
preserve
keep `pii'

	* export the pii data as new consortia_master_data 
export excel `pii' using "${el_raw}/consortia_el_pii", firstrow(var) replace
		

		
save "${el_raw}/consortia_el_pii", replace

restore

	* rename list_group for analysis data
rename List_group_el list_group

***********************************************************************
* 	PART 3:  save a de-identified analysis file	
***********************************************************************
	* drop all pii
drop ident_nouveau_personne_el id_ident id_ident2 firmname_change_el ident_repondent_position_el comptable_email comptable_numero  


***********************************************************************
* 	PART 4:  Add treatment status	
***********************************************************************
merge 1:1 id_plateforme using "${ml_final}/ml_final", keepusing(treatment)
drop if _merge == 2
drop _merge 

save "${el_intermediate}/el_intermediate", replace
