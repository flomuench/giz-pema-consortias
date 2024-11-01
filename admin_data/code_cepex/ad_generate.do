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
use "${intermediate}/rct_rne_inter", clear


***********************************************************************
* 	PART 2:  Generate costs
***********************************************************************
gen cost = profit - ca_ttc

***********************************************************************
* 	PART 2:  DV Transformations: Winsorisations, IHS
***********************************************************************
{
local kpis "ca_local ca_ttc total_wage cost employees wages net_job_creation"
local export "ca_export export_value import_value export_weight import_weight"
local vars `kpis' `export'

foreach var of local vars {
	winsor2 `var', suffix(_w99) cuts(0 99)
	winsor2 `var', suffix(_w95) cuts(0 95)
	ihstrans `var'_w99, prefix(ihs_)
	ihstrans `var'_w95, prefix(ihs_)
}

	* profits: as negative, wins bottom too
winsor2 profit, suffix(_w99) cuts(1 99)
winsor2 profit, suffix(_w95) cuts(5 95)
ihstrans profit_w99, prefix(ihs_)
ihstrans profit_w95, prefix(ihs_)

}


***********************************************************************
* 	PART 3:  Percentile transformation
***********************************************************************
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

	* profitable dummy
gen profitable = (profit > 0)
	replace profitable = . if profit == .

	* export dummy
gen exported = (ca_export > 0)
	replace exported = . if ca_export == .  // account for MVs
	replace exported = 1 if exported == . & (export_value < . & export_value > 0) // account for customs data
}
	


***********************************************************************
* 	PART :  Save directory to progress folder
***********************************************************************
save "${final}/rct1_rne_final", replace
