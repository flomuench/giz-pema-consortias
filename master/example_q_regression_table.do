***********************************************************************
* 			Master regression analysis	- RCT female export consortia			  
***********************************************************************
*																	  
*	PURPOSE: Create regression table for one outcome family including p-and q-values												  
*
*														  
*	Authors:  	Florian Münch						    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium_final.dta

***********************************************************************
* 	Part 0: 	set the stage		  
***********************************************************************
	* please replace with directory on your computer
use "${master_final}/sample", clear

	* change directory to output directory
cd "${master_regressiontables}/midline"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* replace baseline values with number of business contacts
foreach var of varlist net_nb_f net_nb_m {
	replace `var' = net_size if surveyround == 1
}

***********************************************************************
* 	Part 1: create a program to estimate sharpened q-values
***********************************************************************
{
	* source 1:https://blogs.worldbank.org/impactevaluations/updated-overview-multiple-hypothesis-testing-commands-stata
	* source 2: are.berkeley.edu/~mlanderson/downloads/fdr_sharpened_qvalues.do.zip
	* source 3: https://are.berkeley.edu/~mlanderson/pdf/Anderson%202008a.pdf
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
* 	PART 2: Midline results - regression table network outcomes - add FDR q-values
***********************************************************************
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

	* ToT, IV		
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

		* transform variables into matrix/column to add to esttab cells option
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

	* apply program to network outcomes
rct_regression_network net_size net_nb_f net_nb_m net_nb_qualite net_coop_pos, gen(network_outcomes)

}