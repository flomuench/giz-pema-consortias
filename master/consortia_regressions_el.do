***********************************************************************
* 			Master endline analysis/regressions				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake treatment effect analysis of
*				outcomes
*
*													
*																	  
*	Authors:  	Ayoub Chamakhi
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
cd "${master_regressiontables}/endline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on
}
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
* 	PART 1: survey attrition 		
***********************************************************************

*test for differential total attrition
{
	* is there differential attrition between treatment and control group?
		* column (1): at endline
eststo att1, r: areg refus i.treatment if surveyround == 3, absorb(strata_final) cluster(id_plateforme)
estadd local strata_final "Yes"
		
		* column (2): at endline
eststo att2, r: areg refus i.treatment if surveyround == 3, absorb(strata_final) cluster(id_plateforme)
estadd local strata_final "Yes"

		* column (3): at baseline
eststo att3, r: areg refus i.treatment if surveyround == 1, absorb(strata_final) cluster(id_plateforme)
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
	addnotes("All standard errors are Hubert-White robust standord errors clustered at the firm level." "Indexes are z-score as defined in Kling et al. 2007.")
		
}

***********************************************************************
* 	PART 2: balance table		
***********************************************************************
*take_up
	*without outlier
iebaltab ca ca_2024 ca_exp ca_exp_2024 profit profit_2024 employes car_empl1 car_empl2 net_coop_pos net_coop_neg net_size3 net_size4 net_gender3 net_gender4 exp_pays exp_pays_ssa clients clients_ssa if surveyround == 3 & id_plateforme != 1092, grpvar(take_up) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok savetex(el_take_up_baltab_adj) replace

	*with outlier
iebaltab ca ca_2024 ca_exp ca_exp_2024 profit profit_2024 employes car_empl1 car_empl2 net_coop_pos net_coop_neg net_size3 net_size4 net_gender3 net_gender4 exp_pays exp_pays_ssa clients clients_ssa if surveyround == 3 & id_plateforme != 1092, grpvar(take_up) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok savetex(el_take_up_baltab_unadj) replace

*treatment
*without outlier
iebaltab ca ca_2024 ca_exp ca_exp_2024 profit profit_2024 employes car_empl1 car_empl2 net_coop_pos net_coop_neg net_size3 net_size4 net_gender3 net_gender4 exp_pays exp_pays_ssa clients clients_ssa if surveyround == 3 & id_plateforme != 1092, grpvar(treatment) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok savetex(el_treat_baltab_adj) replace

*with outlier
iebaltab ca ca_2024 ca_exp ca_exp_2024 profit profit_2024 employes car_empl1 car_empl2 net_coop_pos net_coop_neg net_size3 net_size4 net_gender3 net_gender4 exp_pays exp_pays_ssa clients clients_ssa if surveyround == 3 & id_plateforme != 1092, grpvar(treatment) rowvarlabels format(%15.2fc) vce(robust) ftest fmissok savetex(el_treat_baltab_unadj) replace

************************************************************
* 	PART 3: list experiment regression
***********************************************************************

{
	* ITT, ancova	
			* baseline differences amount
eststo lexp1, r: reg listexp i.list_group i.strata_final if surveyround == 1, cluster(id_plateforme)
estadd local strata_final "Yes"

		
			* midline ancova with stratification dummies 
eststo lexp2, r: reg listexp i.treatment##i.list_group l.listexp i.strata_final missing_bl_listexp if surveyround == 2, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata_final "Yes"		

			* endline ancova with stratification dummies 
eststo lexp3, r: reg listexp i.treatment##i.list_group_el l.listexp i.strata_final missing_bl_listexp if surveyround == 3, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
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
* 	PART 4: Endline results - regression table indexes
***********************************************************************

{
capture program drop rct_regression_indexes // enables re-running the program
program rct_regression_indexes
	version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
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
rct_regression_indexes network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi bpi bpi_2024, gen(indexes)

}
***********************************************************************
* 	PART 5: endline results - regression network outcomes
***********************************************************************
**************** number of network & coop ****************
{
capture program drop rct_regression_network // enables re-running
program rct_regression_network
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network size & cooperation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Association membership (ITT)"' `1'2 = `"Association membership (TOT)"' `2'1 = `"entrepreneurship discussions (ITT)"' `2'2 = `"entrepreneurship discussions (TOT)"' `3'1 = `"Male entrepreneurship discussions (ITT)"' `3'2 = `"Male entrepreneurship discussions (TOT)"' `4'1 = `"Female entrepreneurship discussions (ITT)"' `4'2 = `"Female entrepreneurship discussions (TOT)"' `5'1 = `"Female entrepreneurs met at activities (ITT)"' `5'2 = `"Female entrepreneurs met at activities (TOT)"' `6'1 = `"Positive cooperation (ITT)"' `6'2 = `"Positive cooperation (TOT)"' `7'1 = `"Negative cooperation (ITT)"' `7'2 = `"Negative cooperation (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to business performance outcomes
rct_regression_network net_association net_size3 net_size3_m net_gender3 net_gender3_giz net_coop_pos net_coop_neg, gen(network)

}

**************** net_services ****************
rename net_services_pratiques net_pratiques
rename net_services_produits net_produits
rename net_services_mark net_mark
rename net_services_sup net_sup
rename net_services_contract net_contract
rename net_services_confiance net_confiance
rename net_services_autre net_autre

{

local ys net_pratiques net_produits net_mark net_sup net_contract net_confiance net_autre

	* gen dummy + replace missings with zero at bl
foreach var of local ys {
	gen missing_bl_`var' = (`var' == . & surveyround == 1) 
	replace `var' = 0 if `var' == . & surveyround == 1
}

	* generate Y0 --> baseline value for ancova & mht
foreach var of local ys {
		* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]					// filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)								// create variable = bl value for all three surveyrounds by id
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first														// clean up
	lab var `var'_y0 "Y0 `var'"
	}

}
{
capture program drop rct_regression_netserv // enables re-running
program rct_regression_netserv
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Network services} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.*
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Practices (ITT)"' `1'2 = `"Practices (TOT)"' `2'1 = `"Products/services (ITT)"' `2'2 = `"Products/services (TOT)"' `3'1 = `"Marketing (ITT)"' `3'2 = `"Marketing (TOT)"' `4'1 = `"Supply (ITT)"' `4'2 = `"Supply (TOT)"' `5'1 = `"Contract (ITT)"' `5'2 = `"Contract (TOT)"' `6'1 = `"Confidence (ITT)"' `6'2 = `"Confidence (TOT)"' `7'1 = `"Other (ITT)"' `7'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to business performance outcomes
rct_regression_netserv net_pratiques net_produits net_mark net_sup net_contract net_confiance net_autre, gen(network)

}
***********************************************************************
* 	PART 6: endline results - regression table innovation knowledge transfer
***********************************************************************
**************** inno_produit ****************

{
capture program drop rct_regression_kt // enables re-running
program rct_regression_kt
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Product Innovations} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 // adjust manually to number of variables 
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
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Process innovations} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
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
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"New production technology (ITT)"' `1'2 = `"New production technology (TOT)"' `2'1 = `"New marketing channels (ITT)"' `2'2 = `"New marketing channels (TOT)"' `3'1 = `"New pricing methods (ITT)"' `3'2 = `"New pricing methods (TOT)"' `4'1 = `"New suppliers (ITT)"' `4'2 = `"New suppliers (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_ktpro inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres, gen(ktpro)

}

**************** inno_mot ****************

{
capture program drop rct_regression_ktmot // enables re-running
program rct_regression_ktmot
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
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
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
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
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Innovation source: consultant (ITT)"' `1'2 = `"Innovation source: consultant (TOT)"' `2'1 = `"Innovation source: entrepreneurs (ITT)"' `2'2 = `"Innovation source: entrepreneurs (TOT)"' `3'1 = `"Innovation source: events (ITT)"' `3'2 = `"Innovation source: events (TOT)"' `4'1 = `"Innovation source: clients (ITT)"' `4'2 = `"Innovation source: clients (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_ktmot inno_mot_cons inno_mot_cont inno_mot_eve inno_mot_client inno_mot_dummyother, gen(ktpro)

}

***********************************************************************
* 	PART 7: endline results - regression table management knowledge transfer
***********************************************************************
**************** man_fin_per ****************

{
capture program drop rct_regression_indic // enables re-running
program rct_regression_indic
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management indicators} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
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
	(`6'1, pstyle(p6)) (`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Financial indicators (ITT)"' `1'2 = `"Financial indicators (TOT)"' `2'1 = `"Production management (ITT)"' `2'2 = `"Production management (TOT)"' `3'1 = `"Input quality (ITT)"' `3'2 = `"Input quality (TOT)"' `4'1 = `"Stock (ITT)"' `4'2 = `"Stock (TOT)"' `5'1 = `"Employees performance & absence (ITT)"' `5'2 = `"Employees performance & absence (TOT)"' `6'1 = `"Timely delivery (ITT)"' `6'2 = `"StTimely deliveryock (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_indic man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv, gen(indic)

}

**************** man_fin_fre ****************

{
capture program drop rct_regression_fre // enables re-running
program rct_regression_fre
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management indicators frequency} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2  // adjust manually to number of variables 
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
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Indicatros tracking frequency (ITT)"' `1'2 = `"Indicatros tracking frequency (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_fre man_fin_per_fre, gen(freq)

}

**************** man_fin_pra ****************

{
capture program drop rct_regression_manpra // enables re-running
program rct_regression_manpra
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1   // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management practices} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Business plan and budget (ITT)"' `1'2 = `"Business plan and budget (TOT)"' `2'1 = `"Calculate costs and profit (ITT)"' `2'2 = `"Calculate costs and profit  (TOT)"' `3'1 = `"Distinction between personal and business accounts (ITT)"' `3'2 = `"Distinction between personal and business accounts (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

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
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management source of innovations} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
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
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Manangement source: consultant (ITT)"' `1'2 = `"Manangement source: consultant (TOT)"' `2'1 = `"Manangement source: entrepreneurs (ITT)"' `2'2 = `"Manangement source: entrepreneurs (TOT)"' `3'1 = `"Manangement source: family or friends (ITT)"' `3'2 = `"Manangement source: family or friends (TOT)"' `4'1 = `"Manangement source: events (ITT)"' `4'2 = `"Manangement source: events (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_mans man_source_cons man_source_pdg man_source_fam man_source_even man_source_autres, gen(mans)

}
***********************************************************************
* 	PART 8: endline results - regression table export knowledge transfer
***********************************************************************
**************** exp_pra ****************

{
capture program drop rct_regression_expra // enables re-running
program rct_regression_expra
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export knowledge transfer: Practices} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
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
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Hire export professional (ITT)"' `1'2 = `"Hire export professional (TOT)"' `2'1 = `"Participate to B2B fairs (ITT)"' `2'2 = `"Participate to B2B fairs (TOT)"' `3'1 = `"Identify partner (ITT)"' `3'2 = `"Identify partner  (TOT)"' `4'1 = `"International certifications (ITT)"' `4'2 = `"International certifications (TOT)"' `5'1 = `"Invest in sales structure abroad (ITT)"' `5'2 = `"Invest in sales structure abroads (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

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
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export knowledge transfer: Practices SSA} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Potential client (ITT)"' `1'2 = `"Potential client (TOT)"' `2'1 = `"Commercial partner (ITT)"' `2'2 = `"Commercial partner (TOT)"' `3'1 = `"External financial engagement (ITT)"' `3'2 = `"External financial engagement (TOT)"' `4'1 = `"Invest in SSA sales structure (ITT)"' `4'2 = `"Invest in SSA sales structure (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
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
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export costs} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 // adjust manually to number of variables 
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


***********************************************************************
* 	PART 9: endline results - regression table entrepreneurial empowerment
***********************************************************************
**************** efi ****************

{
capture program drop rct_regression_efi // enables re-running
program rct_regression_efi
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 // adjust manually to number of variables 
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
		local regressions `1'2 `2'2 `3'2  // adjust manually to number of variables 
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
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Efficacy: financial sources (ITT)"' `1'2 = `"Efficacy: financial sources (TOT)"' `2'1 = `"Efficacy: management (ITT)"' `2'2 = `"Efficacy: management (TOT)"' `3'1 = `"Efficacy: motivation (ITT)"' `3'2 = `"Efficacy: motivation (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_efi car_efi_fin1 car_efi_man car_efi_motiv, gen(efi)

}

**************** locus ****************

{
capture program drop rct_regression_locus // enables re-running
program rct_regression_locus
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1  // adjust manually to number of variables 
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
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Locus: network (ITT)"' `1'2 = `"Locus: network (TOT)"' `2'1 = `"Locus: export administration & logistics (ITT)"' `2'2 = `"Locus: export administration & logistics (TOT)"' `3'1 = `"Locus: private & professional life (ITT)"' `3'2 = `"Locus: private & professional life (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_locus car_loc_env car_loc_exp car_loc_soin, gen(locus)

}


***********************************************************************
* 	PART 10: endline results - regression table export
***********************************************************************
**************** export ****************

{
capture program drop rct_regression_exp // enables re-running
program rct_regression_exp
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 // adjust manually to number of variables 
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
		local regressions `1'2 `2'2 `3'2  // adjust manually to number of variables 
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
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Exports (ITT)"' `1'2 = `"Exports (TOT)"' `2'1 = `"Exports via intermediate (ITT)"' `2'2 = `"Exports via intermediate  (TOT)"' `3'1 = `"Does not export (ITT)"' `3'2 = `"Does not export (TOT)"'  `4'1 = `"Extensive margin export 2023 (ITT)"' `4'2 = `"Extensive margin export 2023 "' `5'1 = `"Extensive margin export 2024 (ITT)"' `5'2 = `"Extensive margin export 2024"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_exp export_1 export_2 export_3 marginal_exp_2023 marginal_exp_2024, gen(exp)

}

**************** no export reasons ****************

{
capture program drop rct_regression_noexp // enables re-running
program rct_regression_noexp
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
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
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2   // adjust manually to number of variables 
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
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"No export: high cost (ITT)"' `1'2 = `"No export: high cost (TOT)"' `2'1 = `"No export: no client (ITT)"' `2'2 = `"No export: no client (TOT)"' `3'1 = `"No export: complicated (ITT)"' `3'2 = `"No export: complicated (TOT)"' `4'1 = `"No export: risk & uncertainty (ITT)"' `4'2 = `"No export: risk & uncertainty (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_noexp export_41 export_42 export_43 export_44 export_45, gen(noexp)

}

**************** clients ****************

{
capture program drop rct_regression_expclients // enables re-running
program rct_regression_expclients
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
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
				drop(_cons *.strata_final ?.missing_bl_*) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2   // adjust manually to number of variables 
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
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Number of export countries wins. 99 (ITT)"' `1'2 = `"Number of export countries wins. 99 (TOT)"' `2'1 = `"Clients abroad wins. 99 (ITT)"' `2'2 = `"Clients abroad wins. 99 (TOT)"' `3'1 = `"Clients abroad SSA wins. 99 (ITT)"' `3'2 = `"Clients abroad SSA wins. 99 (TOT)"' `4'1 = `"Orders SSA  wins. 99 (ITT)"' `4'2 = `"Orders SSA  wins. 99 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_expclients exp_pays_w99 clients_w99 clients_ssa_w99 orderssa_w99, gen(clients)

}

***********************************************************************
* 	PART 11: endline results - regression financial results
***********************************************************************
**************** wins 99th ****************
{
capture program drop rct_regression_fin // enables re-running
program rct_regression_fin
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(id_plateforme) first
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
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2 `10'2  // adjust manually to number of variables 
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
	(`8'1, pstyle(p8)) (`8'2, pstyle(p8)) ///
	(`9'1, pstyle(p9)) (`9'2, pstyle(p9)) ///
	(`10'1, pstyle(p10)) (`10'2, pstyle(p10)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Sales 2023 wins. 99th (ITT)"' `1'2 = `"Sales 2023 wins. 99th (TOT)"' `2'1 = `"Sales 2024 wins. 99th (ITT)"' `2'2 = `"Sales 2024 wins. 99th (TOT)"' `3'1 = `"Domestic Sales 2023 wins. 99th (ITT)"' `3'2 = `"Domestic Sales 2023 wins. 99th (TOT)"'  `4'1 = `"Domestic Sales 2024 wins. 99th (ITT)"' `4'2 = `"Domestic Sales 2024 wins. 99th (TOT) "' `5'1 = `"Export turnover 2023 wins. 99th (ITT)"' `5'2 = `"Export turnover 2023 wins. 99th (TOT)"' `6'1 = `"Export turnover 2024 wins. 99th (ITT)"' `6'2 = `"Export turnover 2024 wins. 99th (TOT)"' `7'1 = `"Costs 2023 wins. 99th (ITT)"' `7'2 = `"Costs 2023 wins. 99th (TOT)"' `8'1 = `"Costs 2024 wins. 99th (ITT)"' `8'2 = `"Costs 2024 wins. 99th (TOT)"'  `9'1 = `"Profit 2023 wins. 99th (ITT)"' `9'2 = `"Profit 2023 wins. 99th (TOT) "' `10'1 = `"Profit 2024 wins. 99th (ITT)"' `10'2 = `"Profit 2024 wins. 99th (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_fin ca_w99 ca_2024_w99 localsales_w99 localsales2024_w99 ca_exp_w99 ca_exp_2024_w99 costs_w99 costs_2024_w99 profit_w99 profit_2024_w99, gen(fin)

}