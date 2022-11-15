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
cd "$bl_output/randomisation/final"

	* continue word export
putdocx clear
putdocx begin
putdocx paragraph, halign(center) 
putdocx text ("Results of randomisation"), bold linebreak

***********************************************************************
* 	PART 1: Sort the data
***********************************************************************

	* Set a seed for today

set seed 07042022

	* Sort 
sort id_plateforme, stable


***********************************************************************
* 	PART 2: Randomise
***********************************************************************

	* random allocation, with seed generated random number on random.org between 1 million & 1 billion
randtreat, gen(treatment) strata(strata_final) misfits(strata) setseed(07042022)

	* label treatment assignment status
lab def treat_status 0 "Control" 1 "Treatment" 
lab values treatment treat_status
tab treatment, missing

	* visualising treatment status by strata
graph hbar (count), over(treatment, lab(labs(tiny))) over(strata_final, lab(labs(small))) ///
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
set matsize 25

iebaltab ca_2021 ca_exp_2021 profit_2021 capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, grpvar(treatment) ftest save(baltab_final) replace ///

			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
			 
		* balance for continuous and few units categorical variables tex formati
set matsize 25

iebaltab ca_2021 ca_exp_2021 profit_2021 capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite exportmngt exportprep mngtvars, grpvar(treatment) ftest savetex(baltab_final) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
			 
*Balance table without Outlier (ID=1092)
preserve
drop if id_plateforme==1092
iebaltab ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite, grpvar(treatment) ftest save(baltab_final_nooutlier) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
log using pstesttables_final_nooutlier.txt, text replace
pstest ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite, t(treatment) raw rubin label dist
log close
restore
	* Manully check the f-test for joint orthogonality using hc3:
	
local balancevarlist ca_2021 ca_exp_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam

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
pstest ca_2021 ca_exp_2021 profit_2021 exp_pays exprep_inv exprep_couts inno_rd num_inno net_nb_dehors net_nb_fam net_nb_qualite, t(treatment) raw rubin label dist
log close



*balance check winsorized at 99th percentile
iebaltab w_ca2021 w_caexp2021 w_profit2021 exp_pays w_exprep_inv exprep_couts inno_rd num_inno w_nonfamilynetwork net_nb_fam net_nb_qualite, grpvar(treatment) ftest save(baltab_final_winsorized) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
log using pstesttables_final_winsorized.txt, text replace
pstest w_ca2021 w_caexp2021 w_profit2021 exp_pays w_exprep_inv exprep_couts inno_rd num_inno w_nonfamilynetwork net_nb_fam net_nb_qualite, t(treatment) raw rubin label dist
log close

/*

***********************************************************************
* 	PART 4: Export excel spreadsheet
***********************************************************************			 		


	* save dta file with treatments and strata
	
cd "$bl_final"

save "bl_final", replace

	* Add a bunch of variables about the firms knowledge and digital presence in case the consultant want to group by ability*

order id_plateforme treatment pole


tostring id_plateforme, gen(id_plateforme2) format(%15.0f)
        drop id_plateforme
        ren id_plateforme2 id_plateforme
		

cd "$consortia_master"

merge 1:1 id_plateforme using contact_info_master.dta, generate(_merge2) force

keep if _merge2==3

drop _merge2	

cd "$bl_output/randomisation/final"
sort pole id_plateforme
local consortialist treatment id_plateforme firmname pole codepostal rg_adresse email_pdg email_rep tel_pdg tel_rep produit1 produit2 produit3 entr_idee operation_export age employes ca_2018 ca_2019 ca_2020 ca_2021 ca_exp2018 ca_exp2019 ca_exp2020 ca_exp_2021 att_adh_autres  

export excel `consortialist' using "consortia_listfinale" if treatment==1, sheet("Groupe participants") sheetreplace firstrow(var) 
export excel `consortialist' using "consortia_listfinale" if treatment==0, sheet("Groupe control") sheetreplace firstrow(var) 

	* save word document with visualisations
putdocx save results_randomisation.docx, replace


***********************************************************************
* 	PART 5: Add variable treatment to consortium_bl_pii
***********************************************************************		
preserve
keep id_plateforme treatment

* change directory to bl folder for merge with bl_final
cd "$bl_raw"

		* merge 1:1 based on project id_plateforme
merge 1:1 id_plateforme using consortia_bl_pii
drop _merge

    * save as consortia_bl_pii

save "consortia_bl_pii", replace

restore
*/
***********************************************************************
* 	PART 6: Add variable treatment to consortium_bl_final
***********************************************************************		
preserve
keep id_plateforme treatment
destring id_plateforme, replace
* change directory to bl folder for merge with bl_final
cd "$bl_final"

		* merge 1:1 based on project id_plateforme
merge 1:1 id_plateforme using "${bl_final}/bl_final"
drop _merge

    * save as consortia_bl_final

save "bl_final", replace
restore






