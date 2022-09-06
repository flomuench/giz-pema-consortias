***********************************************************************
* 			power, female export consortias
***********************************************************************
*																	  
*	PURPOSE: calculate baseline power for JDE stage-1 application						  
*																	  
*	OUTLINE: 	PART 1: set the stage  
*				Part 2: estimate power for export at all
*					PART 2.1: get all relevant baseline parameters
*					PART 2.2: define assumed treatment effects
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
putexcel F2 = "Export readiness index", border(bottom) hcenter
putexcel G2 = "Management practices index", border(bottom) hcenter
putexcel H2 = "Marketing practices index", border(bottom) hcenter
putexcel I2 = "Innovation index", border(bottom) hcenter
putexcel J2 = "Gender index", border(bottom) hcenter
 
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
putexcel B10 = "0.343", hcenter

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
* 	PART 4:    estimate power for countries exported
***********************************************************************

***********************************************************************
* 	PART 4.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum exp_pays
local exp_pays_mean = r(mean)
putexcel D4 = `exp_pays_mean', hcenter nformat(number_d2)

	* add SD
local exp_pays_sd = r(sd)
putexcel D5 = `exp_pays_sd', hcenter nformat(number_d2)
scalar exp_pays_sd = r(sd)

	* add residual SD
regress exp_pays i.strata_final, vce(hc3)
scalar exp_pays_ressd = sqrt(1 - e(r2))
local exp_pays_ressd = exp_pays_sd * exp_pays_ressd
putexcel D6 = `exp_pays_ressd', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 4.2.:     define assumed treatment effects
***********************************************************************
	* exported countries extensive margin
		* as percent
putexcel D9	= "0.5", hcenter
		* as percentage point
putexcel D10 = "***", hcenter

***********************************************************************
* 	PART 4.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means

sampsi  1.27 1.77, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd')
local power = r(power)
putexcel D12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 1.27 1.77, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd')
local power = r(power)
putexcel D13 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 4.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 1.27 2.37, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd')
local power = r(power)
putexcel D17 = 1.1, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 1.27 2.27, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd')
local power = r(power)
putexcel D18 = 1.0, hcenter nformat(number_d2)


***********************************************************************
* 	PART 5:    estimate power for log employees
***********************************************************************
gen log_employees= log(employes)

***********************************************************************
* 	PART 5.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum log_employees
local log_employees_mean = r(mean)
putexcel E4 = `log_employees_mean', hcenter nformat(number_d2)

	* add SD
local log_employees_sd = r(sd)
putexcel E5 = `log_employees_sd', hcenter nformat(number_d2)
scalar log_employees_sd = r(sd)

	* add residual SD
regress log_employees i.strata_final, vce(hc3)
scalar log_employees_ressd = sqrt(1 - e(r2))
local log_employees_ressd = log_employees_sd * log_employees_ressd
putexcel E6 = `log_employees_ressd', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 5.2.:     define assumed treatment effects
***********************************************************************
	* exported countries extensive margin
		* as percent
putexcel E9	= "0.2", hcenter
		* as percentage point
putexcel E10 = "***", hcenter

***********************************************************************
* 	PART 5.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi  1.68 1.88, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd')
local power = r(power)
putexcel E12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 1.68 1.88, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd')
local power = r(power)
putexcel E13 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 5.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 1.68 2.78, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd')
local power = r(power)
putexcel E17 = 1.1, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 1.68 2.68, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd')
local power = r(power)
putexcel E18 = 1.0, hcenter nformat(number_d2)

***********************************************************************
* 	PART 6:    estimate power for Export preparation
***********************************************************************
***********************************************************************
* 	PART 6.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum exportprep
local exportprep_mean = r(mean)
putexcel F4 = `exportprep_mean', hcenter nformat(number_d2)

	* add SD
local exportprep_sd = r(sd)
putexcel F5 = `exportprep_sd', hcenter nformat(number_d2)
scalar exportprep_sd = r(sd)

	* add residual SD
regress exportprep i.strata_final, vce(hc3)
scalar exportprep_ressd = sqrt(1 - e(r2))
local exportprep_ressd = exportprep_sd * exportprep_ressd
putexcel F6 = `exportprep_ressd', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 6.2.:     define assumed treatment effects
***********************************************************************
	* exported countries extensive margin
		* as percent
putexcel F9	= "0.1", hcenter
		* as percentage point
putexcel F10 = "***", hcenter

***********************************************************************
* 	PART 6.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi  0.03 0.13, n1(80) n2(80) sd1(`exportprep_sd') sd2(`exportprep_sd')
local power = r(power)
putexcel F12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.03 0.13, n1(80) n2(80) sd1(`exportprep_ressd') sd2(`exportprep_ressd')
local power = r(power)
putexcel F13 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 6.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 0.03 0.28, n1(80) n2(80) sd1(`exportprep_sd') sd2(`exportprep_sd')
local power = r(power)
putexcel F17 = 0.25, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 0.03 0.29, n1(80) n2(80) sd1(`exportprep_ressd') sd2(`exportprep_ressd')
local power = r(power)
putexcel F18 = 0.26, hcenter nformat(number_d2)


***********************************************************************
* 	PART 7:    estimate power for Management practices index
***********************************************************************
***********************************************************************
* 	PART 7.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum mngtvars
local mngtvars_mean = r(mean)
putexcel G4 = `mngtvars_mean', hcenter nformat(number_d2)

	* add SD
local mngtvars_sd = r(sd)
putexcel G5 = `mngtvars_sd', hcenter nformat(number_d2)
scalar mngtvars_sd = r(sd)

	* add residual SD
regress mngtvars i.strata_final, vce(hc3)
scalar mngtvars_ressd = sqrt(1 - e(r2))
local mngtvars_ressd = mngtvars_sd * mngtvars_ressd
putexcel G6 = `mngtvars_ressd', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 7.2.:     define assumed treatment effects
***********************************************************************
	* exported countries extensive margin
		* as percent
putexcel G9	= "0.1", hcenter
		* as percentage point
putexcel G10 = "***", hcenter

***********************************************************************
* 	PART 7.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi  0.03 0.13, n1(80) n2(80) sd1(`mngtvars_sd') sd2(`mngtvars_sd')
local power = r(power)
putexcel G12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.03 0.13, n1(80) n2(80) sd1(`mngtvars_ressd') sd2(`mngtvars_ressd')
local power = r(power)
putexcel G13 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 7.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 0.03 0.29, n1(80) n2(80) sd1(`mngtvars_sd') sd2(`mngtvars_sd')
local power = r(power)
putexcel G17 = 0.26, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 0.03 0.29, n1(80) n2(80) sd1(`mngtvars_ressd') sd2(`mngtvars_ressd')
local power = r(power)
putexcel G18 = 0.26, hcenter nformat(number_d2)


***********************************************************************
* 	PART 8:    estimate power for Marketing practices index
***********************************************************************
***********************************************************************
* 	PART 8.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum markvars
local markvars_mean = r(mean)
putexcel H4 = `markvars_mean', hcenter nformat(number_d2)

	* add SD
local markvars_sd = r(sd)
putexcel H5 = `markvars_sd', hcenter nformat(number_d2)
scalar markvars_sd = r(sd)

	* add residual SD
regress markvars i.strata_final, vce(hc3)
scalar markvars_ressd = sqrt(1 - e(r2))
local markvars_ressd = markvars_sd * markvars_ressd
putexcel H6 = `markvars_ressd', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 8.2.:     define assumed treatment effects
***********************************************************************
	* exported countries extensive margin
		* as percent
putexcel H9	= "0.1", hcenter
		* as percentage point
putexcel H10 = "***", hcenter

***********************************************************************
* 	PART 8.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 0.04 0.14, n1(80) n2(80) sd1(`markvars_sd') sd2(`markvars_sd')
local power = r(power)
putexcel H12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.04 0.14, n1(80) n2(80) sd1(`markvars_ressd') sd2(`markvars_ressd')
local power = r(power)
putexcel H13 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 8.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 0.04 0.31, n1(80) n2(80) sd1(`markvars_sd') sd2(`markvars_sd')
local power = r(power)
putexcel H17 = 0.27, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 0.04 0.31, n1(80) n2(80) sd1(`markvars_ressd') sd2(`markvars_ressd')
local power = r(power)
putexcel H18 = 0.27, hcenter nformat(number_d2)


***********************************************************************
* 	PART 9:    estimate power for Innovation index
***********************************************************************
***********************************************************************
* 	PART 9.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum innovars
local innovars_mean = r(mean)
putexcel I4 = `innovars_mean', hcenter nformat(number_d2)

	* add SD
local innovars_sd = r(sd)
putexcel I5 = `innovars_sd', hcenter nformat(number_d2)
scalar innovars_sd = r(sd)

	* add residual SD
regress innovars i.strata_final, vce(hc3)
scalar innovars_ressd = sqrt(1 - e(r2))
local innovars_ressd = innovars_sd * innovars_ressd
putexcel I6 = `innovars_ressd', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 9.2.:     define assumed treatment effects
***********************************************************************
	* exported countries extensive margin
		* as percent
putexcel I9	= "0.13", hcenter
		* as percentage point
putexcel I10 = "***", hcenter

***********************************************************************
* 	PART 9.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi  -0.01 0.12, n1(80) n2(80) sd1(`innovars_sd') sd2(`innovars_sd')
local power = r(power)
putexcel I12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi -0.01 0.12, n1(80) n2(80) sd1(`innovars_ressd') sd2(`innovars_ressd')
local power = r(power)
putexcel I13 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 9.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi -0.01 0.19, n1(80) n2(80) sd1(`innovars_sd') sd2(`innovars_sd')
local power = r(power)
putexcel I17 = 0.20, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi -0.01 0.18, n1(80) n2(80) sd1(`innovars_ressd') sd2(`innovars_ressd')
local power = r(power)
putexcel I18 = 0.19, hcenter nformat(number_d2)


***********************************************************************
* 	PART 10:    estimate power for Gender index
***********************************************************************
***********************************************************************
* 	PART 10.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum gendervars
local gendervars_mean = r(mean)
putexcel J4 = `gendervars_mean', hcenter nformat(number_d2)

	* add SD
local gendervars_sd = r(sd)
putexcel J5 = `gendervars_sd', hcenter nformat(number_d2)
scalar gendervars_sd = r(sd)

	* add residual SD
regress gendervars i.strata_final, vce(hc3)
scalar gendervars_ressd = sqrt(1 - e(r2))
local gendervars_ressd = gendervars_sd * gendervars_ressd
putexcel J6 = `gendervars_ressd', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 10.2.:     define assumed treatment effects
***********************************************************************
	* exported countries extensive margin
		* as percent
putexcel J9	= "0.1", hcenter
		* as percentage point
putexcel J10 = "***", hcenter

***********************************************************************
* 	PART 10.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi  -0.01 0.09, n1(80) n2(80) sd1(`gendervars_sd') sd2(`gendervars_sd')
local power = r(power)
putexcel J12 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi -0.01 0.09, n1(80) n2(80) sd1(`gendervars_ressd') sd2(`gendervars_ressd')
local power = r(power)
putexcel J13 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 10.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi -0.01 0.36, n1(80) n2(80) sd1(`gendervars_sd') sd2(`gendervars_sd')
local power = r(power)
putexcel J17 = 0.37, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi -0.01 0.33, n1(80) n2(80) sd1(`gendervars_ressd') sd2(`gendervars_ressd')
local power = r(power)
putexcel J18 = 0.34, hcenter nformat(number_d2)

***********************************************************************
* 	PART end:     Table notes
***********************************************************************
putexcel A21 = "Notes:"
putexcel A22 = "n.a. denotes not available."
putexcel A23 = "MDE denotes minimum detectable effect size."
putexcel A24 = "Residual SD is standard deviation after controlling for strata fixed effects."
putexcel A25 = "One-and two-year autocorrelation come frome self-reported registration data."
	
	