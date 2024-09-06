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
* 	PART0: load data
***********************************************************************
use "${master_final}/consortia_final", clear
set graphics on		
		* change directory to regis folder for merge with regis_final
cd "${master_gdrive}/output/giz_el_simplified"
set scheme burd

*temporarily generate a variable that compares only companies that took up to control

gen take_up_control=.
replace take_up_co~l=1 if take_up==1 & treatment==1
replace take_up_co~l =0 if take_up==0 & treatment==0
label define take_up_col 1 "Participant" 0 "Comparison Group"
***********************************************************************
* 	PART 1: Adoption of digital practices and technologys
***********************************************************************
*Knowledge index midline
betterbar knowledge_index dig_con6_bl dig_con5_ml dig_con4_ml dig_con3_ml dig_con2_ml dig_con1_ml if surveyround == 2, over(take_up_control) barlab ci ///     
    title("Knowledge about e-commerce/digital", pos(12) size(small)) ///
    xtitle(, size(small)) ///
    ytitle(, size(small))
	
gr export knowledge_ml.png, replace

*Digital Marketing and e-commerce practices (NO financials)
betterbar dsi dmi dtp dtai dig_marketing_index if surveyround == 3, over(take_up_control) barlab ci ///     
    title("Digital Marketing", pos(12) size(small)) ///
    xtitle(, size(small)) ///
    ytitle(, size(small))
	
gr export dig_practices.png, replace


*Exports
betterbar exported exported_2024 eri ihs_exports95_2023 ihs_exports95_2024 if surveyround == 3, over(take_up_control) barlab ci ///     
    title("Export", pos(12) size(small)) ///
    xtitle(, size(small)) ///
    ytitle(, size(small))
	
gr export exports_overview.png, replace

*Profits, revenues employment
betterbar ihs_ca95_2024 ihs_ca95_2023 profit_2024_pos profit_2023_pos ihs_profit95_2024 ihs_profit95_2023 fte fte_femmes w95_fte_young if surveyround == 3, over(take_up_control) barlab ci ///     
    title("Chiffre d'affaire, profits, emploi", pos(12) size(small)) ///
    xtitle(, size(small)) ///
    ytitle(, size(small))
	
gr export profit_ca_empl.png, replace
