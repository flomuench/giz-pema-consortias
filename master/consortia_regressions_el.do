***********************************************************************
* 			Master endline analysis/regressions				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake treatment effect analysis of
*				outcomes
*
*													
*																	  
*	Authors:  	Florian Muench, Ayoub Chamakhi
*	ID variable: id_platforme		  					  
*	Requires:  	consortium_final.dta
*	Creates:	reg graphs

***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************
{
use "${master_final}/consortium_final", clear

/*	* export dta file for Michael Anderson
preserve
keep id_plateforme surveyround treatment take_up *net_size *net_nb_f *net_nb_m *net_nb_qualite *net_coop_pos strata_final
save "${master_final}/sample.dta", replace
restore
*/

* export dta file for Damian Clarke
/*
preserve
keep id_plateforme surveyround treatment take_up *genderi *female_efficacy *female_loc strata_final
save "${master_final}/sample_clarke.dta", replace
restore
*/	
		* change directory
cd "${master_regressiontables}/endline/regressions"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on

		* set color scheme
if "`c(username)'" == "MUNCHFA" | "`c(username)'" == "fmuench"  {
	set scheme stcolor
} 
	else {

set scheme s1color
		
	}
}
	
	
twoway scatter ihs_ca_w95_k1 ca_rel_growth_w95 if surveyround == 3 & ihs_ca_w95_k1 > 0, colorvar(treatment)

twoway scatter ihs_ca_w95_k1 ca_rel_growth_w95 if surveyround == 3 & ihs_ca_w95_k1 > 0 & ca_rel_growth_w95 <= 5, colorvar(treatment)
	
	
***********************************************************************
* 	Part 0.1: create a program to estimate sharpened q-values
***********************************************************************
{
	* source 1:
	* source 2:
capture program drop qvalues
program qvalues 
	* settings
		version 16
		syntax varlist(max=1 numeric) // where varlist is a variable containing all the pvalues
	* code
		* Collect the total number of p-values tested
			quietly sum `varlist'
			local totalpvals = r(N)

		* Sort the p-values in ascending order and generate a variable that codes each p-value's rank
			quietly gen int original_sorting_order = _n
			quietly sort `varlist'
			quietly gen int rank = _n if `varlist'~=.

		* Set the initial counter to 1 
			local qval = 1

		* Generate the variable that will contain the BKY (2006) sharpened q-values
			gen bky06_qval = 1 if `varlist'~=.

		* Set up a loop that begins by checking which hypotheses are rejected at q = 1.000, then checks which hypotheses are rejected at q = 0.999, then checks which hypotheses are rejected at q = 0.998, etc.  The loop ends by checking which hypotheses are rejected at q = 0.001.
			while `qval' > 0 {
			* First Stage
			* Generate the adjusted first stage q level we are testing: q' = q/1+q
				local qval_adj = `qval'/(1+`qval')
			* Generate value q'*r/M
				gen fdr_temp1 = `qval_adj'*rank/`totalpvals'
			* Generate binary variable checking condition p(r) <= q'*r/M
				gen reject_temp1 = (fdr_temp1>=`varlist') if `varlist'~=.
			* Generate variable containing p-value ranks for all p-values that meet above condition
				gen reject_rank1 = reject_temp1*rank
			* Record the rank of the largest p-value that meets above condition
				egen total_rejected1 = max(reject_rank1)

			* Second Stage
			* Generate the second stage q level that accounts for hypotheses rejected in first stage: q_2st = q'*(M/m0)
				local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-total_rejected1[1]))
			* Generate value q_2st*r/M
				gen fdr_temp2 = `qval_2st'*rank/`totalpvals'
			* Generate binary variable checking condition p(r) <= q_2st*r/M
				gen reject_temp2 = (fdr_temp2>=`varlist') if `varlist'~=.
			* Generate variable containing p-value ranks for all p-values that meet above condition
				gen reject_rank2 = reject_temp2*rank
			* Record the rank of the largest p-value that meets above condition
				egen total_rejected2 = max(reject_rank2)

			* A p-value has been rejected at level q if its rank is less than or equal to the rank of the max p-value that meets the above condition
				replace bky06_qval = `qval' if rank <= total_rejected2 & rank~=.
			* Reduce q by 0.001 and repeat loop
				drop fdr_temp* reject_temp* reject_rank* total_rejected*
				local qval = `qval' - .001
			}
			

		quietly sort original_sorting_order
		display "Code has completed."
		display "Benjamini Krieger Yekutieli (2006) sharpened q-vals are in variable 'bky06_qval'"
		display	"Sorting order is the same as the original vector of p-values"
	
	end  

}

***********************************************************************
* 	PART 1: test for differential survey attrition 		
***********************************************************************
* Is there differential attrition between treatment and control group?
{
		* column (1): at endline
eststo att1, r: areg refus i.treatment if surveyround == 3, absorb(strata_final) cluster(consortia_cluster)
estadd local strata_final "Yes"
		
		* column (2): at midline
eststo att2, r: areg refus i.treatment if surveyround == 2, absorb(strata_final) cluster(consortia_cluster)
estadd local strata_final "Yes"

		* column (3): at baseline
eststo att3, r: areg refus i.treatment if surveyround == 1, absorb(strata_final) cluster(consortia_cluster)
estadd local strata_final "Yes"

local attrition att1 att2 att3
esttab `attrition' using "el_attrition.tex", replace ///
	title("Attrition: Total") ///
	mtitles("EL" "ML" "BL") ///
	label ///
	b(3) ///
	se(3) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata_final strata_final controls") ///
	addnotes("All standard errors are Hubert-White robust standord errors clustered at the firm level for the control and at the consortia level for the treatment group.")
		
}

* Does pre-balance btw T & C still hold? Do attriters differ from non-attriters before treatment?
		* define list of pre-treatment characteristics
gen temp_el_refus = refus if surveyround == 3
egen el_refus = min(temp_el_refus), by(id_plateforme) missing
drop temp_el_refus
local kpis "age ihs_profit_w95_k1 ihs_ca_w95_k1 employes_w95"
local exp "operation_export exp_pays_w95 ihs_ca_exp2018_w95_k1" // 
local management "mpi_points"
local network "net_size net_coop_pos net_coop_neg"
local confidence "female_efficacy_points female_loc_points"
local vars "`kpis' `exp' `management' `network' `confidence'"
local cond1 "surveyround == 1"
local cond2 "surveyround == 1 & id_plateforme != 1092"

iebaltab `vars'  if `cond1', ///
	grpvar(el_refus) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_attrition_yesvsno_bl) replace
	
iebaltab `vars'  if `cond2', ///
	grpvar(el_refus) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_attrition_yesvsno_bl_no1092) replace
	
/*
suggests that
	1: attriters had higher pre-sales than non-attriters
	2: attriters are more likely to have pre-treatment export experience
*/
	
	
* Do attriters in the control group differ from attriters in the treatment group before treatment?
local kpis "age ihs_profit_w95_k1 ihs_ca_w95_k1 employes_w95"
local exp "operation_export exp_pays_w95 ihs_ca_exp2018_w95_k1" // 
local management "mpi_points"
local network "net_size net_coop_pos net_coop_neg"
local confidence "female_efficacy_points female_loc_points"
local vars "`kpis' `exp' `management' `network' `confidence'"
local cond1 "surveyround == 1 & el_refus == 1"
local cond2 "surveyround == 1 & id_plateforme != 1092 & el_refus == 1"

iebaltab `vars'  if `cond1', ///
	grpvar(treatment) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_attrition_TvsC_bl) replace
	
iebaltab `vars'  if `cond2', ///
	grpvar(treatment) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_attrition_TvsC_bl_no1092) replace
	
/*
suggests that
	1: attriters in T had higher pre-sales than in C 
	2: attriters in T had higher pre-treatment export experience
*/


* Lee/Behaghel bounds: Prepare data
tabstat refus if surveyround == 3, by(treatment) statistics(mean) save
return list
display "Treatment response rate is: " 1 - r(Stat2)[1,1] // 0.77 (67 out of 87 firms)
display "Control response rate is: " 1 - r(Stat1)[1,1] 	 // 0.67 (60 out of 89 firms)

	* Find out at what call 67% of treated firms had responded 
preserve
			* keep only respondents and endline data
keep if refus == 0 & surveyround == 3
			* collapse  to have respondents for each nth call in T and C
collapse (count) id_plateforme, by(calls treatment)
drop if calls == . // one obs in T & C who categorically refused after midline
rename id_plateforme firms

			* generate
				* proportion of respondents for each nth call in T and C
gen proportion = firms/87 if treatment == 1
replace proportion = firms/89 if treatment == 0
				* generate cumulative distribution
bys treatment (calls): gen cum = sum(proportion) 

			* Visualise as Behaghel et al. 2015
sum cum if treatment == 0
local response_rate_c = r(max)
twoway ///
	(line cum calls if treatment == 1, lcolor(maroon))  ///
	(line cum calls if treatment == 0, lcolor(red)), ///
		yline(`response_rate_c') ///
		xline(15) ///
		ylabel(0(.1)1) ytitle("Cum. Response Rate") ///
		xlabel(0(5)30) xtitle("Calls") ///
		legend(pos(6) rows(2) order(1 "Treatment" 2 "Control"))
graph export "${figures_attrition}/behaghel_graph.pdf"	
	
	 * Calculate percentage of treatment group observations to be trimmed
sum cum if calls == 15 & treatment == 1
local response_rate_t = r(mean)
display `response_rate_t'

sum cum if treatment == 0
local response_rate_c = r(max)
display `response_rate_c'

display `response_rate_t' - `response_rate_c' // 0.00374532
local trim_perc = (`response_rate_t' - `response_rate_c')/`response_rate_t'
display "Percentage of observations in T to be trimmed off: " `trim_perc' // .00561798

restore

* generate group-variable for C (all) + T (within 15 calls)
gen bh_sample_temp = 0 if surveyround == 3
	replace bh_sample_temp = 1 if treatment == 0 & refus == 0 & surveyround == 3 				// 60 firms
	replace bh_sample_temp = 1 if treatment == 1 & refus == 0 & surveyround == 3 & calls <= 15 	// 58 firms
egen bh_sample = min(bh_sample_temp), by(id_plateforme)

* check if there is balance between Behaghel trimmed T and controls
local kpis "age ihs_profit_w95_k1 ihs_ca_w95_k1 employes_w95"
local exp "operation_export exp_pays_w95 ihs_ca_exp2018_w95_k1" // 
local management "mpi_points"
local network "net_size net_coop_pos net_coop_neg"
local confidence "female_efficacy_points female_loc_points"
local vars "`kpis' `exp' `management' `network' `confidence'"
local cond "surveyround == 1 & bh_sample == 1" // Gourmandise 1092 not included as categorical refusal at ML, no EL call

iebaltab `vars'  if `cond', ///
	grpvar(treatment) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_attrition_TvsC_bl_bhsample) replace
	
***********************************************************************
* 	PART 2: balance table of baseline characteristics	
***********************************************************************
{

* gen dummy for whether firm joined consortium or not
 egen el_take_up = min(take_up), by(id_plateforme) missing
	
* define list of pre-treatment characteristics
local kpis "age ihs_profit_w95_k1 ihs_ca_w95_k1 employes_w95"
local exp "operation_export exp_pays_w95 ihs_ca_exp2018_w95_k1"
local management "mpi_points"
local network "net_size net_coop_pos net_coop_neg"
local confidence "female_efficacy_points female_loc_points"
local vars "`kpis' `exp' `management' `network' `confidence'"
local cond "surveyround == 1 & id_plateforme != 1092 & treatment == 1"

br id_plateforme pole el_take_up `vars' if el_take_up == 1 & treatment == 1 & surveyround == 1

*take_up
	*without outlier
		* Take-up vs. Drop out across all consortia
iebaltab `vars'  if `cond', ///
	grpvar(el_take_up) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_el_tu_all_adj) replace
	
		* Take-up vs. Drop out across all but Digital consortium
iebaltab `vars'  if `cond' & inlist(pole, 1,2,3), ///
	grpvar(el_take_up) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_el_tu_nodig_adj) replace
	
		* Take-up vs. Drop out across all but Digital consortium
iebaltab `vars'  if `cond' & inlist(pole, 4), ///
	grpvar(el_take_up) ///
	rowvarlabels format(%15.2fc) vce(robust) ///
	ftest fmissok ///
	save(baltab_el_tu_dig_adj) replace


iebaltab ca ca_exp profit employes mpi net_coop_pos net_coop_neg net_size exp_pays  if surveyround == 1 & id_plateforme != 1092 & inlist(pole, 1,2,3) & treatment == 1, grpvar(el_take_up) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok save(el_take_up_baltab_adj_aut) replace

iebaltab ca ca_exp profit employes mpi net_coop_pos net_coop_neg net_size exp_pays  if surveyround == 1 & id_plateforme != 1092 & inlist(pole, 4) & treatment == 1, grpvar(el_take_up) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok save(el_take_up_baltab_adj_dig) replace

	*with outlier
iebaltab ca ca_exp  profit employes mpi  net_coop_pos net_coop_neg net_size exp_pays  if surveyround == 1 & id_plateforme == 1092, grpvar(take_up) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok savetex(el_take_up_baltab_unadj) replace



*treatment
*without outlier
iebaltab ca ca_exp  profit employes mpi net_coop_pos net_coop_neg net_size exp_pays  if surveyround == 1 & id_plateforme != 1092, grpvar(treatment) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok save(el_treat_baltab_adj) replace

*with outlier
iebaltab ca ca_exp  profit employes mpi net_coop_pos net_coop_neg net_size exp_pays  if surveyround == 1 & id_plateforme != 1092, grpvar(treatment) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok savetex(el_treat_baltab_unadj) replace

}


***********************************************************************
* 	PART 3: operated/closed		
***********************************************************************
{
capture program drop rct_regression_close // enables re-running the program
program rct_regression_close
	version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
	
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)

		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
*/
		
	* Put all regressions into one table
		* Top panel: ATE
		local regressions `1'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Indexes} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
				
				* Bottom panel: ITT
		local regressions `1'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `2' `3'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. The only exception are columns 2 and 3 for which we did not collect baseline data. The number of observations for network quality is only 123 as all other 18 firms reported zero contacts with other entrepreneurs. The total of female, male and all other CEOs met are winsorized at the 99th percentile. Coefficients display absolute values of the outcomes. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
		keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Closed (ITT)"' `1'2 = `"Closed (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace
			
end

	* apply program to network outcomes
rct_regression_close closed, gen(closed)
}

***********************************************************************
* 	PART 4: list experiment regression
***********************************************************************
{
	* ITT, ancova	
			* baseline differences amount
eststo lexp1, r: reg listexp i.list_group i.strata_final if surveyround == 1, cluster(consortia_cluster)
estadd local strata_final "Yes"

		
			* midline ancova with stratification dummies 
eststo lexp2, r: reg listexp i.treatment##i.list_group l.listexp i.strata_final missing_bl_listexp if surveyround == 2, cluster(consortia_cluster) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata_final "Yes"		

			* endline ancova with stratification dummies 
eststo lexp3, r: reg listexp i.treatment##i.list_group_el l.listexp i.strata_final missing_bl_listexp if surveyround == 3, cluster(consortia_cluster) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata_final "Yes"	

esttab lexp1 lexp2 lexp3 using "el_listexp1.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{List experiment: Independent entrepreneurial decision-making} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(N strata_final bl_control, fmt(%9.0fc) labels("Observations" "strata_final controls" "Y0 controls")) ///
				mtitles("Baseline" "Midline" "Endline") ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final missing* L.*) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{10}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Column (1) presents baseline results with strata_final controls." "Column (2) presents an ANCOVA specification with strata_final controls." "Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}

***********************************************************************
* 	PART 5: Endline results - regression table indexes
***********************************************************************
{
	
capture program drop rct_regression_indexes
program rct_regression_indexes
    version 16
    syntax varlist(min=1 numeric), GENerate(string)
    
    foreach var in `varlist' {
        capture confirm variable `var'_y0
        if _rc == 0 {
            // ITT: ANCOVA plus stratification dummies
            eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
            estadd local bl_control "Yes"
            estadd local strata_final "Yes"

            // ATT, IV
            eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
            estadd local bl_control "Yes"
            estadd local strata_final "Yes"
            
            // Calculate control group mean
            sum `var' if treatment == 0 & surveyround == 3
            estadd scalar control_mean = r(mean)
            estadd scalar control_sd = r(sd)
        }
        else {
            // ITT: ANCOVA plus stratification dummies
            eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
            estadd local bl_control "No"
            estadd local strata_final "Yes"

            // ATT, IV
            eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
            estadd local bl_control "No"
            estadd local strata_final "Yes"
            
            // Calculate control group mean
            sum `var' if treatment == 0 & surveyround == 3
            estadd scalar control_mean = r(mean)
            estadd scalar control_sd = r(sd)
        }
    }

	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)

		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
*/
		
	* Put all regressions into one table
		* Top panel: ATE
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1 `11'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Indexes} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 `11'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `2' `3'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. The only exception are columns 2 and 3 for which we did not collect baseline data. The number of observations for network quality is only 123 as all other 18 firms reported zero contacts with other entrepreneurs. The total of female, male and all other CEOs met are winsorized at the 99th percentile. Coefficients display absolute values of the outcomes. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)) ///
	(`8'1, pstyle(p8)) (`8'2, pstyle(p8)) ///
	(`9'1, pstyle(p9)) (`9'2, pstyle(p9)) ///
	(`10'1, pstyle(p10)) (`10'2, pstyle(p10)) ///
	(`11'1, pstyle(p11)) (`11'2, pstyle(p11)), ///
		keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Network (ITT)"' `1'2 = `"Network (TOT)"' `2'1 = `"Export readiness (ITT)"' `2'2 = `"Export readiness (TOT)"' `3'1 = `"Export readiness SSA (ITT)"' `3'2 = `"Export readiness SSA (TOT)"' `4'1 = `"Export performance (ITT)"' `4'2 = `"Export performance (TOT)"' `5'1 = `"Management practices (ITT)"' `5'2 = `"Management practices (TOT)"' `6'1 = `"Efficacy (ITT)"' `6'2 = `"Efficacy (TOT)"' `7'1 = `"Locus (ITT)"' `7'2 = `"Locus (TOT)"' `8'1 = `"Entrepreneurial empowerment (ITT)"' `8'2 = `"Entrepreneurial empowerment (TOT)"' `9'1 = `"Innovation practices (ITT)"' `9'2 = `"Innovation practices (TOT)"' `10'1 = `"Business performance 2023 (ITT)"' `10'2 = `"Business performance 2023 (TOT)"' `11'1 = `"Business performance 2024 (ITT)"' `11'2 = `"Business performance 2024 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace
			
end

	* apply program to network outcomes
rct_regression_indexes network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024, gen(indexes)

}

***********************************************************************
* 	PART 6: endline results - check consistency reg & reghfde - regression network outcomes
***********************************************************************
/*
* variables:
	* net_association net_size3_w95 net_size3_m_w95 net_gender3_w95 net_size4_w95 net_size4_m_w95 net_gender4_w95 net_coop_pos net_coop_neg

* 1: ANCOVA
	* "reg" one way clustered SE (firm)
reg net_association i.treatment net_association_y0 i.missing_bl_net_association i.strata_final if surveyround == 3, cluster(consortia_cluster)
	* "reghfde" one way clustered SE (firm)
reghdfe net_association i.treatment net_association_y0 i.missing_bl_net_association i.strata_final if surveyround == 3, vce(cluster id_plateforme)
	* twoway clustered
reghdfe net_association i.treatment net_association_y0 i.missing_bl_net_association i.strata_final if surveyround == 3, vce(cluster id_plateforme consortia_cluster)
reghdfe net_association i.treatment net_association_y0 i.missing_bl_net_association i.strata_final if surveyround == 3, vce(cluster consortia_cluster1)

/*	
			Coefficient  std. err.      t    P>|t|     [95% conf. interval]
reg		 = .9857697   .2939672     3.35   0.001      .403583    1.567956
reghfde	 = .9857697   .2939672     3.35   0.001      .401478    1.570061
	
*/	
* 2: 2SLS
	* ivreg2
ivreg2 net_association net_association_y0 i.missing_bl_net_association i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
	* reghdfe
reghdfe net_association i.strata_final (take_up = treatment) if surveyround == 3, absorb(net_association_y0 i.missing_bl_net_association) vce(cluster id_plateforme)


* 3: two way clustered SE (firm, consortium)
*/

***********************************************************************
* 	PART 7: endline results - regression network outcomes
***********************************************************************
* useful reference for adjusting coefplots: https://www.statalist.org/forums/forum/general-stata-discussion/general/1713248-coefplot-add-a-line-break-to-coefficient-labels
{	
*** Prep	
* change directory
cd "${master_regressiontables}/endline/regressions/network"	
**** label variables for table
lab var net_size_w95 "All persons"
lab var net_size3_w95 "CEOs"
lab var net_size3_m_w95 "Male CEOs"
lab var net_gender3_w95 "Female CEOs"
lab var net_size4_w95 "Friends/Family"
lab var net_size4_m_w95 "Male Friends/Family"
lab var net_gender4_w95 "Female Friends/Family"

**** TABLES & Figures FOR PAPER ****
* Network size and composition
	* Only endline
{
capture program drop rct_regression_network_paper // enables re-running
program rct_regression_network_paper
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
    foreach var in `varlist' {
        capture confirm variable `var'_y0
        if _rc == 0 {
			// ITT: ANCOVA plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes" : `var'1
			estadd local strata_final "Yes" : `var'1

			// ATT, IV
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes" : `var'2
			estadd local strata_final "Yes" : `var'2

			// Calculate control group mean
			sum `var' if treatment == 0 & surveyround == 3
			estadd scalar control_mean = r(mean) : `var'2
			estadd scalar control_sd = r(sd) : `var'2

        }
        else {
            // ITT: ANCOVA plus stratification dummies
            eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
            estadd local bl_control "No" : `var'1
            estadd local strata_final "Yes" : `var'1

            // ATT, IV
            eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
            estadd local bl_control "No" : `var'2
            estadd local strata_final "Yes" : `var'2
            
            // Calculate control group mean
            sum `var' if treatment == 0 & surveyround == 3
            estadd scalar control_mean = r(mean) : `var'2
            estadd scalar control_sd = r(sd) : `var'2
        }
    }
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 // `10'1  adjust manually to number of variables 
		esttab `regressions' using "${tables_network}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Networks: Size and Composition} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.5cm} >{\centering\arraybackslash}m{1.5cm}} \toprule") ///
				posthead("\toprule \\ \multicolumn{8}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(1)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels("All persons"  "CEOs" "Male CEOs" "Female CEOs"  "\shortstack{Friend/\\Family}" "\shortstack{Male Friend/\\Family}" "\shortstack{Female\\ Friend/Family}") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  `4'2 `5'2 `6'2 `7'2 // `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 adjust manually to number of variables 
		esttab `regressions' using "${tables_network}/rt_`generate'.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{8}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(1)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{8}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: The outcome is the number of people with whom the female entrepreneurs discuss business regularly in the past three months. All variables are winsorised at the $95^{th}$ percentile as pre-specified. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable when available. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}")
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
/*						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Any (ITT)"' `1'2 = `"Any (TOT)"' `2'1 = `"Entrepreneurs (ITT)"' `2'2 = `"Entrepreneurs (TOT)"' `3'1 = `"Male Entrepreneurs (ITT)"' `3'2 = `"Male Entrepreneurs (TOT)"' `4'1 = `"Female Entrepreneurs (ITT)"' `4'2 = `"Female Entrepreneurs (TOT)"' `5'1 = `"Family/Friends (ITT)"' `5'2 = `"Family/Friends (TOT)"' `6'1 = `"Male Family/Friends (ITT)"' `6'2 = `"Male Family/Friends (TOT)"' `7'1 = `" Female Family/Friends (ITT)"' `7'2 = `"Female Family/Friends (TOT)"') ///
		xtitle("Regular business discussion partners", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfplot.png", replace
*/

end

	* apply program to network outcomes
		* w95		
rct_regression_network_paper net_size_w95 net_size3_w95 net_size3_m_w95 net_gender3_w95 net_size4_w95 net_size4_m_w95 net_gender4_w95, gen(netnumb_w95)

		* w99
rct_regression_network_paper net_size_w99 net_size3_w99 net_size3_m_w99 net_gender3_w99 net_size4_w99 net_size4_m_w99 net_gender4_w99, gen(netnumb_w99)

}







	* Endline & midline
{
capture program drop rct_regression_network_paper // enables re-running
program rct_regression_network_paper
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
    foreach var in `varlist' {
		foreach sr in 2 3 {			
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
					eststo `var'1_`sr': reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == `sr', cluster(consortia_cluster)
						// Add to LaTeX table
						estadd local bl_control "Yes" : `var'1_`sr'
						estadd local strata_final "Yes" : `var'1_`sr'
						// Add to coefplot
						local itt_`var'_`sr' = r(table)[1,2]
						local fmt_itt_`var'_`sr' : display %3.2f `itt_`var'_`sr''

				// ATT, IV regression
					eststo `var'2_`sr': ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == `sr', cluster(consortia_cluster) first
						// Add to LaTeX table
						estadd local bl_control "Yes" : `var'2_`sr'
						estadd local strata_final "Yes" : `var'2_`sr'
						// Add to coefplot
						local att_`var'_`sr' = e(b)[1,1]
						local fmt_att_`var'_`sr' : display %3.2f `att_`var'_`sr''

				// Calculate control group mean
					sum `var' if treatment == 0 & surveyround == `sr', d
						// For LaTeX table
						estadd scalar control_mean = r(mean) : `var'2_`sr'
						estadd scalar control_sd = r(sd) : `var'2_`sr'
						// For coefplots
						local c_m_`var'_`sr' = r(p50)
						local fmt_c_m_`var'_`sr' : display %3.2f `c_m_`var'_`sr''

				// Calculate percent change
					local `var'_per_itt_`sr' = (`fmt_itt_`var'_`sr'' / `fmt_c_m_`var'_`sr'') * 100
					local `var'_per_att_`sr' = (`fmt_att_`var'_`sr'' / `fmt_c_m_`var'_`sr'') * 100
	}
        else {
				// ITT: ANCOVA plus stratification dummies
					eststo `var'1_`sr': reg `var' i.treatment i.strata_final if surveyround == `sr', cluster(consortia_cluster)
						// Add to LaTeX table
						estadd local bl_control "Yes" : `var'1_`sr'
						estadd local strata_final "Yes" : `var'1_`sr'
						// Add to coefplot
						local itt_`var'_`sr' = r(table)[1,2]
						local fmt_itt_`var'_`sr' : display %3.2f `itt_`var'_`sr''

				// ATT, IV regression
					eststo `var'2_`sr': ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == `sr', cluster(consortia_cluster) first
						// Add to LaTeX table
						estadd local bl_control "Yes" : `var'2_`sr'
						estadd local strata_final "Yes" : `var'2_`sr'
						// Add to coefplot
						local att_`var'_`sr' = e(b)[1,1]
						local fmt_att_`var'_`sr' : display %3.2f `att_`var'_`sr''

				// Calculate control group mean
					sum `var' if treatment == 0 & surveyround == `sr', d
						// For LaTeX table
						estadd scalar control_mean = r(mean) : `var'2_`sr'
						estadd scalar control_sd = r(sd) : `var'2_`sr'
						// For coefplots
						local c_m_`var'_`sr' = r(p50)
						local fmt_c_m_`var'_`sr' : display %3.2f `c_m_`var'_`sr''

				// Calculate percent change
					local `var'_per_itt_`sr' = (`fmt_itt_`var'_`sr'' / `fmt_c_m_`var'_`sr'') * 100
					local `var'_per_att_`sr' = (`fmt_att_`var'_`sr'' / `fmt_c_m_`var'_`sr'') * 100
					
        }	// closes else condition
	}		// closes loop over srs
} 			// closes loop over vars
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: Endline
				* ITT
		local regressions `1'1_3 // `2'1_3 `3'1_3 `4'1_3 `5'1_3 `6'1_3 `7'1_3
		esttab `regressions' using "${tables_network}/rt_`generate'_el_ml.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Networks: Size and Composition} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.5cm} >{\centering\arraybackslash}m{1.5cm}} \toprule") ///
				posthead("\toprule \\ \multicolumn{8}{c}{Panel A: Endline} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(1)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels("All persons"  "CEOs" "Male CEOs" "Female CEOs"  "\shortstack{Friend/\\Family}" "\shortstack{Male Friend/\\Family}" "\shortstack{Female\\ Friend/Family}") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
				
				* ToT
		local regressions `1'2_3 // `2'2_3 `3'2_3 `4'2_3 `5'2_3 `6'2_3 `7'2_3  
		esttab `regressions' using "${tables_network}/rt_`generate'_el_ml.tex", append booktabs ///
				fragment ///	
				cells(b(star fmt(1)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\addlinespace[0.3cm] \midrule")
			
			* BOTTOM PANEL: MIDLINE
				* ITT
		local regressions `1'1_2 // `2'1_2 `3'1_2 `4'1_2 `5'1_2 `6'1_2 `7'1_2
		esttab `regressions' using "${tables_network}/rt_`generate'_el_ml.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{8}{c}{Panel B: Midline} \\\\[-1ex]") ///
				cells(b(star fmt(1)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
		
		local regressions `1'2_2 // `2'2_2 `3'2_2 `4'2_2 `5'2_2 `6'2_2 `7'2_2
		esttab `regressions' using "${tables_network}/rt_`generate'_el_ml.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{8}{c}{Panel B: Midline} \\\\[-1ex]") ///
				cells(b(star fmt(1)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{8}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: The outcome is the number of people with whom the female entrepreneurs discuss business regularly in the past three months. All variables are winsorised at the $95^{th}$ percentile as pre-specified. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable when available. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}")
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
/*						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Any (ITT)"' `1'2 = `"Any (TOT)"' `2'1 = `"Entrepreneurs (ITT)"' `2'2 = `"Entrepreneurs (TOT)"' `3'1 = `"Male Entrepreneurs (ITT)"' `3'2 = `"Male Entrepreneurs (TOT)"' `4'1 = `"Female Entrepreneurs (ITT)"' `4'2 = `"Female Entrepreneurs (TOT)"' `5'1 = `"Family/Friends (ITT)"' `5'2 = `"Family/Friends (TOT)"' `6'1 = `"Male Family/Friends (ITT)"' `6'2 = `"Male Family/Friends (TOT)"' `7'1 = `" Female Family/Friends (ITT)"' `7'2 = `"Female Family/Friends (TOT)"') ///
		xtitle("Regular business discussion partners", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfplot.png", replace
*/

end

	* apply program to network outcomes
		* w95

rct_regression_network_paper net_size_w95, gen(net_size_w95)

rct_regression_network_paper net_size_w95 net_size3_w95 net_size3_m_w95 net_gender3_w95 net_size4_w95 net_size4_m_w95 net_gender4_w95, gen(netnumb_w95)

		* w99
rct_regression_network_paper net_size_w99 net_size3_w99 net_size3_m_w99 net_gender3_w99 net_size4_w99 net_size4_m_w99 net_gender4_w99, gen(netnumb_w99)

}






* Network Use
{
capture program drop rct_regression_netserv // enables re-running
program rct_regression_netserv
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar control_mean = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local control_mean_`var' = r(mean)
					local fmt_control_mean_`var' : display  %3.2f `control_mean_`var''
										local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_control_mean_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_control_mean_`var'')*100		

		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 // `10'1  adjust manually to number of variables 
		esttab `regressions' using "${tables_network}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Networks: Use} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}p{1.25cm} >{\centering\arraybackslash}p{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.5cm} >{\centering\arraybackslash}m{1.25cm}} \toprule") ///
				posthead("\toprule \\ \multicolumn{8}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels("\shortstack{Manage-\\ment}"  "Innovation" "Export" "Referral"  "Joint bid" "Emotional support" "Other use") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  `4'2 `5'2 `6'2 `7'2 // `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 adjust manually to number of variables 
		esttab `regressions' using "${tables_network}/rt_`generate'.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{8}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{8}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: All outcomes are based on a binary yes-no-question whether the entrepreneur either shares, e.g., management practices, innovation ideas, export experience with or has made or received a referral, emotional support vis-a-vis business and exports risks and uncertainty or participated in a joint contract bid with other entrepreneurs. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}")
				// when inserting table in overleaf/latex, requires adding space after %
				// if MHT correction done, add to note: P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
    (`1'1, pstyle(p1)) ///
    (`1'2, pstyle(p1) ///
    mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
    mlabposition(12) mlabgap(*2) mlabsize(medsmall)) ///
    (`2'1, pstyle(p2)) ///
    (`2'2, pstyle(p2) ///
    mlabel(string(@b, "%9.2f") + " equivalent to " + string(``2'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
    mlabposition(12) mlabgap(*2) mlabsize(medsmall)) ///
    (`3'1, pstyle(p3)) ///
    (`3'2, pstyle(p3) ///
    mlabel(string(@b, "%9.2f") + " equivalent to " + string(``3'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
    mlabposition(12) mlabgap(*2) mlabsize(medsmall)) ///
    (`4'1, pstyle(p4)) ///
    (`4'2, pstyle(p4)) ///
    (`5'1, pstyle(p5)) ///
    (`5'2, pstyle(p5) ///
    mlabel(string(@b, "%9.2f") + " equivalent to " + string(``5'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
    mlabposition(12) mlabgap(*2) mlabsize(medsmall)) ///
    (`6'1, pstyle(p6)) ///
    (`6'2, pstyle(p6) ///
    mlabel(string(@b, "%9.2f") + " equivalent to " + string(``6'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
    mlabposition(12) mlabgap(*2) mlabsize(medsmall)) ///
    (`7'1, pstyle(p7)) ///
    (`7'2, pstyle(p7)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.5(0.25)1) /// title("Network Use", position(12) size(medium)) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Shares management practices (ITT)"' `1'2 = `"Shares management practices (TOT)"' `2'1 = `"Shares product ideas (ITT)"' `2'2 = `"Shares product ideas (TOT)"' `3'1 = `"Shares export experience (ITT)"' `3'2 = `"Shares export experience (TOT)"' `4'1 = `"Make/receive referral (ITT)"' `4'2 = `"Make/receive referral (TOT)"' `5'1 = `"Joint contract bid (ITT)"' `5'2 = `"Joint contract bid (TOT)"' `6'1 = `"Emotional support business risk (ITT)"' `6'2 = `"Emotional support business risk (TOT)"' `7'1 = `"Other (ITT)"' `7'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(12)  ysize(6) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "Number of observations is `fmt_nobs_`1''." "Confidence intervals are at the 95 percent level." "All variables are binary (0/1).", span size(medsmall)) ///	
		ysc(outergap(-8)) ///
		name(el_`generate'_cfp, replace)
gr export "${figures_network}/el_`generate'_cfp.pdf", replace	
	
*gr export "${figures_network}/el_`generate'_cfp.pdf", replace

end

	* apply program to network use/services
rct_regression_netserv net_pratiques net_produits net_mark net_sup net_contract net_confiance net_autre, gen(network_use)

}




**** TABLES FOR PRESENTATION ******
	* network size
capture program drop network_size_presentation // enables re-running
program network_size_presentation
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.1f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.1f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar control_mean = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local control_mean_`var' = r(mean)
					local fmt_control_mean_`var' : display  %3.1f `control_mean_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.1f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_control_mean_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_control_mean_`var'')*100			

		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network size & cooperation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{3}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{2}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 95 percent level, corresponding to three extreme values. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are clustered at the individual firm-level for the control group and at the consortia level for treatment group firms.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(1)10) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Monthly business `=char(13)'`=char(10)' discussions (ITT)"' `1'2 = `"Monthly business `=char(13)'`=char(10)' discussions (TOT)"') ///
		xtitle("Persons", size(medium)) ///  
		leg(off) ysize(5) xsize(10)  /// xsize controls aspect ratio, makes graph wider & reduces its height 
		ysc(outergap(-35)) /// negative outer gap --> reduces space btw coef names & plot
		note("{bf:Note}:" "The control group endline average is `fmt_control_mean_`1''." "Variables are winsorized at the 95th percentile." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfp1, replace)
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfp1.png", replace
		
		
coefplot ///
	(`1'1, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") mlabposition(12) mlabgap(*2) mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") mlabposition(12) mlabgap(*2) mlabsize(medium)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(1)10) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Monthly business discussions (ITT)"' `1'2 = `"Monthly business discussions (TOT)"') ///
		xtitle("Persons", size(medium)) ///  
		leg(off) ysize(5) xsize(8)  /// xsize controls aspect ratio, makes graph wider & reduces its height 
		note("{bf:Note}:" "The control group endline average is `fmt_control_mean_`1'' and SD is `fmt_sd_`1''." "Number of observations is `fmt_nobs_`1''." "Confidence intervals are at the 95 percent level." "Variable is winsorized at the 95th percentile.", span size(medium)) ///
		name(el_`generate'_cfp2, replace)
gr export "${figures_network}/el_`generate'_cfp2.pdf", replace	
	
*	gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfp2.png", replace


end
	
network_size_presentation net_size_w95, gen(netsize)	
	
	
	
	
	
	* network composition entrepreneurs & gender (1: nbr of contacts, 2: % of women, 3: % GIZ)
capture program drop network_comp_presentation // enables re-running
program network_comp_presentation
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3 & `var' >= 0, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3 `var' >= 0, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1  // adjust manually to number of variables: `5'1 `6'1 `7'1 `8'1 `9'1
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network size & cooperation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.*  ?.missing_bl_*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 // adjust manually to number of variables:  `5'2 `6'2 `7'2 `8'2 `9'2
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.*  ?.missing_bl_*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Outcomes in columns (1) and (2) are winsorized at the 95 percent level. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are clustered at the individual firm-level for the control group and at the consortia level for treatment group firms.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) /// 
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(1)10) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Female `=char(13)'`=char(10)' Entrepreneurs (ITT)"' `1'2 = `"Female `=char(13)'`=char(10)' Entrepreneurs (TOT)"' `2'1 = `"Male `=char(13)'`=char(10)' Entrepreneurs (ITT)"' `2'2 = `"Male `=char(13)'`=char(10)' Entrepreneurs (TOT)"') ///
		xtitle("Monthly business discussion partners", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-20)) ///
		name(el_`generate'_tot_cfp, replace)
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_tot_cfp.png", replace
		
		
coefplot ///
	 (`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	 (`4'1, pstyle(p4)) (`4'2, pstyle(p4)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(0.5)2) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`3'1 = `"Female vs. `=char(13)'`=char(10)' Male Entrepreneurs (ITT)"' `3'2 = `"Female vs. `=char(13)'`=char(10)' Male Entrepreneurs (TOT)"' `4'1 = `"Consortia Members in `=char(13)'`=char(10)' Tot. Fem. Entr. (ITT)"' `4'2 = `"Consortia Members in `=char(13)'`=char(10)' Tot. Fem. Entr. (TOT)"') ///
		xtitle("Shares", size(medsmall)) ///  
		leg(off) xsize(4) ysize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-30)) ///
		name(el_`generate'_share_cfp, replace)

//  `5'1 = `"Family/Friends (ITT)"' `5'2 = `"Family/Friends (TOT)"' `6'1 = `"Male Family/Friends (ITT)"' `6'2 = `"Male Family/Friends (TOT)"' `7'1 = `" Female Family/Friends (ITT)"' `7'2 = `"Female Family/Friends (TOT)"'
	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_share_cfp.png", replace

//  (`5'1, pstyle(p5)) (`5'2, pstyle(p5)) (`6'1, pstyle(p6)) (`6'2, pstyle(p6)) (`7'1, pstyle(p7)) (`7'2, pstyle(p7))


end

network_comp_presentation net_gender3_w95 net_size3_m_w95 net_gender3_ratio net_giz_ratio, gen(netcomp_entr)	


	* network composition familly/friends & gender 
capture program drop network_comp_presentation // enables re-running
program network_comp_presentation
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3 & `var' >= 0, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3 & `var' >= 0, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1  // adjust manually to number of variables: `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network size & cooperation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.*  ?.missing_bl_*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 // adjust manually to number of variables:  `3'2 `4'2  `5'2 `6'2 `7'2 `8'2 `9'2
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.*  ?.missing_bl_*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Outcomes in columns (1) and (2) are winsorized at the 95 percent level. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are clustered at the individual firm-level for the control group and at the consortia level for treatment group firms.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) /// 
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(1)10) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Female `=char(13)'`=char(10)' Friends & Family (ITT)"' `1'2 = `"Female `=char(13)'`=char(10)' Friends & Family (TOT)"' `2'1 = `"Male `=char(13)'`=char(10)' Friends & Family (ITT)"' `2'2 = `"Male `=char(13)'`=char(10)' Friends & Family (TOT)"') ///
		xtitle("Monthly business discussion partners", size(medsmall)) ///  
		leg(off) xsize(4) ysize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-20)) ///
		name(el_`generate'_total_cfp, replace)

	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfp.png", replace

end

network_comp_presentation net_gender4_w95 net_size4_m_w95, gen(netcomp_ff)	

**************** net_association: Did the control group and drop out firms join other business associations instead? ****************
capture program drop network_asso // enables re-running
program network_asso
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1  // adjust manually to number of variables: `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network size & cooperation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{3}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.*  ?.missing_bl_*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2  // adjust manually to number of variables: `2'2 `3'2 `4'2  `5'2 `6'2 `7'2 `8'2 `9'2
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.*  ?.missing_bl_*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{2}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are clustered at the individual firm-level for the control group and at the consortia level for treatment group firms.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), /// (`2'1, pstyle(p2)) (`2'2, pstyle(p2)) 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(0.5)2) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Business Association `=char(13)'`=char(10)' Memberships (ITT)"' `1'2 = `"Business Association `=char(13)'`=char(10)' Memberships (TOT)"') ///  `2'1 = `"Male Friends & Family (ITT)"' `2'2 = `"Male Friends & Family (TOT)"'
		xtitle("Treatment effect", size(medsmall)) ///  
		leg(off) xsize(4) ysize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height		
		ysc(outergap(-40)) ///
		name(el_`generate'_cfp, replace)

	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfp.png", replace

end

network_asso net_association, gen(net_asso)	

	
**************** net_services ****************
{
capture program drop rct_regression_netserv // enables re-running
program rct_regression_netserv
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1   // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network services} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{9}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{8}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls")) ///
				drop(_cons *.strata_final) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{8}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata. All outcomes are binary 1 or 0 variables. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors reported in parentheses are clustered on the firm-level for control group and on the consortia-level for treatment group firms. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// if MHT correction done, add to note: P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		title("Network Use", position(12) size(medium)) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Shares management practices (ITT)"' `1'2 = `"Shares management practices (TOT)"' `2'1 = `"Shares product ideas (ITT)"' `2'2 = `"Shares product ideas (TOT)"' `3'1 = `"Shares export experience (ITT)"' `3'2 = `"Shares export experience (TOT)"' `4'1 = `"Referral (ITT)"' `4'2 = `"Referral (TOT)"' `5'1 = `"Joint contract bid (ITT)"' `5'2 = `"Joint contract bid (TOT)"' `6'1 = `"Confidence (ITT)"' `6'2 = `"Confidence (TOT)"' `7'1 = `"Other (ITT)"' `7'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-8)) ///
		name(el_`generate'_cfp, replace)
	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfp.png", replace

end

	* apply program to network use/services
rct_regression_netserv net_pratiques net_produits net_mark net_sup net_contract net_confiance net_autre, gen(network_use)

}


**************** net_coop ****************
{
capture program drop rct_regression_coop // enables re-running
program rct_regression_coop
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			// ITT: ANCOVA plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes" : `var'1
			estadd local strata_final "Yes" : `var'1

			// ATT, IV
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes" : `var'2
			estadd local strata_final "Yes" : `var'2

			// Calculate control group mean
			sum `var' if treatment == 0 & surveyround == 3
			estadd scalar control_mean = r(mean) : `var'2
			estadd scalar control_sd = r(sd) : `var'2
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network cooperation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot pos
coefplot ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)) ///
	(`8'1, pstyle(p8)) (`8'2, pstyle(p8)) ///
	(`9'1, pstyle(p9)) (`9'2, pstyle(p9)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
eqrename(`2'1 = `"Cooperate (ITT)"' `2'2 = `"Cooperate (TOT)"' `3'1 = `"Trust (ITT)"' `3'2 = `"Trust (TOT)"' `7'1 = `"Learn (ITT)"' `7'2 = `"Learn (TOT)"' `8'1 = `"Partnership (ITT)"' `8'2 = `"Partnership (TOT)"'  `9'1 = `"Connect (ITT)"' `9'2 = `"Connect (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_pos_cfp, replace)

gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_pos_cfp.png", replace
	
			* coefplot neg
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`10'1, pstyle(p10)) (`10'2, pstyle(p10)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
eqrename(`1'1 = `"Jealousy (ITT)"' `1'2 = `"Jealousy (TOT)"' `4'1 = `"Protecting business secrets (ITT)"' `4'2 = `"Protecting business secrets (TOT)"' `5'1 = `"Risks (ITT)"' `5'2 = `"Risks (TOT)"' `6'1 = `"Conflict (ITT)"' `6'2 = `"Conflict (TOT)"' `10'1 = `"Competition (ITT)"' `10'2 = `"Competition (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)

gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfplot.png", replace

end

	* apply program to export outcomes
rct_regression_coop netcoop2 netcoop3 netcoop7 netcoop8 netcoop9 netcoop1 netcoop4 netcoop5 netcoop6 netcoop10, gen(coop)

}


**************** net_coop ML/EL ****************
lab var net_coop_pos "Pos. view"
lab var net_coop_neg "Neg. view"
{
capture program drop rct_regression_coopsr // enables re-running
program rct_regression_coopsr
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
local i = 1
foreach var in `varlist' {
		// Loop for surveyround == 2 and 3
	foreach sr in 2 3 {
    // ITT: ANCOVA plus stratification dummies
    eststo `var'1_`sr': reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == `sr', cluster(consortia_cluster)
        // Add to LaTeX table
        estadd local bl_control "Yes" : `var'1_`sr'
        estadd local strata_final "Yes" : `var'1_`sr'
        // Add to coefplot
        local itt_`var'_`sr' = r(table)[1,2]
        local fmt_itt_`var'_`sr' : display %3.2f `itt_`var'_`sr''

    // ATT, IV regression
    eststo `var'2_`sr': ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == `sr', cluster(consortia_cluster) first
        // Add to LaTeX table
        estadd local bl_control "Yes" : `var'2_`sr'
        estadd local strata_final "Yes" : `var'2_`sr'
        // Add to coefplot
        local att_`var'_`sr' = e(b)[1,1]
        local fmt_att_`var'_`sr' : display %3.2f `att_`var'_`sr''

    // Calculate control group mean
    sum `var' if treatment == 0 & surveyround == `sr', d
        // For LaTeX table
        estadd scalar control_mean = r(mean) : `var'2_`sr'
        estadd scalar control_sd = r(sd) : `var'2_`sr'
        // For coefplots
        local c_m_`var'_`sr' = r(p50)
        local fmt_c_m_`var'_`sr' : display %3.2f `c_m_`var'_`sr''

    // Calculate percent change
    local `var'_per_itt_`sr' = (`fmt_itt_`var'_`sr'' / `fmt_c_m_`var'_`sr'') * 100
    local `var'_per_att_`sr' = (`fmt_att_`var'_`sr'' / `fmt_c_m_`var'_`sr'') * 100
}

}

	
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1_2 `1'1_3 `2'1_2 `2'1_3 // adjust manually to number of variables 
		esttab `regressions' using "${tables_network}/rt_`generate'.tex", replace booktabs /// ${master_regressiontables}/endline/regressions/network
				prehead("\begin{table}[!h] \centering \\ \caption{Network cooperation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") /// m{1.25cm}
				posthead("\toprule \\ \multicolumn{4}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels("\shortstack{Pos. view \\ ML}" "\shortstack{Pos. view \\ EL}" "\shortstack{Neg. view \\ ML}" "\shortstack{Neg. view \\ EL}")  /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2_2 `1'2_3  `2'2_2 `2'2_3     // adjust manually to number of variables 
		esttab `regressions' using "${tables_network}/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\midrule \\ \multicolumn{4}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.11 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\midrule") ///
				postfoot("\bottomrule \\ \addlinespace[0.2cm] \multicolumn{8}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: Respondents selected three among the following five negative terms (Jealousy, Protect business secrets, Risks, Conflict, Competition) and positive terms ( Cooperate, Trust, Learn, Partnership, Connect). Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable when available. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
				
	* coefplot
			* no effect sizes
		coefplot ///
			(`1'1_2, pstyle(p1)) (`1'2_2, pstyle(p1))  ///
			(`2'1_2, pstyle(p2)) (`2'2_2, pstyle(p2)), ///
				bylabel("Midline") ///
				subtitle(, size(medlarge)) ///
				asequation /// name of model is used
				swapnames /// swaps coeff & equation names after collecting result
				levels(95) ///
				xtitle(, size(medlarge)) ///
				eqrename(`1'1_2 = `"Positive terms (ITT)"' `1'2_2 = `"Positive terms (TOT)"' `2'1_2 = `"Negative terms (ITT)"' `2'2_2 = `"Negative Terms (TOT)"') ///
		|| ///
			(`1'1_3, pstyle(p1)) (`1'2_3, pstyle(p1))  ///
			(`2'1_3, pstyle(p2)) (`2'2_3, pstyle(p2)), /// 
				bylabel("Endline") ///
				subtitle(, size(medlarge)) ///
				asequation /// name of model is used
				swapnames /// swaps coeff & equation names after collecting result
				levels(95) ///
				xtitle(, size(medlarge)) ///
				eqrename(`1'1_3 = `"Positive terms (ITT)"' `1'2_3 = `"Positive terms (TOT)"' `2'1_3 = `"Negative terms (ITT)"' `2'2_3 = `"Negative Terms (TOT)"') ///
		||, ///		
		byopts(title("{bf:View of Business Interactions between Entrepreneurs}", justification(center)) note("{bf:Note}:" "All variables are counts of the 3 terms selected among 10 options." "Midline Negative Terms (TOT) is significant at the 10% level." "Negative: Jealousy, Protect business secrets, Risks, Conflict, Competition." "Positive: Cooperate, Trust, Learn, Partnership, Connect.", span size(medsmall)) leg(off)) ///
		keep(*treatment take_up) drop(_cons *strata_final) xline(0) ///
		name(el_coopcount_cfp1, replace)
gr export "${master_regressiontables}/endline/regressions/confidence/el_coopcount_cfp1.pdf", replace

				* include effect sizes
		coefplot ///
			(`1'1_2, pstyle(p1)) ///
			(`1'2_2, pstyle(p1)  ///
			mlabel(string(@b, "%9.2f") +" equivalent to " + string(``1'_per_att_2', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") mlabposition(12) mlabgap(*2)  mlabsize(medium))  ///
			(`2'1_2, pstyle(p2)) ///
			(`2'2_2, pstyle(p2)  ///
			mlabel(string(@b, "%9.2f") +" equivalent to " + string(``1'_per_att_2', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") mlabposition(12) mlabgap(*2)  mlabsize(medium)), ///
				bylabel("Midline") ///
				subtitle(, size(medlarge)) ///
				asequation /// name of model is used
				swapnames /// swaps coeff & equation names after collecting result
				levels(95) ///
				xtitle(, size(medlarge)) ///
				eqrename(`1'1_2 = `"Positive terms (ITT)"' `1'2_2 = `"Positive terms (TOT)"' `2'1_2 = `"Negative terms (ITT)"' `2'2_2 = `"Negative Terms (TOT)"') ///
		|| ///
			(`1'1_3, pstyle(p1)) ///
			(`1'2_3, pstyle(p1)) ///
			(`2'1_3, pstyle(p2)) ///
			(`2'2_3, pstyle(p2)), /// 
				bylabel("Endline") ///
				subtitle(, size(medlarge)) ///
				asequation /// name of model is used
				swapnames /// swaps coeff & equation names after collecting result
				levels(95) ///
				xtitle(, size(medlarge)) ///
				eqrename(`1'1_3 = `"Positive terms (ITT)"' `1'2_3 = `"Positive terms (TOT)"' `2'1_3 = `"Negative terms (ITT)"' `2'2_3 = `"Negative Terms (TOT)"') ///
		||, ///
		byopts(title("{bf:View of Business Interactions between Entrepreneurs}", justification(center)) note("{bf:Note}:" "All variables are counts of the 3 terms selected among 10 options." "Average negative terms in control at ML & EL is `fmt_c_m_net_coop_neg_2' & `fmt_c_m_net_coop_neg_3'." "Average negative terms in control at ML & EL is `fmt_c_m_net_coop_pos_2' & `fmt_c_m_net_coop_pos_3'."
	"Negative: Jealousy, Protect business secrets, Risks, Conflict, Competition." "Positive: Cooperate, Trust, Learn, Partnership, Connect.", span size(medsmall)) leg(off)) ///
		keep(*treatment take_up) drop(_cons *strata_final) xline(0) ///
		name(el_coopcount_cfp2, replace)
gr export "${master_regressiontables}/endline/regressions/confidence/el_coopcount_cfp2.pdf", replace
			

end

	* apply program to outcomes
rct_regression_coopsr net_coop_pos net_coop_neg, gen(coopsr)

}





}





***********************************************************************
* 	PART 8: endline results - regression table entrepreneurial empowerment
***********************************************************************
{
cd "${master_regressiontables}/endline/regressions/confidence"
**************** TABLES FOR PAPER & PRESENTATION ****************
* change label for table output
lab var car_efi_fin1 "access new funding"
lab var car_loc_env "grasp internal and external dynamics"
lab var car_loc_exp "deal with exports requisities"
lab var car_loc_soin "balance personal and professional life"


*** midline & endline (not so much additional information? Focus on endline?!)
{
capture program drop rct_confidence // enables re-running
program rct_confidence
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// (surveyround == 2)
				eststo `var'1_ml: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 2, cluster(consortia_cluster)
				estadd local bl_control "Yes" : `var'1_ml
				estadd local strata_final "Yes" : `var'1_ml

				eststo `var'2_ml: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 2, cluster(consortia_cluster) first
				estadd local bl_control "Yes" : `var'2_ml
				estadd local strata_final "Yes" : `var'2_ml

				sum `var' if treatment == 0 & surveyround == 2
				estadd scalar control_mean = r(mean) : `var'2_ml
				estadd scalar control_sd = r(sd) : `var'2_ml

				//  (surveyround == 3)
				eststo `var'1_el: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes" : `var'1_el
				estadd local strata_final "Yes" : `var'1_el

				eststo `var'2_el: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes" : `var'2_el
				estadd local strata_final "Yes" : `var'2_el

				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean) : `var'2_el
				estadd scalar control_sd = r(sd) : `var'2_el
			}
			else {
				// (surveyround == 2)
				eststo `var'1_ml: reg `var' i.treatment i.strata_final if surveyround == 2, cluster(consortia_cluster)
				estadd local bl_control "No" : `var'1_ml
				estadd local strata_final "Yes" : `var'1_ml

				eststo `var'2_ml: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 2, cluster(consortia_cluster) first
				estadd local bl_control "No" : `var'2_ml
				estadd local strata_final "Yes" : `var'2_ml

				sum `var' if treatment == 0 & surveyround == 2
				estadd scalar control_mean = r(mean) : `var'2_ml
				estadd scalar control_sd = r(sd) : `var'2_ml

				//  (surveyround == 3)
				eststo `var'1_el: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No" : `var'1_el
				estadd local strata_final "Yes" : `var'1_el

				eststo `var'2_el: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No" : `var'2_el
				estadd local strata_final "Yes" : `var'2_el

				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean) : `var'2_el
				estadd scalar control_sd = r(sd) : `var'2_el
        }

}

tokenize `varlist'
/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
	
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1_ml `1'1_el `2'1_ml `2'1_el  // adjust manually to number of variables 
		esttab `regressions' using "${figures_confidence}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial confidence: Efficacy and Locus of Control} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm} >{\centering\arraybackslash}m{1.25cm}} \toprule") ///
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{5}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3))) /// rw ci(fmt(2))
				mlabels("\shortstack{ML\\ Efficacy}" "\shortstack{EL\\ Efficacy}" "\shortstack{ML\\ Locus of Control}" "\shortstack{EL\\ Locus of Control}") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final *_y0 ?.missing_bl_*) ///  L.* oL.* ?.missing_bl_*  *_y0
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2_ml `1'2_el `2'2_ml `2'2_el // adjust manually to number of variables 
		esttab `regressions' using "${figures_confidence}/rt_`generate'.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3))) ///  rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final *_y0 ?.missing_bl_*) ///  L.* `5' `6' ?.missing_bl_*  *_y0
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{8}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: All dependent variables are indexes calculated based on z-scores as described in \citet{Anderson.2008}. Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Panel A reports ANCOVA estimates as defined in \citet{McKenzie.2012}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors in parentheses are clustered on the consortia-level for treatment group firms and on the firm-level for control group firms following \citet{Cai.2018}. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.
end

	* apply program to efficacy & loc
rct_confidence female_efficacy female_loc, gen(conf)

	* apply program to efficacy & loc
rct_confidence female_efficacy_mean female_loc_mean, gen(conf_mean)

}



{
capture program drop rct_confidence // enables re-running
program rct_confidence
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	

			capture confirm variable `var'_y0
			if _rc == 0 {
				// (surveyround == 2)
				eststo `var'1_ml: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 2, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				eststo `var'2_ml: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 2, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				sum `var' if treatment == 0 & surveyround == 2
				estadd scalar ml_control_mean = r(mean)
				estadd scalar ml_control_sd = r(sd)

				//  (surveyround == 3)
				eststo `var'1_el: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				eststo `var'2_el: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar el_control_mean = r(mean)
				estadd scalar el_control_sd = r(sd)
			}
			else {
				// (surveyround == 2)
				eststo `var'1_ml: reg `var' i.treatment i.strata_final if surveyround == 2, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				eststo `var'2_ml: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 2, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				sum `var' if treatment == 0 & surveyround == 2
				estadd scalar ml_control_mean = r(mean)
				estadd scalar ml_control_sd = r(sd)

				//  (surveyround == 3)
				eststo `var'1_el: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				eststo `var'2_el: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar el_control_mean = r(mean)
				estadd scalar el_control_sd = r(sd)
        }

}

tokenize `varlist'
/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
	
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1_ml `1'1_el `2'1_ml `2'1_el `3'1_ml `3'1_el `4'1_ml `4'1_el `5'1_ml `5'1_el  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/confidence/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial empowerment: Efficacy} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final *_y0) ///  L.* oL.* ?.missing_bl_*  *_y0
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2_ml `1'2_el `2'2_ml `2'2_el `3'2_ml `3'2_el `4'2_ml `4'2_el `5'2_ml `5'2_el  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/confidence/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(el_control_mean el_control_sd ml_control_mean ml_control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final *_y0) ///  L.* `5' `6' ?.missing_bl_*  *_y0
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are z-scores and columns (1) and (2) are composite indexes of the other columns as in Anderson et al. (2008).  Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors in parentheses are clustered on the consortia-level for treatment group firms and on the firm-level for control group firms. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.
end

	* apply program to efficacy
rct_confidence female_efficacy female_efficacy car_efi_fin1 car_efi_man car_efi_motiv, gen(conf_efi)
	* apply program to locus of control
rct_confidence female_loc female_loc car_loc_env car_loc_exp car_loc_soin, gen(conf_efi)

}




**************** efi & loc (z-scores) ****************
{
capture program drop rct_regression_efi // enables re-running
program rct_regression_efi
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
				// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100
					
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 // `3'1 `4'1 adjust manually to number of variables 
		esttab `regressions' using "${tables_confidence}/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial empowerment: Efficacy} \\ \begin{adjustbox}{width=\columnwidth,center} \\\begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{3}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2  //  `3'2 `4'2 adjust manually to number of variables 
		esttab `regressions' using "${tables_confidence}/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\midrule \\ \multicolumn{3}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: The outcomes are z-scores following \citet{Anderson.2008}. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.6(0.2)1) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Efficacy: `=char(13)'`=char(10)' Z-score (ITT)"' `1'2 = `"Efficacy: `=char(13)'`=char(10)' Z-score (TOT)"' `2'1 = `"Locus of Control: `=char(13)'`=char(10)' Z-score (ITT)"' `2'2 = `"Locus of Control: `=char(13)'`=char(10)' Z-score (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}: 0.4 corresponds roughly to 2x the mean of the control group.", span) ///
		ysc(outergap(-20)) ///
		name(el_`generate'_cfp, replace)
gr export "${master_regressiontables}/endline/regressions/confidence/el_`generate'_cfp.pdf", replace


		* cfp 1: direction & significance (CI)
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.6(0.2)1) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`1'1 = `"Efficacy: `=char(13)'`=char(10)' Z-score (ITT)"' `1'2 = `"Efficacy: `=char(13)'`=char(10)' Z-score (TOT)"' `2'1 = `"Locus of Control: `=char(13)'`=char(10)' Z-score (ITT)"' `2'2 = `"Locus of Control: `=char(13)'`=char(10)' Z-score (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "The control group endline median is `fmt_c_m_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfp1, replace)
gr export "${master_regressiontables}/endline/regressions/confidence/el_`generate'_cfp1.pdf", replace


		* cfp 2: magnitude & significance (p-value)
coefplot ///
	(`1'1,  pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") /// " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" + 
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///  + " equivalent to " + string(``1'_per_att', "%9.0f") + "%"
	mlabposition(12) mlabgap(*2) mlabsize(medium))  ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.6(0.2)1) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Efficacy: Z-score (ITT)"' `1'2 = `"Efficacy: Z-score (TOT)"' `2'1 = `"Locus of Control: Z-score (ITT)"' `2'2 = `"Locus of Control: Z-score (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "The control group endline median efficacy is `fmt_c_m_`1'' and SD is `fmt_sd_`1''." "The control group endline median locus of control is `fmt_c_m_`2'' and SD is `fmt_sd_`2''."  "Number of observations is `fmt_nobs_`1''." "Confidence intervals are at the 95 percent level." "Variables are z-scores following Anderson (2008) based on three 7-likert scale self-affirmation questions.", span size(medium)) ///
		name(el_`generate'_cfp2, replace)
	* export for google drive (presentation?)
*gr export "${master_regressiontables}/endline/regressions/confidence/el_`generate'_cfp2.pdf", replace
	* export for github paper repo
gr export "${figures_confidence}/el_`generate'_cfp2.pdf", replace



end

	* apply program to efi & loc
rct_regression_efi female_efficacy female_loc, gen(efi_loc)

}




**************** efi (components) ****************
{
capture program drop rct_efi_comp // enables re-running
program rct_efi_comp
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 // `4'1 adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial empowerment: Efficacy} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  // `4'2 adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1.5(0.5)1.5) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		title("Efficacy (Ability)", pos(11)) ///
		eqrename(`1'1 = `"Capable to get funding (ITT)"' `1'2 = `"Capable to get funding (TOT)"' `2'1 = `"Able to manage the firm (ITT)"' `2'2 = `"Able to manage the firm (TOT)"' `3'1 = `"Motivate employees (ITT)"' `3'2 = `"Motivate employees (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-5)) ///
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_efi_comp car_efi_fin1 car_efi_man car_efi_motiv, gen(efi_comp)

}

**************** loc (components) ****************
{
capture program drop rct_loc_comp // enables re-running
program rct_loc_comp
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1  // `4'1 adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial empowerment: Locus of Control} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  // `4'2 adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0)  xlabel(-1.5(0.5)1.5) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Ease of establishing `=char(13)'`=char(10)' business contacts (ITT)"' `1'2 = `"Ease of establishing `=char(13)'`=char(10)' business contacts (TOT)"' `2'1 = `"Master Export Logistics `=char(13)'`=char(10)' & Administration (ITT)"' `2'2 = `"Master Export Logistics `=char(13)'`=char(10)' & Administration (TOT)"' `3'1 = `"Reconciliate private & `=char(13)'`=char(10)' professional life (ITT)"' `3'2 = `"Reconciliate private & `=char(13)'`=char(10)' professional life (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) /// 
		title("Locus of Control", justification(center) pos(11)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-45)) ///
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_loc_comp car_loc_env car_loc_exp car_loc_soin, gen(locus_comp)

}


**************** efi (z-score + components) ****************


{
capture program drop rct_regression_efi // enables re-running
program rct_regression_efi
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial empowerment: Efficacy} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1.5(0.5)1.5) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		title("Efficacy (Ability)", pos(11)) ///
		eqrename(`1'1 = `"Efficacy: Z-score (ITT)"' `1'2 = `"Efficacy: Z-score (TOT)"' `2'1 = `"Capable to get funding (ITT)"' `2'2 = `"Capable to get funding (TOT)"' `3'1 = `"Able to manage the firm (ITT)"' `3'2 = `"Able to manage the firm (TOT)"' `4'1 = `"Motivate employees (ITT)"' `4'2 = `"Motivate employees (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-5)) ///
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_efi female_efficacy car_efi_fin1 car_efi_man car_efi_motiv, gen(efi)

}

**************** locus (z-score + components) ****************

{
capture program drop rct_regression_locus // enables re-running
program rct_regression_locus
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial empowerment: Locus of Control} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0)  xlabel(-1.5(0.5)1.5) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Locus of Control `=char(13)'`=char(10)' Z-score (ITT)"' `1'2 = `"Locus of Control `=char(13)'`=char(10)' Z-score (TOT)"' `2'1 = `"Ease of establishing `=char(13)'`=char(10)' business contacts (ITT)"' `2'2 = `"Ease of establishing `=char(13)'`=char(10)' business contacts (TOT)"' `3'1 = `"Master Export Logistics `=char(13)'`=char(10)' & Administration (ITT)"' `3'2 = `"Master Export Logistics `=char(13)'`=char(10)' & Administration (TOT)"' `4'1 = `"Reconciliate private & `=char(13)'`=char(10)' professional life (ITT)"' `4'2 = `"Reconciliate private & `=char(13)'`=char(10)' professional life (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) /// 
		title("Locus of Control", justification(center) pos(11)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-45)) ///
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_locus female_loc car_loc_env car_loc_exp car_loc_soin, gen(locus)

}

}


***********************************************************************
* 	PART 9:knowledge transfer overview: MPI, ERI, II
***********************************************************************
lab var ipi "Innovation practices"
capture program drop kt_overview // enables re-running
program kt_overview
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	capture confirm variable `var'_y0
        if _rc == 0 {	
				
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group median
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(p50) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	

			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No": `var'2 
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group median
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(p50) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
			}

		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 // `3'1 `4'1 adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge Transfer: Management and Innovation Indexes} \\ \begin{adjustbox}{width=\columnwidth,center} \\\begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{3}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2  //  `3'2 `4'2 adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\midrule \\ \multicolumn{3}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: The outcomes are z-scores following \citet{Anderson.2008}. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}")
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), /// (`3'1, pstyle(p3)) (`3'2, pstyle(p3))
	keep(*treatment take_up) drop(_cons *strata_final) xline(0) /// xlabel(0(1)10)
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (ITT)"' `1'2 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (TOT)"' `2'1 = `"Innovation `=char(13)'`=char(10)' Index (ITT)"' `2'2 = `"Innovation `=char(13)'`=char(10)' Index (TOT)"') /// `2'1 = `"Export `=char(13)'`=char(10)' Readiness `=char(13)'`=char(10)' Index (ITT)"' `2'2 = `"Export `=char(13)'`=char(10)' Readiness `=char(13)'`=char(10)' Index (TOT)"'
		xtitle("Treatment Effect", size(medsmall)) ///  
		leg(off) xsize(4) ysize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height 
		ysc(outergap(-50)) /// negative outer gap --> reduces space btw coef names & plot
		name(el_`generate'_cfp, replace)
gr export "${master_regressiontables}/endline/regressions/el_`generate'_cfp.pdf", replace


		* cfp 1: direction & significance (CI)
			* Management `1'
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.6(0.2)1) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`1'1 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (ITT)"' `1'2 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (TOT)"' `2'1 = `"Innovation `=char(13)'`=char(10)' Index (ITT)"' `2'2 = `"Innovation `=char(13)'`=char(10)' Index (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "The control group endline median is `fmt_c_m_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfp1, replace)
gr export "${master_regressiontables}/endline/regressions/el_`generate'_cfp1.pdf", replace


		* cfp 2: magnitude & significance (p-value)
coefplot ///
	(`1'1,  pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") /// " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" +
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") /// + " equivalent to " + string(``1'_per_att', "%9.0f") + "%"
	mlabposition(12) mlabgap(*2) mlabsize(medium))  ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.6(0.2)1) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (ITT)"' `1'2 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (TOT)"' `2'1 = `"Innovation `=char(13)'`=char(10)' Index (ITT)"' `2'2 = `"Innovation `=char(13)'`=char(10)' Index (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}: Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfp2, replace)
	* export to Gdrive
gr export "${master_regressiontables}/endline/regressions/el_`generate'_cfp2.pdf", replace
	* export to paper github repo
gr export "${figures_management}/el_`generate'_cfp2.pdf", replace



end
	
kt_overview mpi ipi, gen(kt) // eri

***********************************************************************
* 	PART 10: endline results - INNOVATION - knowledge transfer
***********************************************************************
{
**************** inno_produit ****************
* change directory
cd "${master_regressiontables}/endline/regressions/innovation"

{
capture program drop rct_regression_kt // enables re-running
program rct_regression_kt
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
			
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes" : `var'1
			estadd local strata_final "Yes" : `var'1

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes" : `var'2
			estadd local strata_final "Yes" : `var'2
			
			* calculate control group mean
				* take endline mean to control for time trend
			sum `var' if treatment == 0 & surveyround == 3
			estadd scalar control_mean = r(mean) : `var'2
			estadd scalar control_sd = r(sd) : `var'2
	}
	else {
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes" : `var'1
			estadd local strata_final "Yes" : `var'1

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes" : `var'2
			estadd local strata_final "Yes" : `var'2
			
			* calculate control group mean
				* take endline mean to control for time trend
			sum `var' if treatment == 0 & surveyround == 3
			estadd scalar control_mean = r(mean) : `var'2
			estadd scalar control_sd = r(sd) : `var'2
		
		
	}
}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "${figures_innovation}/rt_`generate'.tex", replace ///
				prehead("\begin{table}[H] \centering \\ \caption{Innovation: Improved or New Products} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{5}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 // adjust manually to number of variables 
		esttab `regressions' using "${figures_innovation}/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\midrule \\ \multicolumn{5}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{5}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: All dependent variables are dummies [0;1]. Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Panel A reports ANCOVA estimates as defined in \citet{McKenzie.2012}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors in parentheses are clustered on the consortia-level for treatment group firms and on the firm-level for control group firms following \citet{Cai.2018}. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}")  // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Improved product (ITT)"' `1'2 = `"Improved product (TOT)"' `2'1 = `"New Product (ITT)"' `2'2 = `"New Product (TOT)"' `3'1 = `"Both (ITT)"' `3'2 = `"Both (TOT)"' `4'1 = `"None (ITT)"' `4'2 = `"None (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_kt inno_improve inno_new inno_both inno_none, gen(ktinno)

}

**************** inno_proc ****************

{
capture program drop rct_regression_ktpro // enables re-running
program rct_regression_ktpro
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
			
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes" : `var'1
			estadd local strata_final "Yes" : `var'1

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes" : `var'2
			estadd local strata_final "Yes" : `var'2
			
			* calculate control group mean
				* take endline mean to control for time trend
			sum `var' if treatment == 0 & surveyround == 3
			estadd scalar control_mean = r(mean) : `var'2
			estadd scalar control_sd = r(sd) : `var'2
	}
	else {
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes" : `var'1
			estadd local strata_final "Yes" : `var'1

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes" : `var'2
			estadd local strata_final "Yes" : `var'2
			
			* calculate control group mean
				* take endline mean to control for time trend
			sum `var' if treatment == 0 & surveyround == 3
			estadd scalar control_mean = r(mean) : `var'2
			estadd scalar control_sd = r(sd) : `var'2
		
		
	}
}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "${figures_innovation}/rt_`generate'.tex", replace ///
				prehead("\begin{table}[H] \centering \\ \caption{Innovation: Improved or New Products} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{6}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels("\shortstack{Production\\Technology}" "\shortstack{Marketing//Channels}" "\shortstack{Pricing\\Methods}" "\shortstack{Suppliers}" "Other") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "${figures_innovation}/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\midrule \\ \multicolumn{6}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{5}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: All dependent variables are dummies [0;1]. Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Panel A reports ANCOVA estimates as defined in \citet{McKenzie.2012}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors in parentheses are clustered on the consortia-level for treatment group firms and on the firm-level for control group firms following \citet{Cai.2018}. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}")  // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
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
		eqrename(`1'1 = `"Production technology (ITT)"' `1'2 = `"Production technology (TOT)"' `2'1 = `"Marketing channels (ITT)"' `2'2 = `"Marketing channels (TOT)"' `3'1 = `"Pricing methods (ITT)"' `3'2 = `"Pricing methods (TOT)"' `4'1 = `"Suppliers (ITT)"' `4'2 = `"Suppliers (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_ktpro inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres, gen(inno_process)

}

**************** inno_mot ****************

{
capture program drop rct_regression_ktmot // enables re-running
program rct_regression_ktmot
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
					* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
					* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
			}
else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
					* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
					* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
						
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
	}
}		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // `10'1  adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Innovation - Knowledge Sources} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{0.9\linewidth}{l>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{6}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels("Consultant" "Entrepreneur" "Event" "Client" "Other") ///	
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", append booktabs ///
				fragment ///
				posthead("\addlinespace[0.4cm]  \midrule \\ \multicolumn{6}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\addlinespace[0.4cm]  \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{0.9\linewidth}{% \textit{Notes}: The outcome variables are either zero or one. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.5(.1).5) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Innovation - Sources") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Events (ITT)"' `3'2 = `"Events (TOT)"' `4'1 = `"Clients (ITT)"' `4'2 = `"Clients (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "Control means are `fmt_c_m_`1'' (Consultants), `fmt_c_m_`2'' (Entrepreneurs), `fmt_c_m_`3'' (Events), & `fmt_c_m_`4'' (Clients)." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		leg(off) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace


		* cfp 1: direction & significance (CI)
coefplot ///
(`1'1,  pstyle(p1)) ///
(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(small)) ///
(`2'1, pstyle(p2)) ///
(`2'2, pstyle(p2) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(small)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Innovation - Sources") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Events (ITT)"' `3'2 = `"Events (TOT)"' `4'1 = `"Clients (ITT)"' `4'2 = `"Clients (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "Control means are `fmt_c_m_`1'' (Consultants), `fmt_c_m_`2'' (Entrepreneurs), `fmt_c_m_`3'' (Events), & `fmt_c_m_`4'' (Clients)." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot1, replace)
gr export "${figures_innovation}/el_`generate'_cfplot1.pdf", replace


		* cfp 2: magnitude & significance (p-value)
coefplot ///
(`1'1,  pstyle(p1)) ///
(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(small)) ///
(`2'1, pstyle(p2)) ///
(`2'2, pstyle(p2) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``2'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(small)) ///
	(`3'1, pstyle(p3)) ///
	(`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) ///
	(`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) ///
	(`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Innovation - Sources") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Events (ITT)"' `3'2 = `"Events (TOT)"' `4'1 = `"Clients (ITT)"' `4'2 = `"Clients (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "Control means are `fmt_c_m_`1'' (Consultants), `fmt_c_m_`2'' (Entrepreneurs), `fmt_c_m_`3'' (Events), & `fmt_c_m_`4'' (Clients)." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot2, replace)
gr export "${figures_innovation}/el_`generate'_cfplot2.pdf", replace


end

	* apply program to inspiration/motivation for innovation
rct_regression_ktmot inno_mot_cons inno_mot_cont inno_mot_eve inno_mot_client inno_mot_dummyother, gen(ktmot)

}


**************** ipi vars ****************

{
capture program drop rct_regression_ipivars // enables re-running
program rct_regression_ipivars
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Source of innovations} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
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
		eqrename(`1'1 = `"Production process (ITT)"' `1'2 = `"Production process (TOT)"' `2'1 = `"Sales & marketing (ITT)"' `2'2 = `"Sales & marketing (TOT)"' `3'1 = `"Management & organization (ITT)"' `3'2 = `"Management & organization (TOT)"' `4'1 = `"Product improvement (ITT)"' `4'2 = `"Product improvement (TOT)"' `5'1 = `"New product (ITT)"' `5'2 = `"New product (TOT)"') ///
		title("Innovation") ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_ipivars proc_prod_correct proc_mark_correct inno_org_correct inno_product_imp inno_product_new, gen(ipivars)

}
}


***********************************************************************
* 	PART 11: endline results - MANAGEMENT - knowledge transfer
***********************************************************************
**************** memory limit clear all and reload ****************
{
clear all
{
use "${master_final}/consortium_final", clear

/*	* export dta file for Michael Anderson
preserve
keep id_plateforme surveyround treatment take_up *net_size *net_nb_f *net_nb_m *net_nb_qualite *net_coop_pos strata_final
save "${master_final}/sample.dta", replace
restore
*/

* export dta file for Damian Clarke
/*
preserve
keep id_plateforme surveyround treatment take_up *genderi *female_efficacy *female_loc strata_final
save "${master_final}/sample_clarke.dta", replace
restore
*/	
		* change directory
cd "${master_regressiontables}/endline/regressions/management"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on

		* set color scheme
if "`c(username)'" == "MUNCHFA" | "`c(username)'" == "fmuench"  {
	set scheme stcolor
} 
	else {

set scheme s1color
		
	}
}

**************** TABLES FOR PAPER ****************
{
capture program drop rct_management_ml_el // enables re-running
program rct_management_ml_el
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// (surveyround == 2)
				eststo `var'1_ml: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 2, cluster(consortia_cluster)
				estadd local bl_control "Yes" : `var'1_ml
				estadd local strata_final "Yes" : `var'1_ml

				eststo `var'2_ml: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 2, cluster(consortia_cluster) first
				estadd local bl_control "Yes" : `var'2_ml
				estadd local strata_final "Yes" : `var'2_ml

				sum `var' if treatment == 0 & surveyround == 2
				estadd scalar control_mean = r(mean) : `var'2_ml
				estadd scalar control_sd = r(sd) : `var'2_ml

				//  (surveyround == 3)
				eststo `var'1_el: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes" : `var'1_el
				estadd local strata_final "Yes" : `var'1_el

				eststo `var'2_el: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes" : `var'2_el
				estadd local strata_final "Yes" : `var'2_el

				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean) : `var'2_el
				estadd scalar control_sd = r(sd) : `var'2_el
			}
			else {
				// (surveyround == 2)
				eststo `var'1_ml: reg `var' i.treatment i.strata_final if surveyround == 2, cluster(consortia_cluster)
				estadd local bl_control "No" : `var'1_ml
				estadd local strata_final "Yes" : `var'1_ml

				eststo `var'2_ml: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 2, cluster(consortia_cluster) first
				estadd local bl_control "No" : `var'2_ml
				estadd local strata_final "Yes" : `var'2_ml

				sum `var' if treatment == 0 & surveyround == 2
				estadd scalar control_mean = r(mean) : `var'2_ml
				estadd scalar control_sd = r(sd) : `var'2_ml

				//  (surveyround == 3)
				eststo `var'1_el: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No" : `var'1_el
				estadd local strata_final "Yes" : `var'1_el

				eststo `var'2_el: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No" : `var'2_el
				estadd local strata_final "Yes" : `var'2_el

				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean) : `var'2_el
				estadd scalar control_sd = r(sd) : `var'2_el
        }

}

tokenize `varlist'
/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
	
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1_ml `1'1_el   // `2'1_ml `2'1_el adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Management Practices Index (MPI): ML and EL} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{3}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels("\shortstack{ML\\ MPI}" "\shortstack{EL\\ MPI}") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final *_y0 ?.missing_bl_*) ///  L.* oL.* ?.missing_bl_*  *_y0
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2_ml `1'2_el  // `2'2_ml `2'2_el adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{3}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3))) ///  p(fmt(3)) rw ci(fmt(2))
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final *_y0 ?.missing_bl_*) ///  L.* `5' `6' ?.missing_bl_*  *_y0
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: All dependent variables are indexes calculated based on z-scores as described in \citet{Anderson.2008}. Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Panel A reports ANCOVA estimates as defined in \citet{McKenzie.2012}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors in parentheses are clustered on the consortia-level for treatment group firms and on the firm-level for control group firms following \citet{Cai.2018}. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.
end

	* apply program to mp index
rct_management_ml_el mpi, gen(mpi_paper)

	* apply program to mp rate for comparison of treatment effect size with Bloom et al. 2013, 2020
rct_management_ml_el mpi_rate, gen(mpi_rate)

}








**************** Deep dive management practices (10 vars) ****************
capture program drop deep_man_el // enables re-running
program deep_man_el
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
					* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
					* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
			}
else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
					* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
					* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
						
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
	}
}		
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Management practices - Knowledge Sources} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{0.9\linewidth}{l>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{11}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels("\shortstack{KPIs}" "\shortstack{Prod-\\uction}" "\shortstack{Input}" "\shortstack{Stock}" "\shortstack{Empl-\\oyees}" "\shortstack{Logis-\\tics}" "\shortstack{KPIs\\ Freq.}" "\shortstack{Bud-\\get}" "\shortstack{Cost\\ estimate}" "\shortstack{Business/\\ private}") ///	
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", append booktabs ///
				fragment ///
				posthead("\addlinespace[0.4cm]  \midrule \\ \multicolumn{11}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\addlinespace[0.4cm]  \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{11}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{0.9\linewidth}{% \textit{Notes}: The outcome variables are either zero or one. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				
end

deep_man_el man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis, gen(deep_man)

**************** TABLES FOR PRESENTATION ****************
{
**************** Management index mpi ****************
capture program drop mpi_presentation // enables re-running
program mpi_presentation
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100			
				
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100		
        }
	}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge Transfer - Management Practices Index} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{3}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{2}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{2}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 95 percent level, corresponding to three extreme values. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are clustered at the individual firm-level for the control group and at the consortia level for treatment group firms.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)), ///
	keep(*treatment take_up) drop(_cons) xline(0) /// xlabel(0(1)10)
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Management Practices z-score (ITT)"' `1'2 = `"Management Practices z-score (TOT)"') ///
		xtitle("Treatment Effect", size(medsmall)) ///  
		leg(off) xsize(10) ysize(6) /// xsize controls aspect ratio, makes graph wider & reduces its height 
		note("{bf:Note}:" "The control endline median is `fmt_c_m_`1'' and SD is `fmt_sd_`1''." "Number of observations is `fmt_nobs_`1''." "Confidence intervals are at the 95 percent level." "Variables are z-scores following Anderson (2008)." "Z-score based on 10 management practice variables correlated with Bloom et al. (2013).", span size(medium)) ///
		name(el_`generate'_cfp, replace)
gr export "${figures_management}/el_`generate'_cfp.pdf", replace	
*gr export "${master_regressiontables}/endline/regressions/management/el_`generate'_cfp.png", replace


end
	
mpi_presentation mpi, gen(mpi)	


**************** man_fin_per (6 vars) ****************
{
capture program drop rct_regression_indic // enables re-running
program rct_regression_indic
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		capture confirm variable `var'_y0
        if _rc == 0 {
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		else {
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
	}
}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management indicators} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. % \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				// P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Financial indicators (ITT)"' `1'2 = `"Financial indicators (TOT)"' `2'1 = `"Production management (ITT)"' `2'2 = `"Production management (TOT)"' `3'1 = `"Input quality (ITT)"' `3'2 = `"Input quality (TOT)"' `4'1 = `"Stock (ITT)"' `4'2 = `"Stock (TOT)"' `5'1 = `"Employee (ITT)"' `5'2 = `"Employee performance (TOT)"' `6'1 = `"Timely delivery (ITT)"' `6'2 = `"Timely deliveryock (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export "${master_regressiontables}/endline/regressions/management/el_`generate'_cfplot.png", replace

end

	* apply to monitored firm performance outcomes
rct_regression_indic man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv, gen(indic)

}

**************** man_fin_fre (1 var) ****************
{
capture program drop rct_regression_fre // enables re-running
program rct_regression_fre
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		capture confirm variable `var'_y0
        if _rc == 0 {
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		else {
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
	}
}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management indicators frequency} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Indicators tracking frequency (ITT)"' `1'2 = `"Indicators tracking frequency (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to frequency of monitoring performance outcomes
rct_regression_fre man_fin_per, gen(freq)

}

**************** man_fin_pra (3 vars) ****************
{
capture program drop rct_regression_manpra // enables re-running
program rct_regression_manpra
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		capture confirm variable `var'_y0
        if _rc == 0 {
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		else {
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
	}
}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1   // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management practices} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2   // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Business plan `=char(13)'`=char(10)' & budget (ITT)"' `1'2 = `"Business plan `=char(13)'`=char(10)' & budget (TOT)"' `2'1 = `"Calculate costs `=char(13)'`=char(10)' & profit (ITT)"' `2'2 = `"Calculate costs `=char(13)'`=char(10)' & profit  (TOT)"' `3'1 = `"Distinguish personal `=char(13)'`=char(10)' & business accounts (ITT)"' `3'2 = `"Distinguish personal `=char(13)'`=char(10)' & business accounts (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///
		ysc(outergap(-35)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export "${master_regressiontables}/endline/regressions/management/el_`generate'_cfplot.png", replace

end

	* apply program to export outcomes
rct_regression_manpra man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis, gen(manpra)

}

**************** man_source ****************

{
capture program drop rct_regression_mans // enables re-running
program rct_regression_mans
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
					* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''


				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
					* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
			}
else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
					* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
					* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
						
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
	}
}		
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // `10'1  adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Management practices - Knowledge Sources} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{0.9\linewidth}{l>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{7}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels("Consultant" "Entrepreneur" "Family/ Friend" "Event" "Training" "Other") ///	
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
		esttab `regressions' using "${tables_kt}/rt_`generate'.tex", append booktabs ///
				fragment ///
				posthead("\addlinespace[0.4cm]  \midrule \\ \multicolumn{7}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\addlinespace[0.4cm]  \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{0.9\linewidth}{% \textit{Notes}: The outcome variables are either zero or one. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.5(.1).5) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Family & Friends (ITT)"' `3'2 = `"Family & Friends (TOT)"' `4'1 = `"Events (ITT)"' `4'2 = `"Events (TOT)"' `5'1 = `"Training (ITT)"' `5'2 = `"Training (TOT)"' `6'1 = `"Other (ITT)"' `6'2 = `"Other (TOT)"') ///
		title("New Management Practices", size(medium)) ///
		subtitle("Sources", size(medsmall)) ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(0)) ///
		note("{bf:Note}: The Consultant (TOT) is significant at the 10% level.", span) ///
		name(el_`generate'_cfplot, replace)
gr export "${master_regressiontables}/endline/regressions/management/el_`generate'_cfplot.png", replace


		* cfp 1: direction & significance (CI)
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.6(0.1)0.6) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Management Practices - Sources") ///
		levels(95) ///
		ysize(7) xsize(12) /// specifies 16:9 height width ratio for whole graph as in latex presentation
	eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Family & Friends (ITT)"' `3'2 = `"Family & Friends (TOT)"' `4'1 = `"Events (ITT)"' `4'2 = `"Events (TOT)"' `5'1 = `"Training (ITT)"' `5'2 = `"Training (TOT)"' `6'1 = `"Other (ITT)"' `6'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "Control means [SD] are `fmt_c_m_`1'' [`fmt_sd_`1''] (Consultants), `fmt_c_m_`3'' [`fmt_sd_`3''] (Family/Friends), `fmt_c_m_`5'' [`fmt_sd_`5''] (Training)." "Number of observations is `fmt_nobs_`1''." "Variables are binary [0;1]." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot1, replace)
gr export "${figures_management}/el_`generate'_cfplot1.pdf", replace


		* cfp 2: magnitude & significance (p-value)
coefplot ///
(`1'1,  pstyle(p1)) ///
(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medsmall)) ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)) ///
(`3'1, pstyle(p3)) ///
(`3'2, pstyle(p3) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medsmall)) ///
	(`4'1, pstyle(p4)) ///
	(`4'2, pstyle(p4)) ///
(`5'1, pstyle(p5)) ///
(`5'2, pstyle(p5) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medsmall)) ///
	(`6'1, pstyle(p6)) ///
	(`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.6(0.1)0.6) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Management Practices - Sources") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
	eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Family & Friends (ITT)"' `3'2 = `"Family & Friends (TOT)"' `4'1 = `"Events (ITT)"' `4'2 = `"Events (TOT)"' `5'1 = `"Training (ITT)"' `5'2 = `"Training (TOT)"' `6'1 = `"Other (ITT)"' `6'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "Control means are `fmt_c_m_`1'' (Consultants), `fmt_c_m_`3'' (Family/Friends), `fmt_c_m_`5'' (Training)." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot2, replace)
gr export "${figures_management}/el_`generate'_cfplot2.pdf", replace



		* cfp 3: magnitude & significance (p-value)
coefplot ///
(`1'1,  pstyle(p1)) ///
(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " or " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medsmall)) ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)) ///
(`3'1, pstyle(p3)) ///
(`3'2, pstyle(p3) ///
	mlabel(string(@b, "%9.2f") + " or " + string(``3'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medsmall)) ///
	(`4'1, pstyle(p4)) ///
	(`4'2, pstyle(p4)) ///
(`5'1, pstyle(p5)) ///
(`5'2, pstyle(p5) ///
	mlabel(string(@b, "%9.2f") + " or " + string(``5'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medsmall)) ///
	(`6'1, pstyle(p6)) ///
	(`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.6(0.1)0.6) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(12) /// specifies 16:9 height width ratio for whole graph as in latex presentation
	eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Family & Friends (ITT)"' `3'2 = `"Family & Friends (TOT)"' `4'1 = `"Events (ITT)"' `4'2 = `"Events (TOT)"' `5'1 = `"Training (ITT)"' `5'2 = `"Training (TOT)"' `6'1 = `"Other (ITT)"' `6'2 = `"Other (TOT)"') ///
		xtitle("Sources Management Practices", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "Control means [SD]: `fmt_c_m_`1'' [`fmt_sd_`1''] (Consultants), `fmt_c_m_`3'' [`fmt_sd_`3''] (Family & Friends), & `fmt_c_m_`5'' [`fmt_sd_`5''] (Training)." "Number of observations is `fmt_nobs_`1''. Variables are binary [0;1]." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot3, replace)
gr export "${figures_management}/el_`generate'_cfplot3.pdf", replace


end

	* apply program to sources of management practices
rct_regression_mans man_source_cons man_source_pdg man_source_fam man_source_even man_source_formation man_source_autres, gen(mans)

}

}

}


***********************************************************************
* 	PART 12: endline results - EXPORT READINESS
***********************************************************************
{
capture program drop eri_presentation // enables re-running
program eri_presentation
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately		
			capture confirm variable `var'_y0
			if _rc == 0 {
			// ITT: ANCOVA plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''

			// ATT, IV
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
					
			// Calculate control group mean
			sum `var' if treatment == 0 & surveyround == 3, d
				* for latex table
			estadd scalar control_median = r(p50) : `var'2
			estadd scalar control_sd = r(sd) : `var'2
				* for coefplots
			local c_m_`var' = r(p50)
			local fmt_c_m_`var' : display  %3.2f `c_m_`var''			
			local sd_`var' = r(sd)
			local fmt_sd_`var' : display  %3.2f `sd_`var''

        }
        else {
            // ITT: ANCOVA plus stratification dummies
            eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''

            // ATT, IV
            eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
			
        }
}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 // adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge Transfer - Export Readiness Index} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{0.9\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{3}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2  // adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", append booktabs ///
				fragment ///
				posthead("\midrule \\ \multicolumn{3}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{0.9\linewidth}{% \textit{Notes}: The outcomes are z-scores calculated as in \citet{Anderson.2008}. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable when available. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium) ///
	) ///
	(`2'2, pstyle(p2) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium) ///
	), ///
	keep(*treatment take_up) drop(_cons) xline(0) /// xlabel(0(1)10)
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Export Readiness Index, General (ITT)"' `1'2 = `"Export Readiness Index, General (TOT)"' `2'1 = `"Export Readiness Index, SSA (ITT)"' `2'2 = `"Export Readiness Index, SSA (TOT)"') ///
		xtitle("Treatment Effect", size(medsmall)) ///  
		leg(off) xsize(10) ysize(5) /// xsize controls aspect ratio, makes graph wider & reduces its height 
		note("{bf:Note}:" "The control endline median ERI SSA is `fmt_c_m_`1'' and SD is `fmt_sd_`1''." "Number of observations is `fmt_nobs_`1''." "Confidence intervals are at the 95 percent level." "Variables are z-scores following Anderson (2008).", span size(medium)) ///
		name(el_`generate'_cfp, replace)
gr export "${figures_exports}/el_`generate'_cfp.pdf", replace


end
	
	* apply program to export readiness index
eri_presentation eri eri_ssa, gen(eri)	


**************** exp_pra ****************
{
capture program drop rct_regression_expra // enables re-running
program rct_regression_expra
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately		
			capture confirm variable `var'_y0
			if _rc == 0 {
			// ITT: ANCOVA plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
					* add to latex table
				estadd local bl_control "Yes" : `var'1
				estadd local strata_final "Yes" : `var'1
					* add to coefplot
				local itt_`var' = r(table)[1,2]
				local fmt_itt_`var' : display %3.2f `itt_`var''	
				local nobs_`var' = e(N)
				local fmt_nobs_`var' : display %3.0f `nobs_`var''

			// ATT, IV
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	

			// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''

        }
        else {
            // ITT: ANCOVA plus stratification dummies
            eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
					
					
            // ATT, IV
            eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
            
            // Calculate control group mean
            sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
        }
}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge Transfer - Export Readiness General: Sub-componenents} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{0.9\linewidth}{l>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{6}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels("\shortstack{Export \\ manager}" "\shortstack{Trade \\ Fair}" "\shortstack{Business \\ Partner}" "\shortstack{Intl. \\ Certification}" "\shortstack{Sales \\ structure}") ///	
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", append booktabs ///
				fragment ///
				posthead("\addlinespace[0.4cm]  \midrule \\ \multicolumn{6}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\addlinespace[0.4cm]  \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{0.9\linewidth}{% \textit{Notes}: The outcome variables are either zero or one. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)  ///
		mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
		mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///	
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///	
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p4)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.75(0.25)0.75) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		title("Export Readiness") ///
		subtitle("General") ///
		eqrename(`1'1 = `"Export manager (ITT)"' `1'2 = `"Export manager (TOT)"' `2'1 = `"Trade fair (ITT)"' `2'2 = `"Trade fair (TOT)"' `3'1 = `"Business partner (ITT)"' `3'2 = `"Business partner  (TOT)"' `4'1 = `"Intl. certification (ITT)"' `4'2 = `"Intl. certification (TOT)"' `5'1 = `"Sales structure (ITT)"' `5'2 = `"Sales structure (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(12) ysize(6) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control endline median for trade fair is `fmt_c_m_`2'' and SD is `fmt_sd_`2''." "Number of observations is `fmt_nobs_`2''." "Confidence intervals are at the 95 percent level." "Variables are binary [0;1].", span size(medium)) ///
		name(el_`generate'_cfplot, replace)
gr export "${figures_exports}/el_`generate'_cfp.pdf", replace

end

	* apply program to export outcomes
rct_regression_expra exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent, gen(expra)

}




**************** exp_pra_SSA ****************
{
capture program drop rct_regression_expraSSA // enables re-running
program rct_regression_expraSSA
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately		
			capture confirm variable `var'_y0
			if _rc == 0 {
			// ITT: ANCOVA plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''

			// ATT, IV
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	

			// Calculate control group mean
			sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''

        }
        else {
            // ITT: ANCOVA plus stratification dummies
            eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
					
					
            // ATT, IV
            eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
            
            // Calculate control group mean
            sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(p50)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
        }
}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*
		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge Transfer - Export Readiness Subsahara-Africa: Sub-componenents} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{0.9\linewidth}{l>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X>{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{5}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				mlabels("Client" "Business Partner" "Funding" "Sales structure") ///	
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.*
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 // adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", append booktabs ///
				fragment ///
				posthead("\addlinespace[0.4cm]  \midrule \\ \multicolumn{5}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\addlinespace[0.4cm]  \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{5}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{0.9\linewidth}{% \textit{Notes}: The outcome variables are either zero or one. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
						* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1) ///
		mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
		mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2) ///
		mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
		mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///	
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3) ///
		mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
		mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///	
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		title("Export Readiness") ///
		subtitle("Sub-Sahara Africa") ///
		eqrename(`1'1 = `"Potential client (ITT)"' `1'2 = `"Potential client (TOT)"' `2'1 = `"Business partner (ITT)"' `2'2 = `"Business partner (TOT)"' `3'1 = `"Funding (ITT)"' `3'2 = `"Funding (TOT)"' `4'1 = `"Sales structure (ITT)"' `4'2 = `"Sales structure (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(12) ysize(6) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "Control endline medians [SD]: `fmt_c_m_`1'' [`fmt_sd_`1''] (Client), `fmt_c_m_`2'' [`fmt_sd_`2''] (Partner), & `fmt_c_m_`3'' [`fmt_sd_`3''] (Funding)." "Number of observations is `fmt_nobs_`2''." "Confidence intervals are at the 95 percent level." "Variables are binary [0;1].", span size(medium)) ///		
		name(el_`generate'_cfplot, replace)
gr export "${figures_exports}/el_`generate'_cfp.pdf", replace


end
	
	* apply program to outcomes
rct_regression_expraSSA ssa_action1 ssa_action2 ssa_action3 ssa_action4, gen(expraSSA)

}



**************** expp_cost ****************

{
capture program drop rct_regression_expcost // enables re-running
program rct_regression_expcost
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export costs & benefits perception} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Export costs (ITT)"' `1'2 = `"Export costs (TOT)"' `2'1 = `"Export benefits (ITT)"' `2'2 = `"Export benefits (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_expcost expp_cost expp_ben, gen(expcost)

}

}
}

***********************************************************************
* 	PART 13: endline results - EXPORT - intensive & extensive margin
***********************************************************************
{
**************** export - extensive margin ****************
{
	* change directory
cd "${master_regressiontables}/endline/regressions/export"

*** explorative
{
capture program drop rct_regression_exp // enables re-running
program rct_regression_exp
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Exporting table} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"' `3'1 = `"Export sales > 0, 2023 (ITT)"' `3'2 = `"Export sales > 0, 2023 (TOT)"'  `4'1 = `"Export sales > 0, 2024 (ITT)"' `4'2 = `"Export sales > 0, 2024 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export - extensive margin
rct_regression_exp export_1 export_2 exported exported_2024, gen(exp_ext)

}

reg export_1 i.treatment exported_y0 missing_bl_exported i.strata_final if surveyround == 3 & bh_sample == 1, cluster(consortia_cluster)
ivreg2 export_1 exported_y0 missing_bl_exported (take_up = i.treatment) if surveyround == 3 & bh_sample == 1, cluster(consortia_cluster) first


reg ihs_ca_w95_k1 i.treatment ihs_ca_w95_k1_y0 missing_bl_ihs_ca_w95_k1 i.strata_final if surveyround == 3 & bh_sample == 1, cluster(consortia_cluster)
ivreg2 ihs_ca_w95_k1 ihs_ca_w95_k1_y0 missing_bl_ihs_ca_w95_k1 (take_up = i.treatment) if surveyround == 3 & bh_sample == 1, cluster(consortia_cluster) first

*** Tables for presentation
{
capture program drop exp_ext // enables re-running
program exp_ext
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar control_mean = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local control_mean_`var' = r(mean)
					local fmt_control_mean_`var' : display  %3.2f `control_mean_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_control_mean_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_control_mean_`var'')*100			
				
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''
					local nobs_`var' = e(N)
					local fmt_nobs_`var' : display %3.0f `nobs_`var''

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar control_mean = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local control_mean_`var' = r(mean)
					local fmt_control_mean_`var' : display  %3.2f `control_mean_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_control_mean_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_control_mean_`var'')*100		
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Exporting table} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplots
{
* retrieve & format TOT TE
*local te_`1' = e(b)[1,1]
*local fmt_te_`1' : display %3.2f `te_`1''

	* retrieve & format control mean
*sum `1' if treatment == 0 & surveyround == 3
*local control_mean_`1' = r(mean)
*local fmt_control_mean_`1' : display  %3.2f `control_mean_`1''

	* calculate percent increase
*local `1'_per = (`fmt_te_`1'' / `fmt_control_mean_`1'')*100

		* cfp 1: direction & significance (CI)
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Exported in 2023/24") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "The control group endline average direct export is `fmt_control_mean_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot1, replace)
gr export el_`generate'_cfplot1.pdf, replace


		* cfp 2: magnitude & significance (p-value)
coefplot ///
	(`1'1,  pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2) mlabsize(medium))  ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Exported in 2023/24") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "The control group endline average direct export is `fmt_control_mean_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot2, replace)
gr export el_`generate'_cfplot2.pdf, replace


		* cfp 3: comparison with other studies
coefplot ///
	(`1'1,  pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") ///
	mlabposition(12) mlabgap(*2) mlabsize(medium))  ///
	(`1'2, pstyle(p1) ///
	mlabel("0.09 in Makioka (2021, JPN)") ///
	mlabposition(0) mlabgap(*2) offset(-0.15) msymbol(none) noci mlabsize(medium))  ///
	(`1'2, pstyle(p1) ///
	mlabel("0.08 pp in Munch & Schaur (2018, DNK)") ///
	mlabposition(6) mlabgap(*2) offset(-0.25) msymbol(none) noci mlabsize(medium))  ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Exported in 2023/24") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "The control group endline average direct export is `fmt_control_mean_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot3, replace)
gr export el_`generate'_cfplot3.pdf, replace


coefplot ///
	(`1'1,  pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") ///
	mlabposition(12) mlabgap(*2) mlabsize(medium))  ///
	(`1'2, pstyle(p1) ///
	mlabel("0.09 in Makioka (2021, JPN)") ///
	mlabposition(0) mlabgap(*2) offset(-0.15) msymbol(none) noci mlabsize(medium))  ///
	(`1'2, pstyle(p1) ///
	mlabel("0.08 pp in Munch & Schaur (2018, DNK)") ///
	mlabposition(6) mlabgap(*2) offset(-0.25) msymbol(none) noci mlabsize(medium)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Direct Export [0;1] 2023/2024 (ITT)"' `1'2 = `"Direct Export [0;1] 2023/2024 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "The control group endline average [SD] direct export is `fmt_control_mean_`1'' [`fmt_sd_`1'']." "Number of observations is `fmt_nobs_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot4, replace)
gr export "${figures_export}/el_`generate'_cfplot4.jpg", replace	

*gr export el_`generate'_cfplot3.pdf, replace	
		
		
}
		
 // need to test this:
//https://www.statalist.org/forums/forum/general-stata-discussion/general/1577775-placing-text-label-above-and-below-marker-in-a-coefplot-generated-plot

	// https://www.statalist.org/forums/forum/general-stata-discussion/general/1500621-formatting-numbers-saved-in-a-local-and-using-these-in-a-text-output
	
end

	* apply program to export - extensive margin
exp_ext export_1 export_2, gen(exp_ext)

}


*** Tables for paper
egen bl_operation_export = min(operation_export), by(id_plateforme) // to test - robust, no change to results if included as BL 0 controls.
lab var export_1 "Exported (Yes = 1)"
{
capture program drop exp_ext // enables re-running
program exp_ext
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately
		  local conds `" "surveyround == 3" "surveyround == 3 & bh_sample == 1" "'
		  local i = 1 			
		  foreach cond of local conds {
			capture confirm variable `var'_y0
			if `var' == exp_pays_w95 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1`i': reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if `cond', cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1`i'
					estadd local strata "Yes" : `var'1`i'
						* add to coefplot
					local itt_`var'`i' = r(table)[1,2]
					local fmt_itt_`var'`i' : display %3.2f `itt_`var'`i''
				
				// ATT, IV
				eststo `var'2`i': ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if `cond', cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2`i'
					estadd local strata "Yes" : `var'2`i'
						* add to coefplot
					local att_`var'`i' = e(b)[1,1]
					local fmt_att_`var'`i' : display %3.2f `att_`var'`i''
					
				
				// Calculate control group mean
				sum `var' if treatment == 0 & `cond'
						* for latex table
					estadd scalar control_mean = r(mean) : `var'2`i'
					estadd scalar control_sd = r(sd) :  `var'2`i'
						* for  coefplots
					local control_mean_`var'`i' = r(mean)
					local fmt_control_mean_`var'`i' : display  %3.2f `control_mean_`var'`i''
					
					// Calculate percent change
					local `var'`i'_per_itt = (`fmt_itt_`var'`i'' / `fmt_control_mean_`var'`i'')*100			
					local `var'`i'_per_att = (`fmt_att_`var'`i'' / `fmt_control_mean_`var'`i'')*100
				
			}
			else {
				// ITT: ANCOVA plus stratification dummies
					// not accounting for differential attrition
				eststo `var'1`i': reg `var' i.treatment exported_y0 missing_bl_exported i.strata_final if `cond', cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1`i'
					estadd local strata_final "Yes" : `var'1`i'
						* add to coefplot
					local itt_`var'`i' = r(table)[1,2]
					local fmt_itt_`var'`i' : display %3.2f `itt_`var'`i''	

				
				// ATT, IV
				eststo `var'2`i': ivreg2 `var' exported_y0 missing_bl_exported i.strata_final (take_up = i.treatment) if `cond', cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2`i' 
					estadd local strata "Yes" : `var'2`i'
						* add to coefplot
					local att_`var'`i' = e(b)[1,1]
					local fmt_att_`var'`i' : display %3.2f `att_`var'`i''			
				
				// Calculate control group mean
				sum `var' if treatment == 0 & `cond'
						* for latex table
					estadd scalar control_mean = r(mean) : `var'2`i'
					estadd scalar control_sd = r(sd) : `var'2`i'
						* for  coefplots
					local control_mean_`var'`i' = r(mean)
					local fmt_control_mean_`var'`i' : display  %3.2f `control_mean_`var'`i''
					
					// Calculate percent change
					local `var'`i'_per_itt = (`fmt_itt_`var'`i'' / `fmt_control_mean_`var'`i'')*100			
					local `var'`i'_per_att = (`fmt_att_`var'`i'' / `fmt_control_mean_`var'`i'')*100
			}
		local i = `i' + 1	
        }
	}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
	* Table only with outcomes w/o accounting for attrition	
			* Top panel: ITT
		local regressions `1'11 `2'11 //  adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export: Market Access Intensive and Extensive Margins} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{3}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) ci(fmt(2)) rw
				mlabels(, depvars) /// use dep vars labels as model title
 /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final *_y0 *missing_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'21 `2'21 //  adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{3}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) ci(fmt(2)) rw
				stats(control_mean control_sd N bl_control strata, fmt(%9.2fc %9.2fc %9.0g) labels("EL control group mean" "EL control group SD" "Observations" "BL controls" "Strata controls")) ///
				drop(_cons *.strata_final *_y0 *missing_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: The outcome variable 'Exported' is based on firms' survey response to whether they exported in 2023 or the first six month of 2024. The 'Export countries' variable is winsorized at the 95th percentile as pre-specified. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after each % sign and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications%
				
	* Table for outcomes w/o & with accounting for attrition for comparison	
			* Top panel: ITT
		local regressions `1'11 `1'12 `2'11 `2'12 //  adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'_attrit.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export: Market Access Intensive and Extensive Margins} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{5}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) ci(fmt(2)) rw
				mlabels("\shortstack{Direct\\ Export}" "\shortstack{BH\\ Attrition}" "\shortstack{N. of \\ Export countries}" "\shortstack{BH\\ Attrition}") ///				
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final *_y0 *missing_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'21 `1'22 `2'21 `2'22 //  adjust manually to number of variables 
		esttab `regressions' using "${tables_exports}/rt_`generate'_attrit.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{5}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) ci(fmt(2)) rw
				stats(control_mean control_sd N bl_control strata, fmt(%9.2fc %9.2fc %9.0g) labels("EL control group mean" "EL control group SD" "Observations" "BL controls" "Strata controls")) ///
				drop(_cons *.strata_final *_y0 *missing_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{5}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: The outcome variable 'Exported' is based on firms' survey response to whether they exported in 2023 or the first six month of 2024. The 'Export countries' variable is winsorized at the 95th percentile as pre-specified. Attrition corrections are based on \citet{Behaghel2015}. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after each % sign and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications%
								
				
				
			* coefplots
{
/*		* cfp 1: direction & significance (CI)
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Exported in 2023/24") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "The control group endline average direct export is `fmt_control_mean_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot1, replace)
gr export el_`generate'_cfplot1.pdf, replace


		* cfp 2: magnitude & significance (p-value)
coefplot ///
	(`1'1,  pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2) mlabsize(medium))  ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Exported in 2023/24") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "The control group endline average direct export is `fmt_control_mean_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot2, replace)
gr export el_`generate'_cfplot2.pdf, replace

		
		* cfp 3: comparison with other studies
coefplot ///
	(`1'1,  pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``1'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") ///
	mlabposition(12) mlabgap(*2) mlabsize(medium))  ///
	(`1'2, pstyle(p1) ///
	mlabel("0.09 in Makioka (2021, JPN)") ///
	mlabposition(0) mlabgap(*2) offset(-0.15) msymbol(none) noci mlabsize(medium))  ///
	(`1'2, pstyle(p1) ///
	mlabel("0.08 pp in Munch & Schaur (2018, DNK)") ///
	mlabposition(6) mlabgap(*2) offset(-0.25) msymbol(none) noci mlabsize(medium))  ///
	(`2'1, pstyle(p2)) ///
	(`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-0.2(0.1)0.4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		title("Exported in 2023/24") ///
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
				note("{bf:Note}:" "The control group endline average direct export is `fmt_control_mean_`1''." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfplot3, replace)
gr export el_`generate'_cfplot3.pdf, replace	
*/		
		
}
		
 // need to test this:
//https://www.statalist.org/forums/forum/general-stata-discussion/general/1577775-placing-text-label-above-and-below-marker-in-a-coefplot-generated-plot

	// https://www.statalist.org/forums/forum/general-stata-discussion/general/1500621-formatting-numbers-saved-in-a-local-and-using-these-in-a-text-output
	
end

	* apply program to export - extensive margin
exp_ext export_1 exp_pays_w95, gen(exp_ext)

}






**************** Reason of not exporting reasons ****************
{
capture program drop rct_regression_noexp // enables re-running
program rct_regression_noexp
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export: Reasons of not exporting} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
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
		eqrename(`1'1 = `"High cost (ITT)"' `1'2 = `"High cost (TOT)"' `2'1 = `"No client (ITT)"' `2'2 = `"No client (TOT)"' `3'1 = `"Complicated (ITT)"' `3'2 = `"Complicated (TOT)"' `4'1 = `"Risk & uncertainty (ITT)"' `4'2 = `"Risk & uncertainty (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_noexp export_41 export_42 export_43 export_44 export_45, gen(noexp)

}

**************** export - intensive margin ****************
**************** export majors - sales, countries, countries ssa ****************
{
capture program drop exp_int // enables re-running
program exp_int
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100			
				
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100		
        }
		}

		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1  // `3'1 `4'1 `5'1 `6'1 `7'1 `8'1  adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions: export sensitivity to k} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2  // `3'2 `4'2 `5'2 `6'2 `7'2 `8'2  adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), /// (`3'1, pstyle(p3)) (`3'2, pstyle(p3))
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Export sales 2023 (ITT)"' `1'2 = `"Export sales 2023 (TOT)"' `2'1 = `"Export countries (ITT)"' `2'2 = `"Export countries (TOT)"') ///  `4'1 = `"Export countries SSA (ITT)"' `4'2 = `"Export countries SSA (TOT) "' `5'1 = `"Export k^3 2024 (ITT)"' `5'2 = `"Export k^3 2024 (TOT) "' `6'1 = `"Export k^3 2023 (ITT)"' `6'2 = `"Export k^3 2023 (TOT)"' `7'1 = `"Export k^4 2024 (ITT)"' `7'2 = `"Export k^4 2024 (TOT)"' `8'1 = `"Export k^4 2023 (ITT)"' `8'2 = `"Export k^4 2023 (TOT)"'
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The Export countries (TOT) is significant at the 10% level." "Export sales variables are winsorised & ihs-transformed.", span) ///
		name(el_`generate'_cfp, replace)

//  `2'1 = `"Export sales 2024 (ITT)"' `2'2 = `"Export sales 2024 (TOT)"'	
	
// (`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) /// (`6'1, pstyle(p6)) (`6'2, pstyle(p6)) /// (`7'1, pstyle(p7)) (`7'2, pstyle(p7)) /// (`8'1, pstyle(p8)) (`8'2, pstyle(p8))
	
// (`4'1, pstyle(p4)) (`4'2, pstyle(p4))
	
gr export el_`generate'_cfp.png, replace


		* cfp 1: direction & significance (CI)
coefplot ///
	(`2'1, pstyle(p1)) (`2'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-2(0.5)2) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(10) /// specifies 16:9 height width ratio for whole graph as in latex presentation
		eqrename(`2'1 = `"Export countries (ITT)"' `2'2 = `"Export countries  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "The control group endline average direct export is `fmt_c_m_`2''." "The Export countries (TOT) is significant at the 10% level." "Export countries are winsorised at the 95th percentile." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfp1, replace)
gr export el_`generate'_cfp1.pdf, replace


		* cfp 2: magnitude & significance (p-value)
coefplot ///
	(`2'1,  pstyle(p2) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``2'_per_itt', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
	(`2'2, pstyle(p2) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``2'_per_att', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2) mlabsize(medium)),  ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-2(0.5)2) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		ysize(5) xsize(10) /// specifies height width ratio for whole graph as in latex presentation
		eqlabels(, labsize(medium)) ///
		eqrename(`2'1 = `"Export countries (ITT)"' `2'2 = `"Export countries  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) /// 
		note("{bf:Note}:" "The control group endline average direct export is `fmt_c_m_`2''." "Export countries are winsorised at the 95th percentile." "Confidence intervals are at the 95 percent level.", span size(medium)) ///
		name(el_`generate'_cfp2, replace)
gr export el_`generate'_cfp2.pdf, replace

end

	* apply program to export outcomes
*exp_int ihs_ca_exp_w99_k1 exp_pays_w99, gen(exp_int_majors99) // ihs_caexp2024_w99_k1 exp_pays_ssa_w99

exp_int ihs_ca_exp_w95_k1 exp_pays_w95, gen(exp_int_majors95) // ihs_caexp2024_w95_k1 exp_pays_ssa_w95

}




**************** export new - clients, clients ssa, orders ssa ****************
{
capture program drop rct_regression_expclients // enables re-running
program rct_regression_expclients
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export: Clients & Orders} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Clients abroad (ITT)"' `1'2 = `"Clients abroad (TOT)"' `2'1 = `"Clients SSA (ITT)"' `2'2 = `"Clients SSA (TOT)"' `3'1 = `"Orders SSA (ITT)"' `3'2 = `"Orders SSA (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_expclients clients_w99 clients_ssa_w99 orderssa_w99, gen(exp_int99)

rct_regression_expclients clients_w95 clients_ssa_w95 orderssa_w95, gen(exp_int95)

}
}



**************** export sales sensitivity to scale k^s ****************
{
capture program drop rct_regression_finexpks // enables re-running
program rct_regression_finexpks
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions: export sensitivity to k} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)) ///
	(`8'1, pstyle(p8)) (`8'2, pstyle(p8)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Export k^1 2024 (ITT)"' `1'2 = `"Export k^1 2024 (TOT)"' `2'1 = `"Export k^1 2023 (ITT)"' `2'2 = `"Export k^1 2023 (TOT)"' `3'1 = `"Export k^2 2024 (ITT)"' `3'2 = `"Export k^2 2024 (TOT)"'  `4'1 = `"Export k^2 2023 (ITT)"' `4'2 = `"Export k^2 2023 (TOT) "' `5'1 = `"Export k^3 2024 (ITT)"' `5'2 = `"Export k^3 2024 (TOT) "' `6'1 = `"Export k^3 2023 (ITT)"' `6'2 = `"Export k^3 2023 (TOT)"' `7'1 = `"Export k^4 2024 (ITT)"' `7'2 = `"Export k^4 2024 (TOT)"' `8'1 = `"Export k^4 2023 (ITT)"' `8'2 = `"Export k^4 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_finexpks ihs_caexp2024_w99_k1 ihs_ca_exp_w99_k1 ihs_caexp2024_w99_k2 ihs_ca_exp_w99_k2 ihs_caexp2024_w99_k3 ihs_ca_exp_w99_k3 ihs_caexp2024_w99_k4 ihs_ca_exp_w99_k4, gen(finexpks99)

rct_regression_finexpks ihs_caexp2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k2 ihs_ca_exp_w95_k2 ihs_caexp2024_w95_k3 ihs_ca_exp_w95_k3 ihs_caexp2024_w95_k4 ihs_ca_exp_w95_k4, gen(finexpks95)

}

}

***********************************************************************
* 	PART 14: endline results - KPIs (sales, profits, employees)
***********************************************************************
{
* change directory
cd "${master_regressiontables}/endline/regressions/compta"


**************** finale tables & figures for presentation & paper ****************
*** label variables for each output
lab var ihs_employes_w95_k1 "N. of Employees"
lab var ihs_ca_w95_k1 "Total Sales"
lab var ihs_catun_w95_k1 "Domestic Sales"
lab var ihs_ca_exp_w95_k1 "Export Sales"
lab var ihs_profit_w95_k1 "Profits"
lab var ihs_costs_w95_k1 "Costs"

* without zeros
reg ihs_ca_w95_k1 i.treatment ihs_ca_w95_k1_y0 i.missing_bl_ihs_ca_w95_k1 i.strata_final if surveyround == 3  & ihs_ca_w95_k1 > 0, cluster(consortia_cluster)
ivreg2 ihs_ca_w95_k1 ihs_ca_w95_k1_y0 i.missing_bl_ihs_ca_w95_k1 i.strata_final (take_up = i.treatment) if surveyround == 3 & ihs_ca_w95_k1 > 0, cluster(consortia_cluster) first

* Cai and Szeidl, Iacovone et al. firm fixed effects
gen midline = (surveyround == 2)
gen endline = (surveyround == 3)

	* absolute sales
reg ca_w95 i.treatment##i.midline i.treatment##i.endline i.id_plateforme, cluster(consortia_cluster)
reg ca_exp_w95 i.treatment##i.midline i.treatment##i.endline i.id_plateforme, cluster(consortia_cluster)
reg ca_tun_w95 i.treatment##i.midline i.treatment##i.endline i.id_plateforme, cluster(consortia_cluster)

	* ihs-win-sales
reg ihs_ca_w95_k1 i.treatment##i.midline i.treatment##i.endline i.id_plateforme, cluster(consortia_cluster)
reg ihs_catun_w95_k1 i.treatment##i.midline i.treatment##i.endline i.id_plateforme, cluster(consortia_cluster)
reg ihs_caexp_w95_k1 i.treatment##i.midline i.treatment##i.endline i.id_plateforme, cluster(consortia_cluster)

	* relative growth rate in sales
reg ca_rel_growth i.treatment##i.midline i.treatment##i.endline i.strata_final, cluster(consortia_cluster)
reg ca_tun_rel_growth i.treatment##i.midline i.treatment##i.endline i.strata_final, cluster(consortia_cluster)
reg ca_exp_rel_growth i.treatment##i.midline i.treatment##i.endline i.strata_final, cluster(consortia_cluster)


reg ca_rel_growth i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
ivreg2 ca_rel_growth i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first

reg ca_exp_abs_growth i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
ivreg2 ca_exp_abs_growth i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first

reg ca_tun_abs_growth i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
ivreg2 ca_tun_abs_growth i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first

*** For presentation & For paper
	* Business Performance: Sales
capture program drop rct_regression_fin // enables re-running
program rct_regression_fin
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100			
				
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "No" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "No" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3, d
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
					estadd scalar c_med = r(p50) : `var'2
					
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100		
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
{		
		* 1st table w/o growth rates
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 // `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  adjust manually to number of variables 
		esttab `regressions' using "${tables_business}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Business Performance: Sales} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{4}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels("Total sales" "Domestic sales" "Export sales") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  // `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 adjust manually to number of variables 
		esttab `regressions' using "${tables_business}/rt_`generate'.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{4}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule ") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: All outcome variables are winsorised at the $95^{th}$ percentile and inverse hyperbolic sine transormed as pre-specified. 'Total', 'Domestic', and 'Export sales' are in units of Tunisian Dinar before transformation. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %

			***2nd table with growth rates (for presentation need to remove caption)
		local regressions `1'1 `4'1 `5'1 // `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  adjust manually to number of variables 
		esttab `regressions' using "${tables_business}/rt_`generate'_2.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Business Performance: Sales - IHS-transformed and growth rates} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{4}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(2)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels("Total sales - IHS" "Total sales - Growth rate" " Total sales - Growth rate (wins.)") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `4'2 `5'2  // `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 adjust manually to number of variables 
		esttab `regressions' using "${tables_business}/rt_`generate'_2.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{4}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(2)) se(par fmt(2))) /// p(fmt(3)) rw ci(fmt(2))
				stats(c_m c_med control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group median" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule ") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: Total sales is winsorised at the $95^{th}$ percentile and inverse hyperbolic sine transormed as pre-specified.   'Total', 'Domestic', and 'Export sales' are in units of Tunisian Dinar before transformation. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") 
				
				
				
}				
		* coefplot
				* total sales 2023 only
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1(0.5)4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1'' & SD is `fmt_sd_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp1, replace)
gr export "${figures_business}/el_`generate'_2023_cfp1.pdf", replace


				* total sales 2023 only
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " (P = " + string(@pval, "%9.2f") + ") ") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1(0.5)4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1'' & SD is `fmt_sd_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp2, replace)
gr export "${figures_business}/el_`generate'_2023_cfp2.pdf", replace



				* total sales 2023 only, added aggregated sales & VAT numbers
coefplot ///
	(`1'1, pstyle(p1)) ///
	(`1'2, pstyle(p1)  ///
	mlabel("Aggregated sales are ~5.1 million TND higher in T vs. C at EL.") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) /// 
	(`1'2, pstyle(p1)  ///
	mlabel("Equivalent to 970k TND in additional VAT revenue vs. 600k TND program costs.") ///
	mlabposition(0) mlabgap(*2) offset(-0.15) msymbol(none) noci  mlabsize(medium) ///
	), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1(0.5)4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1'' & SD is `fmt_sd_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp, replace)
gr export "${figures_business}/el_`generate'_2023_cfp3.pdf", replace

				
				* total, domestic, export sales 2023
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), /// 
	keep(*treatment take_up) drop(_cons) xline(0)  xlabel(-1(0.5)4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"' `2'1 = `"Domestic sales 2023 (ITT)"' `2'2 = `"Domestic sales 2023 (TOT)"'  `3'1 = `"Export sales 2023 (ITT)"' `3'2 = `"Export sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control EL means are `fmt_c_m_`1'' (total), `fmt_c_m_`3'' (domestic), and `fmt_c_m_`5'' (export)." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_decomp_2023_cfp, replace)
gr export "${figures_business}/el_`generate'_decomp_2023_cfp.pdf", replace
			

end

	* win95, k1
rct_regression_fin ihs_ca_w95_k1 ihs_catun_w95_k1 ihs_ca_exp_w95_k1 ca_rel_growth ca_rel_growth_w95, gen(sales)



	* Business Performance: Profits, Costs, Employment
capture program drop rct_regression_fin // enables re-running
program rct_regression_fin
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100			
				
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes" : `var'1
					estadd local strata_final "Yes" : `var'1
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes" : `var'2
					estadd local strata_final "Yes" : `var'2
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean) : `var'2
					estadd scalar control_sd = r(sd) : `var'2
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100		
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
{		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 // `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  adjust manually to number of variables 
		esttab `regressions' using "${tables_business}/rt_`generate'.tex", replace booktabs ///
				prehead("\begin{table}[!h] \centering \\ \caption{Business Performance: Profits, Costs, and Employment} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabularx}{\linewidth}{l >{\centering\arraybackslash}X >{\centering\arraybackslash}X >{\centering\arraybackslash}X} \toprule") ///
				posthead("\toprule \\ \multicolumn{4}{c}{Panel A: Intention-to-treat (ITT)} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) rw ci(fmt(2))
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  // `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 adjust manually to number of variables 
		esttab `regressions' using "${tables_business}/rt_`generate'.tex", append booktabs ///
				fragment ///	
				posthead("\addlinespace[0.3cm] \midrule \\ \multicolumn{4}{c}{Panel B: Treatment Effect on the Treated (TOT)} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3))) /// p(fmt(3)) rw ci(fmt(2))
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "BL controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\addlinespace[0.3cm] \midrule ") ///
				postfoot("\bottomrule \addlinespace[0.2cm] \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% \textit{Notes}: All outcome variables are winsorised at the $95^{th}$ percentile and inverse hyperbolic sine transormed as pre-specified. 'Profits' and 'Costs' are in units of Tunisian Dinar before transformation. 'Costs' values are calculated by substracting profits from total sales. Panel A reports ANCOVA estimates as defined in \citet{Bruhn.2009}. Panel B documents IV estimates, instrumenting take-up with treatment assignment. Standard errors are clustered on the firm-level for the control group and on the consortium-level for the treatment group following \citet{Cai.2018} and reported in parentheses. Each specification includes controls for randomization strata and baseline values of the outcome variable. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabularx} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}				
		* coefplot

coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), /// 
	keep(*treatment take_up) drop(_cons) xline(0)  ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Profit 2023 (ITT)"' `1'2 = `"Profit 2023 (TOT)"' `2'1 = `"Costs 2023 (ITT)"' `2'2 = `"Costs 2023 (TOT)"'  `3'1 = `"Employees 2023 (ITT)"' `3'2 = `"Employees 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control EL means are `fmt_c_m_`1'' (profit), `fmt_c_m_`2'' (cost), and `fmt_c_m_`3'' (employees)." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp2, replace)
gr export "${figures_business}/el_`generate'_2023_cfp.pdf", replace
			

end

	* win95, k1
rct_regression_fin ihs_profit_w95_k1 ihs_costs_w95_k1 ihs_employes_w95_k1, gen(profit)



**************** sales scale sensitive ****************

{
capture program drop rct_regression_ca // enables re-running
program rct_regression_ca
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.ihs_ca_w95_k1 i.missing_bl_ihs_ca_w95_k1 i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.ihs_ca_w95_k1 i.missing_bl_ihs_ca_w95_k1 i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum `var' if treatment == 0 & surveyround == 2
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

{
/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
*/		
}
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Sensitivity of impact on sales depending on sales-transformation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.*) /// oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile (apart from the positive sales dummy). \textit{K} refers to the units of saless. K $=4$ implies sales is measured in units of ten thousand ($10^4$), k $=3$ implies sales is measured in units of thousand ($10^4$), and so forth. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. Confidence intervals are documented below the adjusted p-values.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
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
		eqrename(`1'1 = `"sales, k = 1 (ITT)"' `1'2 = `"sales, k = 1 (TOT)"' `2'1 = `"sales, k = 2 (ITT)"' `2'2 = `"sales, k = 2 (TOT)"' `3'1 = `"sales, k = 3 (ITT)"' `3'2 = `"sales, k = 3 (TOT)"' `4'1 = `"sales, k = 4 (ITT)"' `4'2 = `"sales, k = 4 (TOT)"' `5'1 = `"sales, k = 5 (ITT)"' `5'2 = `"sales, k = 5 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace				
end

	* apply program to sales outcomes
rct_regression_ca ihs_ca_w95_k1 ihs_ca_w95_k2 ihs_ca_w95_k3 ihs_ca_w99_k4 ihs_ca_w99_k5, gen(ca_scale)

}




**************** sales ANCOVA including 3-year pre-treatment controls ****************
{
capture program drop sales_pre // enables re-running
program sales_pre
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			if regexm("`var'", "exp") == 0 {

				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment ihs_ca_2018_w95_k1 ihs_ca_2019_w95_k1 ihs_ca_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	

				// ATT, IV
				eststo `var'2: ivreg2 `var' ihs_ca_2018_w95_k1 ihs_ca_2019_w95_k1 ihs_ca_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
				
			} 
			
			else if regexm("`var'", "tun")  {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment ihs_ca_tun_2018_w95_k1 ihs_ca_tun_2019_w95_k1 ihs_ca_tun_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	

				// ATT, IV
				eststo `var'2: ivreg2 `var' ihs_ca_tun_2018_w95_k1 ihs_ca_tun_2019_w95_k1 ihs_ca_tun_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
					
				}	
			
			
				else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment ihs_ca_exp2018_w95_k1 ihs_ca_exp2019_w95_k1 ihs_ca_exp2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	

				// ATT, IV
				eststo `var'2: ivreg2 `var' ihs_ca_exp2018_w95_k1 ihs_ca_exp2019_w95_k1 ihs_ca_exp2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100	
					
				}	
}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
{		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1  //  adjust manually to number of variables `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions wins 99th.} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *ca_2018* *ca_2019* *ca_2020*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 // adjust manually to number of variables `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *ca_2018* *ca_2019* *ca_2020*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}			
			* coefplot
				* Total sales only
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(0.5)3) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"' `2'1 = `"Export sales 2023 (ITT)"' `2'2 = `"Export sales 2023 (TOT)"' `3'1 = `"Domestic sales 2023 (ITT)"' `3'2 = `"Domestic sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'1, replace)
gr export el_`generate'1.pdf, replace	

			
				* Total, domestic, and export sales
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(0.5)3) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'2, replace)
gr export el_`generate'2.pdf, replace	
				
				
				
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p3)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(0(0.5)3) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"' `2'1 = `"Export sales 2023 (ITT)"' `2'2 = `"Export sales 2023 (TOT)"' `3'1 = `"Domestic sales 2023 (ITT)"' `3'2 = `"Domestic sales 2023 (TOT)"' `4'1 = `"Total sales 2024 (ITT)"' `4'2 = `"Total sales 2024 (TOT)"' `5'1 = `"Export sales 2024 (ITT)"' `5'2 = `"Export sales 2024 (TOT)"' `6'1 = `"Domestic sales 2024 (ITT)"' `6'2 = `"Domestic sales 2024 (TOT)"') ///
		title("Sales 2023 & 2024") ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average direct export is `fmt_c_m_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate', replace)
gr export el_`generate'.png, replace


end

	* apply to sales
sales_pre ihs_ca_w95_k1 ihs_ca_exp_w95_k1 ihs_catun_w95_k1, gen(sales_pre)

}


* Overview
{
capture program drop sales_pre // enables re-running
program sales_pre
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			if regexm("`var'", "exp") == 0 {

				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment ihs_ca_2018_w95_k1 ihs_ca_2019_w95_k1 ihs_ca_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' ihs_ca_2018_w95_k1 ihs_ca_2019_w95_k1 ihs_ca_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
				
			} 
			
			else if regexm("`var'", "tun")  {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment ihs_ca_tun_2018_w95_k1 ihs_ca_tun_2019_w95_k1 ihs_ca_tun_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' ihs_ca_tun_2018_w95_k1 ihs_ca_tun_2019_w95_k1 ihs_ca_tun_2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
					
				}	
			
			
				else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment ihs_ca_exp2018_w95_k1 ihs_ca_exp2019_w95_k1 ihs_ca_exp2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' ihs_ca_exp2018_w95_k1 ihs_ca_exp2019_w95_k1 ihs_ca_exp2020_w95_k1 `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
					
				}	
}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1  //  adjust manually to number of variables `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions wins 99th.} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *ca_2018* *ca_2019* *ca_2020*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *ca_2018* *ca_2019* *ca_2020*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p3)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"' `2'1 = `"Export sales 2023 (ITT)"' `2'2 = `"Export sales 2023 (TOT)"' `3'1 = `"Domestic sales 2023 (ITT)"' `3'2 = `"Domestic sales 2023 (TOT)"' `4'1 = `"Total sales 2024 (ITT)"' `4'2 = `"Total sales 2024 (TOT)"' `5'1 = `"Export sales 2024 (ITT)"' `5'2 = `"Export sales 2024 (TOT)"' `6'1 = `"Domestic sales 2024 (ITT)"' `6'2 = `"Domestic sales 2024 (TOT)"') ///
		title("Sales 2023 & 2024") ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}: All variables are winsorised & IHS-transformed.", span) ///
		name(el_`generate', replace)
gr export el_`generate'.png, replace


end

	* apply to sales
sales_pre ihs_ca_w95_k1 ihs_ca_exp_w95_k1 ihs_catun_w95_k1 ihs_ca_2024_w95_k1 ihs_caexp2024_w95_k1 ihs_catun2024_w95_k1, gen(sales_pre)

}




**************** financials: ANCOVA ****************
{
capture program drop rct_regression_fin // enables re-running
program rct_regression_fin
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	
				
				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100			
				
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local itt_`var' = r(table)[1,2]
					local fmt_itt_`var' : display %3.2f `itt_`var''	

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
						* add to latex table
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
						* add to coefplot
					local att_`var' = e(b)[1,1]
					local fmt_att_`var' : display %3.2f `att_`var''	
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
						* for latex table
					estadd scalar c_m = r(mean)
					estadd scalar control_sd = r(sd)
						* for  coefplots
					local c_m_`var' = r(mean)
					local fmt_c_m_`var' : display  %3.2f `c_m_`var''
					local sd_`var' = r(sd)
					local fmt_sd_`var' : display  %3.2f `sd_`var''
					
					// Calculate percent change
					local `var'_per_itt = (`fmt_itt_`var'' / `fmt_c_m_`var'')*100			
					local `var'_per_att = (`fmt_att_`var'' / `fmt_c_m_`var'')*100		
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
{		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1 //  adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions wins 99th.} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{11}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{11}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(c_m control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{11}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}				
			* coefplot
				* total sales 2023 only
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1(0.5)4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1'' & SD is `fmt_sd_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp1, replace)
gr export el_`generate'_2023_cfp1.pdf, replace

				* total sales 2023 only, added aggregated sales & VAT numbers
coefplot ///
	(`1'1, pstyle(p1)) ///
	(`1'2, pstyle(p1)  ///
	mlabel("Aggregated sales are ~5.1 million TND higher in T vs. C at EL.") ///
	mlabposition(12) mlabgap(*2)  mlabsize(medium)) /// 
	(`1'2, pstyle(p1)  ///
	mlabel("Equivalent to 970k TND in additional VAT revenue.") ///
	mlabposition(0) mlabgap(*2) offset(-0.15) msymbol(none) noci  mlabsize(medium) ///
	), /// 
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1(0.5)4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1'' & SD is `fmt_sd_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp1a, replace)
gr export el_`generate'_2023_cfp1a.pdf, replace
				
				* total, domestic, export sales 2023
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`3'1, pstyle(p2)) (`3'2, pstyle(p2)) ///
	(`5'1, pstyle(p3)) (`5'2, pstyle(p3)), /// 
	keep(*treatment take_up) drop(_cons) xline(0)  xlabel(-1(0.5)4) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"' `3'1 = `"Domestic sales 2023 (ITT)"' `3'2 = `"Domestic sales 2023 (TOT)"'  `5'1 = `"Export sales 2023 (ITT)"' `5'2 = `"Export sales 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control EL means are `fmt_c_m_`1'' (total), `fmt_c_m_`3'' (domestic), and `fmt_c_m_`5'' (export)." "The control EL SDs are `fmt_sd_`1'' (total), `fmt_sd_`3'' (domestic), and `fmt_sd_`5'' (export)." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp2, replace)
gr export el_`generate'_2023_cfp2.pdf, replace
			
				* overview: 2023
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`3'1, pstyle(p2)) (`3'2, pstyle(p2)) ///
	(`5'1, pstyle(p3)) (`5'2, pstyle(p3)) ///
	(`7'1, pstyle(p4)) (`7'2, pstyle(p4)) ///
	(`9'1, pstyle(p5)) (`9'2, pstyle(p5)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"' `3'1 = `"Domestic sales 2023 (ITT)"' `3'2 = `"Domestic sales 2023 (TOT)"'  `5'1 = `"Export sales 2023 (ITT)"' `5'2 = `"Export sales 2023 (TOT)"' `7'1 = `"Profit 2023 (ITT)"' `7'2 = `"Profit 2023 (TOT)"' `9'1 = `"Costs 2023 (ITT)"' `9'2 = `"Costs 2023 (TOT)"') ///
		title("KPIs 2023") ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2023_cfp, replace)
gr export el_`generate'_2023_cfp.png, replace

				* overview: 2024
coefplot ///
	(`2'1, pstyle(p1)) (`2'2, pstyle(p1)) ///
	(`4'1, pstyle(p2)) (`4'2, pstyle(p2)) ///
	(`6'1, pstyle(p3)) (`6'2, pstyle(p3)) ///
	(`8'1, pstyle(p4)) (`8'2, pstyle(p4)) ///
	(`10'1, pstyle(p5)) (`10'2, pstyle(p5)), /// 
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`2'1 = `"Total sales 2024 (ITT)"' `2'2 = `"Total sales 2024 (TOT)"' `4'1 = `"Domestic sales 2024 (ITT)"' `4'2 = `"Domestic sales 2024 (TOT) "' `6'1 = `"Export sales 2024 (ITT)"' `6'2 = `"Export sales 2024 (TOT)"' `8'1 = `"Profit 2023 (ITT)"' `8'2 = `"Profit 2023 (TOT) "' `10'1 = `"Costs 2024 (ITT)"' `10'2 = `"Costs 2024 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "The control group endline average is `fmt_c_m_`1''." "Confidence intervals are at the 95 percent level." "All variables are winsorised at the 95th percentile & IHS-transformed.", span size(medium)) ///
		name(el_`generate'_2024_cfp, replace)
gr export el_`generate'_2024_cfp.png, replace


end

	* apply program to financial outcomes
			* win99, k1
rct_regression_fin ihs_ca_w99_k1 ihs_ca_2024_w99_k1 ihs_catun_w99_k1 ihs_catun2024_w99_k1 ihs_ca_exp_w99_k1 ihs_caexp2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k1 ihs_costs_w99_k1 ihs_costs_2024_w99_k1, gen(fin_k1_w99)
		
			* win95, k1
rct_regression_fin ihs_ca_w95_k1 ihs_ca_2024_w95_k1 ihs_catun_w95_k1 ihs_catun2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1 ihs_profit_w95_k1 ihs_profit2024_w95_k1 ihs_costs_w95_k1 ihs_costs_2024_w95_k1, gen(fin_k1_w95)

			* win99, k4
rct_regression_fin ihs_ca_w99_k4 ihs_ca_2024_w99_k4 ihs_catun_w99_k4 ihs_catun2024_w99_k4 ihs_ca_exp_w99_k4 ihs_caexp2024_w99_k4 ihs_profit_w99_k4 ihs_profit2024_w99_k4 ihs_costs_w99_k4 ihs_costs_2024_w99_k4, gen(fin_k4_w99)

			* win95, k4
rct_regression_fin ihs_ca_w95_k4 ihs_ca_2024_w95_k4 ihs_catun_w95_k4 ihs_catun2024_w95_k4 ihs_ca_exp_w95_k4 ihs_caexp2024_w95_k4 ihs_profit_w95_k4 ihs_profit2024_w95_k4 ihs_costs_w95_k4 ihs_costs_2024_w95_k4, gen(fin_k4_w95)


}

**************** financials: DiD ****************
{
capture program drop rct_did_fin // enables re-running
program rct_did_fin
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment##i.post i.strata_final, cluster(consortia_cluster)
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: reg `var' i.take_up##i.post i.strata_final, cluster(consortia_cluster)
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1 //  adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions wins 99th.} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{11}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{11}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{11}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`3'1, pstyle(p2)) (`3'2, pstyle(p2)) ///
	(`5'1, pstyle(p3)) (`5'2, pstyle(p3)) ///
	(`7'1, pstyle(p4)) (`7'2, pstyle(p4)) ///
	(`9'1, pstyle(p5)) (`9'2, pstyle(p5)), /// 
	keep(1.treatment#1.post 1.take_up#1.post) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Total sales 2023 (ITT)"' `1'2 = `"Total sales 2023 (TOT)"' `3'1 = `"Domestic sales 2023 (ITT)"' `3'2 = `"Domestic sales 2023 (TOT)"'  `5'1 = `"Export sales 2023 (ITT)"' `5'2 = `"Export sales 2023 (TOT)"' `7'1 = `"Profit 2023 (ITT)"' `7'2 = `"Profit 2023 (TOT)"' `9'1 = `"Costs 2023 (ITT)"' `9'2 = `"Costs 2023 (TOT)"') ///
		title("KPIs 2023") ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}: All variables are winsorised & IHS-transformed.", span) ///
		name(el_`generate'_2023_cfp, replace)
gr export el_`generate'_2023_cfp.png, replace

		
coefplot ///
	(`2'1, pstyle(p1)) (`2'2, pstyle(p1)) ///
	(`4'1, pstyle(p2)) (`4'2, pstyle(p2)) ///
	(`6'1, pstyle(p3)) (`6'2, pstyle(p3)) ///
	(`8'1, pstyle(p4)) (`8'2, pstyle(p4)) ///
	(`10'1, pstyle(p5)) (`10'2, pstyle(p5)), /// 
	keep(1.treatment#1.post 1.take_up#1.post) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		title("KPIs 2024") ///
		eqrename(`2'1 = `"Total sales 2024 (ITT)"' `2'2 = `"Total sales 2024 (TOT)"' `4'1 = `"Domestic sales 2024 (ITT)"' `4'2 = `"Domestic sales 2024 (TOT) "' `6'1 = `"Export sales 2024 (ITT)"' `6'2 = `"Export sales 2024 (TOT)"' `8'1 = `"Profit 2023 (ITT)"' `8'2 = `"Profit 2023 (TOT) "' `10'1 = `"Costs 2024 (ITT)"' `10'2 = `"Costs 2024 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}: All variables are winsorised & IHS-transformed.", span) ///
		name(el_`generate'_2024_cfp, replace)
gr export el_`generate'_2024_cfp.png, replace


end

	* apply program to financial outcomes
		* win99, k1
rct_did_fin ihs_ca_w99_k1 ihs_ca_2024_w99_k1 ihs_catun_w99_k1 ihs_catun2024_w99_k1 ihs_ca_exp_w99_k1 ihs_caexp2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k1 ihs_costs_w99_k1 ihs_costs_2024_w99_k1, gen(did_fin_k1_w99)
		
		* win95, k1
rct_did_fin ihs_ca_w95_k1 ihs_ca_2024_w95_k1 ihs_catun_w95_k1 ihs_catun2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1 ihs_profit_w95_k1 ihs_profit2024_w95_k1 ihs_costs_w95_k1 ihs_costs_2024_w95_k1, gen(did_fin_k1_w95)

rct_did_fin ca_w95_k1 ca_2024_w95_k1 ca_tun_w95_k1 ca_tun_2024_w95_k1 ca_exp_w95_k1 ca_exp_2024_w95_k1 profit_w95_k1 profit_2024_w95_k1 costs_w95_k1 costs_2024_w95_k1, gen(did_fin_k1_w95)

		* win99, k4
rct_did_fin ihs_ca_w99_k4 ihs_ca_2024_w99_k4 ihs_catun_w99_k4 ihs_catun2024_w99_k4 ihs_ca_exp_w99_k4 ihs_caexp2024_w99_k4 ihs_profit_w99_k4 ihs_profit2024_w99_k4 ihs_costs_w99_k4 ihs_costs_2024_w99_k4, gen(fin_k4_w99)

		* win95, k4
rct_did_fin ihs_ca_w95_k4 ihs_ca_2024_w95_k4 ihs_catun_w95_k4 ihs_catun2024_w95_k4 ihs_ca_exp_w95_k4 ihs_caexp2024_w95_k4 ihs_profit_w95_k4 ihs_profit2024_w95_k4 ihs_costs_w95_k4 ihs_costs_2024_w95_k4, gen(fin_k4_w95)


}


**************** profit k^s ***************
*with intervals
{
capture program drop rct_regression_finprtks // enables re-running
program rct_regression_finprtks
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions: Profit Sensitivity to k} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)) ///
	(`8'1, pstyle(p8)) (`8'2, pstyle(p8)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Profit k^1 2024 (ITT)"' `1'2 = `"Profit k^1 2024 (TOT)"' `2'1 = `"Profit k^1 2023 (ITT)"' `2'2 = `"Profit k^1 2023 (TOT)"' `3'1 = `"Profit k^2 2024 (ITT)"' `3'2 = `"Profit k^2 2024 (TOT)"'  `4'1 = `"Profit k^2 2023 (ITT)"' `4'2 = `"Profit k^2 2023 (TOT) "' `5'1 = `"Profit k^3 2024 (ITT)"' `5'2 = `"Profit k^3 2024 (TOT) "' `6'1 = `"Profit k^3 2023 (ITT)"' `6'2 = `"Profit k^3 2023 (TOT)"' `7'1 = `"Profit k^4 2024 (ITT)"' `7'2 = `"Profit k^4 2024 (TOT)"' `8'1 = `"Profit k^4 2023 (ITT)"' `8'2 = `"Profit k^4 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_finprtks ihs_profit2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k2 ihs_profit_w99_k2 ihs_profit2024_w99_k3 ihs_profit_w99_k3 ihs_profit2024_w99_k4 ihs_profit_w99_k4 ihs_profit2024_w99_k5 ihs_profit_w99_k5, gen(finprtks)

}

*without intervals
{
capture program drop rct_regression_finprtks // enables re-running
program rct_regression_finprtks
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions: Profit Sensitivity to k} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)) ///
	(`7'1, pstyle(p7)) (`7'2, pstyle(p7)) ///
	(`8'1, pstyle(p8)) (`8'2, pstyle(p8)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Profit k^1 2024 (ITT)"' `1'2 = `"Profit k^1 2024 (TOT)"' `2'1 = `"Profit k^1 2023 (ITT)"' `2'2 = `"Profit k^1 2023 (TOT)"' `3'1 = `"Profit k^2 2024 (ITT)"' `3'2 = `"Profit k^2 2024 (TOT)"'  `4'1 = `"Profit k^2 2023 (ITT)"' `4'2 = `"Profit k^2 2023 (TOT) "' `5'1 = `"Profit k^3 2024 (ITT)"' `5'2 = `"Profit k^3 2024 (TOT) "' `6'1 = `"Profit k^3 2023 (ITT)"' `6'2 = `"Profit k^3 2023 (TOT)"' `7'1 = `"Profit k^4 2024 (ITT)"' `7'2 = `"Profit k^4 2024 (TOT)"' `8'1 = `"Profit k^4 2023 (ITT)"' `8'2 = `"Profit k^4 2023 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_finprtks ihs_pr2024ni_w99_k1 ihs_prni_w99_k1 ihs_pr2024ni_w99_k2 ihs_prni_w99_k2 ihs_pr2024ni_w99_k3 ihs_prni_w99_k3 ihs_pr2024ni_w99_k4 ihs_prni_w99_k4 ihs_pr2024ni_w99_k5 ihs_prni_w99_k5, gen(finprt_noint_ks)

}

**************** profitable? ****************
{
capture program drop rct_regression_pft // enables re-running
program rct_regression_pft
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
			foreach var in `varlist' {
			capture confirm variable `var'_y0
			if _rc == 0 {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "Yes"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
			}
			else {
				// ITT: ANCOVA plus stratification dummies
				eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
				estadd local bl_control "No"
				estadd local strata_final "Yes"

				// ATT, IV
				eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
				estadd local bl_control "No"
				estadd local strata_final "Yes"
				
				// Calculate control group mean
				sum `var' if treatment == 0 & surveyround == 3
				estadd scalar control_mean = r(mean)
				estadd scalar control_sd = r(sd)
        }
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial results: profitable} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), //////
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Profitable 2023 (ITT)"' `1'2 = `"Profitable 2023 (TOT)"' `2'1 = `"Profitable 2024 (ITT)"' `2'2 = `"Profitable 2024 (TOT)"' `3'1 = `"Profit percentiles (ITT)"' `3'2 = `"Profit percentiles (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_pft profit_pos profit_2024_category profit_pct, gen(pft)

}



**************** empl ****************

{
capture program drop rct_regression_empl // enables re-running
program rct_regression_empl
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(consortia_cluster)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(consortia_cluster)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Business performance: Employees} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* `5' `6'
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) ///
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0) xlabel(-3(1)3) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Employees (ITT)"' `1'2 = `"Employees (TOT)"' `2'1 = `"Female employees (ITT)"' `2'2 = `"Female employees (TOT)"' `3'1 = `"Young employees < 36 (ITT)"' `3'2 = `"Young employees < 36  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		note("{bf:Note}: All variables are winsorised at the 95th percentile.", span) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_empl employes_w95 car_empl1_w95 car_empl2_w95, gen(empl)

}



}
