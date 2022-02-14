***********************************************************************
* 			registration corrections									  	  
***********************************************************************
*																	    
*	PURPOSE: correct all incoherent responses				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Define non-response categories 			  				  
* 	2) 		correct unique identifier - matricule fiscal
*	3)   	Replace string with numeric values						  
*	4)  	Convert string to numerical variaregises	  				  
*	5)  	Convert proregisematic values for open-ended questions		  
*	6)  	Traduction reponses en arabe au francais				  
*   7)      Rename and homogenize the observed values                   
*	8)		Import categorisation for opend ended QI questions
*	9)		Remove duplicates
*
*																	  															      
*	Author:  	Florian Muench & Kais Jomaa							  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta 	  								  
*	Creates:  regis_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Define non-response categories  			
***********************************************************************
use "${regis_intermediate}/regis_inter", clear

{
	* replace "-" with missing value
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
		replace `x' = "" if `x' == "-"
	}
* scalar: numerical variables & local: string variables	
scalar not_know    = 77777777777777777
scalar refused     = 99999999999999999
scalar check_again = 88888888888888888
scalar not_applicable = 66666666666666666

local not_know    = 77777777777777777
local refused     = 99999999999999999
local check_again = 88888888888888888
local not_applicable = 66666666666666666
local en_cours  = 5555555555555


	* replace, gen, label
	
*/
}
gen needs_check = 0
gen questions_needing_check = ""

***********************************************************************
* 	PART 2: use regular expressions to correct variables 		  			
***********************************************************************

* Nombre d'employés dans l'entreprise 
* le nombre d'employes féminin dans l'entreprise doit être inférieur au nombre d'employés total.

replace rg_fte_femmes = 88888888888888888 if rg_fte < rg_fte_femmes


        * Matricule fiscale de l'entreprise:

replace id_admin = ustrregexra( id_admin ,"/","")
replace id_admin = ustrregexra( id_admin ," ","")


		* gen dummy if matricule fiscal is correct: 7 digit, 1 character condition
gen id_admin_correct = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")
order id_admin_correct, a(id_admin)
lab def correct 1 "correct" 0 "incorrect"
lab val id_admin_correct correct


    *correct code de la douane


replace rg_codedouane = ustrregexra(rg_codedouane," ","")
replace rg_codedouane = "1435318s" if rg_codedouane == "1435318/s"
replace rg_codedouane = "1269807b" if rg_codedouane == "1269807/b"
replace rg_codedouane = "" if rg_codedouane == "gr"
replace rg_codedouane = "" if rg_codedouane == "pasencore"

	* correct telephone numbers with regular expressions
		* representative
replace rg_telrep = ustrregexra(rg_telrep, "^216", "")
replace rg_telrep = ustrregexra( rg_telrep,"[a-z]","")
replace rg_telrep = ustrregexra( rg_telrep," ","")
replace rg_telrep = ustrregexra( rg_telrep,"00216","")
replace rg_telrep = ustrregexra( rg_telrep, "^[\+]216", "")
replace rg_telrep = subinstr(rg_telrep, " ", "", .)
replace rg_telrep = "29530240" if rg_telrep == "(+216)29530240"
replace rg_telrep = "55507179" if rg_telpdg == "555071179"

	* Vérifier nom et prénom du representant*
replace rg_nom_rep = ustrlower(rg_nom_rep)
replace rg_nom_rep = "Hermassi Dorra" if  rg_nom_rep=="1724949/e"
replace rg_nom_rep = "fathia errouki" if  rg_nom_rep=="fathia errouki import-export"
replace rg_nom_rep = "hana youssef" if  rg_nom_rep=="هناء يوسف"

	* Téléphone du de lagérante

replace rg_telpdg = ustrregexra( rg_telpdg, "^216", "")
replace rg_telpdg = subinstr(rg_telpdg, " ", "", .)
replace rg_telpdg = ustrregexra( rg_telpdg,"[a-z]","")
replace rg_telpdg = ustrregexra( rg_telpdg,"00216","")
replace rg_telpdg = ustrregexra( rg_telpdg, "^[\+]216", "")
replace rg_telpdg = subinstr(rg_telpdg, " ", "", .)
replace rg_telpdg = "52710565" if rg_telpdg == "(+216)52710565"


	* variable: Qualité/fonction

replace rg_position_rep = ustrlower(rg_position_rep)
replace rg_position_rep = "directrice" if rg_position_rep == "dirctrice"

/*
replace rg_position_repcor = "$check_again" if rg_position_rep == "group task 6 - peer to peer group wee"

*/
replace rg_position_rep = "gérante" if rg_position_rep == "gerant"
replace rg_position_rep = "gérante" if rg_position_rep == "gerante"
replace rg_position_rep = "gérante" if rg_position_rep == "gérant"
replace rg_position_rep = "gérante" if rg_position_rep == "gérant e"
replace rg_position_rep = "coo" if rg_position_rep == "c.o.o"
replace rg_position_rep = "artisane" if rg_position_rep == "artisan"
replace rg_position_rep = "artisane" if rg_position_rep == "artisanne"
replace rg_position_rep = "artisane" if rg_position_rep == "artisante"



	* variable: Matricule CNSS

replace rg_matricule = ustrregexra(rg_matricule, "[ ]", "")
replace rg_matricule = ustrregexra(rg_matricule, "[/]", "-")
replace rg_matricule = ustrregexra(rg_matricule, "[_]", "-")

		* Format CNSS Number:
gen t1 = ustrregexs(0) if ustrregexm(rg_matricule, "\d{8}")
gen t2 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9][0-9][0-9][0-9][0-9]")
gen t3 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9]$") 
gen t4 = t2 + "-" + t3
replace t4 = ustrregexra(t4, "[-]", "") if length(t4)==1
replace rg_matricule = t4 if length(rg_matricule)==8
drop t1 t2 t3 t4 

		* Format CNRPS Number:

gen t1 = ustrregexs(0) if ustrregexm(rg_matricule, "\d{10}")
gen t2 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]")
gen t3 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9]$") 
gen t4 = t2 + "-" + t3
replace t4 = ustrregexra(t4, "[-]", "") if length(t4)==1
replace rg_matricule = t4 if length(rg_matricule)==10
drop t1 t2 t3 t4  
replace rg_matricule = "" if rg_matricule == "xxx"
replace rg_matricule = "" if rg_matricule == "pasencore"

		* Nom de l'entreprise:
replace firmname = "cœur du moulin" if firmname== "afef graa"
replace firmname = "ines messaoudi" if firmname== "gérante"
replace firmname = "atmosphere interieure" if id_plateforme== 1100
replace firmname = "" if id_plateforme== 1217
replace firmname = "kaouther mejdi" if firmname== "كوثر الماجدي"
replace firmname = "top management" if  id_plateforme == 1049
replace firmname = "archivart" if  id_plateforme == 1057


		* Adresse de l'entreprise:
replace rg_adresse = ustrlower(rg_adresse) 
replace rg_adresse = "rue jaber ibn hayen, bhar lazreg  la marsa, tunis 2046" if id_plateforme == 1151
replace rg_adresse = "" if id_plateforme == 995
replace rg_adresse = "rue n. 290 mohi al-din alklibi almanar 2" if rg_adresse == "عدد 290 نهج محي الدين القليبي المنار 2"

        * Site web de l'entreprise:


replace rg_siteweb = ustrregexra( rg_siteweb ,"https://","")
replace rg_siteweb = ustrregexra( rg_siteweb ,"/","")
replace rg_siteweb = ustrregexra( rg_siteweb ,"http:","")
replace rg_siteweb = ustrregexra( rg_siteweb ,"www.","")

replace rg_siteweb = "`en_cours'" if rg_siteweb=="en cours"
replace rg_siteweb = "`en_cours'" if rg_siteweb=="en cours de construction"
replace rg_siteweb = "`en_cours'" if rg_siteweb=="en cours de réalisation"
replace rg_siteweb = "https://www.agritable.tn/" if id_plateforme == 1151
replace rg_siteweb = "" if id_plateforme == 1193
replace rg_siteweb = "" if id_plateforme == 992
replace rg_siteweb = "" if id_plateforme == 996
replace rg_siteweb = "" if id_plateforme == 1036
replace rg_siteweb = "" if id_plateforme == 1181
replace rg_siteweb = "" if id_plateforme == 1209
replace rg_siteweb = "" if id_plateforme == 1159
replace rg_siteweb = "" if id_plateforme == 1108


/*
foreach x in ca_ {
replace `x'2018 = `not_applicable' if date_created > td(31dec2018) & date_created != .
replace `x'2019 = `not_applicable' if date_created > td(31dec2019) & date_created != .
replace `x'2020 = `not_applicable' if date_created > td(31dec2020) & date_created != .
}
*/

			* browse for CA == 0
*br id_plateform etat ca_???? if ca_exp2018==0 & ca_exp2019==0 & ca_exp2020==0
*br id_plateform etat ca_???? if ca_2018==0  & ca_2019==0 & ca_2020==0

			* browse for ca_exp > ca_2018
*br id_plateform etat if ca_exp2018 > ca_2018
*br id_plateform etat if ca_exp2019 > ca_2019
*br id_plateform etat if ca_exp2020 > ca_2020

			* browse capital <= 1000
*br id_plateform etat rg_capital if rg_capital <= 1000

 *Réseau  social de l'entreprise:

replace rg_media = "facebook.comzina.boughdiri" if id_plateforme == 1193
replace rg_media = "https://www.facebook.com/tinhinansac/   &   https://www.instagram.com/tin_hinan.tn/" if id_plateforme == 996
replace rg_media = "https://www.facebook.com/profile.php?id=100054933390120" if id_plateforme == 1036
replace rg_media = "https://www.facebook.com/Rissala.Kids.Farm/" if rg_media == "rissala kids farm"
replace rg_media = "https://www.facebook.com/tresors.naturels.tunisie/" if rg_media == "laboratoire trésors naturels"
replace rg_media = "https://www.facebook.com/aabacti/" if rg_media == "bacteriolab"
replace rg_media = "https://www.facebook.com/halfawin/" if rg_media == "www,facebook,com/halfawin,7"
replace rg_media = "Sonya Flowers.tn " if id_plateforme == 1108
replace rg_media = "`en_cours'" if rg_media == "en cours"
replace rg_media = "`en_cours'" if rg_media == "en cours de construction"
replace rg_media = ustrregexra( rg_media ,"https://","")
replace rg_media = ustrregexra( rg_media ,"http:","")


       * Capital social de l'entreprise


***********************************************************************
* 	PART 3:  Check again variables	  			
**************************************************************
replace questions_needing_check = "firmname" if id_plateforme == 987
replace needs_check = 1 if id_plateforme == 987
replace questions_needing_check = "rg_capital" if id_plateforme == 990
replace needs_check = 1 if id_plateforme == 990
replace questions_needing_check = "le chiffre d'affaire export est supérieur au chiffre d'affaire total" if id_plateforme == 992
replace needs_check = 1 if id_plateforme == 992
replace questions_needing_check = "rg_capital" if id_plateforme == 993
replace needs_check = 1 if id_plateforme == 993
replace questions_needing_check = "rg_adresse" if id_plateforme == 995
replace needs_check = 1 if id_plateforme == 995 
replace questions_needing_check = "rg_codedouane" if id_plateforme == 1002
replace needs_check = 1 if id_plateforme == 1002
replace questions_needing_check = "firmname" if id_plateforme == 1003
replace needs_check = 1 if id_plateforme == 1003
replace questions_needing_check = "rg_capital" if id_plateforme == 1005
replace needs_check = 1 if id_plateforme == 1005
replace questions_needing_check = "rg_nom_rep" if id_plateforme == 1008
replace needs_check = 1 if id_plateforme == 1008
replace questions_needing_check = "rg_capital/id_admin" if id_plateforme == 1013
replace needs_check = 1 if id_plateforme == 1013
replace questions_needing_check = "firmname" if id_plateforme == 1019
replace needs_check = 1 if id_plateforme == 1019
replace questions_needing_check = "rg_capital" if id_plateforme == 1020
replace needs_check = 1 if id_plateforme == 1020
replace questions_needing_check = "rg_siteweb" if id_plateforme == 1021
replace needs_check = 1 if id_plateforme == 1021
replace questions_needing_check = "rg_siteweb" if id_plateforme == 1030
replace needs_check = 1 if id_plateforme == 1030
replace questions_needing_check = "rg_capital" if id_plateforme == 1031
replace needs_check = 1 if id_plateforme == 1031
replace questions_needing_check = "rg_capital" if id_plateforme == 1032
replace needs_check = 1 if id_plateforme == 1032
replace questions_needing_check = "rg_media" if id_plateforme == 1034
replace needs_check = 1 if id_plateforme == 1034
replace questions_needing_check = "rg_capital" if id_plateforme == 1035
replace needs_check = 1 if id_plateforme == 1035
replace questions_needing_check = "rg_siteweb/firmname" if id_plateforme == 1036
replace needs_check = 1 if id_plateforme == 1036
replace questions_needing_check = "rg_capital/rg_siteweb/rg_telrep/rg_telpdg" if id_plateforme == 1037
replace needs_check = 1 if id_plateforme == 1037
replace questions_needing_check = "firmname/id_admin" if id_plateforme == 1039
replace needs_check = 1 if id_plateforme == 1039
replace questions_needing_check = "firmname" if id_plateforme == 1041
replace needs_check = 1 if id_plateforme == 1041
replace questions_needing_check = "rg_capital" if id_plateforme == 1043
replace needs_check = 1 if id_plateforme == 1043
replace questions_needing_check = "le chiffre d'affaire export est supérieur au chiffre d'affaire total" if id_plateforme == 1044
replace needs_check = 1 if id_plateforme == 1044
replace questions_needing_check = "firmname" if id_plateforme == 1049
replace needs_check = 1 if id_plateforme == 1049
replace questions_needing_check = "firmname" if id_plateforme == 1054
replace needs_check = 1 if id_plateforme == 1054
replace questions_needing_check = "firmname" if id_plateforme == 1057
replace needs_check = 1 if id_plateforme == 1057
replace questions_needing_check = "rg_capital" if id_plateforme == 1063
replace needs_check = 1 if id_plateforme == 1063
replace questions_needing_check = "rg_capital" if id_plateforme == 1068
replace needs_check = 1 if id_plateforme == 1068
replace questions_needing_check = "rg_siteweb" if id_plateforme == 1071
replace needs_check = 1 if id_plateforme == 1071
replace questions_needing_check = "rg_capital/le chiffre d'affaire export est supérieur au chiffre d'affaire total" if id_plateforme == 1073
replace needs_check = 1 if id_plateforme == 1073
replace questions_needing_check = "rg_capital" if id_plateforme == 1074
replace needs_check = 1 if id_plateforme == 1074
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1075
replace needs_check = 1 if id_plateforme == 1075
replace questions_needing_check = "rg_telrep" if id_plateforme == 1079
replace needs_check = 1 if id_plateforme == 1079
replace questions_needing_check = "firmname" if id_plateforme == 1080
replace needs_check = 1 if id_plateforme == 1080
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1083
replace needs_check = 1 if id_plateforme == 1083
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1085
replace needs_check = 1 if id_plateforme == 1085
replace questions_needing_check = "rg_siteweb/id_admin" if id_plateforme == 1091
replace needs_check = 1 if id_plateforme == 1091
replace questions_needing_check = "id_admin" if id_plateforme == 1092
replace needs_check = 1 if id_plateforme == 1092
replace questions_needing_check = "rg_media/id_admin" if id_plateforme == 1094
replace needs_check = 1 if id_plateforme == 1094
replace questions_needing_check = "id_admin" if id_plateforme == 1095
replace needs_check = 1 if id_plateforme == 1095
replace questions_needing_check = "id_admin" if id_plateforme == 1105
replace needs_check = 1 if id_plateforme == 1105
replace questions_needing_check = "rg_capital" if id_plateforme == 1108
replace needs_check = 1 if id_plateforme == 1108
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1112
replace needs_check = 1 if id_plateforme == 1112
replace questions_needing_check = "le chiffre d'affaire export est supérieur au chiffre d'affaire total" if id_plateforme == 1114
replace needs_check = 1 if id_plateforme == 1114
replace questions_needing_check = "id_admin/rg_codedouane/rg_matricule" if id_plateforme == 1124
replace needs_check = 1 if id_plateforme == 1124
replace questions_needing_check = "rg_telpdg" if id_plateforme == 1129
replace needs_check = 1 if id_plateforme == 1129
replace questions_needing_check = "rg_telrep/rg_telpdg/rg_capital" if id_plateforme == 1133
replace needs_check = 1 if id_plateforme == 1133
replace questions_needing_check = "rg_capital" if id_plateforme == 1140
replace needs_check = 1 if id_plateforme == 1140
replace questions_needing_check = "rg_capital" if id_plateforme == 1143
replace needs_check = 1 if id_plateforme == 1143
replace questions_needing_check = "rg_capital" if id_plateforme == 1145
replace needs_check = 1 if id_plateforme == 1145
replace questions_needing_check = "rg_siteweb" if id_plateforme == 1151
replace needs_check = 1 if id_plateforme == 1151
replace questions_needing_check = "rg_capital" if id_plateforme == 1155
replace needs_check = 1 if id_plateforme == 1155
replace questions_needing_check = "rg_capital" if id_plateforme == 1174
replace needs_check = 1 if id_plateforme == 1174
replace questions_needing_check = "rg_capital" if id_plateforme == 1175
replace needs_check = 1 if id_plateforme == 1175
replace questions_needing_check = "identifiant unique / code douane" if id_plateforme == 1185
replace needs_check = 1 if id_plateforme == 1185
replace questions_needing_check = "rg_capital" if id_plateforme == 1193
replace needs_check = 1 if id_plateforme == 1193
replace questions_needing_check = "rg_capital" if id_plateforme == 1197
replace needs_check = 1 if id_plateforme == 1197
replace questions_needing_check = "rg_capital" if id_plateforme == 1198
replace needs_check = 1 if id_plateforme == 1198
replace questions_needing_check = "rg_capital" if id_plateforme == 1220
replace needs_check = 1 if id_plateforme == 1220
replace questions_needing_check = "rg_capital" if id_plateforme == 1221
replace needs_check = 1 if id_plateforme == 1221
replace questions_needing_check = "rg_matricule/ code_douane/ identifiant unique" if id_plateforme == 1224
replace needs_check = 1 if id_plateforme == 1224
replace questions_needing_check = "rg_matricule/ code_douane/ identifiant unique" if id_plateforme == 1226
replace needs_check = 1 if id_plateforme == 1226
replace questions_needing_check = "rg_capital" if id_plateforme == 1227
replace needs_check = 1 if id_plateforme == 1227
replace questions_needing_check = "rg_capital" if id_plateforme == 1231
replace needs_check = 1 if id_plateforme == 1231
replace questions_needing_check = "rg_capital" if id_plateforme == 1236
replace needs_check = 1 if id_plateforme == 1236
replace questions_needing_check = "rg_capital" if id_plateforme == 1242
replace needs_check = 1 if id_plateforme == 1242
replace questions_needing_check = "rg_capital" if id_plateforme == 1244
replace needs_check = 1 if id_plateforme == 1244

***********************************************************************
* 	PART 3:  Replace string with numeric values		  			
***********************************************************************
{

/*
* br id_plateforme if rg_capital < 300

         *Test logical values*

* In Tunisia, SCA and SA must have a minimum of 5000 TND of capital social

*All values having a too small capital social (less than 100)
replace rg_capital = "`check_again'" if rg_capital == "0"
replace rg_capital = "`check_again'" if rg_capital == "o"


*/

}
***********************************************************************
* 	PART 4:  Convert string to numerical variaregises	  			
***********************************************************************

local destrvar "rg_fte rg_fte_femmes id_plateforme ca_2018 ca_2019 ca_2020 ca_exp2018 ca_exp2019 ca_exp2020 rg_capital"
foreach x of local destrvar { 
destring `x', replace
}

       * chiffre d'affaire
			* replace CA not applicable if company has been created after 
foreach x in ca_exp ca_ {
replace `x'2018 = not_applicable if date_created > td(31dec2018) & date_created != .
replace `x'2019 = not_applicable if date_created > td(31dec2019) & date_created != .
replace `x'2020 = not_applicable if date_created > td(31dec2020) & date_created != .
}

***********************************************************************
* 	PART 5:  Convert problematic values for open-ended questions  			
***********************************************************************

***********************************************************************
* 	PART 6:  Traduction reponses en arabe au francais		  			
***********************************************************************


***********************************************************************
* 	PART 7: 	Rename and homogenize the observed values		  			
***********************************************************************


***********************************************************************
* 	PART 8:  Identify duplicates (for removal see regis_generate)
***********************************************************************
	* formating the variables for whcih we check duplicates
format firmname rg_emailrep rg_emailpdg %-35s
format id_plateforme %9.0g
sort firmname
	
	* id_plateform
duplicates report id_plateforme

	* email
duplicates report rg_emailrep
duplicates report rg_emailpdg
duplicates tag rg_emailpdg, gen(dup_emailpdg)

	* firmname	
duplicates report firmname
duplicates tag firmname, gen(dup_firmname)

	* drop duplicates
drop if id_plateforme == 1078
* replace address = "Cyber parc  18 janvier Kasserine" if id_plateforme == 1214
* Note: I cannot find the variable address to be replaced.

***********************************************************************
* 	PART 10:  autres / miscallaneous adjustments
***********************************************************************
/*
	* correct the response categories for moyen de communication
replace moyen_com = "site institution gouvernmentale" if moyen_com == "site web d'une autre institution gouvernementale" 
replace moyen_com = "bulletin d'information giz" if moyen_com == "bulletin d'information de la giz"

	* correct wrong response categories for subsectors
replace subsector = "industries chimiques" if subsector == "industrie chimique"
*/

***********************************************************************
* 	PART:  Test logical values		  			
***********************************************************************
	* In Tunisia, SCA and SA must have a minimum of 5000 TND of capital social
		*All values having a too small capital social (less than 100)
/*
replace capitalsocialr = "$check_again" if capitalsocialr == "0"
replace capitalsocialr = "$check_again" if capitalsocialr == "o"
destring capitalsocialr, replace
*/

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$regis_intermediate"
save "regis_inter", replace


***********************************************************************
* 	Export an excel sheet with needs_check variables  			
***********************************************************************
cd "$regis_checks"
preserve 
keep if needs_check ==1 & etat=="vérifié" 
export excel id_plateforme needs_check questions_needing_check commentairesequipegiz commentairesequipemsb semaine-dup_firmname using "ficherection", firstrow(variables) replace 
restore
