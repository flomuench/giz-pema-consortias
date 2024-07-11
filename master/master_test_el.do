***********************************************************************
* 			consortia master logical tests                           *	
***********************************************************************
*																	    
*	PURPOSE: Check that answers make logical sense			  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Load data & generate check variables
* 	2) 		Define logical tests
*	2.1) 	Networking Questions
*	2.2) 	Export Investment Questions
*	2.3)	Comptabilité / accounting questions	
*	2.4)	Number of Employees
*   3) 		Additional logical test cross-checking answers from registration & baseline	
*	3.1)	CA export	
*   4) 		large Outliers
*	5)		Check for missing values	
*	6)		Manual corrections of needs_check after Amouri Feedback 
*	7)		Export an excel sheet with needs_check variables 
*						  															      
*	Author:  Ayoub Chamakhi
*	ID variable: 	id_plateforme (example: f101)			  					  
*	Requires: consortium_int.dta 	  								  
*	Creates:  fiche_correction.xls			                          
*																	  
***********************************************************************
* 	PART 1:  Load data & generate check variables 		
***********************************************************************
use "${master_final}/consortium_final", clear

gen needs_check = 0
lab var needs_check "logical test to be checked by El Amouri"

gen questions_needing_checks  = ""
lab var questions_needing_checks "questions to be checked by El Amouri"


***********************************************************************
* 	PART 2:  Define logical tests
**********************************************************************
/* --------------------------------------------------------------------
	PART 2.1: financial cross-checking from baseline & endline
----------------------------------------------------------------------*/
*panel data to long
replace ca_2021 = ca if surveyround == 1
gen ca_exp2021 = ca_exp if surveyround == 1
replace profit_2021 = profit if surveyround == 1

*generate financial per empl
local varn ca_2021 ca_exp2021 profit_2021

foreach x of local varn { 
gen n`x' = 0
replace n`x' = . if `x' == -777
replace n`x' = . if `x' == -888
replace n`x' = . if `x' == -999
replace n`x' = `x'/employes if n`x'!= .
}

*add inflation //https://www.focus-economics.com/country-indicator/tunisia/inflation/#:~:text=Inflation%20in%20Tunisia,information%2C%20visit%20our%20dedicated%20page
replace nca_2021 = nca_2021*1.176

replace nca_exp2021 = nca_exp2021*1.176

*manual thresholds at 95% (Highest among surveyrounds)
	*turnover total
	
local new_turnover "nca nca_2024"

foreach var of local new_turnover {
	sum nca_2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) & `var' != .
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if `var' != . & surveyround == 3 & `var' > r(p95) & `var' != .
}	

	*turnover export
local new_turnoverexp "nca_exp nca_exp_2024"


foreach var of local new_turnoverexp {
	sum nca_exp2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) & `var' != .
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if `var' != . & surveyround == 3 & `var' > r(p95) & `var' != .
}	

	*profit
local new_profit "nprofit nprofit_2024"

foreach var of local new_profit {
	sum profit_2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) & `var' != .
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if `var' != . & surveyround == 3 & `var' > r(p95) & `var' != .
}	

*growth rates
gen bl_empl = employes if surveyround == 1
replace ca_exp_2021 = ca_exp if surveyround == 1

local compta_vars "ca_2021 ca_exp_2021 profit_2021 bl_empl"
sort id_plateforme surveyround

foreach var of local compta_vars {
    by id_plateforme: egen first_`var' = max(cond(!missing(`var'), `var', .))
    
    gen adjusted_`var' = first_`var'
    
    drop first_`var'
}

*add inflation
replace adjusted_ca_2021 = adjusted_ca_2021*1.176
replace adjusted_ca_exp_2021 = adjusted_ca_exp_2021*1.176

*generate growth rates
gen gr_ca2021_2024 = (ca_2024 - adjusted_ca_2021) / adjusted_ca_2021 if ca_2024 != . & surveyround == 3

gen gr_ca2021_2023 = (ca - adjusted_ca_2021) / adjusted_ca_2021 if ca != . & surveyround == 3

	*ca_exp
gen gr_caexp2021_2024 = (ca_exp_2024 - adjusted_ca_exp_2021) / adjusted_ca_exp_2021 if ca_exp_2024 != . & surveyround == 3

gen gr_caexp2021_2023 = (ca_exp - adjusted_ca_exp_2021) / adjusted_ca_exp_2021 if ca_exp != . & surveyround == 3

	*profit
gen gr_profit2021_2024 = (profit_2024 - adjusted_profit_2021) / adjusted_profit_2021 if profit_2024 != . & surveyround == 3

gen gr_profit2021_2023 = (profit - adjusted_profit_2021) / adjusted_profit_2021 if profit != . & surveyround == 3

	*employes
gen gr_empl2021_2024 = (employes - adjusted_bl_empl) / adjusted_bl_empl if employes != . & surveyround == 3

/*
sum gr_ca2021_2024 gr_ca2021_2023 gr_caexp2021_2024 gr_caexp2021_2023 gr_profit2021_2024 gr_profit2021_2023 gr_empl2021_2024 if surveyround == 3, d

                       gr_ca2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%           -1             -1
 5%    -.9957483      -.9967294
10%    -.8937075      -.9959508       Obs                  78
25%    -.6134818      -.9957483       Sum of wgt.          78

50%    -.1770902                      Mean           .9725437
                        Largest       Std. dev.       3.34369
75%     1.107365       9.629251
90%     3.251701       10.22449       Variance       11.18026
95%     9.629251       13.17234       Skewness        3.42845
99%     19.40816       19.40816       Kurtosis       16.15069

                       gr_ca2021_2023
-------------------------------------------------------------
      Percentiles      Smallest
 1%           -1             -1
 5%    -.9959508             -1
10%     -.787415      -.9967294       Obs                  79
25%    -.1496599      -.9959508       Sum of wgt.          79

50%     .8221574                      Mean           2.169327
                        Largest       Std. dev.      5.535046
75%     1.882509       10.22449
90%     5.377551       10.33787       Variance       30.63674
95%     10.22449       33.01361       Skewness       4.543058
99%     33.01361       33.01361       Kurtosis       25.22736

                      gr_caexp2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%           -1             -1
 5%           -1             -1
10%           -1             -1       Obs                  31
25%           -1             -1       Sum of wgt.          31

50%    -.8198432                      Mean           .0468342
                        Largest       Std. dev.      2.510654
75%    -.2346939        .984127
90%      .984127       3.047632       Variance       6.303384
95%     4.668934       4.668934       Skewness       3.666513
99%      11.7551        11.7551       Kurtosis       16.77452

                      gr_caexp2021_2023
-------------------------------------------------------------
      Percentiles      Smallest
 1%           -1             -1
 5%           -1             -1
10%           -1             -1       Obs                  31
25%           -1             -1       Sum of wgt.          31

50%     -.744898                      Mean           .2586257
                        Largest       Std. dev.      1.947047
75%     .8221574       2.968254
90%     2.968254       4.102041       Variance        3.79099
95%     5.073858       5.073858       Skewness       1.596964
99%     5.746054       5.746054       Kurtosis         4.3391

                     gr_profit2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -16.95745      -16.95745
 5%    -6.714286      -8.142858
10%           -4          -7.25       Obs                  77
25%    -1.166667      -6.714286       Sum of wgt.          77

50%          -.5                      Mean           1.335887
                        Largest       Std. dev.      14.63997
75%            1              7
90%            4           11.5       Variance       214.3288
95%            7       12.33333       Skewness       7.760952
99%          124            124       Kurtosis       65.74869

                     gr_profit2021_2023
-------------------------------------------------------------
      Percentiles      Smallest
 1%         -8.5           -8.5
 5%        -7.25      -7.428571
10%    -3.857143      -7.382979       Obs                  78
25%    -1.271297          -7.25       Sum of wgt.          78

50%       -.4375                      Mean           1.437764
                        Largest       Std. dev.      14.48241
75%            1              9
90%            4           11.5       Variance       209.7402
95%            9       12.33333       Skewness       7.913424
99%          124            124       Kurtosis       67.49981

                      gr_empl2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%           -1             -1
 5%         -.75           -.96
10%    -.7058824            -.9       Obs                  91
25%    -.3333333            -.8       Sum of wgt.          91

50%            0                      Mean           2.070107
                        Largest       Std. dev.      15.75413
75%           .5              4
90%     1.333333              4       Variance       248.1926
95%            4             17       Skewness       9.163689
99%        149.5          149.5       Kurtosis       86.17249

*/

*ca2024
scalar gr_ca2021_2024p95 = 9.629251

replace needs_check = 1 if gr_ca2021_2024 >= gr_ca2021_2024p95 & surveyround == 3 & gr_ca2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA 2024 est superiéur à 962,9251 %, veuillez vérifier / " if gr_ca2021_2024 >= gr_ca2021_2024p95 & surveyround == 3 & gr_ca2021_2024 != .

scalar gr_ca2021_2024p5 = -.9957483

replace needs_check = 1 if gr_ca2021_2024 <= gr_ca2021_2024p5 & surveyround == 3 & gr_ca2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA 2024 est superiéur à -99,57483 %, veuillez vérifier / " if gr_ca2021_2024 <= gr_ca2021_2024p5 & surveyround == 3 & gr_ca2021_2024 != .

*ca2023
scalar gr_ca2021_2023p95 = 10.22449 

replace needs_check = 1 if gr_ca2021_2023 >= gr_ca2021_2023p95 & surveyround == 3 & gr_ca2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA 2023 est superiéur à 1022,449  %, veuillez vérifier / " if gr_ca2021_2023 >= gr_ca2021_2023p95 & surveyround == 3 & gr_ca2021_2023 != .

scalar gr_ca2021_2023p5 = -.9959508

replace needs_check = 1 if gr_ca2021_2023 <= gr_ca2021_2023p5 & surveyround == 3 & gr_ca2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA 2023 est superiéur à -99,59508 %, veuillez vérifier / " if gr_ca2021_2023 <= gr_ca2021_2023p5 & surveyround == 3 & gr_ca2021_2023 != .

*ca_exp2024
scalar gr_caexp2021_2024p95 = 4.668934 

replace needs_check = 1 if gr_caexp2021_2024 >= gr_caexp2021_2024p95 & surveyround == 3 & gr_caexp2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA export 2024 est superiéur à 466,8934  %, veuillez vérifier / " if gr_caexp2021_2024 >= gr_caexp2021_2024p95 & surveyround == 3 & gr_caexp2021_2024 != .

scalar gr_caexp2021_2024p5 = -1

replace needs_check = 1 if gr_caexp2021_2024 <= gr_caexp2021_2024p5 & surveyround == 3 & gr_caexp2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA export 2024 est -100 %, veuillez vérifier / " if gr_caexp2021_2024 <= gr_caexp2021_2024p5 & surveyround == 3 & gr_caexp2021_2024 != .
*ca_exp2023
scalar gr_caexp2021_2023p95 = 5.073858

replace needs_check = 1 if gr_caexp2021_2023 >= gr_caexp2021_2023p95 & surveyround == 3 & gr_caexp2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA export 2023 est superiéur à 507,3858 %, veuillez vérifier / " if gr_caexp2021_2023 >= gr_caexp2021_2023p95 & surveyround == 3 & gr_caexp2021_2023 != .


scalar gr_caexp2021_2023p5 = -1

replace needs_check = 1 if gr_caexp2021_2023 <= gr_caexp2021_2023p5 & surveyround == 3 & gr_caexp2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA export 2023 est -100 %, veuillez vérifier / " if gr_caexp2021_2023 <= gr_caexp2021_2023p5 & surveyround == 3 & gr_caexp2021_2023 != .

*ca_profit2024
scalar gr_profit2021_2024p95 =  7


replace needs_check = 1 if gr_profit2021_2024 >= gr_profit2021_2024p95 & surveyround == 3 & gr_profit2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance Profit 2024 est superiéur à 700 %, veuillez vérifier / " if gr_profit2021_2024 >= gr_profit2021_2024p95 & surveyround == 3 & gr_profit2021_2024 != .

*ca_profit2023
scalar gr_profit2021_2023p95 = 9

replace needs_check = 1 if gr_profit2021_2023 >= gr_profit2021_2023p95 & surveyround == 3 & gr_profit2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance Profit 2023 est superiéur à 900 %, veuillez vérifier / " if gr_profit2021_2023 >= gr_profit2021_2023p95 & surveyround == 3 & gr_profit2021_2023 != .

*empl
scalar gr_empl2021_2024p95 = 4 

replace needs_check = 1 if gr_empl2021_2024 >= gr_empl2021_2024p95 & surveyround == 3 & gr_empl2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA est superiéur à 400 %, veuillez vérifier / " if gr_empl2021_2024 >= gr_empl2021_2024p95 & surveyround == 3 & gr_empl2021_2024 != .

/* --------------------------------------------------------------------
	PART 2.2: Comptabilité / accounting questions
----------------------------------------------------------------------*/		
/* 0 NOW SHOWS AN INTERVAL
	* turnover zero
local accountvars comp_ca2023 comp_ca2024
foreach var of local accountvars {
		* = 0
	replace needs_check = 1 if surveyround == 3 & `var' == 0 
	replace questions_needing_checks = questions_needing_checks + "`var' est rare d'être zero, êtes vous sure? / " if surveyround == 3 & `var' == 0 
	
}


	* turnover export zero even though it exports
local accountexpvars compexp_2023 compexp_2024
foreach var of local accountexpvars {
		* = 0
	replace needs_check = 1 if surveyround == 3 & `var' == 0 & export_1 == 1 & export_2 == 1
	replace questions_needing_checks = questions_needing_checks + "`var' est zero alors qu'elle exporte, êtes vous sure? / " if surveyround == 3 & `var' == 0  & export_1 == 1 & export_2 == 1
	
}	
*/

	*Company does not export but has ca export
	
replace needs_check = 1 if (ca_exp > 0 | ca_exp_2024 > 0 ) & surveyround == 3 & export_1 == 0 & export_2 == 0 & ca_exp != 666 & ca_exp != 777 & ca_exp != 888 & ca_exp != 999 & ca_exp != . & ca_exp != 1234 & ca_exp_2024 != 666 & ca_exp_2024 != 777  & ca_exp_2024 != 888  & ca_exp_2024 != 999 & ca_exp_2024 != . & ca_exp_2024 != 1234 & id_plateforme != 1157
replace questions_needing_checks = questions_needing_checks + "L'entreprise n'export pas alors qu'elle a ca export / " if (ca_exp > 0 | ca_exp_2024 > 0 ) & surveyround == 3 & export_1 == 0 & export_2 == 0 & ca_exp != 666 & ca_exp != 777 & ca_exp != 888 & ca_exp != 999 & ca_exp != . & ca_exp != 1234 & ca_exp_2024 != 666 & ca_exp_2024 != 777  & ca_exp_2024 != 888  & ca_exp_2024 != 999 & ca_exp_2024 != . & ca_exp_2024 != 1234 & id_plateforme != 1157

/*	FILTERED BY EL AMOURI
	* Profits > sales 2023

replace needs_check = 1 if surveyround == 3 & comp_benefice2023 > comp_ca2023 & comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 & comp_benefice2023 != 999 & comp_benefice2023 != 1234 & comp_benefice2023 != . ///
	& comp_benefice2023 != 0 & comp_ca2023 != 666 & comp_ca2023 != 777 & comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA 2023 / "  if surveyround == 3 & comp_benefice2023 > comp_ca2023 & comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 & 	  comp_benefice2023 != 999 & comp_benefice2023 != 1234 & comp_benefice2023 != . & comp_benefice2023 != 0 & comp_ca2023 != 666 & comp_ca2023 != 777 & comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234

	* Profits > sales 2024
	
replace needs_check = 1 if surveyround == 3 & comp_benefice2024 > comp_ca2024 & compexp_2024 != 666 & compexp_2024 != 777 & compexp_2024 != 888 & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234 & ///
	comp_benefice2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234
replace questions_needing_checks = questions_needing_checks + "Benefices sont plus élevés que CA 2024 / "  if surveyround == 3 & comp_benefice2024 > comp_ca2024 & compexp_2024 != 666 & compexp_2024 != 777 & compexp_2024 != 888 ///
	& compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234 & comp_benefice2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 0 & compexp_2024 != 1234

	* Outliers/extreme values: Very low values
		* ca2023
	
replace needs_check = 1 if surveyround == 3 & comp_ca2023 < 5000 & comp_ca2023 != 666 & comp_ca2023 != 777 & comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234
replace questions_needing_checks = questions_needing_checks + "CA 2023 moins que 5000 TND, êtes vous sure? / " if surveyround == 3 & comp_ca2023 < 5000 & comp_ca2023 != 666 & comp_ca2023 != 777 ///
	& comp_ca2023 != 888 & comp_ca2023 != 999 & comp_ca2023 != . & comp_ca2023 != 0 & comp_ca2023 != 1234

		* ca2024

replace needs_check = 1 if surveyround == 3 & comp_ca2024 < 5000 & comp_ca2024 != 666 & comp_ca2024 != 777 & comp_ca2024 != 888 & comp_ca2024 != 999 & comp_ca2024 != . & comp_ca2024 != 0 & comp_ca2024 != 1234
replace questions_needing_checks = questions_needing_checks + "CA 2024 moins que 5000 TND, êtes vous sure? / " if surveyround == 3 & comp_ca2024 < 5000 ///
	& comp_ca2024 != 666 & comp_ca2024 != 777 & comp_ca2024 != 888 & comp_ca2024 != 999 & comp_ca2024 != . & comp_ca2024 != 0 & comp_ca2024 != 1234

		* profit2023 just above zero

replace needs_check = 1 if surveyround == 3 & comp_benefice2023 < 2500 & comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 ///
	& comp_benefice2023 != 999 & comp_benefice2023 != . & comp_benefice2023 != 0 & comp_benefice2023 != 1234 
replace questions_needing_checks = questions_needing_checks + "Benefice 2023 moins que 2500 TND / " if surveyround == 3 & comp_benefice2023 < 2500 ///
	& comp_benefice2023 != 666 & comp_benefice2023 != 777 & comp_benefice2023 != 888 & comp_benefice2023 != 999 & comp_benefice2023 != . & comp_benefice2023 != 0 & comp_benefice2023 != 1234 

		* profit2024 just above zero

replace needs_check = 1 if surveyround == 3 & comp_benefice2024 < 2500 & comp_benefice2024 != 666 & comp_benefice2024 != 777 & comp_benefice2024 != 888 ///
	& comp_benefice2024 != 999 & comp_benefice2024 != . & comp_benefice2024 != 0 & comp_benefice2024 != 1234
replace questions_needing_checks = questions_needing_checks + "benefice 2024 moins que 2500 TND / " if surveyround == 3 & comp_benefice2024 < 2500 ///
	& comp_benefice2024 != 666 & comp_benefice2024 != 777 & comp_benefice2024 != 888 & comp_benefice2024 != 999 & comp_benefice2024 != . & comp_benefice2024 != 0 & comp_benefice2024 != 1234


		* profit2023 just below zero
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2023 > -2500 & comp_benefice2023 < 0  & comp_benefice2023 != . & comp_benefice2023 != 1234 & comp_benefice2023 != 0
replace questions_needing_checks = questions_needing_checks + "benefice 2023 + que -2500 TND mais - que zero / " if surveyround == 3 & comp_benefice2023 > -2500 ///
	& comp_benefice2023 < 0  & comp_benefice2023 != . & comp_benefice2023 != 1234 & comp_benefice2023 != 0

		* profit2024 just below zero
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2024 > -2500 & comp_benefice2024 < 0  & comp_benefice2024 != . & comp_benefice2024 != 1234 & comp_benefice2024 != 0
replace questions_needing_checks = questions_needing_checks + "benefice 2024 + que -2500 TND mais - que zero / " if surveyround == 3 & comp_benefice2024 > -2500 & comp_benefice2024 < 0 ///
	& comp_benefice2024 != . & comp_benefice2024 != 1234 & comp_benefice2024 != 0
*/
		*profit2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & profit > 1000000 & profit != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2023 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & profit > 1000000 & profit != . 
	
		*profit2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & profit_2024 > 1000000 & profit_2024 != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2024 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & profit_2024 > 1000000 & profit_2024 != . 

		*ca2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & ca > 2000000 & ca != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 2 millions de dinars / " if surveyround == 3 & ca > 2000000 & ca != . 
	
		*ca2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & ca_2024 > 2000000 & ca_2024 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 2 millions de dinars / " if surveyround == 3 & ca_2024 > 2000000 & ca_2024 != . 

		*ca_exp2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & ca_exp > 1500000 & ca_exp != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 1.5 millions de dinars / " if surveyround == 3 & ca_exp > 2000000 & ca_exp != . 
	
		*ca_exp2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & ca_exp_2024 > 1500000 & ca_exp_2024 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 1.5 millions de dinars / " if surveyround == 3 & ca_exp_2024 > 2000000 & ca_exp_2024 != . 


/* THERE WILL BE AN INTERVAL
		*comptability vars that should not be 1234
local not1234_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 mark_invest dig_invest"

foreach var of local not1234_vars {
	replace needs_check = 1 if `var' == 1234 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "Les intervalles utilisés `var' ne sont possible que pour le profit / " if `var' == 1234 & surveyround == 3
}
*/

/* --------------------------------------------------------------------
	PART 2.3: Networking questions
----------------------------------------------------------------------*/
*products_other
replace needs_check = 1 if net_size3 > 0 & net_services_pratiques == . & surveyround == 3 & attest == 1
replace questions_needing_checks = questions_needing_checks + "Réponses net_services manquantes alors que le nombre de contact avec d'autres entrepreneurs est > 0, veuillez vérifier. / " if net_size3 > 0 & net_services_pratiques == . & surveyround == 3 & attest == 1

replace needs_check = 1 if net_size3 > 30 & surveyround == 3 & net_size3 != .
replace questions_needing_checks = questions_needing_checks + "Nombre de discussions d'affaire avec les autres entrepreneurs est supérieur à 30, veuillez vérifier. / " if net_size3 > 30 & surveyround == 3 & net_size3 != .

replace needs_check = 1 if net_size4 > 30 & surveyround == 3 & net_size4 != .
replace questions_needing_checks = questions_needing_checks + "Nombre de discussions d'affaire avec les memebres de la famille est supérieur à 30, veuillez vérifier. / " if net_size4 > 30 & surveyround == 3 & net_size4 != .

/* --------------------------------------------------------------------
	PART 2.4: Export Questions
----------------------------------------------------------------------*/
*Clients number is too huge
replace needs_check = 1 if surveyround==3 & clients > 10000 & clients != .
replace questions_needing_checks = questions_needing_checks + "Nombre de clients international superiéur à 10000, veuillez vérifier aussi le nombre de clients SSA. / "  if surveyround==3 & clients > 10000 & clients != .

*Does export practices and activties, but no client?
local export_act "exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent ssa_action1 ssa_action2 ssa_action3 ssa_action4"
foreach var of local export_act {
	replace needs_check = 1 if surveyround == 3 & `var' == 1 & clients == 0
	replace questions_needing_checks = questions_needing_checks + "L'entreprise dit qu'elle fait `var', mais elle n'a pas de clients, veuillez vérifier. / " if surveyround == 3 & `var' == 1 & clients == 0
}

/* --------------------------------------------------------------------
	PART 2.5: Management Questions
----------------------------------------------------------------------*/	
*management 
	*follows performance indicators but says they never track it
local mana_perf "man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv"
foreach var of local mana_perf {
	replace needs_check = 1 if surveyround == 3 & `var' == 1 & man_fin_per_fre  == 0
	replace questions_needing_checks = questions_needing_checks + "L'entreprise dit qu'elle suit `var', mais elle indique qu'elle la fréquence est de jamais, veuillez vérifier. / " if surveyround == 3 & `var' == 1 & man_fin_per_fre  == 0
}

*network
replace needs_check = 1 if surveyround==3 & net_association > 10 & net_association !=.
replace questions_needing_checks = questions_needing_checks + "L'entreprise a plus de 10 contacts d'affaire, veuillez vérifier. / " if surveyround==3 & net_association > 10 & net_association !=.

*is treatment but has 0 associations
replace needs_check = 1 if surveyround==3 & take_up ==1 & net_association == 0
replace questions_needing_checks = questions_needing_checks + "Le nombre d'affiliations aux associations est de 0, alors qu'elle participe aux activités des consortiums. Veuillez vérifier. / " if surveyround==3 & take_up ==1 & net_association == 0

/* --------------------------------------------------------------------
	PART 2.6: Open-ended questions
----------------------------------------------------------------------*/
	*products_other
replace needs_check = 1 if id_plateforme == 1197 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(products_other) le nom du produit additionnel n'est pas clair (حولي و حايك) / " if id_plateforme == 1197 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1234 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(products_other) le nom du produit additionnel n'est pas clair (la franche) / " if id_plateforme == 1234 & surveyround == 3

replace needs_check = 1 if id_plateforme == 989 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(products_other) elle n'a pas donné de produit addtionnel(0) / " if id_plateforme == 989 & surveyround == 3

*inno_exampl_produit1
replace needs_check = 1 if id_plateforme == 989 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) à préciser(recrutement) / " if id_plateforme == 989 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1010 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) Ce n'est pas une innovation / " if id_plateforme == 1010 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1017 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) Ce n'est pas une innovation du produit / " if id_plateforme == 1017 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1035 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser / " if id_plateforme == 1035 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1043 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (diversité des produits , je cible le consommateur, diversification des services ) / " if id_plateforme == 1043 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1046 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (des nouvelles techniques et de nouveaux outils d'auteur dans la création de contenus) / " if id_plateforme == 1046 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1049 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) Ce n'est pas une innovation de produit(j'ai changé l'entreprise avec laquelle je travaille avec: c'était une entreprise américaine et maintenant c'est devenue une entreprise allemande.) / " if id_plateforme == 1049 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1055 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (nous avons augmenter le nombre de produits et nous avons change l'emballage) / " if id_plateforme == 1055 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1065 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) Ce n'est pas une innovation de produit ou à préciser (marketing) / " if id_plateforme == 1065 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1098 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (nous allons introduire d'autres services innovants à la fin de l'année 2024) / " if id_plateforme == 1098 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1112 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (matériaux de construction) / " if id_plateforme == 1112 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1118 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (développement en mode de paiement ) / " if id_plateforme == 1118 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1128 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (création et innovation de produit changer la formation des produit) / " if id_plateforme == 1128 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1128 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (d'autres produits et services digital) / " if id_plateforme == 1128 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1170 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (de nouvelles solutions digitales, on a rajouté dans la quantité et de nouveaux partenariats en Afrique )/ " if id_plateforme == 1170 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1178 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) Ce n'est pas une innovation de produit ou à préciser (introduire à d'autres marchés - augmenter le chiffre d'affaire - export) / " if id_plateforme == 1178 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1190 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (changement des types de produits élargir la gamme des produits) / " if id_plateforme == 1190 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1191 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) Ce n'est pas une innovation de produit ou à préciser (augmenation de ca ) / " if id_plateforme == 1191 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1210 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (sport et enfant) / " if id_plateforme == 1210 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1224 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (développement des nouveaux produit) / " if id_plateforme == 1224 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1231 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) Pas compris, à expliquer (hasanna fil masna3 w wafarna l9loub ) / " if id_plateforme == 1231 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1234 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit1) À préciser (des nouvelles création des produits ) / " if id_plateforme == 1234 & surveyround == 3

*inno_exampl_produit2
replace needs_check = 1 if id_plateforme == 999 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (nouvelle services de comptabilité carbone( déclaration de matériel ) / " if id_plateforme == 999 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1019 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (rakzou aala les services professionnels) / " if id_plateforme == 1019 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1035 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (le conseil) / " if id_plateforme == 1035 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1046 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (ils proposent des services sur mesure ) / " if id_plateforme == 1046 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1112 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (des produit agro alimentaires ) / " if id_plateforme == 1112 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1118 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) Ce n'est pas une innovation de produit ou à préciser (déloppement fel export) / " if id_plateforme == 1118 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1124 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) Pas compris, à expliquer (produit en gré) / " if id_plateforme == 1124 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1128 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (des nouvelles forme de produit) / " if id_plateforme == 1128 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1153 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (le marketing digital) / " if id_plateforme == 1153 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1170 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (les solutions degitales) / " if id_plateforme == 1170 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1176 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (nouvelle conception et liaison intelligente) / " if id_plateforme == 1176 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1210 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (service dans le domaine de sport) / " if id_plateforme == 1210 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1222 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (le conseil, audit ) / " if id_plateforme == 1222 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1248 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_exampl_produit2) À préciser (mini chaine dolive) / " if id_plateforme == 1248 & surveyround == 3

*inno_proc_other
replace needs_check = 1 if id_plateforme == 988 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_proc_other) À préciser quel type d'innovation (l'export da5elto, service formation ) / " if id_plateforme == 988 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1087 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_proc_other) À préciser quel type d'innovation (les competences de lequippe et recrutement jdod) / " if id_plateforme == 1087 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1117 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_proc_other) À préciser quel type d'innovation, ce n'est pas clair (genre) / " if id_plateforme == 1117 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1118 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_proc_other) À préciser quel type d'innovation (informations , technique de commmunication avec le client) / " if id_plateforme == 1118 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1124 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_proc_other) Ce n'est pas une innovation (l' expot) / " if id_plateforme == 1124 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1135 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_proc_other) Ce n'est pas une innovation (étude de marché à l'etranger) / " if id_plateforme == 1135 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1176 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_proc_other) Ce n'est pas une innovation (zedou enfathou ala marchés international) / " if id_plateforme == 1176 & surveyround == 3

*inno_mot_other
replace needs_check = 1 if id_plateforme == 986 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_mot_other) À préciser la source de l'innovation (à travers les besoins) / " if id_plateforme == 986 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1065 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_mot_other) À préciser la source de l'innovation (selon les besoins) / " if id_plateforme == 1065 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1081 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_mot_other) À préciser la source de l'innovation (mil 5edma) / " if id_plateforme == 1081 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1125 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_mot_other) Il y a une innovation et à cliquer sur d'autres sources d'innovation: pourquoi ce commentaire ? (non concernné) / " if id_plateforme == 1125 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1186 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_mot_other) La source d'innovation n'est pas claire(3d de bouzard) / " if id_plateforme == 1186 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1215 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(inno_mot_other) À préciser la source de l'innovation (recherche,) / " if id_plateforme == 1215 & surveyround == 3

*export_other
replace needs_check = 1 if id_plateforme == 1054 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(export_other) La raison pour laquelle elle n'exporte pas n'est pas claire (fama des opportunités metaa exportation ama tkmelech l'operation ) / " if id_plateforme == 1054 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1083 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(export_other) La raison pour laquelle elle n'exporte pas n'est pas claire (parce quelle nexiste plus) / " if id_plateforme == 1083 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1222 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(export_other) La raison pour laquelle elle n'exporte pas n'est pas claire (prospection) / " if id_plateforme == 1222 & surveyround == 3

*man_sources_other
replace needs_check = 1 if id_plateforme == 996 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(man_sources_other) À préciser la source d'apprentissage des nouvelles stratégies(des structure de accompangement) / " if id_plateforme == 996 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1068 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(man_sources_other) À préciser la source d'apprentissage des nouvelles stratégies (organisime internationale) / " if id_plateforme == 1068 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1151 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(man_sources_other) La source d'apprentissage des nouvelles stratégies n'est pas claire(agence de communication heya teb3a proggrame dream for use gg4 youth) / " if id_plateforme == 1151 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1176 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(man_sources_other) À préciser la source d'apprentissage des nouvelles stratégies (a travers des recherches) / " if id_plateforme == 1176 & surveyround == 3

*int_ben
replace needs_check = 1 if id_plateforme == 1068 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(int_ben2) À préciser les bénéfices de la participation au consortium(tet3alem barcha hajet fe les techniques) / " if id_plateforme == 1068 & surveyround == 3

replace needs_check = 1 if id_plateforme == 1135 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(int_ben2) À préciser les bénéfices de la participation au consortium(complémentarité) / " if id_plateforme == 1135 & surveyround == 3

*int_other
replace needs_check = 1 if id_plateforme == 1028 & surveyround == 3
replace questions_needing_checks = questions_needing_checks + "(int_other) Elle n'a pas donné de raison pour sa non-participation au consortium(————————) / " if id_plateforme == 1028 & surveyround == 3


***********************************************************************
* 	Part 5: Add erroneous matricule fiscales
***********************************************************************
*use regex to check that matricule fiscale starts with 7 numbers followed by a letter
	*mistake in matricule fiscale
*manually adding matricules that conform with regex but are wrong anyways

*replace needs_check = 1 if id_plateforme == 1083
*replace questions_needing_checks = questions_needing_checks + "matricule fiscale tjrs. faux. Appeler pour comprendre le problème." if id_plateforme == 1083 & surveyround == 2

***********************************************************************
* 	PART 6:  Remove firms from needs_check in case calling them again did not solve the issue		
***********************************************************************

***********************************************************************
* 	PART 7: Variable has been tagged as "needs_check" = 888, 777 or .
***********************************************************************
/*
local test_vars "employes dig_empl mark_invest dig_invest comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local test_vars {
	replace needs_check = 1 if `var' == 888 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "`var' = 888, êtes vous sure? / " if `var' == 888 & surveyround == 3
	replace needs_check = 1 if `var' == 777 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "`var' = 777, êtes vous sure? / " if `var' == 777 & surveyround == 3
	replace needs_check = 1 if `var' == 999 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "`var' = 999, êtes vous sure? / " if `var' == 999 & surveyround == 3
	replace needs_check = 1 if `var' == . & surveyround == 3 & exporter == 1
	replace questions_needing_checks = questions_needing_checks + "`var' = missing, êtes vous sure? / " if `var' == . & surveyround == 3 & exporter == 1
}
*/

*tackling problematique answer codes
		*666
local compta_vars "ca ca_2024 ca_exp ca_exp_2024 profit profit_2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 666
	replace questions_needing_checks = questions_needing_checks + "`var' est 666, il faut rappeler la personne responsable de la comptabilité. / " if surveyround == 3 & `var' == 666
	
}
		*777
local compta_vars "ca ca_2024 ca_exp ca_exp_2024 profit profit_2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 777
	replace questions_needing_checks = questions_needing_checks + "`var' est 777, Il faut réécouter l'appel / " if surveyround == 3 & `var' == 777
	
}

***********************************************************************
* 	PART 8:  Manually cancel needs_check if fixed	
***********************************************************************
replace needs_check = 0 if id_plateforme == 1026 // large outlier firm, comptability should be fine.
***********************************************************************
* 	PART 9:  Export an excel sheet with needs_check variables  			
***********************************************************************
*re-merge additional contact information to dataset (?)
/*
consortia: merge m:1 id_plateforme using  "${ml_raw}/consortia_ml_pii" 
keep if _merge==3 & surveyround == 2
e-commerce: merge 1:1 id_plateforme using "${consortia_master}/add_contact_data", generate(_merge_cd)
*/

preserve
			* generate empty variable for survey institute comments/corrections
gen commentaires_elamouri = ""

			* keep order stable
sort id_plateforme, stable

			* adjust needs check to panel structure (same value for each surveyround)
				* such that when all values for each firms are kepts dropping those firms
					* that do not need checking
						* 1: needs_check
egen keep_check = max(needs_check), by(id_plateforme)
drop needs_check
rename keep_check needs_check
keep if needs_check > 0 // drop firms that do not need check

						* 2: questions needing check
egen occurence = count(id_plateforme), by(id_plateforme)
drop if occurence < 2 // drop firms that have not yet responded to midline 
drop occurence

			* export excel file. manually add variables listed in questions_needing_check
				* group variables into lists (locals) to facilitate overview
local order_vars "id_plateforme surveyround take_up needs_check attest survey_phone treatment commentaires_elamouri questions_needing_checks"
local accounting_vars "`order_vars' adjusted_bl_empl employes car_empl1 gr_empl2021_2024 adjusted_ca_2021 ca gr_ca2021_2023 adjusted_ca_2021 ca_2024 gr_ca2021_2024 export_3 adjusted_ca_exp_2021 ca_exp gr_ca2021_2023 adjusted_ca_exp_2021 ca_exp_2024 gr_caexp2021_2024 adjusted_profit_2021 profit gr_profit2021_2023 adjusted_profit_2021 profit_2024 gr_profit2021_2024"
local networking_vars "`accounting_vars' net_size3 net_size4 net_association net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre"
local export_vars "`networking_vars' clients exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent ssa_action1 ssa_action2 ssa_action3 ssa_action4"
local management_vars "`export_vars' man_fin_per_fre man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv"
local openended_vars "`management_vars' products_other inno_exampl_produit1 inno_exampl_produit2 inno_proc_other inno_mot_other export_other man_sources_other int_ben2 int_other"
				
* Export to Excel
export excel `openended_vars' using "${el_checks}/fiche_correction.xlsx" ///
   if surveyround == 3 & attest == 1, sheetreplace firstrow(var) datestring("%-td")

restore
