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
*	6)		Manual corrections of needs_check after Amouri Feedback 
*	7)		Export an excel sheet with needs_check variables 
*						  															      
*	Author:  	Florian Münch, Ayoub Chamakhi
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


***********************************************************************
* 	PART 2:  Define logical tests
***********************************************************************
/* --------------------------------------------------------------------
	PART 2.1: Networking Questions
----------------------------------------------------------------------*/	
replace needs_check = 1 if surveyround == 2 &  net_nb_m > 50 & net_nb_m < .
replace questions_needing_checks = "nombre de contact mâle est excessivement grand / " if surveyround == 2 &  net_nb_m > 50 & net_nb_m < .

replace needs_check = 1 if surveyround == 2 &  net_nb_f > 50 & net_nb_f < .
replace questions_needing_checks = "nombre de contact féminin est excessivement grand / " if surveyround == 2 &  net_nb_f > 50 & net_nb_f < .


/* --------------------------------------------------------------------
	PART 2.2: Export Questions
----------------------------------------------------------------------*/	
	* negative exports
replace needs_check = 1 if surveyround == 2 & exprep_inv < 0 & exprep_inv != -999 & exprep_inv != -888
replace questions_needing_checks = questions_needing_checks + "chiffre investi dans l'export est négatif / " if surveyround == 2 & exprep_inv < 0 & exprep_inv != -999 & exprep_inv != -888

	* did not invest in export but did export activities
local exp_vars exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission ///
 exp_pra_plan exp_pra_foire ssa_action4 ssa_action5	
 
foreach var of local exp_vars {
	replace needs_check = 1 if surveyround == 2 & `var' == 1 & exprep_inv==0
	replace questions_needing_checks = questions_needing_checks + "pas d'investissement dans l'export alors qu'il y'a activités d'export (`var' = 1) / " if surveyround == 2 & `var' == 1 & exprep_inv==0
	
}	

/* --------------------------------------------------------------------
	PART 2.3: Comptabilité / accounting questions
----------------------------------------------------------------------*/		

	* Sales or profit is zero or missing
local accountvars ca profit
foreach var of local accountvars {
		* = 0
	replace needs_check = 1 if surveyround == 2 & `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' zero / " if surveyround == 2 & `var' == 0 
	
		* = .
	replace needs_check = 1 if surveyround == 2 & `var' == . 
	replace questions_needing_checks = questions_needing_checks + "`var' manque / " if `var' == . 	
	
	
}

	*  companies that had to re-fill accounting data actually corrected it
local accounting_vars "ca_2021 ca_exp_2021 profit_2021"
local missing_2021 "ca_2021_missing ca_exp_2021_missing	profit_2021_missing"
foreach var of local acccounting_vars {
	gettoken cond missing_2021 : missing_2021
	replace needs_check = 1 if `var' == . & `cond' == 1
	replace questions_needing_checks = questions_needing_checks + "`var' manque même que l'entreprise dans la liste pour re-fournier donnés 2021 /" if `var' == . & `cond' == 1
	
}

	* Profits > sales
replace needs_check = 1 if surveyround == 2 & profit!=. & profit > ca 
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA / " if surveyround == 2 & profit!=. & profit > ca 


	* Export > sales 
replace needs_check = 1 if surveyround == 2 & ca_exp!=. & ca_exp > ca 
replace questions_needing_checks = questions_needing_checks + "Exports plus élevés que CA / " if surveyround == 2 & ca_exp!=. & ca_exp > ca


	* Outliers/extreme values: Very low values
		* ca_exp
replace needs_check = 1 if surveyround == 2 & ca_exp < 100 & ca_exp > 0
replace questions_needing_checks = questions_needing_checks + "export moins que 100 TND, demander comment possible / " if surveyround == 2 & ca_exp < 100 & ca_exp>0

		* ca
replace needs_check = 1 if surveyround == 2 & ca < 5000 & ca>0
replace questions_needing_checks = questions_needing_checks + "CA moins que 5000 TND, vérifier / " if surveyround == 2 & ca < 5000 & ca > 0

		* profit
				* just above zero
replace needs_check = 1 if surveyround == 2 & profit<2500 & profit>0 
replace questions_needing_checks = questions_needing_checks + "benefice moins que 2500 TND / " if surveyround == 2 & profit<2500 & profit>0 
				* just below zero
					*not sure what to do if profit is -999 as don't know
replace needs_check = 1 if surveyround == 2 & profit>-2500 & profit<0 & profit !=-999 & profit !=-888
replace questions_needing_checks = questions_needing_checks + "benefice + que -2500 TND mais - que zero / " if surveyround == 2 & profit>-2500 & profit<0 & profit !=-999 & profit !=-888

/* --------------------------------------------------------------------
	PART 2.4: Number of Employees
----------------------------------------------------------------------*/

	* employees > 200 (SME upper limit)
local nbempl car_carempl1 car_carempl2 car_carempl3 car_carempl4
 	
foreach var of local nb_empl {	
	replace needs_check = 1 if `var'>200 & surveyround==2 & id_plateforme != 1092 
	replace questions_needing_checks = questions_needing_checks + "ceci n'est pas une PME, verifier le nombre d'employées / " if `var'>200 & surveyround==2
}

	* employees = zero or missing
			* zero
replace needs_check = 1 if employes == 0 & surveyround==2
replace questions_needing_checks = questions_needing_checks + "zero employés / " if employes == 0 & surveyround==2

			* manquantes
replace needs_check = 1 if employes == . & surveyround==2
replace questions_needing_checks = questions_needing_checks + "nombre d'employés manque / " if employes == . & surveyround==2

***********************************************************************
* 	Part 3: large Outliers	(absolute, cross-sectional values)		
***********************************************************************
local acccounting_vars "ca ca_exp profit employes exprep_inv"
foreach var of local acccounting_vars {
	sum `var', d
	replace needs_check = 1 if `var' != .& surveyround == 2 & `var' > r(p95) & id_plateforme != 1092 
	replace questions_needing_checks = questions_needing_checks + "`var' très grand, vérifier / " if `var' != .& surveyround == 2 & `var' > r(p95)
}

***********************************************************************
* 	Part 4: Cross-checking answers from registration & baseline		
***********************************************************************
/* --------------------------------------------------------------------
	PART 4.1.: CA export
----------------------------------------------------------------------*/
* firms that reported to be exporters according to registration & baseline datas

		 * CA exp & pays d'export
/* does not apply to midline, recover at endline

replace needs_check = 1 if ca_exp > 0 & ca_exp!=. & exp_pays[_n-1] == . 
replace questions_needing_checks = questions_needing_checks + " exp_pays manquent pour entreprise avec ca_exp>0 / " if ca_exp>0 & ca_exp!=.  & exp_pays==. 

replace needs_check = 1 if ca_exp>0 & ca_exp!=. & exp_pays ==0 
replace questions_needing_checks = questions_needing_checks + " exp_pays zero pour entreprise avec ca_exp>0 / " if ca_exp>0 & ca_exp!=. & exp_pays==0 
*/


/* --------------------------------------------------------------------
	PART 4.2.: Growth rate in accounting variables
----------------------------------------------------------------------*/
local acccounting_vars "ca ca_exp profit employes"
foreach var of local acccounting_vars {
	sum `var'_abs_growth, d
	replace needs_check = 1 if `var'_abs_growth != . & `var'_abs_growth > r(p95) | `var'_abs_growth < r(p5)
	replace questions_needing_checks = questions_needing_checks + "différence extrême entre midline et baseline pour `var', vérifier / " if `var'_abs_growth != . & `var'_abs_growth > r(p95) | `var'_abs_growth < r(p5)
}


***********************************************************************
* 	Part 5: Add erroneous matricule fiscales
***********************************************************************
*use regex to check that matricule fiscale starts with 7 numbers followed by a letter
gen check_matricule = 1
replace check_matricule = 0 if ustrregexm(id_admin, "^[0-9]{7}[a-zA-Z]$") == 1
replace needs_check = 1 if check_matricule == 1 & surveyround ==2 & matricule_fisc_incorrect ==1
replace questions_needing_checks = questions_needing_checks + "matricule fiscale tjrs. faux. Appeler pour comprendre le problème." if check_matricule == 1 & surveyround ==2 & matricule_fisc_incorrect ==1

*manually adding matricules that conform with regex but are wrong anyways

replace needs_check = 1 if id_plateforme == 1083
replace questions_needing_checks = questions_needing_checks + "matricule fiscale tjrs. faux. Appeler pour comprendre le problème." if id_plateforme == 1083 & surveyround == 2
 
replace needs_check = 1 if id_plateforme == 1150
replace questions_needing_checks = questions_needing_checks + "matricule fiscale tjrs. faux. Appeler pour comprendre le problème." if id_plateforme == 1150 & surveyround == 2

replace needs_check = 1 if id_plateforme == 1197
replace questions_needing_checks = questions_needing_checks + "matricule fiscale tjrs. faux. Appeler pour comprendre le problème." if id_plateforme == 1197 & surveyround == 2

***********************************************************************
* 	PART 6:  Remove firms from needs_check in case calling them again did not solve the issue		
***********************************************************************
replace needs_check = 0 if id_plateforme == 985
replace needs_check = 0 if id_plateforme == 989
replace needs_check = 0 if id_plateforme == 991 // ca_exp +30%
replace needs_check = 0 if id_plateforme == 995 // injoingables
replace needs_check = 0 if id_plateforme == 997
replace needs_check = 0 if id_plateforme == 1005
replace needs_check = 0 if id_plateforme == 1007
replace needs_check = 0 if id_plateforme == 1008
replace needs_check = 0 if id_plateforme == 1019
replace needs_check = 0 if id_plateforme == 1022
replace needs_check = 0 if id_plateforme == 1027
replace needs_check = 0 if id_plateforme == 1028
replace needs_check = 0 if id_plateforme == 1033
replace needs_check = 0 if id_plateforme == 1036
replace needs_check = 0 if id_plateforme == 1037
replace needs_check = 0 if id_plateforme == 1044
replace needs_check = 0 if id_plateforme == 1054
replace needs_check = 0 if id_plateforme == 1065
replace needs_check = 0 if id_plateforme == 1067 
replace needs_check = 0 if id_plateforme == 1071
replace needs_check = 0 if id_plateforme == 1092
replace needs_check = 0 if id_plateforme == 1102
replace needs_check = 0 if id_plateforme == 1128
replace needs_check = 0 if id_plateforme == 1130
replace needs_check = 0 if id_plateforme == 1133
replace needs_check = 0 if id_plateforme == 1147
replace needs_check = 0 if id_plateforme == 1161
replace needs_check = 0 if id_plateforme == 1150
replace needs_check = 0 if id_plateforme == 1154
replace needs_check = 0 if id_plateforme == 1170
replace needs_check = 0 if id_plateforme == 1175
replace needs_check = 0 if id_plateforme == 1179
replace needs_check = 0 if id_plateforme == 1184
replace needs_check = 0 if id_plateforme == 1193
replace needs_check = 0 if id_plateforme == 1185
replace needs_check = 0 if id_plateforme == 1190
replace needs_check = 0 if id_plateforme == 1195
replace needs_check = 0 if id_plateforme == 1204
replace needs_check = 0 if id_plateforme == 1205
replace needs_check = 0 if id_plateforme == 1243
replace needs_check = 0 if id_plateforme == 1248

***********************************************************************
* 	PART 7:  Export an excel sheet with needs_check variables  			
***********************************************************************
*re-merge additional contact information to dataset (?)
/*
consortia: merge m:1 id_plateforme using  "${ml_raw}/consortia_ml_pii" 
keep if _merge==3 & surveyround == 2
e-commerce: merge 1:1 id_plateforme using "${consortia_master}/add_contact_data", generate(_merge_cd)
*/

preserve
			* generate empty variable for survey institute comments/corrections
gen commentaires_elamouri = ""

			* keep order stable
sort id_plateforme, stable

			* adjust needs check to panel structure (same value for each surveyround)
				* such that when all values for each firms are kepts dropping those firms
					* that do not need checking
						* 1: needs_check
egen keep_check = max(needs_check), by(id_plateforme)
drop needs_check
rename keep_check needs_check
keep if needs_check > 0 // drop firms that do not need check

						* 2: questions needing check
egen occurence = count(id_plateforme), by(id_plateforme)
drop if occurence < 2 // drop firms that have not yet responded to midline 
drop occurence
			
			* export excel file. manually add variables listed in questions_needing_check
				* group variables into lists (locals) to facilitate overview
local order_vars "id_plateforme surveyround needs_check refus date heure validation survey_phone   commentaires_elamouri questions_needing_checks produit1 produit2 produit3"
local accounting_vars "`order_vars' id_admin ca ca_exp profit ca_2021 ca_exp_2021 profit_2021 ca_2021_missing ca_exp_2021_missing profit_2021_missing"
local export_vars "`accounting_vars' exprep_inv exp_pays"
local network_vars "`export_vars' net_nb_f net_nb_m"
local employee_vars "`network_vars' employes car_empl1 car_empl2 car_empl3 car_empl4 car_empl5"
					
				* export
export excel `employee_vars' ///
   using "${ml_checks}/fiche_correction.xlsx", sheetreplace firstrow(var) datestring("%-td")


restore
