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

***********************************************************************
* 	PART 2:  create + save bl_pii file	  			
***********************************************************************
	* put all pii variamles into a local
local pii id_plateforme nom_rep NOM_ENTREPRISE nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptamle_email comptamle_numero Numero1 Numero2 List_group_ml

	* save as stata master data
preserve
keep `pii'

    * transform byte variamle of nom_rep into string to match the baseline data
tostring nom_rep, gen(nom_rep2) format(%15.0f)
        drop nom_rep
        ren nom_rep2 nom_rep
		
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
drop Id_ident ident2 firmname_change ident_nouveau_personne ident_base_respondent ident_respondent_position comptable_numero comptable_email id_admin Numero1 Numero2


save "${ml_intermediate}/ml_intermediate", replace
