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
use "${master_gdrive}/contact_info_master", clear

	* put key variables first
order id_plateforme, first

	* format id_plateforme
destring id_plateforme, replace



***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
***********************************************************************
* 	PART 3:     clean & correct analysis data set
***********************************************************************
use "${master_raw}/consortium_raw", clear

	* remove unnecessary variables
drop eligible programme needs_check questions_needing_check eligibilité dup_emailpdg dup_firmname question_unclear_regis _merge_ab check_again ca_check random_number rank ident2 questions_needing_checks commentsmsb dup dateinscription date_creation_string subsector_var subsector date heuredébut heurefin


***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_intermediate}/consortium_int", replace


