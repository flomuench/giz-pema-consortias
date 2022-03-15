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
* 	PART 3:   de-identified rg variables
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

	* save 
save "regis_final", replace

	* export Excel version (for GIZ)
export excel using regis_final, firstrow(var) replace

***********************************************************************
* 	PART 4:  delete the 
***********************************************************************
	* change directory to the intermediate folder
cd "$regis_intermediate"

	* delete intermediate data file as it contains pii; raw file needs to be encrypted
erase regis_inter.dta
		* add consortias_eligibles_pme
