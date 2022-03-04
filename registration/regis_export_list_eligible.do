***********************************************************************
* 			consortium femmes eligible & ineligible firms
***********************************************************************
*																	   
*	PURPOSE:  export list of eligible & eligible firms  														 
*	OUTLINE:														  
*	1)				create + save a master file		  		  			
*	2)  			save a de-identified final analysis file					 
*	3)  			delete the intermediate file							  
*																	  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta	  
*	Creates:  list_final_eligible list_ineligible_final	  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
	* import file
use "${regis_intermediate}/regis_inter", clear

***********************************************************************
* 	PART 2:   rename for better understanding	  			
***********************************************************************
	rename rg_media reseau_social
	rename rg_siteweb site_web 
	rename id_admin matricule_fiscale
	rename rg_resident onshore
	rename rg_fte employes
	rename rg_produitexp produit_exportable
	rename rg_intention intention_export
	rename rg_oper_exp operation_export
	rename rg_codedouane code_douane
	rename rg_matricule matricule_cnss
	rename rg_capital capital
	rename rg_nom_rep nom_rep
	rename rg_position_rep position_rep
	rename rg_emailpdg email_pdg
	rename rg_telrep tel_rep
	rename rg_telpdg tel_pdg
	rename rg_emailrep email_rep
order id_plateforme firmname eligible date_created matricule_fiscale code_douane matricule_cnss operation_export 


***********************************************************************
* 	PART 3:   export list of eligible firms	  			
***********************************************************************
	* 
cd "$regis_final"
local contactvariables "id_plateforme eligible firmname id_admin_correct matricule_fiscale nom_rep position_rep email_pdg email_rep tel_pdg tel_rep list_group ca_check ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020"
export excel `contactvariables' using "list_eligible_final" if eligible == 1, firstrow(var) replace


***********************************************************************
* 	PART 4:   export list of non-eligible firms	  			
***********************************************************************
local contactvariables "id_plateforme eligible firmname nom_rep position_rep email_pdg email_rep tel_pdg tel_rep"
export excel `contactvariables' using "list_ineligible_final" if eligible == 0, firstrow(var) replace


***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
	* set export directory
cd "$regis_intermediate"

	* save dta file
save "regis_inter", replace
