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
* 	PART 1: 	import raw data	  			
***********************************************************************		
use "${raw}/raw/rct_rne_raw", clear
	
	
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

***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

***********************************************************************
* 	PART 4: 	Drop unnecessary variables (e.g. text windows)		  			
***********************************************************************
drop effectifst? salairest? tranches generat*

***********************************************************************
* 	PART 5: 	Order the variables in the data set		  			
***********************************************************************
order id ndgcf annee, first

***********************************************************************
* 	PART 6: 	Rename the variables		  			
***********************************************************************
		* rename endline identification of respondent section
rename  masse_salariale total_wage
rename  exportv export_value
rename  exportp export_weight
rename  importv import_value
rename  importp import_weight
rename  njc net_job_creation

**********************************************************************
* 	PART 7: 	Label the variables		  			
***********************************************************************

            * comptabilité
label var moyennes "number of full-time employees"
label var ca_export_dt "export turnover in dt"
label var ca_local_dt "domestic turnover in dt "
label var resultataltat "company profit in dt"
label var ca_ttc_dt "total turnover in dt"
label var total_wage "total wage bill in millimes"
label var export_value "value of export in DT"
label var export_weight "export (weight)"
label var import_value "value of import in DT"
label var import_weight "import (weight)"
label var net_job_creation "net job creation"


***********************************************************************
* 	PART 8: Removing trail and leading spaces from string variables 			
***********************************************************************
ds, has(type string)
foreach x of varlist `r(varlist)' {
replace `x' = lower(strtrim(`x'))
}

***********************************************************************
* 	PART 9: Removing trail and leading spaces from string variables 			
***********************************************************************
ds, has(type string)
foreach x of varlist `r(varlist)' {
replace `x' = lower(strtrim(`x'))
}

***********************************************************************
* 	PART 10: Define panel: a) years considered, b) sort
***********************************************************************
	* keep only the last five years
drop if annee < 2017

	* sort firm-year with year 2022 first
gsort id -annee

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
save "${intermediate}/rct1_rne_inter", replace
