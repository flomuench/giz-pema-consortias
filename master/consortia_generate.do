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
* PHASE 1 of the treatment: "consortia creation"
	*  label variables from participation "presence_ateliers"
local take_up_vars "webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique"

lab def presence_status 0 "Drop-out" 1 "Participate"

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
replace take_up_per = 0 if surveyround == 1
replace take_up_per = 0 if surveyround == 2 & treatment == 0 

	* create a take_up
replace desistement_consortium = 1 if id_plateforme == 1040
replace desistement_consortium = 1 if id_plateforme == 1192

gen take_up = 0, a(take_up_per)
replace take_up= 1 if treatment == 1 & desistement_consortium != 1
lab var take_up "Consortium participant"
lab values take_up presence_status

	* create a status variable for surveys
gen status = (take_up_per > 0 & take_up_per < .)


* PHASE 2 of the treatment: "consortia export promotion"



***********************************************************************
* 	PART 2:  survey attrition (refusal to respond to survey)	
***********************************************************************
gen refus = 0 // zero for baseline as randomization only among respondents
lab var refus "Comapnies who refused to answer the survey" 

		* midline
replace refus = 1 if id_plateforme == 994 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1014 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1132 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1094 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1025 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1061 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1079 & surveyround == 2 // refus de répondre (baseline & midline) 
replace refus = 1 if id_plateforme == 1247 & surveyround == 2 // Demande de Eya de ne plus les contacter
replace refus = 1 if id_plateforme == 998  & surveyround == 2 // Demande de Eya de ne plus les contacter
replace refus = 1 if id_plateforme == 1067 & surveyround == 2 //Demande d'enlever tous ses informations de la base de contact
replace refus = 1 if id_plateforme == 1136 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1026 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1089 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1109 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1144 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1169 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1172 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1194 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1234 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1237 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1056 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1074 & surveyround == 2 //refus de répondre
replace refus = 1 if id_plateforme == 1110 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1137 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1158 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1162 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1166 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1202 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1235 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1245 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1112 & surveyround == 2 //Refus de répondre 


replace refus = 0 if id_plateforme == 1193 & surveyround == 2 //Refus de répondre aux informations comptables (survey not completed)
replace refus = 0 if id_plateforme == 1040 & surveyround == 2 //Refus de répondre aux informations comptables & employés (survey not completed)
replace refus = 0 if id_plateforme == 1057 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1219 & surveyround == 2 //Refus de répondre aux informations comptables & employés (survey not completed)
replace refus = 0 if id_plateforme == 1071 & surveyround == 2 //Refus de répondre aux corrections comptables
replace refus = 0 if id_plateforme == 1022 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1015 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1068 & surveyround == 2 //Refus de répondre aux informations comptables
replace refus = 1 if id_plateforme == 1168 & surveyround == 2 // Refus de répondre aux informations comptables

		* endline

***********************************************************************
* 	PART 3:  entreprise no longer in operations	
***********************************************************************		
gen closed = 0 
lab var closed "Companies that are no longer operating"

replace closed = 1 if id_plateforme == 1083
replace closed = 1 if id_plateforme == 1059 
replace closed = 1 if id_plateforme == 1090
replace closed = 1 if id_plateforme == 1044

***********************************************************************
* 	PART 4:   Create total sales	+ positive profit  
***********************************************************************
gen sales = ca + ca_exp
lab var sales "total sales in TND"

gen profit_pos = (profit > 0)
replace profit_pos = . if profit == .
lab var profit_pos "profit > 0"


***********************************************************************
*	PART 5: Exported dummy
***********************************************************************
gen exported = (ca_exp > 0)
replace exported = . if ca_exp == .
lab var exported "export sales > 0"


gen exp_invested = (exp_inv > 0)
replace exp_invested = . if exp_inv == .
lab var exp_invested "export investment > 0"


***********************************************************************
*	PART 6: Innovation
***********************************************************************	
egen innovations = rowtotal(inno_commerce inno_lieu inno_process inno_produit)
bys id_plateforme (surveyround): gen innovated = (innovations > 0)
*br id_plateforme surveyround innovations innovated

lab var innovations "Total innovations"
lab var innovated "Innovated"

***********************************************************************
*	PART 7: network
***********************************************************************	
	* create total network size
gen net_size =.
		* combination of female and male CEOs at midline
replace net_size = net_nb_f + net_nb_m if surveyround ==2
		* combination of within family and outside family at baseline
replace net_size = net_nb_fam + net_nb_dehors if surveyround ==1

lab var net_size "Network size"


***********************************************************************
* 	PART 8:   Create the indices based on a z-score			  
***********************************************************************
{
	*Definition of all variables that are being used in index calculation
local allvars man_ind_awa man_fin_per_fre car_loc_exp man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme exp_inv exprep_couts exp_pays exp_afrique car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 man_hr_pro man_fin_num
ds `allvars', has(type string)

*IMPORTANT MODIFICATION: Missing values, Don't know, refuse or needs check answers are being transformed to zeros*
*Temporary variable creation turning missing into zeros
foreach var of local allvars {
	g temp_`var' = `var'
	replace temp_`var' = 0 if `var' == -999		// dont know transformed to zeros
	replace temp_`var' = 0 if `var' == -888
	replace temp_`var' = 0 if `var' == -777
	
}

	* calculate z-score for each individual outcome
		* write a program calculates the z-score
			* if you re-run the code, execture before: 
capture program drop zscore
program define zscore /* opens a program called zscore */
	sum `1' if treatment == 0
	gen `1'z = (`1' - r(mean))/r(sd) /* new variable gen is called --> varnamez */
end

		* calcuate the z-score for each variable
foreach var of local allvars {
	zscore temp_`var'
}

	* calculate the index value: average of zscores 
			* export readiness index (eri)
egen eri = rowmean(temp_exprep_normez temp_exp_pra_foirez temp_exp_pra_sciz temp_exp_pra_rexpz temp_exp_pra_ciblez temp_exp_pra_missionz temp_exp_pra_douanez temp_exp_pra_planz temp_exprep_normez)			
			
			* export readiness SSA index (eri_ssa)
egen eri_ssa = rowmean(temp_ssa_action1z temp_ssa_action2z temp_ssa_action3z temp_ssa_action4z temp_ssa_action5z)

			* management practices (mpi)
egen mpi = rowmean(temp_man_hr_objz temp_man_hr_feedz temp_man_pro_anoz temp_man_fin_enrz temp_man_fin_profitz temp_man_fin_perz temp_man_ind_awaz temp_man_fin_per_frez temp_man_hr_proz temp_man_fin_numz) // added at midline: man_ind_awa man_fin_per_fre instead of man_fin_per, man_hr_feed, man_hr_pro
			
			* marketing practices index (marki)
egen marki = rowmean(temp_man_mark_prixz temp_man_mark_divz temp_man_mark_clientsz temp_man_mark_offrez temp_man_mark_pubz)
			
			* female empowerment index (genderi)
				* locus of control "believe that one has control over outcome, as opposed to external forces"
				* efficacy "the ability to produce a desired or intended result."
				* sense of initiative
egen female_efficacy = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz)
egen female_initiative = rowmean(temp_car_init_probz temp_car_init_initz temp_car_init_oppz)
egen female_loc = rowmean(temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz temp_car_loc_expz)

egen genderi = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz temp_car_init_probz temp_car_init_initz temp_car_init_oppz temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz)	

		* labeling
label var eri "Export readiness"
label var eri_ssa "Export readiness SSA"
label var mpi "Management practices"
label var marki "Marketing practices"
label var female_efficacy "Effifacy"
label var female_initiative "Initiaitve"
label var female_loc "Locus of control"
label var genderi "Entrepreneurial empowerment"

}

***********************************************************************
* 	PART 9:   Create the indices as total points		  
***********************************************************************
{
	* find out max. points
sum temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per
sum temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub
sum temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_rexp temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan
sum temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp
sum temp_exprep_norme temp_exp_inv temp_exprep_couts temp_exp_pays temp_exp_afrique
	
	* create total points per index dimension
			* export readiness index (eri)
egen eri_points = rowtotal(exprep_norme exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme), missing			
			
			* export readiness SSA index (eri_ssa)
egen eri_ssa_points = rowtotal(ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5), missing

			* management practices (mpi)
egen mpi_points = rowtotal(man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_ind_awa man_fin_per_fre man_fin_num), missing
			
			* marketing practices index (marki)
egen marki_points = rowtotal(man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub), missing
			
			* female empowerment index (genderi)
				* locus of control "believe that one has control over outcome, as opposed to external forces"
				* efficacy "the ability to produce a desired or intended result."
				* sense of initiative
egen female_efficacy_points = rowtotal(car_efi_fin1 car_efi_nego car_efi_conv), missing
egen female_initiative_points = rowtotal(car_init_prob car_init_init car_init_opp), missing
egen female_loc_points = rowtotal(car_loc_succ car_loc_env car_loc_insp car_loc_exp), missing

egen genderi_points = rowtotal(car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp), missing

		* labeling
label var eri_points "Export readiness index points"
label var eri_ssa_points "Export readiness SSA index points"
label var mpi_points "Management practices index points"
label var marki_points "Marketing practices index points"
label var female_efficacy_points "Women's entrepreneurial effifacy points"
label var female_initiative_points "Women's entrepreneurial initiaitve points"
label var female_loc_points "Women's locus of control points"
label var genderi_points "Gender index points"

	* drop temporary vars		  										  
drop temp_*

}

***********************************************************************
* 	PART 10:   generate survey-to-survey growth rates
***********************************************************************
	* accounting variables
local acccounting_vars "ca ca_exp profit employes"
foreach var of local acccounting_vars {
		bys id_plateforme: g `var'_rel_growth = D.`var'/L.`var'
			bys id_plateforme: replace `var'_rel_growth = . if `var' == -999 | `var' == -888
		bys id_plateforme: g `var'_abs_growth = D.`var' if `var' != -999 | `var' != -888
			bys id_plateforme: replace `var'_abs_growth = . if `var' == -999 | `var' == -888

}

/*
use links to understand the code syntax for creating the accounting variables' growth rates:
- https://www.stata.com/statalist/archive/2008-10/msg00661.html
- https://www.stata.com/support/faqs/statistics/time-series-operators/

*/

***********************************************************************
*	PART 11: Financial indicators
***********************************************************************
	* quantile transform profits --> see Delius and Sterck 2020 : https://oliviersterck.files.wordpress.com/2020/12/ds_cash_transfers_microenterprises.pdf
gen profit_pct = .
	egen profit_pct1 = rank(profit) if surveyround == 1	& !inlist(profit, -777, -888, -999, .)	// use egen rank to get the rank of each value in the distribution of profits
	sum profit if surveyround == 1 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct1/(`r(N)' + 1) if surveyround == 1			// divide by N + 1 to get a percentile for each observation
	
	egen profit_pct2 = rank(profit) if surveyround == 2 & !inlist(profit, -777, -888, -999, .)
	sum profit if surveyround == 2 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct2/(`r(N)' + 1) if surveyround == 2
	drop profit_pct1 profit_pct2


	* winsorize
local wins_vars "ca ca_exp sales profit exp_inv employes car_empl1 car_empl2 exp_pays inno_rd net_size net_nb_f net_nb_m net_nb_dehors net_nb_fam"
foreach var of local wins_vars {
	winsor2 `var', suffix(_w99) cuts(0 99) 		  // winsorize
}

	* find optimal k before ihs-transformation
		* see Aihounton & Henningsen 2021 for methodological approach

		* put all ihs-transformed outcomes in a list
local ys "employes_w99 car_empl1_w99 car_empl2_w99 ca_w99 ca_exp_w99 sales_w99 profit_w99 exp_inv_w99" // add at endline: exp_pays_w99

		* check how many zeros
foreach var of local ys {
		sum `var' if surveyround == 2 & !inlist(`var', -777, -888, -999,.)
		local N = `r(N)'
		sum `var' if `var' == 0 & surveyround == 2
		local zeros = `r(N)'
		scalar perc = `zeros'/`N'
		if perc > 0.05 {
			display "`var' has `zeros' zeros out of `N' non-missing observations ("perc "%)."
			}
	scalar drop perc
}

		* generate re-scaled outcome variables
foreach var of local ys {
				* k = 1, 10^3-10^6
	if !inlist(`var', employes_w99, car_empl1_w99, car_empl2_w99) {
		gen `var'_k1   = `var'
		forvalues k = 3(1)6 {
			local i = `k' - 1
			gen `var'_k`i' = `var' / 10^`k' if !inlist(`var', ., -777, -888, -999)
			lab var `var'_k`i' "`var' wins., scaled by 10^`k'" 
			}
	}
				* k = 1, 10^1-10^3
	else {
		gen `var'_k1   = `var'
		forvalues k = 1(1)3 {
			local i = 1 +`k'
			gen `var'_k`i' = `var' / 10^`k' if !inlist(`var', ., -777, -888, -999)
			lab var `var'_k`i' "`var' wins., scaled by 10^`k'" 
			}
		}
	}

		* ihs-transform all rescaled numerical variables
foreach var of local ys {
		ihstrans `var'_k?, prefix(ihs_) 
}

		* visualize distribution of ihs-transformed, rescaled variables
foreach var of local ys {
	if !inlist(`var', employes_w99, car_empl1_w99, car_empl2_w99) {
		local powers "1 10^3 10^4 10^5 10^6"
		forvalues i = 1(1)5 {
			gettoken power powers : powers
				if `var' == profit_w99 {
				histogram ihs_`var'_k`i', start(-16) width(1)  ///
					name(`var'`i', replace) ///
					title("IHS-Tranformed `var': K = `power'")
					}
				else {
				histogram ihs_`var'_k`i', start(0) width(1)  ///
					name(`var'`i', replace) ///
					title("IHS-Tranformed `var': K = `power'")
					}					
				}
	gr combine `var'1 `var'2 `var'3 `var'4 `var'5, row(2)
	gr export "${master_figures}/scale_`var'.png", replace
				}
	else {
		local powers "1 10^1 10^2 10^3"
		forvalues i = 1(1)4 {
			gettoken power powers : powers
			histogram ihs_`var'_k`i', start(0) width(1)  ///
				name(`var'`i', replace) ///
				title("IHS-Tranformed `var': K = `power'")
				}
	gr combine `var'1 `var'2 `var'3 `var'4, row(2)
	gr export "${master_figures}/scale_`var'.png", replace
	}
}
		
		* generate Y0 + missing baseline to be able to run final regression
			* at midline use only for mht
foreach var of local ys {
			* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]					// filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)								// create variable = bl value for all three surveyrounds by id
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first														// clean up
	lab var `var'_y0 "Y0 `var'"
	
		* generate missing baseline dummy
	gen miss_bl_`var' = 0 if surveyround == 1											// gen dummy for baseline
	replace miss_bl_`var' = 1 if surveyround == 1 & inlist(`var',., -777, -888, -999)	// replace dummy 1 if variable missing at bl
	egen missing_bl_`var' = min(miss_bl_`var'), by(id_plateforme)									// expand dummy to ml, el
	lab var missing_bl_`var' "YO missing, `var'"
	drop miss_bl_`var'
}

		* run final regression & collect r-square in Excel file
				* create excel document
putexcel set "${master_figures}/scale_k.xlsx", replace

				* define table title
putexcel A1 = "Selection of optimal K", bold border(bottom) left
	
				* create top border for variable names
putexcel A2:H2 = "", border(top)
	
				* define column headings
putexcel A2 = "", border(bottom) hcenter
putexcel B2 = "employees", border(bottom) hcenter
putexcel C2 = "female employees", border(bottom) hcenter
putexcel D2 = "young employees", border(bottom) hcenter
putexcel E2 = "domestic sales", border(bottom) hcenter
putexcel F2 = "export sales", border(bottom) hcenter
putexcel G2 = "total sales", border(bottom) hcenter
putexcel H2 = "profit", border(bottom) hcenter
putexcel I2 = "Export invt.", border(bottom) hcenter
	
				* define rows
putexcel A3 = "k = 1", border(bottom) hcenter
putexcel A4 = "k = 10^2", border(bottom) hcenter
putexcel A5 = "k = 10^3", border(bottom) hcenter
putexcel A6 = "k = 10^4", border(bottom) hcenter
putexcel A7 = "k = 10^5", border(bottom) hcenter
putexcel A7 = "k = 10^6", border(bottom) hcenter

				* run the main specification regression looping over all values of k
xtset id_plateforme surveyround, delta(1)
local columns "B C D"
foreach var of varlist employes_w99 car_empl1_w99 car_empl2_w99 {
	local row = 3
	gettoken column columns : columns
	forvalues i = 1(1)4 {
		reg ihs_`var'_k`i' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
		local r2 = e(r2)
		putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
			local row = `row' + 1
	}
}

local columns "E F G H I"
foreach var of varlist ca_w99 ca_exp_w99 profit_w99 exp_inv_w99 sales_w99 {
	local row = 3
	gettoken column columns : columns
	forvalues i = 1(1)5 {
			reg ihs_`var'_k`i' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			local r2 = e(r2)
			putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
			local row = `row' + 1
	}
}


		* drop all the created variables
drop missing_bl_* // *_k?


		* label optimal k variables & k = 1 for consistency checks
lab var ihs_exp_inv_w99_k1 "Export investment"
lab var ihs_exp_inv_w99_k4 "Export investment"
lab var ihs_ca_exp_w99_k1 "Export sales"
lab var ihs_ca_exp_w99_k4 "Export sales"
lab var ihs_sales_w99_k1  "Total sales"
lab var ihs_sales_w99_k4  "Total sales" 
lab var ihs_ca_w99_k1 "Domestic sales" 
lab var ihs_ca_w99_k4 "Domestic sales" 
lab var ihs_profit_w99_k1 "Profit" 
lab var ihs_profit_w99_k2 "Profit"
lab var ihs_profit_w99_k3 "Profit" 
lab var ihs_profit_w99_k4 "Profit"
lab var profit_pct "Profit"
lab var ihs_employes_w99_k1 "Employees"
lab var car_empl1_w99_k1 "Female employees"
lab var car_empl2_w99_k1 "Young employees"
lab var ihs_employes_w99_k3 "Employees" 
lab var car_empl1_w99_k3 "Female employees"

***********************************************************************
* 	PART 12: (endline) generate YO + missing baseline dummies	
***********************************************************************
	* results for optimal k
		* k = 10^3 --> employees, female employees, young employees
		* k = 10^4 --> domestic sales, export sales, total sales, exp_inv
	* collect all ys in string
local network "net_size net_size_w99 net_nb_qualite net_coop_pos net_nb_f_w99 net_nb_m_w99"
local empowerment "genderi female_efficacy female_loc listexp"
local mp "mpi"
local innovation "innovated innovations"
local export_readiness "eri eri_ssa exp_invested ihs_exp_inv_w99_k1 ihs_exp_inv_w99_k4 exported ca_exp ihs_ca_exp_w99_k1 ihs_ca_exp_w99_k4 exprep_couts ssa_action1" // add at endline: ihs_exp_pays_w99_k1
local business_performance "ihs_sales_w99_k1 ihs_sales_w99_k4 ihs_ca_w99_k1 ihs_ca_w99_k4 profit_pos ihs_profit_w99_k1 ihs_profit_w99_k2 ihs_profit_w99_k3 ihs_profit_w99_k4 profit_pct ihs_employes_w99_k1 car_empl1_w99_k1 car_empl2_w99_k1 ihs_employes_w99_k3 car_empl1_w99_k3 car_empl2_w99_k3"
local ys `network' `empowerment' `mp' `innovation' `export_readiness' `business_performance'

	* gen dummy + replace missings with zero at bl
foreach var of local ys {
	gen missing_bl_`var' = (`var' == . & surveyround == 1) 
	replace `var' = 0 if `var' == . & surveyround == 1
}

	* generate Y0 --> baseline value for ancova & mht
foreach var of local ys {
		* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]					// filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)								// create variable = bl value for all three surveyrounds by id
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first														// clean up
	lab var `var'_y0 "Y0 `var'"
}


***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_final}/consortium_final", replace

/*
* export lists for GIZ
preserve 
keep if surveyround == 1
keep id_plateforme year_created pole subsector_corrige produit?
merge 1:1 id_plateforme using "${master_final}/consortium_pii_final"
export excel id_plateforme treatment nom_rep position_rep tel_pdg email_pdg year_created pole subsector_corrige produit? using "${master_final}/eya_list.xlsx", firstrow(var) replace
restore
