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

***********************************************************************
* 	Part 1: 	Midline analysis			  
***********************************************************************

***********************************************************************
* 	PART 1.1: survey attrition 		
***********************************************************************
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

	 
***********************************************************************
* 	PART 1.2: Write a program that generates generic regression table
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
			eststo `var'2, r: reg `var' i.treatment l.`var', cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "No"

						* ancova with stratification dummies
			eststo `var'3, r: reg `var' i.treatment l.`var' i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_ate

				* DiD
			eststo `var'4, r: xtreg `var' i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"			

				* ATT, IV (participation in phase 1 meetings)
			eststo `var'5, r:ivreg2 `var' l.`var' i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			estimates store `var'_att

				* ATT, IV (participation in consortia)
			eststo `var'6, r:ivreg2 `var' l.`var' i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
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
* 	PART 1.3: Apply program to all outcome variables
***********************************************************************		
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
rct_regression_table ihs_ca_exp_w99 ihs_ca_w99 ihs_profit_w99 ihs_employes_w99



***********************************************************************
* 	PART 1.4: Network regression (female network)	
***********************************************************************
	* ATE, ancova
			* pure mean comparison at midline 
eststo nf1, r: reg net_nb_f i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo nf2, r: reg net_nb_f i.treatment, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo nf3, r: reg net_nb_f i.treatment i.strata_final, cluster(id_plateforme) 
estadd local bl_control "Yes"
estadd local strata "Yes"

			/* DiD (create an aggreate variable for network size)
eststo ep4, r: xtreg net_nb_f i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			
*/
	* ATT, IV (participation in phase 1 meetings) 
eststo nf4, r:ivreg2 net_nb_f i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_nf4

	* ATT, IV (participation in consortium)
eststo nf5, r:ivreg2 net_nb_f i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
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

	
***********************************************************************
* 	PART 1.5: Network regression (male network)	
***********************************************************************
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
	
***********************************************************************
* 	PART 1.6: SSA Export Readiness index		
***********************************************************************
	* ATE, ancova
			* pure mean comparison at midline
eststo esa1, r: reg eri_ssa i.treatment if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"

			* ancova without stratification dummies
eststo esa2, r: reg eri_ssa i.treatment l.eri, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies
eststo esa3, r: reg eri_ssa i.treatment l.eri i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"

			* ATT, IV (with 1 session counting as taken up)
eststo esa4, r:ivreg2 eri_ssa l.eri i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_esa4

			* ATT, IV (with 1 session counting as taken up)
eststo esa5, r:ivreg2 eri_ssa l.eri i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
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

***********************************************************************
* 	PART 1.7: list experiment regression
***********************************************************************
	* ATE, ancova
	
			* no significant baseline differences
reg listexp i.treatment if surveyround == 1, vce(hc3)

			* pure mean comparison at midline 
eststo lexp1, r: reg listexp i.treatment##i.list_group if surveyround == 2, vce(hc3)
estadd local bl_control "No"
estadd local strata "No"
		
			* ancova without stratification dummies 
eststo lexp2, r: reg listexp i.treatment##i.list_group l.listexp, cluster(id_plateforme) /*lagged value (l): include the value of the variable in previous survey_round*/
estadd local bl_control "Yes"
estadd local strata "No"

			* ancova with stratification dummies 
eststo lexp3, r: reg listexp i.treatment##i.list_group l.listexp i.strata_final, cluster(id_plateforme) /*include the control variables pour les différentes stratas+ lagged value*/
estadd local bl_control "Yes"
estadd local strata "Yes"

			* DiD 
eststo lexp4, r: xtreg listexp i.treatment##i.surveyround i.strata_final, cluster(id_plateforme)
estadd local bl_control "Yes"
estadd local strata "Yes"			

	* ATT, IV (participation in phase 1 meetings) 
eststo lexp5, r:ivreg2 listexp l.listexp i.strata_final (take_up_per = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"
estimates store iv_lexp5

	* ATT, IV (participation in consortium)
eststo lexp6, r:ivreg2 listexp l.listexp i.strata_final (take_up = i.treatment), cluster(id_plateforme) first
estadd local bl_control "Yes"
estadd local strata "Yes"

local regressions lexp1 lexp2 lexp3 lexp4 lexp5 lexp6
esttab `regressions' using "ml_listexp.tex", replace ///
	mtitles("Mean comparison" "Ancova" "Ancova" "DiD" "ATT" "ATT") ///
	label ///
	b(3) ///
	se(3) ///
	drop(*.strata_final) ///
	star(* 0.1 ** 0.05 *** 0.01) ///
	nobaselevels ///
	scalars("strata Strata controls" "bl_control Y0 control") ///
	addnotes("Column (1) presents estimates for a simple mean comparison between treatment and control group at midline."  "Column (2) presents an ANCOVA specification without strata controls." "Column (3) presents an ANCOVA specification with strata controls." "Column (4) provides estimates from a difference-in-difference specification." "Column (5) estimates are based on 2SLS instrumental variable estimation where treatment assignment is the instrument for treatment participation." "(1) uses robust standard errors. In (2)-(5) standard errors are clustered at the firm level to account for multiple observations per firm")


/*

	
***********************************************************************
* 	PART 3: Plot the regression estimates		
***********************************************************************
set scheme burd

*Plotting the regression estimates of the midline
cd "${master_gdrive}/output/GIZ_presentation_graphs"
coefplot ki3 pres3 dig_mark3 dig_rev3, bylabel("Average Treatment Effect (Treatment vs. Control)") keep (*treatment) drop(take_up _cons)  xline(0) ///
	coeflabels(*treatment = "Treatment", labsize(vsmall)) ///
	xlabel(-1(0.5)2,labsize(vsmall)) xscale(range(-1(0.5)2)) /// 
	xtitle("Standardized Coefficients", size (vsmall)) ///
	leg(off) ///
	title("Average Treatment Effect (Treatment vs. Control)", size (small) pos(12) span) ///
	saving(midline_treatment_coefplot, replace)  fysize(40)

coefplot ki6 pres6 dig_mark6 dig_rev6, bylabel("Effect only on participating firms") keep (take_up) drop(*treatment _cons) xline(0)||, ///
	coeflabels(take_up = "Take-up    ", labsize(vsmall)) /// 
	xlabel(-1(0.5)2,labsize(vsmall)) xscale(range(-1(0.5)2)) /// 
	xtitle("Standardized Coefficients", size (vsmall)) ///
	legend(position(6) size (vsmall) ///
	col(2) order(2 "Dig.Marketing Knowledge"  4 "Online presence" 6 "Digital marketing" 8 "E-commerce revenues")) ///
	title("Effect only on participating firms", size (small) pos(12) span)  ///
	saving(midline_takeup_coefplot, replace) fysize(50)

graph combine midline_treatment_coefplot.gph midline_takeup_coefplot.gph, colfirst ycommon col(1) iscale(*1.4)
gr export midline_coefplot.png, replace
*/	
		 

	
