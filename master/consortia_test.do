***********************************************************************
* 			consortia master  logical tests                           *	
***********************************************************************
*																	    
*	PURPOSE: Check that answers make logical sense			  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Load data & generate check variables
* 	2) 		Define logical tests
*	2.1) 	Networking Questions
*	2.2) 	Export Investment Questions
*	2.3)	Comptabilité / accounting questions	
*	2.4)	Number of Employees
*   3) 		Additional logical test cross-checking answers from registration & baseline	
*	3.1)	CA export	
*   4) 		large Outliers
*	5)		Check for missing values	
*	6)		Export an excel sheet with needs_check variables 
*						  															      
*	Author:  	Ayoub Chamakhi
*	ID variable: 	id_plateforme (example: f101)			  					  
*	Requires: consortium_int.dta 	  								  
*	Creates:  fiche_correction.xls			                          
*																	  
***********************************************************************
* 	PART 1:  Load data & generate check variables 		
***********************************************************************
	 
use "${master_final}/consortium_final", clear

gen needs_check = 0
lab var needs_check "logical test to be checked by El Amouri"

gen questions_needing_checks  = ""
lab var questions_needing_checks "questions to be checked by El Amouri"


/* Categorisation of checks
1: Low Prioritiy Errors: 
2: High Prioritiy Errors: 
3: Highest Prioritiy Errors: Accountibility

*/



***********************************************************************
* 	PART 2:  Define logical tests
***********************************************************************
/* --------------------------------------------------------------------
	PART 2.1: Networking Questions
----------------------------------------------------------------------*/	

replace needs_check =2 if net_nb_m<0 & net_nb_m >500
replace questions_needing_checks = questions_needing_checks + "nombre de contact mâle est négatif ou trop grand" ///
if net_nb_m<0 & net_nb_m >500

replace needs_check =2 if net_nb_f<0 & net_nb_f>500
replace questions_needing_checks = questions_needing_checks + "nombre de contact femmes est négatif ou trop grand" ///
if net_nb_f<0 & net_nb_f >500


/* --------------------------------------------------------------------
	PART 2.2: Export Investment Questions
----------------------------------------------------------------------*/	

replace needs_check =3 if exprep_inv <0 & exprep_inv >900000
replace questions_needing_checks = questions_needing_checks + "chiffre investi dans l'export est négatif ou trop grand" ///
if exprep_inv <0 & exprep_inv >900000

/* --------------------------------------------------------------------
	PART 2.3: Comptabilité / accounting questions
----------------------------------------------------------------------*/		

* If any of the accounting vars has missing value or zero, create 
local accountvars ca ca_exp profit

foreach var of local accountvars {
	replace needs_check = 3 if `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' zero/ " if `var' == 0 
	replace needs_check = 3 if `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque/ " if `var' == . 	
	
	
}
*check whether the companies that had to re-fill accounting data actually corrected it
local vars_checked ca_2021_missing ca_exp_2021_missing	profit_2021_missing	ca_2021	ca_exp2021	profit_2021	

foreach var of local vars_checked {
	replace needs_check = 3 if `var' == . & ca_check==1
	replace questions_needing_checks = questions_needing_checks + "`var' manque, entreprise dans la liste pour re-fournier donnés 2021 /" if `var' ==. & ca_check==1 
	
}

* If profits are larger than 'chiffres d'affaires' need to check: 
replace needs_check = 3 if profit>ca & ca!=. & profit!=. 
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA / " if profit>ca & ca!=. & profit!=.


* Check if export values are larger than total revenues 

replace needs_check = 3 if ca_exp>ca & ca!=. & ca!=. 
replace questions_needing_checks = questions_needing_checks + "Exports plus élevés que CA/ " ///
if ca_exp>ca & ca!=. & ca_exp!=. 


*Very low values
replace needs_check = 3 if ca_exp<500 & ca_exp>0
replace questions_needing_checks = questions_needing_checks + "export moins que 500 TND/ " ///
if ca_exp<500 & ca_exp>0

replace needs_check = 3 if ca<1000 & ca>0
replace questions_needing_checks = questions_needing_checks + "CA moins que 1000 TND/ " ///
if ca<500 & ca>0

replace needs_check = 3 if profit<100 & profit>0 
replace questions_needing_checks = questions_needing_checks + "benefice moins que 100 TND/ " ///
if profit<100 & profit>0 

/* --------------------------------------------------------------------
	PART 2.4: Number of Employees
----------------------------------------------------------------------*/

local nbempl car_carempl1 car_carempl2 car_carempl3 car_carempl4
 	
foreach var of local nb_employees {
	
replace needs_check = 3 if `var'>200 & `var'<0 & surveyround==2
replace questions_needing_check = " | ceci n'est pas une PME, verifier le nombre d'employées " + ///
questions_needing_check if `var'>200 & `var'<0 & surveyround==2

}
***********************************************************************
* 	Part 3: Additional logical test cross-checking answers from registration & baseline		
***********************************************************************
/* --------------------------------------------------------------------
	PART 3.1.: CA export
----------------------------------------------------------------------*/
*firms that reported to be exporters according to registration & baseline datas

replace needs_check=2 if ca_exp>0 & ca_exp!=.  & exp_pays==. 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent pour entreprise avec ca_exp>0/ " if ca_exp>0 & ca_exp!=.  & exp_pays==. 

replace needs_check=2 if ca_exp>0 & ca_exp!=. & exp_pays==0 
replace questions_needing_checks = questions_needing_checks + " exp_pays zero pour entreprise avec ca_exp>0/ " if ca_exp>0 & ca_exp!=. & exp_pays==0 

replace needs_check=2 if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)|(ca_exp2021>0 & ca_exp2021!=.)) & ca_exp==0 
replace questions_needing_checks = questions_needing_checks + " ca_exp_2021 zéro mais export rapporté dans le passé/ " if ((ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)|(ca_exp2021>0 & ca_exp2021!=.)) & ca_exp==0 

replace needs_check=2 if ((ca_exp2021>0 & ca_exp2021!=.) |(ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & exp_pays==. 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent mais export rapporté dans le passé/ " if ((ca_exp2021>0 & ca_exp2021!=.) |(ca_exp2020>0 & ca_exp2020!=.) |(ca_exp2019>0 & ca_exp2019!=.)|(ca_exp2018>0 & ca_exp2018!=.)) & exp_pays==. 
*/

* If number of export countries is higher than 50 – needs check 
replace needs_check=1 if exp_pays>49 & exp_pays!=.
replace questions_needing_checks = questions_needing_checks + " exp_pays très elevé/ " if exp_pays>49 & exp_pays!=.


***********************************************************************
* 	Part 4: large Outliers			
***********************************************************************
sum ca, d
scalar ca_95p = r(p95)
replace needs_check=2 if ca> ca_95p & ca!=.
replace questions_needing_checks = questions_needing_checks + "ca_2022 très grand/" if ca> ca_95p & ca!=.

sum ca_exp, d
scalar ca_exp95p = r(p95)
replace needs_check=2 if ca_exp> ca_exp95p & ca_exp!=.
replace questions_needing_checks = questions_needing_checks + "ca_exp_2022 très grand/" if ca_exp> ca_exp95p & ca_exp!=.

sum profit, d
scalar profit_95p = r(p95)
replace needs_check=2 if profit> profit_95p & profit!=.
replace questions_needing_checks = questions_needing_checks + "profit très grand/" if profit> profit_95p & profit!=.

sum ca_exp_2021, d
scalar profit_95p = r(p95)
replace needs_check=2 if ca_exp2021> profit_95p & ca_exp2021!=.
replace questions_needing_checks = questions_needing_checks + "export 2021 très grand/" ///
if ca_exp2021> profit_95p & ca_exp2021!=.

sum ca_2021, d
scalar profit_95p = r(p95)
replace needs_check=2 if ca_2021> profit_95p & ca_2021!=.
replace questions_needing_checks = questions_needing_checks + "profit 2021 très grand/" ///
if ca_2021> profit_95p & ca_2021!=.

* check if ca_2022 too big
replace needs_check = 3 if ca> 9000000 & ca<. & surveyround==2
replace questions_needing_checks = " | chiffre d'affaire 2022 très grand " + ///
questions_needing_checks if ca> 9000000 & ca<. & surveyround==2

* check if ca_2021_check too big
replace needs_check = 3 if ca_2021> 9000000 & ca_2021<. & surveyround==2
replace questions_needing_checks = " | chiffre d'affaire 2021 très grand " + ///
questions_needing_checks if ca_2021> 9000000 & ca_2021<. & surveyround==2


***********************************************************************
* 	PART 5:  Check for missing values
***********************************************************************

	* employee data

local fte car_carempl1 car_carempl2 car_carempl3 car_carempl4 car_carempl5

foreach var of local closed_vars {
	capture replace needs_check = 1 if `var' == 201 & surveyround==2
	capture replace questions_needing_checks = questions_needing_checks + " | `var' ne sais pas (donnée d'emploi)" if `var' == . & surveyround==2
}

***********************************************************************
* 	PART 6:  Export an excel sheet with needs_check variables  			
***********************************************************************
*re-merge additional contact information to dataset
*merge 1:1 id_plateforme using "${consortia_master}/add_contact_data", generate(_merge_cd)

*Split questions needing check and move it from wide to long
gen commentaires_elamouri = ""
sort id_plateforme, stable
cd "$ml_checks"

preserve
bysort id_plateforme (surveyround): gen checked= needs_check + needs_check[_n+1]
replace checked=0 if checked==.
*keep both baseline and midline value for observations that need checking
keep if needs_check > 0 | checked >0


merge m:1 id_plateforme using  "${ml_raw}/consortia_ml_pii" 
keep if _merge==3 & surveyround == 2
export excel id_plateforme heure surveyround id_ident ident_nouveau_personne_ml needs_check commentaires_elamouri /// 
questions_needing_checks ca ca_exp profit exprep_inv net_nb_f net_nb_m ca_2021_missing ca_exp_2021_missing	///
profit_2021_missing	ca_2021	ca_exp2021	profit_2021 car_empl1 car_empl2 car_empl3 car_empl4 car_empl5 exp_pays email ///
 using "${ml_checks}/fiche_correction.xlsx", sheetreplace firstrow(var)


restore