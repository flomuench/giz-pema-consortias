***********************************************************************
* 			Master analysis/regressions				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake treatment effect analysis of primary and secondary
*				outcomes as well as sub-group/heterogeneity analyses																	  
*
*													
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	ecommerce_master_final.dta
*	Creates:

***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************

use "${master_final}/consortium_final", clear
		
		* change directory
cd "${master_regressiontables}/midline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

/*
***********************************************************************
* 	PART 1: survey attrition 		
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
	
* balance after attrition
	* with outliers (Gourmandise)
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0, grpvar(treatment) ftest fmissok  vce(robust) format(%12.2fc) save(baltab_midline_all) replace
						 
	* w/o outliers
iebaltab ca ca_exp profit capital employes fte_femmes age exp_pays exprep_inv exprep_couts inno_rd net_nb_dehors net_nb_fam net_nb_qualite mpi eri if surveyround == 1 & refus == 0 & id_plateforme != 1092, grpvar(treatment) ftest fmissok vce(robust) format(%12.2fc) save(baltab_midline_wo_outlier) replace 

}
 
***********************************************************************
* 	PART 2: Write a program that generates generic regression table
***********************************************************************	
program rct_regression_table
	version 15								// define Stata version 15 used
	syntax varlist(min=1 numeric), *		// input is variable list, minimum 1 numeric variable. * enables any options.
	foreach var in `varlist' {			// do following for all variables in varlist seperately
					* ATE, ancova´			
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
	* ATE, ancova
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
	* ATE, ancova
	
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
	* ATE, ancova
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
* 	PART 7: list experiment regression - not possibe in program
***********************************************************************
	
{
	* ATE, ancova	
			* baseline differences amount
eststo lexp1, r: reg listexp i.list_group i.strata_final if surveyround == 1, vce(hc3)
estadd local strata "Yes"

			* pure mean comparison at midline 
eststo lexp2, r: reg listexp i.treatment##i.list_group if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo lexp3, r: reg listexp i.treatment##i.list_group l.listexp i.missing_bl_list_exp, cluster(id_plateforme) /*lagged value (l): include the value of the variable in previous survey_round*/
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo lexp4, r: reg listexp i.treatment##i.list_group l.listexp i.strata_final missing_bl_list_exp, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"		


local regressions lexp1 lexp2 lexp3 lexp4
esttab `regressions' using "ml_listexp.tex", replace ///
	mtitles("BL comparison" "ML mean comparison" "ML Ancova" "ML Ancova") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents baseline results with strata controls." "Column (2) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (3) presents an ANCOVA specification without strata controls." "Column (4) presents an ANCOVA specification with strata controls." "(1) uses robust standard errors. In (2)-(4) standard errors are clustered at the firm level to account for multiple observations per firm")
	
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
* 	PART 9: Midline results - regression table network outcomes
***********************************************************************
{
capture program drop rct_regression_network // enables re-running
program rct_regression_network
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			* ATE: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate
			eststo dir

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att
			eststo dir
		}
		* Put all regressions into one table
			* Top panel: ATE
		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on female entrepreneurs' business network} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Average Treatment Effect (ATE)}} \\\\[-1ex]") ///
				fragment ///
				mtitles("`1'" "`2'" "`3'" "`4'" "`5'") ///
				label b(3) se(3) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				label b(3) se(3) ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \multicolumn{6}{l}{\footnotesize Robust Standard errors in parentheses.} \\ \multicolumn{6}{l}{\footnotesize Sales, profits, employees and female employees are winsorized at the 99th percentile and inverse hyperbolic sine transformed.} \\ \multicolumn{6}{l}{\footnotesize In column(3), profits are percentile transformed.} \\ \multicolumn{6}{l}{\footnotesize \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\).} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
			
end

	* apply program to business performance outcomes
rct_regression_network net_size net_nb_f net_nb_m net_nb_qualite net_coop_pos, gen(network_outcomes)

	* export ate + att in coefplot
			* network size
coefplot net_size_ate net_size_att net_nb_f_ate net_nb_f_att net_nb_m_ate net_nb_m_att, ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation swapnames levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
 	title("Network size", pos(12)) ///
	name(ml_network_size, replace)
			* network characteristics
coefplot net_nb_qualite_ate net_nb_qualite_att net_coop_pos_ate net_coop_pos_att, ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation swapnames levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	leg(off) xsize(4.5) ///
	title("Network characteristics", pos(12)) /// pos(12) centers title
	name(ml_network_car, replace)	
gr combine ml_network_size ml_network_car, ///
	name(ml_network_cfplot, replace) ///
	note("Note: Confidence intervals are at the 95% level.") ///
	xsize(6)
gr export ml_network_cfplot.png, replace


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
			* ATE: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate
			eststo dir

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att
			eststo dir
		}
		* Put all regressions into one table
			* Top panel: ATE
		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on women's entrepreneurial empowerment} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Average Treatment Effect (ATE)}} \\\\[-1ex]") ///
				fragment ///
				mtitles("`1'" "`2'" "`3'") ///
				label b(3) se(3) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2  // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				label b(3) se(3) ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \multicolumn{4}{l}{\footnotesize Robust Standard errors in parentheses.} \\ \multicolumn{4}{l}{\footnotesize All outcomes are z-scores indeces.} \\ \multicolumn{4}{l}{\footnotesize \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\).} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
			
end

	* apply program to business performance outcomes
rct_regression_empowerment genderi female_efficacy female_loc, gen(empowerment_outcomes)

	* export ate + att in coefplot
			* network size
coefplot genderi_ate genderi_att female_efficacy_ate female_efficacy_att female_loc_ate female_loc_att, ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation swapnames levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_empowerment_cfplot, replace)
gr export ml_empowerment_cfplot.png, replace


}

/*

***********************************************************************
* 	PART 11: Midline results - regression table business performance outcomes
***********************************************************************
{
capture program drop rct_regression_business // enables re-running
program rct_regression_business
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			* ATE: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate
			eststo dir

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att
			eststo dir
		}
		* Put all regressions into one table
			* Top panel: ATE
		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on female entrepreneurs' business performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel A: Average Treatment Effect (ATE)}} \\\\[-1ex]") ///
				fragment ///
				mtitles("`1'" "`2'" "`3'" "`4'" "`5'") ///
				label b(3) se(3) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{6}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				label b(3) se(3) ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \multicolumn{6}{l}{\footnotesize Robust Standard errors in parentheses.} \\ \multicolumn{6}{l}{\footnotesize Sales, profits, employees and female employees are winsorized at the 99th percentile and inverse hyperbolic sine transformed.} \\ \multicolumn{6}{l}{\footnotesize In column(3), profits are percentile transformed.} \\ \multicolumn{6}{l}{\footnotesize \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\).} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
			
end

	* apply program to business performance outcomes
rct_regression_business ihs_ca_w99 ihs_profit_w99 profit_pct ihs_employes_w99 car_empl1_w99, gen(business_outcomes)

	* export ate + att in coefplot
coefplot ihs_ca_w99_ate ihs_ca_w99_att ihs_profit_w99_ate ihs_profit_w99_att profit_pct_ate profit_pct_att ihs_employes_w99_ate ihs_employes_w99_att car_empl1_w99_ate car_empl1_w99_att, ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation swapnames levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	leg(off) ///
	note("Note: Confidence intervals are at the 95% level.") ///
	name(ml_business_cfplot, replace)
gr export ml_business_cfplot.png, replace


}		
	

***********************************************************************
* 	PART 12: Midline results - regression table export outcomes
***********************************************************************

{
capture program drop rct_regression_export // enables re-running
program rct_regression_export
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
			* ATE: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate
			eststo dir

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att
			eststo dir
		}
		* Put all regressions into one table
			* Top panel: ATE
		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on female entrepreneurs' export performance} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{9}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{10}{c}{\textbf{Panel A: Average Treatment Effect (ATE)}} \\\\[-1ex]") ///
				fragment ///
				mtitles("`1'" "`2'" "`3'" "`4'" "`5'" "`6'") ///
				label b(3) se(3) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{10}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				label b(3) se(3) ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \multicolumn{7}{l}{\footnotesize Robust Standard errors in parentheses.} \\ \multicolumn{7}{l}{\footnotesize Export sales and export investment in column (5) and (9) are winsorized at the 99th percentile and inverse hyperbolic sine transformed.} \\ \multicolumn{7}{l}{\footnotesize Export readiness and export readiness Sub-Sahara Africa in column (1) and (2) are z-score indeces.} \\ \multicolumn{7}{l}{\footnotesize \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\).} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
				
end

	* apply program to export outcomes
rct_regression_export ca_exp ihs_ca_exp_w99 exported exprep_couts exprep_inv ihs_exprep_inv_w99, gen(export_outcomes)


	* export ate + att in coefplot
coefplot ihs_ca_exp_w99_ate ihs_ca_exp_w99_att exported_ate exported_att exprep_couts_ate exprep_couts_att ihs_exprep_inv_w99_ate ihs_exprep_inv_w99_att, ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation swapnames levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	leg(off) ///
	note("Note: Confidence intervals are at the 95% level.") ///
	name(ml_export_cfplot, replace)
gr export ml_export_cfplot.png, replace


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
			* ATE: ancova plus stratification dummies
			eststo `var'1: reg `var' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate
			eststo dir

			* ATT, IV		
			eststo `var'2: ivreg2 `var' l.`var' i.missing_bl_`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att
			eststo dir
		}
		* Put all regressions into one table
			* Top panel: ATE
		tokenize `varlist'
		local regressions `1'1 `2'1 `3'1 `4'1 `5'1 `6'1 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Impact on knowledge transfer: management practices, innovation, export readiness} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel A: Average Treatment Effect (ATE)}} \\\\[-1ex]") ///
				fragment ///
				mtitles("`1'" "`2'" "`3'" "`4'" "`5'" "`6'") ///
				label b(3) se(3) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				
				* Bottom panel: ITT
		local regressions `1'2 `2'2 `3'2 `4'2 `5'2 `6'2 // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				label b(3) se(3) ///
				drop(*.strata_final ?.missing_bl_* L.*) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				scalars("strata Strata controls" "bl_control Y0 control") ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \multicolumn{7}{l}{\footnotesize Robust Standard errors in parentheses.} \\ \multicolumn{7}{l}{\footnotesize Management practices, export readiness and export readiness Sub-Sahara Africa in column (1), (4) and (5) are z-score indeces.} \\ \multicolumn{7}{l}{\footnotesize Innovated and having a potential client in Sub-Sahara Africa in column (3) and (6) are binary dummies.} \\\multicolumn{7}{l}{\footnotesize \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\).} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
			
end

	* apply program to export outcomes
rct_regression_kt mpi innovations innovated eri eri_ssa ssa_action1, gen(kt_outcomes)

	* export as coefplot
coefplot mpi_ate mpi_att innovated_ate innovated_att eri_ate eri_att eri_ssa_ate eri_ssa_att ssa_action_ate ssa_action_att, ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation swapnames levels(90) ///
	xlabel(-0.5(0.1)0.5,labsize(medium)) xscale(range(-0.5(0.1)0.5)) /// 
	xtitle("Treatment coefficient", size(medium)) ///
	leg(off) ///
	note("Note: Confidence intervals are at the 90% level.") ///
	name(ml_kt_cfplot, replace)
gr export ml_kt_cfplot.png, replace

}	
		 

	
