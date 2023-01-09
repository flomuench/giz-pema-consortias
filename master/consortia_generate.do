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
*	Author:  	Fabian Scheifele & Siwar Hakim							    
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
	replace `var'1 = "1" if `var' == "présente"
	replace `var'1 = "0" if `var' == "absente" | `var' == "désistement"
	drop `var'
	destring `var'1, replace
	rename `var'1 `var'
	lab values `var' presence_status
}
	



	* Create take-up percentage per firm
egen take_up_per = rowtotal(webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique), missing
replace take_up_per = take_up_per/10

	* create a take_up

	* create a status variable for surveys
gen status = (take_up_per > 0 & take_up_per < .)

***********************************************************************
* 	PART II.2:    Create missing variables for accounting number			  
***********************************************************************
gen profit_2021_missing=0
replace profit_2021_missing= 1 if profit_2021==.
replace profit_2021_missing= 1 if profit_2021==0

gen ca_2021_missing =0
replace ca_2021_missing= 1 if ca_2021==.
replace ca_2021_missing= 1 if ca_2021==0

gen ca_exp_2021_missing=0
replace ca_exp_2021_missing= 1 if ca_exp_2021==.

***********************************************************************
* 	PART III:   Create the indices 			  
***********************************************************************
*Definition of all variables that are being used in index calculation*
local allvars man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme exprep_inv exprep_couts exp_pays exp_afrique car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp inno_produit inno_process inno_lieu inno_commerce inno_rd inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7 inno_mot8 inno_pers num_inno

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
	sum `1' if treatment == 0
	gen `1'z = (`1' - r(mean))/r(sd)   /* new variable gen is called --> varnamez */
end

	* calculate z score for all variables that are part of the index
	// removed dig_marketing_respons, dig_service_responsable and expprepres_per bcs we don't have fte data without matching (& abs value doesn't make sense)

local exportprep temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan 
local innovars temp_inno_produit temp_inno_process temp_inno_lieu temp_inno_commerce temp_inno_rd temp_inno_mot1 temp_inno_mot2 temp_inno_mot3 temp_inno_mot4 temp_inno_mot5 temp_inno_mot6 temp_inno_mot7 temp_inno_mot8 temp_inno_pers temp_num_inno
local mngtvars temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per 
local markvars temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub 
local gendervars temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
local exportmngt temp_exprep_norme temp_exprep_inv temp_exprep_couts temp_exp_pays temp_exp_afrique

forvalues x = 1(1)2 {
	foreach z in markvars innovars gendervars mngtvars exportprep exportmngt {
		foreach x of local `z'  {
				zscore `x' 
			}
	}	

			* calculate the index value: average of zscores 

	egen mngtvars = rowmean(temp_man_hr_objz temp_man_hr_feedz temp_man_pro_anoz temp_man_fin_enrz temp_man_fin_profitz temp_man_fin_perz)
	egen markvars = rowmean(temp_man_mark_prixz temp_man_mark_divz temp_man_mark_clientsz temp_man_mark_offrez temp_man_mark_pubz )
	egen exportprep = rowmean(temp_exp_pra_foirez temp_exp_pra_sciz temp_exp_pra_rexpz temp_exp_pra_ciblez temp_exp_pra_missionz temp_exp_pra_douanez temp_exp_pra_planz)
	egen gendervars = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz temp_car_init_probz temp_car_init_initz temp_car_init_oppz temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz)
	egen innovars = rowmean(temp_inno_produitz temp_inno_processz temp_inno_lieuz temp_inno_commercez temp_inno_rdz temp_inno_mot1z temp_inno_mot2z temp_inno_mot3z temp_inno_mot4z temp_inno_mot5z temp_inno_mot6z temp_inno_mot7z temp_inno_mot8z temp_inno_persz temp_num_innoz)
	egen exportmngt = rowmean(temp_exprep_normez temp_exprep_invz temp_exprep_coutsz temp_exp_paysz temp_exp_afriquez)
}
	
label var mngtvars "Management practices index-Z Score"
label var exportprep "Export readiness index -Z Score"
label var markvars "Marketing practices index -Z Score"
label var gendervars "Gender index -Z Score"
label var innovars "Innovation index -Z Score"
label var exportmngt "Export management index -Z Score"

* 	PART 2: Create indexes as total points (not zscores)		  										  
	* find out max. points
sum temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per
sum temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub
sum temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan
sum temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
sum temp_inno_produit temp_inno_process temp_inno_lieu temp_inno_commerce temp_inno_rd temp_inno_mot1 temp_inno_mot2 temp_inno_mot3 temp_inno_mot4 temp_inno_mot5 temp_inno_mot6 temp_inno_mot7 temp_inno_mot8 temp_inno_pers temp_num_inno
sum temp_exprep_norme temp_exprep_inv temp_exprep_couts temp_exp_pays temp_exp_afrique
	* create total points per index dimension
egen mngtvars_points = rowtotal(`mngtvars'), missing

egen markvars_points = rowtotal(`markvars'), missing

egen exportprep_points = rowtotal(`exportprep'), missing

egen innovars_points = rowtotal(`innovars'), missing

egen gendervars_points = rowtotal(`gendervars'), missing

egen exportmngt_points = rowtotal(`exportmngt'), missing

	* label variables

label var mngtvars_points "Management practices points"
label var markvars_points "Marketing practices points"
label var exportprep_points "Export readiness points"
label var innovars_points "Innovation points"
label var gendervars_points "Gender points"
label var exportmngt_points "Export management"
	
* 	PART 4: drop temporary vars		  										  
drop temp_*

***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_final}/consortia_master_final", replace
