**********************************************************************
* 			Adminstrative clean									  		  
***********************************************************************
*																	  
*	PURPOSE: clean adminstrative intermediate data					  	  			
*																	  
*																	  
*	OUTLINE:														  
*	1)		Clean up repeated variables Format string & numerical variables				          
*	2)  	Make all variables names lower case						  
*	3)   	Drop unnecessary variables (e.g. all text windows) from the survey
*	4)  	Order the variables in the data set						  	  
*	5)  	Rename the variables									  
*	6)  	Label the variables										  
*   8) 		Trim obversations										 
*																	  													      
*	Authors:  	Florian Muench & Teo Firpo
*	ID variable: 	id (example: f101)			  					  
*	Requires: rct1_rne_raw.dta or list_rct 	  										  
*	Creates:  rct1_rne_inter.dta			                                  
***********************************************************************
* 	PART 0: 	import raw data	  			
***********************************************************************		

use "${raw}/cepex_raw", clear
	
***********************************************************************
* 	PART 1: 	Clean up 		
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

	* destring
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

	* average unit price by product
	forvalues i = 2020(1)2024 {
		bysort ndgcf product_name: egen avg_unit_price`i' = mean(unit_price`i')	
		lab var avg_unit_price`i' "Average unit product price in `i'"
	}	
	
	/* increases in unit prices
		** take first available unit price (in 2020 or 2021)
gen first_price = .
replace first_price = avg_unit_price2020 if avg_unit_price2020!=.
replace first_price = avg_unit_price2021 if avg_unit_price2021!=.	& avg_unit_price2020==.
		** last price
gen last_price = .
replace last_price = avg_unit_price2024 if !missing(avg_unit_price2024)
replace last_price = avg_unit_price2023 if !missing(avg_unit_price2023) & missing(avg_unit_price2024)

		** now unit price changes
gen price_change_pc = .
replace price_change_pc = last_price - first_price if !missing(first_price) & !missing(last_price)
		
		** including in percentage terms
gen price_change_pc_per = price_change_pc/first_price
drop last_price first_price
*/
}


	* Total number of countries per year

	forvalues i = 2020(1)2024 {
		* check if the value for that product-country-firm combo is nonzero
		gen exported_`i' = !missing(SumVALEUR_`i') & SumVALEUR_`i' > 0
		* tag unique countries
		egen tag`i' = tag(ndgcf country) if exported_`i'==1
		egen num_countries_`i' = total(tag`i'), by(ndgcf)
		* lable 
		lab var num_countries_`i' "Number of countries exported to in `i'"
	}	
	
	* Total number of products per year

	
		forvalues i = 2020(1)2024 {
		* tag unique products
		egen tag_product_`i' = tag(ndgcf product_name) if exported_`i'==1
		egen num_products_`i' = total(tag_product_`i'), by(ndgcf)
		* lable 
		lab var num_products_`i' "Number of products exported to in `i'"
	}	
	
	
	* Total number of products-country combinations per year
	
		* create unique product-countries
			* decode the two encoded variables into string versions
			decode country, gen(country_str)
			decode product_name, gen(product_name_str)

			* combine the two decoded string variables into one
			gen country_product = country_str + "_" + product_name_str
		
		forvalues i = 2020(1)2024 {
		* tag unique products-countries
		egen tag_combos_`i' = tag(ndgcf country_product) if exported_`i'==1
		egen num_combos_`i' = total(tag_combos_`i'), by(ndgcf)
		* lable 
		lab var num_combos_`i' "Number of product-country combinations exported to in `i'"
	}	
	


***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

***********************************************************************
* 	PART 4: 	Drop unnecessary variables (e.g. text windows)		  			
***********************************************************************

drop tag* tag_combos_* tag_product_* country_str product_name_str country_product exported_*


***********************************************************************
* 	PART 5: 	Rename the variables		  			
***********************************************************************

*** ADD


**********************************************************************
* 	PART 6: 	Label the variables		  			
***********************************************************************

lab var program_num "Number of programs the firm participated in"
lab var matricule_fiscale "Fiscal identifier"

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
save "${intermediate}/cepex_wide", replace

