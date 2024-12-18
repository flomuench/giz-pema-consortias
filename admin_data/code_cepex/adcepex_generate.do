***********************************************************************
* 			Appui Qualité Export (AQE) - master generate
***********************************************************************
*																	    
*	PURPOSE: Generate variables for final analysis AQE			
*																	  
*	OUTLINE:														 
*	1)	Gen treatment status variable			  						 
*	2)  Winsorisations 						  		    
*	3)  Log transformations
*	4)  Percentile transformation		  
*																	  
*	Author:  	Florian Muench					          													      
*	ID variable: 	id (example: f101)			  					  
*	Requires: aqe_database_inter 	   								   
*	Creates:  aqe_database_inter			   						  
*																	  
***********************************************************************
* 	PART 1:  Gen treatment status variable		  			
***********************************************************************
use "${intermediate}/cepex_long", clear


***********************************************************************
* 	PART 2:  Transform into Euros (easier for intl audiance)
***********************************************************************
/* annual exchange rates
2024 = 0.2968 
2023 = 


*/


gen exp_rev_euro = total_revenue_/3


***********************************************************************
* 	PART 3:  Accounting for inflation
***********************************************************************
gen exp_rev_dinar_deflated = 
gen exp_rev_euro_deflated = 

***********************************************************************
* 	PART 2:  DV Transformations: Winsorisations, IHS
***********************************************************************
{

local vars "total_revenue_ total_qty_ num_combos_ num_countries_ num_products_ exp_rev_dinar_deflated exp_rev_euro exp_rev_euro_deflated"

foreach var of local vars {
	winsor2 `var', suffix(_w99) cuts(0 99)
	winsor2 `var', suffix(_w95) cuts(0 95)
	ihstrans `var'_w99, prefix(ihs_)
	ihstrans `var'_w95, prefix(ihs_)
	}
}


***********************************************************************
* 	PART 3:  Percentile transformation
***********************************************************************
/* either delete or consider at later stage
{
	* quantile transform profits --> see Delius and Sterck 2020 : https://oliviersterck.files.wordpress.com/2020/12/ds_cash_transfers_microenterprises.pdf
gen profit_pct = .
	egen profit_pct1 = rank(profit) if !inlist(profit, -777, -888, -999, .)	// use egen rank to get the rank of each value in the distribution of resultatal~ts
	sum profit if !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct1/(`r(N)' + 1)			// divide by N + 1 to get a percentile for each observation
	
	egen profit_pct2 = rank(profit) if !inlist(profit, -777, -888, -999, .)
	sum profit if !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct2/(`r(N)' + 1)
	drop profit_pct1 profit_pct2
}	
*/

***********************************************************************
* 	PART 4:  Generating unit price variables
***********************************************************************	
{
	* price
gen price_exp  = export_value / export_weight
lab var price_exp "Export price"

gen price_imp  = import_value / import_weight
lab var price_imp "Import price"

gen price_exp_w99  = export_value_w99 / export_weight_w99
lab var price_exp_w99 "Export price, winsorized"

gen price_imp_w99  = import_value_w99 / import_weight_w99
lab var price_imp_w99 "Import price, winsorized"

gen price_exp_w95  = export_value_w95 / export_weight_w95
lab var price_exp_w95 "Export price, winsorized"

gen price_imp_w95  = import_value_w95 / import_weight_w95
lab var price_imp_w95 "Import price, winsorized"

foreach var of varlist price_exp price_exp_w99 price_exp_w95 price_imp price_imp_w99 price_imp_w95 {
	gen l`var' = log(`var')
	}

}
	
***********************************************************************
* 	PART 4:  Export dummy
***********************************************************************
	* export dummy
gen exported = (total_revenue_ > 0)
	replace exported = . if total_revenue_ == .  // account for MVs
	replace exported = 1 if exported == . & (total_revenue_ < . & total_revenue_ > 0) // account for customs data
}
	


***********************************************************************
* 	PART :  Save directory to progress folder
***********************************************************************
save "${final}/cepex_long", replace
