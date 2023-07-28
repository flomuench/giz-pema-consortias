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

		* limit sample to take-up firms
keep if take_up == 1

***********************************************************************
* 	Part 1: peer effect on entrepreneurial confidence: does confidence boost depends on other consortia members?	  
***********************************************************************
{
capture program drop peer_confidence // enables re-running
program peer_confidence
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
						
			* Peer effect regression
			eststo `var': reg genderi_abs_growth `var' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate treatment group mean
				* take mean over midline to account for time trend
sum genderi if take_up == 1 & surveyround == 2
estadd scalar take_up_mean = r(mean)
estadd scalar take_up_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg genderi `1' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `2' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `3' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `4' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `5' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `6' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `7' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `8' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `9' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg genderi `10' genderi_y0 i.missing_bl_genderi i.strata_final if surveyround == 2, cluster(id_plateforme)), ///
	indepvars(`1', `2', `3', `4', `5', `6', `7', `8', `9', `10') ///
	seed(110723) reps(999) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Effect of peer quality on entrepreneurial confidence} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") /// posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(take_up_mean take_up_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Take-up mean" "Take-up SD" "Observations" "Strata controls" "Y0 controls")) ///
				nomtitles /// mlabels(, depvars) --> use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{10}{@{}p{\textwidth}@{}}{\parbox{24cm}{% Notes: The dependent variable is the change in entrepreneurial confidence between baseline and midline. Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. The sample is restricted to companies that joined the consortium. Take-up mean and take-up SD refer to the outcome variable mean and SD at midline. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1', pstyle(p1)) (`2', pstyle(p2))  ///
	(`3', pstyle(p3)) (`4', pstyle(p4))  ///
	(`5', pstyle(p5)) (`6', pstyle(p6))  /// 
	(`7', pstyle(p7)) (`8', pstyle(p8))  ///
	(`9', pstyle(p9)) (`10', pstyle(p10)) , ///
	drop(_cons *.strata_final ?.missing_bl_* *_y0) xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	byopts(xrescale compact) /// enable different axes for subgraphs
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(`1' = `"Dist. to mean management practices"' `2' = `"Dist. to top-3 management practices"' `3' = `"Dist. to mean Entrepreneurial confidence"' `4' = `"Dist. to top-3 entrepreneurial confidence"' `5' = `"Dist. to mean export performance"' `6' = `"Dist. to top-3 export performance"' `7' = `"Dist. to mean size"' `8' = `"Dist. to top-3 Size"' `9' = `"Dist. to mean profit"' `10' = `"Dist. to top-3 profit"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)
	
gr export ml_`generate'_cfplot.png, replace

	
end

	* apply program to business performance outcomes
peer_confidence peer_d_avg2_mpmarki peer_d_top2_mpmarki peer_d_avg2_genderi peer_d_top2_genderi peer_d_avg2_epp peer_d_top2_epp peer_d_avg2_size peer_d_top2_size peer_d_avg2_profit peer_d_top2_profit, gen(peer_confidence)

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
			eststo `var': reg mpi_abs_growth `var' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate treatment group mean
				* take mean over ml to account for time trend
sum mpi if take_up == 1 & surveyround == 2
estadd scalar take_up_mean = r(mean)
estadd scalar take_up_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*	* Correct for MHT - FWER
rwolf2 ///
	(reg mpi `1' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `2' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `3' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `4' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `5' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `6' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `7' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `8' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `9' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg mpi `10' mpi_y0 i.missing_bl_mpi i.strata_final if surveyround == 2, cluster(id_plateforme)), ///
	indepvars(`1', `2', `3', `4', `5', `6', `7', `8', `9', `10') ///
	seed(110723) reps(999) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Effect of peer quality on management practices} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") /// posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(take_up_mean take_up_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Take-up mean" "Take-up SD" "Observations" "Strata controls" "Y0 controls")) ///
				nomtitles /// mlabels(, depvars) --> use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{10}{@{}p{\textwidth}@{}}{\parbox{24cm}{% Notes: The dependent variable is the change in the management practices index between baseline and midline. Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. The sample is restricted to companies that joined the consortium. Take-up mean and take-up SD refer to the outcome variable mean and SD at midline. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1', pstyle(p1)) (`2', pstyle(p2))  ///
	(`3', pstyle(p3)) (`4', pstyle(p4))  ///
	(`5', pstyle(p5)) (`6', pstyle(p6))  /// 
	(`7', pstyle(p7)) (`8', pstyle(p8))  ///
	(`9', pstyle(p9)) (`10', pstyle(p10)) , ///
	drop(_cons *.strata_final ?.missing_bl_* *_y0) xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	byopts(xrescale compact) /// enable different axes for subgraphs
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(`1' = `"Dist. to mean management practices"' `2' = `"Dist. to top-3 management practices"' `3' = `"Dist. to mean Entrepreneurial confidence"' `4' = `"Dist. to top-3 entrepreneurial confidence"' `5' = `"Dist. to mean export performance"' `6' = `"Dist. to top-3 export performance"' `7' = `"Dist. to mean size"' `8' = `"Dist. to top-3 Size"' `9' = `"Dist. to mean profit"' `10' = `"Dist. to top-3 profit"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)

	
end

	* apply program to business performance outcomes
peer_management peer_d_avg2_mpmarki peer_d_top2_mpmarki peer_d_avg2_genderi peer_d_top2_genderi peer_d_avg2_epp peer_d_top2_epp peer_d_avg2_size peer_d_top2_size peer_d_avg2_profit peer_d_top2_profit, gen(peer_management)

}

***********************************************************************
* 	Part 3: peer effect on profit	  
***********************************************************************
rename ihs_profit_w99_k1_abs_growth t_profit
rename ihs_profit_w99_k1_y0 t_profit_y0
rename missing_bl_ihs_profit_w99_k1 t_miss_profit
{
capture program drop peer_profit // enables re-running
program peer_profit
	version 15							// define Stata version 15 used
	syntax varlist(min=1 numeric), GENerate(string)
		foreach var in `varlist' {		// do following for all variables in varlist seperately	
						
			* Peer effect regression
			eststo `var': reg t_profit `var' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* calculate control group mean
				* take mean over surveyrounds to control for time trend
sum t_profit if take_up == 1 & surveyround == 2
estadd scalar take_up_mean = r(mean)
estadd scalar take_up_sd = r(sd)
		}
		
	* change logic from "to same thing to each variable" (loop) to "use all variables at the same time" (program)
		* tokenize to use all variables at the same time
tokenize `varlist'

/*		* Correct for MHT - FWER
rwolf2 ///
	(reg t_profit `1' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `2' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `3' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `4' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `5' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `6' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `7' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `8' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `9' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)) ///
	(reg t_profit `10' t_profit_y0 i.t_miss_profit i.strata_final if surveyround == 2, cluster(id_plateforme)), ///
	indepvars(`1', `2', `3', `4', `5', `6', `7', `8', `9', `10') ///
	seed(110723) reps(999) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_`generate'.tex, replace  
*/	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions `1' `2' `3' `4' `5' `6' `7' `8' `9' `10' // adjust manually to number of variables 
		esttab `regressions' using "rt_`generate'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Effect of peer quality on management practices} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") /// posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(take_up_mean take_up_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Take-up mean" "Take-up SD" "Observations" "Strata controls" "Y0 controls")) ///
				nomtitles /// mlabels(, depvars) --> use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final 0.t_miss_profit t_profit_y0) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{10}{@{}p{\textwidth}@{}}{\parbox{24cm}{% Notes: The dependent variable is the change in inverse hyperbolice sine transformed profits between baseline and midline. Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. The sample is restricted to companies that joined the consortium. Take-up mean and take-up SD refer to the outcome variable mean and SD at midline. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`1', pstyle(p1)) (`2', pstyle(p2))  ///
	(`3', pstyle(p3)) (`4', pstyle(p4))  ///
	(`5', pstyle(p5)) (`6', pstyle(p6))  /// 
	(`7', pstyle(p7)) (`8', pstyle(p8))  ///
	(`9', pstyle(p9)) (`10', pstyle(p10)) , ///
	drop(_cons *.strata_final 0.t_miss_profit t_profit_y0) xline(0) ///
	asequation /// name of model is used
	swapnames /// swaps coeff & equation names after collecting result
	byopts(xrescale compact) /// enable different axes for subgraphs
	levels(95) ///
	xtitle("Treatment coefficient", size(medium)) ///
	eqrename(`1' = `"Dist. to mean management practices"' `2' = `"Dist. to top-3 management practices"' `3' = `"Dist. to mean Entrepreneurial confidence"' `4' = `"Dist. to top-3 entrepreneurial confidence"' `5' = `"Dist. to mean export performance"' `6' = `"Dist. to top-3 export performance"' `7' = `"Dist. to mean size"' `8' = `"Dist. to top-3 Size"' `9' = `"Dist. to mean profit"' `10' = `"Dist. to top-3 profit"') ///
	leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
	name(ml_`generate'_cfplot, replace)

	
end

	* apply program to business performance outcomes
peer_profit peer_d_avg2_mpmarki peer_d_top2_mpmarki peer_d_avg2_genderi peer_d_top2_genderi peer_d_avg2_epp peer_d_top2_epp peer_d_avg2_size peer_d_top2_size peer_d_avg2_profit peer_d_top2_profit, gen(peer_profit)

}