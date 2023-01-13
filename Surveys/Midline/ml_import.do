***********************************************************************
* 			midline consortias experiment import					  *
***********************************************************************
*																	   
*	PURPOSE: import the midline survey data provided by the survey 
*   institute
*																	  
*	OUTLINE:														  
*	1)	import contact list as Excel or CSV		
*   2)  seperate PII data												  
*	3)	save the contact list as dta file in intermediate folder
*																	 					
*	Author: Ayoub Chamakhi, Kais Jomaa, Amina Bousnina		 														  

*	ID variable: id_plateforme			  									  
*	Requires: ml_raw.xlsx	
*	Creates: ml_intermediate.dta							  
*																	  
***********************************************************************
* 	PART 1: import the list of surveyed firms as Excel				  										  *
************************************************************************
import excel "${ml_raw}/ml_raw.xlsx", firstrow clear

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

	* rename variables to indicate ml as origin
local ml_changes ident_nouveau_personne firmname_change Numero1 Numero2 ident_repondent_position
foreach var of local ml_changes {
	rename `var' `var'_ml
}

	* put all pii variables into a local
local pii id_plateforme ident_nouveau_personne_ml id_ident id_ident2 firmname_change_ml ident_repondent_position_ml comptable_email comptable_numero Numero1_ml Numero2_ml List_group

	* change format of accountant email to text for merge with master_pii
tostring comptable_email, replace


	* save as stata master data
preserve
keep `pii'

   
		
	* rename list_group to specify surveyround
rename List_group List_group_ml
		
save "${ml_raw}/consortia_ml_pii", replace

	* export the pii data as new consortia_master_data 
export excel `pii' using "${ml_raw}/consortia_ml_pii", firstrow(var) replace

restore


***********************************************************************
* 	PART 3:  save a de-identified analysis file	
***********************************************************************
	* drop all pii
drop ident_nouveau_personne id_ident id_ident2 firmname_change_ml ident_repondent_position_ml comptable_email comptable_numero Numero1_ml Numero2_ml 


***********************************************************************
* 	PART 4:  Add treatment status	
***********************************************************************
merge 1:1 id_plateforme using "${bl_final}/bl_final", keepusing(treatment)
drop _merge

save "${ml_intermediate}/ml_intermediate", replace
