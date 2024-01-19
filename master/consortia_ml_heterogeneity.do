***********************************************************************
* 			Master midline analysis/regressions: heterogeneity analysis				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake sub-group/heterogeneity analyses
*
*	PART 0:		set the stage
*													
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi					    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium_final.dta
*	Creates:
***********************************************************************
* 	Part 0.1: 	set the stage		  
***********************************************************************
use "${master_final}/consortium_final", clear

	* change directory
cd "${master_regressiontables}/midline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on

***********************************************************************
* 	PART 0.2:  set the stage - 	write program for Anderson sharpened q-values
***********************************************************************
{
	* source 1:https://blogs.worldbank.org/impactevaluations/updated-overview-multiple-hypothesis-testing-commands-stata
	* source 2: are.berkeley.edu/~mlanderson/downloads/fdr_sharpened_qvalues.do.zip
	* source 3: https://are.berkeley.edu/~mlanderson/pdf/Anderson%202008a.pdf
capture program drop qvalues
program qvalues 
	* settings
		version 10
		syntax varlist(max=1 numeric) // where varlist is a variable containing all the `varlist'
		* Collect N of p-values
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
				local qval_adj = `qval'/(1+`qval') 					
				gen fdr_temp1 = `qval_adj'*rank/`totalpvals'
				gen reject_temp1 = (fdr_temp1>=`varlist') if `varlist'~=.
				gen reject_rank1 = reject_temp1*rank
				egen total_rejected1 = max(reject_rank1)
			* Second Stage
				local qval_2st = `qval_adj'*(`totalpvals'/(`totalpvals'-total_rejected1[1]))
				gen fdr_temp2 = `qval_2st'*rank/`totalpvals'
				gen reject_temp2 = (fdr_temp2>=`varlist') if `varlist'~=.
				gen reject_rank2 = reject_temp2*rank
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
	version 16
	
	end  

}

***********************************************************************
* 	PART 0.3:  set the stage - 	write program for Romano-Wolf fw errors
***********************************************************************
*for 3 conditions
{
capture program drop wolf
program wolf
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 cond1 cond2 cond3 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata if `14' & `11', cluster(id)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata (take_up = treatment) if `14' & `11', cluster(id)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata if `14' & `12', cluster(id)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata (take_up = treatment) if `14' & `12', cluster(id)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata (take_up = treatment) if `14' & `13', cluster(id)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata (take_up = treatment) if `14' & `13', cluster(id)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata (take_up = treatment) if `14' & `13', cluster(id)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata (take_up = treatment) if `14' & `13', cluster(id)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata (take_up = treatment) if `14' & `13', cluster(id)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata (take_up = treatment) if `14' & `13', cluster(id)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata (take_up = treatment) if `14' & `13', cluster(id)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata if `14' & `13', cluster(id)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata (take_up = treatment) if `14' & `13', cluster(id)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110723) reps(30) usevalid strata(strata)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${aqe_rt_el}/`15'", replace
	
end
}

*for 2 conditions
{
capture program drop wolf2
program wolf2
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 cond1 cond2 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata if `13' & `11', cluster(id)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata (take_up = treatment) if `13' & `11', cluster(id)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata (take_up = treatment) if `13' & `12', cluster(id)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata (take_up = treatment) if `13' & `12', cluster(id)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata (take_up = treatment) if `13' & `12', cluster(id)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata (take_up = treatment) if `13' & `12', cluster(id)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata (take_up = treatment) if `13' & `12', cluster(id)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata (take_up = treatment) if `13' & `12', cluster(id)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata (take_up = treatment) if `13' & `12', cluster(id)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata if `13' & `12', cluster(id)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata (take_up = treatment) if `13' & `12', cluster(id)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110724) reps(30) usevalid strata(strata)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${aqe_rt_el}/`14'", replace
	
end
}

***********************************************************************
* 	PART 2:  Size heterogeneity
***********************************************************************
{
local outcome "qii"
local conditions "sector==12  inlist(sector,13,14) !inlist(sector,12,13,14)"
local sectors "a t r"
foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata if `cond' & surveyround==3, cluster(id)
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata (take_up = i.treatment) if `cond' & surveyround==3, cluster(id) first
			estadd local bl_control "Yes"
			estadd local strata "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 3 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_a1 `outcome'_a2 `outcome'_t1 `outcome'_t2 `outcome'_r1 `outcome'_r2  
esttab `regressions' using "rt_hetero_certification_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on Quality infrastructure/management index by sector} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{5}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("No cert." "In progress" "Certification", ///
				pattern(1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_a1 `outcome'_a2 `outcome'_t1 `outcome'_t2 `outcome'_r1 `outcome'_r2
		esttab `regressions' using "rt_hetero_certification_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{7}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "Strata controls" "Y0 controls")) ///
				drop(_cons *.strata ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("No cert." "In progress" "Certification", ///
				pattern(1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_a1, pstyle(p1)) (`outcome'_a2, pstyle(p1)) ///
	(`outcome'_t1, pstyle(p2)) (`outcome'_t2, pstyle(p2)) ///
	(`outcome'_r1, pstyle(p3)) (`outcome'_r2, pstyle(p3)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_a1 = `"No cert. (ITT)"' `outcome'_a2 = `"No cert. (TOT)"' `outcome'_t1 = `"In progress (ITT)"' `outcome'_t2 = `"In progress (TOT)"' `outcome'_r1 = `"Certification (ITT)"' `outcome'_r2 = `"Certification (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Quality infrastructure/management index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_sector_`outcome', replace)
gr export el_het_sector_`outcome'.png, replace

}

***********************************************************************
* 	PART 3:  Sectoral heterogeneity
***********************************************************************

***********************************************************************
* 	PART 4:  Network heterogeneity
***********************************************************************