***********************************************************************
* 			registration list experiment randomisation
***********************************************************************
*																	   
*	PURPOSE:  simple random draw for list experiment  														 
*	OUTLINE:  allocation women CEOs into TG (4 options) & CG (3 options)
*				  
*	1)				create + save a master file		  		  			
*	2)  			save a de-identified final analysis file					 
*	3)  			delete the intermediate file							  
*																	  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta	  
*	Creates:  regis_final.dta + consortia_master_data			  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
use "${master_raw}/consortium_pii_raw", clear


***********************************************************************
* 	PART 2: midline: randomize firms, by treatment group, into two groups  			
***********************************************************************
set seed 8413195
set sortseed 8413195
		
order treatment, a(id_plateforme)

		* sort the data by id_plateforme (stable sort --> randomisation rule 2)
isid id_plateforme, sort

		* rank_ml the random number
bysort treatment: gen random_number_ml = uniform()
egen rank_ml = rank(random_number_ml), by(treatment) unique

		* identify the observation that divides ranked firms into half
sum rank_ml if treatment == 1, d
scalar rank_median_treat = r(p50)

sum rank_ml if treatment == 0, d
scalar rank_median_control = r(p50)

		* allocate firms 50:50 to list treatment & control group
gen list_group_ml = .
replace list_group_ml = 1 if treatment == 1 & rank_ml >= rank_median_treat
replace list_group_ml = 0 if treatment == 1 & rank_ml < rank_median_treat

replace list_group_ml = 1 if treatment == 0 & rank_ml >= rank_median_control
replace list_group_ml = 0 if treatment == 0 & rank_ml < rank_median_control

order List_group, a(list_group_ml)

***********************************************************************
* 	PART 3: endline: randomize firms, by treatment group, into two groups  			
***********************************************************************
set seed 06182014
set sortseed 06182014
		
order treatment, a(id_plateforme)

		* sort the data by id_plateforme (stable sort --> randomisation rule 2)
isid id_plateforme, sort

		* rank_el the random number
bysort treatment: gen random_number_el = uniform()
egen rank_el = rank(random_number_el), by(treatment) unique

		* identify the observation that divides ranked firms into half
sum rank_el if treatment == 1, d
scalar rank_median_treat = r(p50)

sum rank_el if treatment == 0, d
scalar rank_median_control = r(p50)

		* allocate firms 50:50 to list treatment & control group
gen list_group_el = .
replace list_group_el = 1 if treatment == 1 & rank_el >= rank_median_treat
replace list_group_el = 0 if treatment == 1 & rank_el < rank_median_treat

replace list_group_el = 1 if treatment == 0 & rank_el >= rank_median_control
replace list_group_el = 0 if treatment == 0 & rank_el < rank_median_control

order List_group, a(list_group_el)

***********************************************************************
* 	PART 4: evaluate balance 			
***********************************************************************
*iebaltab ca_mean ca_expmean rg_fte rg_capital rg_oper_exp age presence_enligne, grpvar(list_group) save("${ml_output}/baltab_list_experiment_ml") replace ///
*			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
*			 format(%12.2fc)
tab list_group_ml treatment		
tab list_group_el treatment		
tab list_group_ml list_group_el

***********************************************************************
* 	PART 5: assess replicability			
***********************************************************************
			* when re-running manually change the name of result_randomisation to compare
preserve
keep id_plateforme list_group_ml random_number_ml rank_ml treatment
save "${ml_output}/result_randomisation_list_ml", replace
restore

* when re-running manually change the name of result_randomisation to compare
preserve
keep id_plateforme list_group_el random_number_el rank_el treatment
save "${el_output}/result_randomisation_list_el", replace
restore
***********************************************************************
* 	PART 6: save 
***********************************************************************
save "${master_intermediate}/consortium_pii_inter", replace
