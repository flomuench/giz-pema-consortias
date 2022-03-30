***********************************************************************
* 			registration de-identify + save final file for analysis
***********************************************************************
*																	   
*	PURPOSE:  de-identify the data &  														 
*	OUTLINE:														  
*	1)				create + save a master file		  		  			
*	2)  			save a de-identified final analysis file					 
*	3)  			delete the intermediate file							  
*																	  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta	  
*	Creates:  regis_final.dta + consortia_master_data			  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
	* import file
use "${regis_intermediate}/regis_inter", clear
	
***********************************************************************
* 	PART 2:  create + save a master file	  			
***********************************************************************
	* put all pii variables into a local
local pii id_plateforme firmname eligible matricule_fiscale matricule_cnss code_douane nom_rep position_rep email_rep email_pdg tel_rep tel_pdg site_web reseau_social rg_adresse codepostal  date_created

	* change directory to 
cd "$regis_data"

	* save as stata master data
preserve
keep `pii'
save "consortia_master_data", replace
restore

	* export the pii data as new consortia_master_data 
export excel `pii' using consortia_master_data, firstrow(var) replace

	* master data + raw file need manual encryption
***********************************************************************
* 	PART 3:  de-identified variables  			
***********************************************************************
rename rg_legalstatus legalstatus 
rename rg_fte_femmes fte_femmes 
rename rg_confidentialite confidentialite 
rename rg_partage_donnees partage_donnees 
rename rg_enregistrement_coordonnees enregistrement_coordonnees 
rename rg_gender_rep gender_rep 
rename rg_gender_pdg gender_pdg 
rename rg_expstatus expstatus


***********************************************************************
* 	PART 4:  save a de-identified final analysis file	
***********************************************************************
	* change directory to final folder
cd "$regis_final"

	* identify all pii but unique identifier id_plateforme
local pii firmname matricule_fiscale matricule_cnss code_douane nom_rep position_rep email_rep email_pdg tel_rep tel_pdg site_web reseau_social rg_adresse codepostal date_created

	* drop all pii
drop `pii'


***********************************************************************
* 	PART 5:  create a new variable for survey round
***********************************************************************
/*

generate survey_round= .
replace survey_round= 1 if surveyround== "registration"
replace survey_round= 2 if surveyround== "baseline"
replace survey_round= 3 if surveyround== "session1"
replace survey_round= 4 if surveyround== "session2"
replace survey_round= 5 if surveyround== "session3"
replace survey_round= 6 if surveyround== "session4"
replace survey_round= 7 if surveyround== "session5"
replace survey_round= 8 if surveyround== "session6"
replace survey_round= 9 if surveyround== "midline"
replace survey_round= 10 if surveyround== "endline"

label var survey_round "which survey round?"

label define label_survey_round  1 "registration" 2 "baseline" 3 "session1" 4 "session2" 5 "session3" 6 "session4" 7 "session5" 8 "session6" 9 "midline" 10 "endline" 
label values survey_round  label_survey_round 
*/

***********************************************************************
* 	PART 6:  save final
***********************************************************************
	* save 
save "regis_final", replace

	* export Excel version (for GIZ)
export excel using regis_final, firstrow(var) replace

***********************************************************************
* 	PART 5:  delete the 
***********************************************************************
	* change directory to the intermediate folder
cd "$regis_intermediate"

	* delete intermediate data file as it contains pii; raw file needs to be encrypted
erase regis_inter.dta
		* add consortias_eligibles_pme
