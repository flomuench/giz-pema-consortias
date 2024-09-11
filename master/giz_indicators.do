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


	* treatment only
keep if treatment == 1

	* add condition to include only firms that reponded to all surveys?! 	

	* keep only firms that participated?
	
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
*egen ssa_any = rowmax(ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5)

lab var ssa_any "Any of the above"
lab values ssa_any yesno
	  
dtable, by(surveyround, nototal) ///
	factor(ssa_action1, statistics(fvfrequency fvproportion)) ///
	factor(ssa_action2, statistics(fvfrequency fvproportion)) ///
	factor(ssa_action3, statistics(fvfrequency fvproportion)) ///
	factor(ssa_action4, statistics(fvfrequency fvproportion)) ///
	factor(ssa_action5, statistics(fvfrequency fvproportion)) ///
	factor(ssa_any, statistics(fvfrequency fvproportion)) ///
	sformat("(%s)" fvproportion) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
* export(ssa.docx, replace)
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


* Change CA en absolue et proportion
* by consortium
dtable, by(surveyround, nototal) ///
    continuous(ca_rel_growth ca_abs_growth ///
               ca_exp_rel_growth ca_exp_abs_growth ///
               profit_rel_growth profit_abs_growth ///
               employes_rel_growth employes_abs_growth ///
               car_empl1_rel_growth car_empl1_abs_growth ///
               car_empl2_rel_growth car_empl2_abs_growth, statistics(mean))	   ///
    nformat(%9.0g mean)
*    export(kpis_growth.docx, replace)

putdocx collect

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

lab var exported "Exported"
lab values exported yesno

lab var exp_pays "Number of export countries"


dtable, by(surveyround, nototal) ///
	factor(exported, statistics(fvfrequency fvproportion)) ///
	continuous(exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes, statistics(mean)) 	///
	nformat(%9.2fc  mean fvproportion) ///
	nformat(%9.0g fvfrequency)
* export(export.docx, replace)
putdocx collect	
	
}


putdocx save giz_indicators, replace