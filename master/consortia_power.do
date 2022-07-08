***********************************************************************
* 			power, female export consortias
***********************************************************************
*																	  
*	PURPOSE: calculate baseline power for JDE stage-1 application						  
*																	  
*	OUTLINE: 	PART 1: set the stage  
*				Part 2: estimate power for export at all
*					PART 2.1: get all relevant baseline parameters
*					PART 2.2:	define assumed treatment effects
*					PART 2.3: estimate power given relevant parameters
*					PART 2.4: estimate MDE at 80% power
*				Part 3: estimate power for ihs export sales
*							...
*				Part end: table notes
*											  
*	Author:  	Florian Münch
*	ID variable: id_plateforme		  					  
*	Requires:  	 consortium_raw									  
*	Creates:     	-

***********************************************************************
* 	PART 1:    set the stage	  
***********************************************************************
use "${master_raw}/consortium_raw", clear

	* set folder path 
cd "$master_power"

	* generate necessary variables 
		*ihs transformed export sales
forvalues year = 2018(1) 2020 {
	ihstrans ca_exp`year'
}
		* average export sales 2018, 2019
gen mean_caexp_1819 = (ihs_ca_exp2018 + ihs_ca_exp2019)/2

	
	* create excel document
putexcel set power_consortia, replace

	* define table title
putexcel A1 = "Power calculations", bold border(bottom) left
	
	* create top border for variable names
putexcel A2:I2 = "", border(top)
	
	* define column headings
putexcel A2 = "", border(bottom) hcenter
putexcel B2 = "Export at all", border(bottom) hcenter
putexcel C2 = "IHS export sales", border(bottom) hcenter
putexcel D2 = "Countries exported", border(bottom) hcenter
putexcel E2 = "Log employees", border(bottom) hcenter
putexcel F2 = "Export practices index", border(bottom) hcenter
putexcel G2 = "Management practices index", border(bottom) hcenter
putexcel H2 = "Gender index", border(bottom) hcenter
putexcel I2 = "Network index", border(bottom) hcenter

***********************************************************************
* 	PART 2:    estimate power for export at all
***********************************************************************
***********************************************************************
* 	PART 2.1:     get all the relevant baseline parameters
***********************************************************************
	* define first column
putexcel A3 = "Parameters from baseline data", italic left

	* add mean
putexcel A4 = "Baseline mean", hcenter
sum operation_export
local operation_export_mean = r(mean)
putexcel B4 = `operation_export_mean', hcenter nformat(number_d2)

	* add SD
putexcel A5 = "Baseline SD", hcenter
local operation_export_sd = r(sd)
putexcel B5 = `operation_export_sd', hcenter nformat(number_d2)
scalar operation_export_sd = r(sd)

	* add residual SD
putexcel A6 = "Residual SD", hcenter
regress operation_export i.strata_final, vce(hc3)
scalar operation_export_ressd = sqrt(1 - e(r2))
local operation_export_ressd = operation_export_sd * operation_export_ressd
putexcel B6 = `operation_export_ressd', hcenter nformat(number_d2)
		
		* 1-year (only applies to export sales)
putexcel A7 = "1-year autocorrelation", hcenter
putexcel B7 = "0,80", hcenter
		
		* average 2-year autocorrelation (only applies to export sales)
putexcel A8 = "2-year autocorrelation", hcenter
putexcel B8 = "0,70", hcenter

***********************************************************************
* 	PART 2.2.:     define assumed treatment effects
***********************************************************************
	* export extensive margin
		* as percent
putexcel A9 = "Assumed treatment effect", italic left
putexcel B9	= "0.175", hcenter
		* as percentage point
putexcel A10 = "as a percentage change", hcenter
putexcel B10 = "34.3", hcenter

***********************************************************************
* 	PART 2.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
putexcel A11 = "Power", italic left

	* comparison of means
putexcel A12 = "comparison of means", hcenter
sampsi 0.45 0.625, n1(80) n2(80) sd1(`operation_export_sd') sd2(`operation_export_sd')
local power = r(power)
putexcel B12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
putexcel A13 = "after controll for strata", hcenter
sampsi 0.45 0.625, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd')
local power = r(power)
putexcel B13 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
putexcel A14 = "Ancova 1-year before", hcenter
sampsi 0.45 0.625, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel B14 = `power', hcenter nformat(number_d2)

	* Ancova 2 years before 
putexcel A15 = "Ancova 2-years before", hcenter
sampsi 0.45 0.625, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(2) post(2) r1(0.7)
local power = r(power)
putexcel B15 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 2.4:     MDE at 80% power
***********************************************************************
putexcel A16 = "MDE at 80% power", italic

	*  comparison of means
putexcel A17 = "comparison of means", hcenter
sampsi .51 0.74, n1(80) n2(80) sd1(`operation_export_sd') sd2(`operation_export_sd')
local power = r(power)
putexcel B17 = 0.23, hcenter nformat(number_d2)

	* after controlling for strata 
putexcel A18 = "after controll for strata", hcenter
sampsi .51 0.695, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd')
local power = r(power)
putexcel B18 = 0.185, hcenter nformat(number_d2)

	* Ancova 1-year before
putexcel A19 = "Ancova 1-year before", hcenter
sampsi 0.45 0.545, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel B19 = 0.095, hcenter nformat(number_d2)

	* Ancova 5 years before 
putexcel A20 = "Ancova 2-years before", hcenter border(bottom)
sampsi 0.45 0.545, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(2) post(2) r1(0.7)
local power = r(power)
putexcel B20 = 0.095, hcenter nformat(number_d2) border(bottom)




***********************************************************************
* 	PART 3:    estimate power for export sales
***********************************************************************

***********************************************************************
* 	PART 3.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum ihs_ca_exp2020
local ihs_ca_exp2020_mean = r(mean)
putexcel C4 = `ihs_ca_exp2020_mean', hcenter nformat(number_d2)

	* add SD
local ihs_ca_exp2020_sd = r(sd)
putexcel C5 = `ihs_ca_exp2020_sd', hcenter nformat(number_d2)
scalar ihs_ca_exp2020_sd = r(sd)

	* add residual SD
regress ihs_ca_exp2020 i.strata_final, vce(hc3)
scalar ihs_ca_exp2020_ressd = sqrt(1 - e(r2))
local ihs_ca_exp2020_ressd = ihs_ca_exp2020_sd * ihs_ca_exp2020_ressd
putexcel C6 = `ihs_ca_exp2020_ressd', hcenter nformat(number_d2)
		
		* 1-year (only applies to export sales)
corr ihs_ca_exp2020 ihs_ca_exp2019
local correlation1 = r(rho)
putexcel C7 = `correlation1', hcenter nformat(number_d2)
		
		* average 2-year autocorrelation (only applies to export sales)
corr ihs_ca_exp2020 mean_caexp_1819
local correlation2 = r(rho)
putexcel C8 = `correlation2', hcenter nformat(number_d2)


***********************************************************************
* 	PART 3.2.:     define assumed treatment effects
***********************************************************************
	* export extensive margin
		* as percent
putexcel C9	= "0.43", hcenter
		* as percentage point
putexcel C10 = "0.1", hcenter

***********************************************************************
* 	PART 3.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 4.34 4.77, n1(80) n2(80) sd1(`ihs_ca_exp2020_sd') sd2(`ihs_ca_exp2020_sd')
local power = r(power)
putexcel C12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 4.34 4.77, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd')
local power = r(power)
putexcel C13 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 4.34 4.77, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel C14 = `power', hcenter nformat(number_d2)

	* Ancova 2 years before 
sampsi 4.34 4.77, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(2) post(2) r1(`correlation2')
local power = r(power)
putexcel C15 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 3.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 4.34 6.84, n1(80) n2(80) sd1(`ihs_ca_exp2020_sd') sd2(`ihs_ca_exp2020_sd')
local power = r(power)
putexcel C17 = 2.5, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 4.34 6.44, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd')
local power = r(power)
putexcel C18 = 2.1, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 4.34 5.44, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel C19 = 1.1, hcenter nformat(number_d2)

	* Ancova 2 years before 
sampsi 4.34 5.44, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(2) post(2) r1(0.7)
local power = r(power)
putexcel C20 = 1, hcenter nformat(number_d2) border(bottom)


***********************************************************************
* 	PART end:     Table notes
***********************************************************************
putexcel A21 = "Notes:"
putexcel A22 = "n.a. denotes not available."
putexcel A23 = "MDE denotes minimum detectable effect size."
putexcel A24 = "Residual SD is standard deviation after controlling for strata fixed effects."
putexcel A25 = "One-and two-year autocorrelation come frome self-reported registration data."
	
	