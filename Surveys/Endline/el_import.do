***********************************************************************
* 			endline consortias experiment import					  *
***********************************************************************
*																	   
*	PURPOSE: import the endline survey data provided by the survey 
*   institute
*																	  
*	OUTLINE:														  
*	1)	import contact list as Excel or CSV		
*   2)  seperate PII data												  
*	3)	save the contact list as dta file in intermediate folder
*																	 					
*	Author: Kais Jomaa , Amira Bouziri , Eya Hanefi, Ayoub Chamakhi													  

*	ID variable: id_plateforme			  									  
*	Requires: el_raw.xlsx	
*	Creates: el_intermediate.dta							  
*																	  
***********************************************************************
* 	PART 1: import the answers from questionnaire as Excel				  										  *
***********************************************************************

import excel "${el_raw}/el_raw.xlsx", firstrow clear
***********************************************************************
* 	PART 2:  Rename variable for code	  			
************************************************************************
rename Id id_plateforme 
rename NOMESE firmname 
rename NOMREP repondant_endline 
rename Firmname same_firmname
rename Prenom firstname_el
rename Nom lastname_el
rename ident_repondent_position new_respondent_pos
rename Quelestvotrefonctionausein  new_respondent_otherpos
rename Firmname_el new_firmname

rename Product el_products
rename Autresأخرى products_other

rename W inno_proc_other
lab var inno_proc_other "Example of another innovation of process"

rename Y inno_mot_other
lab var inno_mot_other "Binary answer of other source of inspiration"

// to check if not example
rename AC export_other
lab var export_other "Binary answer of other reasons to not export?"

rename BM man_sources_other
lab var man_sources_other "Example of another source of new management strategy"

rename CA net_services_other


rename CZ profit_2023_category_gain
rename DB profit_2024_category_gain
rename DM int_other

rename vousenmesuredenousfournirl accord_q29


*Drop id_duplicates
drop if id_plateforme == 1210 & inno_mot == "/ 2 / 3 / 4 /"
***********************************************************************
* 	PART 3:  create + save bl_pii file	  			
***********************************************************************
	* remove variables that already exist in pii
drop firmname same_firmname accord_q29
	* rename variables to indicate el as origin
local el_changes id_ident new_firmname new_respondent_pos new_respondent_otherpos 
foreach var of local el_changes {
	rename `var' `var'_el
}

	* put all pii variables into a local
local pii id_plateforme repondant_endline id_ident_el firstname_el lastname_el new_firmname_el new_respondent_pos_el  new_respondent_otherpos_el

	* save as stata master data
preserve
keep `pii'

	* export the pii data as new consortia_master_data 
export excel `pii' using "${el_raw}/ecommerce_el_pii", firstrow(var) replace
save "${el_raw}/ecommerce_el_pii", replace

restore

*import list_group_el from master for listexp
merge m:1 id_plateforme using "${master_final}/endline_contactlist", keepusing(list_group_el)
drop if _merge != 3
drop _merge

*import fiche de SUIVI
preserve

import excel "${el_raw}/FichedesuiviCF.xlsx", firstrow clear
rename A id_plateforme
save "${el_raw}/FichedesuiviCF.dta", replace

restore

merge 1:1 id_plateforme using "${el_raw}/FichedesuiviCF", keepusing(A1_date_heure)
drop if _merge != 3
drop _merge

***********************************************************************
* 	PART 3:  save a de-identified analysis file	
***********************************************************************
	* drop all pii
drop repondant_endline id_ident_el firstname_el lastname_el new_firmname_el new_respondent_pos_el new_respondent_otherpos_el

***********************************************************************
* 	PART 4:  Add treatment status	
***********************************************************************
merge 1:1 id_plateforme using "${master_final}/endline_contactlist", keepusing(treatment)
drop if _merge == 2
drop _merge 

label var treatment "Treatment status"
label define treat 0 "Control" 1 "Treatment" 
label values treatment treat 

***********************************************************************
* 	PART 5: save the answers as dta file in intermediate folder 			  						
***********************************************************************

save "${el_intermediate}/el_intermediate", replace
