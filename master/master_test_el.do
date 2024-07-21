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
**********************************************************************
/* --------------------------------------------------------------------
	PART 2.1: Export Questions
----------------------------------------------------------------------*/
*Clients number is too huge
replace needs_check = 1 if surveyround==3 & clients > 10000 & clients != .
replace questions_needing_checks = questions_needing_checks + "Nombre de clients international superiéur à 10000, veuillez vérifier aussi le nombre de clients SSA. / "  if surveyround==3 & clients > 10000 & clients != .

*Does export practices and activties, but no client?
local export_act "exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_norme exp_pra_vent ssa_action1 ssa_action2 ssa_action3 ssa_action4"
foreach var of local export_act {
	replace needs_check = 1 if surveyround == 3 & `var' == 1 & clients == 0
	replace questions_needing_checks = questions_needing_checks + "L'entreprise dit qu'elle fait `var', mais elle n'a pas de clients, veuillez vérifier. / " if surveyround == 3 & `var' == 1 & clients == 0
}

/* --------------------------------------------------------------------
	PART 2.2: Management Questions
----------------------------------------------------------------------*/	
*management 
	*follows performance indicators but says they never track it
local mana_perf "man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv"
foreach var of local mana_perf {
	replace needs_check = 1 if surveyround == 3 & `var' == 1 & man_fin_per_fre  == 0
	replace questions_needing_checks = questions_needing_checks + "L'entreprise dit qu'elle suit `var', mais elle indique qu'elle la fréquence est de jamais, veuillez vérifier. / " if surveyround == 3 & `var' == 1 & man_fin_per_fre  == 0
}

*network
replace needs_check = 1 if surveyround==3 & net_association > 10 & net_association !=.
replace questions_needing_checks = questions_needing_checks + "L'entreprise a plus de 10 contacts d'affaire, veuillez vérifier. / " if surveyround==3 & net_association > 10 & net_association !=.

*is treatment but has 0 associations
replace needs_check = 1 if surveyround==3 & treatment ==1 & net_association == 0
replace questions_needing_checks = questions_needing_checks + "L'entreprise est traitement, donc elle est membre du consortium, veuillez vérifier. / " if surveyround==3 & treatment ==1 & net_association == 0

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

/*	FILTERED BY EL AMOURI
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
*/
		*profit2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2023 > 1000000 & comp_benefice2023 != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2023 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & comp_benefice2023 > 1000000 & comp_benefice2023 != . 
	
		*profit2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2024 > 1000000 & comp_benefice2024 != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2024 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & comp_benefice2024 > 1000000 & comp_benefice2024 != . 

		*ca2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_ca2023 > 2000000 & comp_ca2023 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 2 millions de dinars / " if surveyround == 3 & comp_ca2023 > 2000000 & comp_ca2023 != . 
	
		*ca2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_ca2024 > 2000000 & comp_ca2024 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 2 millions de dinars / " if surveyround == 3 & comp_ca2024 > 2000000 & comp_ca2024 != . 

		*ca_exp2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & compexp_2023 > 1500000 & compexp_2023 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 1.5 millions de dinars / " if surveyround == 3 & compexp_2023 > 2000000 & compexp_2023 != . 
	
		*ca_exp2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_ca2024 > 1500000 & comp_ca2024 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 1.5 millions de dinars / " if surveyround == 3 & comp_ca2024 > 2000000 & comp_ca2024 != . 


/* THERE WILL BE AN INTERVAL
		*comptability vars that should not be 1234
local not1234_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 mark_invest dig_invest"

foreach var of local not1234_vars {
	replace needs_check = 1 if `var' == 1234 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "Les intervalles utilisés `var' ne sont possible que pour le profit / " if `var' == 1234 & surveyround == 3
}
*/

/* --------------------------------------------------------------------
	PART 2.4: Networking questions
----------------------------------------------------------------------*/

replace needs_check = 1 if net_size3 > 0 & net_services_pratiques == . & surveyround == 3 & attest == 1
replace questions_needing_checks = questions_needing_checks + "Réponses net_services manquantes alors que le nombre de contact avec d'autres entrepreneurs est > 0, veuillez vérifier. / " if net_size3 > 0 & net_services_pratiques == . & surveyround == 3 & attest == 1

***********************************************************************
* 	Part 3: Cross-checking answers from baseline & midline		
***********************************************************************
*generate financial per empl
local varn ca_2018 ca_2019 ca_2020 ca_2021 ca_exp2018 ca_exp2019 ca_exp2020 ca_exp_2021 profit_2021

foreach x of local varn { 
gen n`x' = 0
replace n`x' = . if `x' == -777
replace n`x' = . if `x' == -888
replace n`x' = . if `x' == -999
replace n`x' = `x'/employes if n`x'!= .
}

*add inflation //https://www.focus-economics.com/country-indicator/tunisia/inflation/#:~:text=Inflation%20in%20Tunisia,information%2C%20visit%20our%20dedicated%20page
replace nca_2018 = nca_2018*1.356
replace nca_2019 = nca_2018*1.289
replace nca_2020 = nca_2018*1.233
replace nca_2021 = nca_2018*1.176

replace nca_exp2018 = nca_exp2018*1.356
replace nca_exp2019 = nca_exp2019*1.289
replace nca_exp2020 = nca_exp2020*1.233

replace nprofit_2021 = nprofit_2021*1.176

*manual thresholds at 95% (Highest among surveyrounds)
	*turnover total

local old_turnover "nca_2018 nca_2019 nca_2020 nca_2021"
local new_turnover "ncomp_ca2023 ncomp_ca2024"
scalar maxtt_p95 = 0

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
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport aux dernières vagues, vérifier / " if `var' != . & surveyround == 3 & `var' > maxtt_p95
}	

	*turnover export
local old_turnoverexp "nca_exp2018 nca_exp2019 nca_exp2020 nca_exp_2021"
local new_turnoverexp "ncompexp_2023 ncompexp_2024"
scalar maxte_p95 = 0

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
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport aux dernières vagues, vérifier / " if `var' != . & surveyround == 3 & `var' > maxte_p95
}	

	*profit
local new_profit "ncomp_benefice2023 ncomp_benefice2024"

foreach var of local new_profit {
	sum profit_2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) 
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport aux dernières vagues, vérifier / " if `var' != . & surveyround == 3 & `var' > r(p95)
}	

		*employees
local fte_surveyround "surveyround==1 surveyround==2"
scalar maxm_p95 = 0

foreach var of local fte_surveyround {
    sum employes if `var', detail
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
local test_vars "employes dig_empl mark_invest dig_invest comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
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
local compta_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 666
	replace questions_needing_checks = questions_needing_checks + "`var' est 666, il faut rappeler la personne responsable de la comptabilité. / " if surveyround == 3 & `var' == 666
	
}
		*777
local compta_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 777
	replace questions_needing_checks = questions_needing_checks + "`var' est 777, Il faut réécouter l'appel / " if surveyround == 3 & `var' == 777
	
}

***********************************************************************
<<<<<<< Updated upstream
* 	PART 8:  Export an excel sheet with needs_check variables  			
=======
* 	PART 8:  Manually cancel needs_check if fixed	
***********************************************************************
replace needs_check = 0 if id_plateforme == 1026 // large outlier firm, comptability should be fine.

***********************************************************************
* 	PART 9:  Second test sheet
***********************************************************************
replace needs_check = 1 if net_gender3 > 30 & surveyround == 3 & net_gender3 != .
replace questions_needing_checks = questions_needing_checks + "Nombre de discussions d'affaire avec les autres femmes entrepreneuses est supérieur à 30, veuillez vérifier. / " if net_gender3 > 30 & surveyround == 3 & net_gender3 != .

replace needs_check = 1 if net_gender4 > 30 & surveyround == 3 & net_gender4 != .
replace questions_needing_checks = questions_needing_checks + "Nombre de discussions d'affaire avec les memebres de la famille femmes est supérieur à 30, veuillez vérifier. / " if net_gender4 > 30 & surveyround == 3 & net_gender4 != .

replace needs_check = 1 if net_gender3_giz > 30 & surveyround == 3 & net_gender3_giz != .
replace questions_needing_checks = questions_needing_checks + "Nombre d'entrepreneuses femmes rencontré aux activités GIZ est supérieur à 30, veuillez vérifier. / " if net_gender3_giz > 30 & surveyround == 3 & net_gender3_giz != .

***********************************************************************
* 	PART 9:  Export an excel sheet with needs_check variables  			
>>>>>>> Stashed changes
***********************************************************************
replace needs_check = 0 if id_plateforme =="984" 
replace needs_check = 0 if id_plateforme =="986" 
replace needs_check = 0 if id_plateforme =="988" 
replace needs_check = 0 if id_plateforme =="996" 
replace needs_check = 0 if id_plateforme =="999" 
replace needs_check = 0 if id_plateforme =="1000" 
replace needs_check = 0 if id_plateforme =="1005" 
replace needs_check = 0 if id_plateforme =="1009" 
replace needs_check = 0 if id_plateforme =="1010" 
replace needs_check = 0 if id_plateforme =="1017" 
replace needs_check = 0 if id_plateforme =="1019" 
replace needs_check = 0 if id_plateforme =="1027" 
replace needs_check = 0 if id_plateforme =="1028" 
replace needs_check = 0 if id_plateforme =="1035" 
replace needs_check = 0 if id_plateforme =="1036" 
replace needs_check = 0 if id_plateforme =="1043" 
replace needs_check = 0 if id_plateforme =="1046" 
replace needs_check = 0 if id_plateforme =="1049" 
replace needs_check = 0 if id_plateforme =="1054" 
replace needs_check = 0 if id_plateforme =="1059" 
replace needs_check = 0 if id_plateforme =="1065" 
replace needs_check = 0 if id_plateforme =="1068" 
replace needs_check = 0 if id_plateforme =="1081" 
replace needs_check = 0 if id_plateforme =="1083" 
replace needs_check = 0 if id_plateforme =="1087" 
replace needs_check = 0 if id_plateforme =="1084" 
replace needs_check = 0 if id_plateforme =="1097" 
replace needs_check = 0 if id_plateforme =="1108" 
replace needs_check = 0 if id_plateforme =="1118" 
replace needs_check = 0 if id_plateforme =="1122" 
replace needs_check = 0 if id_plateforme =="1125" 
replace needs_check = 0 if id_plateforme =="1126" 
replace needs_check = 0 if id_plateforme =="1128" 
replace needs_check = 0 if id_plateforme =="1133" 
replace needs_check = 0 if id_plateforme =="1134" 
replace needs_check = 0 if id_plateforme =="1135" 
replace needs_check = 0 if id_plateforme =="1147" 
replace needs_check = 0 if id_plateforme =="1151" 
replace needs_check = 0 if id_plateforme =="1164" 
replace needs_check = 0 if id_plateforme =="1167" 
replace needs_check = 0 if id_plateforme =="1176" 
replace needs_check = 0 if id_plateforme =="1178" 
replace needs_check = 0 if id_plateforme =="1179" 
replace needs_check = 0 if id_plateforme =="1182" 
replace needs_check = 0 if id_plateforme =="1186" 
replace needs_check = 0 if id_plateforme =="1191" 
replace needs_check = 0 if id_plateforme =="1197" 
replace needs_check = 0 if id_plateforme =="1203" 
replace needs_check = 0 if id_plateforme =="1224" 
replace needs_check = 0 if id_plateforme =="1231" 
replace needs_check = 0 if id_plateforme =="1234" 
replace needs_check = 0 if id_plateforme =="1239" 
replace needs_check = 0 if id_plateforme =="1243" 



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
local order_vars "id_plateforme needs_check attest survey_phone treatment commentaires_elamouri questions_needing_checks"
local accounting_vars "`order_vars' employes comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
local export_vars "`accounting_vars' clients exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_norme exp_pra_vent ssa_action1 ssa_action2 ssa_action3 ssa_action4"
local management_vars "`export_vars' man_fin_per_fre man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv"
local networking_vars "`management_vars' net_size3 net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre"
local employee_vars "`networking_vars' car_empl1"
					
				* export
export excel `employee_vars' ///
   using "${el_checks}/fiche_correction.xlsx" if surveyround == 3, sheetreplace firstrow(var) datestring("%-td")


restore
