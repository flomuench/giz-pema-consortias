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
*drop all entries that have not yet started answering the questionnaire
drop if _merge_ab==1
***********************************************************************
* 	PART 2:  Define logical tests
***********************************************************************

/* --------------------------------------------------------------------
	PART 2.1: Comptabilité / accounting questions
----------------------------------------------------------------------*/		

* If any of the accounting vars has missing value or zero, create 

local accountvars ca_2021 profit_2021

foreach var of local accountvars {
	replace check_again = 2 if `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' zero/ " if `var' == 0 
	replace check_again = 2 if `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque/ " if `var' == . 	
}

local accountvars2  inno_rd exprep_inv ca_exp_2021
foreach var of local accountvars2 {
	replace check_again = 2 if `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque/ " if `var' == . 	
}


*check whether the companies that had to re-fill accounting data actually corrected it

local vars_checked ca_2018_cor ca_exp_2018_cor ca_2019_cor ca_exp2019_cor ca_2020_cor ca_exp2020_cor
foreach var of local vars_checked {
	replace check_again = 2 if `var' == . & needs_check==1
	replace questions_needing_checks = questions_needing_checks + "`var' manque, entreprise dans la liste pour re-fournier donnés 2018-2020 /" if `var' == .& needs_check==1 
	
}
*/

* If profits are larger than 'chiffres d'affaires' need to check: 
replace check_again = 2 if profit_2021>ca_2021 & ca_2021!=. & profit_2021!=. 
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
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent pour entreprise avec ca_exp2021>0/ " if ca_exp_2021>0 & ca_exp_2021!=.  & exp_pays==. 

replace check_again=2 if ca_exp_2021>0 & ca_exp_2021!=. & exp_pays==0 
replace questions_needing_checks = questions_needing_checks + " exp_pays zero pour entreprise avec ca_exp2021>0/ " if ca_exp_2021>0 & ca_exp_2021!=. & exp_pays==0 

replace check_again=2 if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & ca_exp_2021==0 
replace questions_needing_checks = questions_needing_checks + " ca_exp_2021 zéro mais export rapporté dans le passé/ " if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & ca_exp_2021==0 

replace check_again=2 if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & exp_pays==. 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent mais export rapporté dans le passé/ " if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & exp_pays==. 
*/

* If number of export countries is higher than 50 – needs check 
replace check_again=1 if exp_pays>49 & exp_pays!=.
replace questions_needing_checks = questions_needing_checks + " exp_pays très elevé/ " if exp_pays>49 & exp_pays!=.


***********************************************************************
* 	Part 2.3 large Outliers			
***********************************************************************
sum ca_2021, d
scalar ca_95p = r(p95)
replace check_again=2 if ca_2021> ca_95p & ca_2021!=.
replace questions_needing_checks = questions_needing_checks + "ca_2021 très grand/" if ca_2021> ca_95p & ca_2021!=.

sum ca_exp_2021, d
scalar ca_exp95p = r(p95)
replace check_again=2 if ca_exp_2021> ca_exp95p & ca_exp_2021!=.
replace questions_needing_checks = questions_needing_checks + "ca_exp_2021 très grand/" if ca_exp_2021> ca_exp95p & ca_exp_2021!=.

sum profit_2021, d
scalar profit_95p = r(p95)
replace check_again=2 if profit_2021> profit_95p & profit_2021!=.
replace questions_needing_checks = questions_needing_checks + "profit très grand/" if profit_2021> profit_95p & profit_2021!=.

sum inno_rd, d
scalar inno_rd_95p = r(p95)
replace check_again=2 if inno_rd> inno_rd_95p & inno_rd!=.
replace questions_needing_checks = questions_needing_checks + "investissement recherche très grand/" if inno_rd> inno_rd_95p & inno_rd!=.

sum exprep_inv, d
scalar exprep_inv_95p = r(p95)
replace check_again=2 if exprep_inv> exprep_inv_95p & exprep_inv!=.
replace questions_needing_checks = questions_needing_checks + "investissement export très grand/" if exprep_inv> exprep_inv_95p & exprep_inv!=.

***********************************************************************
* 	Part 2.4 manual approval of values that appear illogical/very high
			
***********************************************************************
*Please create check_again=0 if the value would be captured by 
*the logical tests above, but it was confirmed by the survey institute
*that it is indeed the correct value




***********************************************************************
* 	Part 2.5 Remove observations with more than 10 missing fields			
***********************************************************************
*Add 1 point in priority if survey was validated
replace check_again = check_again+1 if validation==1 & check_again>0
replace check_again=0 if miss>10



***********************************************************************
* 	Part 3 Re-shape the correction sheet			
***********************************************************************
*re-merge additional contact information to dataset
merge 1:1 id_plateforme using "${consortia_master}/add_contact_data", generate(_merge_cd)

*Split questions needing check and move it from wide to long
preserve
split questions_needing_checks, parse(/) generate(questions)
drop questions_needing_checks 
reshape long questions, i(id_plateforme)
drop if questions==""
by id_plateforme: gene nombre_questions=_n
drop _j
gen commentaires_ElAmouri = .
gen correction_propose=.
gen correction_valide=.
cd "$bl_checks"
sort date heuredébut validation nombre_question
order id_plateforme date heuredébut miss check_again questions nombre_questions commentaires_ElAmouri commentsmsb correction_propose correction_valide

*Export the fiche de correction with additional contact information
cd "$bl_checks"
sort date heuredébut validation nombre_questions
export excel id_plateforme miss validation check_again nombre_questions comptable_numero comptable_email Numero1 Numero2 questions commentaires_ElAmouri commentsmsb correction_propose correction_valide ca_2021 profit_2021 inno_rd exprep_inv ca_exp_2021 ca_2018_cor ca_exp_2018_cor ca_2019_cor ca_exp2019_cor ca_2020_cor ca_exp2020_cor using "fiche_de_correction.xlsx" if check_again>=1, firstrow(variables) replace
restore


