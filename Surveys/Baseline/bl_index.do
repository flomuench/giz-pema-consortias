***********************************************************************
* 			baseline index calculation									  	  
***********************************************************************
*																	    
*	PURPOSE: generate index variables				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1) Define variables used in index calculation
* 	2) Modify missing values as well as don't know and refuse to zeros
*	3) Create z-score indices
*	4) Create raw indices
*
*																	  															      
*	Author:  	Fabian Scheifele						  
*	ID variaregise: 	id_plateforme (example: 777)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			      

**********************************************************************
* 	PART 1:  Index calculation based on z-score		
***********************************************************************
use "${bl_intermediate}/bl_inter", clear
/*
calculation of indeces is based on Kling et al. 2007 and adopted from Mckenzie et al. 2018
JDE pre-analysis publication:
1: calculate z-score for each individual outcome
2: average the z-score of all individual outcomes --> this is the index value
	--> implies: no absolute evaluation but relative to all other firms
	--> requires: firms w/o missing values
3: average the three index values to get the QI index for firms
	--> implies: same weight for all three dimensions
*/
*Definition of all variables that are being used in index calculation*
local allvars man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan expprep_norme exprep_inv exprep_couts exp_pays car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp


*IMPORTANT MODIFICATION: Missing values, Don't know, refuse or needs check answers are being transformed to zeros*
*Temporary variable creation turning missing into zeros
foreach var of local  allvars {
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
	sum `1'
	gen `1'z = (`1' - r(mean))/r(sd)   /* new variable gen is called --> varnamez */
end

	* calculate z score for all variables that are part of the index
	// removed dig_marketing_respons, dig_service_responsable and expprepres_per bcs we don't have fte data without matching (& abs value doesn't make sense)
local mngtvars temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per 
local markvars temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub 
local exportmngt temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan 
local exportprep temp_expprep_norme temp_exprep_inv temp_exprep_couts temp_exp_pays 
local exportcombined temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan temp_expprep_norme temp_exprep_inv temp_exprep_couts temp_exp_pays
local gendervars temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
local efficacy temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv 
local initiative temp_car_init_prob temp_car_init_init temp_car_init_opp
local control temp_car_loc_succ temp_car_loc_env temp_car_loc_insp

foreach z in mngtvars markvars exportmngt exportprep gendervars {
	foreach x of local `z'  {
			zscore `x' 
		}
}	

		* calculate the index value: average of zscores 

egen mngtvars = rowmean(temp_man_hr_objz temp_man_hr_feedz temp_man_pro_anoz temp_man_fin_enrz temp_man_fin_profitz temp_man_fin_perz)
egen markvars = rowmean(temp_man_mark_prixz temp_man_mark_divz temp_man_mark_clientsz temp_man_mark_offrez temp_man_mark_pubz )

egen exportmngt = rowmean(temp_exp_pra_foirez temp_exp_pra_sciz temp_exp_pra_rexpz temp_exp_pra_ciblez temp_exp_pra_missionz temp_exp_pra_douanez temp_exp_pra_planz)
egen exportprep = rowmean(temp_expprep_normez temp_exprep_invz temp_exprep_coutsz temp_exp_paysz)
egen exportcombined = rowmean(temp_exp_pra_foirez temp_exp_pra_sciz temp_exp_pra_rexpz temp_exp_pra_ciblez temp_exp_pra_missionz temp_exp_pra_douanez temp_exp_pra_planz temp_expprep_normez temp_exprep_invz temp_exprep_coutsz temp_exp_paysz)

egen efficacy = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz)
egen initiative = rowmean(temp_car_init_probz temp_car_init_initz temp_car_init_oppz)
egen control = rowmean(temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz)
egen gendervars = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz temp_car_init_probz temp_car_init_initz temp_car_init_oppz temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz)

label var mngtvars   "Management practices index-Z Score"
label var markvars "Marketing practices index -Z Score"
label var exportmngt "Export management index -Z Score"
label var exportprep "Export readiness index -Z Score"
label var exportcombined "Combined export practices index -Z Score"
label var gendervars "Gender index -Z Score"
label var efficacy "belief in own ability - Z Score"
label var initiative "sense of own initiative - Z Score"
label var control "sense of control over business situation - Z Score"


//drop scalar_issue



**************************************************************************
* 	PART 2: Create indexes as total points (not zscores)		  										  
**************************************************************************
	* find out max. points
sum temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per
sum temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub
sum temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan
sum temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp

	* create total points per index dimension
egen mngtvars_points = rowtotal(`mngtvars'), missing

egen markvars_points = rowtotal(`markvars'), missing

egen exportmngt_points = rowtotal(`exportmngt'), missing

egen exportprep_points = rowtotal(`exportprep'), missing

egen exportcombined_points = rowtotal(`exportcombined'), missing

egen efficacy_points = rowtotal(`efficacy'), missing

egen initiative_points = rowtotal(`initiative'), missing

egen control_points = rowtotal(`control'), missing

egen gendervars_points = rowtotal(`gendervars'), missing

	* label variables

label var mngtvars_points "Management practices points"
label var markvars_points "Marketing practices points"
label var exportmngt_points "Export management points"
label var exportprep_points "Export readiness points"
label var exportcombined_points "Combined export practices points"
label var gendervars_points "Gender points"
label var efficacy_points "belief in own ability - points"
label var initiative_points "sense of own initiative - points"
label var control_points "sense of control over business situation - points"
	
**************************************************************************
* 	PART 4: drop temporary vars		  										  
**************************************************************************
drop temp_*


***********************************************************************
* 	PART 5:  create a new variable for survey round
***********************************************************************
/*

generate survey_round= .
replace survey_round= 1 if surveyround== "registration"
replace survey_round= 2 if surveyround== "baseline"
replace survey_round= 3 if surveyround== "session1"
replace survey_round= 4 if surveyround== "session2"
replace survey_round= 5 if surveyround== "session3"
replace survey_round= 6 if surveyround== "session4"
replace survey_round= 7 if surveyround== "session5"
replace survey_round= 8 if surveyround== "session6"
replace survey_round= 9 if surveyround== "midline"
replace survey_round= 10 if surveyround== "endline"

label var survey_round "which survey round?"

label define label_survey_round  1 "registration" 2 "baseline" 3 "session1" 4 "session2" 5 "session3" 6 "session4" 7 "session5" 8 "session6" 9 "midline" 10 "endline" 
label values survey_round  label_survey_round 
*/
***********************************************************************
* 	PART 4:  saving final
***********************************************************************

cd "$bl_final"
save "bl_final", replace
