***********************************************************************
* 			E-commerce experiment randomisation								  		  
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

set seed 542022

	* Sort 
sort id_plateforme, stable


***********************************************************************
* 	PART 2: Randomise
***********************************************************************

	* random allocation, with seed generated random number on random.org between 1 million & 1 billion
randtreat, gen(treatment) strata(strata_final) misfits(strata) setseed(542022)

	* label treatment assignment status
lab def treat_status 0 "Control" 1 "Treatment" 
lab values treatment treat_status
tab treatment, missing

	* visualising treatment status by strata
graph hbar (count), over(treatment, lab(labs(tiny))) over(strata, lab(labs(small))) ///
	title("Firms by trial arm within each strata") ///
	blabel(bar, format(%4.0f) size(tiny)) ///
	ylabel(, labsize(minuscule) format(%-100s))
	graph export firms_per_treatmentgroup_strata.png, replace
	putdocx paragraph, halign(center)
	putdocx image firms_per_treatmentgroup_strata.png, width(4)
	
	
***********************************************************************
* 	PART 3: Balance checks
***********************************************************************
		
		* balance for continuous and few units categorical variables
iebaltab ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam exportmngt exportprep mngtvars, grpvar(treatment) ftest save(baltab_final) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)

	* Manully check the f-test for joint orthogonality using hc3:
	
local balancevarlist ca_2021 ca_exp_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam exportmngt exportprep mngtvars

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
pstest ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts num_inno net_nb_dehors net_nb_fam exportmngt exportprep mngtvars, t(treatment) raw rubin label dist
log close
***********************************************************************
* 	PART 4: Export excel spreadsheet
***********************************************************************			 		


	* save dta file with treatments and strata
	
cd "$bl_final"

save "bl_final", replace

	* Add a bunch of variables about the firms knowledge and digital presence in case the consultant want to group by ability*

order id_plateforme treatment pole

cd "$consortia_master"

merge 1:1 id_plateforme using consortia_master_data.dta, generate(_merge2) force

keep if _merge2==3

drop _merge2	

cd "$bl_output/randomisation"

local consortialist treatment id_plateforme pole codepostal rg_adresse email_pdg email_rep tel_pdg tel_rep produit1 produit2 produit3 
export excel `consortialist' using "consortia_listfinale" if treatment==1, sheet("Groupe participants") sheetreplace firstrow(var) 
export excel `consortialist' using "consortia_listfinale" if treatment==0, sheet("Groupe control") sheetreplace firstrow(var) 
*/
	* save word document with visualisations
putdocx save results_randomisation.docx, replace
















