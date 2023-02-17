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
 
 
* define first column
putexcel A3 = "A. Parameters from baseline data", italic left

*define row headings
putexcel A4 = "Baseline mean", hcenter
putexcel A5 = "Baseline SD", hcenter
putexcel A6 = "Residual SD", hcenter
putexcel A7 = "1-year autocorrelation", hcenter
putexcel A8 = "2-year autocorrelation", hcenter
putexcel A10 = "B. Assumed treatment effect", italic left
putexcel A11 = "Assumed take-up", hcenter
putexcel A12 = "take-up adjusted treatment effect", hcenter
putexcel A13 = "as a percentage change", hcenter
putexcel A14 = "C. Power of take-up adjusted treatment effect", italic left
putexcel A15 = "comparison of means", hcenter
putexcel A16 = "after controll for strata", hcenter
putexcel A17 = "Ancova 1-year before", hcenter
putexcel A18 = "Ancova 2-year before", hcenter
putexcel A19 = "D. MDE at 80% power and 67% take up (compare with assumed treatment effect)", italic left
putexcel A20 = "comparison of means", hcenter
putexcel A21 = "after controll for strata", hcenter
putexcel A22 = "Ancova 1-year before", hcenter
putexcel A23 = "Ancova 2-year before", hcenter
putexcel A24 = "Notes:"
putexcel A25 = "n.a. denotes not available."
putexcel A26 = "MDE denotes minimum detectable effect size."
putexcel A27 = "Residual SD is standard deviation after controlling for strata fixed effects."
putexcel A28 = "One-and two-year autocorrelation come frome self-reported registration data."

***********************************************************************
* 	PART 2:    estimate power for export at all
***********************************************************************
{
***********************************************************************
* 	PART 2.1:     get all the relevant baseline parameters
***********************************************************************

	* add mean
sum operation_export
local operation_export_mean = r(mean)
putexcel B4 = `operation_export_mean', hcenter nformat(number_d2)

	* add SD
local operation_export_sd = r(sd)
putexcel B5 = `operation_export_sd', hcenter nformat(number_d2)
scalar operation_export_sd = r(sd)

	* add residual SD
regress operation_export i.strata_final, vce(hc3)
scalar operation_export_ressd = sqrt(1 - e(r2))
local operation_export_ressd = operation_export_sd * operation_export_ressd
putexcel B6 = `operation_export_ressd', hcenter nformat(number_d2)
		
		* 1-year (only applies to export sales)
putexcel B7 = "0,80", hcenter
		
		* average 2-year autocorrelation (only applies to export sales)
putexcel B8 = "0,70", hcenter

***********************************************************************
* 	PART 2.2.:     define assumed treatment effects
***********************************************************************
	* export extensive margin
		* as percent
putexcel B10 = "0.175", hcenter
		* assumed take-up
putexcel B11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel B12 = formula(=SUM(B10*B11)), hcenter			
		* as percentage point
putexcel B13 = formula(=SUM(B12/B4)), hcenter

***********************************************************************
* 	PART 2.3:     power calculations
***********************************************************************

	* comparison of means
sampsi 0.49 0.607, n1(80) n2(80) sd1(`operation_export_sd') sd2(`operation_export_sd')
local power = r(power)
putexcel B15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.49 0.607, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd')
local power = r(power)
putexcel B16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 0.49 0.607, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel B17 = `power', hcenter nformat(number_d2)

	* Ancova 2 years before 
sampsi 0.49 0.607, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(2) post(2) r1(0.7)
local power = r(power)
putexcel B18 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 2.4:     MDE at 80% power
***********************************************************************

	*  comparison of means
sampsi 0.49 0.71, n1(80) n2(80) sd1(`operation_export_sd') sd2(`operation_export_sd')
local power = r(power)
putexcel B20 = 0.22, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 0.49 0.68, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd')
local power = r(power)
putexcel B21 = 0.18, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 0.49 0.585, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel B22 = 0.095, hcenter nformat(number_d2)

	* Ancova 5 years before 
sampsi 0.49 0.585, n1(80) n2(80) sd1(`operation_export_ressd') sd2(`operation_export_ressd') pre(2) post(2) r1(0.7)
local power = r(power)
putexcel B23 = 0.095, hcenter nformat(number_d2) border(bottom)

}


***********************************************************************
* 	PART 3:    estimate power for export sales
***********************************************************************
{
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
putexcel C10= "1.5", hcenter
		* assumed take-up
putexcel C11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel C12 = formula(=SUM(C10*C11)), hcenter			
		* as percentage point
putexcel C13 = formula(=SUM(C12/C4)), hcenter


***********************************************************************
* 	PART 3.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 4.34 5.345, n1(80) n2(80) sd1(`ihs_ca_exp2020_sd') sd2(`ihs_ca_exp2020_sd')
local power = r(power)
putexcel C15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 4.34 5.345, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd')
local power = r(power)
putexcel C16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 4.34 5.345, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel C17 = `power', hcenter nformat(number_d2)

	* Ancova 2 years before 
sampsi 4.34 5.345, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(2) post(2) r1(`correlation2')
local power = r(power)
putexcel C18 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 3.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 4.34 6.84, n1(80) n2(80) sd1(`ihs_ca_exp2020_sd') sd2(`ihs_ca_exp2020_sd')
local power = r(power)
putexcel C20 = 2.5, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 4.34 6.44, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd')
local power = r(power)
putexcel C21 = 2.1, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 4.34 5.45, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel C22 = 1.11, hcenter nformat(number_d2)

	* Ancova 2 years before 
sampsi 4.34 5.44, n1(80) n2(80) sd1(`ihs_ca_exp2020_ressd') sd2(`ihs_ca_exp2020_ressd') pre(2) post(2) r1(0.7)
local power = r(power)
putexcel C23 = 1, hcenter nformat(number_d2) border(bottom)

}

***********************************************************************
* 	PART 4:    estimate power for countries exported
***********************************************************************
{
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

	* add 1-year autocorrelation
putexcel D7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 4.2.:     define assumed treatment effects
***********************************************************************

	* extensive margin
		* as percent
putexcel D10= "0.7", hcenter
		* assumed take-up
putexcel D11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel D12 = formula(=SUM(D10*D11)), hcenter			
		* as percentage point
putexcel D13 = formula(=SUM(D12/D4)), hcenter
***********************************************************************
* 	PART 4.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means

sampsi  1.13 1.60, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd')
local power = r(power)
putexcel D15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 1.13 1.60, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd')
local power = r(power)
putexcel D16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 1.13 1.60, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel D17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 4.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 1.13 2.23, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd')
local power = r(power)
putexcel D20 = 1.1, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 1.13 2.13, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd')
local power = r(power)
putexcel D21 = 1.0, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 1.13 1.63, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel D22 = 0.50, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 5:    estimate power for log employees
***********************************************************************
{

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
		
	* add 1-year autocorrelation
putexcel E7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 5.2.:     define assumed treatment effects
***********************************************************************

	* extensive margin
		* as percent
putexcel E10= "0.3", hcenter
		* assumed take-up
putexcel E11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel E12 = formula(=SUM(E10*E11)), hcenter			
		* as percentage point
putexcel E13 = formula(=SUM(E12/E4)), hcenter
***********************************************************************
* 	PART 5.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 1.58 1.781, n1(80) n2(80) sd1(`log_employees_sd') sd2(`log_employees_sd')
local power = r(power)
putexcel E15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 1.58 1.781, n1(80) n2(80) sd1(`log_employees_ressd') sd2(`log_employees_ressd')
local power = r(power)
putexcel E16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 1.58 1.781, n1(80) n2(80) sd1(`log_employees_ressd') sd2(`log_employees_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel E17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 5.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 1.58 2.02, n1(80) n2(80) sd1(`log_employees_sd') sd2(`log_employees_sd')
local power = r(power)
putexcel E20 = 0.44, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 1.58 1.92, n1(80) n2(80) sd1(`log_employees_ressd') sd2(`log_employees_ressd')
local power = r(power)
putexcel E21 = 0.34, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 1.58 1.75, n1(80) n2(80) sd1(`log_employees_ressd') sd2(`log_employees_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel E22 = 0.17, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 6:    estimate power for Export preparation
***********************************************************************
{

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
		
	* add 1-year autocorrelation
putexcel F7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 6.2.:     define assumed treatment effects
***********************************************************************

	* extensive margin
		* as percent
putexcel F10= "0.1", hcenter
		* assumed take-up
putexcel F11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel F12 = formula(=SUM(F10*F11)), hcenter			
		* as percentage point
putexcel F13 = formula(=SUM(F12/F4)), hcenter

***********************************************************************
* 	PART 6.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi -0.0000000308 0.099, n1(80) n2(80) sd1(`exportprep_sd') sd2(`exportprep_sd')
local power = r(power)
putexcel F15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi -0.0000000308 0.099, n1(80) n2(80) sd1(`exportprep_ressd') sd2(`exportprep_ressd')
local power = r(power)
putexcel F16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi -0.0000000308 0.099, n1(80) n2(80) sd1(`exportprep_ressd') sd2(`exportprep_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel F17 = `power', hcenter nformat(number_d2)
***********************************************************************
* 	PART 6.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi -0.0000000308 0.264, n1(80) n2(80) sd1(`exportprep_sd') sd2(`exportprep_sd')
local power = r(power)
putexcel F20 = 0.265, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi -0.0000000308 0.229, n1(80) n2(80) sd1(`exportprep_ressd') sd2(`exportprep_ressd')
local power = r(power)
putexcel F21 = 0.23, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi -0.0000000308 0.114, n1(80) n2(80) sd1(`exportprep_ressd') sd2(`exportprep_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel F22 = 0.115, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 7:    estimate power for Management practices index
***********************************************************************
{
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
		
	* add 1-year autocorrelation
putexcel G7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 7.2.:     define assumed treatment effects
***********************************************************************

	* extensive margin
		* as percent
putexcel G10= "0.1", hcenter
		* assumed take-up
putexcel G11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel G12 = formula(=SUM(G10*G11)), hcenter			
		* as percentage point
putexcel G13 = formula(=SUM(G12/G4)), hcenter
***********************************************************************
* 	PART 7.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi -0.0000000593 0.099, n1(80) n2(80) sd1(`mngtvars_sd') sd2(`mngtvars_sd')
local power = r(power)
putexcel G15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi -0.0000000593 0.099, n1(80) n2(80) sd1(`mngtvars_ressd') sd2(`mngtvars_ressd')
local power = r(power)
putexcel G16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi -0.0000000593 0.099, n1(80) n2(80) sd1(`mngtvars_ressd') sd2(`mngtvars_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel G17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 7.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi -0.0000000593 0.279, n1(80) n2(80) sd1(`mngtvars_sd') sd2(`mngtvars_sd')
local power = r(power)
putexcel G20 = 0.28, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi -0.0000000593 0.259, n1(80) n2(80) sd1(`mngtvars_ressd') sd2(`mngtvars_ressd')
local power = r(power)
putexcel G21 = 0.26, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi -0.0000000593 0.129, n1(80) n2(80) sd1(`mngtvars_ressd') sd2(`mngtvars_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel G22 = 0.13, hcenter nformat(number_d2)

}
***********************************************************************
* 	PART 8:    estimate power for Marketing practices index
***********************************************************************
{

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
		
	* add 1-year autocorrelation
putexcel H7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 8.2.:     define assumed treatment effects
***********************************************************************
	* extensive margin
		* as percent
putexcel H10= "0.1", hcenter
		* assumed take-up
putexcel H11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel H12 = formula(=SUM(H10*H11)), hcenter			
		* as percentage point
putexcel H13 = formula(=SUM(H12/H4)), hcenter

***********************************************************************
* 	PART 8.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi -0.0000000419 0.099, n1(80) n2(80) sd1(`markvars_sd') sd2(`markvars_sd')
local power = r(power)
putexcel H15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi -0.0000000419 0.099, n1(80) n2(80) sd1(`markvars_ressd') sd2(`markvars_ressd')
local power = r(power)
putexcel H16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi -0.0000000419 0.099, n1(80) n2(80) sd1(`markvars_ressd') sd2(`markvars_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel H17 = `power', hcenter nformat(number_d2)
***********************************************************************
* 	PART 8.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi -0.0000000419 0.279, n1(80) n2(80) sd1(`markvars_sd') sd2(`markvars_sd')
local power = r(power)
putexcel H20 = 0.28, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi -0.0000000419 0.259, n1(80) n2(80) sd1(`markvars_ressd') sd2(`markvars_ressd')
local power = r(power)
putexcel H21 = 0.26, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi -0.0000000419 0.134, n1(80) n2(80) sd1(`markvars_ressd') sd2(`markvars_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel H22 = 0.135, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 9:    estimate power for Innovation index
***********************************************************************
{
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
		
	* add 1-year autocorrelation
putexcel I7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 9.2.:     define assumed treatment effects
***********************************************************************

	* extensive margin
		* as percent
putexcel I10= "0.13", hcenter
		* assumed take-up
putexcel I11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel I12 = formula(=SUM(I10*I11)), hcenter			
		* as percentage point
putexcel I13 = formula(=SUM(I12/I4)), hcenter

***********************************************************************
* 	PART 9.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi  0.0000000132 0.1200000132, n1(80) n2(80) sd1(`innovars_sd') sd2(`innovars_sd')
local power = r(power)
putexcel I15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.0000000132 0.1200000132, n1(80) n2(80) sd1(`innovars_ressd') sd2(`innovars_ressd')
local power = r(power)
putexcel I16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 0.0000000132 0.1200000132, n1(80) n2(80) sd1(`innovars_ressd') sd2(`innovars_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel I17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 9.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 0.0000000132 0.2000000132, n1(80) n2(80) sd1(`innovars_sd') sd2(`innovars_sd')
local power = r(power)
putexcel I20 = 0.20, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 0.0000000132 0.1850000132, n1(80) n2(80) sd1(`innovars_ressd') sd2(`innovars_ressd')
local power = r(power)
putexcel I21 = 0.185, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 0.0000000132 0.0950000132, n1(80) n2(80) sd1(`innovars_ressd') sd2(`innovars_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel I22 = 0.095, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 10:    estimate power for Gender index
***********************************************************************
{

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
		
	* add 1-year autocorrelation
putexcel J7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 10.2.:     define assumed treatment effects
***********************************************************************

	* extensive margin
		* as percent
putexcel J10= "0.1", hcenter
		* assumed take-up
putexcel J11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel J12 = formula(=SUM(J10*J11)), hcenter			
		* as percentage point
putexcel J13 = formula(=SUM(J12/J4)), hcenter

***********************************************************************
* 	PART 10.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 0.0000000379 0.1000000379, n1(80) n2(80) sd1(`gendervars_sd') sd2(`gendervars_sd')
local power = r(power)
putexcel J15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.0000000379 0.1000000379, n1(80) n2(80) sd1(`gendervars_ressd') sd2(`gendervars_ressd')
local power = r(power)
putexcel J16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 0.0000000379 0.1000000379, n1(80) n2(80) sd1(`gendervars_ressd') sd2(`gendervars_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel J17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 10.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
sampsi 0.0000000379 0.3700000379, n1(80) n2(80) sd1(`gendervars_sd') sd2(`gendervars_sd')
local power = r(power)
putexcel J20 = 0.37, hcenter nformat(number_d2)

	* after controlling for strata 
sampsi 0.0000000379 0.3400000379, n1(80) n2(80) sd1(`gendervars_ressd') sd2(`gendervars_ressd')
local power = r(power)
putexcel J21 = 0.34, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 0.0000000379 0.1750000379, n1(80) n2(80) sd1(`gendervars_ressd') sd2(`gendervars_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel J22 = 0.175, hcenter nformat(number_d2)

}