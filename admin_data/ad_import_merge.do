***********************************************************************
* 			Administrative data Import									  		  
***********************************************************************
*																	  
*	PURPOSE:  Import the adminstrative data provided by the INS
*																	  
*																	  
*	OUTLINE:														  
*	1)	import list of firms and variables needed for analysis
*	2)	merge rct firms to RNE universe of firms
*	3)  save merged file      					  
*																	  									  			
*
*	Authors:  	Florian Muench & Amira Bouziri
*	ID variable: 	id (example: f101)			  					  
*	Requires: enterprises.xlsx; ins_adminstrative_data.xlsx  
*   Creates:  ins_adminstrative_data.dta
		  
***********************************************************************
* 	PART 1: 	import list of firms and variables needed for analysis
***********************************************************************
import excel "${raw}/entreprises.xlsx", clear

*replace matricule_fiscale_correct = "966564M" in 42
*replace matricule_fiscale_correct = "1092914B" in 166
*replace matricule_fiscale_correct = "941121M" in 183

encode id_plateforme, gen(id)	
sum id
keep in 1/`r(N)' 	// make sure only real observations and not format induced missing values are kept
order id, first
sort id, stable

***********************************************************************
* 	PART 2:  merge rct firms to RNE universe of firms  					  
***********************************************************************
	* rename fiscal identifier for consistency with RNE
gen ndgcf = substr(matricule_fiscale, 1, strlen(matricule_fiscale) - 1)
duplicates drop ndgcf, force
sort ndgcf

	* merge RCT sample with RNE firm population
merge 1:m ndgcf using "${raw}/dw2022v"
	* @Jawhar: please share the result of this merge with us. Probably, several matricule fiscale
		* might have been named differently and must be corrected to be matched smoothly.

/* result merge:


*/

gen sample = (_merge == 1 | _merge == 3)
lab var sample "sample vs. rest of firm population"

local balancevar "ca_ttc_dt moyennes ca_export_dt ca_local_dt resultatall_dt  masse_salariale exportv exportp importv importp"

foreach var of varlist _all {
    rename `var' `=lower("`var'")'
}

iebaltab `balancevar' if annee == 2020, ///
    grpvar(sample) vce(robust) format(%12.2fc) replace ///
    ftest rowvarlabels ///
    savetex("${tables}/baltab_admin_population")

	* drop all the firms in the RNE that are not part of the RCT sample or could not be matched
drop if _merge == 2 | _merge == 1


***********************************************************************
* 	PART 3: 	save merged file
***********************************************************************
save "${raw}/rct_rne_raw", replace

