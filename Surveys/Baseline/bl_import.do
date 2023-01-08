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
import excel "${bl_raw}/bl_raw.xlsx", sheet("Feuil1") firstrow clear
drop if id_plateforme==.


***********************************************************************
* 	PART 2:  create + save bl_pii file	  			
***********************************************************************
	* save copy in memory
preserve

	* put all pii variables into a local
local pii id_plateforme nom_rep NOM_ENTREPRISE nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2 List_group

	* save as stata master data
keep `pii'

    * transform byte variable of nom_rep into string to match the baseline data
tostring nom_rep, gen(nom_rep2) format(%15.0f)
        drop nom_rep
        ren nom_rep2 nom_rep
		
save "${bl_raw}/consortia_bl_pii", replace

	* export the pii data as new consortia_master_data 
export excel `pii' using "${bl_raw}/consortia_bl_pii", firstrow(var) replace

	* restore copy in memory
restore


***********************************************************************
* 	PART 3:  save a de-identified analysis file	
***********************************************************************
	* drop all pii
drop nom_rep NOM_ENTREPRISE nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2
save "${bl_raw}/bl_raw", replace



