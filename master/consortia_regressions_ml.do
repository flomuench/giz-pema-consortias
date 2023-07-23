***********************************************************************
* 			Master analysis/regressions				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake treatment effect analysis of
*				outcomes & sub-group/heterogeneity analyses
*
*													
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium_final.dta
*	Creates:

***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************
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
cd "${master_regressiontables}/midline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on
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
* 	PART 1: balance 		
***********************************************************************
{
	* baseline
		* concern: F-test significant at baseline
				* major outcome variables, untransformed
local network_vars "net_size net_nb_qualite net_coop_pos net_coop_neg"
local empowerment_vars "genderi female_efficacy female_loc"
local kt_vars "mpi innovations innovated inno_rd"
local business_vars "ca profit employes"
local export_vars "eri exprep_couts exprep_inv exported ca_exp"
local vars_untransformed `network_vars' `empowerment_vars' `kt_vars' `business_vars' `export_vars'
				
					* F-test
*local balancevarlist ca_2021 ca_exp_2021 exp_pays exprep_inv exprep_couts inno_rd innovations age net_nb_dehors net_nb_fam net_nb_qualite
reg treatment `vars_untransformed' if surveyround == 1, vce(robust)
testparm `vars_untransformed'
iebaltab `vars_untransformed' if surveyround == 1, ///
	grpvar(treatment) vce(robust) format(%12.2fc) replace ///
	ftest pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
	savetex(baltab_bl_unadj)

				* major outcome variables, transformed
local network_vars "net_size_w99 net_nb_qualite net_coop_pos net_coop_neg"
local empowerment_vars "genderi female_efficacy female_loc"
local kt_vars "mpi innovations innovated inno_rd_w99"
local business_vars "age ihs_ca_w99_k4 profit employes"
local export_vars "eri ihs_ca_exp_w99_k4 exp_pays_w99 ihs_exprep_inv_w99_k4 exprep_couts"
local vars_transformed `network_vars' `empowerment_vars' `kt_vars' `business_vars' `export_vars'
reg treatment `vars_transformed' if surveyround == 1, vce(robust)
testparm `vars_transformed'
iebaltab `vars_transformed' if surveyround == 1, ///
	grpvar(treatment) vce(robust) format(%12.2fc) replace ///
	ftest pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
	savetex(baltab_bl_adj)

}

***********************************************************************
* 	PART 2: survey attrition 		
***********************************************************************
{
*test for differential attrition using the PAP specification (cluster SE, strata)
eststo a2, r:reg  refus treatment if surveyround==2, cluster(id_plateforme)
estadd local strata "No"

eststo a3, r:areg  refus treatment if surveyround==2, absorb(strata_final) cluster(id_plateforme)
estadd local strata "Yes"

eststo a4, r:areg  refus i.pole if surveyround==2, absorb(strata_final) cluster(id_plateforme)
estadd local strata "Yes"

eststo a5, r:reg  refus i.pole if surveyround==2, cluster(id_plateforme)
estadd local strata "No"

local regressions a2 a3 a4 a5
esttab `regressions' using "ml_attrition.tex", replace ///
	mtitles("ML attrition" "ML attrition" "ML attrition" "ML attrition") ///
	label ///
	b(3) ///
	se(3) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls") ///
	addnotes("All standard errors are clustered at firm level.")
	
* baseline balance after attrition
	* with outliers (Gourmandise)
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0, grpvar(treatment) ftest fmissok  vce(robust) format(%12.2fc) save(baltab_midline_all) replace
						 
	* w/o outliers
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0 & id_plateforme != 1092, grpvar(treatment) ftest fmissok vce(robust) format(%12.2fc) save(baltab_midline_wo_outlier) replace 

}
 

***********************************************************************
* 	PART 2: Write a program that generates generic regression table
***********************************************************************
/*	
program rct_regression_table
	version 15								// define Stata version 15 used
	syntax varlist(min=1 numeric), *		// input is variable list, minimum 1 numeric variable. * enables any options.
	foreach var in `varlist' {			// do following for all variables in varlist seperately
					* ITT, ancova´			
						* test no significant baseline differences
			reg `var' i.treatment if surveyround == 1, vce(hc3)

						* pure mean comparison at midline
			eststo `var'1, r: reg `var' i.treatment if surveyround == 2, vce(hc3)
			estadd local bl_control "No"
			estadd local strata "No"
					
						* ancova without stratification dummies
			eststo `var'2, r: reg `var' i.treatment l.`var' i.missing_bl_`var', cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "No"

						* ancova with stratification dummies
			eststo `var'3, r: reg `var' i.treatment l.`var' i.strata_final i.missing_bl_`var', cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate

				* DiD
			eststo `var'4, r: xtreg `var' i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"			

				* ATT, IV (participation in phase 1 meetings)
			eststo `var'5, r:ivreg2 `var' l.`var' i.strata_final i.missing_bl_`var' (take_up_per = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att

				* ATT, IV (participation in consortia)
			eststo `var'6, r:ivreg2 `var' l.`var' i.strata_final i.missing_bl_`var' (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"		
		
		
			* Put all regressions into one table
			local regressions `var'1 `var'2 `var'3 `var'4 `var'5 `var'6
			esttab `regressions' using "rt_`var'.tex", replace ///
				mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
				label ///
				b(3) ///
				se(3) ///
				drop(*.strata_final) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	} // closes loop
	
end

***********************************************************************
* 	PART 3: Apply program to all outcome variables
***********************************************************************
{	
	* network 
rct_regression_table net_size net_nb_qualite net_coop_pos // cannot apply due to missing baseline to: net_nb_f & m

	* female entrepreneurial empowerment
rct_regression_table genderi female_efficacy female_loc

	* management practices
rct_regression_table mpi
	
	* innovation
rct_regression_table innovated innovations
	
	* export
rct_regression_table eri exprep_inv // cannot apply due to missing baseline to: eri_ssa

	* kpi
rct_regression_table ihs_ca_exp_w99 ihs_ca_w99 ihs_profit_w99 profit_pct ihs_employes_w99 car_empl1_w99 car_empl2_w99

}


***********************************************************************
* 	PART 4: Network regression (female network)	- not possible in program
***********************************************************************
{
	* ITT, ancova
			* pure mean comparison at midline 
eststo nf1, r: reg net_nb_f i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo nf2, r: reg net_nb_f i.treatment i.strata_final l.net_size i.missing_bl_net_size, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo nf3, r: reg net_nb_f i.treatment i.strata_final l.net_size i.missing_bl_net_size, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "Yes"

			/* DiD (create an aggreate variable for network size)
eststo ep4, r: xtreg net_nb_f i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			
*/
	* ATT, IV (participation in phase 1 meetings) 
eststo nf4, r:ivreg2 net_nb_f i.strata_final l.net_size i.missing_bl_net_size (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_nf4

	* ATT, IV (participation in consortium)
eststo nf5, r:ivreg2 net_nb_f i.strata_final l.net_size i.missing_bl_net_size (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions nf1 nf2 nf3 nf4 nf5
esttab `regressions' using "ml_net_nb_f.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")

}

***********************************************************************
* 	PART 5: Network regression (male network)	- not possible in program
***********************************************************************
{
	* ITT, ancova
	
			* pure mean comparison at midline (create an aggreate variable for network size)
eststo nm1, r: reg net_nb_m i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo nm2, r: reg net_nb_m i.treatment, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo nm3, r: reg net_nb_m i.treatment i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			/* DiD 
eststo ep4, r: xtreg eri i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			
*/
	* ATT, IV (participation in phase 1 meetings) 
eststo nm4, r:ivreg2 net_nb_m i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_nm4

	* ATT, IV (participation in consortium)
eststo nm5, r:ivreg2 net_nb_m i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions nm1 nm2 nm3 nm4 nm5 
esttab `regressions' using "ml_net_nb_m.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	
}	
	
***********************************************************************
* 	PART 6: SSA Export Readiness index		- not possible in program
***********************************************************************
{
	* ITT, ancova
			* pure mean comparison at midline
eststo esa1, r: reg eri_ssa i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo esa2, r: reg eri_ssa i.treatment l.eri missing_bl_eri, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo esa3, r: reg eri_ssa i.treatment l.eri missing_bl_eri i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* ATT, IV (with 1 session counting as taken up)
eststo esa4, r:ivreg2 eri_ssa l.eri missing_bl_eri i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_esa4

			* ATT, IV (with 1 session counting as taken up)
eststo esa5, r:ivreg2 eri_ssa l.eri missing_bl_eri i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions esa1 esa2 esa3 esa4 esa5
esttab `regressions' using "ml_eri_ssa.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")
	
}


***********************************************************************
* 	PART 8: Check consistency of profit regression to DV definition
***********************************************************************
{
foreach var of varlist profit profit_w99 ihs_profit_w99 profit_pct {
	
				* ancova with stratification dummies
			eststo `var'1, r: reg `var' i.treatment l.`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate

				* DiD
			eststo `var'2, r: xtreg `var' i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"			

				* ATT, IV (participation in phase 1 meetings)
			eststo `var'3, r:ivreg2 `var' l.`var' i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att
			
}

esttab profit? profit_w99? ihs_profit_w99? profit_pct? using "profit_consistency.tex", replace ///
	mtitles("Ancova" "DiD" "ATT" "Ancova" "DiD" "ATT" "Ancova" "DiD" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("")

}

*/
	
***********************************************************************
* 	PART 7: list experiment regression
***********************************************************************
	
{
	* ITT, ancova	
			* baseline differences amount
eststo lexp1, r: reg listexp i.list_group i.strata_final if surveyround == 1, cluster(id_plateforme)
estadd local strata "Yes"

		
			* ancova with stratification dummies 
eststo lexp2, r: reg listexp i.treatment##i.list_group l.listexp i.strata_final missing_bl_listexp, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"		

esttab lexp1 lexp2 using "ml_listexp.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{List experiment: Independent entrepreneurial decision-making} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(N strata bl_control, fmt(%9.0fc) labels("Observations" "Strata controls" "Y0 controls")) ///
				mtitles("Baseline" "Midline") ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final missing* L.*) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{10}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Column (1) presents baseline results with strata controls." "Column (2) presents an ANCOVA specification with strata controls." "Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %

	
}
	
***********************************************************************
* 	PART 9: Midline results - regression table network outcomes
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
				* take midline mean to control for time trend
sum `var' if treatment == 0 & surveyround == 2
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
rct_regression_network net_size_w99 net_nb_f_w99 net_nb_m_w99 net_nb_qualite net_coop_pos net_coop_neg, gen(network_outcomes)

}


***********************************************************************
* 	PART 10: Midline results - regression empowerment outcomes
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
sum `var' if treatment == 0 & surveyround == 2
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
* 	PART 11: Midline results - regression table business performance outcomes
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
sum `var' if treatment == 0
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
	seed(110723) reps(30) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on business performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
	(`2'1, pstyle(p2)) (`2'2, pstyle(p2)) /// 	*(`3'1, pstyle(p3)) (`3'2, pstyle(p3))
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
			
end

	* apply program to business performance outcomes
rct_regression_business ihs_ca_w99_k4 ihs_sales_w99_k4 ihs_profit_w99_k4 profit_pct ihs_employes_w99_k3 car_empl1_w99_k3, gen(business_outcomes)

}		
	
* consider a seperate regression for profit specifically?
	* profit pos yes/no or certain threshold?

***********************************************************************
* 	PART 12: Midline results - regression table export outcomes
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
sum `var' if treatment == 0
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
	(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment), cluster(id_plateforme)), ///
	indepvars(treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up, treatment, take_up) ///
	seed(110723) reps(999) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on export performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{7}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///			
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
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///	
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
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
		eqrename(`1'1 = `"Export investment > 0 (ITT)"' `1'2 = `"Export > 0 investment (TOT)"' `2'1 = `"Export costs (ITT)"' `2'2 = `"Export costs (TOT)"' `3'1 = `"Export investment, ihs (ITT)"' `3'2 = `"Export investment, ihs (TOT)"' `4'1 = `"Exported (ITT)"' `4'2 = `"Exported (TOT)"' `5'1 = `"Export sales, ihs (ITT)"' `5'2 = `"Export sales, ihs (TOT)"') ///
		xtitle("Treatment coefficient", size(medium)) ///  
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace
				
end

	* apply program to export outcomes
rct_regression_export exp_invested ihs_exp_inv_w99_k4 exprep_couts exported ihs_ca_exp_w99_k4, gen(export_outcomes)

}	
	

***********************************************************************
* 	PART 13: Midline results - regression table knowledge transfer
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
sum `var' if treatment == 0 & surveyround == 2
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
	seed(110723) reps(30) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace	
		
		
		* Put all regressions into one table
			* Top panel: ITT
		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Knowledge transfer: Management practices, Innovation, Export readiness} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
* 	PART 14: Midline results - profit
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
sum `var' if treatment == 0
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
	seed(110723) reps(30) usevalid strata(strata_final)
		
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace
		
		* Put all regressions into one table
			* Top panel: ITT
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on export performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{8}{c}} \hline\hline") ///
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
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
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
				
end

	* apply program to export outcomes
rct_regression_profit ihs_profit_w99_k1 ihs_profit_w99_k2 ihs_profit_w99_k3 ihs_profit_w99_k4 profit_pct profit_pos, gen(profit)

}


***********************************************************************
* 	PART 10: Midline results - regression innovation outcomes
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
sum `var' if treatment == 0 & surveyround == 2
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
	seed(110723) reps(30) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Innovation} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
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
		local regressions `1'2 `2'2 `3'2 `4'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_median control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group median" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				label ///
				nobaselevels ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{5}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
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

	
end

	* apply program to business performance outcomes
rct_regression_innovation inno_produit inno_process inno_lieu inno_commerce, gen(innovation)

}



	
***********************************************************************
* 	Archive
***********************************************************************
		* code for Anderson sharpened q values
/*
{
capture program drop rct_regression_network // enables re-running the program
program rct_regression_network
	version 16							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
		
	* ITT: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate	// use eststo dir to see
			quietly ereturn display
			matrix b = r(table)			// access p-values for mht
			scalar `var'p1 = b[4,2]

	* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att
			quietly ereturn display // provides same table but with r(table)
			matrix b = r(table)
			scalar `var'p2 = b[4,1]

		}
	
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

	* Generate Anderson/Hochberg sharpened q-values to control for MH testing/false discovery rate
		* put all p-values into matrix/column vector
mat p = (`1'p1 \ `1'p2 \ `2'p1 \ `2'p2 \ `3'p1 \ `3'p2 \ `4'p1 \ `4'p2 \ `5'p1 \ `5'p2)
mat colnames p = "pvalues"

		* create & go to frame as following command will clear data set
frame copy default pvalues, replace
frame change pvalues
drop _all	
		
		* transform matrix into variable/data set with one variable pvals
svmat double p, names(col)

		* apply q-values program to variable pvalues
qvalues pvalues

		* transform variables into matrix/column
mkmat pvalues bky06_qval, matrix(qs)

		* switch to initial frame & import qvalues
frame change default
	
	* Put all regressions into one table
		* Top panel: ATE
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on female entrepreneurs' business network} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				mtitles("`1'" "`2'" "`3'" "`4'" "`5'") ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3))) label ///
				nobaselevels ///
				drop(*.strata_final ?.missing_bl_* *L.*) ///
				scalars("strata Strata controls" "bl_control Y0 control")
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3))) label /// qvalues(fmt(3))
				drop(*.strata_final ?.missing_bl_* *L.*) ///
				nobaselevels ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \multicolumn{6}{l}{\footnotesize Robust Standard errors in parentheses.} \\ \multicolumn{6}{l}{\footnotesize All outcomes are in absolute values.} \\ \multicolumn{6}{l}{\footnotesize \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\).} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
			
end

	* apply program to business performance outcomes
rct_regression_network net_size net_nb_f net_nb_m net_nb_qualite net_coop_pos, gen(network_outcomes)

}

*/

		* Attemps to automize integration of RW p-values in regression table
/* 
*ereturn list
* estadd mat = e(RW)

	* loop over models & variables simultaneously
			* models : `1'1, `1'2
/*			
foreach var in `varlist' {
	estadd scalar rw_itt = e(rw_`var'_treatment), replace : `var'1
	*eststo `var'1, add(rw_`var'_treatment)
	estadd scalar rw_tot = e(rw_`var'_take_up), replace : `var'2
	*eststo `var'2, add(rw_`var'_take_up)

}
*/
/*	
mat rw = e(RW)
	scalar rw_itt = rw[1,3]
	estadd scalar rw_itt = rw_itt, replace : `1'1 /// get rw p-value for itt
	scalar rw_tot = rw[2,3]
	estadd scalar rw_tot = rw_tot, replace : `1'2 /// get rw p-value for tot
	
	scalar rw_itt = rw[3,3]
	estadd scalar rw_itt = rw_itt, replace : `2'1 /// get rw p-value for itt
	scalar rw_tot = rw[4,3]
	estadd scalar rw_tot = rw_tot, replace : `2'2 /// get rw p-value for tot
	
	scalar rw_itt = rw[5,3]
	estadd scalar rw_itt = rw_itt, replace : `3'1 /// get rw p-value for itt
	scalar rw_tot = rw[6,3]
	estadd scalar rw_tot = rw_tot, replace : `3'2 /// get rw p-value for tot
*/

/*	estadd scalar rw_itt = rw[3,3], replace : `2'1 /// get rw p-value for itt
	estadd scalar rw_tot = rw[4,3], replace : `2'2 /// get rw p-value for tot
	estadd scalar rw_itt = rw[5,3], replace : `3'1 /// get rw p-value for itt
	estadd scalar rw_tot = rw[6,3], replace : `3'2 /// get rw p-value for tot
*/
/*
foreach var in `varlist' {
	scalar rw_itt`row' = rw[`row',3]
	estadd scalar rw_itt = rw_itt`row', replace : `var'1 /// get rw p-value for itt
	local row = `row' + 1
	scalar rw_tot`row' = rw[`row',3]
	estadd scalar rw_tot = rw_tot`row', replace : `var'2 /// get rw p-value for tot
	local row = `row' + 1
}
*/
/*
estadd scalar = rw[3,3], : `2'1 /// get rw p-value for itt
estadd scalar = rw[4,3], : `2'2 /// get rw p-value for tot


mat rw5 = e(RW)
mat rw4 = rw5[1..6, 3..3]
mat rw_3 = rw4[1..2,1..1]
mat rw_2 = rw4[3..4,1..1]
mat rw_1 = rw4[5..6,1..1]
mat rw = rw_3, rw_2
mat rw = rw, rw_1
mat rw_itt = rw[1..1, 1..3]
mat rw_tot = rw[2..2, 1..3]


foreach var in `varlist' {
	estadd scalar rw_itt, `var'
	estadd mat rw_tot
}
*/
/*
	* Generate Anderson/Hochberg sharpened q-values to control for MH testing/false discovery rate
		* put all p-values into matrix/column vector
mat p = (`1'p1 \ `1'p2 \ `2'p1 \ `2'p2 \ `3'p1 \ `3'p2)
mat colnames p = "pvalues"

		* create & go to frame as following command will clear data set
frame copy default pvalues, replace
frame change pvalues
drop _all	
		
		* transform matrix into variable/data set with one variable pvals
svmat double p, names(col)

		* apply q-values program to variable pvalues
qvalues pvalues

		* transform variables into matrix/column
mkmat pvalues bky06_qval, matrix(qs)

		* switch to initial frame & import qvalues
frame change default
*/	
*/
