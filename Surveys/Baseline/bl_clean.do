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
*	Author:     	Fabian Scheifele						    
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
*strtrim(`x')*
}
	* numeric 
ds, has(type numeric) 
local numvars "`r(varlist)'"
format %-25.2fc `numvars'

	* dates
		* creation
format Date %td


}
	* keep dates as string variables for RA quality checks
gen date_creation_string = Date
format date_creation_string %td
tostring date_creation_string, replace u force


/* --------------------------------------------------------------------
	PART 1.2: Turn binary questions numerical 
----------------------------------------------------------------------*/
/*
local binaryvars Acceptezvousenregistrement  Nomdelapersonne Nomdelentreprise id_ident2 dig_con1 dig_con3 dig_con5 dig_presence1 dig_presence2 dig_presence3 dig_marketing_lien expprep_cible  dig_vente dig_marketing_ind1 attest attest2 dig_service_satisfaction expprep_norme expprep_demande rg_oper_exp carsoutien_gouvern perc_com1 perc_com2 exp_afrique car_ecom_prive exp_avant21 info_neces
 
foreach var of local binaryvars {
	capture replace `var' = "1" if strpos(`var', "oui")
	capture replace `var' = "0" if strpos(`var', "non")
	capture replace `var' = "-999" if strpos(`var', "sais")
	capture replace `var' = "-1200" if strpos(`var', "prévu")
	capture destring `var', replace
}



/* --------------------------------------------------------------------
	PART 1.3: Fix mutliple choice questions
----------------------------------------------------------------------*/
{
	
* entr_bien_service
	
//capture encode entr_bien_service, gen(entr_service_bien)

* car_sex_pdg
/*
replace car_sex_pdg = "1" if car_sex_pdg == "femme أنثى"
replace car_sex_pdg = "2" if car_sex_pdg == "homme ذكر"
destring car_sex_pdg, replace

* car_pdg_educ

replace car_pdg_educ = "1" if car_pdg_educ == "aucune scolarité, école primaire, secondaire (sans obtention du bac) ماقراش/ تعليم ابتدائي / تعليم ثانوي (ما خذاش البكالوريا)"
replace car_pdg_educ = "1" if car_pdg_educ == "formation professionnelle diplômante (bts/ btp...)  تكوين مهني (يمكن من الحصول على شهادة)"
replace car_pdg_educ = "2" if car_pdg_educ == "diplôme de l'enseignement secondaire (baccalauréat) متحصل على شهادة ختم التعليم الثانوي (البكالوريا)"
replace car_pdg_educ = "3" if car_pdg_educ == "enseignement supérieur (diplôme universitaire) متحصل على شهادة جامعية"
replace car_pdg_educ = "-999" if car_pdg_educ == "ne sais pas (ne pas lire) - ما نعرفش (ما تقراش)"
destring car_pdg_educ, replace
*/	
	
* variable dig_con2
gen dig_con2_internationale = 0
replace dig_con2_internationale = 1 if strpos(dig_con2, "r1")

gen dig_con2_correct = 0
replace dig_con2_correct = 1 if strpos(dig_con2, "1")

gen dig_con2_pas_paiement = 0
replace dig_con2_pas_paiement = 1 if strpos(dig_con2, "r3")



* Surlesquellesdesmarketplaces

g dig_presence3_ex1 = 0
replace dig_presence3_ex1 = 1 if strpos(Surlesquellesdesmarketplaces, "r1")

g dig_presence3_ex2 = 0
replace dig_presence3_ex2= 1 if strpos(Surlesquellesdesmarketplaces, "r2")

g dig_presence3_ex3 = 0
replace dig_presence3_ex3= 1 if strpos(Surlesquellesdesmarketplaces, "r3")

g dig_presence3_ex4 = 0
replace dig_presence3_ex4= 1 if strpos(Surlesquellesdesmarketplaces, "r4")

g dig_presence3_ex5 = 0
replace dig_presence3_ex5= 1 if strpos(Surlesquellesdesmarketplaces, "r5")

g dig_presence3_ex6 = 0
replace dig_presence3_ex6= 1 if strpos(Surlesquellesdesmarketplaces, "r6")

g dig_presence3_ex7 = 0
replace dig_presence3_ex7= 1 if strpos(Surlesquellesdesmarketplaces, "r7")

g dig_presence3_ex8 = 0
replace dig_presence3_ex8= 1 if strpos(Surlesquellesdesmarketplaces, "r8")

g dig_presence3_exnsp = 0
replace dig_presence3_exnsp= 1 if strpos(Surlesquellesdesmarketplaces, "-999")



* dig_miseajour1

local vars_misea dig_miseajour2 dig_miseajour1 dig_miseajour3

foreach var of local vars_misea {
	replace `var' = "0" if `var' == "jamais / أبدا"
	replace `var' = "0.25" if `var' == "annuellement / سنويا"
	replace `var' = "0.5" if `var' == "mensuellement / شهريا"
	replace `var' = "0.75" if `var' == "hebdomadairement / أسبوعيا"
	replace `var' = "1" if `var' == "plus qu'une fois par semaine / أكثر من مرة في الأسبوع"
	destring `var', replace
	} 
	
* dig_payment
local vars_payments dig_payment1 dig_payment2 dig_payment3

foreach var of local vars_payments {
	replace `var' = "0.5" if `var' == "seulement commander en ligne, mais le paiement se fait par d'autres moyens (virement, mandat postal, cash-on-delivery...)  / تكمندي منو فقط وتخلص بوسائل أخرى"
	replace `var' = "1" if `var' == "commander et payer en ligne /  تكمندي وتخلص منو"
	replace `var' = "0" if `var' == "ni commander ni payer en ligne / لا تكمندي لا تخلص"
	destring `var', replace
}

***********************************************************************
* 	PART 2: 	Drop all unneeded columns and rows from the survey		  			
***********************************************************************

*drop VARNAMES

drop dig_con2 dig_con6 Surlesquellesdesmarketplaces dig_marketing_num19 dig_con4 dig_logistique_retour 

drop if Id_plateforme==.

* 	Drop incomplete entries

gen complete = 0 

replace complete = 1 if attest ==1 | attest2 ==1 |  Acceptezvousdevalidervosré ==1 

// keep if complete == 1

// drop complete
*/
***********************************************************************
* 	PART 3: 	Make all variables names lower case		  			
***********************************************************************
rename *, lower

***********************************************************************
* 	PART 4: 	Order the variables in the data set		  			
***********************************************************************
/*
order id_plateforme heure date attest attest2 acceptezvousdevalidervosré survey_type


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
lab var inno_aucune "no innovation"
lab var inno_mot_idee "personal idea"
lab var inno_mot_conc "exchange ideas with a competitor"
lab var inno_mot_cons "exchange ideas with a consultant"
lab var inno_mot_cont "exchange ideas with business network"
lab var inno_mot_eve "exchange ideas in an event"
lab var inno_mot_emp "exchnage ideas with employees"
lab var inno_mot_test "test"
lab var inno_mot_autre "other"
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

		* Section marketing practices
lab var man_mark_prix  "study the prices and/or products of one of competitors"
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
lab var comptable_numero "phone number of accountant" 
lab var comptable_email "email of accountant"
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
lab var att_strat1 "participant don't have an export strategy. She would adopt that of the consortium"
lab var att_strat2 "the consortium's strategy must be consistent with her own strategy"
lab var att_strat3 "the company has an export strategy and the consortium is a vector for certain actions"
lab var att_strat4 "other"
lab var att_cont1 "no contribution"
lab var att_cont2 "fixed, lump sum contribution"
lab var att_cont3 "proportional contribution to the turnover"
lab var att_cont4 "proportional contribution to the turnover achieved at export"
lab var att_cont5 "other"
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
lab var support2 "organize virtual meetings (zoom or skype)"
lab var support3 "change the meeting place"
lab var support4 "adopt a time slot before or after the regular working day"
lab var support5 "offer free childcare during consortia meetings"
lab var support6 "provide financial support for transportation and accommodation"
lab var support7 "other"

		* Section contact & validation
lab var tel_supl "other phone number"
lab var attest "validation"

}
***********************************************************************
* 	PART 7: 	Label the variables values	  			
***********************************************************************


local yesnovariables ident ident2 man_fin_profit man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci    ///
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
/*
***********************************************************************
* 	PART 8: Removing trail and leading spaces in from string variables  			
***********************************************************************
* Creating global according to the variable type
global varstring info_compt2 exp_afrique_principal exp_pays_principal_21 car_attend1 car_attend2 car_attend3 exp_produit_services_avant21 exp_produit_services21 entr_histoire entr_bien_service entr_produit1 entr_produit2 entr_produit3 dig_presence3_exemples_autres investcom_benefit3_1 investcom_benefit3_2 investcom_benefit3_3 expprep_norme2
global numvars info_compt1 dig_revenues_ecom comp_benefice2020 comp_ca2020 compexp_2020 tel_sup2 tel_sup1 car_carempl_div1 car_carempl_dive2 car_carempl_div3 dig_marketing_respons investcom_futur investcom_2021 expprep_responsable exp_pays_avant21 exp_pays_principal_avant21 exp_pays_21


{
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
replace `x' = stritrim(strtrim(`x'))
}
}

*/
***********************************************************************
* 	Part 9: Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
