***********************************************************************
* 	Main regressions - Adminstrative data
***********************************************************************
*																	   
*	PURPOSE: Run main regression for analysis of the experiment 
*	OUTLINE:														  
*			PART 3: Regression table with 3 vars (sales, import)
*			PART 4: Regression table with 5 vars (profit, costs, employees)
*			PART 5: Regression table with 5 vars (export)
*																
*	Author:  	Florian Muench			         													      
*	ID variable: 	id (example: f101)			  			
*	  Requires: ad_final.dta 	  										  
*	  Creates:  ad_final.dta										  							  
***********************************************************************
* 	PART:  set the stage - technicalities	
***********************************************************************
	* import the data 
use "${final}/cepex_long", clear

	* set panel and sort the observations
encode ndgcf, gen(ID)
order ID, b(ndgcf)
sort ID year, stable
xtset ID year 

	* set graphics output window on
set graphics on
	
***********************************************************************
* 	PART 1: Labeled variables for tables & figures
***********************************************************************
	* label variables
lab var total_revenue_ "Exp. Revenue [Dinar]"
lab var exp_rev_euro "Exp. Revenue [Euro]"
lab var total_qty_ "Exp. Quantity [unit]"
lab var num_combos_ "Country-product pairs"
lab var num_countries_ "Exp. countries"
lab var num_products_ "Exp. products"
*lab var exp_rev_dinar_deflated "Exp. Rev. [Dinar, deflated]"
*lab var exp_rev_euro_deflated "Exp. Rev. [Euro, deflated]"


***********************************************************************
* 	PART 0: Check how many firms got matched/not matched (either no export or wrong legal ID)
***********************************************************************
lab def match 1 "matched" 0 "not matched"
lab val not_matched match

local programs "aqe cf ecom all"
forvalues s = 1(1)4 {
	gettoken p programs : programs
		graph bar (count) if year == 2020 & (treatment`s' == 1 | treatment`s' == 0), ///
			over(not_matched) blabel(total) ///
			ytitle("No of Firms") title("`p'")
		gr export "${fig_`p'}/matchN_`s'.pdf", replace
	}

***********************************************************************
* 	PART 1: Check pre-treatment balance table
***********************************************************************
* BALANCE - PRE TREATMENT BALANCE TABLE 2020 compare treatment vs control for the whole sampple and then each program
	* loop elements
local balancevar "total_revenue_ total_qty_ num_combos_ num_countries_ num_products_"
local fmt "xlsx tex"
local programs "aqe cf ecom all"
	
	* balance table
forvalues s = 1(1)4 {
	gettoken p programs : programs
	foreach f of local fmt {
iebaltab `balancevar' if year == 2020, ///
    grpvar(treatment`s') vce(robust) format(%12.2fc) ///
    rowvarlabels ///
    save`f'("${tab_`p'}/bt_cepex_treat`s'.`f'") replace
	}
}


***********************************************************************
* 	PART 2: Annual density distributions in T vs. C
***********************************************************************
	* look at distribution
			* Treatment vs control
local vars "total_revenue_ num_combos_ num_countries_ num_products_" // total_qty_
local programs "aqe cf ecom all"

forvalues s = 1(1)4 {
 gettoken p programs : programs
	foreach v of local vars {
		forvalues y = 2020(1)2024 {
			graph twoway  (kdensity `v'_w95 if treatment`s' == 1 & year == `y' & `v' > 0, lp(l) lc(maroon) yaxis(2)) ///
						  (kdensity `v'_w95 if treatment`s' == 0 & year == `y' & `v' > 0, lp(l) lc(green) yaxis(2)), ///
						legend(rows(3) symxsize(small) ///
							   order(1 "Treatment group" ///
									 2 "Control group") ///
							   col(1) pos(6) ring(6)) ///
						xtitle("`v'") title("`y'") ///
						xlabel(, angle(45)) ///
						saving(density_`v'`s'_`y', replace)
			gr export "${fig_`p'}/density_`v'`s'_`y'.pdf", replace
		}
	}
}


local vars "total_revenue_ num_combos_ num_countries_ num_products_" // total_qty_
local programs "aqe cf ecom all"
forvalues s = 1(1)4 {
	gettoken p programs : programs
		foreach v of local vars {
			gr combine "density_`v'`s'_2020" "density_`v'`s'_2021" "density_`v'`s'_2022" "density_`v'`s'_2023" "density_`v'`s'_2024", title("`p'")
			gr export "${fig_`p'}/density_`v'`s'_combined.pdf", replace
		}
}


		* Take-up vs. drop-out + control
local vars "total_revenue_ num_combos_ num_countries_ num_products_" // total_qty_
local programs "aqe cf ecom all"

forvalues s = 1(1)4 {
 gettoken p programs : programs
	foreach v of local vars {
		forvalues y = 2020(1)2024 {
			graph twoway  (kdensity `v'_w95 if take_up`s' == 1 & year == `y' & `v' > 0, lp(l) lc(maroon) yaxis(2)) ///
						  (kdensity `v'_w95 if take_up`s' == 0 & year == `y' & `v' > 0, lp(l) lc(green) yaxis(2)), ///
						legend(rows(3) symxsize(small) ///
							   order(1 "Take-up = 1" ///
									 2 "Take-up = 0") ///
							   col(1) pos(6) ring(6)) ///
						xtitle("`v'") title("`y'") ///
						xlabel(, angle(45)) ///
						saving(density_`v'`s'_`y'_tup, replace)
			gr export "${fig_`p'}/density_`v'`s'_`y'_tup.pdf", replace
		}
	}
}


local vars "total_revenue_ num_combos_ num_countries_ num_products_" // total_qty_
local programs "aqe cf ecom all"
forvalues s = 1(1)4 {
	gettoken p programs : programs
		foreach v of local vars {
			gr combine "density_`v'`s'_2020_tup" "density_`v'`s'_2021_tup" "density_`v'`s'_2022_tup" "density_`v'`s'_2023_tup" "density_`v'`s'_2024_tup", title("`p'")
			gr export "${fig_`p'}/density_`v'`s'_combined_tup.pdf", replace
		}
}

	
	* Exported vs. not exported
		* Treatment vs. control
lab def exp 1 "exported" 0 "no export"
lab val exported exp

local programs "aqe cf ecom all"
forvalues s = 1(1)4 {
	gettoken p programs : programs
	forvalues t = 2020(1)2024 {
		graph bar (mean) exported if year == `t', ///
				 over(treatment`s', label(labsize(large))) ///
				 blabel(total, format(%9.2fc) size(large)) ///
				 ytitle("mean of exported in `t'", size(large)) title("`p'")
		gr export "${fig_`p'}/exported_`s'_`t'.pdf", replace
	}
}
	
local programs "aqe cf ecom all"
forvalues s = 1(1)4 {
	gettoken p programs : programs
		foreach v of local vars {
			gr combine "exported_`s'_2020" "exported_`s'_2021" "exported_`s'_2022" "exported_`s'_2023" "exported_`s'_2024", title("`p'")
			gr export "${fig_`p'}/exported_`s'_combined.pdf", replace
		}
}
	

		 
		 
***********************************************************************
* 	PART : Event study analysis
***********************************************************************
{
	
	* shift ttt variable as Stata does not accept negative factors
gen ttt_sh = ttt + 2
	
	* test
reg total_revenue_ i.ttt_sh#ib0.treatment4 i.strata4, cluster(ID)\\

reg total_revenue_ i.treatment4 L1.total_revenue_ i.strata4 if year == 2021, cluster(ID)

reg total_revenue_ i.treatment4 L2.total_revenue_ i.strata4 if year == 2022, cluster(ID)
reg total_revenue_ i.treatment4 L3.total_revenue_ i.strata4 if year == 2023, cluster(ID)
reg total_revenue_ i.treatment4 L4.total_revenue_ i.strata4 if year == 2024, cluster(ID)


reg total_revenue_ i.treatment4 L2.total_revenue__w95 i.strata4 if year == 2022, cluster(ID)
reg total_revenue_ i.treatment4 L3.total_revenue__w95 i.strata4 if year == 2023, cluster(ID)
reg total_revenue_ i.treatment4 L4.total_revenue__w95 i.strata4 if year == 2024, cluster(ID)


	* Cai/Szeidl, Mckenzie/Woodruff FE specification
xtreg total_revenue_ i.treatment4##ib2020.year, fe cluster(ID)
xtreg total_revenue__w95 i.treatment4##ib2020.year, fe cluster(ID)
xtreg ihs_total_revenue__w95 i.treatment4##ib2020.year, fe cluster(ID)

	
capture program drop rcts_event // enables re-running
program rcts_event
	version 15						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
				* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program4 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.ttt#i.treatment i.strata, cluster(ID)
				* for latex table
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata4 (take_up4 = i.treatment4) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			
			* calculate control group mean
			sum `var' if treatment4 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_all}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_all}/cfp_`var'_22_2.pdf", replace	
	}
}	
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
		* sales (3 vars)
rct_admin ca_ttc ca_local ca_export, gen(sales_abs)
rct_admin ihs_ca_ttc_w99 ihs_ca_local_w99 ihs_ca_export_w99, gen(sales_99)
rct_admin ihs_ca_ttc_w95 ihs_ca_local_w95 ihs_ca_export_w95, gen(sales_95)

		* import (3 vars)
rct_admin import_value import_weight price_imp, gen(import_abs)
rct_admin ihs_import_value_w99 ihs_import_weight_w99 lprice_imp_w99, gen(import_99)
rct_admin ihs_import_value_w95 ihs_import_weight_w95 lprice_imp_w95, gen(import_95)
}

	

***********************************************************************
* 	PART 2A: Test regressions
***********************************************************************
{
* Jawhar you can use this to understand what is in the program/loop
/*
* test
	* with lags
reg ca_ttc i.treatment4 L2.ca_ttc i.strata4 if annee == 2022, cluster(ID)
local obs_ca_ttc = e(N)
display `obs_ca_ttc'

ivreg2 ca_ttc L2.ca_ttc i.strata4 (take_up4 = i.treatment4) if annee == 2022, cluster(ID) first
matrix u = e(b)

			eststo ca_ttc1: reg ca_ttc i.treatment4 L2.ca_ttc i.strata4 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_ca_ttc = e(N)
			matrix t = r(table)
			local itt_ca_ttc = t[1,2]
			local fmt_itt_ca_ttc : display %3.2f `itt_ca_ttc'


			* ATT, IV		
			eststo ca_ttc2: ivreg2 ca_ttc L2.ca_ttc i.strata4 (take_up4 = i.treatment4) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_ca_ttc = u[1,1]
			local fmt_att_ca_ttc : display %3.2f `att_ca_ttc'
			
			* calculate control group mean
			sum ca_ttc if treatment4 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_ca_ttc = r(mean)
			local fmt_c_m_ca_ttc : display %3.2f `c_m_ca_ttc'
			
			* calculate percent change
			local ca_ttc_per_itt = (`fmt_itt_ca_ttc' / `fmt_c_m_ca_ttc')*100
			local ca_ttc_per_att = (`fmt_att_ca_ttc' / `fmt_c_m_ca_ttc')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(ca_ttc1, pstyle(p1)) (ca_ttc2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(ca_ttc1 = `"ca_ttc (ITT)"' ca_ttc2 = `"ca_ttc (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_ca_ttc'." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_ca_ttc'.", span size(medium)) ///
		name(ad_ca_ttc_cfp1, replace)
gr export "${fig}/cfp_ca_ttc_22_1.pdf", replace	

		* with percent changes
coefplot ///
(ca_ttc1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(`ca_ttc_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (ca_ttc2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(`ca_ttc_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(ca_ttc1 = `"ca_ttc (ITT)"' ca_ttc2 = `"ca_ttc (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_ca_ttc'." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_ca_ttc'.", span size(medium)) ///
		name(ad_ca_ttc_cfp2, replace)
gr export "${fig}/cfp_ca_ttc_22_2.pdf", replace	
*/
}


***********************************************************************
* 	PART 2A: Sales - all - 3 vars
***********************************************************************
{
capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
				* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program4 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment4 L2.`var' i.strata4 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata4 (take_up4 = i.treatment4) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			
			* calculate control group mean
			sum `var' if treatment4 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_all}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_all}/cfp_`var'_22_2.pdf", replace	
	}
}	
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
		* sales (3 vars)
rct_admin ca_ttc ca_local ca_export, gen(sales_abs)
rct_admin ihs_ca_ttc_w99 ihs_ca_local_w99 ihs_ca_export_w99, gen(sales_99)
rct_admin ihs_ca_ttc_w95 ihs_ca_local_w95 ihs_ca_export_w95, gen(sales_95)

		* import (3 vars)
rct_admin import_value import_weight price_imp, gen(import_abs)
rct_admin ihs_import_value_w99 ihs_import_weight_w99 lprice_imp_w99, gen(import_99)
rct_admin ihs_import_value_w95 ihs_import_weight_w95 lprice_imp_w95, gen(import_95)
}




***********************************************************************
* 	PART 2B: Sales - AQE - 3 vars
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
	
	* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program1 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment1 L2.`var' i.strata1 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata1 (take_up1 = i.treatment1) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment1 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_aqe}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_aqe}/cfp_`var'_22_2.pdf", replace	
}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_aqe}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_aqe}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}

						
end

	* apply program to business performance outcomes
		* sales (3 vars)
rct_admin ca_ttc ca_local ca_export, gen(sales_abs)
rct_admin ihs_ca_ttc_w99 ihs_ca_local_w99 ihs_ca_export_w99, gen(sales_99)
rct_admin ihs_ca_ttc_w95 ihs_ca_local_w95 ihs_ca_export_w95, gen(sales_95)

		* import (3 vars)
rct_admin import_value import_weight price_imp, gen(import_abs)
rct_admin ihs_import_value_w99 ihs_import_weight_w99 lprice_imp_w99, gen(import_99)
rct_admin ihs_import_value_w95 ihs_import_weight_w95 lprice_imp_w95, gen(import_95)


}




***********************************************************************
* 	PART 2C: Sales - CF - 3 vars
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
	* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program2 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment2 L2.`var' i.strata2 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata2 (take_up2 = i.treatment2) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment2 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_cf}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_cf}/cfp_`var'_22_2.pdf", replace	
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_cf}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_cf}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
		* sales (3 vars)
rct_admin ca_ttc ca_local ca_export, gen(sales_abs)
rct_admin ihs_ca_ttc_w99 ihs_ca_local_w99 ihs_ca_export_w99, gen(sales_99)
rct_admin ihs_ca_ttc_w95 ihs_ca_local_w95 ihs_ca_export_w95, gen(sales_95)

		* import (3 vars)
rct_admin import_value import_weight price_imp, gen(import_abs)
rct_admin ihs_import_value_w99 ihs_import_weight_w99 lprice_imp_w99, gen(import_99)
rct_admin ihs_import_value_w95 ihs_import_weight_w95 lprice_imp_w95, gen(import_95)

}








***********************************************************************
* 	PART 2D: Sales - Ecom - 3 vars
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	
		* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program3 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
		
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment3 L2.`var' i.strata3 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata3 (take_up3 = i.treatment3) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment3 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_ecom}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_ecom}/cfp_`var'_22_2.pdf", replace	
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_ecom}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_ecom}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
		* sales (3 vars)
rct_admin ca_ttc ca_local ca_export, gen(sales_abs)
rct_admin ihs_ca_ttc_w99 ihs_ca_local_w99 ihs_ca_export_w99, gen(sales_99)
rct_admin ihs_ca_ttc_w95 ihs_ca_local_w95 ihs_ca_export_w95, gen(sales_95)

		* import (3 vars)
rct_admin import_value import_weight price_imp, gen(import_abs)
rct_admin ihs_import_value_w99 ihs_import_weight_w99 lprice_imp_w99, gen(import_99)
rct_admin ihs_import_value_w95 ihs_import_weight_w95 lprice_imp_w95, gen(import_95)


}









***********************************************************************
* 	PART 3A: profit, costs, employees (5 vars) - all
***********************************************************************
{
capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
				* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program4 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
		
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment4 L2.`var' i.strata4 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata4 (take_up4 = i.treatment4) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment4 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_all}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_all}/cfp_`var'_22_2.pdf", replace	
	}
}	
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `4'2 `5'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
		* sales (3 vars)
rct_admin profit profitable employees cost wages, gen(profit_abs)
rct_admin ihs_profit_w99 profitable ihs_employees_w99 ihs_cost_w99 ihs_wages_w99, gen(profit_99)
rct_admin ihs_profit_w95 profitable ihs_employees_w95 ihs_cost_w95 ihs_wages_w95, gen(profit_95)

rct_admin exported ca_export export_value export_weight price_exp, gen(exp_abs)
rct_admin exported ihs_ca_export_w99 ihs_export_value_w99 ihs_export_weight_w99 lprice_exp_w99, gen(exp_99)
rct_admin exported ihs_ca_export_w95 ihs_export_value_w95 ihs_export_weight_w95 lprice_exp_w95, gen(exp_95)


}









***********************************************************************
* 	PART 3B: profit, costs, employees (5 vars) - AQE
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
				* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program1 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment1 L2.`var' i.strata1 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata1 (take_up1 = i.treatment1) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment1 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_aqe}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_aqe}/cfp_`var'_22_2.pdf", replace	
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_aqe}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `4'2 `5'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_aqe}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
rct_admin profit profitable employees cost wages, gen(profit_abs)
rct_admin ihs_profit_w99 profitable ihs_employees_w99 ihs_cost_w99 ihs_wages_w99, gen(profit_99)
rct_admin ihs_profit_w95 profitable ihs_employees_w95 ihs_cost_w95 ihs_wages_w95, gen(profit_95)


}




***********************************************************************
* 	PART 3C: profit, costs, employees (5 vars) - CF
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
		* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program2 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment2 L2.`var' i.strata2 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata2 (take_up2 = i.treatment2) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment2 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_cf}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_cf}/cfp_`var'_22_2.pdf", replace
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_cf}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `4'2 `5'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_cf}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
		* sales (3 vars)
rct_admin profit profitable employees cost wages, gen(profit_abs)
rct_admin ihs_profit_w99 profitable ihs_employees_w99 ihs_cost_w99 ihs_wages_w99, gen(profit_99)
rct_admin ihs_profit_w95 profitable ihs_employees_w95 ihs_cost_w95 ihs_wages_w95, gen(profit_95)

rct_admin exported ca_export export_value export_weight price_exp, gen(exp_abs)
rct_admin exported ihs_ca_export_w99 ihs_export_value_w99 ihs_export_weight_w99 lprice_exp_w99, gen(exp_99)
rct_admin exported ihs_ca_export_w95 ihs_export_value_w95 ihs_export_weight_w95 lprice_exp_w95, gen(exp_95)



}






***********************************************************************
* 	PART 3D: profit, costs, employees (5 vars) - Ecom
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
						* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program3 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment3 L2.`var' i.strata3 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L2.`var' i.strata3 (take_up3 = i.treatment3) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment3 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_ecom}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_ecom}/cfp_`var'_22_2.pdf", replace	
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_ecom}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `4'2 `5'2   // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_ecom}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to business performance outcomes
rct_admin profit profitable employees cost wages, gen(profit_abs)
rct_admin ihs_profit_w99 profitable ihs_employees_w99 ihs_cost_w99 ihs_wages_w99, gen(profit_99)
rct_admin ihs_profit_w95 profitable ihs_employees_w95 ihs_cost_w95 ihs_wages_w95, gen(profit_95)


}












***********************************************************************
* 	PART 4A: export (5 vars) - all
***********************************************************************
{
capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
						* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program4 == 1
		local obs_tot = r(N)
		if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment4 L1.`var' i.strata4 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L1.`var' i.strata4 (take_up4 = i.treatment4) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment4 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_all}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_all}/cfp_`var'_22_2.pdf", replace
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2  // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_all}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to trade outcomes
		* export (4 vars)
rct_admin exported ca_export export_value export_weight price_exp, gen(exp_abs)
rct_admin exported ihs_ca_export_w99 ihs_export_value_w99 ihs_export_weight_w99 lprice_exp_w99, gen(exp_99)
rct_admin exported ihs_ca_export_w95 ihs_export_value_w95 ihs_export_weight_w95 lprice_exp_w95, gen(exp_95)

}











***********************************************************************
* 	PART 4B: export (5 vars) - AQE
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
						* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program1 == 1
		local obs_tot = r(N)
if `obs_tot' > 30 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment1 L1.`var' i.strata1 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L1.`var' i.strata1 (take_up1 = i.treatment1) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment1 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_aqe}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_aqe}/cfp_`var'_22_2.pdf", replace	
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'2 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_aqe}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_aqe}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to trade outcomes
		* export (5 vars)
rct_admin exported ca_export export_value export_weight price_exp, gen(exp_abs)
rct_admin exported ihs_ca_export_w99 ihs_export_value_w99 ihs_export_weight_w99 lprice_exp_w99, gen(exp_99)
rct_admin exported ihs_ca_export_w95 ihs_export_value_w95 ihs_export_weight_w95 lprice_exp_w95, gen(exp_95)


}









***********************************************************************
* 	PART 4C: export (5 vars) - CF
***********************************************************************

{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
						* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program2 == 1
		local obs_tot = r(N)
		if `obs_tot' > 50 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment2 L1.`var' i.strata2 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L1.`var' i.strata2 (take_up2 = i.treatment2) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment2 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_cf}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_cf}/cfp_`var'_22_2.pdf", replace
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_cf}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2  `5'2 // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_cf}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to trade outcomes
		* export (4 vars)
rct_admin exported ca_export export_value export_weight price_exp, gen(exp_abs)
rct_admin exported ihs_ca_export_w99 ihs_export_value_w99 ihs_export_weight_w99 lprice_exp_w99, gen(exp_99)
rct_admin exported ihs_ca_export_w95 ihs_export_value_w95 ihs_export_weight_w95 lprice_exp_w95, gen(exp_95)


}












***********************************************************************
* 	PART 4D: export(5 vars) - Ecom
***********************************************************************
{

capture program drop rct_admin // enables re-running
program rct_admin
	version 14.2						// define Stata version 14.2 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
						* make sure enough obs to technically run regression
		count if `var' != . & annee == 2022 & program3 == 1
		local obs_tot = r(N)
		if `obs_tot' > 50 {
* ITT: ancova plus stratification dummies						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment3 L1.`var' i.strata3 if annee == 2022, cluster(ID)
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			local obs_`var' = e(N)
			matrix t = r(table)
			local itt_`var' = t[1,2]
			local fmt_itt_`var' : display %3.2f `itt_`var''


			* ATT, IV		
			eststo `var'2: ivreg2 `var' L1.`var' i.strata3 (take_up3 = i.treatment3) if annee == 2022, cluster(ID) first
				* for latex table
			estadd local lags "Yes"
			estadd local strata "Yes"
				* for coefplot
			matrix u = e(b)
			local att_`var' = u[1,1]
			local fmt_att_`var' : display %3.2f `att_`var''
			
			* calculate control group mean
			sum `var' if treatment3 == 0 & annee == 2022 
				* for latex table
			estadd scalar control_mean = r(mean)
			estadd scalar control_sd = r(sd)
				* for coefplot
			local c_m_`var' = r(mean)
			local fmt_c_m_`var' : display %3.2f `c_m_`var''
			
			* calculate percent change
			local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100
			local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
			
			* number of obs
			

	* coefplot
		* "nature"
coefplot ///
(`var'1, pstyle(p1)) (`var'2, pstyle(p2)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp1, replace)
gr export "${fig_ecom}/cfp_`var'_22_1.pdf", replace	

		* with percent changes
coefplot ///
(`var'1, pstyle(p1) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
 (`var'2, pstyle(p2) ///
 mlabel(string(@b, "%9.2f") + " equivalent to " + string(``var'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "9.2f") + ")") ///
 mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment* take_up*) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`var'1 = `"`var' (ITT)"' `var'2 = `"`var' (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf: Note}:" "The control group EL mean is `fmt_c_m_`var''." "Confidence intervals are at the 95 percent level." "Number of observation is `obs_`var''.", span size(medium)) ///
		name(ad_`var'_cfp2, replace)
gr export "${fig_ecom}/cfp_`var'_22_2.pdf", replace	
	}
}		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'
{
				* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'2 `2'2 `3'2 `4'1 `5'1 // `4'1 `5'1 adjust manually to number of variables 
		esttab `regressions' using "${tab_ecom}/rt_`generate'_22.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on `generate' performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata* *l*) ///
				noobs
				
			* Bottom panel: TOT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // `4'2 `5'2  adjust manually to number of variables 
		esttab `regressions' using "${tab_ecom}/rt_`generate'_22.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) ci(fmt(2)) rw) ///
				stats(control_mean control_sd N strata lags, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "3-year lags")) ///
				drop(_cons *.strata* *l*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, the lagged outcome in the previous 3-years, and a missing lag dummy. Employee and sales variables are winsorized at the 99 percentile, IHS-transformed with units-scaled for optimal R-square. Export and import prices are winsorized and log-transformed. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}						
end

	* apply program to trade outcomes
		* export (4 vars)
rct_admin exported ca_export export_value export_weight price_exp, gen(exp_abs)
rct_admin exported ihs_ca_export_w99 ihs_export_value_w99 ihs_export_weight_w99 lprice_exp_w99, gen(exp_99)
rct_admin exported ihs_ca_export_w95 ihs_export_value_w95 ihs_export_weight_w95 lprice_exp_w95, gen(exp_95)


}










***********************************************************************
* 	END
***********************************************************************
* close log file
log close






***********************************************************************
* 	PART: ARCHIVE
***********************************************************************
***********************************************************************
* 	PART 1:  rename transformed variables for simpler loopping	
***********************************************************************
{
/*
	* rename variables absolute values as varname_temp
local absolute_values ca_export ca_local resultatall import_value ca_ttc export_value price_exp price_imp
foreach var of local absolute_values {
		rename `var' `var'_temp
}

	* rename transformed variables to original variable names
		* ! requires selecting optimal unit k for transformation of continuous outcomes
		
			* ca_export
rename ihs_ca_export_wk6 ca_export

			* ca_local
rename ihs_ca_local_wk6 ca_local

			* resultatal~t
rename ihs_resultatall_wk6 resultatall		// ihs_resultatal~t_w98

			* ca_ttc
rename ihs_ca_ttc_wk6 ca_ttc

			* ex-/import amount
rename ihs_export_value_wk6 export_value
rename ihs_import_value_wk6 import_value

			* export/import price
rename lprice_exp_w99 price_exp
rename lprice_imp_w99 price_imp

		* for regression tables shorten take-up2 name
rename take_up_sum2 take_up2
		
*/
}


***********************************************************************
* 	PART 2:  create lagged values 
***********************************************************************
*local kpi_table ca_local ca_ttc profitable resultatall resultatall_pct
*local trade_table ca_export export_value price_exp import_value price_imp

local kpi_table ca_local ca_ttc resultatall profitable resultatall_pct
local trade_table ca_export export_value price_exp import_value price_imp
 

foreach var of varlist `kpi_table' `trade_table' {
	
	forvalues x = 1(1)5 	{	// for 5-pre treatment years
		* generate lags
	gen `var'l`x' = l`x'.`var'
	lab var `var'l`x' "`var' lag-`x'"
		
		* generate missing lag
	gen miss_`var'_l`x' = (`var'l`x' == .)										// gen dummy for baseline
	lab var miss_`var'_l`x' "`var' lag-`x' missing"
	}
}

