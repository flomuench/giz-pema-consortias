***********************************************************************
* 			Consortium experiment randomisation								  		  
***********************************************************************
*																	   
*	PURPOSE: 						  								  
*																	  
*																	  
*	OUTLINE:														  
*	1)	 set seed + sort by id_plateforme													  
*	2)	 random allocation
*	3)	 balance table
*	4) 	 generate Excel sheets by treatment status
*																 	 *
*	Author:  	Fabian													  
*	ID variable: 	id_plateforme			  									  
*	Requires:		bl_final.dta
*	Creates:		bl_final.dta					  
*																	  
***********************************************************************
* 	PART Start: Import the data + set the seed				  		  *
***********************************************************************
	* import data
use "${bl_final}/bl_final", clear

	* change directory to visualisations
cd "$bl_output/randomisation"

	* continue word export
putdocx clear
putdocx begin
putdocx paragraph, halign(center) 
putdocx text ("Results of randomisation"), bold linebreak

***********************************************************************
* 	PART 1: Sort the data
***********************************************************************

	* Set a seed for today
set seed 2202

	* Sort 
sort id_plateforme, stable


***********************************************************************
* 	PART 2: Randomise
***********************************************************************
local stratavars strata2 strata3 strata4 strata5 strata6 strata7 strata8 strata9 strata10
foreach var of local stratavars{
	* random allocation, with seed generated random number on random.org between 1 million & 1 billion
randtreat, gen(treatment`var') strata(`var') misfits(strata) setseed(2202)

	* label treatment assignment status
lab def treat_status`var' 0 "Control" 1 "Treatment" 
lab values treatment`var' treat_status`var'
tab treatment`var', missing
}
/*
	* visualising treatment status by strata
graph hbar (count), over(treatment`var', lab(labs(tiny))) over(`var', lab(labs(small))) ///
	title("Firms by trial arm within each strata") ///
	blabel(bar, format(%4.0f) size(tiny)) ///
	ylabel(, labsize(minuscule) format(%-100s))
	graph export firms_per_treatmentgroup_strata`var'.png, replace
	putdocx paragraph, halign(center)
	putdocx image firms_per_treatmentgroup_strata`var'.png, width(4)
	
	*/
***********************************************************************
* 	PART 3: Balance checks
***********************************************************************
	/*	
		* balance for continuous and few units categorical variables
set matsize 20
iebaltab ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam exportmngt exportprep mngtvars, grpvar(treatment`var') ftest save(baltab_`var') replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)

	* Manully check the f-test for joint orthogonality using hc3:
	
local balancevarlist ca_2021 ca_exp_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam exportmngt exportprep mngtvars

reg treatment`var' `balancevarlist', vce(hc3)
testparm `balancevarlist'		
			 
		* visualizing balance for categorical variables with multiple categories
graph hbar (count), over(treatment`var', lab(labs(tiny))) over(pole, lab(labs(vsmall))) ///
	title("Balance across 4 sectors") ///
	blabel(bar, format(%4.0f) size(tiny)) ///
	ylabel(, labsize(minuscule) format(%-100s))
	graph export balance_sectors`var'.png, replace
	putdocx paragraph, halign(center)
	putdocx image balance_sectors`var'.png, width(4)	
		

}
*/


***********************************************************************
* 	PART 3c: comparing different options
***********************************************************************	
*Baltab for different options
local tvars treatmentstrata2 treatmentstrata3 treatmentstrata4 treatmentstrata5 treatmentstrata6 treatmentstrata7 treatmentstrata8 treatmentstrata9 treatmentstrata10

foreach var of local tvars{
display"`var'"
iebaltab ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam, grpvar(`var') ftest save(baltab_`var') replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)

	* Manully check the f-test for joint orthogonality using hc3:
	
local balancevarlist ca_2021 ca_exp_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam 

reg `var' `balancevarlist', vce(hc3)
testparm `balancevarlist'		
	}		 


		*exporting pstest with rubin's d
log using pstesttables.txt, text replace
local tvars treatmentstrata2 treatmentstrata3 treatmentstrata4 treatmentstrata5 treatmentstrata6 treatmentstrata7 treatmentstrata8 treatmentstrata9 treatmentstrata10
foreach var of local tvars{
display"`var'"
pstest ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam, t(`var') raw rubin label dist
}
log close

	* save word document with visualisations
putdocx save results_randomisation.docx, replace

***********************************************************************
* 	PART 5: Deciding on final approach and dropping remaining 
***********************************************************************	
	* Pick one strata approach, delete others

g strata_final = strata8

*delete intermediary variables used for tests*
drop strata2-strata10
drop strata?_prep
drop treatmentstrata?
drop ca_sd_strata?
drop exp_sd_strata?
drop profit_sd_strata?
drop pays_sd_strata?
drop pole2 

cd "$bl_final"
save "bl_final", replace
