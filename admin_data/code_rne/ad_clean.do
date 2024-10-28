**********************************************************************
* 			Adminstrative clean									  		  
***********************************************************************
*																	  
*	PURPOSE: clean adminstrative intermediate data					  	  			
*																	  
*																	  
*	OUTLINE:														  
*	1)		Format string & numerical variables				          
*	2)  	Make all variables names lower case						  
*	3)   	Drop unnecessary variables (e.g. all text windows) from the survey
*	4)  	Order the variables in the data set						  	  
*	5)  	Rename the variables									  
*	6)  	Label the variables										  
*   8) 		Trim obversations										 
*																	  													      
*	Authors:  	Florian Muench & Amira Bouziri & Kaïs Jomaa & Ayoub Chamakhi 						    
*	ID variable: 	id (example: f101)			  					  
*	Requires: rct1_rne_raw.dta or list_rct 	  										  
*	Creates:  rct1_rne_inter.dta			                                  
***********************************************************************
* 	PART 0: 	import raw data	  			
***********************************************************************		
use "${raw}/rct_rne_raw", clear
	

***********************************************************************
* 	PART 1: 	Clean up reshape		
***********************************************************************	
{
	* keep only one var: mf, program_num
egen program_num = rowfirst(program_num1 program_num2 program_num3)
order program_num, a(program_num3)
drop program_num1 program_num2 program_num3

gen matricule_fiscale = "", a(matricule_fiscale3)
	replace matricule_fiscale = matricule_fiscale1 if program1 == 1 & matricule_fiscale == ""
	replace matricule_fiscale = matricule_fiscale2 if program2 == 1 & matricule_fiscale == ""
	replace matricule_fiscale = matricule_fiscale3 if program3 == 1 & matricule_fiscale == ""

drop matricule_fiscale1 matricule_fiscale2 matricule_fiscale3

	* create any var: treatment, take up, strata
egen treatment4 = rowmax(treatment1 treatment2 treatment3)
egen take_up4 = rowmax(take_up1 take_up2 take_up3)
order treatment4, a(treatment3)
order take_up4, a(take_up3)



gen strata_all = strata1 + strata2 + strata3 
	 order strata_all, a(strata3)
	 replace strata_all = "two programs" if program_num == 2 
	 replace strata_all = "three programs" if program_num == 3
encode strata_all, gen(strata4)
order strata4, a(strata3)
drop strata_all

destring strata2, replace
destring strata3, replace

rename strata1 strat
encode strat, gen(strata1)
order strata1, b(strata2)
drop strat


	* drop: mf_len, dup	
drop mf_len dup

}
	
***********************************************************************
* 	PART 2: 	Adjust format of string and numerical variables		
***********************************************************************
{
ds, has(type string) 
local strvars "`r(varlist)'"
format %-20s `strvars'

*Lower all string observations of string variables*
foreach x of local strvars {
replace `x' = lower(stritrim(strtrim(`x')))
}
 
ds, has(type numeric) 
local numvars "`r(varlist)'"
format %-25.0fc `numvars'
}

format %-9.0g annee


***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

***********************************************************************
* 	PART 4: 	Drop unnecessary variables (e.g. text windows)		  			
***********************************************************************
** correct the employment variable
drop moyennes nat96 apen96
egen employees = rowmean(effectifst1 effectifst2 effectifst3 effectifst4)
egen wages = rowmean(salairest1 salairest2 salairest3 salairest4)

drop effectifst? salairest? tranches generat*


***********************************************************************
* 	PART 5: 	Rename the variables		  			
***********************************************************************
		* rename endline identification of respondent section
rename  masse_salariale total_wage
rename  exportv export_value
rename  exportp export_weight
rename  importv import_value
rename  importp import_weight
rename  njc net_job_creation

rename ca_export_dt ca_export
rename ca_ttc_dt ca_ttc
rename ca_local_dt ca_local
rename resultatall_dt profit

**********************************************************************
* 	PART 6: 	Label the variables		  			
***********************************************************************

            * comptabilité
label var employees "number of full-time employees"
label var ca_export "export turnover in dt"
label var ca_local "domestic turnover in dt "
label var profit "company profit in dt"
label var ca_ttc "total turnover in dt"
label var total_wage "total wage bill in millimes"
label var export_value "value of export in DT"
label var export_weight "export (weight)"
label var import_value "value of import in DT"
label var import_weight "import (weight)"
label var net_job_creation "net job creation"


***********************************************************************
* 	PART 7: Define panel: a) years considered, b) sort
***********************************************************************
order ndgcf annee, first
	* sort firm-year with year 2022 first
gsort ndgcf -annee

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
save "${intermediate}/rct_rne_inter", replace
