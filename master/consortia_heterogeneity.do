***********************************************************************
* 			Master analysis/regressions: heterogeneity analysis				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake sub-group/heterogeneity analyses
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

***********************************************************************
* 	Part 1: 	Which companies experienced biggest increases in entrepreneurial confidence?		  
***********************************************************************

		* Hypotheses: a) smaller firms, b) smaller total contacts, c) women with less (more) contacts outside (within) family, d) remoter areas
{	
			* smaller firms vs. larger firms
			eststo size1: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if employes < 15, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			eststo size2: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if employes >= 15, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* fewer baseline total contacts
			eststo nsize1: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if net_size_y0 < 10, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			eststo nsize2: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if net_size_y0 >= 10, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			*  women with less (more) contacts outside (within) family
			eststo nfsize1: reg genderi i.treatment l.genderi i.missing_bl_genderi net_nb_dehors_y0 i.strata_final if net_nb_fam_y0 <= 2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			eststo nfsize2: reg genderi i.treatment l.genderi i.missing_bl_genderi net_nb_dehors_y0 i.strata_final if net_nb_fam_y0 > 2 & net_nb_fam_y0 < ., cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			* remoter areas
			eststo city1: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if city == 0, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			eststo city2: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if city == 1, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

			* more vs. less children
			eststo child1: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if famille2_y0 == 0, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			
			eststo child2: reg genderi i.treatment l.genderi i.missing_bl_genderi i.strata_final if famille2 > 0 & famille2_y0 < ., cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata "Yes"

rwolf2 ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if employes < 15, cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if employes >= 15, cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if net_size_y0 < 10, cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if net_size_y0 >= 10, cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi net_nb_dehors_y0 i.strata_final if net_nb_fam_y0 <= 2, cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi net_nb_dehors_y0 i.strata_final if net_nb_fam_y0 > 2 & net_nb_fam_y0 < ., cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if city == 0, cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if city == 1, cluster(id_plateforme)) ///
		(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if famille2_y0 == 0, cluster(id_plateforme)) ///
	(reg genderi treatment genderi_y0 i.missing_bl_genderi i.strata_final if famille2_y0 > 0 & famille2_y0 < ., cluster(id_plateforme)), ///
	indepvars(treatment, treatment, treatment, treatment, treatment, treatment, treatment, treatment, treatment, treatment) ///
	seed(110723) reps(999) usevalid strata(strata_final)
	
		* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using rw_hetero_empowerment.tex, replace  
	
		* Put all regressions into one table
			* Top panel: ITT
*		tokenize `varlist'
		local regressions size1 size2 nsize1 nsize2 nfsize1 nfsize2 city1 city2 child1 child2 // adjust manually to number of variables 
		esttab `regressions' using "rt_hetero_empowerment.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Heterogeneous effects: Entrepreneurial Confidence and Empowerment} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{12}{c}} \hline\hline") /// posthead("\hline \\ \multicolumn{4}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Observations" "Strata controls" "Y0 controls")) ///
				mtitles("Small firms" "Large firms" "Small network" "Large network" "Small fam. network" "Large fam. network" "Rural" "City" "No children" "Children") /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				collabels(none) ///	do not use statistics names below models
				label 		/// specifies EVs have label
				drop(_cons *.strata_final ?.missing_bl_* L.* *_y0) ///
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{10}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. All outcomes are z-scores calculated following Kling et al. (2007). Coefficients display effects in standard deviation units of the outcome. Entrepreneurial empowerment combines all indicators used for locus of control and efficacy. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
	
}