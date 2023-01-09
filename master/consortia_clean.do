***********************************************************************
* 			consortia master do files: final cleaning  
***********************************************************************
*																	  
*	PURPOSE: clean inconsistencies related to merging survey data sets						  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*				PART 2: clean bl_final	  
*				PART 3:                         											  
*																	  
*	Author:  	Fabian Scheifele & Siwar Hakim							    
*	ID variable: id_email		  					  
*	Requires:  	 regis_final.dta bl_final.dta 										  
*	Creates:     regis_final.dta bl_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
***********************************************************************
* 	PART 1:    clean consortium pii data
***********************************************************************
use "${master_intermediate}/consortium_pii_inter", clear

	* put key variables first
order id_plateforme, first

	* format id_plateforme
destring id_plateforme, replace


save "${master_intermediate}/consortium_pii_inter", replace




***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
***********************************************************************
* 	PART 3:     clean & correct analysis data set
***********************************************************************
use "${master_raw}/consortium_raw", clear

	* remove unnecessary variables
drop eligible programme needs_check questions_needing_check eligibilité dup_emailpdg dup_firmname question_unclear_regis _merge_ab check_again ca_check random_number rank ident2 questions_needing_checks commentsmsb dup dateinscription date_creation_string subsector_var subsector date heuredébut heurefin

	* clean take_up variables
local take_up_vars "Webinairedelancement Rencontre1Atelier1 Rencontre1Atelier2 Rencontre2Atelier1 Rencontre2Atelier2 Rencontre3Atelier1 Rencontre3Atelier2 EventCOMESA Rencontre456 Atelierconsititutionjuridique Situationdelentreprise"

		* clean values
foreach x of local take_up_vars {
replace `x'= lower(`x')
replace `x' = stritrim(strtrim(`x'))
}
		* clean var names
rename `take_up_vars', lower


***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_intermediate}/consortium_inter", replace


