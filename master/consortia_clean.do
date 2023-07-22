***********************************************************************
* 			consortia master do files: final cleaning  
***********************************************************************
*																	  
*	PURPOSE: clean inconsistencies related to merging survey data sets						  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*				PART 2: clean bl_final	  
*				PART 3:                         											  
*																	  
*	Author:  	Florian Münch, Fabian Scheifele & Siwar Hakim							    
*	ID variable: id_email		  					  
*	Requires:  	 regis_final.dta bl_final.dta 										  
*	Creates:     regis_final.dta bl_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
***********************************************************************
* 	PART 1:    clean consortium pii data
***********************************************************************
use "${master_intermediate}/consortium_pii_inter", clear

	* put key variables first
order id_plateforme, first

	* format id_plateforme
destring id_plateforme, replace

	* 
rename Numero1 tel_sup1_bl
rename Numero2 tel_sup2_bl


save "${master_intermediate}/consortium_pii_inter", replace




***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
***********************************************************************
* 	PART 1:    import analysis data
***********************************************************************
use "${master_raw}/consortium_raw", clear

***********************************************************************
* 	PART 2:     declare panel data set to stata
***********************************************************************
	* order panel identifier first
order id_plateforme surveyround, first
xtset id_plateforme surveyround, delta(1)

***********************************************************************
* 	PART 3:     remove unnecessary variables
***********************************************************************
drop eligible programme needs_check questions_needing_check eligibilité dup_emailpdg dup_firmname question_unclear_regis _merge_ab check_again random_number rank ident2 questions_needing_checks commentsmsb dup dateinscription date_creation_string subsector_var subsector heurefin exp_labor_productivity labor_productivity ca_mean ca_expmean ca_check question_unclear_regis qadmin_correct qadmin_correct2 questions_needing_checks commentsmsb waiting_list reasons mngtvars markvars exportprep gendervars exportmngt mngtvars_points markvars_points innovars_points gendervars_points innovars num_inno inno_aucune


* activate after midline: drop ca_2021 ca_exp_2021 profit_2021 // utiliser au niveau de la midline re-demander des infos manquantes.

***********************************************************************
* 	PART 4:     clean administrative implementation variables
***********************************************************************
		* put all admin-impl variables into a list
local take_up_vars "Webinairedelancement Rencontre1Atelier1 Rencontre1Atelier2 Rencontre2Atelier1 Rencontre2Atelier2 Rencontre3Atelier1 Rencontre3Atelier2 EventCOMESA Rencontre456 Atelierconsititutionjuridique Situationdelentreprise"

		* clean values
foreach x of local take_up_vars {
replace `x'= lower(`x')
replace `x' = stritrim(strtrim(`x'))
}
		* clean var names
rename `take_up_vars', lower

	*CHANGE IN THE EXCEL FILE DESISTEMENT WITH 1 and change it as a numerical variable
destring desistement_consortium, replace
format desistement_consortium %25.0fc
recast int desistement_consortium


***********************************************************************
* 	PART 5:     relabel outcome variables
***********************************************************************
lab var ca "sales in TND in bl = 2021, ml = 2022, el = 2023"
lab var ca_exp "export sales in TND in bl = 2021, ml = 2022, el = 2023"
lab var profit "profit in TND in bl = 2021, ml = 2022, el = 2023" 

lab var net_nb_f "Female CEOs met"
lab var net_nb_m "Male CEOs met"
lab var net_coop_pos "View CEO interaction"
lab var net_nb_qualite "Network quality"

lab var ssa_action1 "SSA client"

***********************************************************************
* 	PART 6:    change gouvernorat label
***********************************************************************
lab def gov 10 "Tunis" 11 "Tunis South-West" 20 "Tunis North", modify

***********************************************************************
* 	PART 7:    shorten variable names for regressions
***********************************************************************
rename exprep_inv exp_inv

***********************************************************************
* 	PART 8:    Transform remaining string to factor variables
***********************************************************************
		* legal status
lab def lstatus 1 "other" 2 "personne_physique" 3 "sa" 4 "sarl" 5 "suarl"
encode legalstatus, generate(legstatus) label(lstatus)
drop legalstatus
rename legstatus legalstatus

		* export countries
replace exp_pays_principal = "" if exp_pays_principal == "corée du nord"
encode exp_pays_principal, gen(pp)
drop exp_pays_principal
rename pp exp_pays_principal
***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_intermediate}/consortium_inter", replace


