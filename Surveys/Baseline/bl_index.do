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
use "${bl_final}/bl_final", clear
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
local allvars man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme exprep_inv exprep_couts exp_pays exp_afrique car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp inno_produit inno_process inno_lieu inno_commerce inno_aucune inno_rd inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7 inno_mot8 inno_pers num_inno



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
	sum `1' if treatment == 0
	gen `1'z = (`1' - r(mean))/r(sd)   /* new variable gen is called --> varnamez */
end

	* calculate z score for all variables that are part of the index
	// removed dig_marketing_respons, dig_service_responsable and expprepres_per bcs we don't have fte data without matching (& abs value doesn't make sense)

local exportprep temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan 
local innovars temp_inno_produit temp_inno_process temp_inno_lieu temp_inno_commerce temp_inno_aucune temp_inno_rd temp_inno_mot1 temp_inno_mot2 temp_inno_mot3 temp_inno_mot4 temp_inno_mot5 temp_inno_mot6 temp_inno_mot7 temp_inno_mot8 temp_inno_pers temp_num_inno
local mngtvars temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per 
local markvars temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub 
local gendervars temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
local exportmngt temp_exprep_norme temp_exprep_inv temp_exprep_couts temp_exp_pays temp_exp_afrique


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
egen innovars = rowmean(temp_inno_produitz temp_inno_processz temp_inno_lieuz temp_inno_commercez temp_inno_aucunez temp_inno_rdz temp_inno_mot1z temp_inno_mot2z temp_inno_mot3z temp_inno_mot4z temp_inno_mot5z temp_inno_mot6z temp_inno_mot7z temp_inno_mot8z temp_inno_persz temp_num_innoz)
egen exportmngt = rowmean(temp_exprep_normez temp_exprep_invz temp_exprep_coutsz temp_exp_paysz temp_exp_afriquez)

label var mngtvars "Management practices index-Z Score"
label var exportprep "Export readiness index -Z Score"
label var markvars "Marketing practices index -Z Score"
label var gendervars "Gender index -Z Score"
label var innovars "Innovation index -Z Score"
label var exportmngt "Export management index -Z Score"

//drop scalar_issue



**************************************************************************
* 	PART 2: Create indexes as total points (not zscores)		  										  
**************************************************************************
	* find out max. points
sum temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per
sum temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub
sum temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan
sum temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
sum temp_inno_produit temp_inno_process temp_inno_lieu temp_inno_commerce temp_inno_aucune  temp_inno_rd temp_inno_mot1 temp_inno_mot2 temp_inno_mot3 temp_inno_mot4 temp_inno_mot5 temp_inno_mot6 temp_inno_mot7 temp_inno_mot8 temp_inno_pers temp_num_inno
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


***********************************************************************
*** PART 5: Indices statistics	  			
***********************************************************************
*PLEASE ADAPT TO INDICES USED IN CONSORTIA and USE STRIPPLOTS & BARCHARTS RATHER THAN HIST

* set directory to checks folder
cd "$bl_output"

	* create pdf document
putpdf clear
putpdf begin 
putpdf paragraph
putpdf text ("consortias training: Z scores"), bold linebreak
putpdf text ("Date: `c(current_date)'"), bold linebreak
putpdf paragraph, halign(center) 


	* Management practices Z-scores
	
hist mngtvars, title("Zscores of management practices questions") xtitle("Zscores")
graph export hist_mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_mngtvars_zscores.png
putpdf pagebreak

graph bar mngtvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_mngtvars_zscores.png
putpdf pagebreak

stripplot mngtvars, over(pole) vertical
gr export strip_mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_mngtvars_zscores.png
putpdf pagebreak
 
	* Marketing practices Z-scores
	
hist markvars, title("Zscores of marketing practices questions") xtitle("Zscores")
graph export hist_markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_markvars_zscores.png
putpdf pagebreak

graph bar markvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_markvars_zscores.png
putpdf pagebreak

stripplot markvars, over(pole) vertical
gr export strip_markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_markvars_zscores.png
putpdf pagebreak


	* Export readiness Z-scores
	
hist exportprep, title("Zscores of export readiness questions") xtitle("Zscores")
graph export hist_exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_exportprep_zscores.png
putpdf pagebreak

graph bar exportprep, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_exportprep_zscores.png
putpdf pagebreak

stripplot exportprep, over(pole) vertical
gr export strip_exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_exportprep_zscores.png
putpdf pagebreak

	* innovation Z-scores
	
hist innovars, title("Zscores of innovation questions") xtitle("Zscores")
graph export hist_inno_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_inno_zscores.png
putpdf pagebreak

graph bar innovars, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_inno_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_inno_zscores.png
putpdf pagebreak

stripplot innovars, over(pole) vertical
gr export strip_inno_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_inno_zscores.png
putpdf pagebreak


	* Gender Z-scores
	
hist gendervars, title("Zscores of gender-related questions") xtitle("Zscores")
graph export hist_gendervars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_gendervars_zscores.png
putpdf pagebreak

graph bar gendervars, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_gendervars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_gendervars_zscores.png
putpdf pagebreak

stripplot gendervars, over(pole) vertical
gr export strip_gendervars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_gendervars_zscores.png
putpdf pagebreak



/*
	* For comparison, the 'raw' indices: 

	* Management practices Z-scores
	
hist raw_mngtvars, title("raw sum of all management practices scores") xtitle("Sum")
graph export hist_raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_raw_mngtvars.png
putpdf pagebreak

graph bar raw_mngtvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_mngtvars.png
putpdf pagebreak

stripplot raw_mngtvars, over(pole) vertical
gr export strip_raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_mngtvars.png
putpdf pagebreak

	* Marketing practices Z-scores
	
hist raw_markvars, title("Raw sum of all marketing practices questions") xtitle("Sum")
graph export raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_markvars.png
putpdf pagebreak

graph bar raw_markvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_markvars.png
putpdf pagebreak

stripplot raw_markvars, over(pole) vertical
gr export strip_raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_markvars.png
putpdf pagebreak

	* Export outcomes Z-scores

hist raw_exportmngt, title("Raw sum of all export management questions") xtitle("Sum")
graph export raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportmngt.png
putpdf pagebreak

graph bar raw_exportmngt, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_exportmngt.png
putpdf pagebreak

stripplot raw_exportmngt, over(pole) vertical
gr export strip_raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_exportmngt.png
putpdf pagebreak


	* Export readiness Z-scores
	
hist raw_exportprep, title("Raw sum of all export readiness questions") xtitle("Sum")
graph export raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportprep.png
putpdf pagebreak

graph bar raw_exportprep, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_exportprep.png
putpdf pagebreak

stripplot raw_exportprep, over(pole) vertical
gr export strip_raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_exportprep.png
putpdf pagebreak

	* Combined export practices Z-scores
	
hist raw_exportcombined, title("Raw sum of allcombined export practices questions") xtitle("Sum")
graph export raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportcombined.png
putpdf pagebreak

graph bar raw_exportcombined, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_exportcombined.png
putpdf pagebreak

stripplot raw_exportcombined, over(pole) vertical
gr export strip_raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_exportcombined.png
putpdf pagebreak

    * Gender Z-scores
	
hist raw_gendervars, title("raw sum of all gender_related scores") xtitle("Sum")
graph export hist_raw_gendervars.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_raw_gendervars.png
putpdf pagebreak

graph bar raw_gendervars, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_raw_gendervars.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_gendervars.png
putpdf pagebreak

stripplot raw_gendervars, over(pole) vertical
gr export strip_raw_gendervars.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_gendervars.png
putpdf pagebreak
*/


*/	
***********************************************************************
* 	PART 6:  Correlation of index variables with accounting data
***********************************************************************
twoway (scatter ca_exp_2021 exportmngt if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 exportmngt if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_exportmanag_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_exportmanag_exp2021.png
putpdf pagebreak

twoway (scatter ca_exp_2021 mngtvars if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 mngtvars if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_manageprac_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_manageprac_exp2021.png
putpdf pagebreak

twoway (scatter ca_exp_2021 innovars if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 innovars if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_innovarsindex_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_innovarsindex_exp2021.png
putpdf pagebreak

twoway (scatter ca_exp_2021 exportprep if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 exportprep if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_expprep_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_expprep_exp2021.png
putpdf pagebreak

twoway (scatter ca_2021 exportmngt if ca_2021<ca_95p) || ///
(lfit ca_2021 exportmngt if ca_2021<ca_95p, lcol(blue))
gr export cor_exportmanag_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_exportmanag_ca2021.png
putpdf pagebreak


twoway (scatter ca_2021 mngtvars if ca_2021<ca_95p) || ///
(lfit ca_2021 mngtvars if ca_2021<ca_95p, lcol(blue))
gr export cor_manageprac_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_manageprac_ca2021.png
putpdf pagebreak

cd "$bl_output"

asdoc cor ca_2021 ca_exp_2021 profit_2021 exprep_inv inno_rd exportmngt mngtvars innovars, save(cor_matrix_bldata.doc) title(Correlation matrix of indices and 2021 data)
asdoc cor ca_2021 ca_2020 ca_2019 ca_2018 ca_exp_2021 ca_exp2020 ca_exp2020 ca_exp2019 ca_exp2018 profit_2021, save(cor_matrix_20182021.doc) title(2021 vs. 2018-2020 financial data)

tab ca_2021
tab ca_2020
tab ca_2019
tab ca_exp_2021
tab ca_exp2020
tab ca_exp2019

*There are less missing values for the newest data from 2021, so probably better to take this one*

***********************************************************************
* 	PART 7:  save pdf
***********************************************************************
	* change directory to progress folder

	* pdf
putpdf save "Zscore_statistics", replace


***********************************************************************
* 	PART 8:  Export excel for missing information
***********************************************************************
cd "$bl_checks"
export excel id_plateforme miss validation using "Missing_info.xlsx" if miss>0, firstrow(variables) replace

	
***********************************************************************
* 	PART 9: Balance checks (coped from bl randomisation and added to it the variables of indexes: exportmngt exportprep mngtvars)
***********************************************************************
		
		* balance for continuous and few units categorical variables
set matsize 25
iebaltab ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, grpvar(treatment) ftest save(baltab_final) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
			 
*Balance table without Outlier (ID=1092)
preserve
drop if id_plateforme==1092
iebaltab ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, grpvar(treatment) ftest save(baltab_final_nooutlier) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
log using pstesttables_final_nooutlier.txt, text replace
pstest ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, t(treatment) raw rubin label dist
log close
restore
	* Manully check the f-test for joint orthogonality using hc3:
	
local balancevarlist ca_2021 ca_exp_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam exportmngt exportprep mngtvars

reg treatment `balancevarlist', vce(hc3)
testparm `balancevarlist'		
			 
		* visualizing balance for categorical variables with multiple categories
graph hbar (count), over(treatment, lab(labs(tiny))) over(pole, lab(labs(vsmall))) ///
	title("Balance across sectors") ///
	blabel(bar, format(%4.0f) size(tiny)) ///
	ylabel(, labsize(minuscule) format(%-100s))
	graph export balance_sectors.png, replace
	putdocx paragraph, halign(center)
	putdocx image balance_sectors.png, width(4)	
		
	*exporting pstest with rubin's d
log using pstesttables_final.txt, text replace
pstest ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, t(treatment) raw rubin label dist
log close



*balance check winsorized at 99th percentile
iebaltab w_ca2021 w_caexp2021 w_profit2021 exp_pays w_exprep_inv exprep_couts inno_rd num_inno w_nonfamilynetwork net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, grpvar(treatment) ftest save(baltab_final_winsorized) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
log using pstesttables_final_winsorized.txt, text replace
pstest w_ca2021 w_caexp2021 w_profit2021 exp_pays w_exprep_inv exprep_couts inno_rd num_inno w_nonfamilynetwork net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, t(treatment) raw rubin label dist
log close

***********************************************************************
* 	PART 4: Export excel spreadsheet
***********************************************************************			 		


	* save dta file with treatments and strata
	
cd "$bl_final"

save "bl_final", replace
