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
		*
order treatment, a(id_plateforme)

		* sort the data by id_plateforme (stable sort --> randomisation rule 2)
isid id_plateforme, sort

		* rank the random number
bysort treatment: gen random_number_ml = uniform()
egen rank = rank(random_number), by(treatment) unique

		* identify the observation that divides ranked firms into half
sum rank if treatment == 1, d
scalar rank_median_treat = r(p50)

sum rank if treatment == 0, d
scalar rank_median_control = r(p50)

		* allocate firms 50:50 to list treatment & control group
gen list_group_ml = .
replace list_group_ml = 1 if treatment == 1 & rank >= rank_median_treat
replace list_group_ml = 0 if treatment == 1 & rank < rank_median_treat

replace list_group_ml = 1 if treatment == 0 & rank >= rank_median_control
replace list_group_ml = 0 if treatment == 0 & rank < rank_median_control

order List_group, a(list_group_ml)

***********************************************************************
* 	PART 3: evaluate balance 			
***********************************************************************
*iebaltab ca_mean ca_expmean rg_fte rg_capital rg_oper_exp age presence_enligne, grpvar(list_group) save("${ml_output}/baltab_list_experiment_ml") replace ///
*			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
*			 format(%12.2fc)
tab list_group treatment		

***********************************************************************
* 	PART 4: assess replicability			
***********************************************************************
			* when re-running manually change the name of result_randomisation to compare
preserve
keep id_plateforme list_group* random_number_ml rank treatment
save "result_randomisation_list_ml", replace
restore