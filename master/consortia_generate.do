***********************************************************************
* 			consortia master do files: generate variables  
***********************************************************************
*																	  
*	PURPOSE: create variables based on merged data			  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*
*				PART II: Analysis data
*					PART 3: 
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	consortium__master_inter.dta
*	Creates:	consortium__master_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	

***********************************************************************
* 	PART 1:    import data  
***********************************************************************
use "${master_intermediate}/consortium_pii_inter", clear

***********************************************************************
* 	PART 2:  generate dummy account contact information missing
***********************************************************************
gen comptable_missing = 0, a(comptable_email)
	replace comptable_missing = 1 if comptable_numero == . & comptable_email == ""
	replace comptable_missing = 1 if comptable_numero == 88888888 & comptable_email == "nsp@nsp.com"
	replace comptable_missing = 1 if comptable_numero == 88888888 & comptable_email == "refus@refus.com"
	replace comptable_missing = 1 if comptable_numero == 99999999 & comptable_email == "nsp@nsp.com"


***********************************************************************
* 	PART 3:    Add Tunis to rg_adresse using PII data 
***********************************************************************

*gen dummy if tunis in variable
gen contains_tunis = strpos(rg_adresse, "tunis") > 0 | strpos(rg_adresse, "tunisia") > 0

*gen new rg_adresse just in case
gen rg_adresse_modified = rg_adresse

*add tunis if it does not contain it or tunisia
replace rg_adresse_modified = rg_adresse_modified + ", tunis" if !contains_tunis

***********************************************************************
* 	PART 4:  save
***********************************************************************
save "${master_final}/consortium_pii_final", replace




***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
use "${master_intermediate}/consortium_inter", clear

***********************************************************************
* 	PART 1:  generate take-up variable
***********************************************************************
{
* PHASE 1 of the treatment: "consortia creation"
	*  label variables from participation "presence_ateliers"
local take_up_vars "webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique"

lab def presence_status 0 "Drop-out" 1 "Participate"

foreach var of local take_up_vars {
	gen `var'1 = `var'
	replace `var'1 = "1" if `var' == "présente"  | `var' == "désistement"
	replace `var'1 = "0" if `var' == "absente"
	drop `var'
	destring `var'1, replace
	rename `var'1 `var'
	lab values `var' presence_status
}
	

	* Create take-up percentage per firm
egen take_up_per = rowtotal(webinairedelancement rencontre1atelier1 rencontre1atelier2 rencontre2atelier1 rencontre2atelier2 rencontre3atelier1 rencontre3atelier2 eventcomesa rencontre456 atelierconsititutionjuridique), missing
replace take_up_per = take_up_per/10
replace take_up_per = 0 if surveyround == 1
replace take_up_per = 0 if surveyround == 2 & treatment == 0 

	* create a take_up
replace desistement_consortium = 1 if id_plateforme == 1040
replace desistement_consortium = 1 if id_plateforme == 1192

gen take_up = 0, a(take_up_per)
replace take_up= 1 if treatment == 1 & desistement_consortium != 1
lab var take_up "Consortium participant"
lab values take_up presence_status

	* create a status variable for surveys
gen status = (take_up_per > 0 & take_up_per < .)


* PHASE 2 of the treatment: "consortia export promotion"

}

***********************************************************************
* 	PART 2:  survey attrition (refusal to respond to survey)	
***********************************************************************
{
gen refus = 0 // zero for baseline as randomization only among respondents
lab var refus "Comapnies who refused to answer the survey" 

		* midline
replace refus = 1 if id_plateforme == 994 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1014 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1132 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1094 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1025 & surveyround == 2 // refusé de répondre et ne souhaitent ne plus être contactées
replace refus = 1 if id_plateforme == 1061 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1079 & surveyround == 2 // refus de répondre (baseline & midline) 
replace refus = 1 if id_plateforme == 1247 & surveyround == 2 // Demande de Eya de ne plus les contacter
replace refus = 1 if id_plateforme == 998  & surveyround == 2 // Demande de Eya de ne plus les contacter
replace refus = 1 if id_plateforme == 1067 & surveyround == 2 //Demande d'enlever tous ses informations de la base de contact
replace refus = 1 if id_plateforme == 1136 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1026 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1089 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1109 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1144 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1169 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1172 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1194 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1234 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1237 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1056 & surveyround == 2 // refus de répondre
replace refus = 1 if id_plateforme == 1074 & surveyround == 2 //refus de répondre
replace refus = 1 if id_plateforme == 1110 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1137 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1158 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1162 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1166 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1202 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1235 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1245 & surveyround == 2 //Refus de répondre 
replace refus = 1 if id_plateforme == 1112 & surveyround == 2 //Refus de répondre 


replace refus = 0 if id_plateforme == 1193 & surveyround == 2 //Refus de répondre aux informations comptables (survey not completed)
replace refus = 0 if id_plateforme == 1040 & surveyround == 2 //Refus de répondre aux informations comptables & employés (survey not completed)
replace refus = 0 if id_plateforme == 1057 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1219 & surveyround == 2 //Refus de répondre aux informations comptables & employés (survey not completed)
replace refus = 0 if id_plateforme == 1071 & surveyround == 2 //Refus de répondre aux corrections comptables
replace refus = 0 if id_plateforme == 1022 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1015 & surveyround == 2 //Refus de répondre aux informations comptables & employés
replace refus = 0 if id_plateforme == 1068 & surveyround == 2 //Refus de répondre aux informations comptables
replace refus = 1 if id_plateforme == 1168 & surveyround == 2 // Refus de répondre aux informations comptables

		* endline
local id 989 994 995 997 1004 1025 1031 1067 1074 1090 1094 1110 1124 1127 1136 1137 1154 1161 1162 1175 1202 1214 1219 1235 1241
foreach var of local id {
	replace refus = 1 if surveyround == 3 & id_plateforme == `var'
}
}
***********************************************************************
* 	PART 3:  entreprise no longer in operations	
***********************************************************************		
gen closed = 0 
lab var closed "Companies that are no longer operating"

replace closed = 1 if id_plateforme == 1083
replace closed = 1 if id_plateforme == 1059 
replace closed = 1 if id_plateforme == 1090
replace closed = 1 if id_plateforme == 1044

***********************************************************************
* 	PART 4:   Create total sales	+ positive profit  
***********************************************************************
gen sales = ca + ca_exp
	replace sales = ca if ca_exp == . & ca != .
	replace sales = ca_exp if ca == . & ca_exp != .

lab var sales "Total sales"

gen profit_pos = (profit > 0)
replace profit_pos = . if profit == .
lab var profit_pos "Profit > 0"

	*profit2024 positive
gen profit_2024_pos = 1 if profit_2024 >= 0
replace profit_2024_pos = 0 if profit_2024 < 0

lab var profit_2024_pos "Profit 2024 > 0"
***********************************************************************
*	PART 5: Exported dummy
***********************************************************************
gen exported = (ca_exp > 0)
replace exported = . if ca_exp == .
lab var exported "Export sales > 0"

gen exp_invested = (exp_inv > 0)
replace exp_invested = . if exp_inv == .
lab var exp_invested "Export investment > 0"


***********************************************************************
*	PART 6.1: Innovation
***********************************************************************	
egen innovations = rowtotal(inno_commerce inno_lieu inno_process inno_produit), missing
bys id_plateforme (surveyround): gen innovated = (innovations > 0)
	replace innovated = . if innovations == .
*br id_plateforme surveyround innovations innovated
lab var innovations "Total innovations"
lab var innovated "Innovated"

***********************************************************************
*	PART 6.2: Categorize the different types of innovation
***********************************************************************	
gen inno_product_imp = 0
lab var inno_product_imp "Improving the existing product"
gen inno_product_new = 0
lab var inno_product_new "New product innovation"
gen proc_prod_correct = 0 
replace proc_prod_correct =1 if inno_proc_met == 1
lab var proc_prod_correct "Innovation in the production process"
gen proc_mark_correct = 0
replace proc_mark_correct =1 if inno_proc_prix == 1 | inno_proc_log ==1
lab var proc_mark_correct "Innovation in sales and marketing techniques"
gen inno_org_correct = 0
replace inno_org_correct =1	if inno_proc_sup == 1
lab var inno_org_correct "Innovation in management techniques and organization"

*inno_product_imp
replace inno_product_imp =1 if id_plateforme == 984 /*changement de l’emballage, introduction des nouveaux jouets et des nouvelle gammes*/
replace inno_product_imp =1 if id_plateforme == 985 /*nous avons améliorés nos packagings, refaits le branding de la marque ainsi qu'une refonte de notre boutique en ligne*/
replace inno_product_imp =1 if id_plateforme == 990 /*yamlou deplacement lel jihet o yamloulhom des formation lapart f locale mte3hom o ykadmou des servies o amlou amenagement*/
replace inno_product_imp =1 if id_plateforme == 996 /*la gamme en cuir est augmenté elle diversifié la gamme de tissu*/
replace inno_product_imp =1 if id_plateforme == 1000 /*développement de la partie ia de la plateforme de résolution des conflits*/
replace inno_product_imp =1 if id_plateforme == 1001 /*la qualité des produits/ la création des nouveaux produits et l'accès aux nouveaux marchés*/
replace inno_product_imp =1 if id_plateforme == 1005 /*la création et la diminution de prix , améloration de qualité du tissu: il travaille l'haut gamme mais aussi, maintenant, la gamme moyenne*/
replace inno_product_imp =1 if id_plateforme == 1007 /*nouveau design */
replace inno_product_imp =1 if id_plateforme == 1009 /*nouveaux recrutements, conception et mise en place des projets de pergola avec les horeca (hotels)*/
replace inno_product_imp =1 if id_plateforme == 1013 /*amélioration de qualité de cuire de produit et amélioration de chaine de produit , amélioration de la finition des sac trouses ect */
replace inno_product_imp =1 if id_plateforme == 1019 /*services sous forme de chatroom en ligne /aamlt des améliorations au niveau de la plateforme*/
replace inno_product_imp =1 if id_plateforme == 1027 /*gamme de maquillage , améliorations fl laboratoire */
replace inno_product_imp =1 if id_plateforme == 1035 /*accompagnement et vulgarisation scientifique */
replace inno_product_imp =1 if id_plateforme == 1036 /*hasanet l'emballage/ hasanet fl les etiquette hasanet fl qualite produit /aamalet des coffret cadeaux double/simple */
replace inno_product_imp =1 if id_plateforme == 1041 /*emballage (étiquette,) w hasnet fl livraison */
replace inno_product_imp =1 if id_plateforme == 1043 /*produit publicitaires , importer des nouveaux produit naturels  et elle fait leurs chartes, elle fait des choses personnalisées en fonction de l'occasion ou de la demande du client*/
replace inno_product_imp =1 if id_plateforme == 1050 /*nous avons réalisé des innovations et des améliorations grâce à des systèmes personnalisés adaptés aux consommateurs*/
replace inno_product_imp =1 if id_plateforme == 1054 /*sacs en 5k/10k/25k */
replace inno_product_imp =1 if id_plateforme == 1055 /*nous avons augmenter le nombre de produits et nous avons change l'emballage*/
replace inno_product_imp =1 if id_plateforme == 1108 /*badalna logo w l embalage  callité espace ecologique en bois decoration  formation ferme pedagogique*/
replace inno_product_imp =1 if id_plateforme == 1119 /*ameliaration pour les mise a jour logiciel*/
replace inno_product_imp =1 if id_plateforme == 1124 /*taille et coulleur de produit*/
replace inno_product_imp =1 if id_plateforme == 1147 /*regrouper l'usine et le lieu de stockage au même endroit/on a amélioré le produit dans la quantite et des differentes qualités; des nouvelles textures et un nouveau emballage*/
replace inno_product_imp =1 if id_plateforme == 1151 /*des produits bio qui sont devenus plus bio à plus de 40%*/
replace inno_product_imp =1 if id_plateforme == 1167 /*amélioration de la qualité du produit et changement du fournisseur*/
replace inno_product_imp =1 if id_plateforme == 1186 /*changement de l'emballage extérieur des boites, tapis barbére , da5elna clim el halfa et zarbia dans le même produit*/
replace inno_product_imp =1 if id_plateforme == 1190 /*changement des types de produits élargir la gamme des produits*/
replace inno_product_imp =1 if id_plateforme == 1192 /*on a amélioré l'emballage, je vois ce que les consommateurs veulent et j'améliore le produit et j'ai fait une diversification des articles (des choses qui sortent de l'ordinaire)*/
replace inno_product_imp =1 if id_plateforme == 1193 /*sebigha , tatawer mantouj men naheyet afkar jdid khedma zdet hajet medhalat */
replace inno_product_imp =1 if id_plateforme == 1196 /*j'ai fait de nouvelles infusions destiné pour les femmes allaitantes / on a fait des améliorations dans la qualité de production/ on a rajouté dans production et qualité de la moringa*/
replace inno_product_imp =1 if id_plateforme == 1203 /*comme chaque année, nous sommes en amélioration continue du qualité du produit (choix des matières, finitions, sous-traitants) pour être plus adapter à l'export et aux normes internationales*/
replace inno_product_imp =1 if id_plateforme == 1117 /*changement du logo w couleur personamisé et création des parfum sur mesure */
replace inno_product_imp =1 if id_plateforme == 1182 /*on a un nouvel emballage carton,certification iso o des salariésresponsable qualité manajement o 2 nouveaux ouvriers*/
replace inno_product_imp =1 if id_plateforme == 1185 /*changement de design */
replace inno_product_imp =1 if id_plateforme == 1215 /*ré innovation : nouvelle étiquette, chart graphique*/
replace inno_product_imp =1 if id_plateforme == 1230 /*changement de l' emballage et qualité de produit */
replace inno_product_imp =1 if id_plateforme == 1240 /*améliorations et corrections des bugs de la plateforme*/
replace inno_product_imp =1 if id_plateforme == 1243 /*amelioration au niveau qualité des panneaux polyester c est un panneau composite rigide anti-flame densité 40*/
replace inno_product_imp =1 if id_plateforme == 1247 /*l'emballage et le design/ dans le produit que nous avons transformé avec des sucres naturels/ innovation dans la diversité des produits en produisant des produits biologiques comme les graines de lin*/

*inno_product_new
replace inno_product_new =1 if id_plateforme == 983 /*bsissa caroube*/
replace inno_product_new =1 if id_plateforme == 984 /*des nouvelles jouets en bois et des autres ustenside de cuisine */
replace inno_product_new =1 if id_plateforme == 985 /*nous avons intégrés la rubrique maroquinerie pour y proposer des sacs à main et des couffins pour nos clients*/
replace inno_product_new =1 if id_plateforme == 990 /*de nouvelles formations de coiffure, ils ont rajouté un atelier de coifire et la possibilité de se déplacer dans les différentes régions pour faire les formations*/
replace inno_product_new =1 if id_plateforme == 994 /*dentifrice naturelle dedorant natrurelle gommage visage*/
replace inno_product_new =1 if id_plateforme == 996 /*un autre modele de portfeuille de bloc note autres sac et ajouter les meme modelle des sac en tissue et une collection saaff o tissaage*/
replace inno_product_new =1 if id_plateforme == 999 /*nouvelle services de comptabilité carbone( déclaration de matériel ) */
replace inno_product_new =1 if id_plateforme == 1001 /*la qualité des produits/ la création des nouveaux produits et l'accès aux nouveaux marchés*/
replace inno_product_new =1 if id_plateforme == 1005 /*des jbeyeb (tenues traditionnelles masculines)*/
replace inno_product_new =1 if id_plateforme == 1010 /*gel fixateur */
replace inno_product_new =1 if id_plateforme == 1017 /*biscuit traditionnelle , biscuit secs , gamme sans sucres*/
replace inno_product_new =1 if id_plateforme == 1020 /*developement un systeme complet de production des plante adapter pour tous les types des climats*/
replace inno_product_new =1 if id_plateforme == 1027 /*concilier , eyeliner , blush , bodyblush  */
replace inno_product_new =1 if id_plateforme == 1028 /*je préfère que ca reste une information confidentiel et interne pour mes clients , c’est pas encore publié*/
replace inno_product_new =1 if id_plateforme == 1030 /*zedna fl nombre des employés / kabarna fl rendement / zedou des articles (assiette rond/ pizza)*/
replace inno_product_new =1 if id_plateforme == 1035 /*le conseil */
replace inno_product_new =1 if id_plateforme == 1036 /*hasanet l'emballage/ hasanet fl les etiquette hasanet fl qualite produit /aamalet des coffret cadeaux double/simple */
replace inno_product_new =1 if id_plateforme == 1038 /*on a rajouté des machines afin d'améliorer la capacité de production / introduire une nouvelle gamme dans secteur décoration ( céramique artistique )*/
replace inno_product_new =1 if id_plateforme == 1041 /*zedet fruits et légume surgelé */
replace inno_product_new =1 if id_plateforme == 1043 /*diversité des produits , je cible le consommateur, diversification des services*/
replace inno_product_new =1 if id_plateforme == 1046 /*ils proposent des services sur mesure */
replace inno_product_new =1 if id_plateforme == 1050 /*nous avons réalisé des innovations et des améliorations grâce à des systèmes personnalisés adaptés aux consommateurs// nous avons développé de nouvelles applications telles que rafekni et kesati*/
replace inno_product_new =1 if id_plateforme == 1054 /*sacs en 5k/10k/25k */
replace inno_product_new =1 if id_plateforme == 1055 /*les astrotorisme */
replace inno_product_new =1 if id_plateforme == 1057 /*variation des produits dérivés en collaboration avec de nouveaux artistes*/
replace inno_product_new =1 if id_plateforme == 1061 /*atelier créatifs pour adultes*/
replace inno_product_new =1 if id_plateforme == 1064 /*création de la gamme peau sensible avec la rose de kairouan :gel, crème, hydratante du jour crème nourrissante du soir,le sérum a base de hé de rose,et un savon// atelier de fabrication des huiles de massage */
replace inno_product_new =1 if id_plateforme == 1065 /*des produits cosmétiques et ont diversifié les produits de décoration*/
replace inno_product_new =1 if id_plateforme == 1068 /*a lancer gamme de shampoing et gel douche o des déo naturelle*/
replace inno_product_new =1 if id_plateforme == 1069 /*vidéo 3 d */
replace inno_product_new =1 if id_plateforme == 1081 /*tomùate, pimon , dele3 ,9ra3*/
replace inno_product_new =1 if id_plateforme == 1084 /*nouvelles formations : convention de partenariati avec la confédération italienne des héliciculteur*/
replace inno_product_new =1 if id_plateforme == 1087 /*deodorant /game cheuveux/huile essensielel*/
replace inno_product_new =1 if id_plateforme == 1096 /*extrait de mare de café */
replace inno_product_new =1 if id_plateforme == 1102 /*landaux, les couvres lits, décoration amigurumis etc*/
replace inno_product_new =1 if id_plateforme == 1112 /*des produit agro alimentaires */
replace inno_product_new =1 if id_plateforme == 1116 /*bonjour,  pour les lampadaires et les lampes on a changé de design nouvelle création: - fauteuil forme ronde avec fibres végétales - canapé ovale avec fibres végétales*/
replace inno_product_new =1 if id_plateforme == 1117 /*des bougies */
replace inno_product_new =1 if id_plateforme == 1122 /*parure de lit et ouss de lit */
replace inno_product_new =1 if id_plateforme == 1124 /*produit en gré */
replace inno_product_new =1 if id_plateforme == 1126 /*des nouvelles sacs a main en cuire */
replace inno_product_new =1 if id_plateforme == 1128 /*création et innovation de produit changer la formation des produit//des nouvelles forme de produit  */
replace inno_product_new =1 if id_plateforme == 1132 /*organisation des evenements*/
replace inno_product_new =1 if id_plateforme == 1135 /*lancement d'un nouveau produit : pour un cadeau (cookies m3a gourmandise)*/
replace inno_product_new =1 if id_plateforme == 1143 /*nouvelle ligne de bijoux fins pour une clientèle plus jeune*/
replace inno_product_new =1 if id_plateforme == 1147 /*maquillage: les écrans, de noveaux mascaras, gloss et pinceaux*/
replace inno_product_new =1 if id_plateforme == 1151 /*des confitures, sauce tomate, jus de citronade*/
replace inno_product_new =1 if id_plateforme == 1153 /*d'autres produits et services digital ,*/
replace inno_product_new =1 if id_plateforme == 1157 /*audit interne de securité */
replace inno_product_new =1 if id_plateforme == 1164 /*on rajouté une nouvelle ligne de produits énérgétiques/ packs de produits/ des formations gratuites pour les femmes// des confitures de tomates sucrées + de nouveaux parfums pour les pâtes à tartiner*/
replace inno_product_new =1 if id_plateforme == 1167 /*sacs de soiré /accesoire de soiré*/
replace inno_product_new =1 if id_plateforme == 1170 /*de nouvelles solutions digitales, on a rajouté dans la quantité et de nouveaux partenariats en Afrique*/
replace inno_product_new =1 if id_plateforme == 1176 /*nouvelle conception et liaison intelligente */
replace inno_product_new =1 if id_plateforme == 1182 /*une gamme luvia c serum o mousse o creme b vitamine c */
replace inno_product_new =1 if id_plateforme == 1185 /*des articles de cadeaux, Haïk Kamraya, des sacs et des pochette sur taille de pc block note*/
replace inno_product_new =1 if id_plateforme == 1186 /*abajoret bil 7alfa w souf */
replace inno_product_new =1 if id_plateforme == 1190 /*les étagères les corbeilles ala base de thmara avec du verre lhsor avec thmara et a travers le tissage*/
replace inno_product_new =1 if id_plateforme == 1192 /*on a amélioré l'emballage, je vois ce que les consommateurs veulent et j'améliore le produit et j'ai fait une diversification des articles (des choses qui sortent de l'ordinaire)//j'ai fait une évolution avec la paille/ j'ai fait des chnagement avec le mais pour les personnes qui ont des maladies infectieuses et les personnes qui souhaitent faire un régime*/
replace inno_product_new =1 if id_plateforme == 1193 /*sebigha , tatawer mantouj men naheyet afkar jdid khedma zdet hajet medhalat // zedet el medhalat , zedet aalam tounes bel halfa  */
replace inno_product_new =1 if id_plateforme == 1196 /*j'ai fait de nouvelles infusions destiné pour les femmes allaitantes / on a fait des améliorations dans la qualité de production/ on a rajouté dans production et qualité de la moringa// diversité des infusion pour le bien-être ( exp: constipation) / poudre de moringa*/
replace inno_product_new =1 if id_plateforme == 1197 /*j'ai travaillé des modèles traditionnels et modernes*/
replace inno_product_new =1 if id_plateforme == 1203 /*produit : une nouvelle collection uni-sexe (adpatation à notre demande feminine et masculine à la fois)*/
replace inno_product_new =1 if id_plateforme == 1205 /*ajout des soins spécifiques avec la nouvelle machine hydrafacial// fabrication des soins capillaires naturelset skin care safe*/
replace inno_product_new =1 if id_plateforme == 1210 /*service dans le domaine de sport*/
replace inno_product_new =1 if id_plateforme == 1215 /*coffret cadeau*/
replace inno_product_new =1 if id_plateforme == 1222 /*le conseil, audit*/
replace inno_product_new =1 if id_plateforme == 1224 /*développement des nouveaux produit,//écran (3 types: invisible, teinté beige clair, beige rosé)*/
replace inno_product_new =1 if id_plateforme == 1230 /*changement de la quantité de produit innovation de bssissa avec du chocolats et des fruits secs et goutée pour les enfants*/
replace inno_product_new =1 if id_plateforme == 1234 /*des nouvelles création des produits */
replace inno_product_new =1 if id_plateforme == 1239 /*odoo et la partie marketing*/
replace inno_product_new =1 if id_plateforme == 1243 /*installation des groupe frigorifique daikin et intégré la nouvelle technologie de gamme daikin zeas mini centrale frigorifique en tunisie*/
replace inno_product_new =1 if id_plateforme == 1244 /*ajout de volet formation au services fournis par le bureau*/
replace inno_product_new =1 if id_plateforme == 1245 /*des nouvelles création des produits */
replace inno_product_new =1 if id_plateforme == 1247 /*l'emballage et le design/ dans le produit que nous avons transformé avec des sucres naturels/ innovation dans la diversité des produits en produisant des produits biologiques comme les graines de lin sucret salé b texture jdida / le fandant */


*proc_prod_correct
replace proc_prod_correct =1 if id_plateforme == 990 /*yamlou deplacement lel jihet o yamloulhom des formation lapart f locale mte3hom o ykadmou des servies o amlou amenagement */
replace proc_prod_correct =1 if id_plateforme == 996 /*la gamme en cuir est augmenté elle diversifié la gamme de tissu*/
replace proc_prod_correct =1 if id_plateforme == 1001 /*la qualité des produits/ la création des nouveaux produits et l'accès aux nouveaux marchés*/
replace proc_prod_correct =1 if id_plateforme == 1005 /*la création et la diminution de prix , améloration de qualité du tissu: il travaille l'haut gamme mais aussi, maintenant, la gamme moyenne*/
replace proc_prod_correct =1 if id_plateforme == 1013 /*amélioration de qualité de cuire de produit et amélioration de chaine de produit , amélioration de la finition des sac trouses ect */
replace proc_prod_correct =1 if id_plateforme == 1020 /*elle a l'intention d'introduire un planning des matières nouvelles afin de faciliter le travail et réduire le coût de production*/
replace proc_prod_correct =1 if id_plateforme == 1027 /*de nouveaux employes et de nouvelles matières ont été rajoutés*/
replace proc_prod_correct =1 if id_plateforme == 1036 /*elle a aggrandit l'espace de stockage et les touriste viennent pour voir l'expérience*/
replace proc_prod_correct =1 if id_plateforme == 1046 /*le local a changé */
replace proc_prod_correct =1 if id_plateforme == 1068 /*elle a changé de local*/
replace proc_prod_correct =1 if id_plateforme == 1108 /*mise en place de panneaux solaires pour génerer l'éclectricité dans sa ferme*/
replace proc_prod_correct =1 if id_plateforme == 1126 /*changement de l’atelier o elle travaille plus sur le marketing digitale*/
replace proc_prod_correct =1 if id_plateforme == 1128 /*changement de local*/
replace proc_prod_correct =1 if id_plateforme == 1147 /*le systheme erp cest la gestion de commande et de fourniseurs et des espace et des machines*/
replace proc_prod_correct =1 if id_plateforme == 1164 /*ajout d'une nouvelle ligne de production + prospection de marché à l'étranger*/
replace proc_prod_correct =1 if id_plateforme == 1192 /*elle a augmenté le nombre d'employés afin d'améliorer la production et augmenter la rapidité du traail + elle a travoué de nouvelles méthodes de travail où elle donne la majorité du travail aux employés et elle prends la responsabilité et s'occupe du suivi du travail*/
replace proc_prod_correct =1 if id_plateforme == 1193 /*ghayart fl mantoujet aamalt midhalet bel halfa*/
replace proc_prod_correct =1 if id_plateforme == 1230 /*le local a été aggrandi*/
replace proc_prod_correct =1 if id_plateforme == 1248 /*intégration de nouveaux matériaux*/
replace proc_prod_correct =1 if id_plateforme == 1020 /*developement un systeme complet de production des plante adapter pour tous les types des climats*/
replace proc_prod_correct =1 if id_plateforme == 1030 /*zedna fl nombre des employés / kabarna fl rendement / zedou des articles (assiette rond/ pizza)*/
replace proc_prod_correct =1 if id_plateforme == 1036 /*hasanet l'emballage/ hasanet fl les etiquette hasanet fl qualite produit /aamalet des coffret cadeaux double/simple */
replace proc_prod_correct =1 if id_plateforme == 1038 /*on a rajouté des machines afin d'améliorer la capacité de production / introduire une nouvelle gamme dans secteur décoration ( céramique artistique )*/
replace proc_prod_correct =1 if id_plateforme == 1046 /*des nouvelles techniques et de nouveaux outils d'auteur dans la création de contenus*/
replace proc_prod_correct =1 if id_plateforme == 1055 /*nous avons augmenter le nombre de produits et nous avons change l'emballage*/
replace proc_prod_correct =1 if id_plateforme == 1087 /*la certifaction /recouler la game cheuveux/ lemballage /qutite des produits*/
replace proc_prod_correct =1 if id_plateforme == 1096 /*certification iso 22716*/
replace proc_prod_correct =1 if id_plateforme == 1112 /*matériaux de construction */
replace proc_prod_correct =1 if id_plateforme == 1186 /*changement de l'emballage extérieur des boites, tapis barbére , da5elna clim el halfa et zarbia dans le même produit*/
replace proc_prod_correct =1 if id_plateforme == 1193 /*sebigha , tatawer mantouj men naheyet afkar jdid khedma zdet hajet medhalat */
replace proc_prod_correct =1 if id_plateforme == 1196 /*j'ai fait de nouvelles infusions destiné pour les femmes allaitantes / on a fait des améliorations dans la qualité de production/ on a rajouté dans production et qualité de la moringa*/
replace proc_prod_correct =1 if id_plateforme == 1203 /*comme chaque année, nous sommes en amélioration continue du qualité du produit (choix des matières, finitions, sous-traitants) pour être plus adapter à l'export et aux normes internationales*/
replace proc_prod_correct =1 if id_plateforme == 1205 /*ajout des soins spécifiques avec la nouvelle machine hydrafacial*/
replace proc_prod_correct =1 if id_plateforme == 1247 /*l'emballage et le design/ dans le produit que nous avons transformé avec des sucres naturels/ innovation dans la diversité des produits en produisant des produits biologiques comme les graines de lin*/
replace proc_prod_correct =1 if id_plateforme == 1248 /*la qualite de la chaine de production qui est devenue plus petite et la qualite de production*/

*proc_mark_correct
replace proc_mark_correct =1 if id_plateforme == 984 /*changement de l’emballage, introduction des nouveaux jouets et des nouvelle gammes*/
replace proc_mark_correct =1 if id_plateforme == 985 /*nous avons améliorés nos packagings, refaits le branding de la marque ainsi qu'une refonte de notre boutique en ligne*/
replace proc_mark_correct =1 if id_plateforme == 1005 /*la création et la diminution de prix , améloration de qualité du tissu: il travaille l'haut gamme mais aussi, maintenant, la gamme moyenne*/
replace proc_mark_correct =1 if id_plateforme == 1010 /*ils ont intégré du commercial et ont un nouvel canal de distribution*/
replace proc_mark_correct =1 if id_plateforme == 1017 /*b2b, pause cafe ,evenement, site web , logiciel erp */
replace proc_mark_correct =1 if id_plateforme == 1019 /*ils ont fait des changements au niveau des offres et ont fait des changements dans les packs services*/
replace proc_mark_correct =1 if id_plateforme == 1030 /*services marketing en ligne/ on a travaillé sur l'image de marque/ site web en cours pour les ventes en ligne/ j'ai fait un logiciel interne personnalisé*/
replace proc_mark_correct =1 if id_plateforme == 1035 /*par rapport aux communications plus networking , participation aux evenemnets d'ordre professionnel*/
replace proc_mark_correct =1 if id_plateforme == 1038 /*elles ont travaillés sur des formations techniques (pratiques), ont rajouté des workshops pour les petits et se sont concentrés plus sur le digital*/
replace proc_mark_correct =1 if id_plateforme == 1043 /*site web , sponsoring , les promotions, application mobile*/
replace proc_mark_correct =1 if id_plateforme == 1054 /*elle a fait un site web*/
replace proc_mark_correct =1 if id_plateforme == 1118 /*informations , technique de commmunication avec le client*/
replace proc_mark_correct =1 if id_plateforme == 1126 /*changement de l’atelier o elle travaille plus sur le marketing digitale*/
replace proc_mark_correct =1 if id_plateforme == 1182 /*ajout d'une charte graphique, changement de l'emballage, changement du site web et de nouveaux catalogues*/
replace proc_mark_correct =1 if id_plateforme == 1215 /*actions de marketing*/
replace proc_mark_correct =1 if id_plateforme == 1036 /*hasanet l'emballage/ hasanet fl les etiquette hasanet fl qualite produit /aamalet des coffret cadeaux double/simple */
replace proc_mark_correct =1 if id_plateforme == 1041 /*emballage (étiquette,) w hasnet fl livraison */
replace proc_mark_correct =1 if id_plateforme == 1055 /*nous avons augmenter le nombre de produits et nous avons change l'emballage*/
replace proc_mark_correct =1 if id_plateforme == 1065 /*marketing*/
replace proc_mark_correct =1 if id_plateforme == 1071 /*meilleur organisation du processus interne, meilleur effort commercial, la prise de décision documenté et organisé*/
replace proc_mark_correct =1 if id_plateforme == 1087 /*la certifaction /recouler la game cheuveux/ lemballage /qutite des produits*/
replace proc_mark_correct =1 if id_plateforme == 1108 /*badalna logo w l embalage  callité espace ecologique en bois decoration  formation ferme pedagogique*/
replace proc_mark_correct =1 if id_plateforme == 1117 /*changement du logo w couleur personamisé et création des parfum sur mesure */
replace proc_mark_correct =1 if id_plateforme == 1126 /*elle travaille sur le marketing digitale o elle lancer un site de l’export a l’internationale */
replace proc_mark_correct =1 if id_plateforme == 1147 /*regrouper l'usine et le lieu de stockage au même endroit/on a amélioré le produit dans la quantite et des differentes qualités; des nouvelles textures et un nouveau emballage*/
replace proc_mark_correct =1 if id_plateforme == 1182 /*on a un nouvel emballage carton,certification iso o des salariésresponsable qualité manajement o 2 nouveaux ouvriers*/
replace proc_mark_correct =1 if id_plateforme == 1185 /*changement de design */
replace proc_mark_correct =1 if id_plateforme == 1186 /*changement de l'emballage extérieur des boites, tapis barbére , da5elna clim el halfa et zarbia dans le même produit*/
replace proc_mark_correct =1 if id_plateforme == 1192 /*on a amélioré l'emballage, je vois ce que les consommateurs veulent et j'améliore le produit et j'ai fait une diversification des articles (des choses qui sortent de l'ordinaire)*/
replace proc_mark_correct =1 if id_plateforme == 1215 /*ré innovation : nouvelle étiquette, chart graphique*/
replace proc_mark_correct =1 if id_plateforme == 1230 /*changement de l' emballage et qualité de produit */
replace proc_mark_correct =1 if id_plateforme == 1247 /*l'emballage et le design/ dans le produit que nous avons transformé avec des sucres naturels/ innovation dans la diversité des produits en produisant des produits biologiques comme les graines de lin*/

*inno_org_correct 
replace inno_org_correct =1 if id_plateforme == 990 /*yamlou deplacement lel jihet o yamloulhom des formation lapart f locale mte3hom o ykadmou des servies o amlou amenagement */
replace inno_org_correct =1 if id_plateforme == 1005 /*des formations pour les employés afin de garantir la durabilté des produits artisanaux*/
replace inno_org_correct =1 if id_plateforme == 1009 /*nouveaux recrutements, conception et mise en place des projets de pergola avec les horeca (hotels)*/
replace inno_org_correct =1 if id_plateforme == 1017 /*aménagement, extension du laboratoire*/
replace inno_org_correct =1 if id_plateforme == 1020 /*elle a l'intention d'introduire un planning des matières nouvelles afin de faciliter le travail et réduire le coût de production*/
replace inno_org_correct =1 if id_plateforme == 1030 /*elle a changé l'organisation du management intérieur*/
replace inno_org_correct =1 if id_plateforme == 1050 /*nous avons adopté de nouvelles stratégies dans le recrutement, telles que les techniciens supérieurs sont devenus aussi prisés que les ingénieurs ( walew yesaktbou akther des techniciens sup)*/
replace inno_org_correct =1 if id_plateforme == 1071 /*team building*/
replace inno_org_correct =1 if id_plateforme == 1087 /*les compétences de l'équipe et de nouveaux recrutements*/
replace inno_org_correct =1 if id_plateforme == 1108 /*mise en place de panneaux solaires pour génerer l'éclectricité dans sa ferme*/
replace inno_org_correct =1 if id_plateforme == 1132 /*aggrandissement de l'équipe et de nouveaux bureaux*/
replace inno_org_correct =1 if id_plateforme == 1147 /*le systheme erp cest la gestion de commande et de fourniseurs et des espace et des machines*/
replace inno_org_correct =1 if id_plateforme == 1192 /*elle a augmenté le nombre d'employés afin d'améliorer la production et augmenter la rapidité du traail + elle a travoué de nouvelles méthodes de travail où elle donne la majorité du travail aux employés et elle prends la responsabilité et s'occupe du suivi du travail*/
replace inno_org_correct =1 if id_plateforme == 1247 /*changement de formation personnels et les technique et le loi pour les personnel*/
replace inno_org_correct =1 if id_plateforme == 1057 /*arrondissement de l équipe, développement de stratégie*/
replace inno_org_correct =1 if id_plateforme == 1071 /*meilleur organisation du processus interne, meilleur effort commercial, la prise de décision documenté et organisé*/
replace inno_org_correct =1 if id_plateforme == 1096 /*certification iso 22716*/
replace inno_org_correct =1 if id_plateforme == 1147 /*regrouper l'usine et le lieu de stockage au même endroit/on a amélioré le produit dans la quantite et des differentes qualités; des nouvelles textures et un nouveau emballage*/
replace inno_org_correct =1 if id_plateforme == 1157 /*amelioration interne au niveau des mesures de securité des donnees de la ste qui va aussi impacter la securité des donnees de nos clients */
replace inno_org_correct =1 if id_plateforme == 1176 /*des nouvelles technologies par exp: des nouveau protocoles de communication*/
replace inno_org_correct =1 if id_plateforme == 1182 /*on a un nouvel emballage carton,certification iso o des salariésresponsable qualité manajement o 2 nouveaux ouvriers*/
replace inno_org_correct =1 if id_plateforme == 1239 /*odoo et tecnologie web */
replace inno_org_correct =1 if id_plateforme == 1244 /*suivi des chantiers verts/mangemenet des projets plus adapté/améliorer la gestion financière*/

***********************************************************************
*	PART 7: network
***********************************************************************	
	* create total network size
gen net_size =.
		* combination of female and male CEOs at midline
replace net_size = net_nb_f + net_nb_m if surveyround ==2
		* combination of within family and outside family at baseline
replace net_size = net_nb_fam + net_nb_dehors if surveyround ==1

lab var net_size "Network size"


***********************************************************************
* 	PART 8:   Create the indices based on a z-score			  
***********************************************************************

{
	*Definition of all variables that are being used in index calculation
local allvars man_fin_per_fre car_loc_exp man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme exp_inv exprep_couts exp_pays exp_afrique car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5 exp_pays_ssa clients_ssa clients_ssa_commandes man_hr_pro man_fin_num employes sales profit inno_improve inno_new inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres man_fin_per_qua man_fin_per_emp man_fin_per_liv man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa man_fin_per_ind man_fin_per_pro man_fin_per_sto exported export_1 export_2 ca ca_exp ca_2024 ca_exp_2024 profit_2024 exp_pra_vent car_efi_man car_efi_motiv car_loc_soin net_association net_size3 net_gender3_giz net_services_pratiques net_services_produits net_services_mark net_services_sup net_services_contract net_services_confiance net_services_autre net_coop_pos net_coop_neg
ds `allvars', has(type string)

	* Create temporary variable
foreach var of local allvars {
	g temp_`var' = `var'
    replace temp_`var' = . if `var' == 999 // don't know transformed to missing values
    replace temp_`var' = . if `var' == 888 
    replace temp_`var' = . if `var' == 777 
    replace temp_`var' = . if `var' == 666 
	replace temp_`var' = . if `var' == -999 // added - since we transformed profit into negative in endline
    replace temp_`var' = . if `var' == -888
    replace temp_`var' = . if `var' == -777
    replace temp_`var' = . if `var' == -666
    replace temp_`var' = . if `var' == 1234 
}

	* calculate z-score for each individual outcome
		* write a program calculates the z-score
			* if you re-run the code, execture before: 
capture program drop zscore
program define zscore /* opens a program called zscore */
	sum `1' if treatment == 0
	gen `1'z = (`1' - r(mean))/r(sd) /* new variable gen is called --> varnamez */
end

		* calcuate the z-score for each variable
foreach var of local allvars {
	zscore temp_`var'
}

	* calculate the index value: average of zscores 
			* networking
egen network = rowmean(temp_net_associationz temp_net_size3z temp_net_gender3_gizz temp_net_services_pratiquesz temp_net_services_produitsz temp_net_services_markz temp_net_services_supz temp_net_services_contractz temp_net_services_confiancez temp_net_services_autrez temp_net_coop_posz temp_net_coop_negz)

			* export readiness index (eri)
egen eri = rowmean(temp_exprep_normez temp_exp_pra_ciblez temp_exp_pra_missionz temp_exp_pra_douanez temp_exp_pra_planz temp_exp_pra_rexpz temp_exp_pra_foirez temp_exp_pra_sciz temp_exp_pra_ventz)			
			
			* export readiness SSA index (eri_ssa)
egen eri_ssa = rowmean(temp_ssa_action1z temp_ssa_action2z temp_ssa_action3z temp_ssa_action4z temp_ssa_action5z temp_exp_pays_ssaz temp_clients_ssaz temp_clients_ssa_commandesz) 

			* export performance
egen epp = rowmean(temp_exportedz temp_export_1z temp_export_2z temp_exp_paysz temp_ca_expz)

			*Innovation practices index
egen ipi = rowmean(temp_inno_improvez temp_inno_newz temp_inno_proc_metz temp_inno_proc_logz temp_inno_proc_prixz temp_inno_proc_supz temp_inno_proc_autresz) 
			
			* business performance
egen bpi = rowmean(temp_employesz temp_salesz temp_profitz)
egen bpi_2024 = rowmean(temp_employesz temp_ca_2024z temp_profit_2024z)

			* management practices (mpi)

egen mpi = rowmean(temp_man_hr_objz temp_man_hr_feedz temp_man_pro_anoz temp_man_fin_enrz temp_man_fin_profitz temp_man_fin_perz temp_man_hr_proz temp_man_fin_numz temp_man_fin_per_indz temp_man_fin_per_proz temp_man_fin_per_quaz temp_man_fin_per_stoz temp_man_fin_per_empz temp_man_fin_per_livz temp_man_fin_per_frez temp_man_fin_pra_budz temp_man_fin_pra_proz temp_man_fin_pra_disz temp_man_ind_awaz) // added at midline: man_ind_awa man_fin_per_fre instead of man_fin_per, man_hr_feed, man_hr_pro			
			* marketing practices index (marki)
egen marki = rowmean(temp_man_mark_prixz temp_man_mark_divz temp_man_mark_clientsz temp_man_mark_offrez temp_man_mark_pubz)
egen mpmarki = rowmean(mpi marki)
			
			* female empowerment index (genderi)
				* locus of control "believe that one has control over outcome, as opposed to external forces"
				* efficacy "the ability to produce a desired or intended result."
				* sense of initiative
egen female_efficacy = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz temp_car_efi_manz temp_car_efi_motivz)
egen female_initiative = rowmean(temp_car_init_probz temp_car_init_initz temp_car_init_oppz)
egen female_loc = rowmean(temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz temp_car_loc_envz temp_car_loc_expz temp_car_loc_soinz)

egen genderi = rowmean(temp_car_efi_fin1z temp_car_efi_negoz temp_car_efi_convz temp_car_efi_manz temp_car_efi_motivz temp_car_init_probz temp_car_init_initz temp_car_init_oppz temp_car_loc_succz temp_car_loc_envz temp_car_loc_inspz temp_car_loc_envz temp_car_loc_expz temp_car_loc_soinz)

		* labeling
label var network "Network"
label var eri "Export readiness"
label var eri_ssa "Export readiness SSA"
label var epp "Export performance"
label var mpi "Management practices"
label var marki "Marketing practices"
label var female_efficacy "Effifacy"
label var female_initiative "Initiaitve"
label var female_loc "Locus of control"
label var genderi "Entrepreneurial empowerment"
label var ipi "Innovation practices index -Z Score"
label var bpi "Business performance index- Z-score"
label var bpi_2024 "Business performance index- Z-score in 2024"

}

***********************************************************************
* 	PART 9:   Create the indices as total points		  
***********************************************************************
{
	* find out max. points
sum temp_man_hr_obj temp_man_hr_feed temp_man_pro_ano temp_man_fin_enr temp_man_fin_profit temp_man_fin_per temp_man_hr_pro temp_man_fin_num temp_man_fin_per_ind temp_man_fin_per_pro temp_man_fin_per_qua temp_man_fin_per_sto temp_man_fin_per_emp temp_man_fin_per_liv temp_man_fin_per_fre temp_man_fin_pra_bud temp_man_fin_pra_pro temp_man_fin_pra_dis temp_man_ind_awa
sum temp_man_mark_prix temp_man_mark_div temp_man_mark_clients temp_man_mark_offre temp_man_mark_pub
sum temp_exprep_norme temp_exp_pra_cible temp_exp_pra_mission temp_exp_pra_douane temp_exp_pra_plan temp_exp_pra_rexp temp_exp_pra_foire temp_exp_pra_sci temp_exp_pra_vent
sum temp_car_efi_fin1 temp_car_efi_nego temp_car_efi_conv temp_car_efi_man temp_car_efi_motiv temp_car_init_prob temp_car_init_init temp_car_init_opp temp_car_loc_succ temp_car_loc_env temp_car_loc_insp temp_car_loc_env temp_car_loc_exp temp_car_loc_soin
sum temp_exprep_norme temp_exp_inv temp_exprep_couts temp_exp_pays temp_exp_afrique
sum temp_inno_improve temp_inno_new temp_inno_proc_met temp_inno_proc_log temp_inno_proc_prix temp_inno_proc_sup temp_inno_proc_autres
	
	* create total points per index dimension
			* export readiness index (eri) 
egen eri_points = rowtotal(exprep_norme exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_vent), missing			
			
			* export readiness SSA index (eri_ssa) 
egen eri_ssa_points = rowtotal(ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5), missing

			* management practices (mpi)  
egen mpi_points = rowtotal(man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per temp_man_hr_pro man_fin_num man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa), missing
			
			* marketing practices index (marki) 
egen marki_points = rowtotal(man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub), missing
			
			*Innovation index
egen inno_points = rowtotal(inno_improve inno_new inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres), missing 

			* female empowerment index (genderi)
				* locus of control "believe that one has control over outcome, as opposed to external forces"
				* efficacy "the ability to produce a desired or intended result."
				* sense of initiative
egen female_efficacy_points = rowtotal(car_efi_fin1 car_efi_nego car_efi_conv car_efi_man car_efi_motiv), missing
egen female_initiative_points = rowtotal(car_init_prob car_init_init car_init_opp), missing
egen female_loc_points = rowtotal(car_loc_succ car_loc_env car_loc_insp car_loc_env car_loc_exp car_loc_soin), missing

egen genderi_points = rowtotal(car_efi_fin1 car_efi_nego car_efi_conv car_efi_man car_efi_motiv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp car_loc_env car_loc_exp car_loc_soin), missing

		* labeling
label var eri_points "Export readiness index points"
label var eri_ssa_points "Export readiness SSA index points"
label var mpi_points "Management practices index points"
label var marki_points "Marketing practices index points"
label var female_efficacy_points "Women's entrepreneurial effifacy points"
label var female_initiative_points "Women's entrepreneurial initiaitve points"
label var female_loc_points "Women's locus of control points"
label var genderi_points "Gender index points"
label var inno_points "Innovation practices index points"

	* drop temporary vars		  										  
drop temp_*

}

***********************************************************************
* 	PART 10:   generate survey-to-survey growth rates
***********************************************************************
	* accounting variables
local acccounting_vars "ca ca_exp profit employes"
foreach var of local acccounting_vars {
		bys id_plateforme: g `var'_rel_growth = D.`var'/L.`var'
			bys id_plateforme: replace `var'_rel_growth = . if `var' == -999 | `var' == -888
		bys id_plateforme: g `var'_abs_growth = D.`var' if `var' != -999 | `var' != -888
			bys id_plateforme: replace `var'_abs_growth = . if `var' == -999 | `var' == -888

}

/*
use links to understand the code syntax for creating the accounting variables' growth rates:
- https://www.stata.com/statalist/archive/2008-10/msg00661.html
- https://www.stata.com/support/faqs/statistics/time-series-operators/

*/

***********************************************************************
*	PART 11: Continuous outcomes (winsorization + ihs-transformation)
***********************************************************************

{
	* log-transform capital invested
foreach var of varlist capital ca employes {
	gen l`var' = log(`var')	
}
	
	* quantile transform profits --> see Delius and Sterck 2020 : https://oliviersterck.files.wordpress.com/2020/12/ds_cash_transfers_microenterprises.pdf
gen profit_pct = .
	egen profit_pct1 = rank(profit) if surveyround == 1	& !inlist(profit, -777, -888, -999, .)	// use egen rank to get the rank of each value in the distribution of profits
	sum profit if surveyround == 1 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct1/(`r(N)' + 1) if surveyround == 1			// divide by N + 1 to get a percentile for each observation
	
	egen profit_pct2 = rank(profit) if surveyround == 2 & !inlist(profit, -777, -888, -999, .)
	sum profit if surveyround == 2 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct2/(`r(N)' + 1) if surveyround == 2

	egen profit_pct3 = rank(profit) if surveyround == 3 & !inlist(profit, -777, -888, -999, 999, 888, 777, 1234, .)
	sum profit if surveyround == 3 & !inlist(profit, -777, -888, -999, .)
	replace profit_pct = profit_pct3/(`r(N)' + 1) if surveyround == 3


	*egen profit_pct4 = rank(comp_benefice2024) if surveyround == 3 & !inlist(comp_benefice2024, -777, -888, -999, 1234, .)
	*sum profit if surveyround == 3 & !inlist(profit, -777, -888, -999, .)
	*replace profit_pct = profit_pct2/(`r(N)' + 1) if surveyround == 3
	
	drop profit_pct1 profit_pct2 profit_pct3

	*Generate cost variable
	gen costs = ca - profit_pct
	lab var costs "Costs"
	
	* winsorize
		* winsorize all outcomes (but profit)
local wins_vars "capital ca ca_exp sales exp_inv employes car_empl1 car_empl2 exp_pays inno_rd net_size net_nb_f net_nb_m net_nb_dehors net_nb_fam ca_2024 ca_exp_2024 net_association net_size3 net_size4 net_gender3 net_size3_m net_size4_m net_gender4 net_gender3_giz clients clients_ssa clients_ssa_commandes"

foreach var of local wins_vars {
		gen `var'_w99 = .
		gen `var'_w95 = .
}

forvalues s = 1(1)3 {
	foreach var of local wins_vars {
		replace `var' = . if `var' == 999  // don't know transformed to missing values
		replace `var' = . if `var' == 888 
		replace `var' = . if `var' == 777 
		replace `var' = . if `var' == 666 
		replace `var' = . if `var' == -999 // added - since we transformed profit into negative in endline
		replace `var' = . if `var' == -888 
		replace `var' = . if `var' == -777 
		replace `var' = . if `var' == -666 
		replace `var' = . if `var' == 1234

		winsor2 `var' if surveyround == `s', suffix(_`s'w99) cuts(1 99)  // winsorize
		replace `var'_w99 = `var'_`s'w99 if surveyround ==  `s'
		
		winsor2 `var' if surveyround == `s', suffix(_`s'w95) cuts(5 95)  // winsorize
		replace `var'_w95 = `var'_`s'w95 if surveyround ==  `s'
					}
								}


		* profit
winsor2 profit, suffix(_w99) cuts(1 99) // winsorize also at lowest percentile to reduce influence of negative outliers
winsor2 profit, suffix(_w95) cuts(5 95) // winsorize also at lowest percentile to reduce influence of negative outliers

winsor2 profit_2024, suffix(_w99) cuts(1 99) // winsorize also at lowest percentile to reduce influence of negative outliers
winsor2 profit_2024, suffix(_w95) cuts(5 95) // winsorize also at lowest percentile to reduce influence of negative outliers

************ generate costs & local sales ************

gen costs_w99 = ca_w99 - profit_w99
lab var costs_w99 "Costs wins. 99th"

gen costs_2024_w99 = ca_2024_w99 - profit_2024_w99
lab var costs_2024_w99 "Costs 2024 wins. 99th"

gen localsales_w99 = ca_w99 - ca_exp_w99
lab var localsales_w99 "Domestic sales 2023 wins. 99th"

gen localsales2024_w99 = ca_2024_w99 - ca_exp_2024_w99
lab var localsales2024_w99 "Domestic sales 2024 wins. 99th"

************************************************************

	* find optimal k before ihs-transformation
		* see Aihounton & Henningsen 2021 for methodological approach

		* put all ihs-transformed outcomes in a list
local ys "employes_w99 car_empl1_w99 car_empl2_w99 sales_w99 exp_inv_w99 exp_pays_w99 employes_w95 car_empl1_w95 car_empl2_w95 ca_w95 ca_exp_w95 sales_w95 profit_w95 exp_inv_w95 exp_pays_w95 profit_2024_w99 ca_w99 ca_exp_2024_w99 profit_w99 costs_w99 costs_2024_w99 ca_exp_w99 ca_2024_w99 localsales2024_w99 localsales_w99"  // add at endline: exp_pays_w9
     

		* check how many zeros
foreach var of local ys {
		sum `var' if surveyround == 2 & !inlist(`var', -777, -888, -999,.)
		local N = `r(N)'
		sum `var' if `var' == 0 & surveyround == 2
		local zeros = `r(N)'
		scalar perc = `zeros'/`N'
		if perc > 0.05 {
			display "`var' has `zeros' zeros out of `N' non-missing observations ("perc "%)."
			}
	scalar drop perc
}

		* generate re-scaled outcome variables
foreach var of local ys {
				* k = 1, 10^3-10^6
	if !inlist(`var', employes_w99, car_empl1_w99, car_empl2_w99) {
		gen `var'_k1   = `var'
		forvalues k = 3(1)6 {
			local i = `k' - 1
			gen `var'_k`i' = `var' / 10^`k' if !inlist(`var', ., -777, -888, -999)
			lab var `var'_k`i' "`var' wins., scaled by 10^`k'" 
			}
	}
				* k = 1, 10^1-10^3
	else {
		gen `var'_k1   = `var'
		forvalues k = 1(1)3 {
			local i = 1 +`k'
			gen `var'_k`i' = `var' / 10^`k' if !inlist(`var', ., -777, -888, -999)
			lab var `var'_k`i' "`var' wins., scaled by 10^`k'" 
			}
		}
	}

		* ihs-transform all rescaled numerical variables
foreach var of local ys {
		ihstrans `var'_k?, prefix(ihs_) 
}

/*		* visualize distribution of ihs-transformed, rescaled variables
foreach var of local ys {
	if !inlist(`var', employes_w99, car_empl1_w99, car_empl2_w99) {
		local powers "1 10^3 10^4 10^5 10^6"
		forvalues i = 1(1)5 {
			gettoken power powers : powers
				if `var' == profit_w99 {
				histogram ihs_`var'_k`i', start(-16) width(1)  ///
					name(`var'`i', replace) ///
					title("IHS-Tranformed `var': K = `power'")
					}
				else {
				histogram ihs_`var'_k`i', start(0) width(1)  ///
					name(`var'`i', replace) ///
					title("IHS-Tranformed `var': K = `power'")
					}					
				}
	gr combine `var'1 `var'2 `var'3 `var'4 `var'5, row(2)
	gr export "${master_figures}/scale_`var'.png", replace
				}
	else {
		local powers "1 10^1 10^2 10^3"
		forvalues i = 1(1)4 {
			gettoken power powers : powers
			histogram ihs_`var'_k`i', start(0) width(1)  ///
				name(`var'`i', replace) ///
				title("IHS-Tranformed `var': K = `power'")
				}
	gr combine `var'1 `var'2 `var'3 `var'4, row(2)
	gr export "${master_figures}/scale_`var'.png", replace
	}
}
*/		
		* generate Y0 + missing baseline to be able to run final regression
			* at midline use only for mht
foreach var of local ys {
			* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]					// filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)								// create variable = bl value for all three surveyrounds by id
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first														// clean up
	lab var `var'_y0 "Y0 `var'"
	
		* generate missing baseline dummy
	gen miss_bl_`var' = 0 if surveyround == 1											// gen dummy for baseline
	replace miss_bl_`var' = 1 if surveyround == 1 & inlist(`var',., -777, -888, -999)	// replace dummy 1 if variable missing at bl
	egen missing_bl_`var' = min(miss_bl_`var'), by(id_plateforme)									// expand dummy to ml, el
	lab var missing_bl_`var' "YO missing, `var'"
	drop miss_bl_`var'
}

		* run final regression & collect r-square in Excel file
				* create excel document
putexcel set "${master_figures}/scale_k.xlsx", replace

				* define table title
putexcel A1 = "Selection of optimal K", bold border(bottom) left
	
				* create top border for variable names
putexcel A2:H2 = "", border(top)
	
				* define column headings
putexcel A2 = "", border(bottom) hcenter
putexcel B2 = "Employees", border(bottom) hcenter
putexcel C2 = "Female employees", border(bottom) hcenter
putexcel D2 = "Young employees", border(bottom) hcenter
putexcel E2 = "Domestic sales", border(bottom) hcenter
putexcel F2 = "Export sales", border(bottom) hcenter
putexcel G2 = "Total sales", border(bottom) hcenter
putexcel H2 = "Profit", border(bottom) hcenter
putexcel I2 = "Export invt.", border(bottom) hcenter
putexcel J2 = "Total sales 2023", border(bottom) hcenter
*putexcel K2 = "Total sales 2024", border(bottom) hcenter
putexcel K2 = "Export 2023", border(bottom) hcenter
*putexcel M2 = "Export 2024", border(bottom) hcenter
putexcel L2 = "Profit 2023", border(bottom) hcenter
*putexcel O2 = "Profit 2024", border(bottom) hcenter
putexcel M2 = "Costs 2023", border(bottom) hcenter
*putexcel Q2 = "Costs 2024", border(bottom) hcenter
	
				* define rows
putexcel A3 = "k = 1", border(bottom) hcenter
putexcel A4 = "k = 10^2", border(bottom) hcenter
putexcel A5 = "k = 10^3", border(bottom) hcenter
putexcel A6 = "k = 10^4", border(bottom) hcenter
putexcel A7 = "k = 10^5", border(bottom) hcenter
putexcel A7 = "k = 10^6", border(bottom) hcenter

				* run the main specification regression looping over all values of k
xtset id_plateforme surveyround, delta(1)
local columns "B C D"
foreach var of varlist employes_w99 car_empl1_w99 car_empl2_w99 {
	local row = 3
	gettoken column columns : columns
	forvalues i = 1(1)4 {
		reg ihs_`var'_k`i' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
		local r2 = e(r2)
		putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
			local row = `row' + 1
	}
}

local columns "E F G H I"
foreach var of varlist ca_w99 ca_exp_w99 profit_w99 exp_inv_w99 sales_w99 {
	local row = 3
	gettoken column columns : columns
	forvalues i = 1(1)5 {
			reg ihs_`var'_k`i' i.treatment l.`var' i.missing_bl_`var' i.strata_final, cluster(id_plateforme)
			local r2 = e(r2)
			putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
			local row = `row' + 1
	}
}

*ca_2024_w99 profit_2024_w99 costs_2024_w99 ca_exp_2024_w99
*endline K^
local columns "J K L M"
foreach var of varlist ca_w99 ca_exp_w99  profit_w99  costs_w99  {
	local row = 3
	gettoken column columns : columns
	forvalues i = 1(1)5 {
			reg ihs_`var'_k`i' i.treatment l.`var' i.missing_bl_`var' i.strata_final if surveyround == 3, cluster(id_plateforme)
			local r2 = e(r2)
			putexcel `column'`row' = `r2', hcenter nformat(0.000)  // `++row'
			local row = `row' + 1
	}
}


		* drop all the created variables
drop missing_bl_* // *_k?
drop *_y0

		* label optimal k variables & k = 1 for consistency checks
lab var ihs_exp_inv_w99_k1 "Export investment"
lab var ihs_exp_inv_w99_k4 "Export investment"
lab var ihs_ca_exp_w99_k1 "Export sales"
lab var ihs_ca_exp_w99_k4 "Export sales"
lab var ihs_sales_w99_k1  "Total sales"
lab var ihs_sales_w99_k4  "Total sales" 
lab var ihs_ca_w99_k1 "Domestic sales" 
lab var ihs_ca_w99_k4 "Domestic sales" 
lab var ihs_profit_w99_k1 "Profit" 
lab var ihs_profit_w99_k2 "Profit"
lab var ihs_profit_w99_k3 "Profit" 
lab var ihs_profit_w99_k4 "Profit"
lab var profit_pct "Profit"
lab var ihs_employes_w99_k1 "Employees"
lab var car_empl1_w99_k1 "Female employees"
lab var car_empl2_w99_k1 "Young employees"
lab var ihs_employes_w99_k3 "Employees" 
lab var car_empl1_w99_k3 "Female employees"

}

***********************************************************************
* 	PART 13: (endline) generate YO + missing baseline dummies	
***********************************************************************

*rename long var
rename clients_ssa_commandes_w99 orderssa_w99

rename ihs_localsales2024_w99_k5 ihs_ls2024_w99_k5
rename ihs_localsales_w99_k5 ihs_ls_w99_k5
rename ihs_ca_exp_2024_w99_k5 ihs_caexp2024_w99_k5

rename ihs_profit_2024_w99_k5 ihs_profit2024_w99_k5
rename ihs_profit_2024_w99_k4 ihs_profit2024_w99_k4
rename ihs_profit_2024_w99_k3 ihs_profit2024_w99_k3
rename ihs_profit_2024_w99_k2 ihs_profit2024_w99_k2
rename ihs_profit_2024_w99_k1 ihs_profit2024_w99_k1


rename ihs_ca_exp_2024_w99_k1 ihs_caexp2024_w99_k1
rename ihs_ca_exp_2024_w99_k2 ihs_caexp2024_w99_k2
rename ihs_ca_exp_2024_w99_k3 ihs_caexp2024_w99_k3
rename ihs_ca_exp_2024_w99_k4 ihs_caexp2024_w99_k4

{
	* results for optimal k
		* k = 10^3 --> employees, female employees, young employees
		* k = 10^4 --> domestic sales, export sales, total sales, exp_inv
	* collect all ys in string
local network "network net_size net_size_w99 net_nb_qualite net_coop_pos net_coop_neg net_nb_f_w99 net_nb_m_w99 net_nb_fam net_nb_dehors famille2 net_association net_size3 net_size3_m net_gender3 net_gender3_giz netcoop1 netcoop2 netcoop3 netcoop4 netcoop5 netcoop6 netcoop7 netcoop8 netcoop9 netcoop10 net_association_w99 net_size3_w99 net_size3_m_w99 net_gender3_w99 net_size4_w99 net_size4_m_w99 net_gender4_w99 net_gender3_giz_w99"
local empowerment "genderi female_efficacy female_loc listexp car_efi_fin1 car_efi_man car_efi_motiv car_loc_env car_loc_exp car_loc_soin"
local mp "mpi man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_source_cons man_source_pdg man_source_fam man_source_even man_source_autres"
local innovation "ipi innovated innovations inno_produit inno_process inno_lieu inno_commerce inno_improve inno_new inno_both inno_none inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres inno_mot_cons inno_mot_cont inno_mot_eve inno_mot_client inno_mot_dummyother"
local export_readiness "eri eri_ssa exp_invested ihs_exp_inv_w99_k1 ihs_exp_inv_w99_k4 exported ca_exp exprep_couts ssa_action1 ssa_action2 ssa_action3 ssa_action4 epp exp_pra_rexp exp_pra_foire exp_pra_sci exprep_norme exp_pra_vent expp_cost expp_ben export_1 export_2 export_3 marginal_exp_2023 marginal_exp_2024 export_41 export_42 export_43 export_44 export_45" // add at endline: ihs_exp_pays_w99_k1
local business_performance "bpi bpi_2024 ihs_sales_w99_k1 ihs_sales_w99_k4 ihs_ca_w99_k1 ihs_ca_w99_k4 profit_pos profit_pct ihs_employes_w99_k1 car_empl1_w99_k1 car_empl2_w99_k1 ihs_employes_w99_k3 car_empl1_w99_k3 car_empl2_w99_k3 ihs_costs_w99_k4 marki ihs_costs_w99_k1 ihs_sales_w99_k2 ihs_sales_w99_k3 ihs_sales_w99_k5 ca_w99 profit_w99 clients_w99 clients_ssa_w99 orderssa_w99 exp_pays_w99 localsales_w99 localsales2024_w99 ca_2024_w99 ca_exp_w99 ca_exp_2024_w99 costs_w99 costs_2024_w99 profit_2024_w99 employes_w99 car_empl1_w99 car_empl2_w99 ihs_ca_w99_k5 ihs_ca_2024_w99_k5 ihs_ls_w99_k5 ihs_ls2024_w99_k5 ihs_ca_exp_w99_k5 ihs_caexp2024_w99_k5 ihs_costs_w99_k5 ihs_costs_2024_w99_k5 ihs_profit_w99_k5 ihs_profit2024_w99_k5 ihs_caexp2024_w99_k1 ihs_ca_exp_w99_k1 ihs_caexp2024_w99_k2 ihs_ca_exp_w99_k2 ihs_caexp2024_w99_k3 ihs_ca_exp_w99_k3 ihs_caexp2024_w99_k4 ihs_ca_exp_w99_k4 ihs_profit2024_w99_k1 ihs_profit_w99_k1 ihs_profit2024_w99_k2 ihs_profit_w99_k2 ihs_profit2024_w99_k3 ihs_profit_w99_k3 ihs_profit2024_w99_k4 ihs_profit_w99_k4 profit_2023_category profit_2024_category"
local ys `network' `empowerment' `mp' `innovation' `export_readiness' `business_performance'

	* gen dummy + replace missings with zero at bl
foreach var of local ys {
	gen missing_bl_`var' = (`var' == . & surveyround == 1) 
	replace `var' = 0 if `var' == . & surveyround == 1
}

	* generate Y0 --> baseline value for ancova & mht
foreach var of local ys {
		* generate YO
	bys id_plateforme (surveyround): gen `var'_first = `var'[_n == 1]					// filter out baseline value
	egen `var'_y0 = min(`var'_first), by(id_plateforme)								// create variable = bl value for all three surveyrounds by id
	replace `var'_y0 = 0 if inlist(`var'_y0, ., -777, -888, -999)		// replace this variable = zero if missing
	drop `var'_first														// clean up
	lab var `var'_y0 "Y0 `var'"
	}

}


***********************************************************************
* 	PART 14: Tunis dummy	
***********************************************************************
gen tunis = (gouvernorat == 10 | gouvernorat == 20 | gouvernorat == 11) // Tunis
gen city = (gouvernorat == 10 | gouvernorat == 20 | gouvernorat == 11 | gouvernorat == 30 | gouvernorat == 40) // Tunis, Sfax, Sousse
lab var tunis "HQ in Tunis"
lab var city "HQ in Tunis, Sousse, Sfax"

***********************************************************************
* 	PART 15: Entreprise Size
***********************************************************************
* Generate entrep_size variable and label it
gen entrep_size = .
lab var entrep_size "1- small, 2- large"

* Replace entrep_size values based on conditions
replace entrep_size = 1 if employes <= 5
replace entrep_size = 2 if employes > 5
replace entrep_size = . if employes ==.

label define entrep_size_label 1 "Small" 2 "Large"
label values entrep_size entrep_size_label

* Generate entrep_size variable and label it
gen entrep_size2 = .
lab var entrep_size2 "1- small, 2- large"

* Replace entrep_size values based on conditions
replace entrep_size2 = 1 if employes <= 10
replace entrep_size2 = 2 if employes > 10
replace entrep_size2 = . if employes ==.

label define entrep_size_label2 1 "Small" 2 "Large"
label values entrep_size2 entrep_size_label2
***********************************************************************
* 	PART 16: Digital consortia dummy	
***********************************************************************
gen cons_dig = (pole == 4)

***********************************************************************
* 	PART 17: peer effects: baseline peer quality	
***********************************************************************	
	* loop over all peer quality baseline characteristics
local labels `" "management practices" "entrepreneurial confidence" "export performance" "business size" "profit" "'
local peer_vars "mpmarki genderi epp profit"
foreach var of local peer_vars {
	* get labels for new variables
	gettoken label labels : labels
	
			* generate rank for top3 within each consortium
				* top1: among all firms being offered treatment (for take-up prediction)
		gsort pole treatment surveyround -`var'
		by pole treatment surveyround: gen rank1_`var' = _n
		egen peer_top1_`var' = mean(`var') if rank1_`var' < 4 & treatment == 1 & surveyround == 1, by(pole)
		egen temp_peer_top1_`var' = min(peer_top1_`var') if treatment == 1, by(pole)
		drop peer_top1_`var'
		rename temp_peer_top1_`var' peer_top1_`var'

				* top2: among all treated firms (for peer effect estimation)
		gsort pole take_up surveyround -`var'
		by pole take_up surveyround: gen rank2_`var' = _n
		egen peer_top2_`var' = mean(`var') if rank2_`var' < 4 & take_up == 1 & surveyround == 1, by(pole)
		egen temp_peer_top2_`var' = min(peer_top2_`var') if take_up == 1, by(pole)
		drop peer_top2_`var'
		rename temp_peer_top2_`var' peer_top2_`var'

		lab var peer_top1_`var' "Top-3 peer average bl `label'"
		lab var peer_top2_`var' "Top-3 peer average bl `label'"

			* generate 
		gen peer_avg1_`var' = .
		gen peer_avg2_`var' = .	
		lab var peer_avg1_`var' "Peer average bl `label'"
		lab var peer_avg2_`var' "Peer average bl `label'"
			* loop over each observation
		gsort -treatment surveyround id_plateforme
		forvalues i = 1(1)87 {
			sum pole in `i' 			// get consortium of the observation
			local pole = r(mean)
				* average for all invited to treatment (for take-up predictions), but i
			sum `var' if `i' != _n & pole == `pole' & surveyround == 1 & treatment == 1
			replace peer_avg1_`var' = r(mean) in `i'	 
				* average for all that took-up treatment (for peer-effect estimation), but i
			sum `var' if `i' != _n & pole == `pole' & surveyround == 1 & take_up == 1
			replace peer_avg2_`var' = r(mean) in `i'
	}
			replace peer_avg2_`var' = . if take_up == 0


}

	* revisit the result
sort treatment pole surveyround
*br id_plateforme treatment take_up pole surveyround peer_*
sort treatment surveyround id_plateforme, stable

	* extend to panel, gen distance
local peer_vars "mpmarki genderi epp profit"
local labels `" "management practices" "entrepreneurial confidence" "export performance" "business size" "profit" "'
foreach var of local peer_vars {
	* get the labels
	gettoken label labels : labels
	forvalues i = 1(1)2 {
	* extend to panel
	bysort id_plateforme (surveyround treatment): replace peer_avg`i'_`var' = peer_avg`i'_`var'[_n-1] if treatment == 1 & peer_avg`i'_`var' == .
		* gen distance
	gen peer_d_avg`i'_`var' = peer_avg`i'_`var' - `var'
	gen peer_d_top`i'_`var' = peer_top`i'_`var' - `var'
	lab var peer_d_avg`i'_`var' "distance to peer average `label'"
	lab var peer_d_top`i'_`var' "distance to top-3 average `label'"
	}
}


	* generate survey-to-survey growth rates
local y_vars "genderi mpi ihs_profit_w99_k1"
foreach var of local y_vars {
		bys id_plateforme: g `var'_abs_growth = D.`var' if `var' != -999 | `var' != -888
			bys id_plateforme: replace `var'_abs_growth = . if `var' == -999 | `var' == -888
}
*bys id_plateforme: g `var'_rel_growth = D.`var'/L.`var'
*bys id_plateforme: replace `var'_rel_growth = . if `var' == -999 | `var' == -888

***********************************************************************
* 	PART final save:    save as final consortium_database
***********************************************************************
save "${master_final}/consortium_final", replace

/*
* export lists for GIZ
preserve 
keep if surveyround == 1
keep id_plateforme year_created pole subsector_corrige produit?
merge 1:1 id_plateforme using "${master_final}/consortium_pii_final"
export excel id_plateforme treatment nom_rep position_rep tel_pdg email_pdg year_created pole subsector_corrige produit? using "${master_final}/eya_list.xlsx", firstrow(var) replace
restore
*/
