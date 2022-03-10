************************************************************************
* 			consortias baseline clean					 		  	  *	  
***********************************************************************
*																	  
*	PURPOSE: clean consortias baseline raw data	& save as intermediate				  	  			
*																	  
*																	  
*	OUTLINE:														  
*	1)		Format string & numerical variables				          
*	2)   	Drop all text windows from the survey					  
*	3)  	Make all variables names lower case						  
*	4)  	Order the variables in the data set						  	  
*	5)  	Rename the variables									  
*	6)  	Label the variables										  
*   7) 		Removing trailing & leading spaces from string variables	
*   8) 		Remove observations for incomplete entries									 
*																	  													      
*	Author:     	Fabian Scheifele, Siwar Hakim & Kais Jomaa						    
*	ID variable: 	id_plateforme (identifiant)			  					  
*	Requires:       bl_raw.dta 	  										  
*	Creates:        bl_inter.dta			                                  
***********************************************************************
* 	PART 1: 	Format string & numerical & date variables		  			
***********************************************************************

use "${bl_raw}/bl_raw", clear

{
	* string
ds, has(type string) 
local strvars "`r(varlist)'"
format %-20s `strvars'

	* make all string obs lower case and trim leading and trailing white space
foreach x of local strvars {
replace `x'= lower(`x')
replace `x' = stritrim(strtrim(`x'))
}
	* numeric 
ds, has(type numeric) 
local numvars "`r(varlist)'"
format %-25.2fc `numvars'

}
	* keep dates as string variables for RA quality checks
gen date_creation_string = Date
format date_creation_string %td
tostring date_creation_string, replace u force


***********************************************************************
* 	PART 2: 	Drop all unneeded columns and rows from the survey		  			
***********************************************************************

*drop VARNAMES

*drop dig_con2 dig_con6 Surlesquellesdesmarketplaces dig_marketing_num19 dig_con4 dig_logistique_retour 

*UNSTAR once numerice IDs are in*drop if id_plateforme==.

* 	Drop incomplete entries

gen complete = 0 

replace complete = 1 if validation ==1 | attest ==1

// keep if complete == 1

// drop complete
*/
***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

/*

***********************************************************************
* 	PART 5: 	Rename the variables as needed
***********************************************************************
ident 
orienter 
ident2
ident_nouveau_personne 
ident_base_respondent 
ident_repondent_position 
entr_idee 
entr_bien 
produit1 
produit2 
produit3 
inno_produit 
inno_process 
inno_lieu 
inno_commerce 
inno_aucune 
inno_mot_idee 
inno_mot_conc 
inno_mot_cons 
inno_mot_cont 
inno_mot_eve
inno_mot_emp 
inno_mot_test 
inno_mot_autre 
inno_rd 
net_nb_fam 
net_nb_dehors 
net_nb_qualite 
net_time 
net_coop 
man_hr_obj 
man_hr_feed 
man_pro_ano 
man_fin_enr 
man_fin_profit 
man_fin_per 
man_mark_prix 
man_mark_div 
man_mark_clients 
man_mark_offre 
man_mark_pub 
exp_pra_foire 
exp_pra_sci 
exp_pra_rexp 
exp_pra_cible 
exp_pra_mission 
exp_pra_douane 
exp_pra_plan 
expprep_norme 
exprep_inv 
exprep_couts 
exp_pays 
exp_pays_principal 
exp_afrique 
info_neces 
comptable_numero
Comptable_email 
ca_2021 
ca_exp_2021 
profit_2021 
ca_2020 
ca_2019 
ca_2018 
ca_exp2020 
ca_exp2019 
ca_exp2018 
id_admin 
car_efi_fin1 
car_efi_nego
car_efi_conv  
car_init_prob 
car_init_init 
car_init_opp  
car_loc_succ 
car_loc_env 
car_loc_insp  
listexp 
car_empl1 
car_empl2 
car_empl3 
car_empl4 
car_empl5 
famille1 
famille2 
Att_adh1 
Att_adh2 
Att_adh3 
Att_adh4 
Att_adh5 
Att_adh6 
att_strat1 
att_strat2 
att_strat3 
att_strat4 
att_cont1 
att_cont2 
att_cont3 
att_cont4 
att_cont5 
lundi 
mardi 
mercredi 
jeudi 
vendredi 
samedi 
dimanche 
Att_hor1
Att_hor2 
Att_hor3 
Att_hor4 
Att_hor5 
Att_voyage1 
Att_voyage2 
Att_voyage3 
support1 
support2 
support3 
support4 
support5 
support6 
support7 
tel_supl 
attest


 forvalues i=1/100 {
    rename `i'"-"`varlist' `varlist'
  }
  
  foreach v of var *_? {
           local new = substr("`v'", 1, length("`v'") - 2)
           rename `v' `new'
}




{
	* Section identification
rename id id_plateforme
rename groupe treatment

	* Section informations personnelles répresentantes
rename nometprénomdudelaparticipa rg_nom_rep
rename qualitéfonction rg_position_rep
rename sexe rg_gender_rep
rename téléphonedudelaparticipante rg_telrep 
rename adressemaildudelaparticipan rg_emailrep
rename téléphonedudelagérante rg_telpdg
rename adressemaildudelagérante rg_emailpdg
rename sexedudelagérante rg_sex_pdg
rename adressesiègesociale rg_adresse 
rename raisonsociale firmname 

}
*/
***********************************************************************
* 	PART 6: 	Label the variables		  			
***********************************************************************

{
        * label the dataset
label data "Baseline Survey"
notes _dta : March 2022
notes _dta : Consortium Project


label variable list_group "Treatment or Control Group"

		* Section identification
*lab var ident "identification"
*lab var orienter "oriontation to the representative"
lab var ident2 "identification 2"
lab var ident_nouveau_personne "identification new person"
lab var ident_base_respondent "identification base respondent"
*lab var ident_repondent_position "identification respondent position"

		* Section essence of the company
lab var entr_idee "the enterprise's idea"
lab var entr_bien "the enterprise's good (service/product)"
lab var produit1 "first product/service"
lab var produit2 "second product/service"
lab var produit3 "third product/service"

		* Section exchange of ideas and innovation
lab var inno_produit "innovation product modification"
lab var inno_process "innovation process modification"
lab var inno_lieu "innovation place"
lab var inno_commerce "innovation commerce"
*lab var inno_aucune "no innovation"
*lab var inno_mot_idee "personal idea"
*lab var inno_mot_conc "exchange ideas with a competitor"
*lab var inno_mot_cons "exchange ideas with a consultant"
*lab var inno_mot_cont "exchange ideas with business network"
*lab var inno_mot_eve "exchange ideas in an event"
*lab var inno_mot_emp "exchange ideas with employees"
*lab var inno_mot_test "test"
lab var inno_mot_autre "other source for innovation"
lab var inno_rd "innovation research and development"

		* Section networking size/business contacts
lab var net_nb_fam "number of business network in the family"
lab var net_nb_dehors "number of business network outside the family"
lab var net_nb_qualite "quality advice of the business network"
lab var net_time "time spent with other directors during the last 3 months"
lab var net_coop "perception of interaction between the enterprises"

		* Section management practices
lab var man_hr_obj "performance indicators for employees"
lab var man_hr_feed "regular meetings with employees for feedback"
lab var man_pro_ano "frequancy of measuring anomalies in production"
lab var man_fin_enr "registration of sales and purchases"
lab var man_fin_profit "knowing the profit per product/service"
lab var man_fin_per "frequency of examinin gfinancial performance"

		* Section marketing practices: man_mark_prix was changed to man_mark_pra/
		*but has to be verified with El-Amouri
lab var man_mark_pra  "study the prices and/or products of one of competitors"
lab var man_mark_div  "ask customers what other products they would like to be produced"
lab var man_mark_clients "investigate why past customers have stopped buying from the company"
lab var man_mark_offre "attract customers with a special offer"
lab var man_mark_pub "advertising in any form"

		* Section export management/readiness and export outcomes
lab var exp_pra_foire "participate in international trade exhibitions/fairs"
lab var exp_pra_sci "engage or work with an international trading company"
lab var exp_pra_rexp "designate an employee in charge of export-related activities"
lab var exp_pra_cible "undertake an analysis of target export markets"
lab var exp_pra_mission "undertake a trade mission/travel to one of target markets"
lab var exp_pra_douane "access the customs website"
lab var exp_pra_plan "maintain or develop an export plan"
lab var expprep_norme "product is certified according to the quality standards in target markets"
lab var exprep_inv "investment in export activities"
lab var exprep_couts "costs of export activities"
lab var exp_pays "number of countries exported to in 2021"
lab var exp_pays_principal "main market exported to in 2021"
lab var exp_afrique "past direct/indirect export activities to an africain country"

		* Section accounting
lab var info_neces "obtaining necessary information"
lab var ca_2021 "turnover in 2021"
lab var ca_exp_2021 "export turnover in 2021"
lab var profit_2021 "profit in 2021"
lab var ca_2020 "turnover in 2020"
lab var ca_2019 "turnover in 2019"
lab var ca_2018 "turnover in 2018"
lab var ca_exp2020 "export turnover in 2020"
lab var ca_exp2019 "export turnover in 2019"
lab var ca_exp2018 "export turnover in 2018"
lab var id_admin "tax identification number"

		* Section characteristics of the company
lab var car_efi_fin1 "participant have the skills to access new sources of funding"
lab var car_efi_nego "participant negotiate the affairs of my company well"
lab var car_efi_conv "participant manage to convince employees and partners to agree with me"
lab var car_init_prob "participant actively confront business problems when they arise"
lab var car_init_init "participant take the initiative immediately, when others do not"
lab var car_init_opp "participant spot and seize opportunities quickly to achieve her professional goals"
lab var car_loc_succ "participant is well able to determine the success of her business"
lab var car_loc_env "participant know how to determine what is happening in the internal and external environment of the company"
lab var car_loc_insp "participant inspires other women to be better entrepreneurs"
lab var listexp "list experiment"
lab var car_empl1 "number of women employees"
lab var car_empl2 "number of youth employees"
lab var car_empl3 "number of full-time employees"
lab var car_empl4 "number of part-time employees"
lab var car_empl5 "number of qualified employees (graduated, certified..)"
lab var famille1 "one of family members has a company"
lab var famille2 "number of children below 18"

		* Section expectations
lab var att_adh1 "develop export turnover"
lab var att_adh2 "access to assistance and support services abroad"
lab var att_adh3 "develop exporting skills"
lab var att_adh4 "being part of a female business network to learn from other female CEOs"
lab var att_adh5 "reduce export costs"
lab var att_adh6 "other"
*lab var att_strat1 "participant don't have an export strategy. She would adopt that of the consortium"
*lab var att_strat2 "the consortium's strategy must be consistent with her own strategy"
*lab var att_strat3 "the company has an export strategy and the consortium is a vector for certain actions"
*lab var att_strat4 "other"
*lab var att_cont1 "no contribution"
*lab var att_cont2 "fixed, lump sum contribution"
*lab var att_cont3 "proportional contribution to the turnover"
*lab var att_cont4 "proportional contribution to the turnover achieved at export"
*lab var att_cont5 "other"
lab var att_jour "preferred day for meetings"
/*
lab var lundi "monday"
lab var mardi "tuesday"
lab var mercredi "wednesday"
lab var jeudi "tuesday"
lab var vendredi "friday"
lab var samedi "saturday"
lab var dimanche "sunday"
lab var att_hor1 "preffered time for meeting 8-10h" 
lab var att_hor2 "preffered time for meeting 9-12h30" 
lab var att_hor3 "preffered time for meeting 12h30-15h30" 
lab var att_hor4 "preffered time for meeting 15h30-19h"
lab var att_hor5 "preffered time for meeting 18-20h"
*/
lab var support1 "Pas besoin de support, je me débrouille seule pour participer aux rencontres"
lab var support2 "organize virtual meetings (zoom or skype)"
lab var support3 "change the meeting place"
lab var support4 "adopt a time slot before or after the regular working day"
lab var support5 "offer free childcare during consortia meetings"
lab var support6 "provide financial support for transportation and accommodation"
lab var support7 "other"

		* Section contact & validation
lab var validation "respondent validated his/her answers"
lab var attest "respondents attest that his/her responses correspond to truth"

}
*/
***********************************************************************
* 	PART 7: 	Label the variables values	  			
***********************************************************************
/*

local yesnovariables ident ident2 man_fin_profit man_mark_pra man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci    ///
exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan expprep_norme exp_afrique info_neces famille1

label define yesno 1 "Yes" 0 "No"
foreach var in local yesnovariables {
	label values `var' yesno
}

local frequencyvariables man_hr_obj man_hr_feed man_pro_ano man_fin_per 

label define frequency 0 "Never" 1 "Annually" 2 "Monthly" 3 "Weekly" 4 "Daily"
foreach var in local frequencyvariables {
	label values `var' frequency
}

local agreevariables car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp

label define agree 1 "Strongly disagree" 2 "Disagree" 3 "Neither agree nor disagree" 4 "Agree" 5 "Strongly agree" 
foreach var in local agreevariables {
	label values `var' agree
}

label define label_list_group 1 "treatment_group" 0 "control_group"
label values d_list_group label_list_group 

label define label_orienter 1 "Currently not available" 2 "Does not answer" 3 "No longer part of the team" 4 "Refuse to take the call" 5 "Mrs NAME-REPRESENTATIVE" 6 "The respondent decides to answer the questionnaire"
label values orienter label_orienter

label define label_ident_nouveau_personne 1  "check with the representative of the company" 0 "continue with the questionnaire"
label values ident_nouveau_personne label_ident_nouveau_personne

label define label_ident_repondent_position 1 "La propriétaire" 2 "La PDG" 3 "Propriétaire et PDG" 4 "Je ne veux pas répondre" 5 "Aucune des deux" 
label values ident_repondent_position label_ident_repondent_position

label define label_entr_bien 1 "Bien" 2 "Service" 3 "Les deux"
label values entr_bien label_entr_bien

label define label_net_coop  1 "Winning" 2 "Communication" 3 "Trust" 4 "Elimination" 5 "Exchange" 6 "Power" 7 "Partnership" 8 "Opponent" 9 "Connect" 10 "Dominate"
label values net_coop label_net_coop

label define label_man_fin_enr 1 "yes, in paper" 2 "yes, in digital" 3 "yes, in paper and digital" 4 "No" 
label values man_fin_enr label_man_fin_enr

label define label_exprep_couts 1 "very low" 10 "very high"
label values exprep_couts label_exprep_couts

label define label_att_voyage 1 "participant can travel" 2 "particiapant can travel if there is a financial support" 3 "participant can not travel"
label values att_voyage label_att_voyage 

label define label_tel_supl 1 "phone number 1" 2 "phone number 2"
label values tel_supl label_tel_supl

label define label_attest 1 "Yes" 
label values attest label_attest 
*/


***********************************************************************
* 	Part 8: Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
