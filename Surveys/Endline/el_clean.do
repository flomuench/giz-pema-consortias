************************************************************************
* 			consortias endline clean					 		  	  *	  
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
*	Author:     	Amira Bouziri, Kais Jomaa, Eya Hanefi		 												    
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
format Date %-td

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
forvalues x = 1(1)4 {
	rename car_carempl`x' car_empl`x'
}

		* rename for coherence with baseline
rename empl employes

		* rename for coherence
rename ca_exp2021 ca_exp_2021

		* rename to differentiate bl & ml to simplify index calculation
rename man_hr_obj man_hr_pro
rename man_fin_per man_fin_num

***********************************************************************
* 	PART 5: 	Label the variables		  			
***********************************************************************
        * label the dataset
label data "Midline Survey"
notes _dta : January 2023
notes _dta : Consortium Project


		* Section exchange of ideas and innovation
lab var inno_produit "innovation product modification"
lab var inno_process "innovation process modification"
lab var inno_lieu "innovation place"
lab var inno_commerce "innovation commerce"


		* Section networking size/business contacts
lab var net_nb_m "number of male CEOs met"
lab var net_nb_f "number of female CEOs met"
lab var net_nb_qualite "quality advice of the business network"
lab var net_coop "perception of interaction between the enterprises"

		* Section management practices
lab var man_hr_pro "employees promotion"

lab var man_hr_ind "frequency of examining employees performance"

lab var man_fin_per_fre "frequency of examining financial performance"

lab var man_fin_num "number of performance indicators tracked for the company"

lab var man_ind_awa "employees goal awareness"

lab var man_source "source of new strategies knowledge"

		* Section export management/readiness and export outcomes
lab var exp_kno_ft_co "COMESA knowledge"
lab var exp_kno_ft_ze "ZECLAF knowledge"

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

lab var car_efi_fin1 "participant have the skills to access new sources of funding"
lab var car_efi_nego "participant negotiate the affairs of my company well"
lab var car_efi_conv "participant manage to convince employees and partners to agree with me"

lab var car_loc_succ "participant is well able to determine the success of her business"
lab var car_loc_env "participant know how to determine what is happening in the internal and external environment of the company"
lab var car_loc_exp "participant knows how to deal with exports requisities"

lab var listexp "list experiment"

		* Section accounting
lab var info_neces "obtaining necessary information"
lab var info_compt1 "willing to share accountant contact info"

lab var ca "turnover in 2022"
lab var ca_exp "export turnover in 2022"
lab var profit "profit in 2022"

lab var ca_2021 "double check CA with baseline&regis data"
lab var ca_exp_2021 "double check export CA with baseline&regis data"

lab var id_admin "matricule fiscale"


		* Section GIZ/ASS activitiy
lab var employes "number of full time employees"
lab var car_empl1 "number of women employees"
lab var car_empl2 "number of youth employees"
lab var car_empl3 "number of full-time employees"
lab var car_empl4 "number of part-time employees"

lab var ssa_action1 "interest of a sub saharan africa client"
lab var ssa_action2 "identification of a business partner likely to promote my product/services in Sub-Saharan Africa"
lab var ssa_action3 "commitment of external financing for preliminary export costs"
lab var ssa_action4 "investment in the sales structure in a target market in Sub-Saharan Africa"
lab var ssa_action5 "introduction of a trade facilitation system, digital innovation"

		* Section contact & validation
*lab var tel_supl "extra phone number for 2023 survey"
lab var attest "respondents attest that his/her responses correspond to truth"


		* other:
label variable list_group "list treatment or control Group"
label variable heure "beginning hour"
label variable date "date"


***********************************************************************
* 	PART 6: 	Label the variables values	  			
***********************************************************************
		*yes/no variables loop:
local yesnovariables formation exp_kno_ft_co info_neces info_compt1 attest exp_kno_ft_ze ///
exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan ///
ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5

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
local agreenotvar car_efi_nego  car_efi_fin1 car_efi_conv car_loc_succ car_loc_env car_loc_exp //

label define agreenot 1 "strongly disagree" 5 "strongly agree"
foreach var of local agreenotvar {
	label values `var' agreenot
}


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

		* list experiment
label define label_list_group 1 "treatment_group" 0 "control_group"
label values list_group label_list_group 

		* declaration of honour
label define label_attest  1 "Yes"
label values attest label_attest


***********************************************************************
* 	PART 7: Change variable format for merger with baseline
***********************************************************************
tostring id_admin, replace

***********************************************************************
* 	Part 7: Save the changes made to the data		  			
***********************************************************************
save "${el_intermediate}/el_intermediate", replace
