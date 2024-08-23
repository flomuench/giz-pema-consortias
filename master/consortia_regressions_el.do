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
{
	* is there differential attrition between treatment and control group?
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

***********************************************************************
* 	PART 2: balance table		
***********************************************************************
{
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
		
**************** number of network & coop ****************
{
* change directory
cd "${master_regressiontables}/endline/regressions/network"
**** TABLES FOR PAPER ****
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
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(consortia_cluster)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata_final(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 // adjust manually to number of variables 
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
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 `7'2 `8'2 `9'2  // adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/network/rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///  
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 95 percent level, corresponding to three extreme values. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are clustered at the individual firm-level for the control group and at the consortia level for treatment group firms.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// add the following for MHT RW when done: Adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors
				
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
		eqrename(`1'1 = `"Any (ITT)"' `1'2 = `"Any (TOT)"' `2'1 = `"Entrepreneurs (ITT)"' `2'2 = `"Entrepreneurs (TOT)"' `3'1 = `"Male Entrepreneurs (ITT)"' `3'2 = `"Male Entrepreneurs (TOT)"' `4'1 = `"Female Entrepreneurs (ITT)"' `4'2 = `"Female Entrepreneurs (TOT)"' `5'1 = `"Family/Friends (ITT)"' `5'2 = `"Family/Friends (TOT)"' `6'1 = `"Male Family/Friends (ITT)"' `6'2 = `"Male Family/Friends (TOT)"' `7'1 = `" Female Family/Friends (ITT)"' `7'2 = `"Female Family/Friends (TOT)"') ///
		xtitle("Regular business discussion partners", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfplot.png", replace


						* coefplot
coefplot ///
	(`8'1, pstyle(p8)) (`8'2, pstyle(p8)) ///
	(`9'1, pstyle(p9)) (`9'2, pstyle(p9)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`8'1 = `"Positive cooperation (ITT)"' `8'2 = `"Positive cooperation (TOT)"' `9'1 = `"Negative cooperation (ITT)"' `9'2 = `"Negative cooperation (TOT)"') ///
		xtitle("Number of terms", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'coop_cfplot, replace)
	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'coop_cfplot.png", replace


end

	* apply program to network outcomes
		* w99
rct_regression_network_paper net_size_w99 net_size3_w99 net_size3_m_w99 net_gender3_w99 net_size4_w99 net_size4_m_w99 net_gender4_w99 net_coop_pos net_coop_neg, gen(netnumb_w99)

		* w95
rct_regression_network_paper net_size_w95 net_size3_w95 net_size3_m_w95 net_gender3_w95 net_size4_w95 net_size4_m_w95 net_gender4_w95 net_coop_pos net_coop_neg, gen(netnumb_w95)

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
		eqrename(`1'1 = `"Monthly business `=char(13)'`=char(10)' discussions (ITT)"' `1'2 = `"Monthly business `=char(13)'`=char(10)' discussions (TOT)"') ///
		xtitle("Persons", size(medsmall)) ///  
		leg(off) xsize(4) ysize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-35)) /// negative outer gap --> reduces space btw coef names & plot
		name(el_`generate'_cfp, replace)
	
gr export "${master_regressiontables}/endline/regressions/network/el_`generate'_cfp.png", replace


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
}

***********************************************************************
* 	PART 8: endline results - regression table entrepreneurial empowerment
***********************************************************************
{
	
**************** TABLES FOR PAPER ****************
* change label for table output
lab var car_efi_fin1 "access new funding"
lab var car_loc_env "grasp internal and external dynamics"
lab var car_loc_exp "deal with exports requisities"
lab var car_loc_soin "balance personal and professional life"

{
capture program drop rct_confidence // enables re-running
program rct_confidence
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
	local i = 1
	foreach var in `varlist' {		// do following for all variables in varlist seperately			
		* start with midline results for first var/column
		if `i' == 1 {	
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
		   estadd scalar ml_control_mean = r(mean)
		   estadd scalar ml_control_sd = r(sd)
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
		   estadd scalar ml_control_mean = r(mean)
		   estadd scalar ml_control_sd = r(sd)
        }
		
		* put = 2 to move to endline		 
		local i = `i' + 1
		} 
		else {
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
		   estadd scalar ml_control_mean = r(mean)
		   estadd scalar ml_control_sd = r(sd)
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
		   estadd scalar ml_control_mean = r(mean)
		   estadd scalar ml_control_sd = r(sd)
        }
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
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2  // adjust manually to number of variables 
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



**************** TABLES FOR PRESENTATION ****************
**************** efi ****************

* change directory
cd "${master_regressiontables}/endline/regressions/confidence"

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

**************** locus ****************

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
capture program drop kt_overview // enables re-running
program kt_overview
version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	capture confirm variable `var'_y0
        if _rc == 0 {	
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
			else {
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment i.strata_final if surveyround == 3, cluster(consortia_cluster)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' i.strata_final (take_up = i.treatment) if surveyround == 3, cluster(consortia_cluster) first
			estadd local bl_control "Yes"
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
		local regressions `1'1 `2'1 // `3'1 adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/rt_`generate'.tex", replace ///
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
		local regressions `1'2 `2'2 // `3'2 adjust manually to number of variables 
		esttab `regressions' using "${master_regressiontables}/endline/regressions/rt_`generate'.tex", append ///
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
	
gr export "${master_regressiontables}/endline/regressions/el_`generate'_cfp.png", replace


end
	
kt_overview mpi ipi, gen(kt) // eri

***********************************************************************
* 	PART 9: endline results - regression table innovation knowledge transfer
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
				drop(_cons *.strata_final) ///  L.* oL.*
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 // adjust manually to number of variables 
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
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Process innovations} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		eqrename(`1'1 = `"Production technology (ITT)"' `1'2 = `"Production technology (TOT)"' `2'1 = `"Marketing channels (ITT)"' `2'2 = `"Marketing channels (TOT)"' `3'1 = `"Pricing methods (ITT)"' `3'2 = `"Pricing methods (TOT)"' `4'1 = `"Suppliers (ITT)"' `4'2 = `"Suppliers (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
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
		eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Events (ITT)"' `3'2 = `"Events (TOT)"' `4'1 = `"Clients (ITT)"' `4'2 = `"Clients (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		title("Innovation") ///
		subtitle("Sources") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

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
* 	PART 10: endline results - regression table management knowledge transfer
***********************************************************************
**************** memory limit clear all and reload ****************
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

**************** TABLES FOR PRESENTATION ****************
{
**************** Management index mpi ****************
capture program drop mpi_presentation // enables re-running
program mpi_presentation
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
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)), ///
	keep(*treatment take_up) drop(_cons) xline(0) /// xlabel(0(1)10)
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (ITT)"' `1'2 = `"Management `=char(13)'`=char(10)' Practices `=char(13)'`=char(10)' Index (TOT)"') ///
		xtitle("Treatment Effect", size(medsmall)) ///  
		leg(off) xsize(4) ysize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height 
		ysc(outergap(-50)) /// negative outer gap --> reduces space btw coef names & plot
		name(el_`generate'_cfp, replace)
	
gr export "${master_regressiontables}/endline/regressions/management/el_`generate'_cfp.png", replace


end
	
mpi_presentation mpi, gen(mpi)	


**************** man_fin_per ****************
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

**************** man_fin_fre ****************

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

**************** man_fin_pra ****************

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
		esttab `regressions' using "${master_regressiontables}/endline/regressions/management/rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management source of innovations} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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
		eqrename(`1'1 = `"Consultant (ITT)"' `1'2 = `"Consultant (TOT)"' `2'1 = `"Other Entrepreneurs (ITT)"' `2'2 = `"Other Entrepreneurs (TOT)"' `3'1 = `"Family & Friends (ITT)"' `3'2 = `"Family & Friends (TOT)"' `4'1 = `"Events (ITT)"' `4'2 = `"Events (TOT)"' `5'1 = `"Other (ITT)"' `5'2 = `"Other (TOT)"') ///
		title("New Management Practices", size(medium)) ///
		subtitle("Sources", size(medsmall)) ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(10)) ///
		note("{bf:Note}: The Consultant (TOT) is significant at the 10% level.", span) ///
		name(el_`generate'_cfplot, replace)
	
gr export "${master_regressiontables}/endline/regressions/management/el_`generate'_cfplot.png", replace

end

	* apply program to sources of management practices
rct_regression_mans man_source_cons man_source_pdg man_source_fam man_source_even man_source_autres, gen(mans)

}

}

***********************************************************************
* 	PART 11: endline results - regression table export knowledge transfer
***********************************************************************
{
	* change directory
cd "${master_regressiontables}/endline/regressions/export"

capture program drop eri_presentation // enables re-running
program eri_presentation
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
		esttab `regressions' using rt_`generate'.tex, replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge Transfer - Export Readiness Index} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{3}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2  // adjust manually to number of variables 
		esttab `regressions' using rt_`generate'.tex, append ///
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
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) /// xlabel(0(1)10)
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Export `=char(13)'`=char(10)' Readiness `=char(13)'`=char(10)' Index, General (ITT)"' `1'2 = `"Export `=char(13)'`=char(10)' Readiness `=char(13)'`=char(10)' Index, General (TOT)"' `2'1 = `"Export `=char(13)'`=char(10)' Readiness `=char(13)'`=char(10)' Index, SSA (ITT)"' `2'2 = `"Export `=char(13)'`=char(10)' Readiness `=char(13)'`=char(10)' Index, SSA (TOT)"') ///
		xtitle("Treatment Effect", size(medsmall)) ///  
		leg(off) xsize(4) ysize(4) /// xsize controls aspect ratio, makes graph wider & reduces its height 
		ysc(outergap(-40)) /// negative outer gap --> reduces space btw coef names & plot
		name(el_`generate'_cfp, replace)
	
gr export el_`generate'_cfp.png, replace


end
	
	* apply program to export readiness index
eri_presentation eri eri_ssa, gen(eri)	


**************** exp_pra ****************
{

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
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") 
				// when inserting table in overleaf/latex, requires adding space after %
				// P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors
				
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
		title("Export Readiness") ///
		subtitle("General") ///
		eqrename(`1'1 = `"Export manager (ITT)"' `1'2 = `"Export manager (TOT)"' `2'1 = `"Trade fair participation (ITT)"' `2'2 = `"Trade fair participation (TOT)"' `3'1 = `"Commmercial partner (ITT)"' `3'2 = `"Commercial partner  (TOT)"' `4'1 = `"Intl. certification (ITT)"' `4'2 = `"Intl. certification (TOT)"' `5'1 = `"Invested in sales structure (ITT)"' `5'2 = `"Invested in sales structure (TOT)"') ///
		xtitle("Treatment coefficient", size(medsmall)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		ysc(outergap(-5)) ///
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
		title("Export Readiness") ///
		subtitle("Sub-Sahara Africa") ///
		eqrename(`1'1 = `"Potential client (ITT)"' `1'2 = `"Potential client (TOT)"' `2'1 = `"Commercial partner (ITT)"' `2'2 = `"Commercial partner (TOT)"' `3'1 = `"Financial support (ITT)"' `3'2 = `"Financial support (TOT)"' `4'1 = `"Invested in sales structure (ITT)"' `4'2 = `"Invested in sales structure (TOT)"') ///
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

***********************************************************************
* 	PART 12: endline results - regression table export
***********************************************************************
**************** export - extensive margin ****************
{
	* change directory
cd "${master_regressiontables}/endline/regressions/export"
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
		eqrename(`1'1 = `"Direct Export (ITT)"' `1'2 = `"Direct Export (TOT)"' `2'1 = `"Export via intermediate (ITT)"' `2'2 = `"Export via intermediate  (TOT)"' `3'1 = `"Export sales > 0, 2023 (ITT)"' `3'2 = `"Export sales > 0, , 2023 (TOT)"'  `4'1 = `"Export sales > 0, 2024 (ITT)"' `4'2 = `"Export sales > 0, 2024 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export - extensive margin
rct_regression_exp export_1 export_2 exported exported_2024, gen(exp_ext)

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
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2  // adjust manually to number of variables 
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
		eqrename(`1'1 = `"Export countries (ITT)"' `1'2 = `"Export countries (TOT)"' `2'1 = `"Export countries SSA (ITT)"' `2'2 = `"Export countries SSA (TOT)"' `3'1 = `"Clients abroad (ITT)"' `3'2 = `"Clients abroad (TOT)"' `4'1 = `"Clients abroad SSA (ITT)"' `4'2 = `"Clients abroad SSA (TOT)"' `5'1 = `"Orders SSA (ITT)"' `5'2 = `"Orders SSA (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_expclients exp_pays_w99 exp_pays_ssa_w99 clients_w99 clients_ssa_w99 orderssa_w99, gen(exp_int99)

rct_regression_expclients exp_pays_w95 exp_pays_ssa_w95 clients_w95 clients_ssa_w95 orderssa_w95, gen(exp_int95)

}
}
}

***********************************************************************
* 	PART 13: endline results - regression performance results
***********************************************************************
{
* change directory
cd "${master_regressiontables}/endline/regressions/compta"
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
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Employees wins. 99th (ITT)"' `1'2 = `"Employees wins. 99th (TOT)"' `2'1 = `"Female employees wins. 99th (ITT)"' `2'2 = `"Female employees wins. 99th (TOT)"' `3'1 = `"Young employees < 36 wins. 99th (ITT)"' `3'2 = `"Young employees < 36 wins. 99th  (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_empl employes_w99 car_empl1_w99 car_empl2_w99, gen(empl)

}

**************** financial wins 99th ****************
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
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  // adjust manually to number of variables 
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
		* win99
rct_regression_fin ihs_ca_w99_k1 ihs_ca_2024_w99_k1 ihs_catun_w99_k1 ihs_catun2024_w99_k1 ihs_ca_exp_w99_k1 ihs_caexp2024_w99_k1 ihs_costs_w99_k1 ihs_costs_2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k1, gen(fin_k1_w99)
}


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
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  // adjust manually to number of variables 
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
		eqrename(`1'1 = `"Sales 2023 wins. 95th (ITT)"' `1'2 = `"Sales 2023 wins. 95th (TOT)"' `2'1 = `"Sales 2024 wins. 95th (ITT)"' `2'2 = `"Sales 2024 wins. 95th (TOT)"' `3'1 = `"Domestic Sales 2023 wins. 95th (ITT)"' `3'2 = `"Domestic Sales 2023 wins. 95th (TOT)"'  `4'1 = `"Domestic Sales 2024 wins. 95th (ITT)"' `4'2 = `"Domestic Sales 2024 wins. 95th (TOT) "' `5'1 = `"Export turnover 2023 wins. 95th (ITT)"' `5'2 = `"Export turnover 2023 wins. 95th (TOT)"' `6'1 = `"Export turnover 2024 wins. 95th (ITT)"' `6'2 = `"Export turnover 2024 wins. 95th (TOT)"' `7'1 = `"Costs 2023 wins. 95th (ITT)"' `7'2 = `"Costs 2023 wins. 95th (TOT)"' `8'1 = `"Costs 2024 wins. 95th (ITT)"' `8'2 = `"Costs 2024 wins. 95th (TOT)"'  `9'1 = `"Profit 2023 wins. 95th (ITT)"' `9'2 = `"Profit 2023 wins. 95th (TOT) "' `10'1 = `"Profit 2024 wins. 95th (ITT)"' `10'2 = `"Profit 2024 wins. 95th (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
		* win95
rct_regression_fin ihs_ca_w95_k1 ihs_ca_2024_w95_k1 ihs_catun_w95_k1 ihs_catun2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1 ihs_costs_w95_k1 ihs_costs_2024_w95_k1 ihs_profit_w95_k1 ihs_profit2024_w95_k1, gen(fin_k1_w95)

}
**************** financial k^4 ****************

{
capture program drop rct_regression_fink4 // enables re-running
program rct_regression_fink4
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
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions ihs wins. 99th k^} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		eqrename(`1'1 = `"IHS Sales 2023 wins. 99th k^5 (ITT)"' `1'2 = `"IHS Sales 2023 wins. 99th k^5 (TOT)"' `2'1 = `"IHS Sales 2024 wins. 99th k^5 (ITT)"' `2'2 = `"IHS Sales 2024 wins. 99th k^5 (TOT)"' `3'1 = `"IHS Domestic Sales 2023 wins. 99th k^5 (ITT)"' `3'2 = `"IHS Domestic Sales 2023 wins. 99th k^5 (TOT)"'  `4'1 = `"IHS Domestic Sales 2024 wins. 99th k^5 (ITT)"' `4'2 = `"IHS Domestic Sales 2024 wins. 99th k^5 (TOT) "' `5'1 = `"IHS Export turnover 2023 wins. 99th k^5 (ITT)"' `5'2 = `"IHS Export turnover 2023 wins. 99th k^5 (TOT) "' `6'1 = `"IHS Export turnover 2024 wins. 99th k^5 (ITT)"' `6'2 = `"IHS Export turnover 2024 wins. 99th k^5 (TOT)"' `7'1 = `"IHS Costs 2023 wins. 99th k^5 (ITT)"' `7'2 = `"IHS Costs 2023 wins. 99th k^5 (TOT)"' `8'1 = `"IHS Costs 2024 wins. 99th k^5 (ITT)"' `8'2 = `"IHS Costs 2024 wins. 99th k^5 (TOT)"'  `9'1 = `"IHS Profit 2023 wins. 99th k^5 (ITT)"' `9'2 = `"IHS Profit 2023 wins. 99th  k^5 (TOT) "' `10'1 = `"IHS Profit 2024 wins. 99th k^5 (ITT)"' `10'2 = `"IHS Profit 2024 wins. 99th k^5 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_fink4 ihs_ca_w99_k4 ihs_ca_2024_w99_k4 ihs_catun_w99_k4 ihs_catun2024_w99_k4 ihs_ca_exp_w99_k4 ihs_caexp2024_w99_k4 ihs_costs_w99_k4 ihs_costs_2024_w99_k4 ihs_profit_w99_k4 ihs_profit2024_w99_k4, gen(fin_k4_w99)

}

{
capture program drop rct_regression_fink4 // enables re-running
program rct_regression_fink4
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
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 `7'1 `8'1 `9'1 `10'1  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Financial regressions ihs wins. 99th k^} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		eqrename(`1'1 = `"IHS Sales 2023 wins. 95th k^5 (ITT)"' `1'2 = `"IHS Sales 2023 wins. 95th k^5 (TOT)"' `2'1 = `"IHS Sales 2024 wins. 95th k^5 (ITT)"' `2'2 = `"IHS Sales 2024 wins. 95th k^5 (TOT)"' `3'1 = `"IHS Domestic Sales 2023 wins. 95th k^5 (ITT)"' `3'2 = `"IHS Domestic Sales 2023 wins. 95th k^5 (TOT)"'  `4'1 = `"IHS Domestic Sales 2024 wins. 95th k^5 (ITT)"' `4'2 = `"IHS Domestic Sales 2024 wins. 95th k^5 (TOT) "' `5'1 = `"IHS Export turnover 2023 wins. 95th k^5 (ITT)"' `5'2 = `"IHS Export turnover 2023 wins. 95th k^5 (TOT) "' `6'1 = `"IHS Export turnover 2024 wins. 95th k^5 (ITT)"' `6'2 = `"IHS Export turnover 2024 wins. 95th k^5 (TOT)"' `7'1 = `"IHS Costs 2023 wins. 95th k^5 (ITT)"' `7'2 = `"IHS Costs 2023 wins. 95th k^5 (TOT)"' `8'1 = `"IHS Costs 2024 wins. 95th k^5 (ITT)"' `8'2 = `"IHS Costs 2024 wins. 95th k^5 (TOT)"'  `9'1 = `"IHS Profit 2023 wins. 95th k^5 (ITT)"' `9'2 = `"IHS Profit 2023 wins. 95th  k^5 (TOT) "' `10'1 = `"IHS Profit 2024 wins. 95th k^5 (ITT)"' `10'2 = `"IHS Profit 2024 wins. 95th k^5 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_fink4 ihs_ca_w95_k4 ihs_ca_2024_w95_k4 ihs_catun_w95_k4 ihs_catun2024_w95_k4 ihs_ca_exp_w95_k4 ihs_caexp2024_w95_k4 ihs_costs_w95_k4 ihs_costs_2024_w95_k4 ihs_profit_w95_k4 ihs_profit2024_w95_k4, gen(fin_k4_w95)

}

**************** export k^s ****************
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
rct_regression_finexpks ihs_caexp2024_w99_k1 ihs_ca_exp_w99_k1 ihs_caexp2024_w99_k2 ihs_ca_exp_w99_k2 ihs_caexp2024_w99_k3 ihs_ca_exp_w99_k3 ihs_caexp2024_w99_k4 ihs_ca_exp_w99_k4, gen(finexpks)

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
		eqrename(`1'1 = `"Profitable 2023 (ITT)"' `1'2 = `"Profitable 2023 (TOT)"' `2'1 = `"Profitable 2024 (ITT)"' `2'2 = `"Profitable 2024 (TOT)"' `3'1 = `"Profitable 2021-2024 (ITT)"' `3'2 = `"Profitable 2021-2024 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(el_`generate'_cfplot, replace)
	
gr export el_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_pft profit_2023_category profit_2024_category profit_pos, gen(pft)

}
}