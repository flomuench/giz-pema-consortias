***********************************************************************
* 	Main regressions - Adminstrative data
***********************************************************************
*																	   
*	PURPOSE: Run main regression for analysis of the experiment 
*	OUTLINE:														  
*
*																
*	Author:  	Florian Muench			         													      
*	ID variable: 	id (example: f101)			  			
*	  Requires: ad_final.dta 	  										  
*	  Creates:  ad_final.dta										  							  
***********************************************************************
* 	PART:  set the stage - technicalities	
***********************************************************************
	* import the data 
use "${final}/rct1_rne_final", clear

	* set directory to regression tables folder
cd "${tables}"

	* set panel and sort the observations
			* sort firm-year with year 2022 first
sort ID annee
			
			* set panel
xtset ID annee 

***********************************************************************
* 	PART 1:  rename transformed variables for simpler loopping	
***********************************************************************
	* rename variables absolute values as varname_temp
local absolute_values ca_export_dt ca_local_dt resultatall_dt import_value ca_ttc_dt export_value price_exp price_imp
foreach var of local absolute_values {
		rename `var' `var'_temp
}

	* rename transformed variables to original variable names
		* ! requires selecting optimal unit k for transformation of continuous outcomes
		
			* ca_export_dt
rename ihs_ca_export_dt_wk6 ca_export_dt

			* ca_local_dt
rename ihs_ca_local_dt_wk6 ca_local_dt

			* resultatal~t
rename ihs_resultatall_dt_wk6 resultatall_dt		// ihs_resultatal~t_w98

			* ca_ttc_dt
rename ihs_ca_ttc_dt_wk6 ca_ttc_dt

			* ex-/import amount
rename ihs_export_value_wk6 export_value
rename ihs_import_value_wk6 import_value

			* export/import price
rename lprice_exp_w99 price_exp
rename lprice_imp_w99 price_imp

		* for regression tables shorten take-up2 name
rename take_up_sum2 take_up2
		
***********************************************************************
* 	PART 2:  create lagged values 
***********************************************************************
*local kpi_table ca_local_dt ca_ttc_dt profitable resultatall_dt resultatall_dt_pct
*local trade_table ca_export_dt export_value price_exp import_value price_imp

local kpi_table ca_local_dt ca_ttc_dt resultatall_dt profitable resultatall_dt_pct
local trade_table ca_export_dt export_value price_exp import_value price_imp
 

foreach var of varlist `kpi_table' `trade_table' {
	
	forvalues x = 1(1)4 	{	// for 5-pre treatment years
		* generate lags
	gen `var'l`x' = l`x'.`var'
	lab var `var'l`x' "`var' lag-`x'"
		
		* generate missing lag
	gen miss_`var'_l`x' = (`var'l`x' == .)										// gen dummy for baseline
	lab var miss_`var'_l`x' "`var' lag-`x' missing"
	}
}

***********************************************************************
* 	PART 3: Make sure all variables are labeled for the regression table columns
***********************************************************************
	* label variables
lab var ca_ttc_dt "sales, ihs"
lab var resultatall_dt "Profit, ihs" 
lab var profitable "Profitable"
lab var resultatall_dt_pct "Profit, pct"

lab var ca_export_dt "Export sales, tax"
lab var export_value  "Export sales, customs"
lab var price_exp "Export price"
lab var import_value "Imports, customs" 
lab var price_imp "Import price" 

gen non_mising = !missing(ca_ttc_dt) & !missing(profitable) & annee == 2022
tab non_mising
drop if missing(ca_ttc_dt) | missing(profitable)
count if !missing(ca_ttc_dt) & !missing(profitable) & annee == 2022
 
***********************************************************************
* 	PART 3: Average treatment effect: business
***********************************************************************
* variables available for 2022

{
capture program drop rct_regression_business // enables re-running
program rct_regression_business
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment c.`var'l1 c.`var'l2 i.miss_`var'_l1 i.miss_`var'_l2 i.strata if annee == 2022 & non_mising == 1 , cluster(id)
			estadd local lags "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' c.`var'l1 c.`var'l2 i.miss_`var'_l1 i.miss_`var'_l2 i.strata (take_up = i.treatment) if annee == 2022 & non_mising == 1 , cluster(id) first
			estadd local lags "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum `var' if treatment == 0 & annee > 2020 
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'_21.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata ?.miss* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'_21.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata ?.miss* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				

* coefplot: ihs
coefplot ///
(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"`1' (ITT)"' `1'2 = `"`1' (TOT)"' `2'1 = `"`2' (ITT)"' `2'2 = `"`2' (TOT)"'  `3'1 = `"`3' (ITT)"' `3'2 = `"`3' (TOT)"' `4'1 = `"`4' (ITT)"' `4'2 = `"`4' (TOT)"'  `5'1 = `"`5' (ITT)"' `5'2 = `"`5' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(business_`generate'_cfplot_21, replace)
gr export business_`generate'_cfplot_21.png, replace

		
end
}
	* apply program to business performance outcomes
rct_regression_business ca_ttc_dt ca_ttc_dt ca_ttc_dt profitable profitable, gen(business)
exit 	
***********************************************************************
* 	PART 5: Average treatment effect: trade
***********************************************************************
{
capture program drop rct_regression_trade // enables re-running
program rct_regression_trade
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment c.`var'l1 i.miss_`var'_l1 i.strata if annee == 2022, cluster(id)
			estadd local lags "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' c.`var'l1 i.miss_`var'_l1 i.strata (take_up = i.treatment) if annee == 2022, cluster(id) first
			estadd local lags "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum `var' if treatment == 0 & annee > 2020 
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'_21.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{3}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata ?.miss* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'_21.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata ?.miss* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				

* coefplot: ihs
coefplot ///
(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"`1' (ITT)"' `1'2 = `"`1' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(`generate'_cfplot_21, replace)
gr export `generate'_cfplot_21.png, replace

		
end
}
	* apply program to business performance outcomes
rct_regression_trade ca_export_dt, gen(trade)

***********************************************************************
* 	PART 6:  Sectoral heterogeneity
***********************************************************************
	* business
{
	* all in one table
capture program drop rth_sector_business
program rth_sector_business
	version 14.2
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "sector==12  inlist(sector,13,14) !inlist(sector,12,13,14)"
		local groups "a t r"
		
		foreach cond of local conditions {
				gettoken group groups : groups

	* ITT: ancova plus stratification dummies						
					* ITT: ancova plus stratification dummies
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'l? i.miss_`outcome'_l? i.strata if `cond' &  annee == 2022, cluster(id)
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'l? i.miss_`outcome'_l? i.strata (take_up = i.treatment) if `cond' & annee == 2022, cluster(id) first
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & annee > 2020 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}


	* Change logic: apply to all variables at a time
tokenize `varlist'

		* Put all regressions into one table
		* Top panel: ITT
		* Put everything into a regression table
			local regressions `1'_a1 `1'_t1 `1'_r1 `2'_a1 `2'_t1 `2'_r1 `3'_a1 `3'_t1 `3'_r1 `4'_a1 `4'_t1 `4'_r1 `5'_a1 `5'_t1 `5'_r1 
		esttab `regressions' using "rth_`generate'_sector_21.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance by firm sector} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{17}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						mlabels(, depvars) /// use dep vars labels as model title
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						collabels(none) ///	do not use statistics names below models
						label 		/// specifies EVs have label
						drop(_cons *.strata ?.miss* *l*) ///
						noobs
					
						* Bottom panel: TOT
			local regressions `1'_a2 `1'_t2 `1'_r2 `2'_a2 `2'_t2 `2'_r2 `3'_a2 `3'_t2 `3'_r2 `4'_a2 `4'_t2 `4'_r2 `5'_a2 `5'_t2 `5'_r2 
			esttab `regressions' using "rth_`generate'_sector_21.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{16}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
						drop(_cons *.strata ?.miss* *l*) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline\hline\hline \\ \multicolumn{16}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 5-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %										
end	
	
}
			
	* apply program to business performance outcomes
rth_sector_business ca_local_dt ca_ttc_dt resultatall_dt profitable resultatall_dt_pct, gen(business)
	
	* trade
{
	* all in one table
capture program drop rth_sector_trade
program rth_sector_trade
	version 14.2
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "sector==12  inlist(sector,13,14) !inlist(sector,12,13,14)"
		local groups "a t r"
		
		foreach cond of local conditions {
				gettoken group groups : groups

	* ITT: ancova plus stratification dummies						
					* ITT: ancova plus stratification dummies
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'l? i.miss_`outcome'_l? i.strata if `cond' &  annee == 2022, cluster(id)
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'l? i.miss_`outcome'_l? i.strata (take_up = i.treatment) if `cond' & annee == 2022, cluster(id) first
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & annee > 2020 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}


	* Change logic: apply to all variables at a time
tokenize `varlist'

		* Put all regressions into one table
		* Top panel: ITT
		* Put everything into a regression table
			local regressions `1'_a1 `1'_t1 `1'_r1
		esttab `regressions' using "rth_`generate'_sector_21.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance by firm sector} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						mlabels(, depvars) /// use dep vars labels as model title
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						collabels(none) ///	do not use statistics names below models
						label 		/// specifies EVs have label
						drop(_cons *.strata ?.miss* *l*) ///
						noobs
					
						* Bottom panel: TOT
			local regressions `1'_a2 `1'_t2 `1'_r2
			esttab `regressions' using "rth_`generate'_sector_21.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
						drop(_cons *.strata ?.miss* *l*) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 5-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %										
end	
	
}

	* apply program to trade outcomes
*rth_sector_admin ca_export_dt export_value lprice_exp_w99 import_value lprice_imp_w99, gen(trade)
rth_sector_trade ca_export_dt, gen(trade)

***********************************************************************
* 	PART 5:  Size heterogeneity
***********************************************************************
	* business
{
	* all in one table
capture program drop rth_size_bus
program rth_size_bus
	version 14.2
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
		local conditions "bl_size==1 bl_size==2 bl_size==3"
		local groups "s m l"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
					* ITT: ancova plus stratification dummies
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'l? i.miss_`outcome'_l?  i.strata if `cond' & annee == 2022, cluster(id)
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'l?  i.miss_`outcome'_l?  i.strata (take_up = i.treatment) if `cond' & annee == 2022, cluster(id) first
					estadd local lags "Yes"
					estadd local strata "Yes"
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & annee > 2020 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}

	* Change logic: apply to all variables at a time
tokenize `varlist'

		* Top panel: ITT
		* Put everything into a regression table
		local regressions `1'_s1 `1'_m1 `1'_l1
		esttab `regressions' using "rth_`generate'_size_21.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on `generate' by firm size} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \begin{tabular}{l*{5}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						mlabels(, depvars) /// use dep vars labels as model title
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						collabels(none) ///	do not use statistics names below models
						label 		/// specifies EVs have label
						drop(_cons *.strata ?.miss* *l*) ///
						noobs
					
						* Bottom panel: TOT
			local regressions `1'_s2 `1'_m2 `1'_l2 
			esttab `regressions' using "rth_`generate'_size_21.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "5-year lags")) ///
						drop(_cons *.strata ?.miss* *l*) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline\hline\hline \\ \multicolumn{16}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 5-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square ( ). Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %					
end		

					
	* apply program to business performance outcomes
rth_size_bus ca_local_dt ca_ttc_dt resultatall_dt profitable resultatall_dt_pct, gen(business)


}


	* trade
{
	* all in one table
capture program drop rth_size_trade
program rth_size_trade
	version 14.2
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
		local conditions "bl_size==1 bl_size==2 bl_size==3"
		local groups "s m l"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
					* ITT: ancova plus stratification dummies
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'l? i.miss_`outcome'_l?  i.strata if `cond' & annee == 2022, cluster(id)
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'l?  i.miss_`outcome'_l?  i.strata (take_up = i.treatment) if `cond' & annee == 2022, cluster(id) first
					estadd local lags "Yes"
					estadd local strata "Yes"
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & annee > 2020 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}

	* Change logic: apply to all variables at a time
tokenize `varlist'

		* Top panel: ITT
		* Put everything into a regression table
		local regressions `1'_s1 `1'_m1 `1'_l1 
		esttab `regressions' using "rth_`generate'_size_21.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on `generate' by firm size} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \begin{tabular}{l*{5}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						mlabels(, depvars) /// use dep vars labels as model title
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						collabels(none) ///	do not use statistics names below models
						label 		/// specifies EVs have label
						drop(_cons *.strata ?.miss* *l*) ///
						noobs
					
						* Bottom panel: TOT
			local regressions `1'_s2 `1'_m2 `1'_l2 
			esttab `regressions' using "rth_`generate'_size_21.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "5-year lags")) ///
						drop(_cons *.strata ?.miss* *l*) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 5-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square ( ). Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %					
end		
			
	
	* apply program to trade outcomes
*rth_size ca_export_dt export_value lprice_exp_w99 import_value lprice_imp_w99, gen(trade)
rth_size_trade ca_export_dt, gen(trade)

}


***********************************************************************
* 	PART 6: Quality Certification heterogeneity
***********************************************************************
	* business
{
	* all in one table
capture program drop rth_cert_bus
program rth_cert_bus
	version 14.2
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "certification_status==1 certification_status==2 certification_status==3"
		local groups "n p c"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
			* ITT: ancova plus stratification dummies
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'l? i.miss_`outcome'_l?  i.strata if `cond' & annee == 2022, cluster(id)
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'l?  i.miss_`outcome'_l?  i.strata (take_up = i.treatment) if `cond' & annee == 2022, cluster(id) first
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & annee > 2020 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}			

	* Change logic: apply to all variables at a time
tokenize `varlist'

		* Put everything into a regression table
				* Top panel: ITT
			local regressions `1'_n1 `1'_p1 `1'_c1 
		esttab `regressions' using "rth_`generate'_cert_21.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on `generate' by prior certification status} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						mlabels(, depvars) /// use dep vars labels as model title
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						collabels(none) ///	do not use statistics names below models
						label 		/// specifies EVs have label
						drop(_cons *.strata ?.miss* *l*) ///
						noobs
					
						* Bottom panel: TOT
			local regressions `1'_n2 `1'_p2 `1'_c2
			esttab `regressions' using "rth_`generate'_cert_21.tex", append ///
		fragment ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "5-year lags")) ///
						drop(_cons *.strata ?.miss* *l*) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 5-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %			

end		

	* apply program to business performance outcomes
rth_cert_bus ca_local_dt ca_ttc_dt resultatall_dt profitable resultatall_dt_pct, gen(business)
	

}

	* trade
{
	* all in one table
capture program drop rth_cert_trade
program rth_cert_trade
	version 14.2
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "certification_status==1 certification_status==2 certification_status==3"
		local groups "n p c"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
			* ITT: ancova plus stratification dummies
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'l? i.miss_`outcome'_l?  i.strata if `cond' & annee == 2022, cluster(id)
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'l?  i.miss_`outcome'_l?  i.strata (take_up = i.treatment) if `cond' & annee == 2022, cluster(id) first
					estadd local lags "Yes"
					estadd local strata "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & annee > 2020 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}			

	* Change logic: apply to all variables at a time
tokenize `varlist'

		* Put everything into a regression table
				* Top panel: ITT
			local regressions `1'_n1 `1'_p1 `1'_c1 
		esttab `regressions' using "rth_`generate'_cert_21.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on `generate' by prior certification status} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						mlabels(, depvars) /// use dep vars labels as model title
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						collabels(none) ///	do not use statistics names below models
						label 		/// specifies EVs have label
						drop(_cons *.strata ?.miss* *l*) ///
						noobs
					
						* Bottom panel: TOT
			local regressions `1'_n2 `1'_p2 `1'_c2
			esttab `regressions' using "rth_`generate'_cert_21.tex", append ///
		fragment ///
						posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
						stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "5-year lags")) ///
						drop(_cons *.strata ?.miss* *l*) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 5-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %			

end		

	
	* apply program to trade outcomes
rth_cert_trade ca_export_dt, gen(trade)

}

	
