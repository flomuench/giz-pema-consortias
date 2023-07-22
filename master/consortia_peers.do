***********************************************************************
* 			Consortia analysis: What is the effect of peers?				  
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

		* change directory
cd "${master_regressiontables}/midline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on

		* limit sample to treated firms
keep if treatment == 1

***********************************************************************
* 	Part 1: peer effect on entrepreneurial confidence	  
***********************************************************************

{
capture program drop peer_confidence // enables re-running
program peer_confidence
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
						
			* Peer effect regression
			eststo `var': reg genderi `var' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum genderi if treatment == 0
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

		* Correct for MHT - FWER
rwolf2 ///
	(reg genderi `1' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `2' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `3' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `4' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `5' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)), ///
	indepvars(`1', `2', `3', `4', `5') ///
	seed(110723) reps(30) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1' `2' `3' `4' `5' // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Effect of peer quality on entrepreneurial confidence} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") /// posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1', pstyle(p1) ) (`2', pstyle(p2) ), bylabel(Large CI) || ///
	(`3', pstyle(p3) ) (`4', pstyle(p4) ) (`5', pstyle(p5) ), bylabel(Small CI) ||, ///
	drop(_cons *.strata_final ?.missing_bl_* *_y0) xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	byopts(xrescale compact) /// enable different axes for subgraphs
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(`1' = `"Management practices"' `2' = `"Entrepreneurial confidence"' `3' = `"Export performance"' `4' = `"Size"' `5' = `"Profit"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace

	
end

	* apply program to business performance outcomes
peer_confidence peer_mpmarki peer_genderi peer_epp peer_business_size peer_profit, gen(peer_confidence)

}

***********************************************************************
* 	Part 2: peer effect on management practices
***********************************************************************
{
capture program drop peer_management // enables re-running
program peer_management
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
						
			* Peer effect regression
			eststo `var': reg mpi `var' mpi_y0 i.missing_bl_mpi i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum mpi if treatment == 0
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

	* Correct for MHT - FWER
rwolf2 ///
	(reg mpi `1' mpi_y0 i.missing_bl_mpi i.strata_final, cluster(id_plateforme)) ///
	(reg mpi `2' mpi_y0 i.missing_bl_mpi i.strata_final, cluster(id_plateforme)) ///
	(reg mpi `3' mpi_y0 i.missing_bl_mpi i.strata_final, cluster(id_plateforme)) ///
	(reg mpi `4' mpi_y0 i.missing_bl_mpi i.strata_final, cluster(id_plateforme)) ///
	(reg mpi `5' mpi_y0 i.missing_bl_mpi i.strata_final, cluster(id_plateforme)), ///
	indepvars(`1', `2', `3', `4', `5') ///
	seed(110723) reps(30) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1' `2' `3' `4' `5' // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Effect of peer quality} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") /// posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot (`1', pstyle(p1)) (`2', pstyle(p2)) (`3', pstyle(p3)) (`4', pstyle(p4)) (`5', pstyle(p5)), ///
	drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
	xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(`1' = `"Management practices"' `2' = `"Entrepreneurial confidence"' `3' = `"Export performance"' `4' = `"Size"' `5' = `"Profit"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace

	
end

	* apply program to business performance outcomes
peer_management peer_mpmarki peer_genderi peer_epp peer_business_size peer_profit, gen(peer_management)

}

***********************************************************************
* 	Part 3: peer effect on profit	  
***********************************************************************
{
capture program drop peer_profit // enables re-running
program peer_profit
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
						
			* Peer effect regression
			eststo `var': reg ihs_profit_w99_k1 `var' l.ihs_profit_w99_k1 i.missing_bl_ihs_profit_w99_k1 i.strata_final, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum ihs_profit_w99_k1 if treatment == 0
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg ihs_profit_w99_k1 `1' l.ihs_profit_w99_k1 i.missing_bl_ihs_profit_w99_k1 i.strata_final, cluster(id_plateforme)) ///
	(reg ihs_profit_w99_k1 `2' l.ihs_profit_w99_k1 i.missing_bl_ihs_profit_w99_k1 i.strata_final, cluster(id_plateforme)) ///
	(reg ihs_profit_w99_k1 `3' l.ihs_profit_w99_k1 i.missing_bl_ihs_profit_w99_k1 i.strata_final, cluster(id_plateforme)) ///
	(reg ihs_profit_w99_k1 `4' l.ihs_profit_w99_k1 i.missing_bl_ihs_profit_w99_k1 i.strata_final, cluster(id_plateforme)) ///
	(reg ihs_profit_w99_k1 `5' l.ihs_profit_w99_k1 i.missing_bl_ihs_profit_w99_k1 i.strata_final, cluster(id_plateforme)), ///
	indepvars(`1', `2', `3', `4', `5') ///
	seed(110723) reps(30) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1' `2' `3' `4' `5' // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Effect of peer quality} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") /// posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.*) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{4}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot (`1', pstyle(p1)) (`2', pstyle(p2)) (`3', pstyle(p3)) (`4', pstyle(p4)) (`5', pstyle(p5))), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(`1' = `"Management practices"' `2' = `"Entrepreneurial confidence"' `3' = `"Export performance"' `4' = `"Size"' `5' = `"Profit"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace

	
end

	* apply program to business performance outcomes
peer_profit peer_mpmarki peer_genderi peer_epp peer_business_size peer_profit, gen(peer_profit)

}