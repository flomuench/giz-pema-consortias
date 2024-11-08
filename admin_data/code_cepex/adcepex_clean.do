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

use "${data}/cepex_raw", clear
	
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
drop mf_len dup _merge

}
	
***********************************************************************
* 	PART 2: 	Adjust formats, encode, etc
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

//format %-9.0g annee

{
	local vars2020 Sum_Qte_2020 SumVALEUR_2021 Sum_Qte_2021 SumVALEUR_2020
	
	foreach x of local vars2020 {
		destring `x', replace
	}
	
}

	* Encode product names
		
encode Libelle_NDP, gen(product_name)

lab var product_name "Name of the product exported"

	* Encode countries
		
encode Libelle_Pays, gen(country)

lab var country "Name of the country to which the firm exported"

	* calculate unit prices

{  
	forvalues i = 2020(1)2024 {
		gen unit_price`i' = SumVALEUR_`i'/Sum_Qte_`i'
		lab var unit_price`i' "Unit price for `i'"
	}

	* average unit price
	
egen unit_price = rowmean(unit_price*)	
	
}

	* Total exports in volume
	
{
	forvalues i = 2020(1)2024 {
	bysort matricule_fiscale : egen export_volume_`i' = total(SumVALEUR_`i')
	
	lab var export_volume_`i' "Total export volumes in `i'"
	}
}

	* Total number of products per firm-year
	
egen tag = tag(matricule_fiscale country)
egen countries = total(tag), by(matricule_fiscale)

lab var countries "Number of countries to which the firm exported"

egen tag2 = tag(matricule_fiscale product_name)
egen products = total(tag2), by(matricule_fiscale)

lab var products "Number of products exported by the firm"

drop tag tag2

***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

***********************************************************************
* 	PART 4: 	Drop unnecessary variables (e.g. text windows)		  			
***********************************************************************

*** ADD


***********************************************************************
* 	PART 5: 	Rename the variables		  			
***********************************************************************

*** ADD


**********************************************************************
* 	PART 6: 	Label the variables		  			
***********************************************************************

   *** ADD

***********************************************************************
* 	PART 7: Reshape into panel form (wide format)
***********************************************************************

	** Save long

save "${data}/cepex_long", replace


	
	* drop year variables
	
drop sumvaleur_* sum_qte_* unit_price* product_name country 

bysort matricule_fiscale : gen tag = _n == 1

keep if tag==1

drop tag 



/*
order ndgcf annee, first
	* sort firm-year with year 2022 first
gsort ndgcf -annee
*/


***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
save "${long}/cepex_wide", replace
