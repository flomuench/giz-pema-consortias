***********************************************************************
* 			consortia master  logical tests                           *	
***********************************************************************
*																	    
*	PURPOSE: Check that answers make logical sense			  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Load data
* 	2) 		Define logical tests
*	2.1) 	Tests for accounting
*	2.1) 	Tests for indices	
*   3) Check missing values
*   4) Export excel sheet 								  															      
*	Author:  	Ayoub Chamakhi
*	ID variable: 	id_plateforme (example: f101)			  					  
*	Requires: consortium_int.dta 	  								  
*	Creates:  fiche_correction.xls			                          
*																	  
***********************************************************************
* 	PART 1:  Load data	  		
***********************************************************************
	 
use "${master_final}/consortium_int", clear

***********************************************************************
* 	PART 2:  Define logical tests
***********************************************************************
/* --------------------------------------------------------------------
	PART 2.1: Comptabilité / accounting questions
----------------------------------------------------------------------*/		

* If any of the accounting vars has missing value or zero, create 
local accountvars ca_2022 ca_exp2022 Profit_2022

foreach var of local accountvars {
	replace check_again = 2 if `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' zero/ " if `var' == 0 
	replace check_again = 2 if `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque/ " if `var' == . 	
	
	
}
*check whether the companies that had to re-fill accounting data actually corrected it
local vars_checked ca_2021_check ca_exp2021_check

foreach var of local vars_checked {
	replace check_again = 2 if `var' == . & ca_check==1
	replace questions_needing_checks = questions_needing_checks + "`var' manque, entreprise dans la liste pour re-fournier donnés 2021 /" if `var' ==. & ca_check==1 
	
}

* If profits are larger than 'chiffres d'affaires' need to check: 
replace check_again = 2 if Profit_2022>ca_2022 & ca_2022!=. & Profit_2022!=. 
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA / " if Profit_2022>ca_2022 & ca_2022!=. & Profit_2022!=.


* Check if export values are larger than total revenues 

replace check_again = 2 if ca_exp2022>ca_2022 & ca_2022!=. & ca_exp2022!=. 
replace questions_needing_checks = questions_needing_checks + "Exports plus élevés que CA/ " ///
if ca_exp2022>ca_2022 & ca_2022!=. & ca_exp2022!=. 


*Very low values
replace check_again =2 if ca_exp2022<500 & ca_exp2022>0
replace questions_needing_checks = questions_needing_checks + "export moins que 500 TND/ " ///
if ca_exp2022<500 & ca_exp2022>0

replace check_again =2 if ca_2022<1000 & ca_2022>0
replace questions_needing_checks = questions_needing_checks + "CA moins que 1000 TND/ " ///
if ca_2022<500 & ca_2022>0

replace check_again =2 if Profit_2022<100 & Profit_2022>0 
replace questions_needing_checks = questions_needing_checks + "benefice moins que 100 TND/ " ///
if Profit_2022<100 & Profit_2022>0 

***********************************************************************
* 	Part 2.2 Additional logical test cross-checking answers from registration & baseline		
***********************************************************************
*firms that reported to be exporters according to registration & baseline datas

replace check_again=2 if ca_exp2022>0 & ca_exp2022!=.  & exp_pays==. 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent pour entreprise avec ca_exp>0/ " if ca_exp2022>0 & ca_exp2022!=.  & exp_pays==. 

replace check_again=2 if ca_exp2022>0 & ca_exp2022!=. & exp_pays==0 
replace questions_needing_checks = questions_needing_checks + " exp_pays zero pour entreprise avec ca_exp>0/ " if ca_exp2022>0 & ca_exp2022!=. & exp_pays==0 

replace check_again=2 if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)|(ca_exp2021>0 & ca_exp2021!=.)) & ca_exp_2022==0 
replace questions_needing_checks = questions_needing_checks + " ca_exp_2021 zéro mais export rapporté dans le passé/ " if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)|(ca_exp2021>0 & ca_exp2021!=.)) & ca_exp_2022==0 

replace check_again=2 if ((ca_exp2021>0 & ca_exp2021!=.) |(ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & exp_pays==. 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent mais export rapporté dans le passé/ " if ((ca_exp2021>0 & ca_exp2021!=.) |(ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & exp_pays==. 
*/

* If number of export countries is higher than 50 – needs check 
replace check_again=1 if exp_pays>49 & exp_pays!=.
replace questions_needing_checks = questions_needing_checks + " exp_pays très elevé/ " if exp_pays>49 & exp_pays!=.


***********************************************************************
* 	Part 2.4 large Outliers			
***********************************************************************
sum ca_2022, d
scalar ca_95p = r(p95)
replace check_again=2 if ca_2022> ca_95p & ca_2022!=.
replace questions_needing_checks = questions_needing_checks + "ca_2022 très grand/" if ca_2022> ca_95p & ca_2022!=.

sum ca_exp_2022, d
scalar ca_exp95p = r(p95)
replace check_again=2 if ca_exp2022> ca_exp95p & ca_exp2022!=.
replace questions_needing_checks = questions_needing_checks + "ca_exp_2022 très grand/" if ca_exp2022> ca_exp95p & ca_exp2022!=.

sum profit_2022, d
scalar profit_95p = r(p95)
replace check_again=2 if profit_2022> profit_95p & profit_2022!=.
replace questions_needing_checks = questions_needing_checks + "profit très grand/" if profit_2022> profit_95p & profit_2022!=.

sum ca_exp_2021_check, d
scalar profit_95p = r(p95)
replace check_again=2 if ca_exp2021_check> profit_95p & ca_exp2021_check!=.
replace questions_needing_checks = questions_needing_checks + "export 2021 très grand/" ///
if ca_exp2021_check> profit_95p & ca_exp2021_check!=.

sum ca_2021_check, d
scalar profit_95p = r(p95)
replace check_again=2 if ca_2021_check> profit_95p & ca_2021_check!=.
replace questions_needing_checks = questions_needing_checks + "profit 2021 très grand/" ///
if ca_2021_check> profit_95p & ca_2021_check!=.

* check if ca_2022 too big
replace needs_check = 3 if ca_2022> 9000000 & ca_2022<. & surveyround==2
replace questions_a_verifier = " | chiffre d'affaire 2022 très grand " + ///
questions_a_verifier if ca_2022> 9000000 & ca_2022<. & surveyround==2

* check if ca_2021_check too big
replace needs_check = 3 if ca_2021_check> 9000000 & ca_2021_check<. & surveyround==2
replace questions_a_verifier = " | chiffre d'affaire 2021 très grand " + ///
questions_a_verifier if ca_2021_check> 9000000 & ca_2021_check<. & surveyround==2


***********************************************************************
* 	PART 3:  Check for missing values
***********************************************************************

	* employee data

local fte car_carempl1 car_carempl2 car_carempl3 car_carempl4 car_carempl5

foreach var of local closed_vars {
	capture replace needs_check = 1 if `var' == 201 & surveyround==2
	capture replace questions_a_verifier = questions_a_verifier + " | `var' ne sais pas (donnée d'emploi)" if `var' == . & surveyround==2
}

***********************************************************************
* 	Export an excel sheet with needs_check variables  			
***********************************************************************
*re-merge additional contact information to dataset
*merge 1:1 id_plateforme using "${consortia_master}/add_contact_data", generate(_merge_cd)

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
cd "$master_checks"
order id_plateforme date heuredébut miss check_again questions nombre_questions commentaires_ElAmouri commentsmsb correction_propose correction_valide

*Export the fiche de correction with additional contact information
cd "$master_checks"
sort id_plateforme nombre_questions
export excel id_plateforme miss validation check_again nombre_questions comptable_numero comptable_email Numero1 Numero2 questions commentaires_ElAmouri commentsmsb correction_propose correction_valide ca_2022 ca_exp_2022 Profit_2022 ca_2021_check ca_exp_2021_check using "fiche_de_correction.xlsx" if check_again>=1, firstrow(variables) replace
restore


