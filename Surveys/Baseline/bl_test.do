***********************************************************************
* 			consortias baseline survey logical tests                  *	
***********************************************************************
*																	    
*	PURPOSE: Check that answers make logical sense			  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Preamble
* 	2) 		Define logical tests
*	2.1) 	Tests for accounting
*	2.1) 	Tests for indices									  															      
*	Author:  	Teo Firpo							  
*	ID variable: 	id_plateforme (example: f101)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Create word file for export		  		
***********************************************************************
	* import file
	
use "${bl_intermediate}/bl_inter", clear


***********************************************************************
* 	PART 2:  Define logical tests
***********************************************************************

/* --------------------------------------------------------------------
	PART 2.1: Comptabilité / accounting questions
----------------------------------------------------------------------*/		
/
* If any of the accounting vars has missing value or zero, create 

local accountvars ca_2021 ca_exp_2021 profit_2021 inno_rd exprep_inv


foreach var of local accountvars {
	replace check_again = 2 if `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' zero, validé /" if `var' == 0 & validation==1
	replace check_again = 2 if `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque, validé /" if `var' == . & validation==1
}

/* check whether the companies that had to re-fill accounting data actually corrected it

local vars_checked ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020
foreach var of local vars_checked {
	replace check_again = 2 if `var' == . & needs_check==1
	replace questions_needing_checks = questions_needing_checks + "`var' manque, validé /" if `var' == .& needs_check==1 
	
	replace check_again = 2 if `var' == 0 & needs_check==1  & validation==1
	replace questions_needing_checks = questions_needing_checks +  "`var' zero, validé /" if `var' == 0 & needs_check==1 

}


* If profits are larger than 'chiffres d'affaires' need to check: 
 
replace check_again = 2 if profit2021>ca_2021 & ca_2021!=. & profit2021!=.
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA/ " if profit2021>ca_2021 & ca_2021!=. & profit2021!=.


* Check if export values are larger than total revenues 

replace check_again = 2 if ca_exp_2021>ca_2021 & ca_2021!=. & ca_exp_2021!=. 
replace questions_needing_checks = questions_needing_checks + "Exports plus élevés que CA/ " if ca_exp_2021>ca_2021 & ca_2021!=. & ca_exp_2021!=. 


*Very low values
replace check_again =2 if ca_exp_2021<500 & ca_exp_2021>0
replace questions_needing_checks = questions_needing_checks + "export moins que 500 TND/ " if ca_exp_2021<500 & ca_exp_2021>0

replace check_again =2 if ca_2021<1000 & ca_2021>0 & validation==1
replace questions_needing_checks = questions_needing_checks + "CA moins que 1000 TND/ " if ca_exp_2021<500 & ca_exp_2021>0

replace check_again =2 if profit_2021<100 & profit_2021>0 
replace questions_needing_checks = questions_needing_checks + "benefice moins que 100 TND/ " if profit_2021<100 & profit_2021>0 


***********************************************************************
* 	Part 2.2 Additional logical test cross-checking answers from registration			
***********************************************************************
*firms that reported to be exporters according to registration data

replace check_again=1 if operation_export==1 & exp_pays==. 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent pour exporteur/" if operation_export==1 & exp_pays==0 
replace check_again=1 if operation_export==1 & exp_pays==0 
replace questions_needing_checks = questions_needing_checks + " exp_pays zero pour exporteur/" if operation_export==1 & exp_pays==0 


* If number of export countries is higher than 50 – needs check 
replace check_again=1 if exp_pays>49 & exp_pays!=.
replace questions_needing_checks = questions_needing_checks + " exp_pays très elevé/"







***********************************************************************
* 	Part 3 Export an excel sheet with needs_check variables  			
***********************************************************************

capture drop dup

sort id_plateforme, stable

quietly by id_plateforme:  gen dup = cond(_N==1,0,_n)

replace needs_check = 1 if dup>0

gen commentaires_ElAmouri = .

cd "$bl_checks"

order id_plateforme check questions_needing_check commentaires_ElAmouri commentsmsb 

export excel commentaires_ElAmouri id_plateforme commentsmsb check questions_needing_check heure date-dig_logistique_retour_score using "fiche_correction" if needs_check>=1, firstrow(variables) replace

