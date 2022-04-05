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
* we may add these variables to check if they changed to string variables: ca_exp2018_cor  ca_exp2019_cor ca_exp2020_cor ca_2018_cor 
foreach var of local numvars {
replace `var' = ustrregexra( `var',"dinars","")
replace `var' = ustrregexra( `var',"dinar","")
replace `var' = ustrregexra( `var',"milles","000")
replace `var' = ustrregexra( `var',"mille","000")
replace `var' = ustrregexra( `var',"million","000")
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
replace `var' = ustrregexra( `var',"m","000")
replace `var' = ustrregexra( `var',"مليون","000")
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
replace produit1 = "Rédaction de programmes de formation pour les organisations" if produit1 =="seyaghet baramej tadribia lel monadhmet"
replace produit1 = "Peintures" if produit1 =="law7at l faniya"
replace produit1 = "alliés plante" if produit1 =="l7alfa"
replace produit1 = "huile essentielle (Caletus Couronne Za'atar)" if produit1 =="lhuiessentiel(kalatous w klil w zater)"
replace produit1 = "engrais liquide" if produit1 =="سماد liquide"
replace produit1 = "pots" if produit1 =="m7abes"
replace produit1 = "huil de alovera" if produit1 =="huil de hendi"
replace produit1 = "huil d'olive bio" if produit1 =="huidolive bio"
replace produit1 = "alliés plante" if produit1 =="halfa"
replace produit1 = "margoum /tapis" if produit1 =="margoum /zrabi"
replace produit1 = "halelem" if produit1 =="la7lelem"
replace produit1 = "thmara (plant)" if produit1 =="thmara"
replace produit1 = "" if produit1 ==""
replace produit1 = "" if produit1 ==""
replace produit1 = "" if produit1 ==""

replace produit2 = "cours de formation sur le voix off"  if produit2 =="دورة تدريبية في التعليق الصوتي"
replace produit2 = "huil d'olive"  if produit2 =="زيت زيتون"
replace produit2 = "vente de pépinières"  if produit2 =="بيع المشاتل"
replace produit2 = "appareils électriques, nourriture, vêtements"  if produit2 =="الأجهزة الكهرومنزلية، المواد الغذائية ،الملابس"
replace produit2 = "antiquités et décorations"  if produit2 =="التحف و الديكورات"
replace produit2 = "fruits"  if produit2 =="فواكه"
replace produit2 = "engrais poudre"  if produit2 =="سماد poudre"
replace produit2 = "alliés plante"  if produit2 =="halfa"
replace produit2 = ""  if produit2 ==""
replace produit2 = ""  if produit2 ==""


replace produit3 = "un cours de création de contenu sur les plateformes de médias sociaux"  if produit3 =="دورة في صناعة المحتوى على منصات التواصل الاجتماعي"
replace produit3 = "matériel alimentaire et agricole"  if produit3 =="مواد غذائية وزراعية"
replace produit3 = "suivi et orientation agricole"  if produit3 =="المتابعة والإرشاد الفلاحي"
replace produit3 = "achat et vente de biens immobiliers en Tunisie et à l'étranger"  if produit3 =="بيع وشراء عقارات في تونس و الخارج"
replace produit3 = "porcelaine murale"  if produit3 =="الخزف الحائطي"
replace produit3 = "poisson"  if produit3 =="أسماك"
replace produit3 = "mhames"  if produit3 =="m7ames"
replace produit3 = ""  if produit3 ==""
replace produit3 = ""  if produit3 ==""
replace produit3 = ""  if produit3 ==""



*3.2	Rename and homogenize the product names	  			
	* Example



*3.3 Manually Transform any remaining "word numerics" to actual numerics 
* browse id_plateforme ca_2018 ca_exp2018 ca_2019 ca_exp2019 ca_2020 ca_exp2020 ca_2021 ca_exp_2021 profit_2021 ca_2020_cor ca_exp2020_cor ca_2019_cor ca_exp2019_cor ca_2018_cor ca_exp_2018_cor

replace inno_rd = "300000" if inno_rd == "اكثرمن300000"
replace ca_2021 = "600000" if ca_2021 == "6cent000"
replace profit_2021 = "150000" if profit_2021 == "cent5uante000"
replace inno_rd ="1000000" if id_plateforme==1054
replace ca_2018_cor="26423000" if id_plateforme==1092

 


*3.4 Mark any non-numerical answers to numeric questions as check_again=1



*3.5 Translate and code entr_idee (Low priority, only at the end of the survey, when more time)

replace inno_mot_autre = "après 16 ans d'expérience dans le domaine de la production pépinière et de la formation en..."  if inno_mot_autre =="بعد خبرة 16 سنة في مجال انتاج المشاتل والتكوين في"
replace inno_mot_autre = "ca depends la demande des clients/ son mari"  if inno_mot_autre =="7asb demande clients / son marie"
replace inno_mot_autre = "représentant de l'artisanat (utica)"  if id_plateforme ==1214
replace inno_mot_autre = "idée de groupe sur le savoir faire" if inno_mot_autre =="fekra jama3eya ala savoir faire"

replace support_autres = "certains jours, la charge de travail n'est pas énorme pour trouver du temps" if support_autres == "في ايام يكون فيها العمل شويا باش نجمو نلقو الوقت ل"
replace support_autres = "valorisation des manifestations en réseaux sociaux"  if support_autres =="tathmin tadhahoraat fi reseaux sociaux"
replace support_autres = "faites-nous savoir à l'avance" if support_autres == "te3lmouna bel msabbe9"
replace support_autres = "envoyer un questionnaire sur l'heure et la date appropriées" if support_autres == "بعث استبيان حول الوقت و التاريخ المناسب"
replace support_autres = "le temps nous convient" if support_autres == "lwa9t ykon moneseb"
replace support_autres = "nous connaissons la participation avant une semaine" if support_autres == "ykon el e3lem 3al mocherka 9bal bjem3a"
replace support_autres = "choisir un lieu fix (club, hotel,..etc)" if support_autres == "chusir un lieu fixe: club, hotel etc,,,"
replace support_autres = "" if support_autres == ""
replace support_autres = "" if support_autres == ""


replace att_adh_autres ="développer un réseau de relations avec des femmes entrepreneures"  if att_adh_autres =="تطوير شبكة العلاقات مع رائدات الأعمال"
replace att_adh_autres ="introduire le produit tunisien et augmenter les transactions commerciales" if att_adh_autres == "ta3rif bel produit tunisien/zyedet elmou3amlet tij"
replace att_adh_autres ="certification ou formation lel produit" if att_adh_autres == "certification wala formation lel produit"
replace att_adh_autres ="ouvrir de nouveaux perspectives" if att_adh_autres =="فتح افاق جديدة"
replace att_adh_autres ="rencontrer d'autres femmes d'affaires" if att_adh_autres =="besh ta3ref akther des femmes d'affaire"
replace att_adh_autres ="commencer de nouvelles expériences" if att_adh_autres =="theb tod5el fi tajareb jdida"
replace att_adh_autres ="développer / networking / apprendre d'autres expériences" if att_adh_autres =="التطوير networking الاستفادة من التجارب"
replace att_adh_autres ="motivation pour que je démarre" if att_adh_autres =="7afez pour que je démarre"
replace att_adh_autres ="mon ambition c'est l'export" if att_adh_autres =="tomou7i l'export"
replace att_adh_autres ="Je recherche de l'expérience et du financement" if att_adh_autres =="t7eb expérience w tamwil"
replace att_adh_autres ="des formations pour savoir comment interagir avec les douanes" if att_adh_autres =="des formations bech taref tet3amel maa douanes"
replace att_adh_autres ="pour voir comment le formateur enseigne" if att_adh_autres =="bach nchouf l formateur kifech y9ari"
replace att_adh_autres ="introduit à de nouvelles opportunités sur les marchés étrangers" if att_adh_autres =="tet3aref 3la afa9 aswa9 5arijiya"
replace att_adh_autres ="" if att_adh_autres ==""


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
replace entr_idee= "produits artisanaux depuis 2017" if id_plateforme==1197
replace entr_idee= "pots en béton" if entr_idee=="ma7bes en béton"
replace entr_idee= "tapis (1990) ou Halfa (2017)" if entr_idee=="zarbia (1990)ou halfa (2017)"
replace entr_idee= "artisana (tapis ; margoum : crochet, couture, goutte à goutte" if entr_idee=="artizana (zrabi ; margoum : crochet , 5iata, ta9tir"
replace entr_idee= "ils ont commencé avec de la confiture (2014)" if id_plateforme==1231
replace entr_idee= "produits artisanaux, depuis 2017" if entr_idee=="depuis 2017 sina3a ta9lideya"
replace entr_idee= "services techniologie de l'information depuis decembre 2020" if id_plateforme==1155
replace entr_idee= "developper l'education a tunisie at l'afrique (2020)" if entr_idee=="tatwir ta3lim fi tounes w ifri9iya (2020)"
replace entr_idee= "volorisation les déchet d'engrais naturelle/ créé en 2018" if entr_idee=="volorisation les déchet سماد طبيعي créé en 2018"
replace entr_idee= "profiter de fourrure/ recyclage" if entr_idee=="istighlel elfourrure :i3adet raskla . pdt recylable."
replace entr_idee= "planter des fleurs pour manger, l'ouverture en 2018" if entr_idee=="tezra3 des fleurs lel akel l'ouverture en 2018"
replace entr_idee= "piece de decoration de diche du paume 2011" if id_plateforme==1128
replace entr_idee= "industrie des équipements de réfrigération 2010" if entr_idee=="sine3et el mo3edet mta3 tabrid 2010"
replace entr_idee= "Fil et aiguille de vêtements traditionnels" if entr_idee=="5it w ebra tradition malabes artisanat"
replace entr_idee= "nous avons commencé avec 9 artisans" if id_plateforme==1186
replace entr_idee= "home-made pâte" if id_plateforme==1230
replace entr_idee= "le nom d'une plante est "thmara" (des produits de cette plante koffa/corbeille) depuis 2008" if entr_idee=="nabta esmha thmara (koffa corbeille)depuis2008"
replace entr_idee= "terrain amande" if entr_idee=="saniya amande"
replace entr_idee= "des produits d'alliés plante (corbeille) depuis 2003" if entr_idee=="mantoujet mel 7alfa (corbeille artizana)depuis 2003"
replace entr_idee= "" if entr_idee==""
replace entr_idee= "" if entr_idee==""
replace entr_idee= "" if entr_idee==""
replace entr_idee= "" if entr_idee==""



*3.6 Comparison of newly provided accounting data for firms with needs_check=1
*Please compare new and old and decide whether to replace the value. 
*If new value continues to be strange, then check_again plus comment

replace ca_2018 =45000 if id_plateforme==1136
replace ca_2018 =150000 if id_plateforme==1159
replace ca_2018 =5000 if id_plateforme==1210
replace ca_2018 =10000 if id_plateforme==1162
replace ca_2018 =2663000 if id_plateforme==1240
replace ca_2018 =40000 if id_plateforme==1041
replace ca_2018 =70000 if id_plateforme==1197
replace ca_2018 =350000 if id_plateforme==1168
replace ca_2018 =150000 if id_plateforme==1074
replace ca_2018 =100000 if id_plateforme==1035
replace ca_2018 =120000 if id_plateforme==1159
replace ca_2018 =33000 if id_plateforme==1013
replace ca_2018 =295000 if id_plateforme==1043
replace ca_2018 =256000 if id_plateforme==1117
replace ca_2018 =4500 if id_plateforme==1186


replace ca_2019 =250000 if id_plateforme==1074
replace ca_2019 =20000 if id_plateforme==1210
replace ca_2019 =20000 if id_plateforme==1162
replace ca_2019 =480294 if id_plateforme==1168
replace ca_2019 =150000 if id_plateforme==1154
replace ca_2019 =25000 if id_plateforme==1197
replace ca_2019 =20000 if id_plateforme==1182
replace ca_2019 =50000 if id_plateforme==1231
replace ca_2019 =138826 if id_plateforme==1027
replace ca_2019 =1300000 if id_plateforme==1222
replace ca_2019 =100000 if id_plateforme==1110
replace ca_2019 =500000 if id_plateforme==1170
replace ca_2019 =1400000 if id_plateforme==991
replace ca_2019 =80000 if id_plateforme==1035
replace ca_2019 =50000 if id_plateforme==1159
replace ca_2019 =45000 if id_plateforme==1013
replace ca_2019 =25000 if id_plateforme==1030
replace ca_2019 =113280 if id_plateforme==1088
replace ca_2019 =15000 if id_plateforme==1123
replace ca_2019 =550000 if id_plateforme==1043
replace ca_2019 =21100 if id_plateforme==1157
replace ca_2019 =1502130 if id_plateforme==1240
replace ca_2019 =150000 if id_plateforme==1041
replace ca_2019 =20000 if id_plateforme==1044
replace ca_2019 =2000 if id_plateforme==1186
replace ca_2019 =10000 if id_plateforme==1193

replace ca_2020 =25000 if id_plateforme==1159
replace ca_2020 =200000 if id_plateforme==1074
replace ca_2020 =1200000 if id_plateforme==1188
replace ca_2020 =20000 if id_plateforme==1210
replace ca_2020 =5500 if id_plateforme==1162
replace ca_2020 =38500 if id_plateforme==1157
replace ca_2020 =250000 if id_plateforme==1041
replace ca_2020 =20000 if id_plateforme==1154
replace ca_2020 =55000 if id_plateforme==1197
replace ca_2020 =310000 if id_plateforme==1168
replace ca_2020 =300000 if id_plateforme==1087
replace ca_2020 =147000 if id_plateforme==1096
replace ca_2020 =100000 if id_plateforme==1231
replace ca_2020 =2420000 if id_plateforme==1027
replace ca_2020 =37000 if id_plateforme==1110
replace ca_2020 =2000000 if id_plateforme==1170
replace ca_2020 =6000 if id_plateforme==1035
replace ca_2020 =5000 if id_plateforme==1108
replace ca_2020 =3000 if id_plateforme==1020
replace ca_2020 =123000 if id_plateforme==1013
replace ca_2020 =60000 if id_plateforme==1030
replace ca_2020 =75831 if id_plateforme==1088
replace ca_2020 =15000 if id_plateforme==1123
replace ca_2020 =10000 if id_plateforme==1019
replace ca_2020 =300000 if id_plateforme==1043
replace ca_2020 =82630 if id_plateforme==1240
replace ca_2020 =176000 if id_plateforme==1117
replace ca_2020 =1000 if id_plateforme==1186
replace ca_2020 =20000 if id_plateforme==1193
replace ca_2020 =3000 if id_plateforme==1192
replace ca_2020 =4500 if id_plateforme==1245
replace ca_2020 =0 if id_plateforme==1136


replace ca_exp2018 =75000 if id_plateforme==1074
replace ca_exp2018 =80000 if id_plateforme==1159
replace ca_exp2018 =9326 if id_plateforme==1168
replace ca_exp2018 =13000 if id_plateforme==1117
replace ca_exp2018 =2100 if id_plateforme==1186


replace ca_exp2019 =100000 if id_plateforme==1074
replace ca_exp2019 =80000 if id_plateforme==1041
replace ca_exp2019 =100000 if id_plateforme==1110
replace ca_exp2019 =20000 if id_plateforme==1044
replace ca_exp2019 =150000 if id_plateforme==1154
replace ca_exp2019 =5000 if id_plateforme==1231
replace ca_exp2019 =25000 if id_plateforme==1222
replace ca_exp2019 =5000 if id_plateforme==1162
replace ca_exp2019 =800 if id_plateforme==1197
replace ca_exp2019 =26000 if id_plateforme==1117
replace ca_exp2019 =400000 if id_plateforme==1158

replace ca_exp2020 =50000 if id_plateforme==1074
replace ca_exp2020 =147000 if id_plateforme==1096
replace ca_exp2020 =2000 if id_plateforme==1231
replace ca_exp2020 =25000 if id_plateforme==1222
replace ca_exp2020 =15960 if id_plateforme==1027
replace ca_exp2020 =4000 if id_plateforme==1197
replace ca_exp2020 =5000 if id_plateforme==1117
replace ca_exp2020 =3000 if id_plateforme==1245


*3.6 Manual corrections that were in correction but not automatically update in raw data

replace ca_2019=4000 if id_plateforme == 1192
replace ca_2020=3000 if id_plateforme == 1192
replace ca_2018=8000 if id_plateforme == 1192
replace profit_2021="2000" if id_plateforme == 1037
replace ca_2021="211000" if id_plateforme == 1045
replace ca_exp_2021="21700" if id_plateforme == 1045
replace inno_rd="1000" if id_plateforme == 1054
replace profit_2021="-7000" if id_plateforme == 1110
replace profit_2021="-3000" if id_plateforme == 1128
replace profit_2021="50000" if id_plateforme == 1178
replace ca_2021= "4191110" if id_plateforme == 1119
replace profit_2021= "-77505" if id_plateforme == 1119
replace ca_exp_2021 ="4015384" if id_plateforme == 1119
replace ca_2018_cor ="2847421" if id_plateforme == 1119
replace ca_exp2018_cor ="2649925" if id_plateforme == 1119
replace ca_2019_cor= "3792943" if id_plateforme == 1119
replace ca_exp2019_cor ="3441390" if id_plateforme == 1119
replace ca_2020_cor ="3904562" if id_plateforme == 1119
replace ca_exp2020_cor ="3380415" if id_plateforme == 1119

*1137 says the figures are confidential but puts zeros for 2021 figures, hence missing is more realistic*
replace ca_2021 ="" if id_plateforme == 1137
replace ca_exp_2021 ="" if id_plateforme == 1137
replace profit_2021 ="" if id_plateforme == 1137

*1137 reports exports are 20.6%, 9.2% and 2.16% of total revenue for 2018,2019 and 2020 respectively
replace ca_exp2018_cor ="497078" if id_plateforme == 1137
replace ca_exp2020_cor="42790" if id_plateforme == 1137
replace ca_exp2019_cor="265972" if id_plateforme == 1137

*995 reports profits are 15% of total revenue
replace profit_2021 = "300000" if id_plateforme == 995

replace ca_2021 = "163000" if id_plateforme == 1049
replace ca_exp_2021 = "163000" if id_plateforme == 1049
replace profit_2021 = "43000" if id_plateforme == 1049

replace ca_2021= "344281" if id_plateforme == 998
replace profit_2021= "264318" if id_plateforme == 998
replace ca_exp_2021= "32842" if id_plateforme == 998

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
local destrvar ca_2021 ca_exp_2021 profit_2021 ca_2020_cor ca_2019_cor exprep_inv inno_rd  ca_2018_cor ca_exp2018_cor ca_exp2019_cor ca_exp2020_cor
foreach x of local destrvar { 
destring `x', replace
*format `x' %25.0fc
}

***********************************************************************
* 	PART 8:  autres / miscellaneous adjustments
***********************************************************************

replace questions_needing_check = "toute la ligne doit être vérifiée /" if id_plateforme == 1237
replace needs_check = 1 if id_plateforme == 1237
replace questions_needing_check = "Ttoute la ligne doit être vérifiée /" if id_plateforme == 1154
replace needs_check = 1 if id_plateforme == 1154

***********************************************************************
* 	Part 9: Save the changes made to the data		  			
***********************************************************************
cd "$bl_intermediate"
save "bl_inter", replace
