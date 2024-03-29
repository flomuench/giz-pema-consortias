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
use "${bl_intermediate}/bl_inter", clear

	* change directory to visualisations
cd "$bl_output/stratification"

	* begin word file to export strata visualisations
version 15
set varabbrev on // quick fix necessary due to bug in tab2docx reported here (otherwise necessary to change ado file): https://www.statalist.org/forums/forum/general-stata-discussion/general/1564330-reporting-a-tab2docx-syntax-error

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


g miss_ca2021 = 1
replace miss_ca2021 =. if ca_2021==.

mdesc miss_ca2021
display "We miss some information on CA2021 for `r(miss)' (`r(percent)'%) out of `r(total)'."
putdocx paragraph
putdocx text ("We miss some information on CA2021 for `r(miss)' (`: display %9.2fc `r(percent)'% out of `r(total)').'")	

	* Management practices
	
putdocx paragraph
putdocx text ("Management practices questions"), bold

g miss_mgmt_prc = 1
local mgmt_prc_m  man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per
foreach var of local  mgmt_prc_m {
	replace miss_mgmt_prc = . if `var' == .
}

mdesc miss_mgmt_prc
display "We miss some information on management practices variables for `r(miss)' (`r(percent)'%) out of `r(total)'."
putdocx paragraph
putdocx text ("We miss some information on management practices variables for `r(miss)' (`: display %9.2fc `r(percent)'% out of `r(total)').'")	


*Use older figures for CA and exp if 2021 figures are missing (NOT GOOD IDEA
*BECAUSE LITTLE CORRELATION BETWEEN 2021 and previous years*
/*
gen ca_exp_2021=ca_exp_2021
replace ca_exp_2021=ca_exp2020 if ca_exp_2021==0 | ca_exp_2021==.
replace ca_exp_2021=ca_exp2019 if (ca_exp2020==0 | ca_exp2020==.) & (ca_exp_2021==0 | ca_exp_2021==.)
replace ca_exp_2021=ca_exp2018 if (ca_exp2020==0 | ca_exp2020==.) & (ca_exp_2021==0 | ca_exp_2021==.)& (ca_exp2019==0 | ca_exp2019==.)

gen ca_2021=ca_2021
replace ca_2021=ca_2020 if ca_exp_2021==0 | ca_exp_2021==.
replace ca_2021=ca_2019 if (ca_2020==0 | ca_2020==.) & (ca_2021==0 | ca_2021==.)
replace ca_2021=ca_2018 if (ca_2020==0 | ca_2020==.) & (ca_2021==0 | ca_2021==.)& (ca_2019==0 | ca_2019==.)
*/
***********************************************************************
* 	PART 3: create strata
***********************************************************************
***********************************************************************
* 	Approach 2: Poles & revenues by quartiles
***********************************************************************
gen strata2_prep=1 

forvalues x = 1(1)4 {
sum ca_2021 if pole == `x',d 
replace strata2_prep = 2 if ca_2021>`r(p75)' & ca_2021!=. & pole== `x'
replace strata2_prep = 3 if ca_2021<=`r(p75)' & ca_2021>`r(p50)' & ca_2021!=. & pole== `x'
replace strata2_prep = 4 if ca_2021<=`r(p50)' & ca_2021>`r(p25)' & ca_2021!=.& pole== `x'
replace strata2_prep = 5 if ca_2021<=`r(p25)' & ca_2021!=. & pole== `x'

}

egen strata2 = group(strata2_prep pole)


***********************************************************************
* 	Approach 3: Poles & exports by quartiles
***********************************************************************

gen strata3_prep=1 

forvalues x = 1(1)4 {
sum ca_exp_2021 if pole == `x',d 
replace strata3_prep = 2 if ca_exp_2021>`r(p75)' & ca_exp_2021!=. & pole== `x'
replace strata3_prep = 3 if ca_exp_2021<=`r(p75)' & ca_exp_2021>`r(p50)' & ca_exp_2021!=. & pole== `x'
replace strata3_prep = 4 if ca_exp_2021<=`r(p50)' & ca_exp_2021>`r(p25)' & ca_exp_2021!=.& pole== `x'
replace strata3_prep = 5 if ca_exp_2021<=`r(p25)' & ca_exp_2021!=. & pole== `x'

}

egen strata3 = group(strata3_prep pole)

*small strata are strata with missing export data, Problem?*

***********************************************************************
* 	Approach 4: Poles & revenues by quartile and top 10%exporters
***********************************************************************
gen strata4_prep=1 

forvalues x = 1(1)4 {
sum ca_2021 if pole == `x',d 
replace strata4_prep = 2 if ca_2021>`r(p75)' & ca_2021!=. & pole== `x'
replace strata4_prep = 3 if ca_2021<=`r(p75)' & ca_2021>`r(p50)' & ca_2021!=. & pole== `x'
replace strata4_prep = 4 if ca_2021<=`r(p50)' & ca_2021>`r(p25)' & ca_2021!=.& pole== `x'
replace strata4_prep = 5 if ca_2021<=`r(p25)' & ca_2021!=. & pole== `x'
sum ca_exp_2021 if pole == `x',d 
replace strata4_prep = 6 if ca_exp_2021>=`r(p90)' & ca_exp_2021!=. & pole== `x'
}

egen strata4 = group(strata4_prep pole)

***********************************************************************
* 	Approach 5: Poles & revenues (90,90-75,75-50,50-25,25-0) and top 10%exporters
***********************************************************************
gen strata5_prep=1 

forvalues x = 1(1)4 {
sum ca_2021 if pole == `x',d 
replace strata5_prep = 2 if ca_2021>`r(p90)' & ca_2021!=. & pole== `x'
replace strata5_prep = 3 if ca_2021<=`r(p90)' & ca_2021>`r(p75)' & ca_2021!=. & pole== `x'
replace strata5_prep = 4 if ca_2021<=`r(p75)' & ca_2021>`r(p50)' & ca_2021!=.& pole== `x'
replace strata5_prep = 5 if ca_2021<=`r(p50)' & ca_2021>`r(p25)' & ca_2021!=. & pole== `x'
replace strata5_prep = 6 if ca_2021<=`r(p25)' & ca_2021!=. & pole== `x'
sum ca_exp_2021 if pole == `x',d 
replace strata5_prep = 7 if ca_exp_2021>=`r(p90)' & ca_exp_2021!=. & pole== `x'
}

egen strata5 = group(strata5_prep pole)

***********************************************************************
* 	Approach 6: Poles & revenues (90,90-75,75-50, below 50) and exporters(90p+)
***********************************************************************
gen strata6_prep=1 

forvalues x = 1(1)4 {
sum ca_2021 if pole == `x',d 
replace strata6_prep = 2 if ca_2021>`r(p90)' & ca_2021!=. & pole== `x'
replace strata6_prep = 3 if ca_2021<=`r(p90)' & ca_2021>`r(p75)' & ca_2021!=. & pole== `x'
replace strata6_prep = 4 if ca_2021<=`r(p75)' & ca_2021>`r(p50)' & ca_2021!=.& pole== `x'
replace strata6_prep = 5 if ca_2021<=`r(p50)' & ca_2021!=. & pole== `x'
sum ca_exp_2021 if pole == `x',d 
replace strata6_prep = 6 if ca_exp_2021>=`r(p90)' & ca_exp_2021!=. & pole== `x'
}

egen strata6 = group(strata6_prep pole)

***********************************************************************
* 	Approach 7: Poles & revenues (90,90-50,below 50) and exporters(90p+)
***********************************************************************
gen strata7_prep=1 

forvalues x = 1(1)4 {
sum ca_2021 if pole == `x',d 
replace strata7_prep = 2 if ca_2021>`r(p90)' & ca_2021!=. & pole== `x'
replace strata7_prep = 3 if ca_2021<=`r(p90)' & ca_2021>`r(p50)' & ca_2021!=. & pole== `x'
replace strata7_prep = 4 if ca_2021<=`r(p50)' & ca_2021!=.& pole== `x'
sum ca_exp_2021 if pole == `x',d 
replace strata7_prep = 6 if ca_exp_2021>=`r(p90)' & ca_exp_2021!=. & pole== `x'
}

egen strata7 = group(strata7_prep pole)


***********************************************************************
* 	Approach 8: Create pair of 6 per pole by revenue (if ca_2021 was missing , then ca_2020)
***********************************************************************
gen ca_all= ca_2021
replace ca_all= ca_2020 if ca_all==. | ca_all==0

sort pole (ca_all), stable
by pole: gen rankstrata8=_n

gen strata8_prep=.
replace strata8_prep= 1 if rankstrata8<=6
replace strata8_prep= 2 if rankstrata8>6 &rankstrata8<=12 
replace strata8_prep= 3 if rankstrata8>12 & rankstrata8<=18
replace strata8_prep= 4 if rankstrata8>18 & rankstrata8<=24
replace strata8_prep= 5 if rankstrata8>24 & rankstrata8<=30
replace strata8_prep= 6 if rankstrata8>30 & rankstrata8<=36
replace strata8_prep= 7 if rankstrata8>36 & rankstrata8<=42
replace strata8_prep= 8 if rankstrata8>42 & rankstrata8<=48
replace strata8_prep= 9 if rankstrata8>48 & rankstrata8<=54
replace strata8_prep= 10 if rankstrata8>54

egen strata8= group(pole strata8_prep)

*manually attributing small rests to previous strata to avoid small group*
replace strata8 = 17 if strata8 == 18    
replace strata8= 8 if pole == 1 & rankstrata8 == 42
/*
egen exp_ca_rank = group(ca_all ca_exp_2021), missing
bysort pole: egen rank = rank(exp_ca_rank), unique
sort pole rank
egen group2=cut(rank), group(6)
egen strata8= group(pole group2)

replace strata8=6 if ca_all>600000 & pole==1
replace strata8=24 if ca_all>=175000 & pole==2
replace strata8=26 if ca_all>800000 & pole==4
replace strata8=27 if ca_all>1300000 & pole==1
replace strata8=28 if ca_all>500000 & pole==2
*/
***********************************************************************
* 	Approach 9: Only revenue poles(90,90-75,75-50, below 50)
***********************************************************************
gen strata9_prep=1 

forvalues x = 1(1)4 {
sum ca_2021 if pole == `x',d 
replace strata9_prep = 2 if ca_2021>`r(p90)' & ca_2021!=. & pole== `x'
replace strata9_prep = 3 if ca_2021<=`r(p90)' & ca_2021>`r(p75)' & ca_2021!=. & pole== `x'
replace strata9_prep = 4 if ca_2021<=`r(p75)' & ca_2021>`r(p50)' & ca_2021!=.& pole== `x'
replace strata9_prep = 4 if ca_2021<=`r(p50)' & ca_2021>`r(p25)' & ca_2021!=.& pole== `x'
replace strata9_prep = 4 if ca_2021<=`r(p25)' & ca_2021!=.& pole== `x'
}

egen strata9 = group(strata9_prep pole)

***********************************************************************
* 	Approach 10: Replicate approach 8 with 5 poles instead of 4
***********************************************************************
gen ca_all2= ca_2021
replace ca_all2= ca_2020 if ca_all2==. 

egen exp_ca_rank2 = group(ca_all2 ca_exp_2021), missing
bysort pole2: egen rank2 = rank(exp_ca_rank2), unique
sort pole2 rank2
egen group3=cut(rank2), group(6)
egen strata10= group(pole2 group3)
replace strata10=29 if ca_all>1100000 & pole==1
replace strata10=30 if ca_all>610000 & pole==3


***********************************************************************
* 	drop all strata prep variables
***********************************************************************
drop strata?_prep

***********************************************************************
* 	PART 4: Compare Variance per approach
***********************************************************************

***********************************************************************
* 	Approach 2
***********************************************************************
putdocx paragraph
putdocx text ("Strata2: average SDs"), linebreak bold
putdocx text ("This approach creates 5 groups based on revenue 2021 (quartiles and missing) per pole")
putdocx paragraph
tab2docx strata2
putdocx paragraph

	*** total revenues
	
bysort strata2: egen ca_sd_strata2 = sd(ca_2021)
sum ca_sd_strata2, d
local s1_strata2 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata2: egen exp_sd_strata2 = sd(ca_exp_2021)
sum exp_sd_strata2, d
local s1_strata2 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
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
putdocx pagebreak

***********************************************************************
* 	Approach 3: Pole& export quartiles*
***********************************************************************
putdocx paragraph
putdocx text ("strata3: average SDs"), linebreak bold
putdocx text ("This approach creates 5 groups on exports (quartiles plus missing) for each pole d'activité")
putdocx paragraph
tab2docx strata3
putdocx paragraph

	*** total revenues
	
bysort strata3: egen ca_sd_strata3 = sd(ca_2021)
sum ca_sd_strata3, d
local s1_strata3 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata3: egen exp_sd_strata3 = sd(ca_exp_2021)
sum exp_sd_strata3, d
local s1_strata3 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata3: egen profit_sd_strata3 = sd(profit_2021)
sum profit_sd_strata3, d
local s1_strata3 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
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
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak
***********************************************************************
* 	Approach 4 Revenue quartiles and top 10% exporters*
***********************************************************************
putdocx paragraph
putdocx text ("strata4: average SDs"), linebreak bold
putdocx text ("This approach creates 5 groups on revenues(quartiles plus missing) plus one group for top10% of exports for each pole d'activité")
putdocx paragraph
tab2docx strata4
putdocx paragraph

	*** total revenues
	
bysort strata4: egen ca_sd_strata4 = sd(ca_2021)
sum ca_sd_strata4, d
local s1_strata4 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata4: egen exp_sd_strata4 = sd(ca_exp_2021)
sum exp_sd_strata4, d
local s1_strata4 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
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
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak

***********************************************************************
* 	Approach 5: 
***********************************************************************
putdocx paragraph
putdocx text ("strata5: average SDs"), linebreak bold
putdocx text ("This approach creates 6 groups on revenues(90+,90-75p,75-50p,50-35p,<25 plus missing) and one group for Top10% exports for each pole d'activité")
putdocx paragraph
tab2docx strata5
putdocx paragraph

	*** total revenues
	
bysort strata5: egen ca_sd_strata5 = sd(ca_2021)
sum ca_sd_strata5, d
local s1_strata5 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata5: egen exp_sd_strata5 = sd(ca_exp_2021)
sum exp_sd_strata5, d
local s1_strata5 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
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
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak

***********************************************************************
* 	Approach 6: 
***********************************************************************
putdocx paragraph
putdocx text ("strata6: average SDs"), linebreak bold
putdocx text ("This approach creates revenue groups (90,90-75,75-50, below 50) and exporters(90p+)for each pole d'activité")
putdocx paragraph
tab2docx strata6
putdocx paragraph

	*** total revenues
	
bysort strata6: egen ca_sd_strata6 = sd(ca_2021)
sum ca_sd_strata6, d
local s1_strata6 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata6: egen exp_sd_strata6 = sd(ca_exp_2021)
sum exp_sd_strata6, d
local s1_strata6 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata6: egen profit_sd_strata6 = sd(profit_2021)
sum profit_sd_strata6, d
local s1_strata6 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata6: egen pays_sd_strata6 = sd(exp_pays)
sum pays_sd_strata6, d
local s1_strata6 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak

***********************************************************************
* 	Approach 7: 
***********************************************************************
putdocx paragraph
putdocx text ("strata7: average SDs"), linebreak bold
putdocx text ("This approach creates revenue groups (90,90-50, below 50) and exporters(90p+)for each pole d'activité")
putdocx paragraph
tab2docx strata7
putdocx paragraph

	*** total revenues
	
bysort strata7: egen ca_sd_strata7 = sd(ca_2021)
sum ca_sd_strata7, d
local s1_strata7 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata7: egen exp_sd_strata7 = sd(ca_exp_2021)
sum exp_sd_strata7, d
local s1_strata7 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata7: egen profit_sd_strata7 = sd(profit_2021)
sum profit_sd_strata7, d
local s1_strata7 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata7: egen pays_sd_strata7 = sd(exp_pays)
sum pays_sd_strata7, d
local s1_strata7 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak

***********************************************************************
* 	Approach 8: 
***********************************************************************
putdocx paragraph
putdocx text ("strata8: average SDs"), linebreak bold
putdocx text ("This approach creates sixlets based on ranking firms by revenues, and in case of ties by exports")
putdocx paragraph
tab2docx strata8
putdocx paragraph

	*** total revenues
	
bysort strata8: egen ca_sd_strata8 = sd(ca_2021)
sum ca_sd_strata8, d
local s1_strata8 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata8: egen exp_sd_strata8 = sd(ca_exp_2021)
sum exp_sd_strata8, d
local s1_strata8 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata8: egen profit_sd_strata8 = sd(profit_2021)
sum profit_sd_strata8, d
local s1_strata8 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata8: egen pays_sd_strata8 = sd(exp_pays)
sum pays_sd_strata8, d
local s1_strata8 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak

***********************************************************************
* 	Approach 9: Only revenue strata (90+,90-75,75-50,50-25,25 below, missing) 
***********************************************************************
putdocx paragraph
putdocx text ("strata9: average SDs"), linebreak bold
putdocx text ("This approach creates 6 groups per pole based on revenue percentiles (90+,90-75,75-50,50-25,25 & below, missing")
putdocx paragraph
tab2docx strata9
putdocx paragraph

	*** total revenues
	
bysort strata9: egen ca_sd_strata9 = sd(ca_2021)
sum ca_sd_strata9, d
local s1_strata9 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata9: egen exp_sd_strata9 = sd(ca_exp_2021)
sum exp_sd_strata9, d
local s1_strata9 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata9: egen profit_sd_strata9 = sd(profit_2021)
sum profit_sd_strata9, d
local s1_strata9 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata9: egen pays_sd_strata9 = sd(exp_pays)
sum pays_sd_strata9, d
local s1_strata9 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak


***********************************************************************
* 	Approach 10 replicate approach 8 with 5 poles
***********************************************************************
putdocx paragraph
putdocx text ("strata10: average SDs"), linebreak bold
putdocx text ("This approach creates replicates approach 8 (six-seven groups on revenue) with 5 poles")
putdocx paragraph
tab2docx strata10
putdocx paragraph

	*** total revenues
	
bysort strata10: egen ca_sd_strata10 = sd(ca_2021)
sum ca_sd_strata10, d
local s1_strata10 : display %9.2fc  `r(mean)'
display "With these strata, total revenue 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total revenue 2021  by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total exports
	
bysort strata10: egen exp_sd_strata10 = sd(ca_exp_2021)
sum exp_sd_strata10, d
local s1_strata10 : display %9.2fc  `r(mean)'
display "With these strata, total exports 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  total export 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum ca_exp_2021,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** total profits
bysort strata10: egen profit_sd_strata10 = sd(profit_2021)
sum profit_sd_strata10, d
local s1_strata10 : display %9.2fc  `r(mean)'
display "With these strata, profit 2021 by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  profit 2021 by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum profit_2021,d
display %9.2fc  `r(sd)'
putdocx paragraph
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")

*** number of countries
bysort strata10: egen pays_sd_strata10 = sd(exp_pays)
sum pays_sd_strata10, d
local s1_strata10 : display %9.2fc  `r(mean)'
display "With these strata, number of export countries by stratum has an average standard deviation of `r(mean)'."
putdocx paragraph
putdocx text ("With these strata,  number of export countries by stratum has an average standard deviation of `: display %9.2fc `r(mean)''")
sum exp_pays,d
display %9.2fc  `r(sd)'
putdocx text ("Compared to overall sd of `: display %9.2fc `r(sd)''.")
putdocx pagebreak


***********************************************************************
* 	PART 5: Save
***********************************************************************

	* Save doc
	
putdocx save stratification.docx, replace
set varabbrev off

cd "$bl_final"

save "bl_final", replace
