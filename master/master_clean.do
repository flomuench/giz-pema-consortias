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
* 	PART 1:    clean regis_final
***********************************************************************

use "${regis_final}/regis_final", clear


cd "$master_final"
save "master_regis_final", replace	

***********************************************************************
* 	PART 2:    clean bl_final			  
***********************************************************************

use "${bl_final}/bl_final", clear
drop ca_2020_rg ca_exp2020_rg ca_2019_rg ca_exp2019_rg ca_2018_rg ca_exp2018_rg ca_2020_cor ca_exp2020_cor ca_2019_cor ca_exp2019_cor ca_2018_cor ca_exp2018_cor

cd "$master_final"
save "master_bl_final", replace
