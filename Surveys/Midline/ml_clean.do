************************************************************************
* 			consortias midline clean					 		  	  *	  
***********************************************************************
*																	  
*	PURPOSE: clean consortias midline intermediate data			  	  			
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
*	Author:     	Ayoub Chamakhi, Kais Jomaa, Amina Bousnina		 												    
*	ID variable: 	id_plateforme			  					  
*	Requires:       ml_intermediate.dta 	  										  
*	Creates:        ml_intermediate.dta		 
***********************************************************************
* 	PART 1: 	Import data				  			
***********************************************************************   
                             
use "${ml_intermediate}/ml_intermediate", clear

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
format Date %td

*drop empty rows
drop if id_plateforme ==.

***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower
*rename empl fte

***********************************************************************
* 	PART 4: 	Rename the variables as needed
***********************************************************************

*In case we need to rename duplicate variable (chiffre_d'affaire)

***********************************************************************
* 	PART 5: 	Label the variables		  			
***********************************************************************

{
        * label the dataset
label data "Midline Survey"
notes _dta : January 2023
notes _dta : Consortium Project


		* Section identification
lab var Id_ident "identification of the respondent"
lab var ident2 "identification of the company"
lab var firmname_change "new name of the company, if existant"
lab var formation "company participated in latest GIZ meetings"
lab var ident_nouveau_personne "identification new person"
lab var ident_base_respondent "identification base respondent"
lab var ident_repondent_position "identification of respondent position"

		* Section exchange of ideas and innovation
lab var inno_types  "modifications in 2022 questions"

lab var inno_produit "innovation product modification"
lab var inno_process "innovation process modification"
lab var inno_lieu "innovation place"
lab var inno_commerce "innovation commerce"
lab var inno_aucune "no innovation"

lab var inno_mot "innovation motivation questions"

lab var inno_mot_idee "personal idea"
lab var inno_mot_cons "exchange ideas with a consultant"
lab var inno_mot_cont "exchange ideas with business network"
lab var inno_mot_eve "exchange ideas in an event"
lab var inno_mot_emp "exchange ideas with employees"
lab var inno_mot_test "test"
lab var inno_mot_autre "other source for innovation"

		* Section networking size/business contacts
lab var net "networking questions"

lab var net_nb_ceo "number of meetings with other CEOs"
lab var net_nb_m "number of male CEOs met"
lab var net_nb_f "number of female CEOs met"

lab var net_nb_qualite "quality advice of the business network"

lab var net_coop "perception of interaction between the enterprises"

		* Section management practices
lab var man "management practices questions"

lab var man_hr_obj "performance indicators for employees"

lab var man_ent_per "number of performance indicators tracked for the company"

lab var man_fin_per "frequency of examining financial performance"

lab var man_ind_awa "employees goal awareness"

lab var man_source "source of new strategies knowledge"

		* Section export management/readiness and export outcomes
lab var exp "export questions"

lab var exp_kno_ft_CO "COMESA knowledge"
lab var exp_kno_ft_ZE "ZECLAF knowledge"

lab var exp_prac "export practices"
lab var exp_pra_foire "participate in international trade exhibitions/fairs"
lab var exp_pra_sci "engage or work with an international trading company"
lab var exp_pra_rexp "designate an employee in charge of export-related activities"
lab var exp_pra_cible "undertake an analysis of target export markets"
lab var exp_pra_mission "undertake a trade mission/travel to one of target markets"
lab var exp_pra_douane "access the customs website"
lab var exp_pra_plan "maintain or develop an export plan"

lab var exprep_inv "investment in export activities"
lab var exprep_couts "costs of export activities"

		* Section characteristics of the company
lab var car "companys characteristics questions"

lab var car_efi "efficiency questions"
lab var car_efi_fin1 "participant have the skills to access new sources of funding"
lab var car_efi_nego "participant negotiate the affairs of my company well"
lab var car_efi_conv "participant manage to convince employees and partners to agree with me"

lab var loc "loc questions"
lab var car_loc_succ "participant is well able to determine the success of her business"
lab var car_loc_env "participant know how to determine what is happening in the internal and external environment of the company"
lab var car_loc_exp "participant knows how to deal with exports requisities"

lab var listexp "list experiment"

		* Section accounting
lab var info_neces "obtaining necessary information"
lab var info_compt1 "willing to share accountant contact info"
lab var info_compt "indicate your accountant contact info"
lab var comptable_numero "accountant phone number"
lab var comptable_email "accountant email"

lab var ca_2022 "turnover in 2022"
lab var ca_exp2022 "export turnover in 2022"
lab var profit_2022 "profit in 2022"

lab var id_admin "matricule fiscale"


		* Section GIZ/ASS activitiy
lab var empl "number of full time employees"
lab var car_carempl1 "number of women employees"
lab var car_carempl2 "number of youth employees"
lab var car_carempl3 "number of full-time employees"
lab var car_carempl4 "number of part-time employees"

lab var ssa_action1 "interest of a sub saharan africa client"
lab var ssa_action2 "identification of a business partner likely to promote my product/services in Sub-Saharan Africa"
lab var ssa_action3 "commitment of external financing for preliminary export costs"
lab var ssa_action4 "investment in the sales structure in a target market in Sub-Saharan Africa"
lab var ssa_action5 "introduction of a trade facilitation system, digital innovation"

		* Section contact & validation
lab var tel_supl "extra phone number for 2023 survey"
lab var attest "respondents attest that his/her responses correspond to truth"


		* other:
label variable list_group "treatment or control Group"
label variable heuredébut "beginning hour"
label variable date "date"
label variable heurefin "finish hour"

}

***********************************************************************
* 	PART 6: 	Label the variables values	  			
***********************************************************************
		*yes/no variables loop:
local yesnovariables Id_ident  formation exp_kno_ft_CO info_neces info_compt1 attestexp_kno_ft_ZE ///
inno_produit inno_process inno_lieu inno_commerce inno_aucune inno_mot_idee inno_mot_cons inno_mot_cont ///
inno_mot_eve inno_mot_emp inno_mot_test inno_mot_autre  exp_pra_foire exp_pra_sci exp_pra_rexp ///
exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan ssa_action1 ssa_action2 ssa_action3 ///
ssa_action4 ssa_action5

label define yesno 1 "Yes" 0 "No"
foreach var of local yesnovariables {
	label values `var' yesno
}

		*scale variables
local lowhighvar net_nb_qualite exprep_couts

label define lowhigh 1 "very low" 10 "very high"
foreach var of local lowhighvar {
	label values `var' lowhigh
}

		*agree or not variables
local agreenotvar car_efi_fin1 car_efi_nego car_efi_conv car_loc_succ car_loc_env car_loc_exp

label define agreenot 1 "strongly disagree" 5 "strongly agree"
foreach var of local agreenotvar {
	label values `var' agreenot
}
		*yes/no/other variable:
label define ident2 0 "Yes" 1 "No" 3 "Firm name changed"

		*time frequency variable:
label define man_fin_per 0 "Never" 0.25 "Annually" 0.5 "Monthly" 0.75 "Weekly" 1 "Daily"

		*company function  variable:
label define ident_respondent_position 1 "CEO" 2 "PDG" 3 "CEO and PDG" 4 "Refuse to answer" 5 "None"

label define net_coop 1 "Win" 2 "Communication" 3 "Trust" 4 "Know down" 5 "Power" 6 "Distant" ///
7 "Partner" 8 "Opponent" 9 "Connected" 10 "Domination"
 
label define man_hr_obj 0.25 "No promotion" 0.5 "Promotion on other factors than performance" /// 
0.75 "Promotion partially based on performance and other factors" 1 "Promotion based on performance"

label define man_ent_per 1 "0.33" 2 "0.66" 3 "1" 4 "0"

label define man_ind_awa 0.25 "seniors" 0.5 "most of seniors and some employees" ///
0.75 "most of seniors and employees" 1 "all seniors and employees"

label define man_source 1 "Consultant" 2 "Network" 3 "Employees" 4 "Family" 5 "Event" 6 "None" 7 "Other"

label define label_list_group 1 "treatment_group" 0 "control_group"
label values list_group label_list_group 


label define attest 1 "Yes" 

***********************************************************************
* 	Part 7: Save the changes made to the data		  			
***********************************************************************
save "${ml_intermediate}/ml_intermediate", replace