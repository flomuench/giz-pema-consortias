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
*																	 																      *
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
* 	PART 2: *select PII data, seperate it from raw data and merge with
*	existing master file- ONLY HAS TO BE DONE ONCE*		  						
***********************************************************************

/*
keep id_plateforme nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2
gen survey_round =3
cd "$consortia_master"
save "add_contact_data", replace
use "$consortia_master/consortia_master_data",clear
drop _merge
merge 1:m id_plateforme using "$consortia_master/add_contact_data", force

save "consortia_master_data",replace

***********************************************************************
* 	PART 3:  save a de-identified final analysis file	
***********************************************************************
	* change directory to final folder
cd "$bl_final"

	* drop all pii
drop nom_rep NOM_ENTREPRISE nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position comptable_email comptable_numero Numero1 Numero2

***********************************************************************
* 	PART 4: re-importing raw data 					
***********************************************************************
*/
save "${ml_intermediate}/ml_intermediate", replace
