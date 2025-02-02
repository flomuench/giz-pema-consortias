************************************************************************
* 			Consortium - master merge									  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible, merge & analysis survey 
*            & pii data related to consoritum program Tunisia
*  
*	OUTLINE: 	PART I: PII data   
*					PART 1: combine pii data from regis, bl, ml, el  
*					PART 2: integrate pii updates         
*
*				PART II: Analysis data					  
*					Part 3: append regis + bl, ml, el									
*					Part 4: integrate take-up data
*
*	Author:  		Florian Münch				    
*	ID variable: 	id_plateforme (panel unit id), surveyround (panel time id)
*	Requires: consortia_bl_pii.dta	consortia_regis_pii.dta										  
*	Creates:  contact_info_master.dta, consortium_raw.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
	                                  
***********************************************************************
* 	PART 1: merge & append to create master data set (pii)
***********************************************************************
{
	* merge registration with baseline data
use "${regis_final}/consortia_regis_pii", clear // 263 firms
				
		* merge 1:1 based on project id_plateforme
merge 1:1 id_plateforme using "${bl_raw}/consortia_bl_pii" // 169 firms
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                            94
        from master                        94  (_merge==1)
        from using                          0  (_merge==2)

    Matched                               169  (_merge==3)
    -----------------------------------------
*/
			*drop unselected firms from registration
* check: id_plateforme. 
	* baseline but no info:  1008 1079 1097 1109 1124 1234 1244 1247
	* registration but not randomized after baseline: 1095
drop if id_plateforme == 1095 // firm not eligible
drop if _merge<3 & !inlist(id_plateforme, 1008, 1079, 1097, 1109, 1124, 1234, 1244, 1247)  /* ineligible firms */
drop _merge

		* add treatment status after bl randomization
merge 1:1 id_plateforme using "${bl_final}/bl_final", keepusing(treatment)
/*
    Result                      Number of obs
    -----------------------------------------
    Not matched                             0
    Matched                               176  (_merge==3)
    -----------------------------------------
*/
drop _merge
	
		* merge 1:1  with midline
merge 1:1 id_plateforme using "${ml_raw}/consortia_ml_pii", update
drop _merge


/*
		* merge 1:1 with endline
merge 1:1 id_plateforme using "${el_raw}/consortia_el_pii"

*/

	* save as Consortium_contact_info_master
save "${master_raw}/consortium_pii_raw", replace

}
/*
***********************************************************************
* 	PART2: integrate and replace contact updates (pii)
***********************************************************************
*Note: the Update_file.xlsx be downloaded from teams, renamed and uploaded again in 6-master

clear
import excel "${master_gdrive}/Update_file.xlsx", sheet("update_entreprises") firstrow clear

merge 1:1 id_plateforme using "${master_gdrive}/contact_info_master"
drop _merge
duplicates drop 
save "${master_gdrive}/contact_info_master", replace


*/

***********************************************************************
********************* II: Analysis data *******************************
***********************************************************************	

***********************************************************************
* 	PART 3: merge registration & bl to create analysis data set (analysis data)
***********************************************************************
{
	* merge registration with baseline data
use "${regis_final}/regis_final", clear						// N = 263
drop treatment /* as it's just missing values in the registration data & in case we keep it then it will replace the data in the using file when merged*/

merge 1:1 id_plateforme using "${bl_final}/bl_final"		// N = 176
keep if _merge==3 /* companies that were eligible and answered on the registration + baseline surveys */
drop _merge

	* make necessary changes in variable [...] for merger with midline & endline
			* names
				* accounting variables 2021 (remove 2021 for panel)
local bl_acccounting_vars "ca ca_exp profit"
foreach var of local bl_acccounting_vars {
	rename `var'_2021 `var'
}
			* survey software variables
rename heuredébut heure

			* format

    * create panel ID
gen surveyround=1
lab def round  1 "baseline" 2 "midline" 3 "endline"
lab val surveyround round
 
    * save as consortium_database
save "${master_raw}/consortium_raw", replace

}

***********************************************************************
* 	PART 4: append analysis data set with midline & endline
***********************************************************************
{
* append with midline
append using "${ml_final}/ml_final"
order id_plateforme surveyround treatment, first
sort id_plateforme surveyround

* append with endline
append using "${el_final}/el_final"
order id_plateforme surveyround treatment, first
sort id_plateforme, stable

* declare panel data set
xtset id_plateforme surveyround, delta(1)

* dealing with attrition
	* create missing values for attrited firms (not in midline or endline data)
tsfill, full

	* replace missing valeus for attrited firms in ml or el for constant variables with their baseline value
local cst_vars_num "treatment strata_final eligible gouvernorat id_admin_correct year_created subsector_corrige operation_export ca_2018 ca_2019 ca_2020 ca_exp2018 ca_exp2019 ca_exp2020"
foreach var of local cst_vars_num {
	bys id_plateforme (surveyround): replace `var' = `var'[_n-1] if `var' == .
	}


local cst_vars_str "legalstatus subsector"
foreach var of local cst_vars_str {
	bys id_plateforme (surveyround): replace `var' = `var'[_n-1] if `var' == ""
	}	

}
***********************************************************************
* 	PART 5: merge with participation data
***********************************************************************
{
*Note: here should the Présence des ateliers.xlsx be downloaded from teams, renamed and uploaded again in 6-master
		*  import participation data
preserve
import excel "${implementation}/presence_ateliers.xlsx", firstrow clear

		* remove blank lines
drop if id_plateforme==.

		* select take-up variables
keep id_plateforme Webinairedelancement Rencontre1Atelier1 Rencontre1Atelier2 Rencontre2Atelier1 Rencontre2Atelier2 Rencontre3Atelier1 Rencontre3Atelier2 EventCOMESA Rencontre456 Atelierconsititutionjuridique Situationdelentreprise desistement_consortium 

		
		* save
save "${implementation}/take_up", replace
drop if id_plateforme==.
restore

		* merge to analysis data
merge m:1 id_plateforme using "${implementation}/take_up"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                           182
        from master                       182  (_merge==1)
        from using                          0  (_merge==2)

    matched                               170  (_merge==3)
    -----------------------------------------* id 1040 & 1192 se sont desistés le 19 et 26 avril après la randomisation du 7 avril (post Eya 4 avril)
*/
drop _merge
order Webinairedelancement Rencontre1Atelier1 Rencontre1Atelier2 Rencontre2Atelier1 Rencontre2Atelier2 Rencontre3Atelier1 Rencontre3Atelier2 EventCOMESA Rencontre456 Atelierconsititutionjuridique Situationdelentreprise desistement_consortium, last

* Replace observations for id_plateforme 1040 & 1192
local take_upvars Webinairedelancement Rencontre1Atelier1 Rencontre1Atelier2 Rencontre2Atelier1 Rencontre2Atelier2 Rencontre3Atelier1 Rencontre3Atelier2 EventCOMESA Rencontre456 Atelierconsititutionjuridique Situationdelentreprise 
foreach var of local take_upvars {
	replace `var'="absente" if id_plateforme == 1040 | id_plateforme == 1192
}
/*
*  import consortium coaching summary data
import excel "${implementation}/consortium_coaching_summary.xlsx", firstrow clear
drop if id_plateforme==.
drop Nombredelentreprise
drop consortium
save "${implementation}/consortium_coaching_summary", replace

merge m:m id_plateforme using "${implementation}/consortium_coaching_summary"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                                64  (_merge==3)
    -----------------------------------------
*/
drop _merge
drop O P Q R S T U
reshape wide subject_1 category_1 subject_2 category_2 subject_3 category_3 subject_4 category_4 subject_5 category_5, i(id_plateforme) j(session)

*generate variables per category for each column
reshape long category, i(id_plateforme) j(cat_num) string

graph hbar (percent) ,blabel(total, format(%9.0fc)) over(category)
	
		* save
save "${implementation}/consortium_coaching_summary", replace
drop if id_plateforme==.
*/

}

***********************************************************************
* 	PART 6: merge with cleaned product/ substitutes
***********************************************************************
/*
{
		*  import data
preserve
import excel "${harmonize}/cepex_produits.xlsx", firstrow clear

		* remove blank lines
drop if id_plateforme==.

		* select take-up variables
keep id_plateforme produit_clean_engl substitutes
		
		* save
save "${harmonize}/cepex_produits", replace
drop if id_plateforme==.
restore

		* merge to analysis data
merge m:1 id_plateforme using "${harmonize}/cepex_produits"
/*
   Result                           # of obs.
    -----------------------------------------
    not matched                             0
    matched                               528  (_merge==3)
    -----------------------------------------

    -----------------------------------------* id 1040 & 1192 se sont desistés le 19 et 26 avril après la randomisation du 7 avril (post Eya 4 avril)
*/
drop _merge
}
*/

***********************************************************************
* 	PART 7: information from pii data that is missing in analysis data
***********************************************************************
* list_group allocation for firms that attrited


***********************************************************************
* 	PART 7: merge with EL fiche de suivi for number of phone calls required to reach firms
***********************************************************************
preserve
import excel "${el_raw}/Fiche de suivi CF.xlsx", firstrow clear

		* remove blank lines
rename A id_plateforme
drop if id_plateforme==.

		* select take-up variables
keep id_plateforme status endline_refus_raison commentaire situation methode_reponse  A1_date_heure-A30_notes

		* modify format
local num 25 28 29
foreach x of local num  {
	drop A`x'_notes
	gen A`x'_notes = ""
}
order A25_notes, a(A25_résultat)  
order A28_notes, a(A28_résultat) 
order A29_notes, a(A29_résultat) 

format %-20s  A1_résultat-A30_notes

		* generate count of total call attempts for each firm
local a "A1_date_heure A2_date_heure A3_date_heure A4_date_heure A5_date_heure"
local b "A6_date_heure A7_date_heure A8_date_heure A9_date_heure A10_date_heure"
local c "A11_date_heure A12_date_heure A13_date_heure A14_date_heure A15_date_heure"
local d "A16_date_heure A17_date_heure A18_date_heure A19_date_heure A20_date_heure"
local e "A21_date_heure A22_date_heure A23_date_heure A24_date_heure A25_date_heure"
local f "A26_date_heure A27_date_heure A28_date_heure A29_date_heure A30_date_heure"
local all_attempts `a' `b' `c' `d' `e' `f'
egen calls = rownonmiss(`all_attempts'), strok

local vars "status commentaire situation methode_reponse"
foreach var of local vars {
	rename `var' el_`var'
}

		* gen surveyround identifier
gen surveyround = 3

order id_plateforme surveyround, first
		
		* save
save "${el_raw}/calls_el", replace
restore

		* merge to analysis data
merge m:1 id_plateforme surveyround using "${el_raw}/calls_el", keepusing(calls el_commentaire endline_refus_raison)


***********************************************************************
* 	PART 8: save finale analysis data set as raw
***********************************************************************
    * save as consortium_database
save "${master_raw}/consortium_raw", replace
