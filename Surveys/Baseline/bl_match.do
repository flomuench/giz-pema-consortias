***********************************************************************
* 			baseline match to registration data									  	  
***********************************************************************
*																	    
*	PURPOSE: match survey data from registration		  							  
*																	  
*																	  
*	OUTLINE:														  
*	1) Set up paths and merge
*	2) Label new vars 
*	3) Save
*																	  															      
*	Author:  	Fabian Scheifele  
*	ID variaregise: 	id_plateforme (example: 777)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Merge bl_match*
***********************************************************************

clear 

use "${regis_final}/regis_final", clear
drop if id_plateforme==.

rename questions_needing_check question_unclear_regis
drop eligible eligibilité programme treatment rg_legalstatus moyen_com rg_confidentialite rg_partage_donnees rg_enregistrement_coordonnees dateinscription date_creation_string date_inscription_string dup_emailpdg dup_firmname onshore produit_exportable intention_export rg_expstatus ca_check random_number rank list_group
merge 1:1 id_plateforme using "${bl_intermediate}/bl_inter", generate(_merge_ab)

***********************************************************************
* 	PART 2:  Label new variables
***********************************************************************


***********************************************************************
* 	PART 3:  Save
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace

