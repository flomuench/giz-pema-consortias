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
* 	PART 1:  Mergebl_match
***********************************************************************

clear 

use "${regis_final}/regis_final", clear

*keep id_plateforme presence_enligne rg_age fte fte_femmes capital sector subsector rg_gender_rep rg_gender_pdg produit_exportable export2017 export2018 export2019 export2020 export2021

*merge 1:m id_plateforme using "${bl_intermediate}/bl_inter"

*keep if _merge==3

*drop _merge

***********************************************************************
* 	PART 2:  Label new variables
***********************************************************************


***********************************************************************
* 	PART 3:  Save
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace

