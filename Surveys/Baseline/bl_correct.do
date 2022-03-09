***********************************************************************
* 			consortias baseline survey corrections                    *	
***********************************************************************
*																	    
*	PURPOSE: correct all incoherent responses				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Define non-response categories 		
*   2)		Manually fix wrong answers 	  				  
* 	3) 		Use regular expressions to correct variables
*	4)   	Replace string with numeric values						  
*	5)  	Convert string to numerical variaregises	  				  
*	6)  	Convert problematic values for open-ended questions		  
*	7)  	Traduction reponses en arabe au francais				  
*   8)      Rename and homogenize the observed values                   
*	9)		Import categorisation for opend ended QI questions
*	10)		Remove duplicates
*
*																	  															      
*	Author:  	Fabian Scheifele, Kais Jomaa & Siwar Jakim							  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: bl_inter.dta 	  								  
*	Creates:  bl_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Define non-response categories  			
***********************************************************************
use "${bl_intermediate}/bl_inter", clear

{
	* replace "-" with missing value
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
		replace `x' = "" if `x' == "-"
	}
	
scalar not_know    = -999
scalar refused     = -888

local not_know    = -999
local refused     = -888

	* replace, gen, label
gen check_again = 0
gen questions_needing_checks = ""
gen commentsmsb = ""
*/
}

***********************************************************************
* 	PART 1.2:  Identify and remove duplicates 
***********************************************************************
* duplicates report id_plateforme
* duplicates tag id_plateforme, gen(dup)


***********************************************************************
* 	PART 2:  Automatic corrections
***********************************************************************
*2.1 Remove commas, dots, dt and dinar Turn zero, zéro into 0 for all numeric vars
local numvars ca_2021 ca_exp_2021 profit_2021 ca_2020_cor ca_2019_cor exprep_inv inno_rd
foreach var of local numvars {
replace `var' = ustrregexra( `var',"dinars","")
replace `var' = ustrregexra( `var',"dinar","")
replace `var' = ustrregexra( `var',"milles","000")
replace `var' = ustrregexra( `var',"mille","000")
replace `var' = ustrregexra( `var',"dt","")
replace `var' = ustrregexra( `var',"k","000")
replace `var' = ustrregexra( `var',"dt","")
replace `var' = ustrregexra( `var',"tnd","")
replace `var' = ustrregexra( `var',"TND","")
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
replace `var' = "1000" if `var' == "000"
replace `var' = subinstr(`var', ".", "",.)
replace `var' = "`not_know'" if `var' =="je ne sais pas"
replace `var' = "`not_know'" if `var' =="لا أعرف"

}
*/


*2.4 Remove linking words like un, une, des,les, from product descriptions
local products produit1 produit2 produit3
foreach var of local products {
replace `var' = ustrregexra( `var',"les ","")
replace `var' = ustrregexra( `var',"des ","")
replace `var' = ustrregexra( `var',"un ","")
replace `var' = ustrregexra( `var',"une ","")
replace `var' = ustrregexra( `var',"la ","")
replace `var' = ustrregexra( `var',"le ","")
}
*/ 

*2.5 fill inno_mot for firms without innovations
replace inno_mot ="no innovation" if inno_produit==0 & inno_process==0 & inno_lieu==0 & inno_commerce==0

***********************************************************************
* 	PART 3:  Manual correction (by variable not by row)
***********************************************************************
*3.1 Translate arab product names and inno_mot_autre, autresapreciser to french*
replace produit1 = "comprehensive media training course"  if produit1 =="دورة تدريبية في الاعلامي الشامل"
replace produit1 = "deglet nour dates"  if produit1 =="تمر دقلة نور"
replace produit1 = "tourism of all kinds: business, commerce, study, entertainment"  if produit1 =="السياحة بكل انواعها :أعمال، تجارة، دراسة، ترفيه"
replace produit1 = "nurseries production"  if produit1 =="انتاج المشاتل"


replace produit2 = "voice over training course"  if produit2 =="دورة تدريبية في التعليق الصوتي"
replace produit2 = "olive oil"  if produit2 =="زيت زيتون"
replace produit2 = "selling nurseries"  if produit2 =="بيع المشاتل"
replace produit2 = "electrical appliances, food, clothes"  if produit2 =="الأجهزة الكهرومنزلية، المواد الغذائية ،الملابس"


replace produit3 = "a course in creating content on social media platforms"  if produit3 =="دورة في صناعة المحتوى على منصات التواصل الاجتماعي"
replace produit3 = "food and agricultural materials"  if produit3 =="مواد غذائية وزراعية"
replace produit3 = "follow-up and agricultural guidance"  if produit3 =="المتابعة والإرشاد الفلاحي"
replace produit3 = "buying and selling real estate in Tunisia and abroad"  if produit3 =="بيع وشراء عقارات في تونس و الخارج"


replace inno_mot_autre = "after 16 years of experience in the field of nursery production and training in..."  if inno_mot_autre =="بعد خبرة 16 سنة في مجال انتاج المشاتل والتكوين في"

*3.2	Rename and homogenize the product names	  			
	* Example

/*
replace produit1 = "tuiles"  if produit1=="9armoud"
replace produit1 = "dattes"  if produit1=="tmar"
replace produit1 = "maillots de bain"  if produit1=="mayo de bain"
*/


*3.3 Manually Transform any remaining "word numerics" to actual numerics 
* browse id_plateforme ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020 ca_2021 ca_exp_2021 profit_2021 ca_2020_cor ca_exp2020_cor ca_2019_cor ca_exp2019_cor ca_2018_cor ca_exp_2018_cor
replace inno_rd = "300000" if inno_rd == "اكثرمن300000"


*3.4 Mark any non-numerical answers to numeric questions as check_again=1



*3.5 Translate and code entr_idee (Low priority, only at the end of the survey, when more time)






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
* Correction des variables investissement
replace investcom_2021 = ustrregexra( investcom_2021,"k","000")
//replace investcom_futur = ustrregexra( investcom_futur,"dinars","")
//replace investcom_futur = ustrregexra( investcom_futur,"dt","")
//replace investcom_futur = ustrregexra( investcom_futur,"k","000")

replace id_base_repondent = ustrregexra( id_base_repondent ,"mme ","")



***********************************************************************
* 	EXAMPLE CODE:  Replace string with numeric values		  			
***********************************************************************
{
*Remplacer les textes de la variable investcom_2021
replace investcom_2021 = "100000" if investcom_2021== "100000dt"
replace investcom_2021 = "18000" if investcom_2021== "huit mille dinars"
replace investcom_2021 = "0" if investcom_2021== "zéro"


replace investcom_2021 = "`refused'" if investcom_2021 == "-888"
replace investcom_2021 = "`not_know'" if investcom_2021 == "-999"
replace investcom_2021 = "`not_know'" if investcom_2021 == "لا اعرف"

}

***********************************************************************
* 	PART 5:  Highlight non-sensical values for open and numerical answers(answers that do not correspond to the desired answer format)  			
***********************************************************************

* Marquer non-sensical value with check_again=1 and question_needing_check with the problem





*/

***********************************************************************
* 	PART 6:  Import categorisation for opend ended QI questions (NOT REQUIRED AT THE MOMENT)
***********************************************************************
{
/*
	* the manually handed categories are in the folder data/AQE/surveys/midline/categorisation/copies
			* q42, q15c5, q18m5, q10n5, q10r5, q21example
local categories "argument-vente source-informations-conformité source-informations-metrologie source-normes source-reglements-techniques verification-intrants-fournisseurs"
foreach x of local categories {
	preserve

	cd "$bl_categorisation"
	
	import excel "${bl_categorisation}/Copie de categories-`x'.xlsx", firstrow clear
	
	duplicates drop id, force

	cd "$bl_intermediate"

	save "`x'", replace

	restore

	merge 1:1 id using `x'
	
	save, replace

	drop if _merge == 2 /* drops all non matched rows from coded categories */
	
	drop _merge
	}
	* format variables

format %-25s q42 q42c q15c5 q18m5 q10n5 q10r5 q21example q15c5c q18m5c q10n5c q10r5c q21examplec

	* visualise the categorical variables
			* argument de vente
codebook q42c /* suggère qu'il y a 94 valeurs uniques doit etre changé */
graph hbar (count), over(q42c, lab(labs(tiny)))
			* organisme de certification
graph hbar (count), over(q15c5c, lab(labs(tiny)))
graph hbar (count), over(q10n5c, lab(labs(tiny)))


	* label variable categories
lab var q42f "(in-) formel argument de vente"
*/
}


***********************************************************************
* 	PART 7:  Convert data types to the appropriate format
***********************************************************************

* 8.1 Destring remaining numerical vars
local destrvar ca_2021 ca_exp_2021 profit_2021 ca_2020_cor ca_2019_cor exprep_inv inno_rd
foreach x of local destrvar { 
destring `x', replace
*format `x' %25.0fc
}





***********************************************************************
* 	PART 8:  autres / miscellaneous adjustments
***********************************************************************

replace questions_needing_check = "The whole raw needs to be checked" if id_plateforme == 1237
replace needs_check = 1 if id_plateforme == 1237

***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
