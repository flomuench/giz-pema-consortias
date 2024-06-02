***********************************************************************
* 			Master midline analysis/regressions: heterogeneity analysis				  
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
*for 4 conditions & 9 vars
{
capture program drop wolf4
program wolf4
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 cond1 cond2 cond3 cond4 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `12', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `12', cluster(id_plateforme)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `13', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `13', cluster(id_plateforme)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `14', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `14', cluster(id_plateforme)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `16' & `15', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `16' & `15', cluster(id_plateforme)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110723) reps(999) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/midline/`17'", replace
	
end
}

*for 3 conditions & 9 vars
{
capture program drop wolf3
program wolf3
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 cond1 cond2 cond3 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `15' & `12', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `15' & `12', cluster(id_plateforme)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `15' & `13', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `15' & `13', cluster(id_plateforme)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `15' & `14', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `15' & `14', cluster(id_plateforme)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110723) reps(999) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/midline/`16'", replace
	
end
}

*for 2 conditions & 9 vars
{
capture program drop wolf2
program wolf2
	args ind1 ind2 var1 var2 var3 var4 var5 var6 var7 var8 var9 cond1 cond2 surveyround name
	version 16
rwolf2 ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `14' & `12', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `14' & `12', cluster(id_plateforme)) ///
		(reg `3' treatment `3'_y0 i.missing_bl_`3' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `3' `3'_y0 i.missing_bl_`3' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `4' treatment `4'_y0 i.missing_bl_`4' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `4' `4'_y0 i.missing_bl_`4' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `5' treatment `5'_y0 i.missing_bl_`5' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `5' `5'_y0 i.missing_bl_`5' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `6' treatment `6'_y0 i.missing_bl_`6' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `6' `6'_y0 i.missing_bl_`6' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `7' treatment `7'_y0 i.missing_bl_`7' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `7' `7'_y0 i.missing_bl_`7' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `8' treatment `8'_y0 i.missing_bl_`8' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `8' `8'_y0 i.missing_bl_`8' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `9' treatment `9'_y0 i.missing_bl_`9' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `9' `9'_y0 i.missing_bl_`9' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `10' treatment `10'_y0 i.missing_bl_`10' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `10' `10'_y0 i.missing_bl_`10' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)) ///
		(reg `11' treatment `11'_y0 i.missing_bl_`11' i.strata_final if `14' & `13', cluster(id_plateforme)) ///
		(ivreg2 `11' `11'_y0 i.missing_bl_`11' i.strata_final (take_up = treatment) if `14' & `13', cluster(id_plateforme)), ///
	indepvars(`1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2', `1', `2') ///
	seed(110724) reps(999) usevalid strata(strata_final)

			* save rw-p-values in a seperate table for manual insertion in latex document
esttab e(RW) using "${master_regressiontables}/midline/`14'", replace
	
end
}


***********************************************************************
* 	PART 2:  Size heterogeneity
***********************************************************************

{
{

	* all in one table
capture program drop rth_size
program rth_size
	version 16
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "entrep_size==1 entrep_size==2"
		local groups "s i"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
					* ITT
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'

	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_s1_p1 \ `1'_i1_p1 \ `2'_s1_p1 \ `2'_i1_p1 \ `3'_s1_p1 \ `3'_i1_p1 \ `4'_s1_p1 \ `4'_i1_p1 \ `5'_s1_p1 \ `5'_i1_p1 \ `6'_s1_p1 \ `6'_i1_p1  \ `7'_s1_p1\ `7'_i1_p1 \ `8'_s1_p1\ `8'_i1_p1 \ `9'_s1_p1\ `9'_i1_p1 \ `1'_s2_p2\ `1'_i2_p2 \ `2'_s2_p2\ `2'_i2_p2\ `3'_s2_p2\ `3'_i2_p2 \ `4'_s2_p2\ `4'_i2_p2 \ `5'_s2_p2\ `5'_i2_p2 \ `6'_s2_p2\ `6'_i2_p2 \ `7'_s2_p2\ `7'_i2_p2 \ `8'_s2_p2\ `8'_i2_p2 \ `9'_s2_p2\ `9'_i2_p2)

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_s1 `1'_i1 `2'_s1 `2'_i1 `3'_s1 `3'_i1 `4'_s1 `4'_i1  `5'_s1 `5'_i1 `6'_s1 `6'_i1 `7'_s1 `7'_i1 `8'_s1 `8'_i1 `9'_s1 `9'_i1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key variables by firm size (5)} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \\ \begin{tabular}{l*{20}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{19}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Female employees" "Profit, ihs.", pattern(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)) ///
						mlabels("Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_s2 `1'_i2 `2'_s2 `2'_i2 `3'_s2 `3'_i2 `4'_s2 `4'_i2  `5'_s2 `5'_i2 `6'_s2 `6'_i2 `7'_s2 `7'_i2 `8'_s2 `8'_i2
			esttab `regressions' using "rth_`generate'_outcomes.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{15}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\end{tabular} \\ \begin{tablenotes}[flushleft] \\ \footnotesize \\ \item Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. \\ \end{tablenotes} \\ \end{threeparttable} \\ \end{adjustbox} \\ \end{table}") 
						

end		

	* execute the program providing the list of variables
rth_size eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1, gen(size5)
	
}

* MHT corrections
	* 1: Anderson q-values
{
* Multiple hypotheses testing corrections
	* 1: Anderson q-values
		* transform matrix into variable/data set with one variable pvals
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
export excel using "${master_regressiontables}/midline/het_empl5_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues


	* 2: Romano-Wolf FWER
wolf2 ///
	treatment take_up /// Ivars
	eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1 /// Dvars
	entrep_size==1 entrep_size==2 surveyround==2 /// conditions
	het_empl5_rwvalues // name
}

	* eri | NOTHING
{
local outcome "eri"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

	* eri | SIGNIFICANT Small 95TH TOT
	
{
local outcome "eri_ssa"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness SSA by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index SSA") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

	* epp | 90% LARGE TOT
{
local outcome "epp"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export performance by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export performance") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

	* mpi  | 95 & 99% SMALL SIGNIFICANT
{
local outcome "mpi"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on management performance index by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Management performance index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

	* female_efficacy   | LARGE 99% SIGNIFICANT
{
local outcome "female_efficacy"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female efficacy  by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female efficacy") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

	* female_loc | 95TH Large TOT
{
local outcome "female_loc"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female locus by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female locus") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

* genderi | 99TH Large
{
local outcome "genderi"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on gender index by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Gender index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

* car_empl1_w99_k3  | LARGE 95TH & 90TH
{
local outcome "car_empl1_w99_k3"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female employees by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female employees") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}

* ihs_profit_w99_k1  | NOTHING
{
local outcome "ihs_profit_w99_k1"
local conditions "entrep_size==1 entrep_size==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on IHS profits, wins. by firm size (5)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl5_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("IHS profit, wins.") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm5_`outcome', replace)
gr export el_het_firm5_`outcome'.png, replace

}
}

{
{

	* all in one table
capture program drop rth_size
program rth_size
	version 16
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "entrep_size2==1 entrep_size2==2"
		local groups "s i"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
					* ITT
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'

	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_s1_p1 \ `1'_i1_p1 \ `2'_s1_p1 \ `2'_i1_p1 \ `3'_s1_p1 \ `3'_i1_p1 \ `4'_s1_p1 \ `4'_i1_p1 \ `5'_s1_p1 \ `5'_i1_p1 \ `6'_s1_p1 \ `6'_i1_p1  \ `7'_s1_p1\ `7'_i1_p1 \ `8'_s1_p1\ `8'_i1_p1 \ `9'_s1_p1\ `9'_i1_p1 \ `1'_s2_p2\ `1'_i2_p2 \ `2'_s2_p2\ `2'_i2_p2\ `3'_s2_p2\ `3'_i2_p2 \ `4'_s2_p2\ `4'_i2_p2 \ `5'_s2_p2\ `5'_i2_p2 \ `6'_s2_p2\ `6'_i2_p2 \ `7'_s2_p2\ `7'_i2_p2 \ `8'_s2_p2\ `8'_i2_p2 \ `9'_s2_p2\ `9'_i2_p2)

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_s1 `1'_i1 `2'_s1 `2'_i1 `3'_s1 `3'_i1 `4'_s1 `4'_i1  `5'_s1 `5'_i1 `6'_s1 `6'_i1 `7'_s1 `7'_i1 `8'_s1 `8'_i1 `9'_s1 `9'_i1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key variables by firm size (10)} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \\ \begin{tabular}{l*{20}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{19}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Female employees" "Profit, ihs.", pattern(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)) ///
						mlabels("Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large & Small & Large", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_s2 `1'_i2 `2'_s2 `2'_i2 `3'_s2 `3'_i2 `4'_s2 `4'_i2  `5'_s2 `5'_i2 `6'_s2 `6'_i2 `7'_s2 `7'_i2 `8'_s2 `8'_i2
			esttab `regressions' using "rth_`generate'_outcomes.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{15}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\end{tabular} \\ \begin{tablenotes}[flushleft] \\ \footnotesize \\ \item Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. \\ \end{tablenotes} \\ \end{threeparttable} \\ \end{adjustbox} \\ \end{table}") 
						

end		

	* execute the program providing the list of variables
rth_size eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1, gen(size10)
	
}

* MHT corrections
	* 1: Anderson q-values
{
* Multiple hypotheses testing corrections
	* 1: Anderson q-values
		* transform matrix into variable/data set with one variable pvals
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
export excel using "${master_regressiontables}/midline/het_empl10_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues


	* 2: Romano-Wolf FWER
wolf2 ///
	treatment take_up /// Ivars
	eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1 /// Dvars
	entrep_size2==1 entrep_size2==2 surveyround==2 /// conditions
	het_empl10_rwvalues // name
}

	* eri | NOTHING
{
local outcome "eri"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

	* eri | NEGATIVE SIGNIFICANT 90% LARGE
	
{
local outcome "eri_ssa"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness SSA by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index SSA") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

	* epp | NEGATIVE SIGNIFICANT 95% LARGE
{
local outcome "epp"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export performance by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export performance") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

	* mpi  | 95% SIGNIFICANT LARGE TOT
{
local outcome "mpi"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on management performance index by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Management performance index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

	* female_efficacy   | LARGE 99% SIGNIFICANT
{
local outcome "female_efficacy"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female efficacy  by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female efficacy") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

	* female_loc | NOTHING
{
local outcome "female_loc"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female locus by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female locus") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

* genderi | 99TH Large TOT
{
local outcome "genderi"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on gender index by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Gender index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

* car_empl1_w99_k3  | 90 TH SMALL TOT
{
local outcome "car_empl1_w99_k3"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female employees by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female employees") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}

* ihs_profit_w99_k1  | - TOT LARGE 99TH, + 95TH SMALL TOT
{
local outcome "ihs_profit_w99_k1"
local conditions "entrep_size2==1 entrep_size2==2"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on IHS profits, wins. by firm size (10)} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names Large models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_empl10_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Small" "Large", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names Large models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported Large the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Small (ITT)"' `outcome'_s2 = `"Small (TOT)"' `outcome'_i1 = `"Large (ITT)"' `outcome'_i2 = `"Large (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("IHS profit, wins.") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_firm10_`outcome', replace)
gr export el_het_firm10_`outcome'.png, replace

}
}

***********************************************************************
* 	PART 3:  Pole heterogeneity
***********************************************************************
{
{
	* all in one table
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
					
					* ITT
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at midline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'

	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_aa1_p1 \ `1'_ac1_p1 \ `1'_s1_p1 \ `1'_tic1_p1 \ `2'_aa1_p1 \ `2'_ac1_p1 \ `2'_s1_p1 \ `2'_tic1_p1 \ `3'_aa1_p1 \ `3'_ac1_p1 \ `3'_s1_p1 \ `3'_tic1_p1 \ `4'_aa1_p1 \ `4'_ac1_p1 \ `4'_s1_p1 \ `4'_tic1_p1 \ `5'_aa1_p1 \ `5'_ac1_p1 \ `5'_s1_p1 \ `5'_tic1_p1 \ `6'_aa1_p1 \ `6'_ac1_p1 \ `6'_s1_p1 \ `6'_tic1_p1 \ `7'_aa1_p1\ `7'_ac1_p1\ `7'_s1_p1 \ `7'_tic1_p1 \ `8'_aa1_p1\ `8'_ac1_p1\ `8'_s1_p1\ `8'_tic1_p1 \ `9'_aa1_p1\ `9'_ac1_p1\ `9'_s1_p1 \ `9'_tic1_p1 \ `1'_aa2_p2\ `1'_ac2_p2\ `1'_s2_p2 \ `1'_tic2_p2 \  `2'_aa2_p2\ `2'_ac2_p2\ `2'_s2_p2 \ `2'_tic2_p2 \ `3'_aa2_p2\ `3'_ac2_p2\ `3'_s2_p2 \ `3'_tic2_p2 \ `4'_aa2_p2\ `4'_ac2_p2\ `4'_s2_p2 \ `4'_tic2_p2 \ `5'_aa2_p2\ `5'_ac2_p2\ `5'_s2_p2 \ `5'_tic2_p2 \ `6'_aa2_p2\ `6'_ac2_p2\ `6'_s2_p2 \  `6'_tic2_p2 \ `7'_aa2_p2\ `7'_ac2_p2\ `7'_s2_p2 \  `7'_tic2_p2 \ `8'_aa2_p2\ `8'_ac2_p2\ `8'_s2_p2 \  `8'_tic2_p2 \ `9'_aa2_p2\ `9'_ac2_p2\ `9'_s2_p2 \ `9'_tic2_p2)

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_aa1 `1'_ac1 `1'_s1 `1'_tic1 `2'_aa1 `2'_ac1 `2'_s1 `2'_tic1 `3'_aa1 `3'_ac1 `3'_s1 `3'_tic1 `4'_aa1 `4'_ac1 `4'_s1 `4'_tic1 `5'_aa1 `5'_ac1 `5'_s1 `5'_tic1 `6'_aa1 `6'_ac1 `6'_s1 `6'_tic1 `7'_aa1 `7'_ac1 `7'_s1 `7'_tic1 `8'_aa1 `8'_ac1 `8'_s1 `8'_tic1 `9'_aa1 `9'_ac1 `9'_s1 `9'_tic1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key outcome variables by firm size} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \begin{tabular}{l*{38}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{37}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Female employees" "Profit, ihs.", pattern(0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0 0 0 1 0  )) ///
						mlabels("Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC & Agro & Artisanat & Service & TIC", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_aa2 `1'_ac2 `1'_s2 `1'_tic2 `2'_aa2 `2'_ac2 `2'_s2 `2'_tic2 `3'_aa2 `3'_ac2 `3'_s2 `3'_tic2 `4'_aa2 `4'_ac2 `4'_s2 `4'_tic2 `5'_aa2 `5'_ac2 `5'_s2 `5'_tic2 `6'_aa2 `6'_ac2 `6'_s2 `6'_tic2 `7'_aa2 `7'_ac2 `7'_s2 `7'_tic2 `8'_aa2 `8'_ac2 `8'_s2 `8'_tic2 `9'_aa2 `9'_ac2 `9'_s2 `9'_tic2
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
rth_pole eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1, gen(pole_outcomes)

}


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
export excel using "${master_regressiontables}/midline/het_pole_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues
}
	* 2: Romano-Wolf FWER
	* 2: Romano-Wolf FWER
wolf4 ///
	treatment take_up /// Ivars
	eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1 /// Dvars
	pole==1 pole==2 pole==3 pole==4 surveyround==2 /// conditions
	het_pole_rwvalues // name
}


	* eri | SIGNIFICANT FOR AGRICULTURE AT 90TH
{
local outcome "eri"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness index by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* eri_ssa | NOT SIGNIFICANT
{
local outcome "eri_ssa"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness index SSA by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index SSA") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* epp | SIGNIFICANT NEGATIVE FOR ARTISANAT
{
local outcome "epp"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export performance by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export performance") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* mpi | 95TH SIGNIFICANT AGRI & TIC
{
local outcome "mpi"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on management practices by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Management practices") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* female_efficacy | 95TH SIGNIFICANT SERVICE TOT
{
local outcome "female_efficacy"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female efficacy by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female efficacy") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* female_loc | SERVICE 99TH SIGNIFICANT TOT
{
local outcome "female_loc"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female locus by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female locus") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* genderi | SERVICE 99TH SIGNIFICANT TOT
{
local outcome "genderi"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on gender index by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Gender index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* car_empl1_w99_k3 | TIC & AGI 99TH SIGNIFICANT TOT
{
local outcome "car_empl1_w99_k3"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female employees by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female employees") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}

* ihs_profit_w99_k1 | TIC & AGI 95TH
{
local outcome "car_empl1_w99_k3"
local conditions "pole==1 pole==2 pole==3 pole==4"
local groups "aa ac s tic"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_aa1 `outcome'_ac1 `outcome'_s1 `outcome'_tic1 
esttab `regressions' using "rt_hetero_pole_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on ihs profit wins. by consortia} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{6}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_aa2 `outcome'_ac2 `outcome'_s2 `outcome'_tic2 
		esttab `regressions' using "rt_hetero_pole_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Agriculture" "Artisanat" "Service" "TIC", ///
				pattern(1 1 1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_aa1, pstyle(p1)) (`outcome'_aa2, pstyle(p1)) ///
	(`outcome'_ac1, pstyle(p2)) (`outcome'_ac2, pstyle(p2)) ///
	(`outcome'_s1, pstyle(p3)) (`outcome'_s2, pstyle(p3)) ///
	(`outcome'_tic1, pstyle(p4)) (`outcome'_tic2, pstyle(p4)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_aa1 = `"Agriculture (ITT)"' `outcome'_aa2 = `"Agriculture (TOT)"' `outcome'_ac1 = `"Artisanat (ITT)"' `outcome'_ac2 = `"Artisanat (TOT)"' `outcome'_s1 = `"Service (ITT)"' `outcome'_s2 = `"Service (TOT)"' `outcome'_tic1 = `"TIC (ITT)"' `outcome'_tic2 = `"TIC (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("IHS profit, wins.") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wid_plateformeer & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_pole_`outcome', replace)
gr export el_het_pole_`outcome'.png, replace

}
}
***********************************************************************
* 	PART 4:  Network heterogeneity
***********************************************************************
{
/*

sum net_size_w99 if surveyround == 2, d

                        Network size
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%            0              0
10%            0              0       Obs                 141
25%            2              0       Sum of wgt.         141

50%            5                      Mean           9.574468
                        Largest       Std. dev.      13.52312
75%           10             57
90%           25             60       Variance       182.8748
95%           36             80       Skewness       3.027139
99%           80             80       Kurtosis       13.87761


*/
{

	* all in one table
capture program drop rth_network
program rth_network
	version 16
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "net_size_w99>=10 net_size_w99<10"
		local groups "s i"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
					* ITT
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'

	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_s1_p1 \ `1'_i1_p1 \ `2'_s1_p1 \ `2'_i1_p1 \ `3'_s1_p1 \ `3'_i1_p1 \ `4'_s1_p1 \ `4'_i1_p1 \ `5'_s1_p1 \ `5'_i1_p1 \ `6'_s1_p1 \ `6'_i1_p1  \ `7'_s1_p1\ `7'_i1_p1 \ `8'_s1_p1\ `8'_i1_p1 \ `9'_s1_p1\ `9'_i1_p1 \ `1'_s2_p2\ `1'_i2_p2 \ `2'_s2_p2\ `2'_i2_p2\ `3'_s2_p2\ `3'_i2_p2 \ `4'_s2_p2\ `4'_i2_p2 \ `5'_s2_p2\ `5'_i2_p2 \ `6'_s2_p2\ `6'_i2_p2 \ `7'_s2_p2\ `7'_i2_p2 \ `8'_s2_p2\ `8'_i2_p2 \ `9'_s2_p2\ `9'_i2_p2)

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_s1 `1'_i1 `2'_s1 `2'_i1 `3'_s1 `3'_i1 `4'_s1 `4'_i1  `5'_s1 `5'_i1 `6'_s1 `6'_i1 `7'_s1 `7'_i1 `8'_s1 `8'_i1 `9'_s1 `9'_i1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key variables when quality is below the mean of network size} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \\ \begin{tabular}{l*{20}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{19}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Female employees" "Profit, ihs.", pattern(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)) ///
						mlabels("Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_s2 `1'_i2 `2'_s2 `2'_i2 `3'_s2 `3'_i2 `4'_s2 `4'_i2  `5'_s2 `5'_i2 `6'_s2 `6'_i2 `7'_s2 `7'_i2 `8'_s2 `8'_i2
			esttab `regressions' using "rth_`generate'_outcomes.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{15}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\end{tabular} \\ \begin{tablenotes}[flushleft] \\ \footnotesize \\ \item Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. \\ \end{tablenotes} \\ \end{threeparttable} \\ \end{adjustbox} \\ \end{table}") 
						

end		

	* execute the program providing the list of variables
rth_network eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1, gen(net_key)
	
}

* MHT corrections
	* 1: Anderson q-values
{
* Multiple hypotheses testing corrections
	* 1: Anderson q-values
		* transform matrix into variable/data set with one variable pvals
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
export excel using "${master_regressiontables}/midline/het_size_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues


	* 2: Romano-Wolf FWER
wolf2 ///
	treatment take_up /// Ivars
	eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1 /// Dvars
	net_size_w99>=10 net_size_w99<10 surveyround==2 /// conditions
	het_network_rwvalues // name
}

	* eri | NOTHING
{
local outcome "eri"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

	* eri SSA | SIGNIFICANT ABOVE 95TH TOT
	
{
local outcome "eri_ssa"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness SSA by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index SSA") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

	* epp | NOTHING
{
local outcome "epp"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export performance by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export performance") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

	* mpi  | NOTHING
{
local outcome "mpi"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on management performance index by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Management performance index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

	* female_efficacy   | NOTHING
{
local outcome "female_efficacy"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female efficacy  by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female efficacy") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

	* female_loc | 90TH BELOW
{
local outcome "female_loc"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female locus by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female locus") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

* genderi | 90TH BELOW
{
local outcome "genderi"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on gender index by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Gender index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

* car_empl1_w99_k3  | 99TH TOT SIGNIFICANT FOR ABOVE
{
local outcome "car_empl1_w99_k3"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female employees by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female employees") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}

* ihs_profit_w99_k1  | 90TH TOT SIGNIFICANT
{
local outcome "ihs_profit_w99_k1"
local conditions "net_size_w99>=10 net_size_w99<10"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_network_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on IHS profits, wins. by network size} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_network_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("IHS profit, wins.") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_network_`outcome', replace)
gr export el_het_network_`outcome'.png, replace

}
}
***********************************************************************
* 	PART 4:  MPI heterogeneity
***********************************************************************
{
/*

sum mpi if surveyround==2, d

                    Management practices
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -1.444829      -2.038404
 5%     -.895434      -1.444829
10%    -.5955321      -1.239517       Obs                 139
25%    -.1486045      -1.191466       Sum of wgt.         139

50%     .1529461                      Mean           .0885276
                        Largest       Std. dev.      .5255135
75%     .4511993       1.009682
90%     .6100951       1.009682       Variance       .2761644
95%     .7601891       1.059381       Skewness      -.7578842
99%     1.059381       1.722517       Kurtosis       4.966112


*/
{

	* all in one table
capture program drop rth_mpi
program rth_mpi
	version 16
	syntax varlist(min=1 numeric), GENerate(string)
		
		* Run all regression and collect relevant info
foreach outcome in `varlist' {
	
		local conditions "mpi>=0.1529461 mpi<0.1529461"
		local groups "s i"
		
		foreach cond of local conditions {
				gettoken group groups : groups
					
					* ITT
					eststo `outcome'_`group'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display
					matrix b = r(table)			// access p-values for mht
					scalar `outcome'_`group'1_p1 = b[4,2]


					* ATT, IV		
					eststo `outcome'_`group'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
					estadd local bl_control "Yes"
					estadd local strata_final "Yes"
					quietly ereturn display // provides same table but with r(table)
					matrix b = r(table)
					scalar `outcome'_`group'2_p2 = b[4,1]
					
					* calculate control group mean
						* take mean at endline to control for time trends
		sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
		estadd scalar control_mean = r(mean)
		estadd scalar control_sd = r(sd)
		}
}
	* Change logic: apply to all variables at a time
tokenize `varlist'

	* Multiple hypotheses testing correction
		* Put all p-values in matrix
mat p = (`1'_s1_p1 \ `1'_i1_p1 \ `2'_s1_p1 \ `2'_i1_p1 \ `3'_s1_p1 \ `3'_i1_p1 \ `4'_s1_p1 \ `4'_i1_p1 \ `5'_s1_p1 \ `5'_i1_p1 \ `6'_s1_p1 \ `6'_i1_p1  \ `7'_s1_p1\ `7'_i1_p1 \ `8'_s1_p1\ `8'_i1_p1 \ `9'_s1_p1\ `9'_i1_p1 \ `1'_s2_p2\ `1'_i2_p2 \ `2'_s2_p2\ `2'_i2_p2\ `3'_s2_p2\ `3'_i2_p2 \ `4'_s2_p2\ `4'_i2_p2 \ `5'_s2_p2\ `5'_i2_p2 \ `6'_s2_p2\ `6'_i2_p2 \ `7'_s2_p2\ `7'_i2_p2 \ `8'_s2_p2\ `8'_i2_p2 \ `9'_s2_p2\ `9'_i2_p2)

mat colnames p = "pvalues"

		* Put everything into a regression table
			local regressions `1'_s1 `1'_i1 `2'_s1 `2'_i1 `3'_s1 `3'_i1 `4'_s1 `4'_i1  `5'_s1 `5'_i1 `6'_s1 `6'_i1 `7'_s1 `7'_i1 `8'_s1 `8'_i1 `9'_s1 `9'_i1
		esttab `regressions' using "rth_`generate'_outcomes.tex", replace ///
						prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on key variables when quality is below the mean of network size} \\ \begin{adjustbox}{width=\columnwidth,center} \\ \begin{threeparttable} \\ \begin{tabular}{l*{20}{c}} \hline\hline") ///
						posthead("\hline \\ \multicolumn{19}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
						fragment ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						nobaselevels ///
						label 		/// specifies EVs have label
						mgroups("Export readiness index" "SSA Export readiness index" "Export performance" "Management practices index" "Female efficacy" "Female loucs" "Gender index" "Female employees" "Profit, ihs.", pattern(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)) ///
						mlabels("Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below & Above & Below", numbers) ///
						collabels(none) ///	do not use statistics names below models
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						noobs
					
						* Bottom panel: ITT
			local regressions `1'_s2 `1'_i2 `2'_s2 `2'_i2 `3'_s2 `3'_i2 `4'_s2 `4'_i2  `5'_s2 `5'_i2 `6'_s2 `6'_i2 `7'_s2 `7'_i2 `8'_s2 `8'_i2
			esttab `regressions' using "rth_`generate'_outcomes.tex", append ///
						fragment ///
						posthead("\hline \\ \multicolumn{15}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
						cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
						stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
						drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
						star(* 0.1 ** 0.05 *** 0.01) ///
						mlabels(none) nonumbers ///		do not use varnames as model titles
						collabels(none) ///	do not use statistics names below models
						nobaselevels ///
						label 		/// specifies EVs have label
						prefoot("\hline") ///
						postfoot("\end{tabular} \\ \begin{tablenotes}[flushleft] \\ \footnotesize \\ \item Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors. \\ \end{tablenotes} \\ \end{threeparttable} \\ \end{adjustbox} \\ \end{table}") 
						

end		

	* execute the program providing the list of variables
rth_mpi eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1, gen(mpi)
	
}

* MHT corrections
	* 1: Anderson q-values
{
* Multiple hypotheses testing corrections
	* 1: Anderson q-values
		* transform matrix into variable/data set with one variable pvals
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
export excel using "${master_regressiontables}/midline/het_mpi_outcome_qvalues", replace firstrow(var)

		* return to default frame and drop for use in next regression table
frame change default
frame drop qvalues


	* 2: Romano-Wolf FWER
wolf2 ///
	treatment take_up /// Ivars
	eri eri_ssa epp mpi female_efficacy female_loc genderi car_empl1_w99_k3 ihs_profit_w99_k1 /// Dvars
	mpi>=0.1529461 mpi<0.1529461 surveyround==2 /// conditions
	het_mpi_rwvalues // name
}

	* eri | NOTHING
{
local outcome "eri"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

	* eri SSA | NOTHING
	
{
local outcome "eri_ssa"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export readiness SSA by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export readiness index SSA") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

	* epp | + SIGNIFICANT FOR BELOW 90TH
{
local outcome "epp"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on export performance by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(90) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Export performance") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 90th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

	* mpi  | NOTHING
{
local outcome "mpi"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on management performance index by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Management performance index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

	* female_efficacy   | ABOVE SIGNIFICANT AT 95TH & 99TH
{
local outcome "female_efficacy"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female efficacy  by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female efficacy") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

	* female_loc | ABOVE TOT SIG AT 99TH & 90TH ITT
{
local outcome "female_loc"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female locus by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female locus") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

* genderi | 99TH ITT TOT ABOVE
{
local outcome "genderi"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on gender index by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(99) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Gender index") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 99th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

* car_empl1_w99_k3  | NOTHING
{
local outcome "car_empl1_w99_k3"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on female employees by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("Female employees") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}

* ihs_profit_w99_k1  | NOTHING
{
local outcome "ihs_profit_w99_k1"
local conditions "mpi>=0.1529461 mpi<0.1529461"
local groups "s i"

foreach cond of local conditions {
		gettoken sector sectors : sectors
			eststo `outcome'_`sector'1: reg `outcome' i.treatment c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final if `cond' & surveyround==2, cluster(id_plateforme)
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,2]

			* ATT, IV		
			eststo `outcome'_`sector'2: ivreg2 `outcome' c.`outcome'_y0 i.missing_bl_`outcome' i.strata_final (take_up = i.treatment) if `cond' & surveyround==2, cluster(id_plateforme) first
			estadd local bl_control "Yes"
			estadd local strata_final "Yes"
			matrix b = r(table)			// access p-values for mht
			scalar `outcome'p1 = b[4,1]
			
			* calculate control group mean
				* take mean at endline to control for time trends
sum `outcome' if treatment == 0 & surveyround == 2 & `cond'
estadd scalar control_mean = r(mean)
estadd scalar control_sd = r(sd)
}


	local regressions `outcome'_s1 `outcome'_i1
esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", replace ///
				prehead("\begin{table}[!h] \centering \\ \caption{Treatment effect on IHS profits, wins. by mpi median} \\ \begin{adjustbox}{wid_plateformeth=\columnwid_plateformeth,center} \\ \begin{tabular}{l*{4}{c}} \hline\hline") ///
				posthead("\hline \\ \multicolumn{3}{c}{\textbf{Panel A: Intention-to-treat (ITT)}} \\\\[-1ex]") ///
				fragment ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				mlabels(, depvars) /// use dep vars labels as model title
				star(* 0.1 ** 0.05 *** 0.01) ///
				nobaselevels ///
				label 		/// specifies EVs have label
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				collabels(none) ///	do not use statistics names below models
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				noobs
				
				* Bottom panel: ITT
	local regressions `outcome'_s2 `outcome'_i2
		esttab `regressions' using "rt_hetero_mpi_`outcome'.tex", append ///
				fragment ///
				posthead("\hline \\ \multicolumn{5}{c}{\textbf{Panel B: Treatment Effect on the Treated (TOT)}} \\\\[-1ex]") ///
				cells(b(star fmt(3)) se(par fmt(3)) p(fmt(3)) rw) ///
				stats(control_mean control_sd N strata_final bl_control, fmt(%9.2fc %9.2fc %9.0g) labels("Control group mean" "Control group SD" "Observations" "strata_final controls" "Y0 controls")) ///
				drop(_cons *.strata_final ?.missing_bl_* *_y0) ///
				star(* 0.1 ** 0.05 *** 0.01) ///
				mgroups("Above" "Below", ///
				pattern(1 1)) ///
				mlabels(none) nonumbers ///		do not use varnames as model titles
				collabels(none) ///	do not use statistics names below models
				nobaselevels ///
				label 		/// specifies EVs have label
				prefoot("\hline") ///
				postfoot("\hline\hline\hline \\ \multicolumn{3}{@{}p{\textwid_plateformeth}@{}}{ \footnotesize \parbox{\linewid_plateformeth}{% Notes: Each specification includes controls for randomization strata_final, baseline outcome, and a missing baseline dummy. QI perception is a z-score indices calculated following Kling et al. (2007). Small corresponds to firms with less or 25 employees, medium more than 25 and less or 70 employees, and large to more than 70 and up to 200 employees at baseline. Panel A reports ANCOVA estimates as defined in Mckenzie and Bruhn (2011). Panel B documents IV estimates, instrumenting take-up with treatment assignment. Clustered standard errors by firms in parentheses. \sym{***} \(p<0.01\), \sym{**} \(p<0.05\), \sym{*} \(p<0.1\) denote the significance level. P-values and adjusted p-values for multiple hypotheses testing using the Romano-Wolf correction procedure (Clarke et al., 2020) with 999 bootstrap replications are reported below the standard errors.% \\ }} \\ \end{tabular} \\ \end{adjustbox} \\ \end{table}") // when inserting table in overleaf/latex, requires adding space after %
				
			* coefplot
coefplot ///
	(`outcome'_s1, pstyle(p1)) (`outcome'_s2, pstyle(p1)) ///
	(`outcome'_i1, pstyle(p2)) (`outcome'_i2, pstyle(p2)), ///
	keep(*treatment take_up) drop(_cons) xline(0) ///
		asequation /// name of model is used
		swapnames /// swaps coeff & equation names after collecting result
		levels(95) /// 95th percentile is null-effect, although tight
		eqrename(`outcome'_s1 = `"Above (ITT)"' `outcome'_s2 = `"Above (TOT)"' `outcome'_i1 = `"Below (ITT)"' `outcome'_i2 = `"Below (TOT)"') ///
		ytitle("", size(medium)) ///
		xtitle("IHS profit, wins.") ///
		leg(off) xsize(4.5) /// xsize controls aspect ratio, makes graph wider & reduces its height
		note("Confidence interval at the 95th percentile.", span size(small)) /// 95th only holds for lare firms
		name(el_het_mpi_`outcome', replace)
gr export el_het_mpi_`outcome'.png, replace

}
}