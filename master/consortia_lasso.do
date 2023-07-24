***********************************************************************
* 			Analysis: What predicts participation in the consortium? (Take-up)
***********************************************************************
*																	  
*	PURPOSE: 	Conduct Lasso regression analysis to identify predictors of take-up			  
*
*													
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium_final.dta
*	Creates:

***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************
use "${master_final}/consortium_final", clear
	
		* change directory
cd "${master_regressiontables}/midline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on

		* limit to baseline observations (pre-treatment)
keep if surveyround == 1


/*
Option 1: In-built Stata command "lasso"
--> https://blog.stata.com/2019/09/09/an-introduction-to-the-lasso-in-stata/
Option 2: Dr. Giovanni Cerulli wrapper: r_ml_stata_cv c_ml_stata_cv
--> https://sites.google.com/view/giovannicerulli/machine-learning-in-stata
Option 3: Zou and Schonlau, rforest algorithm
--> https://journals.sagepub.com/doi/full/10.1177/1536867X20909688
--> https://www.stata.com/meeting/canada18/slides/canada18_Zou.pdf
Option 4 (for inference, not variable/model selection): pdslasso (most used in econ)
*/

***********************************************************************
* 	PART 1: take-up & balance 		
***********************************************************************
{
	* midline
				* major outcome variables, untransformed
local network_vars "net_size net_nb_qualite net_coop_pos net_coop_neg"
local empowerment_vars "genderi female_efficacy female_loc"
local kt_vars "mpi innovations innovated inno_rd"
local business_vars "ca profit employes"
local export_vars "eri exprep_couts exp_inv exported ca_exp"
local vars_untransformed `network_vars' `empowerment_vars' `kt_vars' `business_vars' `export_vars'

				* major outcome variables, transformed
local network_vars "net_size_w99 net_nb_qualite net_coop_pos net_coop_neg"
local empowerment_vars "genderi female_efficacy female_loc"
local kt_vars "mpi innovations innovated inno_rd_w99"
local business_vars "age ihs_ca_w99_k4 profit employes"
local export_vars "eri ihs_ca_exp_w99_k4 exp_pays_w99 ihs_exp_inv_w99_k4 exprep_couts"
local vars_transformed `network_vars' `empowerment_vars' `kt_vars' `business_vars' `export_vars'

{
local exp_status "exported exp_invested exp_afrique"
local financial "ca ca_exp profit profit_pos employes"
local basic "pole presence_enligne tunis year_created age legalstatus lcapital"
local innovation "inno_rd innovations innovated"
local network "net_nb_fam net_nb_dehors net_nb_qualite net_time net_coop_neg" // ml vars: net_nb_f net_nb_m
local obligations "famille1 famille2"
}

local allvars3 `exp_status' eri `financial' `basic' `network' `innovation' mpi marki genderi `obligations'
				
				* balance & take-up: untransformed
iebaltab `vars_untransformed' if surveyround == 1, ///
	grpvar(take_up) vce(robust) format(%12.2fc) replace ///
	ftest pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
	save(take_up_baltab_unajd)

				* balance & take-up: transformed
iebaltab `vars_transformed' if surveyround == 1, ///
	grpvar(take_up) vce(robust) format(%12.2fc) replace ///
	ftest pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
	save(take_up_baltab_ajd)
	
				* balance & take-up: transformed
iebaltab `allvars3' if surveyround == 1, ///
	grpvar(take_up) vce(robust) format(%12.2fc) replace ///
	ftest pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
	save(take_up_baltab_allvars)

}

***********************************************************************
* 	PART 2: split the sample in training and evaluation sample
***********************************************************************
splitsample , balance(treatment take_up) generate(sample) split(.75 .25) rseed(22072023)

label define slabel 1 "Training" 2 "Validation"

label values sample slabel

tabulate sample


***********************************************************************
* 	PART 3: put all potential predictors/covariates into locals
***********************************************************************
{
local exp_status "i.operation_export i.expstatus i.exported i.exp_invested"
local exp_practices "i.exp_pra_foire i.exp_pra_sci i.exp_pra_rexp i.exp_pra_cible i.exp_pra_mission i.exp_pra_douane i.exp_pra_plan i.exprep_norme exp_inv exprep_couts exp_pays i.exp_pays_principal i.exp_afrique"
local financial "ca ca_exp profit i.profit_pos ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020"
local basic "i.subsector_corrige i.presence_enligne i.tunis year_created age i.legalstatus capital"
local employees "employes fte_femmes"
local innovation "i.inno_produit i.inno_process i.inno_lieu i.inno_commerce inno_rd innovations i.innovated"
local network "net_nb_fam net_nb_dehors net_nb_qualite net_time net_coop_pos net_coop_neg" // ml vars: net_nb_f net_nb_m
local management "i.man_hr_obj i.man_hr_feed i.man_pro_ano i.man_fin_enr i.man_fin_profit i.man_fin_per i.man_mark_prix i.man_mark_div i.man_mark_clients i.man_mark_offre i.man_mark_pub" // ml vars: i.man_fin_num i.man_fin_per_fre i.man_hr_ind i.man_hr_pro i.man_ind_awa i.man_source
local confidence "car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp" // ml vars: car_loc_exp

local expectations "i.att_adh1 i.att_adh2 i.att_adh3 i.att_adh4 i.att_adh5 i.att_voyage i.support1 i.support2 i.support3 i.support4 i.support5 i.support6"
local obligations "i.famille1 famille2"
}
local allvars1 `exp_status' `exp_practices' `financial' `basic' `employees' `innovation' `management' `confidence' `expectations' `obligations'

local allvars2 `exp_status' eri eri_ssa `financial' `basic' `employees' `innovation' mpi marki genderi `expectations' `obligations' `network'


{
local exp_status "i.exported i.exp_invested i.exp_afrique"
local financial "ca ca_exp profit i.profit_pos employes"
local basic "i.subsector_corrige i.presence_enligne i.tunis year_created age i.legalstatus capital"
local innovation "inno_rd innovations i.innovated"
local network "net_nb_fam net_nb_dehors net_nb_qualite net_time net_coop_neg" // ml vars: net_nb_f net_nb_m
local obligations "i.famille1 famille2"
}

local allvars3 `exp_status' eri eri_ssa `financial' `basic' `network' `innovation' mpi marki genderi `obligations'

local allvars4 "net_nb_qualite net_coop_neg capital_w99 famille2 innovations net_nb_fam employes_w99 ca_w99 i.pole"
local allvars5 "net_nb_qualite net_coop_neg capital_w99 famille2 innovations net_nb_fam business_size i.pole"


***********************************************************************
* 	PART 4: 
***********************************************************************
	* OLS
regress take_up `allvars5', robust
estimates store ols
	
	* CV selection
lasso linear take_up `allvars5' if sample == 1, rseed(22072023) selection(cv)
estimates store cv

	* Adaptive selection
lasso linear take_up `allvars5' if sample == 1, rseed(22072023) selection(adaptive)
estimates store adaptive

	* Plugin selection
lasso linear take_up `allvars5' if sample == 1, rseed(22072023) selection(plugin)
estimates store plugin

	* compare within vs. out of sample prediction performance
lassogof ols cv adaptive plugin, over(sample) postselection

	* check the sensitivity of the choice of lambda
lassoknot 

	* check which variables where selected in the optimal model
lassocoef cv adaptive plugin, ///
	display(coef, standardized) ///
	sort(coef, standardized)
	
	
***********************************************************************
* 	PART 5: Run simple OLS + logit regressions
***********************************************************************

* selection via hit-and-drop
		* first attempt
{
local exp_status "i.exported i.exp_invested i.exp_afrique"
local financial "ca ca_exp profit i.profit_pos employes"
local basic "i.subsector_corrige i.presence_enligne i.tunis year_created age i.legalstatus capital"
local innovation "inno_rd innovations i.innovated"
local network "net_nb_fam net_nb_dehors net_nb_qualite net_time net_coop_neg" // ml vars: net_nb_f net_nb_m
local obligations "i.famille1 famille2"
}
local allvars3 `exp_status' eri `financial' `basic' `network' `innovation' mpi marki genderi `obligations'

	* OLS
regress take_up `allvars3', robust
estimates store ols

	* Logit
logit take_up `allvars3', robust
estimates store logit

		* second attempt, first adjustment
{
local exp_status "i.exp_invested i.exp_afrique"
local financial "ca_exp business_size"
local basic "i.pole i.presence_enligne i.city year_created age i.legalstatus capital"
local network "net_nb_fam net_nb_qualite" // ml vars: net_nb_f net_nb_m
local obligations "famille2"
}
local allvars4 `exp_status' `financial' `basic' `network' mpmarki genderi `obligations'

	* OLS
regress take_up `allvars4', robust
estimates store ols

	* Logit
logit take_up `allvars4', robust
estimates store logit

		* third attempt, second adjustment
gen suarl = (legalstatus == 5)
{
local exp_status "i.exp_invested i.exp_afrique"
local financial "business_size"
local basic "i.pole i.presence_enligne i.suarl capital"
local network "net_nb_fam"
local obligations "famille2"
}
local allvars5 `exp_status' `financial' `basic' `network' mpmarki genderi `obligations'

	* OLS
regress take_up `allvars5', robust
estimates store ols

	* Logit
logit take_up `allvars5', robust
estimates store logit

		* fourth attempt, third adjustment
{
local exp_status "i.exp_invested i.exp_afrique"
local basic "i.presence_enligne i.suarl capital"
local network "net_nb_fam"
local obligations "famille2"
}
local allvars6 `exp_status' `financial' `basic' `network' mpmarki genderi `obligations'

	* OLS
regress take_up `allvars6', robust
estimates store ols

	* Logit
logit take_up `allvars6', robust
estimates store logit

	* selection via balance table
local balvars4 "net_nb_qualite net_coop_neg capital_w99 famille2 innovations net_nb_fam employes_w99 ca_w99 i.pole"
local balvars5 "net_nb_qualite net_coop_neg capital_w99 famille2 innovations net_nb_fam business_size i.pole"

