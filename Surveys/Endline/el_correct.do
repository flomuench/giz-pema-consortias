***********************************************************************
* 			consortias endline survey corrections                    *	
***********************************************************************
*																	    
*	PURPOSE: correct all incoherent responses				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Import data
*	2)	    Define non-response categories 		
*   3)		Use regular expressions to correct variables	  				  
* 	4) 		Manual correction (by variable not by row)
*	4)   	Replace string with numeric values						  
*	5)  	Convert data types to the appropriate format	  				  
*	6)  	autres / miscellaneous adjustments		  
*	7)		Destring remaining numerical vars
*	8)		Save the changes made to the data
*
*																	  															      
*	Author:  	Amira Bouziri, Kais Jomaa, Eya Hanefi	 														  
*	ID variaregise: id_plateforme			  					  
*	Requires: el_intermediate.dta 	  								  
*	Creates:  el_intermediate.dta			                          
*	
																  
***********************************************************************
* 	PART 1:  Import data 			
***********************************************************************
use "${el_intermediate}/el_intermediate", clear

***********************************************************************
* 	PART 2:  Define non-response categories	 			
***********************************************************************

{
	* replace "-" with missing value
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
		replace `x' = "" if `x' == "-"
	}
	
scalar not_know    = -999
scalar refused     = -888
scalar check_again = -777

local not_know    = -999
local refused     = -888
local check_again = -777

	* replace, gen, label
gen check_again = 0
gen questions_needing_checks = ""
}

***********************************************************************
* 	PART 1.2:  Identify and remove duplicates 
***********************************************************************
/*
sort id_plateforme date
quietly by id_plateforme date:  gen dup = cond(_N==1,0,_n)
drop if dup>1
*/

/*duplicates report id_plateforme heuredébut
duplicates tag id_plateforme heuredébut, gen(dup)
drop if dup>1
*/


*Individual duplicate drops (where heure debut is not the same). If the re-shape
*command in bl_test gives an error it is because there are remaining duplicates,
*please check them individually and drop (actually el-amouri is supposed to that)
*drop if id_plateforme==1239 & heuredébut=="16:02:55"

*restore original order
*sort date heuredébut

***********************************************************************
* 	PART 3:  Automatic corrections
***********************************************************************
*2.1 Remove commas, dots, dt and dinar Turn zero, zéro into 0 for all numeric vars


	* amouri frogot to mention that 999 needs to have a - before in case of don't know
local 999vars comp_ca2023 comp_ca2024 comp_benefice2023 comp_benefice2024 compexp_2023 compexp_2024 
foreach var of local 999vars {
	replace `var' = -999 if `var' == 999
	replace `var' = -888 if `var' == 888
	replace `var' = -777 if `var' == 777
}

	*remove characters added by enumerators because of words limit filter
local innov_vars inno_exampl_produit1 inno_exampl_produit2
foreach var of local innov_vars {
	replace `var' = usubinstr(`var', "*", "", .)
	replace `var' = usubinstr(`var', "+", "", .)
	replace `var' = usubinstr(`var', ".", "", .)


}

replace inno_exampl_produit1 = "badlet les types de produit" if inno_exampl_produit1 == "badlet les types de produit aaaaaaaaaaaaaaaaaaaaaaaaaaa"
replace inno_exampl_produit1 = "badlet les types de produit" if inno_exampl_produit1 == "des etudes a letranger aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

*export = 0 if it does not export
 
replace compexp_2023 = 0 if export_1 == 0
replace compexp_2024 = 0 if export_1 == 0

/*
	*benefits
local bene_vars int_ben1 int_ben2 int_ben3 int_ben_autres
foreach var of local bene_vars {
	replace `var' = "réseautage" if strpos(lower(`var'), "réseautage") | strpos(lower(`var'), "reseautage") | strpos(lower(`var'), "réseaux") | strpos(lower(`var'), "relation") | strpos(lower(`var'), "relations")
	replace `var' = "apprentissage" if strpos(lower(`var'), "apprentissage") | strpos(lower(`var'), "learning")
	replace `var' = "développement de l'entreprise" if strpos(lower(`var'), "développement de l'entreprise") | strpos(lower(`var'), "business development")
	replace `var' = "échange d'expériences" if strpos(lower(`var'), "échange d'expériences") | strpos(lower(`var'), "exchange experiences" | strpos(lower(`var'), "exchange"))
	replace `var' = "coopération" if strpos(lower(`var'), "coopération") | strpos(lower(`var'), "collaboration")
	replace `var' = "ouverture sur des nouveaux marchés" if strpos(lower(`var'), "ouverture sur des nouveaux marchés") | strpos(lower(`var'), "new markets")
}
*/


/*
	* loop over all accounting variables with string
ds ca ca_exp profit ca_2021 ca_exp_2021 profit_2021, has(type string) 
local numvars_with_strings "`r(varlist)'"
foreach var of local numvars_with_strings {
    replace `var' = ustrregexra( `var',"dinars","")
    replace `var' = ustrregexra( `var',"dinar","")
    replace `var' = ustrregexra( `var',"milles","000")
    replace `var' = ustrregexra( `var',"mille","000")
	replace `var' = ustrregexra( `var',"millions","000000")
    replace `var' = ustrregexra( `var',"million","000000") 
    replace `var' = ustrregexra( `var',"dt","")
    replace `var' = ustrregexra( `var',"k","000")
    replace `var' = ustrregexra( `var',"dt","")
    replace `var' = ustrregexra( `var',"tnd","")
    replace `var' = ustrregexra( `var',"TND","")
	replace `var' = ustrregexra( `var',"DT","")
	replace `var' = ustrregexra( `var',"D","")
    replace `var' = ustrregexra( `var',"zéro","0")
    replace `var' = ustrregexra( `var',"zero","0")
    replace `var' = ustrregexra( `var'," ","")
    replace `var' = ustrregexra( `var',"un","1")
    replace `var' = ustrregexra( `var',"deux","2")
    replace `var' = ustrregexra( `var',"trois","3")
    replace `var' = ustrregexra( `var',"quatre","4")
    replace `var' = ustrregexra( `var',"cinq","5")
    replace `var' = ustrregexra( `var',"six","6")
    replace `var' = ustrregexra( `var',"sept","7")
    replace `var' = ustrregexra( `var',"huit","8")
    replace `var' = ustrregexra( `var',"neuf","9")
    replace `var' = ustrregexra( `var',"dix","10")
    replace `var' = ustrregexra( `var',"O","0")
    replace `var' = ustrregexra( `var',"o","0")
    replace `var' = ustrregexra( `var',"دينار تونسي","")
    replace `var' = ustrregexra( `var',"دينار","")
    replace `var' = ustrregexra( `var',"تونسي","")
    replace `var' = ustrregexra( `var',"د","")
    replace `var' = ustrregexra( `var',"de","")
    replace `var' = ustrregexra( `var',"d","")
    replace `var' = ustrregexra( `var',"na","")
    replace `var' = ustrregexra( `var',"r","")
    replace `var' = ustrregexra( `var',"m","000")
    replace `var' = ustrregexra( `var',"مليون","000000")
    replace `var' = subinstr(`var', ".", "",.)
    replace `var' = subinstr(`var', ",", ".",.)
    replace `var' = "`not_know'" if `var' =="je ne sais pas"
    replace `var' = "`not_know'" if `var' =="لا أعرف"

}

*/
***********************************************************************
* 	PART 4:  Manual correction (by variable not by row)
***********************************************************************

*4.1 Manually Transform any remaining "word numerics" to actual numerics 
* browse id_plateforme ca ca_exp Profit ca_2021 ca_exp2021 
 





*4.2 Comparison of newly provided accounting data for firms with needs_check=1
*Please compare new and old and decide whether to replace the value. 
*If new value continues to be strange, then check_again plus comment



*4.3 Manual corrections that were in correction but not automatically update in raw data





***********************************************************************
* 	EXAMPLE CODE FOR : use regular expressions to correct variables 		  			
***********************************************************************
/* for reference and guidance, regularly these commands are used in this section
gen XXX = ustrregexra(XXX, "^216", "")
gen id_adminrect = ustrregexm(id_admin, "([0-9]){6,7}[a-z]")

*replace id_adminrige = $check_again if id_adminrect == 1
lab def correct 1 "correct" 0 "incorrect"
lab val id_adminrect correct

*/
/*

replace id_base_repondent = ustrregexra( id_base_repondent ,"mme ","")
*/

***********************************************************************
* 	EXAMPLE CODE:  Replace string with numeric values		  			
***********************************************************************
/*
{
*Remplacer les textes de la variable investcom_2021
replace investcom_2021 = "100000" if investcom_2021== "100000dt"
replace investcom_2021 = "18000" if investcom_2021== "huit mille dinars"
replace investcom_2021 = "0" if investcom_2021== "zéro"


replace investcom_2021 = "`refused'" if investcom_2021 == "-888"
replace investcom_2021 = "`not_know'" if investcom_2021 == "-999"
replace investcom_2021 = "`not_know'" if investcom_2021 == "لا اعرف"

}

*/
***********************************************************************
* 	PART 5:  Convert data types to the appropriate format
***********************************************************************

***********************************************************************
* 	PART 6:  autres / miscellaneous adjustments
***********************************************************************
	* correct wrongly coded values for man_hr_obj


***********************************************************************
* 	PART 7:  Destring remaining numerical vars
***********************************************************************

local destrvar comp_ca2023 comp_ca2024 comp_benefice2023 comp_benefice2024 compexp_2023 compexp_2024
foreach x of local destrvar { 
destring `x', replace
format `x' %25.0fc
}

***********************************************************************
* 	Part 8: Save the changes made to the data		  			
***********************************************************************
save "${el_intermediate}/el_intermediate", replace
