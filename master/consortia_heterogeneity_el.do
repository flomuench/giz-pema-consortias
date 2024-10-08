***********************************************************************
* 			Master endline analysis/regressions: heterogeneity analysis				  
***********************************************************************
*																	  
*	PURPOSE: 	Undertake sub-group/heterogeneity analyses
*
*	PART 0:		set the stage
*													
*																	  
*	Authors:  	Ayoub Chamakhi				    
*	id_plateforme variable: id_platforme		  					  
*	Requires:  	consortium_final.dta
*	Creates:
***********************************************************************
* 	Part 0.1: 	set the stage		  
***********************************************************************
use "${master_final}/consortium_final", clear

	* change directory
cd "${master_regressiontables}/endline/heterogeneity"

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
{
*for 4 conditions & 11 vars
{
capture program drop wolf4
program wolf4
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 cond1 cond2 cond3 cond4 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `18' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `18' & `14', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `18' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `18' & `15', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `18' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `18' & `16', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `18' & `17', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `18' & `17', cluster(consortia_cluster)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110723) reps(30) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/endline/`19'", replace
	
end
}

*for 3 conditions & 9 vars
{
capture program drop wolf3
program wolf3
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 cond1 cond2 cond3 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `15' & `12', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `15' & `12', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `15' & `13', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `15' & `13', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `15' & `14', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `15' & `14', cluster(consortia_cluster)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110723) reps(30) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/endline/`16'", replace
	
end
}

*for 2 conditions & 11 vars
{
capture program drop wolf2
program wolf2
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 cond1 cond2 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110724) reps(30) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/endline/`17'", replace
	
end
}
** By consortium, by initial network size,by export initial export status **
}

***********************************************************************
* 	PART I:  Pole heterogeneity
***********************************************************************
{
	* change directory
cd "${master_regressiontables}/endline/heterogeneity/pole"

***********************************************************************
* 	PART 1:  Summary table
***********************************************************************
{
{

capture program drop rth_pole
program rth_pole
	version 16
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "pole==1 pole==2 pole==3 pole==4"
		local groups "aa ac s tic"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
							capture confirm variable `outcome'_y0
		if _rc == 0 { // If `outcome'_y0 exists

			// ITT: ANCOVA plus stratification dummies
			eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			quietly ereturn display
			matrix b = r(table) // access p-values for mht
			scalar `outcome'_`group'1_p1 = b[4,2]

			// ATT, IV
			eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			quietly ereturn display // provides same table but with r(table)
			matrix b = r(table)
			scalar `outcome'_`group'2_p2 = b[4,1]

		} 
		else { // If `outcome'_y0 does not exist

			// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
			eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
			estadd local bl_control "No"
			estadd local strata_final "Yes"
			quietly ereturn display
			matrix b = r(table) // access p-values for mht
			scalar `outcome'_`group'1_p1 = b[4,2]

			// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
			eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
			estadd local bl_control "No"
			estadd local strata_final "Yes"
			quietly ereturn display // provides same table but with r(table)
			matrix b = r(table)
			scalar `outcome'_`group'2_p2 = b[4,1]
		}

					
					* calculate control group mean
						* take mean at midline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 3 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'

	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_aa1_p1 \ `1'_ac1_p1 \ `1'_s1_p1 \ `1'_tic1_p1 \ `2'_aa1_p1 \ `2'_ac1_p1 \ `2'_s1_p1 \ `2'_tic1_p1 \ `3'_aa1_p1 \ `3'_ac1_p1 \ `3'_s1_p1 \ `3'_tic1_p1 \ `4'_aa1_p1 \ `4'_ac1_p1 \ `4'_s1_p1 \ `4'_tic1_p1 \ `5'_aa1_p1 \ `5'_ac1_p1 \ `5'_s1_p1 \ `5'_tic1_p1 \ `6'_aa1_p1 \ `6'_ac1_p1 \ `6'_s1_p1 \ `6'_tic1_p1 \ `7'_aa1_p1\ `7'_ac1_p1\ `7'_s1_p1 \ `7'_tic1_p1 \ `8'_aa1_p1\ `8'_ac1_p1\ `8'_s1_p1\ `8'_tic1_p1 \ `9'_aa1_p1\ `9'_ac1_p1\ `9'_s1_p1 \ `9'_tic1_p1 \ `10'_ac1_p1\ `10'_s1_p1 \ `10'_tic1_p1 \ `11'_ac1_p1\ `11'_s1_p1 \ `11'_tic1_p1 \  `1'_aa2_p2\ `1'_ac2_p2\ `1'_s2_p2 \ `1'_tic2_p2 \  `2'_aa2_p2\ `2'_ac2_p2\ `2'_s2_p2 \ `2'_tic2_p2 \ `3'_aa2_p2\ `3'_ac2_p2\ `3'_s2_p2 \ `3'_tic2_p2 \ `4'_aa2_p2\ `4'_ac2_p2\ `4'_s2_p2 \ `4'_tic2_p2 \ `5'_aa2_p2\ `5'_ac2_p2\ `5'_s2_p2 \ `5'_tic2_p2 \ `6'_aa2_p2\ `6'_ac2_p2\ `6'_s2_p2 \  `6'_tic2_p2 \ `7'_aa2_p2\ `7'_ac2_p2\ `7'_s2_p2 \  `7'_tic2_p2 \ `8'_aa2_p2\ `8'_ac2_p2\ `8'_s2_p2 \  `8'_tic2_p2 \ `9'_aa2_p2\ `9'_ac2_p2\ `9'_s2_p2 \ `9'_tic2_p2 \ `10'_s2_p2 \ `10'_tic2_p2 \ `11'_ac2_p2\ `11'_s2_p2 \ `11'_tic2_p2)

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_aa1 `1'_ac1 `1'_s1 `1'_tic1 `2'_aa1 `2'_ac1 `2'_s1 `2'_tic1 `3'_aa1 `3'_ac1 `3'_s1 `3'_tic1 `4'_aa1 `4'_ac1 `4'_s1 `4'_tic1 `5'_aa1 `5'_ac1 `5'_s1 `5'_tic1 `6'_aa1 `6'_ac1 `6'_s1 `6'_tic1 `7'_aa1 `7'_ac1 `7'_s1 `7'_tic1 `8'_aa1 `8'_ac1 `8'_s1 `8'_tic1 `9'_aa1 `9'_ac1 `9'_s1 `9'_tic1 `10'_aa1 `10'_ac1 `10'_s1 `10'_tic1 `11'_aa1 `11'_ac1 `11'_s1 `11'_tic1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key outcome variables by firm size} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \begin{tabular}{l*{38}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{37}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Innovation practices index" "Business performance 2023" "Business performance 2024", pattern(0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1)) ///
						mlabels("Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital & Agro & Handicrafts & Consulting & Digital", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_aa2 `1'_ac2 `1'_s2 `1'_tic2 `2'_aa2 `2'_ac2 `2'_s2 `2'_tic2 `3'_aa2 `3'_ac2 `3'_s2 `3'_tic2 `4'_aa2 `4'_ac2 `4'_s2 `4'_tic2 `5'_aa2 `5'_ac2 `5'_s2 `5'_tic2 `6'_aa2 `6'_ac2 `6'_s2 `6'_tic2 `7'_aa2 `7'_ac2 `7'_s2 `7'_tic2 `8'_aa2 `8'_ac2 `8'_s2 `8'_tic2 `9'_aa2 `9'_ac2 `9'_s2 `9'_tic2  `10'_aa2 `10'_ac2 `10'_s2 `10'_tic2 `11'_aa2 `11'_ac2 `11'_s2 `11'_tic2
			esttab `regressions' using "rth_`generate'_outcomes.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{38}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline \end{tabular} \\ \begin{tablenotes}[flushleft] \\ \footnotesize \\ \item Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. \\ \end{tablenotes} \\ \end{threeparttable} \\ \end{adjustbox} \\ \end{table}") 
						

end		

	* execute the program providing the list of variables
rth_pole network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024, gen(pole_outcomes)

}

/* COMMENT OUT RW UNTIL WE FIND SOLUTION FOR Y0
* MHT corrections
	* 1: Anderson q-values
{
* Multiple hypotheses testing corrections
	* 1: Anderson q-values
		* transform matrix into variable/data set with one variable pvals
{
svmat double p, names(col)
frame put pvalues, into(qvalues)
drop pvalues

		* change frames & start with clear
frame change qvalues
sum pvalues
keep in 1/`r(N)'

		* apply q-values program to variable pvalues
qvalues pvalues			
			
		* save resulting data in Excel sheet
export excel using "${master_regressiontables}/endline/heterogeneity/pole/het_pole_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues
}
	* 2: Romano-Wolf FWER
wolf4 ///
	treatment take_up /// Ivars
	network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024 /// Dvars
	pole==1 pole==2 pole==3 pole==4 surveyround==3 /// conditions
	het_pole_rwvalues // name
}

estimates clear
*/
}

***********************************************************************
* 	PART 2:  Indexes
***********************************************************************
{
local outcomes "network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024"
local conditions "pole==1 pole==2 pole==3 pole==4"


foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}

}

***********************************************************************
* 	PART 3:  Network
***********************************************************************
{
****************************  net_size & net_coop_pos/neg ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/pole/network"

local outcomes "net_size3_w99 net_coop_pos net_coop_neg"
*local outcomes "net_size3_w95 net_coop_pos net_coop_neg" // WINSORIWED95, comment out to use
local conditions "pole==1 pole==2 pole==3 pole==4"



foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}

estimates clear
}

****************************  net_coop ***************************
{
	* lab each cooperate word dummy to overwrite the master lab
label var netcoop1 "Jealousy"
label var netcoop2 "Cooperate"
label var netcoop3 "Trust"
label var netcoop4 "Protecting business secrets"
label var netcoop5 "Risks"
label var netcoop6 "Conflict"
label var netcoop7 "Learn" 
label var netcoop8 "Partnership"
label var netcoop9 "Connect" 
label var netcoop10 "Competition"

local outcomes "netcoop1 netcoop2 netcoop3 netcoop4 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10" // Error: estimated variance-covariance matrix has missing values: netcoop5
local conditions "pole==1 pole==2 pole==3 pole==4"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) xlabel(-1(0.2)1) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medlarge)) ///
        xtitle("`outcome_label'", size(medlarge)) /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("{bf:Note}: Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}

estimates clear
graph drop _all
}

}

***********************************************************************
* 	PART 4:  Innovation
***********************************************************************
{
****************************  product innovation ***************************

{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/pole/innovation"

local outcomes "inno_improve inno_new inno_both inno_none" //
local conditions "pole==1 pole==2 pole==3 pole==4"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}
estimates clear
}
****************************  inno_proc ***************************
{
local outcomes "inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres" //
local conditions "pole==1 pole==2 pole==3 pole==4"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}

estimates clear
graph drop _all
}
}

***********************************************************************
* 	PART 5:  Export
***********************************************************************
{
****************************  export - extensive margin ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/pole/export"

local outcomes "export_1 exported" //
local conditions "pole==1 pole==2 pole==3 pole==4"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}

estimates clear

}

****************************  export wins ***************************
{
local outcomes "exp_pays_w99 exp_pays_ssa_w99 clients_w99 clients_ssa_w99" //
*local outcomes "exp_pays_w95 exp_pays_ssa_w95 clients_w95 clients_ssa_w95" // ACTIVAITE THIS CODE FOR WINS 95
local conditions "pole==1 pole==2 pole==3 pole==4"


foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}

estimates clear
}

**************************** clear memory & reload ***************************
{
clear all
use "${master_final}/consortium_final", clear

	* change directory
cd "${master_regressiontables}/endline/heterogeneity"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on

}
********  set the stage - 	write program for Anderson sharpened q-values ********

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

{
capture program drop wolf2
program wolf2
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 cond1 cond2 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110724) reps(30) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/endline/`17'", replace
	
end
}
}

***********************************************************************
* 	PART 6:  Compta
***********************************************************************
{
**************************** empl ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/pole/compta"

local outcomes "employes_w99 car_empl1_w99" //
*local outcomes "employes_w95 car_empl1_w95" // ACTIVATE THIS CODE FOR W95
local conditions "pole==1 pole==2 pole==3 pole==4"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}

estimates clear
}
**************************** CA & PROFIT  ***************************
{
local outcomes "ihs_ca_w99_k1 ihs_ca_2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k1" // ihs_costs_w99_k1 ihs_costs_2024_w99_k1 IF PROFIT SIG
local outcomes "ihs_ca_w95_k1 ihs_ca_2024_w95_k1 ihs_profit_w95_k1 ihs_profit2024_w95_k1" // ACTIVATE FOR WINS 95TH ihs_costs_w99_k1 ihs_costs_2024_w99_k1 IF PROFIT SIG
local conditions "pole==1 pole==2 pole==3 pole==4"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}
estimates clear
}
**************************** financial wins 95th ***************************
{
local outcomes "ihs_catun_w99_k1 ihs_catun2024_w99_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1"
*local outcomes "ihs_catun_w95_k1 ihs_catun2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1" // ACTIVATE FOR WINS 95TH
local conditions "pole==1 pole==2 pole==3 pole==4"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "aa ac s tic"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhetp_`outcome'_95, replace)
    gr export elhetp_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
        (`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
        (`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
        (`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_aa1 = `"Agri-food (ITT)"' `outcome'_aa2 = `"Agri-food (TOT)"' `outcome'_ac1 = `"Handicrafts (ITT)"' `outcome'_ac2 = `"Handicrafts (TOT)"' `outcome'_s1 = `"Consulting (ITT)"' `outcome'_s2 = `"Consulting (TOT)"' `outcome'_tic1 = `"Digital (ITT)"' `outcome'_tic2 = `"Digital (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhetp_`outcome'_99, replace)
    gr export elhetp_`outcome'_99.png, replace
	
}
estimates clear
}
}

}

***********************************************************************
* 	PART II:  Export status heterogeneity
***********************************************************************
{
	* change directory
cd "${master_regressiontables}/endline/heterogeneity/export"

***********************************************************************
* 	PART 1:  Summary table
***********************************************************************
{
{

capture program drop rth_export
program rth_export
	version 16
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "operation_export==0 operation_export==1"
		local groups "xp noxp"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
							capture confirm variable `outcome'_y0
		if _rc == 0 { // If `outcome'_y0 exists

			// ITT: ANCOVA plus stratification dummies
			eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			quietly ereturn display
			matrix b = r(table) // access p-values for mht
			scalar `outcome'_`group'1_p1 = b[4,2]

			// ATT, IV
			eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			quietly ereturn display // provides same table but with r(table)
			matrix b = r(table)
			scalar `outcome'_`group'2_p2 = b[4,1]

		} 
		else { // If `outcome'_y0 does not exist

			// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
			eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
			estadd local bl_control "No"
			estadd local strata_final "Yes"
			quietly ereturn display
			matrix b = r(table) // access p-values for mht
			scalar `outcome'_`group'1_p1 = b[4,2]

			// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
			eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
			estadd local bl_control "No"
			estadd local strata_final "Yes"
			quietly ereturn display // provides same table but with r(table)
			matrix b = r(table)
			scalar `outcome'_`group'2_p2 = b[4,1]
		}

					
					* calculate control group mean
						* take mean at midline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 3 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'
	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_xp1_p1 \ `1'_noxp1_p1 \ `2'_xp1_p1 \ `2'_noxp1_p1 \ `3'_xp1_p1 \ `3'_noxp1_p1 \ `4'_xp1_p1 \ `4'_noxp1_p1 \ `5'_xp1_p1 \ `5'_noxp1_p1 \ `6'_xp1_p1 \ `6'_noxp1_p1 \ `7'_xp1_p1\ `7'_noxp1_p1 \ `8'_xp1_p1\ `8'_noxp1_p1 \ `9'_xp1_p1 \ `9'_noxp1_p1 \ `10'_xp1_p1 \ `10'_noxp1_p1 \ `11'_xp1_p1\ `11'_noxp1_p1  \  `1'_xp2_p2\ `1'_noxp2_p2 \  `2'_xp2_p2\ `2'_noxp2_p2 \ `3'_xp2_p2\ `3'_noxp2_p2 \ `4'_xp2_p2\ `4'_noxp2_p2 \ `5'_xp2_p2\ `5'_noxp2_p2 \ `6'_xp2_p2\ `6'_noxp2_p2 \ `7'_xp2_p2\ `7'_noxp2_p2 \ `8'_xp2_p2 \ `8'_noxp2_p2 \ `9'_xp2_p2 \ `9'_noxp2_p2 \ `10'_xp2_p2 \ `10'_noxp2_p2 \ `11'_xp2_p2\ `11'_noxp2_p2 )

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_xp1 `1'_noxp1 `2'_xp1 `2'_noxp1 `3'_xp1 `3'_noxp1 `4'_xp1 `4'_noxp1 `5'_xp1 `5'_noxp1 `6'_xp1 `6'_noxp1 `7'_xp1 `7'_noxp1 `8'_xp1 `8'_noxp1 `9'_xp1 `9'_noxp1 `10'_xp1 `10'_noxp1 `11'_xp1 `11'_noxp1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key outcome variables by baseline export status} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \begin{tabular}{l*{38}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{37}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Innovation practices index" "Business performance 2023" "Business performance 2024", pattern(0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1)) ///
						mlabels("Export & No export & Export & No export & Export & No export & Export & No export & Export & No export & Export & No export & Export & No export & Export & No export & Export & No export & Export & No export & Export & No export ", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_xp2 `1'_noxp2 `2'_xp2 `2'_noxp2 `3'_xp2 `3'_noxp2 `4'_xp2 `4'_noxp2 `5'_xp2 `5'_noxp2 `6'_xp2 `6'_noxp2 `7'_xp2 `7'_noxp2 `8'_xp2 `8'_noxp2 `9'_xp2 `9'_noxp2 `10'_xp2 `10'_noxp2 `11'_xp2 `11'_noxp2
			esttab `regressions' using "rth_`generate'_outcomes.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{38}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline \end{tabular} \\ \begin{tablenotes}[flushleft] \\ \footnotesize \\ \item Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. \\ \end{tablenotes} \\ \end{threeparttable} \\ \end{adjustbox} \\ \end{table}") 
						

end		

	* execute the program providing the list of variables
rth_export network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024, gen(exp_outcomes)

}

/*
* MHT corrections
	* 1: Anderson q-values
{
* Multiple hypotheses testing corrections
	* 1: Anderson q-values
		* transform matrix into variable/data set with one variable pvals
{
svmat double p, names(col)
frame put pvalues, into(qvalues)
drop pvalues

		* change frames & start with clear
frame change qvalues
sum pvalues
keep in 1/`r(N)'

		* apply q-values program to variable pvalues
qvalues pvalues			
			
		* save resulting data in Excel sheet
export excel using "${master_regressiontables}/endline/heterogeneity/export/het_export_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues
}
	* 2: Romano-Wolf FWER
wolf2 ///
	treatment take_up /// Ivars
	network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024 /// Dvars
	operation_export==0 operation_export==1 surveyround==3 /// conditions
	het_export_rwvalues // name
}

estimates clear
*/
}

***********************************************************************
* 	PART 2:  Indexes
***********************************************************************
{
local outcomes "network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024"
local conditions "operation_export==0 operation_export==1"
local groups "xp noxp"


foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}


estimates clear
}

***********************************************************************
* 	PART 3:  Network
************************************************************************
{
****************************  Number of contacts wins. ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/export/network"

local outcomes "net_size3_w99 net_coop_pos net_coop_neg"
*local outcomes "net_size3_w95 net_coop_pos net_coop_neg" ACTIVATE FOR W95
local conditions "operation_export==0 operation_export==1"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}
}
****************************  net_coop ***************************
{
* lab each cooperate word dummy to overwrite the master lab
label var netcoop1 "Jealousy"
label var netcoop2 "Cooperate"
label var netcoop3 "Trust"
label var netcoop4 "Protecting business secrets"
label var netcoop5 "Risks"
label var netcoop6 "Conflict"
label var netcoop7 "Learn" 
label var netcoop8 "Partnership"
label var netcoop9 "Connect" 
label var netcoop10 "Competition"

local outcomes "netcoop1 netcoop2 netcoop3 netcoop4 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10" // Error: estimated variance-covariance matrix has missing values: netcoop5
local conditions "operation_export==0 operation_export==1"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}
graph drop _all
}
}

***********************************************************************
* 	PART 4:  Innovation
***********************************************************************
{
****************************  inno_produit ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/export/innovation"

local outcomes "inno_improve inno_new inno_both inno_none" //
local conditions "operation_export==0 operation_export==1"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
****************************  inno_proc ***************************
{
local outcomes "inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres" //
local conditions "operation_export==0 operation_export==1"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear


graph drop _all
}
}

***********************************************************************
* 	PART 5:  Export
***********************************************************************
{
{
****************************  export - extensive margin ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/export/export"

local outcomes "export_1 exported"
local conditions "operation_export==0 operation_export==1"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	
    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"BL Export (ITT)"' `outcome'_xp2 = `"BL Export (TOT)"' `outcome'_noxp1 = `"BL No Export (ITT)"' `outcome'_noxp2 = `"BL No Export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"BL Export (ITT)"' `outcome'_xp2 = `"BL Export (TOT)"' `outcome'_noxp1 = `"BL No Export (ITT)"' `outcome'_noxp2 = `"BL No Export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

}

****************************  export wins 99th ***************************
{
	
// exp_pays_w99 "exp_pays_w99 exp_pays_ssa_w99 clients_w99 clients_ssa_w99" //
*local outcomes "exp_pays_w95 exp_pays_ssa_w95 clients_w95 clients_ssa_w95" // ACTIVATE FOR 95 WINS
local outcomes "exp_pays_w95" 
local conditions "operation_export==0 operation_export==1"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
			capture confirm variable `outcome'_y0
			if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]
						* add to coefplot
						local itt_`outcome'_`group' = r(table)[1,2]
						local fmt_itt_`outcome'_`group' : display %3.2f `itt_`outcome'_`group''	

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
						* add to coefplot
						local att_`outcome'_`group' = e(b)[1,1]
						local fmt_att_`outcome'_`group' : display %3.2f `att_`outcome'_`group''	
						
						// Calculate control group mean
					sum `outcome' if treatment == 0 & surveyround == 3 & `cond'
						* for latex table
					estadd scalar c_m_`group' = r(mean)
					estadd scalar control_sd_`group' = r(sd)
						* for  coefplots
					local c_m_`outcome'_`group' = r(mean)
					local fmt_c_m_`outcome'_`group' : display  %3.2f `c_m_`outcome'_`group''
					
					// Calculate percent change
					local `outcome'_per_itt_`group' = (`fmt_itt_`outcome'_`group'' / `fmt_c_m_`outcome'_`group'')*100
					local `outcome'_per_att_`group' = (`fmt_att_`outcome'_`group'' / `fmt_c_m_`outcome'_`group'')*100		
						
						

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
						
						// Calculate control group mean
					sum `outcome' if treatment == 0 & surveyround == 3 & `cond'
						* for latex table
					estadd scalar c_m_`group' = r(mean)
					estadd scalar control_sd_`group' = r(sd)
						* for  coefplots
					local c_m_`outcome'_`group' = r(mean)
					local fmt_c_m_`outcome'_`group' : display  %3.2f `c_m_`outcome'_`group''
					
					// Calculate percent change
					local `outcome'_per_itt_`group' = (`fmt_itt_`outcome''_`group'' / `fmt_c_m_`outcome''_`group'')*100
					local `outcome'_per_att_`group' = (`fmt_att_`outcome''_`group'' / `fmt_c_m_`outcome''_`group'')*100		
						
					}
				}

* latex table
{
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
}

	* coefplots
    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) ///
		(`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) xlabel(-2(0.5)2) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 
        eqrename(`outcome'_xp1 = `"BL Export (ITT)"' `outcome'_xp2 = `"BL Export (TOT)"' `outcome'_noxp1 = `"BL No Export (ITT)"' `outcome'_noxp2 = `"BL No Export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "Control group EL average export countries {it:with prior export experience} is `fmt_c_m_`outcome'_xp', and `fmt_c_m_`outcome'_noxp' {it:without}." "Export countries are winsorised at the 95th percentile." "Confidence intervals are at the 99th percent level.", span size(medium)) ///
        name(elhete1_`outcome'_99, replace)
    gr export elhete1_`outcome'_99.pdf, replace
	
	    coefplot ///`outcome'_per_itt_`group'
        (`outcome'_xp1, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``outcome'_per_itt_xp', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
		(`outcome'_xp2, pstyle(p1) ///
	mlabel(string(@b, "%9.2f") + " equivalent to " + string(``outcome'_per_att_xp', "%9.0f") + "%" + " (P = " + string(@pval, "%9.2f") + ")") mlabposition(12) mlabgap(*2)  mlabsize(medium)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) xlabel(-2(0.5)2) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 
        eqrename(`outcome'_xp1 = `"BL Export (ITT)"' `outcome'_xp2 = `"BL Export (TOT)"' `outcome'_noxp1 = `"BL No Export (ITT)"' `outcome'_noxp2 = `"BL No Export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) ysize(5) xsize(10) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("{bf:Note}:" "Control group EL average export countries {it:with prior export experience} is `fmt_c_m_`outcome'_xp', and `fmt_c_m_`outcome'_noxp' {it:without}." "Export countries are winsorised at the 95th percentile." "Confidence intervals are at the 99th percent level.", span size(medium)) ///
        name(elhete2_`outcome'_99, replace)
    gr export elhete2_`outcome'_99.pdf, replace
	
}

}
}
**************************** clear memory & reload ***************************
{
clear all
use "${master_final}/consortium_final", clear

	* change directory
cd "${master_regressiontables}/endline/heterogeneity"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on
}
********  set the stage - 	write program for Anderson sharpened q-values ********

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

{
capture program drop wolf2
program wolf2
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 cond1 cond2 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110724) reps(30) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/endline/`17'", replace
	
end
}

sort id_plateforme surveyround

bysort id_plateforme: replace operation_export = operation_export[_n-2] if surveyround == 3

***********************************************************************
* 	PART 6:  Compta
***********************************************************************
{
**************************** empl ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/export/compta"

local outcomes "employes_w99 car_empl1_w99" //
*local outcomes "employes_w95 car_empl1_w95" // FOR 95TH WINS
local conditions "operation_export==0 operation_export==1"
local groups "xp noxp"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
**************************** financial 1st ***************************
{
local outcomes "ihs_ca_w99_k1 ihs_ca_2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k1 " // ihs_costs_w99_k1 ihs_costs_2024_w95_k1
*local outcomes "ihs_ca_w95_k1 ihs_ca_2024_w95_k1 ihs_profit_w95_k1 ihs_profit2024_w95_k1 " // ihs_costs_w95_k1 ihs_costs_2024_w95_k1

local conditions "operation_export==0 operation_export==1"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
**************************** financial 2nd ***************************
{
local outcomes "ihs_catun_w99_k1 ihs_catun2024_w99_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1" //
*local outcomes "ihs_catun_w95_k1 ihs_catun2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1" // 95TH
local conditions "operation_export==0 operation_export==1"
foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Export (ITT)"' `outcome'_xp2 = `"Export (TOT)"' `outcome'_noxp1 = `"No export (ITT)"' `outcome'_noxp2 = `"No export (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
}
}
}

***********************************************************************
* 	PART III:  Initial network size heterogeneity
***********************************************************************
{
		* change directory
cd "${master_regressiontables}/endline/heterogeneity/network"

* Generate the new variable net_sizeSR1
gen net_sizeSR1 = net_size

* Perform the operation on net_sizeSR1
bysort id_plateforme: replace net_sizeSR1 = net_sizeSR1[_n-2] if surveyround == 3

***********************************************************************
* 	PART 1:  Summary table
***********************************************************************
{
{

capture program drop rth_network
program rth_network
	version 16
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "net_sizeSR1<=10 net_sizeSR1>10"
		local groups "xp noxp"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
							capture confirm variable `outcome'_y0
		if _rc == 0 { // If `outcome'_y0 exists

			// ITT: ANCOVA plus stratification dummies
			eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			quietly ereturn display
			matrix b = r(table) // access p-values for mht
			scalar `outcome'_`group'1_p1 = b[4,2]

			// ATT, IV
			eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			quietly ereturn display // provides same table but with r(table)
			matrix b = r(table)
			scalar `outcome'_`group'2_p2 = b[4,1]

		} 
		else { // If `outcome'_y0 does not exist

			// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
			eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
			estadd local bl_control "No"
			estadd local strata_final "Yes"
			quietly ereturn display
			matrix b = r(table) // access p-values for mht
			scalar `outcome'_`group'1_p1 = b[4,2]

			// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
			eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
			estadd local bl_control "No"
			estadd local strata_final "Yes"
			quietly ereturn display // provides same table but with r(table)
			matrix b = r(table)
			scalar `outcome'_`group'2_p2 = b[4,1]
		}

					
					* calculate control group mean
						* take mean at midline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 3 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'
	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_xp1_p1 \ `1'_noxp1_p1 \ `2'_xp1_p1 \ `2'_noxp1_p1 \ `3'_xp1_p1 \ `3'_noxp1_p1 \ `4'_xp1_p1 \ `4'_noxp1_p1 \ `5'_xp1_p1 \ `5'_noxp1_p1 \ `6'_xp1_p1 \ `6'_noxp1_p1 \ `7'_xp1_p1\ `7'_noxp1_p1 \ `8'_xp1_p1\ `8'_noxp1_p1 \ `9'_xp1_p1 \ `9'_noxp1_p1 \ `10'_xp1_p1 \ `10'_noxp1_p1 \ `11'_xp1_p1\ `11'_noxp1_p1  \  `1'_xp2_p2\ `1'_noxp2_p2 \  `2'_xp2_p2\ `2'_noxp2_p2 \ `3'_xp2_p2\ `3'_noxp2_p2 \ `4'_xp2_p2\ `4'_noxp2_p2 \ `5'_xp2_p2\ `5'_noxp2_p2 \ `6'_xp2_p2\ `6'_noxp2_p2 \ `7'_xp2_p2\ `7'_noxp2_p2 \ `8'_xp2_p2 \ `8'_noxp2_p2 \ `9'_xp2_p2 \ `9'_noxp2_p2 \ `10'_xp2_p2 \ `10'_noxp2_p2 \ `11'_xp2_p2\ `11'_noxp2_p2 )

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_xp1 `1'_noxp1 `2'_xp1 `2'_noxp1 `3'_xp1 `3'_noxp1 `4'_xp1 `4'_noxp1 `5'_xp1 `5'_noxp1 `6'_xp1 `6'_noxp1 `7'_xp1 `7'_noxp1 `8'_xp1 `8'_noxp1 `9'_xp1 `9'_noxp1 `10'_xp1 `10'_noxp1 `11'_xp1 `11'_noxp1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key outcome variables by baseline export status} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \begin{tabular}{l*{38}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{37}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Innovation practices index" "Business performance 2023" "Business performance 2024", pattern(0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1)) ///
						mlabels("Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network & Small network & Large network ", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_xp2 `1'_noxp2 `2'_xp2 `2'_noxp2 `3'_xp2 `3'_noxp2 `4'_xp2 `4'_noxp2 `5'_xp2 `5'_noxp2 `6'_xp2 `6'_noxp2 `7'_xp2 `7'_noxp2 `8'_xp2 `8'_noxp2 `9'_xp2 `9'_noxp2 `10'_xp2 `10'_noxp2 `11'_xp2 `11'_noxp2
			esttab `regressions' using "rth_`generate'_outcomes.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{38}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\hline \end{tabular} \\ \begin{tablenotes}[flushleft] \\ \footnotesize \\ \item Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. \\ \end{tablenotes} \\ \end{threeparttable} \\ \end{adjustbox} \\ \end{table}") 
						

end		

	* execute the program providing the list of variables
rth_network network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024, gen(net_outcomes)

}

/*
* MHT corrections
	* 1: Anderson q-values
{
* Multiple hypotheses testing corrections
	* 1: Anderson q-values
		* transform matrix into variable/data set with one variable pvals
{
svmat double p, names(col)
frame put pvalues, into(qvalues)
drop pvalues

		* change frames & start with clear
frame change qvalues
sum pvalues
keep in 1/`r(N)'

		* apply q-values program to variable pvalues
qvalues pvalues			
			
		* save resulting data in Excel sheet
export excel using "${master_regressiontables}/endline/heterogeneity/export/het_export_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues
}
	* 2: Romano-Wolf FWER
wolf2 ///
	treatment take_up /// Ivars
	network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024 /// Dvars
	operation_export==0 operation_export==1 surveyround==3 /// conditions
	het_export_rwvalues // name
}

estimates clear
}
*/
}

***********************************************************************
* 	PART 2:  Indexes
***********************************************************************
{
local outcomes "network eri eri_ssa epp mpi female_efficacy female_loc genderi ipi_correct bpi bpi_2024"
local conditions "net_sizeSR1<=10 net_sizeSR1>10"
local groups "xp noxp"


foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}


estimates clear
}

***********************************************************************
* 	PART 3:  Network
***********************************************************************
{
****************************  Number of contacts wins. ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/network/network"

lab var net_size3_w99 "Network all contacts, wins. 99th pct."

local outcomes "net_size3_w99 net_coop_pos net_coop_neg"
*local outcomes "net_size3_w95 net_coop_pos net_coop_neg" ACTIVATE FOR W95
local conditions "net_sizeSR1<=10 net_sizeSR1>10"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small BL network (ITT)"' `outcome'_xp2 = `"Small BL network (TOT)"' `outcome'_noxp1 = `"Large BL network (ITT)"' `outcome'_noxp2 = `"Large BL network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small BL network (ITT)"' `outcome'_xp2 = `"Small BL network (TOT)"' `outcome'_noxp1 = `"Large BL network (ITT)"' `outcome'_noxp2 = `"Large BL network (TOT)"') ///
        ytitle("", size(medsmall)) ///
        xtitle("`outcome_label'", size(medsmall)) /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("{bf:Note}:" "Confidence interval at the 99th percentile." "Small network is less or equal to 10, while large is more than 10.", span size(small)) /// 99th only holds for large firms
		ysc(outergap(-5)) ///
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}
}

****************************  net_coop ***************************
{
* lab each cooperate word dummy to overwrite the master lab
label var netcoop1 "Jealousy"
label var netcoop2 "Cooperate"
label var netcoop3 "Trust"
label var netcoop4 "Protecting business secrets"
label var netcoop5 "Risks"
label var netcoop6 "Conflict"
label var netcoop7 "Learn" 
label var netcoop8 "Partnership"
label var netcoop9 "Connect" 
label var netcoop10 "Competition"

local outcomes "netcoop1 netcoop2 netcoop3 netcoop4 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10" // Error: estimated variance-covariance matrix has missing values: netcoop5
local conditions "net_sizeSR1<=10 net_sizeSR1>10"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small BL network (ITT)"' `outcome'_xp2 = `"Small BL network (TOT)"' `outcome'_noxp1 = `"Large BL network (ITT)"' `outcome'_noxp2 = `"Large BL network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) xlabel(-.6(0.2)1) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small BL network (ITT)"' `outcome'_xp2 = `"Small BL network (TOT)"' `outcome'_noxp1 = `"Large BL network (ITT)"' `outcome'_noxp2 = `"Large BL network (TOT)"') ///
        ytitle("", size(medlarge)) ///
        xtitle("`outcome_label'", size(medlarge)) /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("{bf:Note}: Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}
graph drop _all
}
}
***********************************************************************
* 	PART 4:  Innovation
***********************************************************************
{
****************************  inno_produit ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/network/innovation"

local outcomes "inno_improve inno_new inno_both inno_none" //
local conditions "net_sizeSR1<=10 net_sizeSR1>10"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
****************************  inno_proc ***************************
{
local outcomes "inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres" //
local conditions "net_sizeSR1<=10 net_sizeSR1>10"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear


graph drop _all
}
}
***********************************************************************
* 	PART 5:  Export
***********************************************************************
{
****************************  export - extensive margin ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/network/export"

local outcomes "export_1 exported" //
local conditions "net_sizeSR1<=10 net_sizeSR1>10"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}

****************************  export wins 99th ***************************
{
local outcomes "exp_pays_w99 exp_pays_ssa_w99 clients_w99 clients_ssa_w99" //
*local outcomes "exp_pays_w95 exp_pays_ssa_w95 clients_w95 clients_ssa_w95" // ACTIVATE FOR 95 WINS
local conditions "net_sizeSR1<=10 net_sizeSR1>10"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}

}
**************************** clear memory & reload ***************************
{
clear all
use "${master_final}/consortium_final", clear

	* change directory
cd "${master_regressiontables}/endline/heterogeneity"

		* declare panel data
xtset id_plateforme surveyround, delta(1)

		* set graphics on for coefplot
set graphics on
}
********  set the stage - 	write program for Anderson sharpened q-values ********

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

{
capture program drop wolf2
program wolf2
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 var10 var11 cond1 cond2 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `14' & `16', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `14' & `16', cluster(consortia_cluster)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `12' treatment `12'_y0 i.missing_bl_`12' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `12' `12'_y0 i.missing_bl_`12' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)) ///
		(reg `13' treatment `13'_y0 i.missing_bl_`13' i.strata_final if `16' & `15', cluster(consortia_cluster)) ///
		(ivreg2 `13' `13'_y0 i.missing_bl_`13' i.strata_final (take_up = treatment) if `16' & `15', cluster(consortia_cluster)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110724) reps(30) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/endline/`17'", replace
	
end
}

* Generate the new variable net_sizeSR1
gen net_sizeSR1 = net_size

* Perform the operation on net_sizeSR1
bysort id_plateforme: replace net_sizeSR1 = net_sizeSR1[_n-2] if surveyround == 3

***********************************************************************
* 	PART 6:  Compta
***********************************************************************
{
**************************** empl ***************************
{
* change directory
cd "${master_regressiontables}/endline/heterogeneity/network/compta"

local outcomes "employes_w99 car_empl1_w99" //
*local outcomes "employes_w95 car_empl1_w95" // FOR 95TH WINS
local conditions "net_sizeSR1<=10 net_sizeSR1>10"
local groups "xp noxp"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
**************************** financial 1st ***************************
{
local outcomes "ihs_ca_w99_k1 ihs_ca_2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k1 " // ihs_costs_w99_k1 ihs_costs_2024_w95_k1
*local outcomes "ihs_ca_w95_k1 ihs_ca_2024_w95_k1 ihs_profit_w95_k1 ihs_profit2024_w95_k1 " // ihs_costs_w95_k1 ihs_costs_2024_w95_k1

local conditions "net_sizeSR1<=10 net_sizeSR1>10"

foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
**************************** financial 2nd ***************************
{
local outcomes "ihs_catun_w99_k1 ihs_catun2024_w99_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1" //
*local outcomes "ihs_catun_w95_k1 ihs_catun2024_w95_k1 ihs_ca_exp_w95_k1 ihs_caexp2024_w95_k1" // 95TH
local conditions "net_sizeSR1<=10 net_sizeSR1>10"
foreach outcome of local outcomes {
    // Retrieve the label of the outcome variable
    local outcome_label : variable label `outcome'
	local groups "xp noxp"
	
    foreach cond of local conditions {
		gettoken group groups : groups

			
					capture confirm variable `outcome'_y0
					if _rc == 0 { // If `outcome'_y0 exists

						// ITT: ANCOVA plus stratification dummies
						eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV
						eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "Yes"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]

					} 
					else { // If `outcome'_y0 does not exist

						// ITT: ANCOVA plus stratification dummies (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'1: reg `outcome' i.treatment i.strata_final if `cond' & surveyround==3, cluster(consortia_cluster)
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display
						matrix b = r(table) // access p-values for mht
						scalar `outcome'_`group'1_p1 = b[4,2]

						// ATT, IV (without `outcome'_y0 and missing_bl_`outcome')
						eststo `outcome'_`group'2: ivreg2 `outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==3, cluster(consortia_cluster) first
						estadd local bl_control "No"
						estadd local strata_final "Yes"
						quietly ereturn display // provides same table but with r(table)
						matrix b = r(table)
						scalar `outcome'_`group'2_p2 = b[4,1]
					}
				}
					
	capture confirm variable `outcome'_y0
	if _rc == 0 { // If `outcome'_y0 exists
		// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final  ?.missing_bl_* *_y0) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}
	else {
				// ITT results table
		local regressions `outcome'_xp1 `outcome'_noxp1
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
			prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on "`outcome_label'"} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
			posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
			fragment ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			mlabels(, depvars) /// use dep vars labels as model title
			star(* 0.1 ** 0.05 *** 0.01) ///
			nobaselevels ///
			label      /// specifies EVs have label
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			collabels(none) /// do not use statistics names below models
			drop(_cons *.strata_final) ///
			noobs
		
		// TOT results table
		local regressions `outcome'_xp2 `outcome'_noxp2
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
			fragment ///
			posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
			cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
			stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
			drop(_cons *.strata_final) ///
			star(* 0.1 ** 0.05 *** 0.01) ///
			mgroups("Agri-food" "Handicrafts" "Consulting" "Digital", ///
			pattern(1 1 1 1)) ///
			mlabels(none) nonumbers /// do not use varnames as model titles
			collabels(none) /// do not use statistics names below models
			nobaselevels ///
			label      /// specifies EVs have label
			prefoot("\hline") ///
			postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwidth}@{}}{ \footnotesize \parbox{\linewidth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}")
	}

    // Coefficient plot for 95% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(95) /// 95th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for large firms
        name(elhete_`outcome'_95, replace)
    gr export elhete_`outcome'_95.png, replace

    // Coefficient plot for 99% confidence interval
    coefplot ///
        (`outcome'_xp1, pstyle(p1)) (`outcome'_xp2, pstyle(p1)) ///
        (`outcome'_noxp1, pstyle(p2)) (`outcome'_noxp2, pstyle(p2)), ///
        keep(*treatment take_up) drop(_cons) xline(0) ///
        asequation /// name of model is used
        swapnames /// swaps coeff & equation names after collecting result
        levels(99) /// 99th percentile is null-effect, although tight
        eqrename(`outcome'_xp1 = `"Small network (ITT)"' `outcome'_xp2 = `"Small network (TOT)"' `outcome'_noxp1 = `"Large network (ITT)"' `outcome'_noxp2 = `"Large network (TOT)"') ///
        ytitle("", size(medium)) ///
        xtitle("`outcome_label'") /// Use the variable label for xtitle
        leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
        note("Confidence interval at the 99th percentile.", span size(small)) /// 99th only holds for large firms
        name(elhete_`outcome'_99, replace)
    gr export elhete_`outcome'_99.png, replace
}

estimates clear
}
}
}