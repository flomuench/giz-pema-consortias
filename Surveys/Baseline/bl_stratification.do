***********************************************************************
* 			Female export consortia field experiment:  stratification								  		  
***********************************************************************
*																	   
*	PURPOSE: Stratify firms that responded to baseline survey; select stratification approach						  								  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Generate strata using different appraoches
*	2)		Calculate variance by stratification approach
*   3)		Save														  
*
*																 																      *
*	Author:  	Fabian Scheifele													  
*	ID variable: 	id_plateforme			  									  
*	Requires:		bl_final.dta
*	Creates:		
*																	  
***********************************************************************
* 	PART I:  	define the settings as necessary 			     	  *
***********************************************************************

	* import data
use "${bl_final}/bl_final", clear

	* change directory to visualisations
cd "$bl_output/stratification"

	* begin word file to export strata visualisations
	
putdocx clear	
putdocx begin
putdocx paragraph, halign(center) 
putdocx text ("Stratification options"), bold


***********************************************************************
* 	PART 2: Identify missing values in strata vars
***********************************************************************


	* Calculate missing values	
	
putdocx paragraph, halign(center) 
putdocx text ("Missing values"), bold
	
	*Chiffre d'affaire 2021

	
putdocx paragraph
putdocx text ("Chiffre d'affaire 2021"), bold


g missing_ca2021 = 1
replace missing_ca2021 =. if ca_2021==.

mdesc missing_ca2021
display "We miss some information on CA2021 for `r(miss)' (`r(percent)'%) out of `r(total)'."
putdocx paragraph
putdocx text ("We miss some information on CA2021 for `r(miss)' (`: display %9.2fc `r(percent)''%) out of `r(total)'.")	

	* Management practices
	
putdocx paragraph
putdocx text ("Management practices questions"), bold

g missing_mgmt_prc = 1
local mgmt_prc_m  man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per
foreach var of local  mgmt_prc_m {
	replace missing_mgmt_prc = . if `var' == .
}

mdesc missing_mgmt_prc
display "We miss some information on management practices variables for `r(miss)' (`r(percent)'%) out of `r(total)'."
putdocx paragraph
putdocx text ("We miss some information on management practices variables for `r(miss)' `: display %9.2fc`r(percent)'''%) out of `r(total)'.")	


*Use older figures for CA and exp if 2021 figures are missing
gen exp_strata=ca_exp_2021
replace exp_strata=ca_exp2020 if ca_exp_2021==0 | ca_exp_2021==.
replace exp_strata=ca_exp2019 if (ca_exp2020==0 | ca_exp2020==.) & (ca_exp_2021==0 | ca_exp_2021==.)
replace exp_strata=ca_exp2018 if (ca_exp2020==0 | ca_exp2020==.) & (ca_exp_2021==0 | ca_exp_2021==.)& (ca_exp2019==0 | ca_exp2019==.)

gen ca_strata=ca_2021
replace ca_strata=ca_2020 if ca_exp_2021==0 | ca_exp_2021==.
replace ca_strata=ca_2019 if (ca_2020==0 | ca_2020==.) & (ca_2021==0 | ca_2021==.)
replace ca_strata=ca_2018 if (ca_2020==0 | ca_2020==.) & (ca_2021==0 | ca_2021==.)& (ca_2019==0 | ca_2019==.)

***********************************************************************
* 	PART 3: create strata
***********************************************************************

***********************************************************************
* 	Approach 1: only poles strata
***********************************************************************


***********************************************************************
* 	Approach 2: Poles & Top-25th percentile revenues & missing revenues
***********************************************************************
gen strata2_ca2021=1
sum ca_strata, d
replace strata2_ca2021 = 2 if ca_strata>`r(p75)' & ca_strata!=.
replace strata2_ca2021 = 3 if ca_strata==.
egen strata2 = group(strata2_ca2021 pole)


***********************************************************************
* 	Approach 3: strata3s & Top-25th percentile revenues, missing revenues & low management practices=0
***********************************************************************
/*Makes no sense because groups too small*
gen strata3_ca2021=1
sum ca_2021, d
replace strata3_ca2021 = 2 if ca_2021>`r(p75)' & ca_2021!=.
replace strata3_ca2021 = 3 if ca_2021==.

*Create additional strata for companies <75p turnover and low management practices
replace strata3_ca2021 = 4 if strata3_ca2021==1 & raw_mngtvars<=8
*group strata =4 does not exist so 
replace strata3_ca2021 = 5 if strata3_ca2021==3 & raw_mngtvars<=8

egen strata3 = group(strata3_ca2021 pole)
*/

***********************************************************************
* 	Approach 4: Poles & Top-50th percentile exports, missing exports and zero
***********************************************************************


gen strata4_prep=1
sum exp_strata, d
replace strata4_prep = 2 if exp_strata>`r(p50)' & exp_strata!=.
replace strata4_prep = 3 if exp_strata==0
replace strata4_prep = 4 if exp_strata==.
egen strata4 = group(strata4_prep pole)
*small strata are strata with missing export data, Problem?*

***********************************************************************
* 	Approach 5: Poles & missing exports and zero (4*3= 12 groups)
***********************************************************************
gen strata5_prep=1
sum exp_strata, d
replace strata5_prep = 2 if exp_strata==0
replace strata5_prep = 3 if exp_strata==.
egen strata5 = group(strata5_prep pole)



***********************************************************************
* 	PART 4: Compare Variance per approach
***********************************************************************
***********************************************************************
* 	Approach 1: only pole strata
***********************************************************************
putdocx paragraph
putdocx text ("Strata1: average SDs"), linebreak bold
putdocx text ("This approach creates 1 stratum for each strata3 d'activité")
putdocx paragraph
tab2docx pole
putdocx paragraph

	*** total revenues
	
bysort pole: egen ca_sd_strata1 = sd(ca_strata)
sum ca_sd_strata1, d
local s1_pole : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort pole: egen exp_sd_strata1 = sd(exp_strata)
sum exp_sd_strata1, d
local s1_pole : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort pole: egen profit_sd_strata1 = sd(profit_2021)
sum profit_sd_strata1, d
local s1_pole : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort pole: egen pays_sd_strata1 = sd(exp_pays)
sum pays_sd_strata1, d
local s1_pole : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")


***********************************************************************
* 	Approach 2
***********************************************************************
putdocx paragraph
putdocx text ("Strata2: average SDs"), linebreak bold
putdocx text ("This approach creates 3 groups based on revenue (>75p, below, missing) per pole")
putdocx paragraph
tab2docx strata2
putdocx paragraph

	*** total revenues
	
bysort strata2: egen ca_sd_strata2 = sd(ca_strata)
sum ca_sd_strata2, d
local s1_strata2 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata2: egen exp_sd_strata2 = sd(exp_strata)
sum exp_sd_strata2, d
local s1_strata2 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata2: egen profit_sd_strata2 = sd(profit_2021)
sum profit_sd_strata2, d
local s1_strata2 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata2: egen pays_sd_strata2 = sd(exp_pays)
sum pays_sd_strata2, d
local s1_strata2 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")


***********************************************************************
* 	Approach 3
***********************************************************************
/*
putdocx paragraph
putdocx text ("Strata1: average SDs"), linebreak bold
putdocx text ("This approach creates 12 strata (4 strata3s * 3 Revenue groups)")
putdocx paragraph
tab2docx strata3
putdocx paragraph

	*** total revenues
	
bysort strata3: egen ca_sd_strata3 = sd(ca_strata)
sum ca_sd_strata3, d
local s1_strata3 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata3: egen exp_sd_strata3 = sd(exp_strata)
sum exp_sd_strata3, d
local s1_strata3 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata3: egen profit_sd_strata3 = sd(profit_2021)
sum profit_sd_strata3, d
local s1_strata3 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata3: egen pays_sd_strata3 = sd(exp_pays)
sum pays_sd_strata3, d
local s1_strata3 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  tnumber of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
*/


***********************************************************************
* 	Approach 4: Pole& above median exports and zero or missing exports*
***********************************************************************
putdocx paragraph
putdocx text ("strata4: average SDs"), linebreak bold
putdocx text ("This approach creates 4 strata on exports (above median, below, zero and missing) for each pole d'activité")
putdocx paragraph
tab2docx strata4
putdocx paragraph

	*** total revenues
	
bysort strata4: egen ca_sd_strata4 = sd(ca_strata)
sum ca_sd_strata4, d
local s1_strata4 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata4: egen exp_sd_strata4 = sd(exp_strata)
sum exp_sd_strata4, d
local s1_strata4 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata4: egen profit_sd_strata4 = sd(profit_2021)
sum profit_sd_strata4, d
local s1_strata4 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata4: egen pays_sd_strata4 = sd(exp_pays)
sum pays_sd_strata4, d
local s1_strata4 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")




***********************************************************************
* 	Approach 5: Pole& and zero or missing exports*
***********************************************************************
putdocx paragraph
putdocx text ("strata5: average SDs"), linebreak bold
putdocx text ("This approach creates 3 strata on exports (above zero, zero and missing) for each pole d'activité")
putdocx paragraph
tab2docx strata5
putdocx paragraph

	*** total revenues
	
bysort strata5: egen ca_sd_strata5 = sd(ca_strata)
sum ca_sd_strata5, d
local s1_strata5 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata5: egen exp_sd_strata5 = sd(exp_strata)
sum exp_sd_strata5, d
local s1_strata5 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_strata,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata5: egen profit_sd_strata5 = sd(profit_2021)
sum profit_sd_strata5, d
local s1_strata5 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata5: egen pays_sd_strata5 = sd(exp_pays)
sum pays_sd_strata5, d
local s1_strata5 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

***********************************************************************
* 	PART 5: Save
***********************************************************************

	* Save doc
	
putdocx save stratification3_withall.docx, replace

	* Pick one strata approach, delete others

g strata = strata2

drop strata4
	
cd "$bl_final"

save "bl_final", replace
