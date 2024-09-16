***********************************************************************
* 			Descriptive Statistics in master file for endline survey  *					  
***********************************************************************
*																	  
*	PURPOSE: Understand the structure of the data from the different survey.					 
*																	  
*	OUTLINE: 	PART 1: Baseline and take-up
*				PART 2: Mid-line	  
*				PART 3: Endline 
*				PART 4: Intertemporal descriptive statistics															
*																	  
*	Author:  	Fabian Scheifele & Kaïs Jomaa							    
*	ID variable: id_platforme		  					  
*	Requires:  	 ecommerce_data_final.dta
***********************************************************************
* 	PART 0: load data
***********************************************************************
use "${master_final}/consortium_final", clear
set graphics on		
		* change directory to regis folder for merge with regis_final
cd "${master_output}/giz"


	* option 1: treatment only
keep if treatment == 1

	* labeling for visualisations
lab var pole "Consortium"
lab def pole 2 "Handicraft" 3 "Consulting" 4 "Digital", modify
lab var surveyround "Survey"
lab def round 1 "BL" 2 "ML" 3 "EL", modify

lab var exported "Exported"
lab values exported yesno

lab var exp_pays "Export countries"
lab var exp_pays_ssa "Export countries, SSA"
lab var clients "Clients abroad"
lab var clients_ssa "Clients SSA"
lab var clients_ssa_commandes "Orders SSA"

	* scheme for visualsiations
if "`c(username)'" == "MUNCHFA" | "`c(username)'" == "fmuench"  {
	set scheme stcolor
} 
	else {

set scheme s1color
		
	}
	
***********************************************************************
* 	PART 1: Start & structure Word Document
***********************************************************************
{
putdocx clear

putdocx begin

// Add a title

putdocx paragraph, style(Title)

putdocx text ("GIZ-CEPEX: Female Export Consortia")

putdocx textblock begin

The following statistics are based on online and telephone responses to a baseline (before start of the activity), midline (1-year after the project start and at the creation of the consortia) and endline (2-year after the project start) survey among all the 87 female-owned or female-managed firms that were invited to participate in the consortia. 

Note that a full stop (.) indicates that the question was not asked in a specific survey wave.

Further note that results pertain to all among the 87 firms that responded to a specific question in the respective surveyround. This includes also firms that dropped-out during the project.

putdocx textblock end
}
	
***********************************************************************
* 	PART 2: Export preparation indicators
***********************************************************************
{
/*
a. Expression d'intérêt par un acheteur potentiel

b. Identification d'un partenaire commercial

c. Engagement d'un financement externe pour les coûts préliminaires (subvention, crédit, garantie, etc.)

d. Investissement dans la structure de vente sur un marché cible

e. Introduction d'un système de facilitation des échanges, innovation numérique

*/

* Section paragraph
	* Add a heading
putdocx paragraph, style(Heading1)

putdocx text ("Export preparation - Sub-Sahara-Africa (SSA)")
	
	* Add an introduction
putdocx textblock begin

The first table displays the number of firms among the 87 invited firms that engaged in one of the five intermediary export steps.

putdocx textblock end

* label vars	  
lab var ssa_action1 "Buyer expression of interest"
lab var ssa_action2 "Identification commercial partner"
lab var ssa_action3 "External export finance"
lab var ssa_action4 "Investment in sales structure abroad"
lab var ssa_action5 "Digital transaction system"

* gen variable any export action
egen ssa_any = rowmax(ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5)

lab var ssa_any "Any of the above"
lab values ssa_any yesno
	  

* Create tables
	* across all consortia by surveyround
table (var) (surveyround), nototals ///
	statistic(fvfrequency  ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	statistic(fvproportion ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	sformat("(%s)" fvproportion) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
* export(ssa.docx, replace)


collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all


putdocx collect


	* by consortium & surveyround
table (var) (pole surveyround), nototals ///
	statistic(fvfrequency  ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	statistic(fvproportion ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	sformat("(%s)" fvproportion) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
	
collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all

putdocx collect

	
	

}	  

***********************************************************************
* 	PART 3: KPIs (CA, CA exp, profit, employees)
***********************************************************************
{
	* Introductory paragraph
putdocx paragraph, style(Heading1)

putdocx text ("Key Performance Indicators - Total sales, export sales, profits, & employees")

putdocx textblock begin

This section presents the AVERAGE annual growth rate in firms' key performance indicators. 

The average annual PERCENT growth rate or percent change is calculated by substracting the performance in period t from its value in period t-1, and dividing the result by the t-1 value. For example, the total sales value 1.186 is read as 118.6% increase in total sales. 

The average annual ABSOLUTE growth rate is simplify calculated by substracting performance in period t from its pre-period. For example, the value 25,033.208 is read as a twenty-five thousand Tunisian Dinar average increase in total sales between midline and endline.

putdocx textblock end
	
	* label
lab var ca_rel_growth "Total sales (% growth)"
lab var ca_abs_growth "Total sales (abs. growth)"

lab var ca_exp_rel_growth "Export sales (% growth)"
lab var ca_exp_abs_growth "Export sales (abs. growth)"

lab var profit_rel_growth "Profits (% growth)"
lab var profit_abs_growth "Profits (abs. growth)"

lab var employes_rel_growth "Employes (% growth)"
lab var employes_abs_growth "Employes (abs. growth)"

lab var car_empl1_rel_growth "Female Employes (% growth)"
lab var car_empl1_abs_growth "Female Employes (abs. growth)"

lab var car_empl2_rel_growth "Young Employes (% growth)"
lab var car_empl2_abs_growth "Young Employes (abs. growth)"


* Across all consortia by surveyround
table (var) (surveyround), nototals ///
	statistic(mean  ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(sd    ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(total ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	nformat(%9.1fc  mean total sd)
*    export(kpis_growth.docx, replace)
putdocx collect


* by consortium by surveyround
table (var) (pole surveyround), nototals ///
	statistic(mean  ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(sd    ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(total ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	nformat(%9.1fc  mean total sd)

putdocx collect

graph bar ca_abs_growth if surveyround == 3, ///
	over(pole, lab(labsize(large))) ///
	title("Sales growth", size(large) pos(12)) ///
	subtitle("At endline relative to baseline", size(medlarge) pos(12)) ///
	ytitle("Average per firm", size(large)) ///
	ylabel(0(25000)150000, format(%15.0fc))
graph export "op1_mean_abs_sales_growth.png", replace

putdocx paragraph, halign(center)
putdocx image op1_mean_abs_sales_growth.png


graph bar (sum) ca_abs_growth if surveyround == 3, ///
	over(pole, lab(labsize(large))) ///
	title("Sales growth", size(large) pos(12)) ///
	subtitle("At endline relative to baseline", size(medlarge) pos(12)) ///
	ytitle("Average per consortium", size(large)) ///
	ylabel(, format(%15.0fc))
graph export "op1_sum_abs_sales_growth.png", replace

putdocx paragraph, halign(center)
putdocx image op1_sum_abs_sales_growth.png


}
	
***********************************************************************
* 	PART 4: Export indicators
***********************************************************************
{
	* Introductory paragraph
putdocx paragraph, style(Heading1)

putdocx text ("Export Performance Indicators - Export sales, export countries, clients & orders")

putdocx textblock begin

This section presents the key export performance indicators. 

The variable "exported" is either "yes" or "no". All other numbers present the mean across all among the 87 firms that responded to the specific question in the respective surveyround.


putdocx textblock end


* across all consortia
table (var) (surveyround), nototals ///
	statistic(fvfrequency  exported) /// 
	statistic(fvproportion exported) /// 
	statistic(mean  exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(sd    exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(total exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.1fc  mean total sd fvproportion)

collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all	
	
putdocx collect	


* by consortium
table (var) (pole surveyround), nototals ///
	statistic(fvfrequency  exported) /// 
	statistic(fvproportion exported) /// 
	statistic(mean  exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(sd    exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(total exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.1fc  mean total sd fvproportion)

collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all
	
putdocx collect	

	
}


putdocx save giz_all_offered_treatment, replace


***************** Option 2: Only take-up = 1
keep if take_up == 1

***********************************************************************
* 	PART 5: Start & structure Word Document
***********************************************************************
{
putdocx clear

putdocx begin

// Add a title

putdocx paragraph, style(Title)

putdocx text ("GIZ-CEPEX: Female Export Consortia")

putdocx textblock begin

The following statistics are based on online and telephone responses to a baseline (before start of the activity), midline (1-year after the project start and at the creation of the consortia) and endline (2-year after the project start) survey among all the firms that joined the consortium (55 at midline, and 46 at endline). 

Note that a full stop (.) indicates that the question was not asked in a specific survey wave.

Further note that results pertain to all among the 55 and 46 firms that responded to a specific question in the respective surveyround.

putdocx textblock end
}
	
***********************************************************************
* 	PART 6: Export preparation indicators
***********************************************************************
{
/*
a. Expression d'intérêt par un acheteur potentiel

b. Identification d'un partenaire commercial

c. Engagement d'un financement externe pour les coûts préliminaires (subvention, crédit, garantie, etc.)

d. Investissement dans la structure de vente sur un marché cible

e. Introduction d'un système de facilitation des échanges, innovation numérique

*/

* Section paragraph
	* Add a heading
putdocx paragraph, style(Heading1)

putdocx text ("Export preparation - Sub-Sahara-Africa (SSA)")
	
	* Add an introduction
putdocx textblock begin

The first table displays the number of firms among the 87 invited firms that engaged in one of the five intermediary export steps.

putdocx textblock end

* label vars	  
lab var ssa_action1 "Buyer expression of interest"
lab var ssa_action2 "Identification commercial partner"
lab var ssa_action3 "External export finance"
lab var ssa_action4 "Investment in sales structure abroad"
lab var ssa_action5 "Digital transaction system"


* Create tables
	* across all consortia by surveyround
table (var) (surveyround), nototals ///
	statistic(fvfrequency  ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	statistic(fvproportion ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	sformat("(%s)" fvproportion) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
* export(ssa.docx, replace)
collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all

putdocx collect


	* by consortium & surveyround
table (var) (pole surveyround), nototals ///
	statistic(fvfrequency  ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	statistic(fvproportion ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 ssa_any) ///
	sformat("(%s)" fvproportion) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
	
collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all

putdocx collect

	
	

}	  

***********************************************************************
* 	PART 7: KPIs (CA, CA exp, profit, employees)
***********************************************************************
{
	* Introductory paragraph
putdocx paragraph, style(Heading1)

putdocx text ("Key Performance Indicators - Total sales, export sales, profits, & employees")

putdocx textblock begin

This section presents the AVERAGE annual growth rate in firms' key performance indicators. 

The average annual PERCENT growth rate or percent change is calculated by substracting the performance in period t from its value in period t-1, and dividing the result by the t-1 value. For example, the total sales value 1.186 is read as 118.6% increase in total sales. 

The average annual ABSOLUTE growth rate is simplify calculated by substracting performance in period t from its pre-period. For example, the value 25,033.208 is read as a twenty-five thousand Tunisian Dinar average increase in total sales between midline and endline.

putdocx textblock end
	
	* label
lab var ca_rel_growth "Total sales (% growth)"
lab var ca_abs_growth "Total sales (abs. growth)"

lab var ca_exp_rel_growth "Export sales (% growth)"
lab var ca_exp_abs_growth "Export sales (abs. growth)"

lab var profit_rel_growth "Profits (% growth)"
lab var profit_abs_growth "Profits (abs. growth)"

lab var employes_rel_growth "Employes (% growth)"
lab var employes_abs_growth "Employes (abs. growth)"

lab var car_empl1_rel_growth "Female Employes (% growth)"
lab var car_empl1_abs_growth "Female Employes (abs. growth)"

lab var car_empl2_rel_growth "Young Employes (% growth)"
lab var car_empl2_abs_growth "Young Employes (abs. growth)"


* Across all consortia by surveyround
table (var) (surveyround), nototals ///
	statistic(mean  ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(sd    ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(total ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	nformat(%9.1fc  mean total sd)
*    export(kpis_growth.docx, replace)
putdocx collect


* by consortium by surveyround
table (var) (pole surveyround), nototals ///
	statistic(mean  ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(sd    ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(total ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	nformat(%9.1fc  mean total sd)

putdocx collect

graph bar ca_abs_growth if surveyround == 3, ///
	over(pole, lab(labsize(large))) ///
	title("Sales growth", size(large) pos(12)) ///
	subtitle("At endline relative to baseline", size(medlarge) pos(12)) ///
	ytitle("Average per firm", size(large)) ///
	ylabel(, format(%15.0fc))
graph export "op2_mean_abs_sales_growth.png", replace

putdocx paragraph, halign(center)
putdocx image op2_mean_abs_sales_growth.png


graph bar (sum) ca_abs_growth if surveyround == 3, ///
	over(pole, lab(labsize(large))) ///
	title("Sales growth", size(large) pos(12)) ///
	subtitle("At endline relative to baseline", size(medlarge) pos(12)) ///
	ytitle("Average per consortium", size(large)) ///
	ylabel(, format(%15.0fc))
graph export "op2_sum_abs_sales_growth.png", replace

putdocx paragraph, halign(center)
putdocx image op2_sum_abs_sales_growth.png


}
	
***********************************************************************
* 	PART 8: Export indicators
***********************************************************************
{
	* Introductory paragraph
putdocx paragraph, style(Heading1)

putdocx text ("Export Performance Indicators - Export sales, export countries, clients & orders")

putdocx textblock begin

This section presents the key export performance indicators. 

The variable "exported" is either "yes" or "no". All other numbers present the mean across all among the 87 firms that responded to the specific question in the respective surveyround.


putdocx textblock end

lab var exported "Exported"
lab values exported yesno

lab var exp_pays "Number of export countries"

* across all consortia
table (var) (surveyround), nototals ///
	statistic(fvfrequency  exported) /// 
	statistic(fvproportion exported) /// 
	statistic(mean  exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(sd    exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(total exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.1fc  mean total sd fvproportion)

collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all
	
putdocx collect	


* by consortium
table (var) (pole surveyround), nototals ///
	statistic(fvfrequency  exported) /// 
	statistic(fvproportion exported) /// 
	statistic(mean  exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(sd    exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(total exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.1fc  mean total sd fvproportion)

collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all
	
putdocx collect	

	
}


putdocx save giz_participants, replace


***************** Option 3: Only take-up = 1 & refus = 0
egen el_refus = max(refus), by(id_plateforme)
egen el_take_up = min(take_up), by(id_plateforme)
keep if el_refus == 0 & el_take_up == 1

	
***********************************************************************
* 	PART 9: Start & structure Word Document
***********************************************************************
{
putdocx clear

putdocx begin

// Add a title

putdocx paragraph, style(Title)

putdocx text ("GIZ-CEPEX: Female Export Consortia")

putdocx textblock begin

The following statistics are based on online and telephone responses to a baseline (before start of the activity), midline (1-year after the project start and at the creation of the consortia) and endline (2-year after the project start) survey among all the 39 female-owned or female-managed firms that were invited & decided to participate in the consortia, and responded to all surveys. 

Note that a full stop (.) indicates that the question was not asked in a specific survey wave.

putdocx textblock end
}
	
***********************************************************************
* 	PART 10: Export preparation indicators
***********************************************************************
{
/*
a. Expression d'intérêt par un acheteur potentiel

b. Identification d'un partenaire commercial

c. Engagement d'un financement externe pour les coûts préliminaires (subvention, crédit, garantie, etc.)

d. Investissement dans la structure de vente sur un marché cible

e. Introduction d'un système de facilitation des échanges, innovation numérique

*/

* Section paragraph
	* Add a heading
putdocx paragraph, style(Heading1)

putdocx text ("Export preparation - Sub-Sahara-Africa (SSA)")
	
	* Add an introduction
putdocx textblock begin

The first table displays the number of firms among the 87 invited firms that engaged in one of the five intermediary export steps.

putdocx textblock end

* label vars	  
lab var ssa_action1 "Buyer expression of interest"
lab var ssa_action2 "Identification commercial partner"
lab var ssa_action3 "External export finance"
lab var ssa_action4 "Investment in sales structure abroad"
lab var ssa_action5 "Digital transaction system"
	  

* Create tables
	* across all consortia by surveyround
table (var) (surveyround), nototals ///
	statistic(fvfrequency  ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5) ///
	statistic(fvproportion ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5) ///
	sformat("(%s)" fvproportion) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
* export(ssa.docx, replace)

collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all

putdocx collect


	* by consortium & surveyround
table (var) (pole surveyround), nototals ///
	statistic(fvfrequency  ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5) ///
	statistic(fvproportion ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5) ///
	sformat("(%s)" fvproportion) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
	
collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all
	
putdocx collect

	
	

}	  

***********************************************************************
* 	PART 11: KPIs (CA, CA exp, profit, employees)
***********************************************************************
{
	* Introductory paragraph
putdocx paragraph, style(Heading1)

putdocx text ("Key Performance Indicators - Total sales, export sales, profits, & employees")

putdocx textblock begin

This section presents the AVERAGE annual growth rate in firms' key performance indicators. 

The average annual PERCENT growth rate or percent change is calculated by substracting the performance in period t from its value in period t-1, and dividing the result by the t-1 value. For example, the total sales value 1.186 is read as 118.6% increase in total sales. 

The average annual ABSOLUTE growth rate is simplify calculated by substracting performance in period t from its pre-period. For example, the value 25,033.208 is read as a twenty-five thousand Tunisian Dinar average increase in total sales between midline and endline.

putdocx textblock end
	
	* label
lab var ca_rel_growth "Total sales (% growth)"
lab var ca_abs_growth "Total sales (abs. growth)"

lab var ca_exp_rel_growth "Export sales (% growth)"
lab var ca_exp_abs_growth "Export sales (abs. growth)"

lab var profit_rel_growth "Profits (% growth)"
lab var profit_abs_growth "Profits (abs. growth)"

lab var employes_rel_growth "Employes (% growth)"
lab var employes_abs_growth "Employes (abs. growth)"

lab var car_empl1_rel_growth "Female Employes (% growth)"
lab var car_empl1_abs_growth "Female Employes (abs. growth)"

lab var car_empl2_rel_growth "Young Employes (% growth)"
lab var car_empl2_abs_growth "Young Employes (abs. growth)"


* Across all consortia by surveyround
table (var) (surveyround), nototals ///
	statistic(mean  ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(sd    ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(total ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	nformat(%9.1fc  mean total sd)
*    export(kpis_growth.docx, replace)
putdocx collect


* by consortium by surveyround
table (var) (pole surveyround), nototals ///
	statistic(mean  ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(sd    ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	statistic(total ca_rel_growth ca_abs_growth ca_exp_rel_growth ca_exp_abs_growth  profit_rel_growth profit_abs_growth employes_rel_growth employes_abs_growth car_empl1_rel_growth car_empl1_abs_growth car_empl2_rel_growth car_empl2_abs_growth) ///
	nformat(%9.1fc  mean total sd)

putdocx collect


graph bar ca_abs_growth if surveyround == 3, ///
	over(pole, lab(labsize(large))) ///
	title("Sales growth", size(large) pos(12)) ///
	subtitle("At endline relative to baseline", size(medlarge) pos(12)) ///
	ytitle("Average per firm", size(large)) ///
	ylabel(, format(%15.0fc))
graph export "op3_mean_abs_sales_growth.png", replace

putdocx paragraph, halign(center)
putdocx image op3_mean_abs_sales_growth.png


graph bar (sum) ca_abs_growth if surveyround == 3, ///
	over(pole, lab(labsize(large))) ///
	title("Sales growth", size(large) pos(12)) ///
	subtitle("At endline relative to baseline", size(medlarge) pos(12)) ///
	ytitle("Average per consortium", size(large)) ///
	ylabel(, format(%15.0fc))
graph export "op3_sum_abs_sales_growth.png", replace

putdocx paragraph, halign(center)
putdocx image op3_sum_abs_sales_growth.png


}
	
***********************************************************************
* 	PART 12: Export indicators
***********************************************************************
{
	* Introductory paragraph
putdocx paragraph, style(Heading1)

putdocx text ("Export Performance Indicators - Export sales, export countries, clients & orders")

putdocx textblock begin

This section presents the key export performance indicators. 

The variable "exported" is either "yes" or "no". All other numbers present the mean across all among the 87 firms that responded to the specific question in the respective surveyround.


putdocx textblock end

lab var exported "Exported"
lab values exported yesno

lab var exp_pays "Number of export countries"

* across all consortia
table (var) (surveyround), nototals ///
	statistic(fvfrequency  exported) /// 
	statistic(fvproportion exported) /// 
	statistic(mean  exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(sd    exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(total exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.1fc  mean total sd fvproportion)
	
collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all
	
putdocx collect	


* by consortium
table (var) (pole surveyround), nototals ///
	statistic(fvfrequency  exported) /// 
	statistic(fvproportion exported) /// 
	statistic(mean  exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(sd    exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	statistic(total exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.1fc  mean total sd fvproportion)
	
collect label list result, all
collect label levels result fvfrequency "Frequency" ///
    fvproportion   "Proportion" ///
    , modify
collect label list result, all
	
putdocx collect	

	
}


putdocx save giz_participants_no_attritition, replace