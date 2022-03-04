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
	* import file
use "${regis_intermediate}/regis_inter", clear

***********************************************************************
* 	PART 2: randomize eligible firms into two groups  			
***********************************************************************
		* sort the data by id_plateforme (stable sort --> randomisation rule 2)
isid id_plateforme, sort
		* rank the random number
gen random_number = uniform() if eligible == 1
egen rank = rank(random_number), unique
		* identify the observation that divides ranked firms into half
sum rank, d
scalar rank_median = r(p50)
		* allocate firms 50:50 to list treatment & control group
gen list_group = .
replace list_group = 1 if eligible == 1 & rank >= rank_median
replace list_group = 0 if eligible == 1 & rank < rank_median


***********************************************************************
* 	PART 3: evaluate balance 			
***********************************************************************
cd "$regis_figures"
iebaltab ca_mean ca_expmean rg_fte rg_capital rg_oper_exp age presence_enligne, grpvar(list_group) save(baltab_list_experiment) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
		

***********************************************************************
* 	PART 4: assess replicability			
***********************************************************************
			* when re-running manually change the name of result_randomisation to compare
preserve
keep id_plateforme list_group random_number rank eligible
save "result_randomisation", replace
restore




***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
	* set export directory
cd "$regis_intermediate"

	* save dta file
save "regis_inter", replace
