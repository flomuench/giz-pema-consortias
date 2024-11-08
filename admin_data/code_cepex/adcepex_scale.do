***********************************************************************
*				AQE: selection of optimal scaling factor k
***********************************************************************
*																	   
*	PURPOSE: Identify k, optimal scaling factor of numerical variables,
*	for ihs-transformation, such that weiht is on intensive margin &
*	R-squared maximised
* 
*	OUTLINE:														  
*	1)		Check how many zeros for each variable at endline 
*	2)		Generate rescaled numerical outcome variables
*	3)		IHS-transform all rescaled numerical outcome variables
*	4)		Change name of k = 1 variable for simpler looping
*	5)   	Set-up a table to store R squares for each variable
*	6)  	Run regressions (main ancova specification) for all transformations & collect R-squared			  
*	5)  	Label optimal k variables
*																
*	Author:  	Florian Muench			         													      
*	ID variable: 	id (example: f101)			  			
*	Requires: rct1_rne_inter.dta 	   								
*	Creates:  rct1_rne_final.dta			   					
*																	  
***********************************************************************
* 	PART:  set the stage 			
***********************************************************************
use "${intermediate}/rct1_rne_inter", clear

***********************************************************************
* 	PART 1:  check how many zeros for each variable at endline 			
***********************************************************************
		* accounting variables
foreach var of varlist ca_export_dt ca_local_dt resultatall_dt ca_ttc_dt export_value import_value {
	sum `var' if annee == 2022
		local N = `r(N)'
	sum `var' if `var' == 0 & annee == 2022
		local zeros = `r(N)'
		scalar perc = `zeros'/`N'
		if perc > 0.05 {
			display "`var' has `zeros' zeros out of `N' non-missing observations ("perc "%)."
			}
	scalar drop perc
}

/* @Jawhar: Result example:
ca_export_dt has 32 zeros out of 153 non-missing observations (.20915033%). 


*/

***********************************************************************
* 	PART 2:  generate rescaled numerical outcome variables 			
***********************************************************************
* all accounting variables wins. at 95th percentile but resultatal~t
	* consider the following re-scaling factors
		* 10^3-10^6 (1000, 10.000, 100.000, 1.000.000)
foreach var of varlist ca_export_dt ca_local_dt ca_ttc_dt export_value import_value {
		forvalues k = 3(1)6 {
			gen `var'_wk`k' = `var'_w99 / 10^`k' if !inlist(`var'_w99, .)
			lab var `var' "`var' wins., scaled by 10^`k'" 
		}
}

* resultatal~t profits are winsorized at 98 percentile
foreach var of varlist resultatall_dt  {
	forvalues k = 3(1)6 {
		gen `var'_wk`k' = `var'_w98 / 10^`k' if !inlist(`var'_w98, .)
		lab var `var' "`var' wins., scaled by 10^`k'" 
	}
}


***********************************************************************
* 	PART 3:  ihs-transform all rescaled numerical outcome variables 			
***********************************************************************
			* K = 1
foreach var of varlist ca_export_dt_w99 ca_local_dt_w99 resultatall_dt_w98 ca_ttc_dt_w99 export_value_w99 import_value_w99 {
		ihstrans `var' if !inlist(`var', .), prefix(ihs_)
}
			* K > 1
				* accounting vars
foreach var of varlist ca_export_dt ca_local_dt resultatall_dt ca_ttc_dt export_value import_value {
	forvalues k = 3(1)6 {
		ihstrans `var'_wk`k', prefix(ihs_)
		lab var ihs_`var'_wk`k' "`var' wins., scaled by 10^`k', ihs-transf." 
		}
}
		
***********************************************************************
* 	PART 4:  change name of k = 1 variable for simpler looping
***********************************************************************	
foreach var of varlist ca_export_dt ca_local_dt ca_ttc_dt import_value export_value {
	rename ihs_`var'_w99 ihs_`var'_wk2
}
foreach var of varlist resultatall_dt /*invest_iq rdd */ {
	rename ihs_`var'_w98 ihs_`var'_wk2
}
		
***********************************************************************
* 	PART 5:  visualize ihs-transformed, rescaled variables 			
***********************************************************************

* Uncommented when needed or first run. Comment out as takes long time to run once decision on transformations taken.

foreach var of varlist ca_export_dt ca_local_dt resultatall_dt ca_ttc_dt export_value import_value {
	local powers "1 10^3 10^4 10^5 10^6"
	forvalues k = 2(1)6 {
		gettoken power powers : powers
		histogram ihs_`var'_wk`k', /*start(0)*/ width(1)  ///
			name(`var'`k', replace) ///
			title("IHS-Tranformed `var': K = `power'")
		}
	gr combine `var'2 `var'3 `var'4 `var'5 `var'6, row(2)
	gr export "${figures}/scale_`var'.png", replace
}

*/

	
***********************************************************************
* 	PART 6:  Set-up a table to store R squares for each variable			
***********************************************************************
	* create excel document
putexcel set "${figures}/scale_k.xlsx", replace

	* define table title
putexcel A1 = "Selection of optimal K", bold border(bottom) left
	
	* create top border for variable names
putexcel A2:G2 = "", border(top)
	
	* define column headings
putexcel A2 = "", border(bottom) hcenter
putexcel B2 = "ca_export_dt", border(bottom) hcenter
putexcel C2 = "ca_local_dt", border(bottom) hcenter
putexcel D2 = "resultatal~t", border(bottom) hcenter
putexcel E2 = "import_value", border(bottom) hcenter
putexcel F2 = "ca_ttc_dt", border(bottom) hcenter
putexcel G2 = "export_value", border(bottom) hcenter

	
	* define rows
putexcel A3 = "k = 1", border(bottom) hcenter
putexcel A4 = "k = 10^3", border(bottom) hcenter
putexcel A5 = "k = 10^4", border(bottom) hcenter
putexcel A6 = "k = 10^5", border(bottom) hcenter
putexcel A7 = "k = 10^6", border(bottom) hcenter

	
***********************************************************************
* 	PART 7:  run regressions (main ancova specification) for all transformations for each outcome & collect R-squared 			
***********************************************************************
	* set panel and sort the observations
			* sort firm-year with year 2022 first
sort id annee
			
			* set panel
xtset ID annee 

	* generate lags & missing lags dummies
foreach var of varlist ca_export_dt ca_local_dt resultatall_dt import_value ca_ttc_dt export_value {
	forvalues x = 1(1)3	{
		* generate lags
	gen `var'l`x' = l`x'.`var'
	lab var `var'l`x' "`var' lag-`x'"
		
		* generate missing lag
	gen miss_`var'_l`x' = (`var'l`x' == .)										// gen dummy for baseline
	lab var miss_`var'_l`x' "`var' lag-`x' missing"
}
}

	* run the main specification regression looping over all values of k
local columns "B C D E F G"
foreach var of varlist ca_export_dt ca_local_dt resultatall_dt ca_ttc_dt import_value export_value {
    local row = 3
    gettoken column columns : columns
    forvalues k = 2(1)6 {
	sum ihs_`var'_wk`k' i.treatment `var'l? i.miss_`var'_l? i.strata if annee == 2022
        capture: reg ihs_`var'_wk`k' i.treatment `var'l? i.miss_`var'_l? i.strata if annee == 2022, cluster(id)
        if _rc == 0 {
            local r2 = e(r2)
            putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
            local row = `row' + 1
        }
        else {
            display "Regression with `var' at lag `k' failed with error code " _rc
            local row = `row' + 1
        }
    }
}

	* drop the y0 & missing bl again (final versions created in regressions_el.do for unit consistency)
drop ca_export_dtl1 ca_export_dtl2 ca_export_dtl3 ca_local_dtl1 ca_local_dtl2 ca_local_dtl3 resultatall_dtl1 resultatall_dtl2 resultatall_dtl3 import_valuel1 import_valuel2 import_valuel3 ca_ttc_dtl1 ca_ttc_dtl2 ca_ttc_dtl3 export_valuel1 export_valuel2 export_valuel3 miss_*


***********************************************************************
* 	PART 8:  label optimal k variables
***********************************************************************
*lab var ihs_invest_iq_wk2 "QI investment"
lab var ihs_ca_export_dt_wk6 "Export sales"
*lab var ihs_rdd_wk4 "R&D expenditure"
lab var ihs_ca_local_dt_wk2 "Domestic sales"
lab var ihs_ca_local_dt_wk6 "Domestic sales"
*lab var zca_ttc_dt "Total sales"
*lab var ihs_resultatal~t "Profit"
*lab var zresultatal~t "Profit"

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
save "${final}/rct1_rne_final", replace
