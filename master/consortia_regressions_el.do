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
* 	Part 0: create a program to estimate sharpened q-values
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
* 	PART 0.1:  set the stage - generate export & business performance z-scores
***********************************************************************
{
{
local indexes ///
	 net_size net_gender man_fin_per man_fin_per_fre comp_ca2023 comp_ca2024 comp_exp2023 comp_exp2024 comp_benefice2023 comp_benefice2024 inno_produit inno_process man_mark_pra eai lai epi empl car_carempl_div1

foreach var of local indexes {
		* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]		 // filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)					 // create variable = bl value for all three surveyrounds by id_plateforme
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first													// clean up
	lab var `var'_y0 "Y0 `var'"
		* generate missing baseline dummy
	gen miss_bl_`var' = 0 if surveyround == 1											// gen dummy for baseline
	replace miss_bl_`var' = 1 if surveyround == 1 & inlist(`var',., -777, -888, -999)	// replace dummy 1 if variable missing at bl
	egen missing_bl_`var' = min(miss_bl_`var'), by(id_plateforme)									// expand dummy to ml, el
	lab var missing_bl_`var' "YO missing, `var'"
	drop miss_bl_`var'
	}
}

***********************************************************************
* 	PART 1: survey attrition 		
***********************************************************************

*test for differential total attrition
{
	* is there differential attrition between treatment and control group?
		* column (1): at endline
eststo att1, r: areg refus i.treatment if surveyround == 3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
		* column (2): at endline
eststo att2, r: areg refus i.treatment if surveyround == 3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

		* column (3): at baseline
eststo att3, r: areg refus i.treatment if surveyround == 1, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

local attrition att1 att2 att3
esttab `attrition' using "el_attrition.tex", replace ///
	title("Attrition: Total") ///
	mtitles("EL" "ML" "BL") ///
	label ///
	b(3) ///
	se(3) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls") ///
	addnotes("All standard errors are Hubert-White robust standord errors clustered at the firm level." "Indexes are z-score as defined in Kling et al. 2007.")
		
}

*test for selective attrition on key outcome variables (indexes)
{
		* c(1): efficacy affirmation index
eststo att4,r: areg  eai treatment##refus eai_y0 i.missing_bl_eai if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
		* c(2): locus of control affirmation index
eststo att5,r: areg  lai treatment##refus lai_y0 i.missing_bl_lai if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
		* c(3): export prep index
eststo att6,r: areg  epi treatment##refus digmarkt_epi i.missing_bl_epi if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"	

		* c(4): net_size
eststo att7,r: areg  net_size treatment##refus net_size_y0 i.missing_bl_net_size if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
		* c(5): net_gender
eststo att8,r: areg  net_gender treatment##refus net_gender_y0 i.missing_bl_net_gender if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"		// consider replacing with quantile transformed profits instead

		* c(6): empl
eststo att9,r: areg  empl treatment##refus empl_y0 i.missing_bl_empl if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
		* c(7): female employees
eststo att10,r: areg  car_carempl_div1 treatment##refus car_carempl_div1_y0 i.missing_bl_car_carempl_div1 if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

local attrition att4 att5 att6 att7 att8 att9 att10
esttab `attritionkey' using "el_keyattrition.tex", replace ///
	title("Attrition: Indexes") ///
	mtitles("Efficacy affirmation index" "Affirmation locus" "Export preparation index" "Network size" "Network size of females" "Employees" "Female employees") ///
	label ///
	b(3) ///
	se(3) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls") ///
	addnotes("Notes: All Columns consider only endline response behaviour."  "All standard errors are Hubert-White robust standord errors clustered at the firm level." "Indexes are z-score as defined in Kling et al. 2007.")
}
      

{
*test for selective attrition on key outcome variables
		* c(1): performance indicators measuring
eststo att4,r: areg man_fin_per treatment##refus man_fin_per_y0 i.missing_bl_man_fin_per if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
		* c(2): performance indiactors measuring frequency
eststo att5,r: areg man_fin_per_fre treatment##refus man_fin_per_fre_y0 i.missing_bl_man_fin_per_fre if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
		* c(3):  comp_ca2023
eststo att6,r: areg  comp_ca2023 treatment##refus comp_ca2023_y0 i.missing_bl_comp_ca2023 if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"		// WINS? IHS? AVERAGE?

		* c(4): comp_ca2024
eststo att7,r: areg comp_ca2024 treatment##refus comp_ca2024_y0 i.missing_bl_comp_ca2024 if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"	// WINS? IHS? AVERAGE?
		
		* c(5): comp_benefice2023
eststo att8,r: areg comp_benefice2023 treatment##refus comp_benefice2023_y0 i.missing_bl_comp_benefice2023 if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"	// WINS? IHS? AVERAGE?

		* c(6): comp_benefit2024
eststo att9,r: areg  comp_benefice2024 treatment##refus comp_benefice2024_y0 i.missing_bl_comp_benefice2024 if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

		* c(7): inno_produit
eststo att10,r: areg inno_produit treatment##refus inno_produit_y0 i.missing_bl_inno_produit if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

		* c(8): inno_process
eststo att11,r: areg inno_process treatment##refus inno_process_y0 i.missing_bl_inno_process if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"

		* c(9): man_mark_pra
eststo att12,r: areg man_mark_pra treatment##refus man_mark_pra_y0 i.missing_bl_man_mark_pra if surveyround==3, absorb(strata) cluster(id_plateforme)
estadd local strata "Yes"
		
local attrition att4 att5 att6 att7 att8 att9 att10 att11 att12
esttab `attritionkey' using "el_keyattrition.tex", replace ///
	title("Attrition: Key outcomes") ///
	mtitles("Performance indicators measuring" " Performance indiactors measuring frequency" "Turnover 2023" "Turnover 2024" "Profit 2023" "Profit 2024" "Product innovations" "Process innovations" "Marketing practices") ///
	label ///
	b(3) ///
	se(3) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls") ///
	addnotes("Notes: All Columns consider only endline response behaviour."  "All standard errors are Hubert-White robust standord errors clustered at the firm level." "Indexes are z-score as defined in Kling et al. 2007.")
}	

/*	
* baseline balance after attrition
	* with outliers (Gourmandise)
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exp_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0, grpvar(treatment) ftest fmissok  vce(robust) format(%12.2fc) save(baltab_endline_all) replace
						 
	* w/o outliers
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exp_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0 & id_plateforme != 1092, grpvar(treatment) ftest fmissok vce(robust) format(%12.2fc) save(baltab_endline_wo_outlier) replace 

}
*/
}
***********************************************************************
* 	PART 2: list experiment regression
***********************************************************************
	
{
	* ITT, ancova	
			* baseline differences amount
eststo lexp1, r: reg listexp1 i.list_group i.strata_final if surveyround == 1, cluster(id_plateforme)
estadd local strata "Yes"

		
			* ancova with stratification dummies 
eststo lexp2, r: reg listexp1 i.treatment##i.list_group l.listexp1 i.strata_final missing_bl_listexp1 if surveyround == 3, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"		

* ancova with stratification dummies 
eststo lexp3, r: reg listexp1 i.treatment##i.list_group l.listexp1 i.strata_final missing_bl_listexp1 if surveyround == 3, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"	

esttab lexp1 lexp2 lexp3 using "el_listexp1.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{List experiment: Independent entrepreneurial decision-making} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(N strata bl_control, fmt(%9.0fc) labels("Observations" "Strata controls" "Y0 controls")) ///
				mtitles("Baseline" "endline" "Endline") ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final missing* L.*) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{10}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Column (1) presents baseline results with strata controls." "Column (2) presents an ANCOVA specification with strata controls." "Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
}
	
***********************************************************************
* 	PART 3: Endline results - regression table network outcomes
***********************************************************************

{
capture program drop rct_regression_network // enables re-running the program
program rct_regression_network
	version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment `var'_y0 i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' `var'_y0 i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take endline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
	
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

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
	seed(110723) reps(999) usevalid strata(strata_final)

		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
		
	* Put all regressions into one table
		* Top panel: ATE
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Business Networks} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.* oL.*) ///
				noobs
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* L.* `2' `3') ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. The only exception are columns 2 and 3 for which we did not collect baseline data. The number of observations for network quality is only 123 as all other 18 firms reported zero contacts with other entrepreneurs. The total of female, male and all other CEOs met are winsorized at the 99th percentile. Coefficients display absolute values of the outcomes. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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
		eqrename(`1'1 = `"Total network size (ITT)"' `1'2 = `"Total network size (TOT)"' `2'1 = `"Female CEOs met (ITT)"' `2'2 = `"Female CEOs met (TOT)"' `3'1 = `"Male CEOs met (ITT)"' `3'2 = `"Male CEOs met (TOT)"' `4'1 = `"Network quality (ITT)"' `4'2 = `"Network quality (TOT)"' `5'1 = `"Pos. view CEO interaction (ITT)"' `5'2 = `"Pos. view CEO interaction (TOT)"' `6'1 = `"Neg. view CEO interaction (ITT)"' `6'2 = `"Neg. view CEO interaction (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace
			
end

	* apply program to network outcomes
rct_regression_network net_size net_size1 net_size2 net_size3 net_size4 net_gender net_gender1 net_gender2 net_gender3 net_gender4 net_gender2_giz net_nb_f net_nb_m net_nb_qualite net_coop_pos net_coop_neg, gen(network_outcomes)

}


***********************************************************************
* 	PART 10: endline results - regression empowerment outcomes
***********************************************************************
{
capture program drop rct_regression_empowerment // enables re-running
program rct_regression_empowerment
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_median = r(p50)
estadd scalar control_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Entrepreneurial confidence and Empowerment} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot (`1'1, pstyle(p1)) (`1'2, pstyle(p1)) (`2'1, pstyle(p2)) (`2'2, pstyle(p2)) (`3'1, pstyle(p3)) (`3'2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(genderi1 = `"Entrepreneurial empowerment (ITT)"' genderi2 = `"Entrepreneurial empowerment (TOT)"' female_efficacy1 = `"Efficacy (ITT)"' female_efficacy2 = `"Efficacy (TOT)"' female_loc1 = `"Locus of control (ITT)"' female_loc2 = `"Locus of control (TOT)"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace

	
end

	* apply program to business performance outcomes
rct_regression_empowerment genderi female_efficacy female_loc, gen(empowerment)

}

***********************************************************************
* 	PART 11: endline results - regression table knowledge transfer
***********************************************************************
{
capture program drop rct_regression_kt // enables re-running
program rct_regression_kt
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
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
	seed(110723) reps(999) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
*/		
		
		* Put all regressions into one table
			* Top panel: ITT
		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management practices, Innovation, Export readiness} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.* oL.*) ///
				noobs
			
			* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* L.* `5' `6') ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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
		eqrename(`1'1 = `"Management practices (ITT)"' `1'2 = `"Management practices (TOT)"' `2'1 = `"Innovations (ITT)"' `2'2 = `"Innovations (TOT)"' `3'1 = `"Innovated (ITT)"' `3'2 = `"Innovated (TOT)"' `4'1 = `"Export readiness (ITT)"' `4'2 = `"Export readiness (TOT)"' `5'1 = `"Export readiness SSA, ihs (ITT)"' `5'2 = `"Export readiness SSA, ihs (TOT)"' `6'1 = `"SSA client (ITT)"' `6'2 = `"SSA client (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace

end

	* apply program to export outcomes
rct_regression_kt mpi innovations innovated eri eri_ssa ssa_action1, gen(kt)

}


***********************************************************************
* 	PART 12: endline results - regression table business performance outcomes
***********************************************************************
{
capture program drop rct_regression_business // enables re-running
program rct_regression_business
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

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
	seed(110723) reps(999) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
/*		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Business performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.*) /// oL.*
				noobs
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{7}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, thousands for employee variables and ten thousands for all other variables, as described in Aihounton and Henningsen (2020). The only exception is the percentile transformed profit variable in column (4) (Delius and Sterck, 2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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
		eqrename(`1'1 = `"Domestic sales (ITT)"' `1'2 = `"Domestic sales (TOT)"' `2'1 = `"Total sales (ITT)"' `2'2 = `"Total sales (TOT)"' `4'1 = `"Profit, pct (ITT)"' `4'2 = `"Profit, pct (TOT)"' `5'1 = `"Employees (ITT)"' `5'2 = `"Employees (TOT)"' `6'1 = `" Female Employees (ITT)"' `6'2 = `"Female employees (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  `3'1 = `"Profit, ihs (ITT)"' `3'2 = `"Profit, ihs (TOT)"'
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace
*/			
end

	* apply program to business performance outcomes
rct_regression_business ihs_ca_w99_k4 ihs_sales_w99_k4 ihs_profit_w99_k1 profit_pct ihs_employes_w99_k3 car_empl1_w99_k3, gen(business_outcomes)

}		
	
***********************************************************************
* 	PART 13: endline results - regression table export outcomes
***********************************************************************
{
capture program drop rct_regression_export // enables re-running
program rct_regression_export
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
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
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
*/		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Export performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
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
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile and ihs-transformed. The units for ihs-transformation are chosen based on the highest R-square, ten thousands for all variables, as described in Aihounton and Henningsen (2020). Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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
		eqrename(`1'1 = `"Export investment > 0 (ITT)"' `1'2 = `"Export > 0 investment (TOT)"' `2'1 = `"Export investment, ihs (ITT)"' `2'2 = `"Export investment, ihs (TOT)"' `3'1 = `"Export costs (ITT)"' `3'2 = `"Export costs (TOT)"' `4'1 = `"Exported (ITT)"' `4'2 = `"Exported (TOT)"' `5'1 = `"Export sales, ihs (ITT)"' `5'2 = `"Export sales, ihs (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace
*/				
end

	* apply program to export outcomes
rct_regression_export exp_invested ihs_exp_inv_w99_k4 exprep_couts exported ihs_ca_exp_w99_k4, gen(export_outcomes)

}	
	
***********************************************************************
* 	PART 14: endline results - profit
***********************************************************************
* try to have two different columns for coefplot of profits?
{
capture program drop rct_regression_profit // enables re-running
program rct_regression_profit
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
	* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)

		}
		
* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

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
	seed(110723) reps(999) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
/*		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Sensitivity of impact on profit depending on profit-transformation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
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
				postfoot("\hline\hline\hline \\ \multicolumn{6}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All variables are winsorized at the 99th percentile (apart from the positive profit dummy). \textit{K} refers to the units of profits. K $=4$ implies profit is measured in units of ten thousand ($10^4$), k $=3$ implies profit is measured in units of thousand ($10^4$), and so forth. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. Confidence intervals are documented below the adjusted p-values.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1'1, pstyle(p1)) (`1'2, pstyle(p1)) ///
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) /// 
	(`3'1, pstyle(p3)) (`3'2, pstyle(p3)) ///
	(`4'1, pstyle(p4)) (`4'2, pstyle(p4)) ///
	(`5'1, pstyle(p5)) (`5'2, pstyle(p5)) ///
	(`6'1, pstyle(p5)) (`6'2, pstyle(p6)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) ///
		eqrename(`1'1 = `"Profit, k = 1 (ITT)"' `1'2 = `"Profit, k = 1 (TOT)"' `2'1 = `"Profit, k = 2 (ITT)"' `2'2 = `"Profit, k = 2 (TOT)"' `3'1 = `"Profit, k = 3 (ITT)"' `3'2 = `"Profit, k = 3"' `4'1 = `"Profit, k = 4 (ITT)"' `4'2 = `"Profit, k = 4 (TOT)"' `5'1 = `"Profit, pct (ITT)"' `5'2 = `"Profit, pct (TOT)"' `6'1 = `"Profit > 0 (ITT)"' `6'2 = `"Profit > 0 (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace
*/				
end

	* apply program to export outcomes
rct_regression_profit ihs_profit_w99_k1 ihs_profit_w99_k2 ihs_profit_w99_k3 ihs_profit_w99_k4 profit_pct profit_pos, gen(profit)

}


***********************************************************************
* 	PART 15: endline results - regression innovation outcomes
***********************************************************************
{
capture program drop rct_regression_innovation // enables re-running
program rct_regression_innovation
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
						
			* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum `var' if treatment == 0 & surveyround == 3
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

		* Correct for MHT - FWER
rwolf2 ///
	(reg `1' treatment `1'_y0 i.missing_bl_`1' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `1' `1'_y0 i.missing_bl_`1' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `2' treatment `2'_y0 i.missing_bl_`2' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `2' `2'_y0 i.missing_bl_`2' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment), cluster(id_plateforme)) ///
	(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final, cluster(id_plateforme)) ///
	(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
/*	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Innovation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				noobs
				
			* Bottom panel: ATT
		local regressions `1'2 `2'2 `3'2 `4'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw ci(fmt(2))) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{5}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All outcomes dummy variables, coded equal to 1 if the firm does a type of innovation and zero otherwise. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot (`1'1, pstyle(p1)) (`1'2, pstyle(p1)) (`2'1, pstyle(p2)) (`2'2, pstyle(p2)) (`3'1, pstyle(p3)) (`3'2, pstyle(p3)) (`4'1, pstyle(p4)) (`4'2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(`1'1 = `"Product innovation (ITT)"' `1'2 = `"Product innovation (TOT)"' `2'1 = `"Process innovation (ITT)"' `2'2 = `"Process innovation (TOT)"' `3'1 = `"Organizational innovation (ITT)"' `3'2 = `"Organizational innovation (TOT)"' `4'1 = `"Marketing innovation (ITT)"' `4'2 = `"Marketing innovation (TOT)"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace
*/
	
end

	* apply program to business performance outcomes
rct_regression_innovation inno_produit inno_process inno_lieu inno_commerce, gen(innovation)

}