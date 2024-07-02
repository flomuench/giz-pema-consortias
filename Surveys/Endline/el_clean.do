************************************************************************
* 			consortias endline clean					 		  	  *	  
***********************************************************************
*																	  
*	PURPOSE: clean consortias endline intermediate data			  	  			
*																	  
*																	  
*	OUTLINE:		
*   1)		Import data												  
*	2)		Removing whitespace & format string and date & lower case			          
*	3)   	Make all variables names lower case						  
*	4)  	Rename the variables as needed						  
*	5)  	Label the variables						  	  									  
*	6)  	Label the variables	values									  
*   7) 		Save the changes made to the data					 
*																	  													      
*	Author:     	Amira Bouziri, Kais Jomaa, Eya Hanefi, Ayoub Chamakhi		 												    
*	ID variable: 	id_plateforme			  					  
*	Requires:       el_intermediate.dta 	  										  
*	Creates:        el_intermediate.dta		 
***********************************************************************
* 	PART 1: 	Import data				  			
***********************************************************************   
                             
use "${el_intermediate}/el_intermediate", clear

***********************************************************************
* 	PART 2: 	Removing whitespace & format string and date & lower case 		  			
***********************************************************************

	*remove leading and trailing white space

{
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
replace `x' = stritrim(strtrim(`x'))
	}
}

	*string
ds, has(type string) 
local strvars "`r(varlist)'"
format %-20s `strvars'
	
	*make all string lower case
foreach x of local strvars {
replace `x'= lower(`x')
}


	*fix date
*format date %-td

*drop empty rows
drop if id_plateforme ==.

***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower


***********************************************************************
* 	PART 4: 	Rename the variables as needed
***********************************************************************
		* rename to correct survey coding typos
forvalues x = 1(1)2 {
	rename car_carempl_div`x' car_empl`x'
}

		* rename for coherence with baseline
rename empl employes
lab var employes "Number of employeess"

lab var car_empl1 "Number of female employees"
lab var car_empl2 "Number of youth less than 36 years old"
***********************************************************************
* 	PART 5: 	Label the variables		  			
***********************************************************************
        * label the dataset
label data "Endline Survey"
notes _dta : June/July 2024
notes _dta : Consortium Project


lab var id_plateforme "Unique identifier of the company"
*lab var date "Date of finished survey"

lab var el_products "Most sold products/ services"
lab var products_other "Other most sold product/ service"

* Section Innovation
lab var inno_produit "Product/ service innovation"
lab var inno_exampl_produit1 "Example product innovation1"
lab var inno_exampl_produit2 "Example product innovation2"


lab var entreprise_model "Type of clients: B2B, B2C or both B2B and B2C" 


* Section Export

label var exp_pays "Number of export countries"
label var exp_pays_ssa "Number of SSA export countries"
label var clients "Number of international clients"
label var clients_ssa "Number of international clients in SSA"
label var clients_ssa_commandes "Number of SSA orders"

	
label var exp_pra_rexp "Appointing a manager responsible for export-related commercial activities."
label var exp_pra_foire "Participation in international exhibition/trade fairs"
label var exp_pra_sci "Find a business partner or international trading company"
label var exp_pra_norme "Product certification"
label var exp_pra_vent "Investment in sales structure"

lab var ssa_action1 "Expression of interest from a potential client in Sub-Saharan Africa for your products/services."
lab var ssa_action2 "Identification of a business partner capable of promoting products/services in Sub-Saharan Africa."
lab var ssa_action3 "Securing external funding for initial export costs (grants, loans, guarantees, etc.)"
lab var ssa_action4 "Investment in sales infrastructure targeting the Sub-Saharan African market" 






* Section The Firm

lab var employes "Number of employees"
lab var car_empl1 "Number of women employees"
lab var car_empl2 "Number of young employees (less than 36 yo)"

* Section Management
lab var man_fin_per_ind "Financial and accounting indicators (sales, costs, profits, etc.)"
lab var man_fin_per_pro "Production management/ service creation"
lab var man_fin_per_qua "The quality of inputs"
lab var man_fin_per_sto "Stock"
lab var man_fin_per_emp "Employee performance and absenteeism"
lab var man_fin_per_liv "On time delivery" 
lab var man_fin_per_fre "frequency of performance indicators examination" 

lab var man_fin_pra_bud "Maintaining an up-to-date written or digital budget and a business plan"
lab var man_fin_pra_pro "Calculating the costs, prices, and profits achieved on each product or service sold."
lab var man_fin_pra_dis "Distunction between business accounts and personal accounts"

lab var man_ind_awa "Providing performance incentives to employees"

/* REMOVED QUESTIONS
lab var man_mark_prix "Studying competitors' prices and products in target local and international markets"
lab var man_mark_clients "Collecting data on customer needs and satisfaction levels"
lab var man_mark_pub "Advertising (paid) in any form"
lab var man_mark_dig "Establishing a digital presence for the company (website or social media)"
*/

lab var inno_proc_met "New methods or technologies for producing goods/services"
lab var inno_proc_log "New logistical procedures, delivery, or distribution of goods/services"
lab var inno_proc_prix "Introduces new pricing methods"
lab var inno_proc_sup "New suppliers or improved business terms (price, quality) with suppliers"
lab var inno_proc_autres "Binary other process of innovation"
lab var inno_proc_other "Example of other process of innovation" 

lab var man_source_cons "Consultant"
lab var man_source_pdg "Other entrepreneur"
lab var man_source_fam "Family or friends"
lab var man_source_even "Event,trade fair,conference" 
lab var man_source_autres "Binary question of other management strategy sources"



* Section Network
lab var net_association " Number of membership in associations"
*lab var net_size1 "Discuss company's business with suppliers" REMOVED FROM QUESTIONS
*lab var net_size2 "Discuss company's business with clients" REMOVED FROM QUESTIONS
lab var net_size3 "Discuss company's business with other entrepreneurs"
lab var net_size4 "Discuss company's business with friends or family" 

lab var net_services_pratiques "Sharing management practices and solutions for entrepreneurial challenges (e.g., management, finance, quality control, etc.)"
lab var net_services_produits "Exchanging ideas on new products/services or technologies"
lab var net_services_mark "Sharing experiences of penetrating foreign markets"
lab var net_services_sup "Connecting with new or existing clients or suppliers"
lab var net_services_contract "Collaboration for important tender bids"
lab var net_services_confiance "Encouragement to build self-confidence in the face of uncertainty and risks"
lab var net_services_autre "Binary other situation of using entrepneurs network"
lab var net_services_other "Example other situation of using entrepneurs network"

*lab var net_gender1 "Discuss company's business with female suppliers" REMOVED FROM QUESTIONS
*lab var net_gender2 "Discuss company's business with female clients" REMOVED FROM QUESTIONS
lab var net_gender3 "Discuss company's business with other female entrepreneurs"
lab var net_gender4 "Discuss company's business with female friends or family" 

lab var net_gender3_giz "Female entrepreneurs met while in GIZ"

* Section L'entrepreneuse
lab var car_efi_fin1 "Having the necessary skills to access sources of funding"
lab var car_efi_man "Ability of managing the business"
lab var car_efi_motiv "Ability of motivating employees"
*lab var  "Ability of managing conflicts" REMOVED FROM QUESTIONS

*lab var car_loc_succ "Confidence in presenting the business and its product in public" REMOVED FROM QUESTIONS
lab var car_loc_env "feeling comfortable in establishing new business contacts, including internationally"
lab var car_loc_exp "proficiency in the administrative and logistical procedures surrounding exports"
lab var car_loc_soin "Managing to balance personal and professional life"

*lab var extrovert1 "Easily establishing new relationships" REMOVED FROM QUESTIONS
*lab var extrovert2 "Preference to work alone or with a small devoted team" REMOVED FROM QUESTIONS
*lab var extrovert3 "Feeling exhausted after interacting with  employees, suppliers, and clients" REMOVED FROM QUESTIONS

lab var listexp1 "List experiment"

* Section accounting 

label var q29 "Tax identification number"

*label var q29_nom "Accountant's name"
*label var q29_tel "Accountant's phone number"
*label var q29_mail "Accountant's email"

label var comp_ca2023 "Total turnover in 2023 in dt"
label var comp_ca2024 "Total turnover in 2024 in dt"

label var compexp_2023 "Export turnover in 2023 in dt"
label var compexp_2024 "Export turnover in 2024 in dt"

label var profit_2023_category "Profit/Loss in 2023 in dt"
label var profit_2024_category "Profit/Loss in 2024 in dt"

label var comp_benefice2023 "Company profit in 2023 in dt"
label var comp_benefice2024 "Company profit in 2024 in dt"


label var profit_2023_category_perte "Company loss category in 2023 in dt"
label var profit_2023_category_gain "Company loss category in 2023 in dt"

label var profit_2024_category_perte "Company loss category in 2024 in dt"
label var profit_2024_category_gain "Company loss category in 2024 in dt"

lab var comp_ca2023_intervalles "Intervals of total turnover in 2023 in dt"
lab var comp_ca2024_intervalles "Intervals of total turnover in 2024 in dt"

lab var profit_2023_category_perte "Intervals of loss in 2023 in dt"
lab var profit_2024_category_perte "Intervals of loss in 2023 in dt"

lab var profit_2023_category_gain "Intervals of profit in 2023 in dt"
lab var profit_2024_category_gain "Intervals of profit in 2023 in dt"


* Section Intervention-retour sur le CF

lab var int_ben1 " Main benefits that the consortium provided to the company"
lab var int_ben2 " Second benefits that the consortium provided to the company"
lab var int_ben3 " Third benefits that the consortium provides to the company"
lab var int_ben_autres "Example of other benefits that the consortium provides to the company"

lab var int_incv1 "Main inconvenient of the consortium to the company"
lab var int_incv2 "Second inconvenient of the consortium to the company"
lab var int_incv3 " Third inconvenient of the consortium to the company"
lab var int_incv_autres "Example of other inconvenient that the consortium provides to the company" 

lab var int_contact "Number of consortium members that were contacted outside of the activities"

*lab var car_loc_succ "participant is well able to determine the success of her business"
lab var car_loc_env "participant know how to determine what is happening in the internal and external environment of the company"
lab var car_loc_exp "participant knows how to deal with exports requisities"

	

		* Section contact & validation
*lab var tel_supl "extra phone number for 2023 survey"
lab var attest "respondents attest that his/her responses correspond to truth"

lab var expp_ben "likert scale of export adventages perception"
lab var expp_cost "likert scale of export disadventages perception"

lab var int_other "example of another refusal to participate in consortia activities"

***********************************************************************
* 	PART 6: 	Label the variables values	  			
***********************************************************************
		*yes/no variables loop:
local yesnovariables inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_norme exp_pra_vent ssa_action1 ssa_action2 ///
ssa_action3 ssa_action4 man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_pra_bud man_fin_per_pro man_fin_pra_dis man_ind_awa ///
man_source_cons man_source_pdg man_source_fam man_source_even man_source_autres net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre

label define yesno 1 "Yes" 0 "No"
foreach var of local yesnovariables {
	label values `var' yesno
}

		*scale variables
local lowhighvar expp_cost expp_ben 

label define lowhigh 1 "very low" 7 "very high"
foreach var of local lowhighvar {
	label values `var' lowhigh
}
		*agree or not variables
local agreenotvar car_efi_fin1 car_efi_man car_efi_motiv  car_loc_env car_loc_exp car_loc_soin //

label define agreenot 1 "strongly disagree" 7 "strongly agree"
foreach var of local agreenotvar {
	label values `var' agreenot
	
}
/*
*labeling likert scale variables 
label define likert 1"Strongly disagree" 2 "Disagree" 3 "Slightly disagree" 4 "Neither disagree nor agree" 5 "Slightly Agree" 6 "Agree" 5 "Strongly Agree"
label values expp_cost expp_ben likert
*/

		* management practices
/* unfortunately, it is not possible to attach value labels to decimals in Stata.
				* number of kpi's
label define kpi 0 "Aucun indicateur" 0.33 "1-2 indicateurs" 0.66 "3-9 indicateurs " 1 "10 ou plus indicateurs"
label values man_fin_per kpi

			* monitoring (frequency)
				* financial performance
label define label_freq_kpi 0 "Never" 0.25 "Annually" 0.5 "Monthy" 0.75 "Weekly" 1 "Daily"
label values man_fin_per_fre label_freq_kpi
			
				* employee performance
label define label_freq_empl 0 "Never" 0.25 "Annually" 0.5 "Quarterly" 0.75 "Monthly" 1 "Weekly or more"
label values man_hr_ind label_freq_empl
				

				* promotion
label define label_promo 0 "No promotion" 0.5 "Promotion on other factors than performance" 0.75 "Promotion based on employee performance" 1 "Promotion based on employee & firm performance"
* note: as we wrongly coded associated value, the label attachment to variable is done in ml_correct

				* who is aware about kpi's of company
label define kpi_empl 0.25 "senior managers" 0.5 "most managers and some employees" 0.75 "majority of managers and employees" 1 "all managers and employees"
label values man_ind_awa kpi_empl
*/
/*
		* list experiment
label define label_list_group 1 "treatment_group" 0 "control_group"
label values list_group label_list_group 
*/
		* declaration of honour
label define label_attest  1 "Yes"
label values attest label_attest

***********************************************************************
* 	Part 7: Save the changes made to the data		  			
***********************************************************************
save "${el_intermediate}/el_intermediate", replace
