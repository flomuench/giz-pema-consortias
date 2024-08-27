***********************************************************************
* 			midline generate									  	  
***********************************************************************
*																	    
*	PURPOSE: generate midline variables				  							  
*																	  
*																	  
*	OUTLINE:			
*	1) Import data & generate surveyround										  
*	1) Additional calculated variables
* 	3) Indices
*
*																	  															      
*	Author:  	Ayoub Chamakhi, Kais Jomaa, Amina Bousnina		 												  
*	ID variaregise: 	id_plateforme 			  					  
*	Requires: ml_intermediate.dta 	  								  
*	Creates:  ml_final.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Import data 			
***********************************************************************

use "${ml_intermediate}/ml_intermediate", clear

***********************************************************************
* 	PART 2:  Generate survey round dummy
***********************************************************************
gen surveyround = 2
lab var surveyround "1-baseline 2-midline 3-endline"

***********************************************************************
* 	PART 3:  Create continuous variable for number of innovation
*********************************************************************** 
generate num_inno = inno_produit +inno_process + inno_lieu + inno_commerce
label var num_inno "Number of different types innovation introduced by a firm"

generate inno_aucune = 0
replace inno_aucune = 1 if inno_produit == 0 & inno_process == 0 & inno_lieu == 0 & inno_commerce == 0
label var inno_aucune "No innovation done"

***********************************************************************
* 	PART 4:  inno_mot
***********************************************************************
	* gen dummies for each innovation motivation category
generate inno_mot1 = regexm(inno_mot, "inno_mot_idee")
generate inno_mot2 = regexm(inno_mot, "inno_mot_cons")
generate inno_mot3 = regexm(inno_mot, "inno_mot_cont")
generate inno_mot4 = regexm(inno_mot, "inno_mot_eve")
generate inno_mot5 = regexm(inno_mot, "inno_mot_emp")
generate inno_mot6 = regexm(inno_mot, "inno_mot_test")
generate inno_mot7 = regexm(inno_mot, "inno_mot_autre")

	* lab each dummy/motivation category
label var inno_mot1 "personal idea"
label var inno_mot2 "exchange ideas with a consultant"
label var inno_mot3 "exchange ideas with business network"
label var inno_mot4 "exchange ideas in an event"
label var inno_mot5 "exchange ideas with employees"
label var inno_mot6 "Norms"
label var inno_mot7 "other source for innovation"

foreach var of varlist inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7 {
replace `var' =. if inno_mot=="" 
}

	* label the values of each dummy/motivation category + numeric format 
local inno_vars inno_mot1 inno_mot2 inno_mot3 inno_mot4 inno_mot5 inno_mot6 inno_mot7 
foreach x of local inno_vars {
	lab val `x' yesno
	destring `x', replace
	format `x' %25.0fc
}


***********************************************************************
* 	PART 5:  man_source
***********************************************************************
	* gen dummies for each new management strategy source
generate man_source1 = regexm(man_source, "1")
generate man_source2=  regexm(man_source, "2")
generate man_source3 = regexm(man_source, "3")
generate man_source4 = regexm(man_source, "4")
generate man_source5 = regexm(man_source, "5")
generate man_source6 = regexm(man_source, "6")
generate man_source7 = regexm(man_source, "7")

	* lab each dummy/motivation category
label var man_source1 "Consultant"
label var man_source2 "Business contact"
label var man_source3 "Employees"
label var man_source4 "Family"
label var man_source5 "Event"
label var man_source6 "No new strategy"
label var man_source7 "Other sources"

foreach var of varlist man_source1 man_source2 man_source3 man_source4 man_source5 man_source6 man_source7 {
replace `var' =. if man_source=="" 
}

	* label the values of each dummy/motivation category + numeric format 
local man_vars man_source1 man_source2 man_source3 man_source4 man_source5 man_source6 man_source7 
foreach x of local man_vars {
	lab val `x' yesno
	destring `x', replace
	format `x' %25.0fc
}

***********************************************************************
* 	PART 6: net_coop
***********************************************************************
	* generate dummies for each cooperative word
generate netcoop1 = regexm(net_coop, "1")
generate netcoop2 = regexm(net_coop, "2")
generate netcoop3 = regexm(net_coop, "3")
generate netcoop4 = regexm(net_coop, "4")
generate netcoop5 = regexm(net_coop, "5")
generate netcoop6 = regexm(net_coop, "6")
generate netcoop7 = regexm(net_coop, "7")
generate netcoop8 = regexm(net_coop, "8")
generate netcoop9 = regexm(net_coop, "9")
generate netcoop10 = regexm(net_coop, "10")

	* lab each cooperate word dummy
label var netcoop1 "Win"
label var netcoop2 "Communicate"
label var netcoop3 "Trust"
label var netcoop4 "Beat"
label var netcoop5 "Power"
label var netcoop6 "Retreat"
label var netcoop7 "Partnership" 
label var netcoop8 "Opponent"
label var netcoop9 "Connect" 
label var netcoop10 "Dominate"

foreach var of varlist netcoop1 netcoop2 netcoop3 netcoop4 netcoop5 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10 {
replace `var' =. if net_coop=="" 
}

	* generate a count of positive & negative cooperative words
generate net_coop_pos = netcoop1 + netcoop2 + netcoop3 + netcoop7 + netcoop9
label var net_coop_pos "Positive answers for the the perception of interactions between CEOs" 
generate net_coop_neg = netcoop4 + netcoop5 + netcoop6 + netcoop8 + netcoop10
label var net_coop_neg "Negative answers for the the perception of interactions between CEOs" 


***********************************************************************
* 	PART 7: Time to complete survey (limited insight given we only see most recent attempt)
***********************************************************************
/*
format date %td
replace heuredébut = ustrregexra( heuredébut ,"h",":")
replace heuredébut = ustrregexra( heuredébut ,"`",":")
replace heuredébut = substr(heuredébut,1,length(heuredébut)-2)
str2time heuredébut, generate(eheuredébut)

replace heurefin = ustrregexra( heurefin ,"h",":")
replace heurefin = ustrregexra( heurefin ,"`",":")
replace heurefin = substr(heurefin,1,length(heurefin)-2)
str2time heurefin, generate(eheurefin)

* Creation of the time variable
gen etime = eheurefin - eheuredébut
gen etime_positive = abs(etime)
time2str etime_positive, generate(time) seconds
label var time "durée du questionnaire par entreprise"

gen str8 stime = time
gen shours = substr(stime, 1, 2) //takes the first two digits//
gen hours = real(shour) //reads first two digits as number
gen sminutes = substr(stime, 4, 2)
gen minutes = real(sminutes)
gen sseconds = substr(stime, 7, 2)
gen seconds = real(sseconds)
gen time_secs = 3600*hours + 60*minutes + seconds
gen time_mins = time_secs/60
label var time_secs "Durée du questionnaire par entreprise en secondes"
label var time_mins "Durée du questionnaire par entreprise en minutes"

drop etime etime_positive eheuredébut eheurefin shours sminutes minutes sseconds seconds stime
*/

***********************************************************************
* 	PART 8: Generate variable to assess number of missing values per firm			  										  
***********************************************************************
	* section 1: innovation
egen miss_inno = rowmiss(inno_produit inno_process inno_lieu inno_commerce inno_mot)
	
	* section 2: network
egen miss_network = rowmiss(net_nb_f net_nb_m net_nb_qualite net_coop)
	
	* section 3: management practices
egen miss_management = rowmiss(man_fin_num man_fin_per_fre man_hr_ind man_hr_pro man_ind_awa man_source)

	* section 4: export readiness
egen miss_eri = rowmiss(exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_inv exprep_couts)
	
	* section 5: gender empowerment
egen miss_gender = rowmiss(car_efi_fin1 car_efi_nego car_efi_conv car_loc_succ car_loc_env listexp)
	
	* section 6: accounting/KPI
egen miss_accounting = rowmiss(employes car_empl1 car_empl2 car_empl3 car_empl4 ca ca_exp profit)

	* section 7: SSA export readiness
egen miss_eri_ssa = rowmiss(ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5)

	* create the sum of missing values per company
gen missing_values = miss_inno + miss_network + miss_management + miss_eri + miss_gender + miss_accounting
lab var missing_values "missing values per company"


***********************************************************************
* 	PART 9: Generate variable to assess completed answers		  										  
***********************************************************************
generate survey_completed= 0
replace survey_completed= 1 if missing_values == 0
label var survey_completed "Number of firms which fully completed the survey"
label values survey_completed yesno


***********************************************************************
* 	PART 10:  Generate variables for companies who answered on phone	
***********************************************************************
gen survey_phone = 0
lab var survey_phone "Comapnies who answered the survey on phone (with enumerators)" 
replace survey_phone = 1 if id_plateforme == 1005
replace survey_phone = 1 if id_plateforme == 1007
replace survey_phone = 1 if id_plateforme == 1027
replace survey_phone = 1 if id_plateforme == 1030
replace survey_phone = 1 if id_plateforme == 1041
replace survey_phone = 1 if id_plateforme == 1054
replace survey_phone = 1 if id_plateforme == 1065
replace survey_phone = 1 if id_plateforme == 1083
replace survey_phone = 1 if id_plateforme == 1116
replace survey_phone = 1 if id_plateforme == 1133
replace survey_phone = 1 if id_plateforme == 1151
replace survey_phone = 1 if id_plateforme == 1157
replace survey_phone = 1 if id_plateforme == 1185
replace survey_phone = 1 if id_plateforme == 1195
replace survey_phone = 1 if id_plateforme == 1197
replace survey_phone = 1 if id_plateforme == 1215
replace survey_phone = 1 if id_plateforme == 1224
replace survey_phone = 1 if id_plateforme == 1239
replace survey_phone = 1 if id_plateforme == 51
replace survey_phone = 1 if id_plateforme == 1132 
replace survey_phone = 1 if id_plateforme == 1094 
replace survey_phone = 1 if id_plateforme == 1025
replace survey_phone = 1 if id_plateforme == 1090 
replace survey_phone = 1 if id_plateforme == 1044
replace survey_phone = 1 if id_plateforme == 1140
replace survey_phone = 1 if id_plateforme == 1147
replace survey_phone = 1 if id_plateforme == 1188
replace survey_phone = 1 if id_plateforme == 48
replace survey_phone = 1 if id_plateforme == 1245 
replace survey_phone = 1 if id_plateforme == 1061 
replace survey_phone = 1 if id_plateforme == 1079
replace survey_phone = 1 if id_plateforme == 997
replace survey_phone = 1 if id_plateforme == 1176
replace survey_phone = 1 if id_plateforme == 1067
replace survey_phone = 1 if id_plateforme == 1033
replace survey_phone = 1 if id_plateforme == 1205
replace survey_phone = 1 if id_plateforme == 1244
replace survey_phone = 1 if id_plateforme == 1037
replace survey_phone = 1 if id_plateforme == 1045
replace survey_phone = 1 if id_plateforme == 1081
replace survey_phone = 1 if id_plateforme == 1117
replace survey_phone = 1 if id_plateforme == 1125
replace survey_phone = 1 if id_plateforme == 1135
replace survey_phone = 1 if id_plateforme == 1150
replace survey_phone = 1 if id_plateforme == 983
replace survey_phone = 1 if id_plateforme == 985
replace survey_phone = 1 if id_plateforme == 1001
replace survey_phone = 1 if id_plateforme == 1017
replace survey_phone = 1 if id_plateforme == 1019
replace survey_phone = 1 if id_plateforme == 1167
replace survey_phone = 1 if id_plateforme == 1182
replace survey_phone = 1 if id_plateforme == 1084
replace survey_phone = 1 if id_plateforme == 1125
replace survey_phone = 1 if id_plateforme == 989
replace survey_phone = 1 if id_plateforme == 988
replace survey_phone = 1 if id_plateforme == 1035
replace survey_phone = 1 if id_plateforme == 1231
replace survey_phone = 1 if id_plateforme == 1046
replace survey_phone = 1 if id_plateforme == 1050
replace survey_phone = 1 if id_plateforme == 1069
replace survey_phone = 1 if id_plateforme == 1008
replace survey_phone = 1 if id_plateforme == 1159
replace survey_phone = 1 if id_plateforme == 1204
replace survey_phone = 1 if id_plateforme == 1028
replace survey_phone = 1 if id_plateforme == 1161
replace survey_phone = 1 if id_plateforme == 1248
replace survey_phone = 1 if id_plateforme == 1203
replace survey_phone = 1 if id_plateforme == 1225
replace survey_phone = 1 if id_plateforme == 1230
replace survey_phone = 1 if id_plateforme == 1071
replace survey_phone = 1 if id_plateforme == 1170
replace survey_phone = 1 if id_plateforme == 1186
replace survey_phone = 1 if id_plateforme == 996
replace survey_phone = 1 if id_plateforme == 1092
replace survey_phone = 1 if id_plateforme == 1163
replace survey_phone = 1 if id_plateforme == 1171
replace survey_phone = 1 if id_plateforme == 1049
replace survey_phone = 1 if id_plateforme == 1087
replace survey_phone = 1 if id_plateforme == 1201
replace survey_phone = 1 if id_plateforme == 1213
replace survey_phone = 1 if id_plateforme == 1190
replace survey_phone = 1 if id_plateforme == 1222
replace survey_phone = 1 if id_plateforme == 1013
replace survey_phone = 1 if id_plateforme == 1146
replace survey_phone = 1 if id_plateforme == 1123
replace survey_phone = 1 if id_plateforme == 1210
replace survey_phone = 1 if id_plateforme == 1175
replace survey_phone = 1 if id_plateforme == 1179
replace survey_phone = 1 if id_plateforme == 1218
replace survey_phone = 1 if id_plateforme == 1138 
replace survey_phone = 1 if id_plateforme == 986 
replace survey_phone = 1 if id_plateforme == 1233  
replace survey_phone = 1 if id_plateforme == 1138  
replace survey_phone = 1 if id_plateforme == 1196  
replace survey_phone = 1 if id_plateforme == 1233  
replace survey_phone = 1 if id_plateforme == 1241  

label define Surveytype 1 "Phone" 0 "Online"
label values survey_phone Surveytype



***********************************************************************
* 	PART 9: save dta file  										  
***********************************************************************
save "${ml_final}/ml_final", replace
