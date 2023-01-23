***********************************************************************
* 			consortia master do files: generate variables  
***********************************************************************
*																	  
*	PURPOSE: create variables based on merged data			  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*
*				PART II: Analysis data
*					PART 3: 
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium__master_inter.dta
*	Creates:	consortium__master_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
***********************************************************************
* 	PART 1:    import data  
***********************************************************************
use "${master_intermediate}/consortium_pii_inter", clear

***********************************************************************
* 	PART 2:  generate dummy account contact information missing
***********************************************************************
gen comptable_missing = 0, a(comptable_email)
	replace comptable_missing = 1 if comptable_numero == . & comptable_email == ""
	replace comptable_missing = 1 if comptable_numero == 88888888 & comptable_email == "nsp@nsp.com"
	replace comptable_missing = 1 if comptable_numero == 88888888 & comptable_email == "refus@refus.com"
	replace comptable_missing = 1 if comptable_numero == 99999999 & comptable_email == "nsp@nsp.com"



***********************************************************************
* 	PART 3:  save
***********************************************************************
save "${master_final}/consortium_pii_final", replace




***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
use "${master_intermediate}/consortium_inter", clear

***********************************************************************
* 	PART 1:  generate take-up variable
***********************************************************************
	*  label variables from participation "presence_ateliers"
local take_up_vars "webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique"

lab def presence_status 0 "Absent" 1 "Present"

foreach var of local take_up_vars {
	gen `var'1 = `var'
	replace `var'1 = "1" if `var' == "présente"  | `var' == "désistement"
	replace `var'1 = "0" if `var' == "absente"
	drop `var'
	destring `var'1, replace
	rename `var'1 `var'
	lab values `var' presence_status
}
	

	* Create take-up percentage per firm
egen take_up_per = rowtotal(webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique), missing
replace take_up_per = take_up_per/10

	* create a take_up
gen take_up = 0
replace take_up= 1 if desistement_consortium != 1 &  treatment == 1  &  surveyround == 1
lab var take_up "The company was present for the consortia formation"

	* create a status variable for surveys
gen status = (take_up_per > 0 & take_up_per < .)

***********************************************************************
* 	PART II.2:    Create missing variables for accounting number			  
***********************************************************************
/*gen profit_2021_missing=0
replace profit_2021_missing= 1 if profit_2021==.
replace profit_2021_missing= 1 if profit_2021==0

gen ca_2021_missing =0
replace ca_2021_missing= 1 if ca_2021==.
replace ca_2021_missing= 1 if ca_2021==0

gen ca_exp_2021_missing=0
replace ca_exp_2021_missing= 1 if ca_exp_2021==.
*/
***********************************************************************
* 	PART III:   Create the indices 			  
***********************************************************************
/*
*Definition of all variables that are being used in index calculation*
local allvars man_ind_awa man_fin_per_fre car_loc_exp man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme exprep_inv exprep_couts exp_pays exp_afrique car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp inno_produit inno_process inno_lieu inno_commerce inno_pers num_inno
ds `allvars', has(type string) 

*IMPORTANT MODIFICATION: Missing values, Don't know, refuse or needs check answers are being transformed to zeros*
*Temporary variable creation turning missing into zeros
foreach var of local allvars {
	g temp_`var' = `var'
	replace temp_`var' = 0 if `var' == .
	replace temp_`var' = 0 if `var' == -999
	replace temp_`var' = 0 if `var' == -888
	replace temp_`var' = 0 if `var' == -777
	replace temp_`var' = 0 if `var' == -1998
	replace temp_`var' = 0 if `var' == -1776 
	replace temp_`var' = 0 if `var' == -1554
	
}

	* calculate z-score for each individual outcome
	* write a program calculates the z-score
	* capture program drop zscore
	
program define zscore /* opens a program called zscore */
	sum `1' if treatment == 0 & surveyround == `2'
	gen `1'z = (`1' - r(mean))/r(sd)   /* new variable gen is called --> varnamez */
end

	* calculate z score for all variables that are part of the index
	// removed dig_marketing_respons, dig_service_responsable and expprepres_per bcs we don't have fte data without matching (& abs value doesn't make sense)
		* baseline 
			* export readiness
local eri_vars temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan temp_exprep_norme
foreach var of local eri_vars {
	zscore `var' 1
}

			* marketing practices
local mark_vars temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub 
foreach var of local mark_vars {
	zscore `var' 1
}
			* female empowerment
local female_efficacy temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv 
local female_initiative temp_car_init_prob temp_car_init_init temp_car_init_opp 
local femle_loc temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
foreach var of local female_efficacy female_initiative female_loc {
	zscore `var' 1
}	
		
		
		* midline
				* export readiness --> same variables --> no need to redefine list
local eri_vars temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan
foreach var of local eri_vars {
	zscore `var' 2
}
				* marketing practices --> not asked at midline

				* female empowerment  --> initiative questions not asked; 
local female_efficacy temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv 
local femle_loc temp_car_loc_succ temp_car_loc_env temp_car_loc_exp // temp_car_loc_insp chanted to temp_car_loc_exp
foreach var of local female_efficacy female_initiative female_loc {
	zscore `var' 2
}	

				* export management


local mngtvars1 temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per 


 


local mngtvars2 temp_man_hr_obj temp_man_source temp_man_ind_awa temp_man_fin_per_fre temp_man_fin_per
 
forvalues s = 1(1)2 {
foreach z in markvars`s' gendervars`s' mngtvars`s' exportprep exportmngt`s' {
	foreach x of local `z'  {
			zscore `x' 
		}
}	

		* calculate the index value: average of zscores 
				* index with changes between baseline and midline
egen mngtvars`s' = rowmean(temp_man_hr_objz temp_man_hr_feedz temp_man_pro_anoz temp_man_fin_enrz temp_man_fin_profitz temp_man_fin_perz) if surveyround == `s' 

egen markvars`s' = rowmean(temp_man_mark_prixz temp_man_mark_divz temp_man_mark_clientsz temp_man_mark_offrez temp_man_mark_pubz ) if surveyround == `s'

egen gendervars`s' = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz temp_car_init_probz temp_car_init_initz temp_car_init_oppz temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz) if surveyround == `s'

egen exportmngt`s' = rowmean(temp_exprep_normez temp_exprep_invz temp_exprep_coutsz temp_exp_paysz temp_exp_afriquez) if surveyround == `s'

}

gen mpi = mngtvars1 + mngtvars2
gen marki = markvars1 + markvars2
gen emi = exportmngt1 + exportmngt2
gen genderi = gendervars1 + gendervars2

				* indexes without changes between baseline and midline
egen eri = rowmean(temp_exp_pra_foirez temp_exp_pra_sciz temp_exp_pra_rexpz temp_exp_pra_ciblez temp_exp_pra_missionz temp_exp_pra_douanez temp_exp_pra_planz)


				* labeling
label var mpi "Management practices index-Z Score"
label var eri "Export readiness index -Z Score"
label var marki "Marketing practices index -Z Score"
label var genderi "Gender index -Z Score"

* 	PART 2: Create indexes as total points (not zscores)		  										  
	* find out max. points
sum temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per
sum temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub
sum temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan
sum temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
sum temp_exprep_norme temp_exprep_inv temp_exprep_couts temp_exp_pays temp_exp_afrique
	
	* create total points per index dimension
		* export readiness points
local exportprep temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan
egen er_points1 = rowtotal(`exportprep') if surveyround == 1, missing
egen er_points2 = rowtotal(`exportprep') if surveyround == 2, missing
gen er_points = er_points1 + er_points2

		* export management points
local exportmngt1 temp_exprep_norme temp_exprep_inv temp_exprep_couts temp_exp_pays temp_exp_afrique
local exportmngt2 temp_exprep_inv temp_exprep_couts

egen em_points1 = rowtotal(`exportmngt1'), missing
egen em_points2 = rowtotal(`exportmngt2'), missing
gen em_points = em_points1 + em_points2

		* management points
local mngtvars1 temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per
egen mp_points1 = rowtotal(`mngtvars1') if surveyround == 1, missing

local mngtvars2 temp_man_hr_obj temp_man_source temp_man_ind_awa temp_man_fin_per_fre temp_man_fin_per
egen mp_points2 = rowtotal(`mngtvars2') if surveyround == 2, missing

gen mp_points = mp_points1 + mp_points2

		* marketing pints
local markvars temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub 
egen mark_points = rowtotal(`markvars'), missing

		* gender points
local gendervars1 temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
egen gender_points1 = rowtotal(`gendervars1'), missing

local gendervars2 temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_loc_succ temp_car_loc_env temp_car_loc_exp
egen gender_points2 = rowtotal(`gendervars1'), missing

gen gender_points = gender_points1 + gender_points2


	* label variables
label var mp_points "Management practices points"
label var mark_points "Marketing practices points"
label var er_points "Export readiness points"
label var gender_points "Gender points"
label var em_points "Export management"
	
* 	PART 4: drop temporary vars		  										  
drop temp_*

*/

***********************************************************************
* 	PART IV:   generate survey-to-survey growth rates
***********************************************************************
	* accounting variables
local acccounting_vars "ca ca_exp profit employes"
foreach var of local acccounting_vars {
		bys id_plateforme: g `var'_growth = D.`var'/L.`var'
}

/*
use links to understand the code syntax for creating the accounting variables' growth rates:
- https://www.stata.com/statalist/archive/2008-10/msg00661.html
- https://www.stata.com/support/faqs/statistics/time-series-operators/

*/

***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_final}/consortium_final", replace
