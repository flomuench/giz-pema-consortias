***********************************************************************
* 			consortia master call list	                              *	
***********************************************************************
*																	    
*	PURPOSE: Creates a list of firms to call			  							  
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
*	6)		Manual corrections of needs_recall after Amouri Feedback 
*	7)		Export an excel sheet with needs_recall variables 
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

gen needs_recall = 0
lab var needs_recall "Firms to be recalled by El Amouri"

gen questions_needing_checks  = ""
lab var questions_needing_checks "questions to be checked by El Amouri"

***********************************************************************
* 	PART 2:  Define logical tests
***********************************************************************
	*firms who refused to answer
replace needs_recall = 1 if refus == 1 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "Veuillez rappeler les entreprises qui ont refusées de répondre / " if refus == 1 & surveyround == 3

	*missing values for net_services*
replace needs_recall = 1 if surveyround == 3 & refus == 0 & net_services_pratiques == .
replace questions_needing_checks = questions_needing_checks + "Veuillez rappeler les entreprises pour les questions de net_services manquantes / " if surveyround == 3 & refus == 0 & net_services_pratiques == .

	*missing values for compta
local missing_compta_vars "ca ca_2024 ca_exp ca_exp_2024 profit profit_2024"

foreach var of local missing_compta_vars {
	replace needs_recall = 1 if `var' == . & surveyround == 3 & refus == 0
	replace questions_needing_checks = questions_needing_checks + "La variable `var' a une valeur manquante, Veuillez rappeler / " if `var' == . & surveyround == 3 & refus == 0
}

	*single cases
replace needs_recall = 1 if id_plateforme == 1244 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "Veuillez revérifier le chiffre d'affaire à l'export / " if id_plateforme == 1244 & surveyround == 3 

replace needs_recall = 1 if id_plateforme == 1231 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "Sa soeur a répondue, elle a demandée d'appeler plus tard / " if id_plateforme == 1231 & surveyround == 3 

***********************************************************************
* 	PART 3:  Export an excel sheet with needs_recall variables  			
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
						* 1: needs_recall
egen keep_check = max(needs_recall), by(id_plateforme)
drop needs_recall
rename keep_check needs_recall
keep if needs_recall > 0 // drop firms that do not need check

						* 2: questions needing check
egen occurence = count(id_plateforme), by(id_plateforme)
drop if occurence < 2 // drop firms that have not yet responded to midline 
drop occurence

			* export excel file. manually add variables listed in questions_needing_check
				* group variables into lists (locals) to facilitate overview
local order_vars "id_plateforme needs_recall treatment commentaires_elamouri questions_needing_checks"
local accounting_vars "`order_vars' refus ca ca_2024 ca_exp ca_exp_2024 profit profit_2024"
local network_vars "`accounting_vars' net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre net_services_other"
				
* Export to Excel
export excel `network_vars' using "${el_checks}/fiche_d'appel.xlsx" ///
   if surveyround == 3, sheetreplace firstrow(var) datestring("%-td")

restore