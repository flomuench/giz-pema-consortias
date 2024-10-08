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
* 	PART 0:  import data		  			
***********************************************************************
use "${intermediate}/rct_rne_inter", clear

***********************************************************************
* 	PART 1:  Generate number of employees (use average)
***********************************************************************
egen employees = rowmean(effectifst1 effectifst2 effectifst3 effectifst4), by(annee id_plateforme)

egen wages = rowmean(salairest1 salairest2 salairest3 salairest4), by(annee id_plateforme)

***********************************************************************
* 	PART 2:  Winsorisation, Log-and IHS-Transformation
***********************************************************************
{
		* gen winsorized numerical variables
local kpis "ca_local_dt ca_ttc_dt resultatall_dt total_wage employees"
local export "ca_export_dt export_value import_value export_weight import_weight"
local vars `kpis' `export'
foreach var of local vars {
	winsor2 `var', suffix(_w99) cuts(0 99)
	winsor2 `var', suffix(_w95) cuts(0 95)
	gen l`var' = log(`var')
	ihstrans `var'_w99 if !inlist(`var', .), prefix(ihs_)
	ihstrans `var'_w95 if !inlist(`var', .), prefix(ihs_)

	}
}


lab var lca_export_dt "log-transformed export turnover"
lab var lca_local_dt "log-transformed turnover of sales in tunisia"
lab var lresultatall_dt "log-transformed company profit"
lab var lca_ttc_dt "log-transformed total sales Y"


***********************************************************************
* 	PART 3:  Percentile transformation
***********************************************************************
	* quantile transform profits --> see Delius and Sterck 2020 : https://oliviersterck.files.wordpress.com/2020/12/ds_cash_transfers_microenterprises.pdf
gen resultatall_dt_pct = .
	egen resultatall_dt_pct1 = rank(resultatall_dt) if !inlist(resultatall_dt, -777, -888, -999, .)	// use egen rank to get the rank of each value in the distribution of resultatal~ts
	sum resultatall_dt if !inlist(resultatall_dt, -777, -888, -999, .)
	replace resultatall_dt_pct = resultatall_dt_pct1/(`r(N)' + 1)			// divide by N + 1 to get a percentile for each observation
	
	egen resultatall_dt_pct2 = rank(resultatall_dt) if !inlist(resultatall_dt, -777, -888, -999, .)
	sum resultatall_dt if !inlist(resultatall_dt, -777, -888, -999, .)
	replace resultatall_dt_pct = resultatall_dt_pct2/(`r(N)' + 1)
	drop resultatall_dt_pct1 resultatall_dt_pct2
	
***********************************************************************
* 	PART 4:  Generating new variables
***********************************************************************	
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

foreach var of varlist price_exp price_exp_w99  price_imp price_imp_w99 {
	gen l`var' = log(`var')
}

	* profitable dummy
gen profitable = (resultatall_dt > 0)
	replace profitable = . if resultatall_dt  == .

	* export dummy
gen exported_admin = (ca_export_dt > 0  & ca_export_dt < .)


***********************************************************************
* 	PART 6:  make sure we have same length panel for all firms
***********************************************************************
			* set panel
drop if annee == . 
xtset ID annee
tsfill, full
	* @Jawhar please check here if there are zeros and not missing values for say export
	
***********************************************************************
* 	PART :  Save directory to progress folder
***********************************************************************
save "${intermediate}/rct_rne_inter", replace
