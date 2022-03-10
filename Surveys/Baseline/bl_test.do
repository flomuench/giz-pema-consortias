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

* If any of the accounting vars has missing value or zero, create 

local accountvars ca_2021 ca_exp_2021 profit_2021

foreach var of local accountvars {
	replace check_again = 2 if `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' zero/ " if `var' == 0 
	replace check_again = 2 if `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque/ " if `var' == . 	
}

local accountvars2  inno_rd exprep_inv
foreach var of local accountvars2 {
	replace check_again = 2 if `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque/ " if `var' == . 	
}


*check whether the companies that had to re-fill accounting data actually corrected it

local vars_checked ca_2018_cor ca_exp_2018_cor ca_2019_cor ca_exp2019_cor ca_2020_cor ca_exp2020_cor
foreach var of local vars_checked {
	replace check_again = 3 if `var' == . & needs_check==1
	replace questions_needing_checks = questions_needing_checks + "`var' manque, entreprise dans la liste pour re-fournier donnés 2018-2020 /" if `var' == .& needs_check==1 
	
	replace check_again = 3 if `var' == 0 & needs_check==1  & validation==1
	replace questions_needing_checks = questions_needing_checks +  "`var' zero, entreprise dans la liste pour re-fournier donnés 2018-2020  /" if `var' == 0 & needs_check==1 

}
*/

* If profits are larger than 'chiffres d'affaires' need to check: 
 
replace check_again = 3 if profit_2021>ca_2021 & ca_2021!=. & profit_2021!=. 
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA / " if profit_2021>ca_2021 & ca_2021!=. & profit_2021!=.


* Check if export values are larger than total revenues 

replace check_again = 2 if ca_exp_2021>ca_2021 & ca_2021!=. & ca_exp_2021!=. 
replace questions_needing_checks = questions_needing_checks + "Exports plus élevés que CA/ " if ca_exp_2021>ca_2021 & ca_2021!=. & ca_exp_2021!=. 


*Very low values
replace check_again =2 if ca_exp_2021<500 & ca_exp_2021>0
replace questions_needing_checks = questions_needing_checks + "export moins que 500 TND/ " if ca_exp_2021<500 & ca_exp_2021>0

replace check_again =2 if ca_2021<1000 & ca_2021>0
replace questions_needing_checks = questions_needing_checks + "CA moins que 1000 TND/ " if ca_exp_2021<500 & ca_exp_2021>0

replace check_again =2 if profit_2021<100 & profit_2021>0 
replace questions_needing_checks = questions_needing_checks + "benefice moins que 100 TND/ " if profit_2021<100 & profit_2021>0 


***********************************************************************
* 	Part 2.2 Additional logical test cross-checking answers from registration			
***********************************************************************
*firms that reported to be exporters according to registration data

replace check_again=2 if ca_exp_2021>0 & ca_exp_2021!=.  & exp_pays==. 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent pour exporteur/ " if ca_exp_2021>0 & ca_exp_2021!=.  & exp_pays==. 
replace check_again=2 if operation_export==1 & exp_pays==0 
replace questions_needing_checks = questions_needing_checks + " exp_pays zero pour exporteur selon registre/ " if operation_export==1 & exp_pays==0

replace check_again=2 if ca_exp2020>0 & ca_exp2020!=. & ca_exp_2021==. 
replace questions_needing_checks = questions_needing_checks + " ca_exp2021 manquent mais exp2020 rapporté/ " if ca_exp2020>0 & ca_exp2020!=. & ca_exp_2021==. 

*replace check_again=2 if ca_exp2020>0 & ca_exp2020!=. & ca_exp_2021==0
*replace questions_needing_checks = questions_needing_checks + " ca_exp2021 zéro mais exp2020 rapporté/ " if ca_exp2020>0 & ca_exp2020!=. & ca_exp_2021==. 

replace check_again=2 if ca_2020>0 & ca_2020==. & ca_2021==. 
replace questions_needing_checks = questions_needing_checks + " ca_2021 manquent mais ca_2021 rapporté/ " if ca_2020>0 & ca_2020==. & ca_2021==.  

replace check_again=2 if ca_2020>0 & ca_2020==. & ca_2021==0
replace questions_needing_checks = questions_needing_checks + " ca_2021 zéro mais ca_2020 rapporté/ " if ca_2020>0 & ca_2020==. & ca_2021==0

 

* If number of export countries is higher than 50 – needs check 
replace check_again=1 if exp_pays>49 & exp_pays!=.
replace questions_needing_checks = questions_needing_checks + " exp_pays très elevé/ " if exp_pays>49 & exp_pays!=.

*Add 1 point in priority if survey was validated
replace check_again = check_again+1 if validation==1 & check_again>0

***********************************************************************
* 	Part 2.3 Outliers			
***********************************************************************
sum ca_2021, d
scalar ca_95p = r(p95)
scalar list
replace check_again=2 if ca_2021> 2800000 & ca_2021!=.


***********************************************************************
* 	Part 3 Re-shape the correction sheet			
***********************************************************************
preserve
split questions_needing_checks, parse(/) generate(questions)
drop questions_needing_checks 
reshape long questions, i(id_plateforme)
drop if questions==""
by id_plateforme: gene nombre_questions=_n
drop _j
gen commentaires_ElAmouri = .
gen valeur_actuelle=.
gen correction_propose=.
gen correction_valide=.
cd "$bl_checks"
order id_plateforme miss check_again questions nombre_questions commentaires_ElAmouri commentsmsb valeur_actuelle correction_propose correction_valide
export excel id_plateforme miss validation check_again nombre_questions questions commentaires_ElAmouri commentsmsb valeur_actuelle correction_propose correction_valide using "fiche de correction" if check_again>=1,  firstrow(variables)replace
restore



