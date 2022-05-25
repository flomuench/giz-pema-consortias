***********************************************************************
* 			clean do file, consortias				  *					  
***********************************************************************
*																	  
*	PURPOSE: clean the regis final and baseline final raw data						  
*																	  
*	OUTLINE: 	PART 1: clean regis_final	  
*				PART 2: clean bl_final	  
*				PART 3:                         											  
*																	  
*	Author:  	Fabian Scheifele & Siwar Hakim							    
*	ID variable: id_email		  					  
*	Requires:  	 regis_final.dta bl_final.dta 										  
*	Creates:     regis_final.dta bl_final.dta

***********************************************************************
* 	PART 1:    clean & correct consortium contact_info	  
***********************************************************************
use "${master_gdrive}/contact_info_master", clear

destring id_plateforme, replace
replace nom_rep="Nesrine dhahri" if id_plateforme==1040
replace firmname="zone art najet omri" if id_plateforme==1133
replace nom_rep="najet omri" if id_plateforme==1133
replace firmname="flav'or" if id_plateforme==1150

drop NOM_ENTREPRISE nom_entr2 ident_base_respondent ident_nouveau_personne ident_base_respondent2 ident_respondent_position


***********************************************************************
* 	PART 2:     clean & correct analysis data set
***********************************************************************
use "${master_raw}/consortium_database_raw", clear
drop eligible programme needs_check questions_needing_check eligibilité dup_emailpdg dup_firmname question_unclear_regis _merge_ab check_again ca_check random_number rank ident2 questions_needing_checks commentsmsb dup dateinscription date_creation_string subsector_var subsector date heuredébut heurefin

    * save as consortium_database

save "consortium_database_raw", replace


/*
***********************************************************************
* 	PART 3:    clean regis_final
***********************************************************************

use "${regis_final}/regis_final", clear
cd "$master_final"
save "master_regis_final", replace	

***********************************************************************
* 	PART 4:    clean bl_final			  
***********************************************************************

use "${bl_final}/bl_final", clear
drop ca_2020_rg ca_exp2020_rg ca_2019_rg ca_exp2019_rg ca_2018_rg ca_exp2018_rg ca_2020_cor ca_exp2020_cor ca_2019_cor ca_exp2019_cor ca_2018_cor ca_exp2018_cor

cd "$master_final"
save "master_bl_final", replace


 
