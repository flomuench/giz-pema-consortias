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
	PART 2.1: Export Questions
----------------------------------------------------------------------*/
*Clients number is too huge
replace needs_check = 1 if surveyround==3 & clients > 10000 & clients != .
replace questions_needing_checks = questions_needing_checks + "Nombre de clients international superiéur à 10000, veuillez vérifier aussi le nombre de clients SSA. / "  if surveyround==3 & clients > 10000 & clients != .

*Does export practices and activties, but no client?
local export_act "exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_norme exp_pra_vent ssa_action1 ssa_action2 ssa_action3 ssa_action4"
foreach var of local export_act {
	replace needs_check = 1 if surveyround == 3 & `var' == 1 & clients == 0
	replace questions_needing_checks = questions_needing_checks + "L'entreprise dit qu'elle fait `var', mais elle n'a pas de clients, veuillez vérifier. / " if surveyround == 3 & `var' == 1 & clients == 0
}

/* --------------------------------------------------------------------
	PART 2.2: Management Questions
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
	PART 2.3: Comptabilité / accounting questions
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
	
replace needs_check = 1 if (compexp_2023 > 0 | compexp_2024 > 0 ) & surveyround == 3 & export_1 == 0 & export_2 == 0 & compexp_2023 != 666 & compexp_2023 != 777 & compexp_2023 != 888 & compexp_2023 != 999 & compexp_2023 != . & compexp_2023 != 1234 & compexp_2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 1234 & id_plateforme != 1157
replace questions_needing_checks = questions_needing_checks + "L'entreprise n'export pas alors qu'elle a ca export / " if (compexp_2023 > 0 | compexp_2024 > 0 ) & surveyround == 3 & export_1 == 0 & export_2 == 0 & compexp_2023 != 666 & compexp_2023 != 777 & compexp_2023 != 888 & compexp_2023 != 999 & compexp_2023 != . & compexp_2023 != 1234 & compexp_2024 != 666 & compexp_2024 != 777  & compexp_2024 != 888  & compexp_2024 != 999 & compexp_2024 != . & compexp_2024 != 1234 & id_plateforme != 1157

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
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2023 > 1000000 & comp_benefice2023 != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2023 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & comp_benefice2023 > 1000000 & comp_benefice2023 != . 
	
		*profit2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_benefice2024 > 1000000 & comp_benefice2024 != . 
replace questions_needing_checks = questions_needing_checks + "Profit 2024 trop grand, supérieur à 1 millions de dinars / " if surveyround == 3 & comp_benefice2024 > 1000000 & comp_benefice2024 != . 

		*ca2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_ca2023 > 2000000 & comp_ca2023 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 2 millions de dinars / " if surveyround == 3 & comp_ca2023 > 2000000 & comp_ca2023 != . 
	
		*ca2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_ca2024 > 2000000 & comp_ca2024 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 2 millions de dinars / " if surveyround == 3 & comp_ca2024 > 2000000 & comp_ca2024 != . 

		*ca_exp2023 Very big values
				
replace needs_check = 1 if surveyround == 3 & compexp_2023 > 1500000 & compexp_2023 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 1.5 millions de dinars / " if surveyround == 3 & compexp_2023 > 2000000 & compexp_2023 != . 
	
		*ca_exp2024 Very big values
				
replace needs_check = 1 if surveyround == 3 & comp_ca2024 > 1500000 & comp_ca2024 != . 
replace questions_needing_checks = questions_needing_checks + "Chiffre d'affaire 2023 trop grand, supérieur à 1.5 millions de dinars / " if surveyround == 3 & comp_ca2024 > 2000000 & comp_ca2024 != . 


/* THERE WILL BE AN INTERVAL
		*comptability vars that should not be 1234
local not1234_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 mark_invest dig_invest"

foreach var of local not1234_vars {
	replace needs_check = 1 if `var' == 1234 & surveyround == 3
	replace questions_needing_checks = questions_needing_checks + "Les intervalles utilisés `var' ne sont possible que pour le profit / " if `var' == 1234 & surveyround == 3
}
*/

/* --------------------------------------------------------------------
	PART 2.4: Networking questions
----------------------------------------------------------------------*/

replace needs_check = 1 if net_size3 > 0 & net_services_pratiques == . & surveyround == 3 & attest == 1
replace questions_needing_checks = questions_needing_checks + "Réponses net_services manquantes alors que le nombre de contact avec d'autres entrepreneurs est > 0, veuillez vérifier. / " if net_size3 > 0 & net_services_pratiques == . & surveyround == 3 & attest == 1

replace needs_check = 1 if net_size3 > 30 & surveyround == 3 & net_size3 != .
replace questions_needing_checks = questions_needing_checks + "Nombre de discussions d'affaire avec les autres entrepreneurs est supérieur à 30, veuillez vérifier. / " if net_size3 > 30 & surveyround == 3 & net_size3 != .

replace needs_check = 1 if net_size4 > 30 & surveyround == 3 & net_size4 != .
replace questions_needing_checks = questions_needing_checks + "Nombre de discussions d'affaire avec les memebres de la famille est supérieur à 30, veuillez vérifier. / " if net_size4 > 30 & surveyround == 3 & net_size4 != .

***********************************************************************
* 	Part 3: Cross-checking answers from baseline & endline		
***********************************************************************
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
	
local new_turnover "ncomp_ca2023 ncomp_ca2024"

foreach var of local new_turnover {
	sum nca_2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) 
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if `var' != . & surveyround == 3 & `var' > r(p95)
}	

	*turnover export
local new_turnoverexp "ncompexp_2023 ncompexp_2024"


foreach var of local new_turnoverexp {
	sum nca_exp2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) 
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if `var' != . & surveyround == 3 & `var' > r(p95)
}	

	*profit
local new_profit "ncomp_benefice2023 ncomp_benefice2024"

foreach var of local new_profit {
	sum profit_2021, d
	replace needs_check = 1 if `var' != . & surveyround == 3 & `var' >  r(p95) 
	replace questions_needing_checks = questions_needing_checks + "`var' par employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if `var' != . & surveyround == 3 & `var' > r(p95)
}	

		*employees
sum employes if surveyround == 1, d
replace needs_check = 1 if employes != . & surveyround == 3 & employes > r(p95)
replace questions_needing_checks = questions_needing_checks + "employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if employes != . & surveyround == 3 & employes > r(p95)

*employees femmes
sum car_empl1 if surveyround == 1, d
replace needs_check = 1 if car_empl1 != . & surveyround == 3 & car_empl1 > r(p95)
replace questions_needing_checks = questions_needing_checks + "employés très grand par rapport à la baseline, veuillez vérifier les deux valeurs / " if car_empl1 != . & surveyround == 3 & car_empl1 > r(p95)

*growth rate 2021
	*ca
gen bl_empl = employes if surveyround == 1
gen el_empl = employes if surveyround == 3

local compta_vars "comp_ca2024 comp_ca2023 ca_2021 compexp_2024 compexp_2023 ca_exp2021 comp_benefice2024 comp_benefice2023 profit_2021 bl_empl el_empl"
sort id_plateforme surveyround

foreach var of local compta_vars {
    by id_plateforme: egen first_`var' = max(cond(!missing(`var'), `var', .))
    
    gen adjusted_`var' = first_`var'
    
    drop first_`var'
}

replace adjusted_ca_2021 = adjusted_ca_2021*1.176
replace adjusted_ca_exp2021 = adjusted_ca_exp2021*1.176

gen gr_ca2021_2024 = (adjusted_comp_ca2024 - adjusted_ca_2021) / adjusted_ca_2021

gen gr_ca2021_2023 = (adjusted_comp_ca2023 - adjusted_ca_2021) / adjusted_ca_2021

	*ca_exp
gen gr_caexp2021_2024 = (adjusted_compexp_2024 - adjusted_ca_exp2021) / adjusted_ca_exp2021

gen gr_caexp2021_2023 = (adjusted_compexp_2023 - adjusted_ca_exp2021) / adjusted_ca_exp2021

	*profit
gen gr_profit2021_2024 = (adjusted_comp_benefice2024 - adjusted_profit_2021) / adjusted_profit_2021

gen gr_profit2021_2023 = (adjusted_comp_benefice2023 - adjusted_profit_2021) / adjusted_profit_2021

	*employes
gen gr_empl2021_2024 = (adjusted_el_empl - adjusted_bl_empl) / adjusted_bl_empl

/*
 sum gr_ca2021_2024 gr_ca2021_2023 gr_caexp2021_2024 gr_caexp2021_2023 gr_profit2021_2024 gr_profit2021_2023 gr_empl2021_2024 if surveyround == 3, d

                       gr_ca2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -1.378453      -1.378453
 5%    -1.343776      -1.377376
10%    -1.219643      -1.346902       Obs                  73
25%    -1.008794      -1.343776       Sum of wgt.          73

50%    -.2449115                      Mean           1.211455
                        Largest       Std. dev.       4.54005
75%     1.417024       10.37702
90%     3.657024       14.14022       Variance       20.61206
95%     10.37702       18.21702       Skewness        3.70752
99%     26.84102       26.84102       Kurtosis       18.35552

                       gr_ca2021_2023
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -1.382976      -1.382976
 5%    -1.346902      -1.378453
10%    -1.177176      -1.377376       Obs                  74
25%    -.3880521      -1.346902       Sum of wgt.          74

50%     1.111824                      Mean           3.038799
                        Largest       Std. dev.      7.882228
75%     2.603465       14.14022
90%     6.457024       14.29702       Variance       62.12952
95%     14.14022       45.65702       Skewness       4.431664
99%     45.65702       45.65702       Kurtosis       23.90827

                      gr_caexp2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -1.382976      -1.382976
 5%    -1.382976      -1.382976
10%    -1.382976      -1.382976       Obs                  31
25%    -1.382976      -1.382976       Sum of wgt.          31

50%    -1.338876                      Mean          -.1236601
                        Largest       Std. dev.      3.482699
75%     -.598976        .773024
90%      .773024       4.214803       Variance       12.12919
95%     6.457024       6.457024       Skewness       3.789172
99%     16.25702       16.25702       Kurtosis       17.39033

                      gr_caexp2021_2023
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -1.382976      -1.382976
 5%    -1.382976      -1.382976
10%    -1.382976      -1.382976       Obs                  31
25%    -1.382976      -1.382976       Sum of wgt.          31

50%    -1.341953                      Mean          -.2724707
                        Largest       Std. dev.      2.194006
75%     -.442176       2.537024
90%     2.537024       2.603465       Variance       4.813663
95%     5.673024       5.673024       Skewness       2.533828
99%     7.946655       7.946655       Kurtosis       8.881398

                     gr_profit2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%    -16.95745      -16.95745
 5%           -6      -8.142858
10%        -3.28      -6.714286       Obs                  71
25%    -1.238095             -6       Sum of wgt.          71

50%          -.5                      Mean           1.477424
                        Largest       Std. dev.      15.21618
75%     .9762846              7
90%            4           11.5       Variance        231.532
95%            7       12.33333       Skewness       7.483395
99%          124            124       Kurtosis       60.95613

                     gr_profit2021_2023
-------------------------------------------------------------
      Percentiles      Smallest
 1%         -8.5           -8.5
 5%    -5.285714      -7.382979
10%    -3.777778          -7.25       Obs                  73
25%    -1.271297      -5.285714       Sum of wgt.          73

50%        -.375                      Mean           1.639976
                        Largest       Std. dev.      14.92524
75%            1              9
90%            4           11.5       Variance       222.7627
95%            9       12.33333       Skewness       7.697777
99%          124            124       Kurtosis       63.62787

                      gr_empl2021_2024
-------------------------------------------------------------
      Percentiles      Smallest
 1%         -.96           -.96
 5%         -.75            -.9
10%    -.7058824            -.8       Obs                  87
25%    -.3333333           -.75       Sum of wgt.          87

50%            0                      Mean            2.15379
                        Largest       Std. dev.      16.11009
75%           .5              4
90%     1.333333              4       Variance       259.5349
95%            4             17       Skewness       8.954912
99%        149.5          149.5       Kurtosis       82.32536

. 
*/

*ca2024
scalar gr_ca2021_2024p95 = 13.31702

replace needs_check = 1 if gr_ca2021_2024 > gr_ca2021_2024p95 & surveyround == 3 & gr_ca2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA 2024 est superiéur à 1331,702 %, veuillez vérifier / " if gr_ca2021_2024 > gr_ca2021_2024p95 & surveyround == 3 & gr_ca2021_2024 != .

*ca2023
scalar gr_ca2021_2023p95 = 13.06044

replace needs_check = 1 if gr_ca2021_2023 > gr_ca2021_2023p95 & surveyround == 3 & gr_ca2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA 2023 est superiéur à 1306,044 %, veuillez vérifier / " if gr_ca2021_2023 > gr_ca2021_2023p95 & surveyround == 3 & gr_ca2021_2023 != .

*ca_exp2024
scalar gr_caexp2021_2024p95 = 6.457024 

replace needs_check = 1 if gr_caexp2021_2024 > gr_caexp2021_2024p95 & surveyround == 3 & gr_caexp2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA export 2024 est superiéur à 645,7024 %, veuillez vérifier / " if gr_caexp2021_2024 > gr_caexp2021_2024p95 & surveyround == 3 & gr_caexp2021_2024 != .

*ca_exp2023
scalar gr_caexp2021_2023p95 = 5.673024

replace needs_check = 1 if gr_caexp2021_2023 > gr_caexp2021_2023p95 & surveyround == 3 & gr_caexp2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA export 2023 est superiéur à 567,3024 %, veuillez vérifier / " if gr_caexp2021_2023 > gr_caexp2021_2023p95 & surveyround == 3 & gr_caexp2021_2023 != .

*ca_profit2024
scalar gr_profit2021_2024p95 =  2
scalar gr_profit2021_2024p5 = -1.5

replace needs_check = 1 if gr_profit2021_2024 > gr_profit2021_2024p95 & surveyround == 3 & gr_profit2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance Profit 2024 est superiéur à 200 %, veuillez vérifier / " if gr_profit2021_2024 > gr_profit2021_2024p95 & surveyround == 3 & gr_profit2021_2024 != .

replace needs_check = 1 if gr_profit2021_2024 < gr_profit2021_2024p5 & surveyround == 3 & gr_profit2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance Profit 2024 est superiéur à -150 %, veuillez vérifier / " if gr_profit2021_2024 < gr_profit2021_2024p5 & surveyround == 3 & gr_profit2021_2024 != .

*ca_profit2023
scalar gr_profit2021_2023p95 = 2
scalar gr_profit2021_2023p5 = -2

replace needs_check = 1 if gr_profit2021_2023 > gr_profit2021_2023p95 & surveyround == 3 & gr_profit2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance Profit 2023 est superiéur à 200 %, veuillez vérifier / " if gr_profit2021_2023 > gr_profit2021_2023p95 & surveyround == 3 & gr_profit2021_2023 != .

replace needs_check = 1 if gr_profit2021_2023 < gr_profit2021_2023p5 & surveyround == 3 & gr_profit2021_2023 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance Profit 2023 est superiéur à -200 %, veuillez vérifier / " if gr_profit2021_2023 < gr_profit2021_2023p5 & surveyround == 3 & gr_profit2021_2023 != .

*empl
scalar gr_empl2021_2024p95 = 4 

replace needs_check = 1 if gr_empl2021_2024 > gr_empl2021_2024p95 & surveyround == 3 & gr_empl2021_2024 != .
replace questions_needing_checks = questions_needing_checks + "Taux de croissance CA est superiéur à 400 %, veuillez vérifier / " if gr_empl2021_2024 > gr_empl2021_2024p95 & surveyround == 3 & gr_empl2021_2024 != .

***********************************************************************
* 	Part 5: Add erroneous matricule fiscales
***********************************************************************
*use regex to check that matricule fiscale starts with 7 numbers followed by a letter
gen check_matricule = 1
replace check_matricule = 0 if ustrregexm(id_admin, "^[0-9]{7}[a-zA-Z]$") == 1
replace needs_check = 1 if check_matricule == 1 & surveyround == 3 & matricule_fisc_incorrect == 1
replace questions_needing_checks = questions_needing_checks + "matricule fiscale fausse / " if check_matricule == 1 & surveyround == 3 & matricule_fisc_incorrect ==1

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
local compta_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 666
	replace questions_needing_checks = questions_needing_checks + "`var' est 666, il faut rappeler la personne responsable de la comptabilité. / " if surveyround == 3 & `var' == 666
	
}
		*777
local compta_vars "comp_ca2023 comp_ca2024 compexp_2023 compexp_2024 comp_benefice2023 comp_benefice2024"
foreach var of local compta_vars {
	
	replace needs_check = 1 if surveyround == 3 & `var' == 777
	replace questions_needing_checks = questions_needing_checks + "`var' est 777, Il faut réécouter l'appel / " if surveyround == 3 & `var' == 777
	
}

***********************************************************************
* 	PART 8:  Export an excel sheet with needs_check variables  			
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
local order_vars "id_plateforme surveyround needs_check attest survey_phone treatment commentaires_elamouri questions_needing_checks"
local accounting_vars "`order_vars' employes gr_empl2021_2024 ca_2021 comp_ca2023 gr_ca2021_2023 ca_2021 comp_ca2024 gr_ca2021_2024 ca_exp2021 compexp_2023 gr_ca2021_2023 ca_exp2021 compexp_2024 gr_caexp2021_2024 profit_2021 comp_benefice2023 gr_profit2021_2023  profit_2021 comp_benefice2024 gr_profit2021_2024"
local export_vars "`accounting_vars' clients exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_norme exp_pra_vent ssa_action1 ssa_action2 ssa_action3 ssa_action4"
local management_vars "`export_vars' man_fin_per_fre man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv"
local networking_vars "`management_vars' net_size3 net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre"
local employee_vars "`networking_vars' car_empl1"
				
* Export to Excel
export excel `employee_vars' using "${el_checks}/fiche_correction.xlsx" ///
   if surveyround == 3 | ///
   (surveyround == 1 & (gr_ca2021_2024 > gr_ca2021_2024p95) & gr_ca2021_2024 != .) | ///
   (surveyround == 1 & (gr_ca2021_2023 > gr_ca2021_2023p95) & gr_ca2021_2023 != .) | ///
   (surveyround == 1 & (gr_caexp2021_2024 > gr_caexp2021_2024p95) & gr_caexp2021_2024 != .) | ///
   (surveyround == 1 & (gr_caexp2021_2023 > gr_caexp2021_2023p95) & gr_caexp2021_2023 != .) | ///
   (surveyround == 1 & (gr_profit2021_2024 > gr_profit2021_2024p95) & gr_profit2021_2024 != .) | ///
   (surveyround == 1 & (gr_profit2021_2024 < gr_profit2021_2024p5) & gr_profit2021_2024 != .) | ///
   (surveyround == 1 & (gr_profit2021_2023 > gr_profit2021_2023p95) & gr_profit2021_2023 != .) | ///
   (surveyround == 1 & (gr_profit2021_2023 < gr_profit2021_2023p5) & gr_profit2021_2023 != .) | ///
   (surveyround == 1 & (gr_empl2021_2024 > gr_empl2021_2024p95) & gr_empl2021_2024 != .), ///
   sheetreplace firstrow(var) datestring("%-td")

restore
