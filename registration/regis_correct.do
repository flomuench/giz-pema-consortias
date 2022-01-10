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
	



scalar not_know    = 77777777777777777
scalar refused     = 99999999999999999
scalar check_again = 88888888888888888

	* replace, gen, label
	
*/
}

***********************************************************************
* 	PART 2: use regular expressions to correct variables 		  			
***********************************************************************
/* 
example code: 
gen id_admin_correct = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")
replace rg_nom_rep_cor = ustrregexra( rg_nom_rep_cor ,"mr ","")
replace rg_codedouane_cor = ustrregexra( rg_codedouane_cor ,"/","")
replace autres_cor = "services informatiques" if ustrregexm( autres_cor ,"informatique")== 1
gen rg_telrep_cor = ustrregexra(rg_telrep, "^216", "")

example variables: 
- id_admin, nom_rep etc.

*/ 
		* gen dummy if matricule fiscal is correct: 7 digit, 1 character condition
gen id_admin_correct = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")
order id_admin_correct, a(id_admin)
lab def correct 1 "correct" 0 "incorrect"
lab val id_admin_correct correct


    *correct code de la douane

gen rg_codedouane_cor = rg_codedouane
replace rg_codedouane_cor = ustrregexra(rg_codedouane," ","")
replace rg_codedouane_cor = "1435318s" if rg_codedouane_cor == "1435318/s"
order rg_codedouane_cor, a(rg_codedouane)
drop rg_codedouane 
rename rg_codedouane_cor rg_codedouane 


	* correct telephone numbers with regular expressions
		* representative
 gen rg_telrep_cor = ustrregexra(rg_telrep, "^216", "")
replace rg_telrep_cor = ustrregexra( rg_telrep_cor,"[a-z]","")
replace rg_telrep_cor = ustrregexra( rg_telrep_cor," ","")
replace rg_telrep_cor = ustrregexra( rg_telrep_cor,"00216","")


	* Check all phone numbers having more or less than 8 digits
replace rg_telrep_cor = "$check_again" if strlen( rg_telrep_cor ) != 8

	* Check phone number
gen diff = length(rg_telrep) - length(rg_telrep_cor)
order rg_telrep_cor diff, a(rg_telrep)
*browse rg_telrep* diff
drop rg_telrep diff
rename rg_telrep_cor rg_telrep 


	* Téléphone du de lagérante

gen rg_telpdg_cor = ustrregexra( rg_telpdg, "^216", "")
replace rg_telpdg_cor = subinstr(rg_telpdg_cor, " ", "", .)
replace rg_telpdg_cor = ustrregexra( rg_telpdg_cor,"[a-z]","")
replace rg_telpdg_cor = ustrregexra( rg_telpdg_cor,"00216","")
order rg_telpdg_cor, a(rg_telpdg)
replace rg_telpdg_cor = "52710565" if rg_telpdg_cor == "(+216)52710565"
replace rg_telpdg_cor = "97405671" if rg_telpdg_cor == "+21697405671"
replace rg_telpdg_cor = "$check_again" if rg_telpdg_cor == "82828"
drop rg_telpdg 
rename rg_telpdg_cor rg_telpdg


    * adresse mail du PDG
replace rg_emailpdg = "$check_again" if rg_emailpdg == "yosra.slama@genoviaing"

	* variable: Qualité/fonction

gen rg_position_repcor = ustrlower(rg_position_rep)
replace rg_position_repcor = "directrice" if rg_position_rep == "dirctrice"
replace rg_position_repcor = "$check_again" if rg_position_rep == "group task 6 - peer to peer group wee"
replace rg_position_repcor = "gérant" if rg_position_rep == "gerant"
replace rg_position_repcor = "gérante" if rg_position_rep == "gerante"
replace rg_position_repcor = "gérant" if rg_position_rep == "gerant"
replace rg_position_repcor = "gérante" if rg_position_rep == "gérant e"
replace rg_position_repcor = "coo" if rg_position_rep == "c.o.o"
order rg_position_repcor, a(rg_position_rep)
drop rg_position_rep 
rename rg_position_repcor rg_position_rep 

	* variable: Matricule CNSS

gen rg_matricule_cor = ustrregexra(rg_matricule, "[ ]", "")
replace rg_matricule_cor = ustrregexra(rg_matricule_cor, "[/]", "-")
replace rg_matricule_cor = ustrregexra(rg_matricule_cor, "[_]", "-")

		* Format CNSS Number:
gen t1 = ustrregexs(0) if ustrregexm(rg_matricule_cor, "\d{8}")
gen t2 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9][0-9][0-9][0-9][0-9]")
gen t3 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9]$") 
gen t4 = t2 + "-" + t3
replace t4 = ustrregexra(t4, "[-]", "") if length(t4)==1
replace rg_matricule_cor = t4 if length(rg_matricule_cor)==8
order rg_matricule_cor , a(rg_matricule)
drop t1 t2 t3 t4 

		* Format CNRPS Number:

gen t1 = ustrregexs(0) if ustrregexm(rg_matricule_cor, "\d{10}")
gen t2 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]")
gen t3 = ustrregexs(0) if ustrregexm(t1, "[0-9][0-9]$") 
gen t4 = t2 + "-" + t3
replace t4 = ustrregexra(t4, "[-]", "") if length(t4)==1
replace rg_matricule_cor = t4 if length(rg_matricule_cor)==10
order rg_matricule_cor , a(rg_matricule)
drop t1 t2 t3 t4  

replace rg_matricule_cor = "$check_again" if length(rg_matricule_cor) >= 12 | length(rg_matricule_cor) <= 7
drop rg_matricule
rename rg_matricule_cor rg_matricule

		* Nom de l'entreprise:

replace firmname = "$check_again" if firmname == "https://www.facebook.com/search/top?q=ol%c3%a9a%20amiri"
replace firmname = "$check_again" if firmname == "suarl"
replace firmname = "$check_again" if firmname == "sarl"

***********************************************************************
* 	PART 3:  Replace string with numeric values		  			
***********************************************************************

	* cleaning capital social
/* gen capitalsocial_corr = rg_capital
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"","")
replace capitalsocial_corr = ustrregexra( capitalsocial_corr," ","")
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"dinars","")
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"dt","")
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"millions","000")
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"mill","000")
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"tnd","")
replace capitalsocial_corr = "10000" if capitalsocial_corr == "10.000"
replace capitalsocial_corr = "1797000" if capitalsocial_corr == "1.797.000"
replace capitalsocial_corr = "50000" if capitalsocial_corr == "50.000"
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"e","")
replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"m","")
replace capitalsocial_corr = "30000" if capitalsocial_corr == "30000n"

replace capitalsocial_corr = ustrregexra( capitalsocial_corr,"000","") if strlen( capitalsocial_corr) >= 9
replace capitalsocial_corr = "$check_again" if strlen( capitalsocial_corr) == 1
replace capitalsocial_corr = "$check_again" if strlen( capitalsocial_corr) == 2


replace capitalsocial_corr = "$check_again" if capitalsocial_corr == "tunis"
*/

***********************************************************************
* 	PART 4:  Convert string to numerical variaregises	  			
***********************************************************************
local destrvar "rg_fte rg_fte_femmes id_plateforme ca_2018 ca_2019 ca_2020 ca_exp2018 ca_exp2019 ca_exp2020"
foreach x of local destrvar { 
destring `x', replace
}

***********************************************************************
* 	PART 5:  Convert problematic values for open-ended questions  			
***********************************************************************
{

	* Sectionname
*replace q04 ="Hors sujet" if q04 == "OUI" 

	*Correction nom du representant

/*gen rg_nom_rep_corr= rg_nom_rep            
replace rg_nom_rep_corr="$check_again" if rg_nom_rep == "Études géomatiques." */

 
}

***********************************************************************
* 	PART 6:  Traduction reponses en arabe au francais		  			
***********************************************************************
{
* Sectionname
/*
replace q05="directeur des ventes"  if q05=="مدير المبيعات" 
*/

}

***********************************************************************
* 	PART 7: 	Rename and homogenize the observed values		  			
***********************************************************************
{
	* Sectionname
*replace regis_unite = "pièce"  if regis_unite=="par piece"
*replace regis_unite = "pièce"  if regis_unite=="Pièce" 

}


***********************************************************************
* 	PART 8:  Identify duplicates (for removal see regis_generate)
***********************************************************************
	* formating the variables for whcih we check duplicates
format firmname rg_emailrep rg_emailpdg %-35s
format id_plateforme %9.0g
sort firmname
	
	* id_plateform
duplicates report id_plateform

	* email
duplicates report rg_emailrep
duplicates report rg_emailpdg
duplicates tag rg_emailpdg, gen(dup_emailpdg)

	* firmname	
duplicates report firmname
duplicates tag firmname, gen(dup_firmname)


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
replace capitalsocial_corr = "$check_again" if capitalsocial_corr == "0"
replace capitalsocial_corr = "$check_again" if capitalsocial_corr == "o"
destring capitalsocial_corr, replace
*/

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$regis_intermediate"
save "regis_inter", replace
