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
*				Part 10: estimate power for gender index
*											  
*	Author:  	Florian Münch
*	ID variable: id_plateforme		  					  
*	Requires:  	 consortium_raw									  
*	Creates:     	-

***********************************************************************
* 	PART 1:    set the stage	  
***********************************************************************
use "${master_final}/consortium_final", clear

	* set folder path 
cd "$master_power"

	* create excel document
putexcel set power_consortia, replace

	* define table title
{
putexcel A1 = "Power calculations", bold border(bottom) left
	
	* create top border for variable names
putexcel A2:H2 = "", border(top)
	
	* define column headings
putexcel A2 = "", border(bottom) hcenter
putexcel B2 = "Exported", border(bottom) hcenter
putexcel C2 = "Export sales", border(bottom) hcenter
putexcel D2 = "Countries exported", border(bottom) hcenter
putexcel E2 = "Employees", border(bottom) hcenter
putexcel F2 = "Export readiness index", border(bottom) hcenter
putexcel G2 = "Management practices index", border(bottom) hcenter
putexcel H2 = "Gender index", border(bottom) hcenter
 
 
* define first column
putexcel A3 = "A. Parameters from baseline data", italic left

*define row headings
putexcel A4 = "Baseline mean", hcenter
putexcel A5 = "Baseline SD", hcenter
putexcel A6 = "Residual SD", hcenter
putexcel A7 = "1-year autocorrelation", hcenter
putexcel A10 = "B. Assumed treatment effect (abs. values)", italic left
putexcel A11 = "Assumed take-up", hcenter
putexcel A12 = "take-up adjusted treatment effect", hcenter
putexcel A13 = "as percent change in mean", hcenter
putexcel A14 = "C. Power of take-up adjusted treatment effect", italic left
putexcel A15 = "comparison of means", hcenter
putexcel A16 = "after controll for strata", hcenter
putexcel A17 = "Ancova 1-year before", hcenter
putexcel A19 = "D. MDE at 80% power and 67% take up (compare with assumed treatment effect)", italic left
putexcel A20 = "comparison of means", hcenter
putexcel A21 = "after controll for strata", hcenter
putexcel A22 = "Ancova 1-year before", hcenter
putexcel A23 = "Notes:"
putexcel A24 = "n.a. denotes not available."
putexcel A25 = "MDE denotes minimum detectable effect size."
putexcel A26 = "Residual SD is standard deviation after controlling for strata fixed effects."
putexcel A27 = "One-and two-year autocorrelation come frome self-reported registration data."

}

***********************************************************************
* 	PART 2:    estimate power for export at all
***********************************************************************
{
***********************************************************************
* 	PART 2.1:     get all the relevant baseline parameters
***********************************************************************
	* add mean
sum exported if surveyround == 1
local exported_mean = r(mean)
putexcel B4 = `exported_mean', hcenter nformat(number_d2)

	* add SD
local exported_sd = r(sd)
putexcel B5 = `exported_sd', hcenter nformat(number_d2)
scalar exported_sd = r(sd)

	* add residual SD
regress exported i.strata_final if surveyround == 1, vce(hc3)
scalar exported_ressd = sqrt(1 - e(r2))
local exported_ressd = exported_sd * exported_ressd
putexcel B6 = `exported_ressd', hcenter nformat(number_d2)
		
		* 1-year (only applies to export sales)
cor exported_2020 exported_2019 if surveyround == 1
scalar exp_rho1 = r(rho)
local exp_rho1 = r(rho)
putexcel B7 = exp_rho1, hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 2.2.:     define assumed treatment effects
***********************************************************************
		* absolute change
putexcel B10 = "0.3", hcenter
		* assumed take-up
putexcel B11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel B12 = formula(=SUM(B10*B11)), hcenter			
		* as percentage point
putexcel B13 = "47%", hcenter

***********************************************************************
* 	PART 2.3:     power calculations
***********************************************************************
	* comparison of means
sampsi 0.41 0.61, n1(80) n2(80) sd1(`exported_sd') sd2(`exported_sd')
local power = r(power)
putexcel B15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.41 0.61, n1(80) n2(80) sd1(`exported_ressd') sd2(`exported_ressd')
local power = r(power)
putexcel B16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 0.41 0.61, n1(80) n2(80) sd1(`exported_ressd') sd2(`exported_ressd') pre(1) post(2) r1(`exp_rho1')
local power = r(power)
putexcel B17 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 2.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
power twomeans 0.41, n1(80) n2(80) sd1(`exported_sd') sd2(`exported_sd') power(.8)
local mde = r(diff)
putexcel B20 = `mde', hcenter nformat(number_d2)

	* after controlling for strata 
power twomeans 0.41, n1(80) n2(80) sd1(`exported_ressd') sd2(`exported_ressd') power(.8)
local mde = r(diff)
putexcel B21 = `mde', hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 0.41 0.6, n1(80) n2(80) sd1(`exported_ressd') sd2(`exported_ressd') pre(1) post(2) r1(0.8)
putexcel B22 = 0.19, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 3:    estimate power for export sales
***********************************************************************
{
***********************************************************************
* 	PART 3.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum ihs_ca_exp_w99 if surveyround == 1
local ihs_ca_exp_w99_mean = r(mean)
putexcel C4 = `ihs_ca_exp_w99_mean', hcenter nformat(number_d2)

	* add SD
local ihs_ca_exp_w99_sd = r(sd)
putexcel C5 = `ihs_ca_exp_w99_sd', hcenter nformat(number_d2)
scalar ihs_ca_exp_w99_sd = r(sd)

	* add residual SD
regress ihs_ca_exp_w99 i.strata_final if surveyround == 1, vce(hc3)
scalar ihs_ca_exp_w99_ressd = sqrt(1 - e(r2))
local ihs_ca_exp_w99_ressd = ihs_ca_exp_w99_sd * ihs_ca_exp_w99_ressd
putexcel C6 = `ihs_ca_exp_w99_ressd', hcenter nformat(number_d2)
		
		* 1-year (only applies to export sales)
corr ihs_ca_exp_w99 ihs_ca_exp2020_w99 if surveyround == 1
local correlation1 = r(rho)
putexcel C7 = `correlation1', hcenter nformat(number_d2)
		

***********************************************************************
* 	PART 3.2.:     define assumed treatment effects
***********************************************************************
		* absolute value
putexcel C10= "35.700", hcenter
		* assumed take-up
putexcel C11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel C12 = formula(=SUM(C10*C11)), hcenter			
		* as percent change
putexcel C13 = "20%", hcenter


***********************************************************************
* 	PART 3.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 4.62 4.82, n1(80) n2(80) sd1(`ihs_ca_exp_w99_sd') sd2(`ihs_ca_exp_w99_sd')
local power = r(power)
putexcel C15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 4.62 4.82, n1(80) n2(80) sd1(`ihs_ca_exp_w99_ressd') sd2(`ihs_ca_exp_w99_ressd')
local power = r(power)
putexcel C16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 4.62 4.82, n1(80) n2(80) sd1(`ihs_ca_exp_w99_ressd') sd2(`ihs_ca_exp_w99_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel C17 = `power', hcenter nformat(number_d2)


***********************************************************************
* 	PART 3.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
power twomeans 4.62, n1(80) n2(80) sd1(`ihs_ca_exp_w99_sd') sd2(`ihs_ca_exp_w99_sd') power(.8)
local mde = r(diff)
putexcel C20 = `mde', hcenter nformat(number_d2)

	* after controlling for strata 
power twomeans 4.62, n1(80) n2(80) sd1(`ihs_ca_exp_w99_ressd') sd2(`ihs_ca_exp_w99_ressd') power(.8)
local mde = r(diff)
putexcel C21 = `mde', hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 4.62 4.85, n1(80) n2(80) sd1(`ihs_ca_exp_w99_ressd') sd2(`ihs_ca_exp_w99_ressd') pre(1) post(2) r1(`correlation1')
putexcel C22 = 0.23, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 4:    estimate power for countries exported
***********************************************************************
{
***********************************************************************
* 	PART 4.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum exp_pays if surveyround == 1
local exp_pays_mean = r(mean)
putexcel D4 = `exp_pays_mean', hcenter nformat(number_d2)

	* add SD
local exp_pays_sd = r(sd)
putexcel D5 = `exp_pays_sd', hcenter nformat(number_d2)
scalar exp_pays_sd = r(sd)

	* add residual SD
regress exp_pays i.strata_final if surveyround == 1, vce(hc3)
scalar exp_pays_ressd = sqrt(1 - e(r2))
local exp_pays_ressd = exp_pays_sd * exp_pays_ressd
putexcel D6 = `exp_pays_ressd', hcenter nformat(number_d2)

	* add 1-year autocorrelation
putexcel D7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 4.2.:     define assumed treatment effects
***********************************************************************
		* absolute number
putexcel D10= "1", hcenter
		* assumed take-up
putexcel D11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel D12 = formula(=SUM(D10*D11)), hcenter			
		* in percent
putexcel D13 = "52%", hcenter

***********************************************************************
* 	PART 4.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means

sampsi  1.13 1.8, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd')
local power = r(power)
putexcel D15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 1.13 1.8, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd')
local power = r(power)
putexcel D16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 1.13 1.8, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel D17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 4.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
power twomeans 1.13, n1(80) n2(80) sd1(`exp_pays_sd') sd2(`exp_pays_sd') power(.8)
local mde = r(diff)
putexcel D20 = `mde', hcenter nformat(number_d2)

	* after controlling for strata 
power twomeans 1.13, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd') power(.8)
local mde = r(diff)
putexcel D21 = `mde', hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 1.13 1.63, n1(80) n2(80) sd1(`exp_pays_ressd') sd2(`exp_pays_ressd') pre(1) post(2) r1(0.8)
putexcel D22 = 0.50, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 5:    estimate power for employees
***********************************************************************
{

***********************************************************************
* 	PART 5.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum ihs_employes_w99 if surveyround == 1
local ihs_employes_w99_mean = r(mean)
putexcel E4 = `ihs_employes_w99_mean', hcenter nformat(number_d2)

	* add SD
local ihs_employes_w99_sd = r(sd)
putexcel E5 = `ihs_employes_w99_sd', hcenter nformat(number_d2)
scalar ihs_employes_w99_sd = r(sd)

	* add residual SD
regress ihs_employes_w99 i.strata_final if surveyround == 1, vce(hc3)
scalar ihs_employes_w99_ressd = sqrt(1 - e(r2))
local ihs_employes_w99_ressd = ihs_employes_w99_sd * ihs_employes_w99_ressd
putexcel E6 = `ihs_employes_w99_ressd', hcenter nformat(number_d2)
		
	* add 1-year autocorrelation
putexcel E7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 5.2.:     define assumed treatment effects
***********************************************************************
* assume each firm that takes up consortium 
		* absolute number 
putexcel E10= "3", hcenter
		* assumed take-up
putexcel E11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel E12 = formula(=SUM(E10*E11)), hcenter			
		* as percentage point
putexcel E13 = "17%", hcenter

***********************************************************************
* 	PART 5.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 2.37 2.47, n1(80) n2(80) sd1(`ihs_employes_w99_sd') sd2(`ihs_employes_w99_sd')
local power = r(power)
putexcel E15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 1.58 1.781, n1(80) n2(80) sd1(`ihs_employes_w99_ressd') sd2(`ihs_employes_w99_ressd')
local power = r(power)
putexcel E16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 1.58 1.781, n1(80) n2(80) sd1(`ihs_employes_w99_ressd') sd2(`ihs_employes_w99_ressd') pre(1) post(2) r1(`correlation1')
local power = r(power)
putexcel E17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 5.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
power twomeans 1.13, n1(80) n2(80) sd1(`ihs_employes_w99_sd') sd2(`ihs_employes_w99_sd') power(.8)
local mde = r(diff)
putexcel E20 = 0.44, hcenter nformat(number_d2)

	* after controlling for strata 
power twomeans 1.13, n1(80) n2(80) sd1(`ihs_employes_w99_ressd') sd2(`ihs_employes_w99_ressd') power(.8)
local mde = r(diff)
putexcel E21 = 0.34, hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 1.58 1.75, n1(80) n2(80) sd1(`ihs_employes_w99_ressd') sd2(`ihs_employes_w99_ressd') pre(1) post(2) r1(0.8)
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
sum eri if surveyround == 1
local eri_mean = r(mean)
putexcel F4 = `eri_mean', hcenter nformat(number_d2)

	* add SD
local eri_sd = r(sd)
putexcel F5 = `eri_sd', hcenter nformat(number_d2)
scalar eri_sd = r(sd)

	* add residual SD
regress eri i.strata_final if surveyround == 1, vce(hc3)
scalar eri_ressd = sqrt(1 - e(r2))
local eri_ressd = eri_sd * eri_ressd
putexcel F6 = `eri_ressd', hcenter nformat(number_d2)
		
	* add 1-year autocorrelation
putexcel F7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 6.2.:     define assumed treatment effects
***********************************************************************
		* number of points. BL mean = 3.98.
putexcel F10= "1", hcenter
		* assumed take-up
putexcel F11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel F12 = formula(=SUM(F10*F11)), hcenter			
		* as percent in mean
putexcel F13 = "16.75%", hcenter

* to find out what 1+ eri_points means in terms of z-score/index
sum eri if surveyround == 1 & eri_points == 4 // m = .21
sum eri if surveyround == 1 & eri_points == 5 // m = .46 --> d = .25

***********************************************************************
* 	PART 6.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi .39 .54, n1(80) n2(80) sd1(`eri_sd') sd2(`eri_sd')
local power = r(power)
putexcel F15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi .39 .54, n1(80) n2(80) sd1(`eri_ressd') sd2(`eri_ressd')
local power = r(power)
putexcel F16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi .39 .54, n1(80) n2(80) sd1(`eri_ressd') sd2(`eri_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel F17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 6.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
power twomeans .39, n1(80) n2(80) sd1(`eri_sd') sd2(`eri_sd') power(.8)
local mde = r(diff)
putexcel F20 = `mde', hcenter nformat(number_d2)

	* after controlling for strata 
power twomeans .39, n1(80) n2(80) sd1(`eri_ressd') sd2(`eri_ressd') power(.8)
local mde = r(diff)
putexcel F21 = `mde', hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi .39 .59, n1(80) n2(80) sd1(`eri_ressd') sd2(`eri_ressd') pre(1) post(2) r1(0.8)
putexcel F22 = 0.2, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 7:    estimate power for Management practices index
***********************************************************************
{
***********************************************************************
* 	PART 7.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum mpi
local mpi_mean = r(mean)
putexcel G4 = `mpi_mean', hcenter nformat(number_d2)

	* add SD
local mpi_sd = r(sd)
putexcel G5 = `mpi_sd', hcenter nformat(number_d2)
scalar mpi_sd = r(sd)

	* add residual SD
regress mpi i.strata_final, vce(hc3)
scalar mpi_ressd = sqrt(1 - e(r2))
local mpi_ressd = mpi_sd * mpi_ressd
putexcel G6 = `mpi_ressd', hcenter nformat(number_d2)
		
	* add 1-year autocorrelation
putexcel G7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 7.2.:     define assumed treatment effects
***********************************************************************
		* absolute points
putexcel G10= "1", hcenter
		* assumed take-up
putexcel G11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel G12 = formula(=SUM(G10*G11)), hcenter			
		* as percent change in terms of mean
putexcel G13 = "9%", hcenter

* to find out what 1+ eri_points means in terms of z-score/index
sum mpi if surveyround == 1 & mpi_points == 7 // m = -.17
sum mpi if surveyround == 1 & mpi_points == 8 // m = -.04 --> d = .13

***********************************************************************
* 	PART 7.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi .03 .16, n1(80) n2(80) sd1(`mpi_sd') sd2(`mpi_sd')
local power = r(power)
putexcel G15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi .03 .16, n1(80) n2(80) sd1(`mpi_ressd') sd2(`mpi_ressd')
local power = r(power)
putexcel G16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi .03 .16, n1(80) n2(80) sd1(`mpi_ressd') sd2(`mpi_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel G17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 7.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
power twomeans .03, n1(80) n2(80) sd1(`mpi_sd') sd2(`mpi_sd') power(.8)
local mde = r(diff)
putexcel G20 = `mde', hcenter nformat(number_d2)

	* after controlling for strata 
power twomeans .03, n1(80) n2(80) sd1(`mpi_ressd') sd2(`mpi_ressd') power(.8)
local mde = r(diff)
putexcel G21 = `mde', hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi .03 0.11, n1(80) n2(80) sd1(`mpi_ressd') sd2(`mpi_ressd') pre(1) post(2) r1(0.8)
putexcel G22 = 0.08, hcenter nformat(number_d2)

}

***********************************************************************
* 	PART 8:    estimate power for Gender index
***********************************************************************
{

***********************************************************************
* 	PART 10.1:     get all the relevant baseline parameters
***********************************************************************		
	* add mean
sum genderi
local genderi_mean = r(mean)
putexcel H4 = `genderi_mean', hcenter nformat(number_d2)

	* add SD
local genderi_sd = r(sd)
putexcel H5 = `genderi_sd', hcenter nformat(number_d2)
scalar genderi_sd = r(sd)

	* add residual SD
regress genderi i.strata_final, vce(hc3)
scalar genderi_ressd = sqrt(1 - e(r2))
local genderi_ressd = genderi_sd * genderi_ressd
putexcel H6 = `genderi_ressd', hcenter nformat(number_d2)
		
	* add 1-year autocorrelation
putexcel H7 = 0.8, hcenter nformat(number_d2)

***********************************************************************
* 	PART 10.2.:     define assumed treatment effects
***********************************************************************
		* absolute points
putexcel H10= "4.5", hcenter
		* assumed take-up
putexcel H11 = "0.67", hcenter	
		* take-up adjusted treatment effect
putexcel H12 = formula(=SUM(H10*H11)), hcenter			
		* as percentage point
putexcel H13 = "10%", hcenter

* to find out what 4.5+ (.75 point per question) eri_points means in terms of z-score/index
sum genderi if surveyround == 1 & genderi_points == 30 // m = .18
sum genderi if surveyround == 1 & genderi_points == 32 // m = .35 --> d = .17

***********************************************************************
* 	PART 10.3:     power calculations
***********************************************************************
* we assume attrition = 0.1 (hence control group goes from 89 to 80, treatment group 87 to 80)
	* comparison of means
sampsi 0.04 0.21, n1(80) n2(80) sd1(`genderi_sd') sd2(`genderi_sd')
local power = r(power)
putexcel H15 = `power', hcenter nformat(number_d2)

	* after controlling for strata_final --> add
sampsi 0.04 0.21, n1(80) n2(80) sd1(`genderi_ressd') sd2(`genderi_ressd')
local power = r(power)
putexcel H16 = `power', hcenter nformat(number_d2)

	* Ancova 1 year before
sampsi 0.04 0.21, n1(80) n2(80) sd1(`genderi_ressd') sd2(`genderi_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel H17 = `power', hcenter nformat(number_d2)

***********************************************************************
* 	PART 10.4:     MDE at 80% power
***********************************************************************
	*  comparison of means
power twomeans 0.04, n1(80) n2(80) sd1(`genderi_sd') sd2(`genderi_sd') power(.8)
local mde = r(diff)
putexcel H20 = `mde', hcenter nformat(number_d2)

	* after controlling for strata 
power twomeans 0.04, n1(80) n2(80) sd1(`genderi_ressd') sd2(`genderi_ressd') power(.8)
local mde = r(diff)
putexcel H21 = `mde', hcenter nformat(number_d2)

	* Ancova 1-year before
sampsi 0.04 0.20, n1(80) n2(80) sd1(`genderi_ressd') sd2(`genderi_ressd') pre(1) post(2) r1(0.8)
local power = r(power)
putexcel H22 = 0.16, hcenter nformat(number_d2)

}


