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
	
	* rename for better understanding
rename eli_cri eligible_final
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
order id_plateforme firmname eligible_final date_created matricule_fiscale code_douane matricule_cnss operation_export 

	* randomly allocate firms to list experiment treatment (= 1) & control group ( = 0)
		* sort the data by id_plateforme (stable sort --> randomisation rule 2)
isid id_plateforme, sort
		* rank the random number
gen random_number = uniform() if eligible_final == 1
egen rank = rank(random_number), unique
		* identify the observation that divides ranked firms into half
sum rank, d
scalar rank_median = r(p50)
		* allocate firms 50:50 to list treatment & control group
gen list_group = .
replace list_group = 1 if eligible_final == 1 & rank >= rank_median
replace list_group = 0 if eligible_final == 1 & rank < rank_median

		* evaluate balance
cd "$regis_final"
iebaltab ca_mean ca_expmean employes capital operation_export rg_age presence_enligne, grpvar(list_group) save(baltab_list_experiment) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
		
		* assess replicability
			* when re-running manually change the name of result_randomisation to compare
preserve
keep id_plateforme random_number rank eligible_final
save "result_randomisation", replace
restore

***********************************************************************
* 	PART 2:  create + save a master file	  			
***********************************************************************
	* put all pii variables into a local
local pii id_plateforme firmname eligible_final matricule_fiscale matricule_cnss code_douane rg_nom_rep rg_position_rep rg_emailrep rg_emailpdg rg_telrep rg_telpdg site_web reseau_social rg_adresse codepostal  date_created

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
* 	PART 3:  save a de-identified final analysis file	
***********************************************************************
	* change directory to final folder
cd "$regis_final"

	* identify all pii but unique identifier id_plateforme
local pii firmname matricule_fiscale matricule_cnss code_douane rg_nom_rep rg_position_rep rg_emailrep rg_emailpdg rg_telrep rg_telpdg site_web reseau_social rg_adresse codepostal date_created

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
