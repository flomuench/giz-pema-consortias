***********************************************************************
* 			Admin Export Data - Generate derived variables
***********************************************************************
*																	    
*	PURPOSE: Generate variables for final analysis			
*																	  
*	OUTLINE:														 
*	1)	Transform into Euros			  						 
*	2)  Deflate 						  		    
*	3)  Ihs-transform & winsorize
*	4)  		  
*																	  
*	Author:  	Florian Muench					          													      
*	ID variable: 	id (example: f101)			  					  
*	Requires: aqe_database_inter 	   								   
*	Creates:  aqe_database_inter			   						  
*																	  
***********************************************************************
* 	PART 1: Import data  			
***********************************************************************
use "${intermediate}/cepex_panel_inter", clear


***********************************************************************
* 	PART 2:  Transform into Euros (easier for intl audiance)
***********************************************************************
{
/* annual exchange rates
2024 = 0.2968 
2023 = 
*/


gen value_eur = value/3

}

***********************************************************************
* 	PART 3:  Accounting for inflation
***********************************************************************
{
/* 
Deflation Factor t = 1 /  (1+Inflation Rate 2021)×(1+Inflation Rate 
2022)×...×(1+Inflation Rate t)
​
Inflation rates (rounded 10^3 after comma):

2021 = 0.057 ; 2022 = 0.071 ; 2023 = 0.074 ; 2024 = 0.066

Source: FED St Louis, IMF: https://fred.stlouisfed.org/series/TUNPCPICOREPCHPT
*/


gen dfl_factor_21 = 1/(1+0.057)
gen dfl_factor_22 = 1/((1+0.057)*(1+0.071))
gen dfl_factor_23 = 1/((1+0.057)*(1+0.071)*(1+0.074))
gen dfl_factor_24 = 1/((1+0.057)*(1+0.071)*(1+0.074)*(1+0.066))

local val "value value_eur"
foreach v of local val {
	gen `v'_dfl = ., a(`v')
		replace `v'_dfl = `v' if year == 2020
			forvalues y = 1(1)4 {
				replace `v'_dfl = `v' * dfl_factor_2`y' if year == 202`y'
	}
	
	format `v'_dfl %-25.0fc

}

drop dfl_factor_2?

}

***********************************************************************
* 	PART 4:  DV Transformations: Winsorisations, IHS
***********************************************************************
{

local vars "value value_dfl value_eur value_eur_dfl countries products quantity" // exp_rev_dinar_deflated exp_rev_euro_deflated

foreach var of local vars {
	winsor2 `var', suffix(_w99) cuts(0 99)
	winsor2 `var', suffix(_w95) cuts(0 95)
	ihstrans `var'_w99, prefix(ihs_)
	ihstrans `var'_w95, prefix(ihs_)
	}
}


***********************************************************************
* 	PART :  Percentile transformation
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
* 	PART 5:  Generating unit price variables
***********************************************************************	
{
	* price
gen price_exp  = value / quantity
lab var price_exp "Average unit price"


gen price_exp_w99  = value_w99 / quantity_w99
lab var price_exp_w99 "Average unit price, winsorized"

gen price_exp_w95  = value_w95 / quantity_w95
lab var price_exp_w95 "Average unit price, winsorized"

foreach var of varlist price_exp price_exp_w99 price_exp_w95 {
	gen l`var' = log(`var')
	}

}
	
***********************************************************************
* 	PART 4:  Export dummy
***********************************************************************
	* export dummy
gen exported = (value > 0)
	replace exported = . if value == .  // account for MVs
	replace exported = 1 if exported == . & (value < . & value > 0) // account for customs data
	

	
***********************************************************************
* 	PART 5:  Create treatment variables for staggered Did
***********************************************************************
* Callaway & Sant'Anna estimator

gen first_treat = ., a(treatment4)
	replace first_treat = 0 if treatment4 == 0
	replace first_treat = 2021 if treatment1 == 1
	replace first_treat = 2022 if treatment2 == 1 | treatment3 == 1
	
tab first_treat, missing


gen first_treat_take_up = ., a(take_up4)
	replace first_treat_take_up = 0 if take_up4 == 0
	replace first_treat_take_up = 2021 if take_up1 == 1
	replace first_treat_take_up = 2022 if take_up2 == 1 | take_up3 == 1




***********************************************************************
* 	PART :  Save directory to progress folder
***********************************************************************
save "${final}/cepex_panel_final", replace
