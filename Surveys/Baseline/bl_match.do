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
use "${regis_final}/regis_final", clear
drop if id_plateforme==.
drop if eligible==0

rename questions_needing_check question_unclear_regis
drop eligible eligibilité programme treatment legalstatus moyen_com confidentialite partage_donnees enregistrement_coordonnees dateinscription date_creation_string date_inscription_string dup_emailpdg dup_firmname onshore produit_exportable intention_export expstatus random_number rank list_group
merge 1:1 id_plateforme using "${bl_intermediate}/bl_inter", generate(_merge_ab)

***********************************************************************
* 	PART 2:   Drop companies that decided to not take part in experiment
***********************************************************************
drop if id_plateforme == 1018| id_plateforme == 1048 | id_plateforme == 1113 | id_plateforme == 1160 | id_plateforme == 1095


***********************************************************************
* 	PART 3:  Save
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace

