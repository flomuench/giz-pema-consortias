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
/*
* If any of the accounting vars corresponds to the scalars (not_know: -999 ; refused: -888; or check_again = -777) change needs_check to 2

local accountvars investcom_2021 investcom_futur expprep_responsable exp_pays_avant21 exp_pays_21 compexp_2020 comp_ca2020 comp_benefice2020 dig_revenues_ecom car_carempl_div1 car_carempl_dive2 car_carempl_div3 car_adop_peer

gen scalar_issue = 0

foreach var of local accountvars {
	replace needs_check = 2 if `var' == -999 
	replace scalar_issue = 1 if `var' ==  -999
	replace questions_needing_checks = "`var' pas connue & " + questions_needing_checks if `var' == -999 

	replace needs_check = 2 if `var' == -888 
	replace scalar_issue = 1 if `var' == -888
	replace questions_needing_checks = "`var' refusée & " + questions_needing_checks if `var' == -888 
	
	replace needs_check = 2 if `var' == -777 
	replace scalar_issue = 1 if `var' == -777
	replace questions_needing_checks = "`var' doit être verifiée & " + questions_needing_checks if `var' == -777 

}

* If profits are larger than 'chiffres d'affaires' need to check: 
 
replace needs_check = 1 if comp_benefice2020>comp_ca2020 & comp_ca2020!=. & comp_benefice2020!=. & scalar_issue==0
replace questions_needing_checks = questions_needing_checks + " Benefices sont plus élevés que comptes d'affaires & " if comp_benefice2020>comp_ca2020 & comp_ca2020!=. & comp_benefice2020!=. & scalar_issue==0

* Check if export values are larger than total revenues 

replace needs_check = 1 if comp_ca2020< compexp_2020 & comp_ca2020!=. & compexp_2020!=. & scalar_issue==0
replace questions_needing_checks = questions_needing_checks +  " Export sont plus élevés que comptes d'affaires & " if comp_ca2020< compexp_2020 & comp_ca2020!=. & compexp_2020!=. & scalar_issue==0

* Check if online revenu is higher than overall revenue

capture replace needs_check = 1 if  comp_ca2020 < dig_revenues_ecom & dig_revenues_ecom!=. & comp_ca2020!=. & scalar_issue==0
capture replace questions_needing_checks = questions_needing_checks +  "Revenues en ligne sont plus élevés que comptes d'affaires & " if  comp_ca2020 < dig_revenues_ecom & dig_revenues_ecom!=. & comp_ca2020!=. & scalar_issue==0

* If number of export countries is higher than 100 – needs check (it's sus)

capture replace needs_check = 1 if  exp_pays_avant21 > 100 & exp_pays_avant21!=. & rg_oper_exp == 1
//capture replace needs_check = 1 if exp_pays_avant21==. &  rg_oper_exp == 1 & exp_pays>1
capture replace questions_needing_checks = questions_needing_checks +  "Vérifer nombre de pays dans exp_pays_avant21 & " if  exp_pays_avant21 > 100 & exp_pays_avant21!=. & rg_oper_exp == 1

capture replace needs_check = 1 if  exp_pays_21 > 100 & exp_pays_21!=. & rg_oper_exp == 1
capture replace questions_needing_checks = questions_needing_checks +  "Vérifer nombre de pays dans exp_pays_21 & " if  exp_pays_21 > 100 & exp_pays_21!=. & rg_oper_exp == 1




/* --------------------------------------------------------------------
	PART 2.2: Indices / questions with points
----------------------------------------------------------------------*/		

local unit_scores dig_presence_score dig_miseajour1 dig_miseajour2 dig_miseajour3 dig_payment1 dig_payment2 dig_payment3 dig_vente dig_marketing_lien dig_marketing_score dig_marketing_ind1 dig_marketing_ind2 dig_logistique_entrepot dig_logistique_retour_score dig_service_satisfaction expprep_cible expprep_norme rg_oper_exp exp_afrique 

foreach var of local acunit_scores {
	replace needs_check = 1 if `var'>1 & `var'!=.
	replace questions_needing_checks = questions_needing_checks + "`var' too high & " if `var'>1 & `var'!=.
	
	replace needs_check = 1 if `var'<0 & `var'!=-999  & `var'!=-888 & `var'!=-777
	replace questions_needing_checks = questions_needing_checks + "`var' too low & " if `var'<0 & `var'!=-999  & `var'!=-888 & `var'!=-777

} 

local cont_vars dig_marketing_respons dig_service_responsable expprep_responsable exp_pays_avant21 exp_pays_21

foreach var of local cont_vars {

	replace needs_check = 1 if `var'<0 & `var'!=-999 & `var'!=-888 & `var'!=-777
	replace questions_needing_checks = questions_needing_checks + "`var' too low & " if `var'<0 & `var'!=-999 & `var'!=-888 & `var'!=-777

} 

* check accounting answers that are empty: 

foreach var of local accountvars {
	capture replace needs_check = 1 if `var' == . 
	capture replace questions_needing_checks = questions_needing_checks + "`var' manque & " if `var' == . 
}


drop scalar_issue


***********************************************************************
* 	Export an excel sheet with needs_check variables  			
***********************************************************************

capture drop dup

sort id_plateforme, stable

quietly by id_plateforme:  gen dup = cond(_N==1,0,_n)

replace needs_check = 1 if dup>0

gen commentaires_ElAmouri = .

cd "$bl_checks"

order id_plateforme check questions_needing_check commentaires_ElAmouri commentsmsb 

export excel commentaires_ElAmouri id_plateforme commentsmsb check questions_needing_check heure date-dig_logistique_retour_score using "fiche_correction" if needs_check>=1, firstrow(variables) replace

