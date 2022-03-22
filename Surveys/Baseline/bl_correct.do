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
sort id_plateforme heuredébut
quietly by id_plateforme heuredébut:  gen dup = cond(_N==1,0,_n)
drop if dup>1

/*duplicates report id_plateforme heuredébut
duplicates tag id_plateforme heuredébut, gen(dup)
drop if dup>1
*/


*Individual duplicate drops (where heure debut is not the same). If the re-shape
*command in bl_test gives an error it is because there are remaining duplicates,
*please check them individually and drop (actually el-amouri is supposed to that)
drop if id_plateforme==1239 & heuredébut=="16:02:55"

*restore original order
sort date heuredébut
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
replace `var' = ustrregexra( `var',"million","000000")
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
replace `var' = ustrregexra( `var',"d","")
replace `var' = ustrregexra( `var',"na","")
replace `var' = ustrregexra( `var',"r","")
replace `var' = ustrregexra( `var',"مليون","000000")
replace `var' = "1000" if `var' == "000"
replace `var' = subinstr(`var', ".", "",.)
replace `var' = subinstr(`var', ",", ".",.)
replace `var' = "`not_know'" if `var' =="je ne sais pas"
replace `var' = "`not_know'" if `var' =="لا أعرف"

}



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
replace produit1 = "cours complet de formation aux médias"  if produit1 =="دورة تدريبية في الاعلامي الشامل"
replace produit1 = "deglet nour dates"  if produit1 =="تمر دقلة نور"
replace produit1 = "tourisme de toutes sortes : affaires, commerce, étude, divertissement"  if produit1 =="السياحة بكل انواعها :أعمال، تجارة، دراسة، ترفيه"
replace produit1 = "pépinières production" if produit1 =="انتاج المشاتل"
replace produit1 = "art de la table / table en porcelaine" if produit1 =="فن الطاولة /خزف الطاولة"
replace produit1 = "tapis traditionnelle (klim, margoum)" if produit1 =="كليم مرقوم"
replace produit1 = "légume" if produit1 =="خضار"
replace produit1 = "" if produit1 ==""
replace produit1 = "" if produit1 ==""

replace produit2 = "cours de formation sur le voix off"  if produit2 =="دورة تدريبية في التعليق الصوتي"
replace produit2 = "olive oil"  if produit2 =="زيت زيتون"
replace produit2 = "vente de pépinières"  if produit2 =="بيع المشاتل"
replace produit2 = "appareils électriques, nourriture, vêtements"  if produit2 =="الأجهزة الكهرومنزلية، المواد الغذائية ،الملابس"
replace produit2 = "antiquités et décorations"  if produit2 =="التحف و الديكورات"
replace produit2 = "fruits"  if produit2 =="فواكه"
replace produit2 = ""  if produit2 ==""
replace produit2 = ""  if produit2 ==""

replace produit3 = "un cours de création de contenu sur les plateformes de médias sociaux"  if produit3 =="دورة في صناعة المحتوى على منصات التواصل الاجتماعي"
replace produit3 = "matériel alimentaire et agricole"  if produit3 =="مواد غذائية وزراعية"
replace produit3 = "suivi et orientation agricole"  if produit3 =="المتابعة والإرشاد الفلاحي"
replace produit3 = "achat et vente de biens immobiliers en Tunisie et à l'étranger"  if produit3 =="بيع وشراء عقارات في تونس و الخارج"
replace produit3 = "porcelaine murale"  if produit3 =="الخزف الحائطي"
replace produit3 = "poisson"  if produit3 =="أسماك"
replace produit3 = ""  if produit3 ==""
replace produit3 = ""  if produit3 ==""
replace produit3 = ""  if produit3 ==""
replace produit3 = ""  if produit3 ==""

replace inno_mot_autre = "après 16 ans d'expérience dans le domaine de la production pépinière et de la formation en..."  if inno_mot_autre =="بعد خبرة 16 سنة في مجال انتاج المشاتل والتكوين في"
replace inno_mot_autre = "ca depends la demande des clients/ son mari"  if inno_mot_autre =="7asb demande clients / son marie"
replace inno_mot_autre = "représentant de l'artisanat (utica)"  if id_plateforme ==1214

replace support_autres = "certains jours, la charge de travail n'est pas énorme pour trouver du temps" if support_autres == "في ايام يكون فيها العمل شويا باش نجمو نلقو الوقت ل"

replace att_adh_autres ="développer un réseau de relations avec des femmes entrepreneures"  if att_adh_autres =="تطوير شبكة العلاقات مع رائدات الأعمال"
replace att_adh_autres ="introduire le produit tunisien et augmenter les transactions commerciales" if att_adh_autres == "ta3rif bel produit tunisien/zyedet elmou3amlet tij"
replace att_adh_autres ="certification ou formation lel produit" if att_adh_autres == "certification wala formation lel produit"


replace entr_idee= "media training, formation de journalistes et d'amateurs en radio et télévision" if entr_idee== "تدريب اعلامي تكوين صحفيين و هواة في الاذاعة والتلفزة" 
replace entr_idee= "la ville de Douz produit des dattes, Deglet Nour, et mon père était un agriculteur" if entr_idee=="مدينة دوز تنتج التمر دقلة نور وابي كان فلاح"
replace entr_idee= "valoriser les produits agricoles et les protéger de la détérioration" if id_plateforme == 1196
replace entr_idee= "production et vente de pépinières" if entr_idee=="انتاج وبيع المشاتل"
replace entr_idee= "appareils électroménagers, nourriture, vêtements" if entr_idee=="الأجهزة الكهرومنزلية، المواد الغذائية، الملابس،"
replace entr_idee= "un atelier de fabrication et de vente de poteries à partir de pots, d'antiquités et de céramiques murales" if entr_idee=="ورشة لصناعة و بيع الفخار من اواني و تحف و خزف حائط"
replace entr_idee= "industries traditionnelles spécialisées dans le tissage à la main" if entr_idee=="صناعات تقليدية مختصة في النسيج اليدوي"
replace entr_idee= "valoriser les déchets organiques et les transformer en engrais naturel" if entr_idee=="تثمين النفايات العضوية و تحويلها الى سماد طبيعي"
replace entr_idee= "exportation de poissons fruits et légumes tunisiens par avion vers les pays" if entr_idee=="تصدير فواكه و خضروات اسماك تونسية بالطائرة لبلدان"
replace entr_idee= "aider les parents et les spécialistes" if entr_idee=="lمساعدة الاولياء و الاخصائيين"
replace entr_idee= "commercialisation de produits artisanaux" if id_plateforme==1214
replace entr_idee= "" if entr_idee==""

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
replace ca_2021 = "600000" if ca_2021 == "6cent000"
replace ca_2021 = "3000000" if ca_2021 == "3m"
replace profit_2021 = "150000" if profit_2021 == "cent5uante000"
replace inno_rd ="1000000" if id_plateforme==1054
replace ca_2020_cor = "2000000" if ca_2020_cor == "2m"
replace ca_exp_2021 = "19000000" if ca_exp_2021 == "19m"




*3.4 Mark any non-numerical answers to numeric questions as check_again=1



*3.5 Translate and code entr_idee (Low priority, only at the end of the survey, when more time)


*3.6 Comparison of newly provided accounting data for firms with needs_check=1
*Please compare new and old and decide whether to replace the value. 
*If new value continues to be strange, then check_again plus comment

replace ca_2018 =45000 if id_plateforme==1136
replace ca_2018 =150000 if id_plateforme==1159
replace ca_2018 =5000 if id_plateforme==1210
replace ca_2018 =10000 if id_plateforme==1162
replace ca_2018 =2663000 if id_plateforme==1240

replace ca_2019 =250000 if id_plateforme==1074
replace ca_2019 =20000 if id_plateforme==1210
replace ca_2019 =20000 if id_plateforme==1162
replace ca_2019 =480294 if id_plateforme==1168

replace ca_2020 =25000 if id_plateforme==1159
replace ca_2020 =200000 if id_plateforme==1074
replace ca_2020 =1200000 if id_plateforme==1188
replace ca_2020 =20000 if id_plateforme==1210
replace ca_2020 =5500 if id_plateforme==1162
replace ca_2020 =38500 if id_plateforme==1157
 

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
local destrvar ca_2021 ca_exp_2021 profit_2021 ca_2020_cor ca_2019_cor exprep_inv inno_rd  ca_2018_cor ca_exp_2018_cor ca_exp2019_cor ca_exp2020_cor
foreach x of local destrvar { 
destring `x', replace
*format `x' %25.0fc
}

***********************************************************************
* 	PART 8:  autres / miscellaneous adjustments
***********************************************************************

replace questions_needing_check = "The whole raw needs to be checked /" if id_plateforme == 1237
replace needs_check = 1 if id_plateforme == 1237
replace questions_needing_check = "The whole raw needs to be checked /" if id_plateforme == 1154
replace needs_check = 1 if id_plateforme == 1154

***********************************************************************
* 	Part 9: Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
