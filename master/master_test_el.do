***********************************************************************
* 			consortia master logical tests                           *	
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
*	Author:  Ayoub Chamakhi
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
	PART 2.1: Export Questions
----------------------------------------------------------------------*/	
replace needs_check = 1 if surveyround == 3 &  clients_b2c_ssa > clients_b2c
replace questions_needing_checks = "nombre de pays d'export plus grand que pays SSA (B2C) / "  if surveyround == 3 &  clients_b2c_ssa > clients_b2c

replace needs_check = 1 if surveyround == 3 &  clients_b2b_ssa > clients_b2b
replace questions_needing_checks = "nombre de pays d'export plus grand que pays SSA (B2B) / "  if surveyround == 3 &  clients_b2b_ssa > clients_b2b

/* --------------------------------------------------------------------
	PART 2.2: Management Questions
----------------------------------------------------------------------*/	
*marketing 
	*uses marketing tools but does not invest in it
foreach var of ​"man_mark_prix  ​man_mark_clients  ​man_mark_pub  ​man_mark_dig" {
	replace needs_check = 1 if surveyround == 3 & `var' == 1 & investissement  == 0
	replace questions_needing_checks = "L'entreprise n'a pas d'investissement mais elle fait `var' / " if surveyround == 3 & `var' == 1 & investissement  == 0
}

*marketing 
	*uses marketing tools but does not invest in it
foreach var of "inno_proc_met inno_proc_log inno_proc_sup" {
	replace needs_check = 1 if surveyround == 3 & `var' == 1 & investissement  == 0
	replace questions_needing_checks = "L'entreprise n'a pas d'investissement mais elle fait `var' / " if surveyround == 3 & `var' == 1 & investissement  == 0
}
/* --------------------------------------------------------------------
	PART 2.3: Comptabilité / accounting questions
----------------------------------------------------------------------*/		
/* 0 NOW SHOWS AN INTERVAL
	* turnover zero
local accountvars comp_ca2023 comp_ca2024
foreach var of local accountvars {
		* = 0
	replace needs_check = 1 if surveyround == 3 & `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' est rare d'être zero, êtes vous sure? / " if surveyround == 3 & `var' == 0 
	
}


	* turnover export zero even though it exports
local accountexpvars compexp_2023 compexp_2024
foreach var of local accountexpvars {
		* = 0
	replace needs_check = 1 if surveyround == 3 & `var' == 0 & export_1 == 1 & export_2 == 1
	replace questions_needing_checks = questions_needing_checks + "`var' est zero alors qu'elle exporte, êtes vous sure? / " if surveyround == 3 & `var' == 0  & export_1 == 1 & export_2 == 1
	
}	
*/

	*Company does not export but has ca export
	
replace needs_check = 1 if (compexp_2023 > 0 | compexp_2024 > 0 ) & surveyround == 3 & export_1 == 0 & export_2 == 0 & compexp_2023 != 666 & compexp_2023 != 777 & compexp_2023 != 888 & compexp_2023 != 999 & compexp_2023 != . & compexp_2023 != 1234 & compexp_2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 1234
replace questions_needing_checks = questions_needing_checks + "L'entreprise n'export pas alors qu'elle a ca export / " if (compexp_2023 > 0 | compexp_2024 > 0 ) & surveyround == 3 & export_1 == 0 & export_2 == 0 & compexp_2023 != 666 & compexp_2023 != 777 & compexp_2023 != 888 & compexp_2023 != 999 & compexp_2023 != . & compexp_2023 != 1234 & compexp_2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 1234
	
	* Profits > sales 2023

replace needs_check = 1 if surveyround == 3 & comp_benefice2023 > comp_ca2023 & comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 & comp_benefice2023 != 999 & comp_benefice2023 != 1234 & comp_benefice2023 != . ///
	& comp_benefice2023 != 0 & comp_ca2023 != 666 & comp_ca2023 != 777 & comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA 2023 / "  if surveyround == 3 & comp_benefice2023 > comp_ca2023 & comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 & 	  comp_benefice2023 != 999 & comp_benefice2023 != 1234 & comp_benefice2023 != . & comp_benefice2023 != 0 & comp_ca2023 != 666 & comp_ca2023 != 777 & comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234

	* Profits > sales 2024
	
replace needs_check = 1 if surveyround == 3 & comp_benefice2024 > comp_ca2024 & compexp_2024 != 666 & compexp_2024 != 777 & compexp_2024 != 888 & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234 & ///
	comp_benefice2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA 2024 / "  if surveyround == 3 & comp_benefice2024 > comp_ca2024 & compexp_2024 != 666 & compexp_2024 != 777 & compexp_2024 != 888 ///
	& compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234 & comp_benefice2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234

	* Outliers/extreme values: Very low values
		* ca2023
	
replace needs_check = 1 if surveyround == 3 & comp_ca2023 < 5000 & comp_ca2023 != 666 & comp_ca2023 != 777 & comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234
replace questions_needing_checks = questions_needing_checks + "CA 2023 moins que 5000 TND, êtes vous sure? / " if surveyround == 3 & comp_ca2023 < 5000 & comp_ca2023 != 666 & comp_ca2023 != 777 ///
	& comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234

		* ca2024

replace needs_check = 1 if surveyround == 3 & comp_ca2024 < 5000 & comp_ca2024 != 666 & comp_ca2024 != 777 & comp_ca2024 != 888 & comp_ca2024 != 999 & comp_ca2024 != . & comp_ca2024 != 0 & comp_ca2024 != 1234
replace questions_needing_checks = questions_needing_checks + "CA 2024 moins que 5000 TND, êtes vous sure? / " if surveyround == 3 & comp_ca2024 < 5000 ///
	& comp_ca2024 != 666 & comp_ca2024 != 777 & comp_ca2024 != 888 & comp_ca2024 != 999 & comp_ca2024 != . & comp_ca2024 != 0 & comp_ca2024 != 1234

		* profit2023 just above zero

replace needs_check = 1 if surveyround == 3 & comp_benefice2023 < 2500 & comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 ///
	& comp_benefice2023 != 999 & comp_benefice2023 != . & comp_benefice2023 != 0 & comp_benefice2023 != 1234 
replace questions_needing_checks = questions_needing_checks + "Benefice 2023 moins que 2500 TND / " if surveyround == 3 & comp_benefice2023 < 2500 ///
	& comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 & comp_benefice2023 != 999 & comp_benefice2023 != . & comp_benefice2023 != 0 & comp_benefice2023 != 1234 

		* profit2024 just above zero

replace needs_check = 1 if surveyround == 3 & comp_benefice2024 < 2500 & comp_benefice2024 != 666 & comp_benefice2024 != 777 & comp_benefice2024 != 888 ///
	& comp_benefice2024 != 999 & comp_benefice2024 != . & comp_benefice2024 != 0 & comp_benefice2024 != 1234
replace questions_needing_checks = questions_needing_checks + "benefice 2024 moins que 2500 TND / " if surveyround == 3 & comp_benefice2024 < 2500 ///
	& comp_benefice2024 != 666 & comp_benefice2024 != 777 & comp_benefice2024 != 888 & comp_benefice2024 != 999 & comp_benefice2024 != . & comp_benefice2024 != 0 & comp_benefice2024 != 1234


		* profit2023 just below zero
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2023 > -2500 & comp_benefice2023 < 0  & comp_benefice2023 != . & comp_benefice2023 != 1234 & comp_benefice2023 != 0
replace questions_needing_checks = questions_needing_checks + "benefice 2023 + que -2500 TND mais - que zero / " if surveyround == 3 & comp_benefice2023 > -2500 ///
	& comp_benefice2023 < 0  & comp_benefice2023 != . & comp_benefice2023 != 1234 & comp_benefice2023 != 0

		* profit2024 just below zero
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2024 > -2500 & comp_benefice2024 < 0  & comp_benefice2024 != . & comp_benefice2024 != 1234 & comp_benefice2024 != 0
replace questions_needing_checks = questions_needing_checks + "benefice 2024 + que -2500 TND mais - que zero / " if surveyround == 3 & comp_benefice2024 > -2500 & comp_benefice2024 < 0 ///
	& comp_benefice2024 != . & comp_benefice2024 != 1234 & comp_benefice2024 != 0

		*profit2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2023 > 1000000 & comp_benefice2023 != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2023 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & comp_benefice2023 > 1000000 & comp_benefice2023 != . 
	
		*profit2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2024 > 1000000 & comp_benefice2024 != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2024 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & comp_benefice2024 > 1000000 & comp_benefice2024 != . 

replace needs_check = 1 if investissement == 1234 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "Intervalle pas possible pour investissement / " if investissement == 1234 & surveyround == 3


/* THERE WILL BE AN INTERVAL
		*comptability vars that should not be 1234
local not1234_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 mark_invest dig_invest"

foreach var of local not1234_vars {
	replace needs_check = 1 if `var' == 1234 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "Les intervalles utilisés `var' ne sont possible que pour le profit / " if `var' == 1234 & surveyround == 3
}
*/

***********************************************************************
* 	Part 3: Cross-checking answers from baseline & midline		
***********************************************************************
*manual thresholds at 95% (Highest among surveyrounds)
	*turnover total
local old_turnover "ca_2018 ca_2019 ca_2020 ca_2021"
local new_turnover "comp_ca2023 comp_ca2024"
local maxtt_p95 = 0

foreach var of local old_turnover {
    sum `var', d
	
	if r(p95) > maxtt_p95 {
	
	scalar drop maxtt_p95
	scalar maxtt_p95 = r(p95)
	scalar list
}
}

foreach var of local new_turnover {
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' > maxtt_p95
	replace questions_needing_checks = questions_needing_checks + "`var' très grand par rapport aux dernières vagues, vérifier / " if `var' != . & surveyround == 3 & `var' > maxtt_p95
}	

	*turnover export
local old_turnoverexp "ca_exp2018 ca_exp2019 ca_exp2020 ca_exp_2021"
local new_turnoverexp "compexp_ca2023 compexp_ca2024"
local maxte_p95 = 0

foreach var of local old_turnover {
    sum `var', d
	
	if r(p95) > maxte_p95 {
	
	scalar drop maxte_p95
	scalar maxte_p95 = r(p95)
	scalar list
}
}


foreach var of local new_turnoverexp {
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' > maxte_p95
	replace questions_needing_checks = questions_needing_checks + "`var' très grand par rapport aux dernières vagues, vérifier / " if `var' != . & surveyround == 3 & `var' > maxte_p95
}	

	*profit
local new_profit "compbenefice_2023 compbenefice_2024"

foreach var of local new_profit {
	sum profit_2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) 
	replace questions_needing_checks = questions_needing_checks + "`var' très grand par rapport aux dernières vagues, vérifier / " if `var' != . & surveyround == 3 & `var' > r(p95)
}	

		*employees
local fte_surveyround "surveyround==1 surveyround==2"
scalar maxm_p95 = 0

foreach var of local fte_surveyround {
    sum fte if `var', detail
    if r(p95) > maxm_p95 {
		scalar drop maxm_p95
		scalar maxm_p95 = r(p95)
		di maxm_p95
	}
}

replace needs_check = 1 if employes != . & surveyround == 3 & employes > maxm_p95
replace questions_needing_checks = questions_needing_checks + "employés très grand par rapport aux dernières vagues, êtes vous sure? / " if employes != . & surveyround == 3 & employes > maxm_p95

*employees femmes
local fte_surveyround "surveyround==1 surveyround==2"
scalar maxf_p95 = 0

foreach var of local fte_surveyround {
    sum car_empl1 if `var', detail
    if r(p95) > maxf_p95 {
		scalar drop maxf_p95
		scalar maxf_p95 = r(p95)
		di maxf_p95
	}
}

replace needs_check = 1 if car_empl1 != . & surveyround == 3 & car_empl1 > maxm_p95
replace questions_needing_checks = questions_needing_checks + "employés femmes très grand par rapport aux dernières vagues, êtes vous sure? / " if car_empl1 != . & surveyround == 3 & car_empl1 > maxm_p95

***********************************************************************
* 	Part 5: Add erroneous matricule fiscales
***********************************************************************
*use regex to check that matricule fiscale starts with 7 numbers followed by a letter
gen check_matricule = 1
replace check_matricule = 0 if ustrregexm(id_admin, "^[0-9]{7}[a-zA-Z]$") == 1
replace needs_check = 1 if check_matricule == 1 & surveyround == 3 & matricule_fisc_incorrect == 1
replace questions_needing_checks = questions_needing_checks + "matricule fiscale fausse / " if check_matricule == 1 & surveyround == 3 & matricule_fisc_incorrect ==1

*manually adding matricules that conform with regex but are wrong anyways

*replace needs_check = 1 if id_plateforme == 1083
*replace questions_needing_checks = questions_needing_checks + "matricule fiscale tjrs. faux. Appeler pour comprendre le problème." if id_plateforme == 1083 & surveyround == 2


***********************************************************************
* 	PART 6:  Remove firms from needs_check in case calling them again did not solve the issue		
***********************************************************************

***********************************************************************
* 	PART 7: Variable has been tagged as "needs_check" = 888, 777 or .
***********************************************************************
/*
local test_vars "fte dig_empl mark_invest dig_invest comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local test_vars {
	replace needs_check = 1 if `var' == 888 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "`var' = 888, êtes vous sure? / " if `var' == 888 & surveyround == 3
	replace needs_check = 1 if `var' == 777 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "`var' = 777, êtes vous sure? / " if `var' == 777 & surveyround == 3
	replace needs_check = 1 if `var' == 999 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "`var' = 999, êtes vous sure? / " if `var' == 999 & surveyround == 3
	replace needs_check = 1 if `var' == . & surveyround == 3 & exporter == 1
	replace questions_needing_checks = questions_needing_checks + "`var' = missing, êtes vous sure? / " if `var' == . & surveyround == 3 & exporter == 1
}
*/

*tackling problematique answer codes
		*666
local compta_vars "investissement comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 666
	replace questions_needing_checks = questions_needing_checks + "`var' est 666, il faut rappeler la personne responsable de la comptabilité. / " if surveyround == 3 & `var' == 666
	
}
		*777
local compta_vars "investissement comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 777
	replace questions_needing_checks = questions_needing_checks + "`var' est 777, Il faut réécouter l'appel / " if surveyround == 3 & `var' == 777
	
}

***********************************************************************
* 	PART 8:  Export an excel sheet with needs_check variables  			
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
local order_vars "id_plateforme surveyround needs_check refus date heure validation survey_phone commentaires_elamouri questions_needing_checks"
local accounting_vars "`order_vars' empl id_admin investissement comp_ca2023 comp_ca2024 comp_exp2023 comp_exp2024 comp_benefice2023 comp_benefice2024"
local export_vars "`accounting_vars' clients_b2c_ssa clients_b2c clients_b2b_ssa clients_b2b"
local management_vars "`export_vars' inno_proc_met inno_proc_log inno_proc_supman_mark_prix  ​man_mark_clients  ​man_mark_pub  ​man_mark_dig"
local employee_vars "`management_vars' car_carempl_div1 id_admin"
					
				* export
export excel `employee_vars' ///
   using "${ml_checks}/fiche_correction.xlsx" if surveyround == 3, sheetreplace firstrow(var) datestring("%-td")


restore
