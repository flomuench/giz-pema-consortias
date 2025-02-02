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
* 	PART 3:  Automatic corrections
***********************************************************************
*2.1 Remove commas, dots, dt and dinar Turn zero, zéro into 0 for all numeric vars


	* amouri frogot to mention that 999 needs to have a - before in case of don't know
local 999vars ca ca_2024 profit profit_2024 ca_exp ca_exp_2024 
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

***********************************************************************
* 	PART 4:  Transform categorical variables into continuous variables
***********************************************************************
{
*ca_intervalles
replace ca = 5000 if comp_ca2023_intervalles == 8
replace ca = 25000 if comp_ca2023_intervalles == 7
replace ca = 100000 if comp_ca2023_intervalles == 6
replace ca = 225000 if comp_ca2023_intervalles == 5
replace ca = 400000 if comp_ca2023_intervalles == 4
replace ca = 600000 if comp_ca2023_intervalles == 3
replace ca = 850000 if comp_ca2023_intervalles == 2
replace ca = 1000000 if comp_ca2023_intervalles == 1

*comp_ca2024_intervalles
replace ca_2024 = 5000 if comp_ca2024_intervalles == 8
replace ca_2024 = 25000 if comp_ca2024_intervalles == 7
replace ca_2024 = 100000 if comp_ca2024_intervalles == 6
replace ca_2024 = 225000 if comp_ca2024_intervalles == 5
replace ca_2024 = 400000 if comp_ca2024_intervalles == 4
replace ca_2024 = 600000 if comp_ca2024_intervalles == 3
replace ca_2024 = 850000 if comp_ca2024_intervalles == 2
replace ca_2024 = 1000000 if comp_ca2024_intervalles == 1

*profit_intervalles
replace profit = 5000 if profit_2023_category_perte == 8
replace profit = 25000 if profit_2023_category_perte == 7
replace profit = 100000 if profit_2023_category_perte == 6
replace profit = 225000 if profit_2023_category_perte == 5
replace profit = 400000 if profit_2023_category_perte == 4
replace profit = 600000 if profit_2023_category_perte == 3
replace profit = 850000 if profit_2023_category_perte == 2
replace profit = 1000000 if profit_2023_category_perte == 1

replace profit = 5000 if profit_2023_category_gain == 8
replace profit = 25000 if profit_2023_category_gain == 7
replace profit = 100000 if profit_2023_category_gain == 6
replace profit = 225000 if profit_2023_category_gain == 5
replace profit = 400000 if profit_2023_category_gain == 4
replace profit = 600000 if profit_2023_category_gain == 3
replace profit = 850000 if profit_2023_category_gain == 2
replace profit = 1000000 if profit_2023_category_gain == 1

*profit_2024_intervalles
replace profit_2024 = 5000 if profit_2024_category_perte == 8
replace profit_2024 = 25000 if profit_2024_category_perte == 7
replace profit_2024 = 100000 if profit_2024_category_perte == 6
replace profit_2024 = 225000 if profit_2024_category_perte == 5
replace profit_2024 = 400000 if profit_2024_category_perte == 4
replace profit_2024 = 600000 if profit_2024_category_perte == 3
replace profit_2024 = 850000 if profit_2024_category_perte == 2
replace profit_2024 = 1000000 if profit_2024_category_perte == 1

replace profit_2024 = 5000 if profit_2024_category_gain == 8
replace profit_2024 = 25000 if profit_2024_category_gain == 7
replace profit_2024 = 100000 if profit_2024_category_gain == 6
replace profit_2024 = 225000 if profit_2024_category_gain == 5
replace profit_2024 = 400000 if profit_2024_category_gain == 4
replace profit_2024 = 600000 if profit_2024_category_gain == 3
replace profit_2024 = 850000 if profit_2024_category_gain == 2
replace profit_2024 = 1000000 if profit_2024_category_gain == 1

replace profit=profit*(-1) if profit_2023_category==0

replace profit_2024=profit_2024*(-1) if profit_2024_category==0
}

***********************************************************************
* Correct management practices
***********************************************************************
{
replace man_fin_per_ind = 1 if id_plateforme == 984
replace man_fin_per_pro = 1 if id_plateforme == 984
replace man_fin_per_qua = 1 if id_plateforme == 984
replace man_fin_per_sto = 1 if id_plateforme == 984
replace man_fin_per_emp = 1 if id_plateforme == 984
replace man_fin_per_liv = 1 if id_plateforme == 984

replace man_fin_per = 0.25 if id_plateforme == 984

replace man_fin_per_ind = 1 if id_plateforme == 1000
replace man_fin_per_pro = 1 if id_plateforme == 1000
replace man_fin_per_qua = 1 if id_plateforme == 1000
replace man_fin_per_sto = 0 if id_plateforme == 1000
replace man_fin_per_emp = 1 if id_plateforme == 1000
replace man_fin_per_liv = 1 if id_plateforme == 1000

replace man_fin_per = 0.5 if id_plateforme == 1000

replace man_fin_per_liv = 0 if id_plateforme == 1059

replace man_fin_per_ind = 1 if id_plateforme == 1126
replace man_fin_per_pro = 1 if id_plateforme == 1126
replace man_fin_per_qua = 1 if id_plateforme == 1126
replace man_fin_per_sto = 1 if id_plateforme == 1126
replace man_fin_per_emp = 1 if id_plateforme == 1126
replace man_fin_per_liv = 1 if id_plateforme == 1126
replace man_fin_per = 0.5 if id_plateforme == 1126


replace man_sources_other ="Apprentissage de nouvelles strategies grace à sa participation à deux sturctures d'accompagnement des entreprises qui sont: impact partner et afkar" if id_plateforme == 996

replace man_sources_other = "Apprentissage de nouvelles strategies grace au formation de la GIZ" if id_plateforme == 1068

replace man_sources_other = "Apprentissage de nouvelles strategies de marketing et management grace à une agence de communication et sa participation à un programme Dream of Use" if id_plateforme == 1151

replace man_sources_other = "Apprentissage de nouvelles strategie grace à la recherche: article de marketing et management" if id_plateforme == 1176
}

******************************************************************************
* Correct products
*****************************************************************************
replace products_other ="vetement traditionnel: houli et hayek" if id_plateforme ==1197 
replace products_other = " frange parfumée" if id_plateforme ==1234


***********************************************************************
* Correct product innovation 
***********************************************************************
{
replace inno_mot_other = "Diversification des fournisseurs et marketing à travers les clients" if id_plateforme ==986
replace inno_mot_other = "Exportation du services, introduction de nouvelles formations dans leur services" if id_plateforme ==988
replace inno_exampl_produit2 = "Introduction d'un nouveau service d'accompagnement pour les entreprises: la comptabilité carbonne pour déterminer l'impact environnemental d'une entreprise et le rapport extra financier annuel qui contient les actions ,démarches et les profits" if id_plateforme ==999
replace inno_exampl_produit1 = "Packaging: changement du logo et charte graphique" if id_plateforme ==1010
replace inno_exampl_produit2 = "Introduction d'un nouveau service: cours dédié aux professionnels(pas que les eleves,etudiants)" if id_plateforme ==1019
replace inno_exampl_produit1 = "Vulgarisation scientifique" if id_plateforme == 1035 
replace inno_exampl_produit1 ="Penetration au marché du B2C, avant elle travaille seulement sur le B2B"  if id_plateforme ==1043
replace inno_exampl_produit1 = "Innovation technique dans l'outil de creation de contenues" if id_plateforme ==1046 
replace inno_exampl_produit2 = " Service sur mesure selon la demande et besoin des clients" if id_plateforme ==1046
replace inno_exampl_produit1 = "Changement de l'entreprise avec laquelle elle travaille" if id_plateforme ==1049
replace inno_mot_other ="Introduire des nouvelles formes des produits sur la plateforme selon les besoins des clients" if id_plateforme ==1065 
replace inno_mot_other ="l'environement du travail et des concurents" if id_plateforme ==1081
replace inno_proc_other = "amelioration des competences des employés, nouveau recrutement et audit RH" if id_plateforme ==1087 
replace inno_exampl_produit1 = "Amélioration au niveau des modes de paiement grâce à des formations de la GIZ avec des experts à l'échelle internationale" if id_plateforme ==1118 
replace inno_exampl_produit1 = "lancement d'un site web de l'entreprise" if id_plateforme ==1118
replace inno_proc_other =" amelioration des techniques de communication avec les clients" if id_plateforme ==1118 
replace inno_mot_other = "" if id_plateforme ==1125
replace inno_exampl_produit1= "produits personnalisable selon les besoin des clients" if id_plateforme==1128 
replace inno_exampl_produit2= "introduction des nouveaux produits, modification de la forme des produits" if id_plateforme ==1128 
replace inno_proc_other =" prospection à l'etranger et lancement des appels d'offres à l'etranger" if id_plateforme == 1135
replace inno_proc_other = "Ouverture sur le marché etranger grace aux strategies marketing " if id_plateforme ==1176
replace inno_exampl_produit2 ="Des nouvelles conceptions basées sur les cartes, tels que les cartes de télécommande, Ils entretiennent l'intelligence artificielle" if id_plateforme ==1176 
replace inno_exampl_produit1 = "Introduire ses services au marché africain" if id_plateforme ==1178
replace inno_mot_other ="Innovation provient des etudiants qui ont effectué un stage PFE au sein de leur entreprise: nouveau emballage et charte graphique" if id_plateforme ==1186 
replace inno_exampl_produit1 = "Diversification des produits" if id_plateforme == 1191
replace inno_exampl_produit1 = " Developpement des nouveaux produits tel que: parfum cheveux,creme hydratante spf20,spray solaire et creme cuir lait bebe" if id_plateforme==1224 
replace inno_exampl_produit1 =" Agrandissement de l'amenagement, amelioration du qualité des huiles,insertion des nouveaux produits intermediaires dans la chaine de production de certains produits" if id_plateforme ==1231 
replace inno_exampl_produit1 =  "frange des rideaux parfumées" if id_plateforme ==1234

replace inno_exampl_produit1 = "Commerce international: Vente pure" if id_plateforme == 1112
replace inno_exampl_produit2 = "Introduction d'un nouveau produit agroalimentaire de l'egypte dans sa vente pure de commerce international" if id_plateforme == 1112 
replace inno_exampl_produit2 = "Des cocottes de cuisine capables de résister à une température de 300 degrés" if id_plateforme == 1124 


replace inno_proc_other="Encourager l'egalité entre hommes et femmes en recrutant plus des femmes dans des postes avant préoccupés par des hommes" if id_plateforme == 1117

replace inno_proc_other=" Exporter et se focaliser sur le marché italien surtout le sud de l'italie" if id_plateforme == 1124

replace inno_exampl_produit1 = "Nouveaux services en relation avec le domaine du sport et animation des enfants" if id_plateforme == 1210 

replace inno_proc_other= "Nouveaux services en relation avec le domaine du sport et animation des enfants" if id_plateforme == 1210 

replace inno_exampl_produit2 = " Integration d'un nouveau systeme d'information et manuel de procedures" if id_plateforme == 1222 

replace  export_other = " Elle a commencé la prospection en cote d'ivoire mais elle a abondonné car l'export coute trop cher" if id_plateforme == 1222 

}

*************************************************************************
*Correct net service 
*************************************************************************
{
replace net_services_pratiques = 1 if id_plateforme ==999 
replace net_services_produits= 1 if id_plateforme ==999 
replace net_services_mark = 1 if id_plateforme ==999 
replace net_services_sup= 1 if id_plateforme ==999 
replace net_services_contract= 0 if id_plateforme == 999 
replace net_services_confiance = 0 if id_plateforme ==999 
replace net_services_autre = 1 if id_plateforme ==999 
replace net_services_other = "stratégies nationales des consultants" if id_plateforme ==999

replace net_services_pratiques = 1 if id_plateforme ==1005 
replace net_services_produits= 0 if id_plateforme ==1005 
replace net_services_mark = 0 if id_plateforme ==1005 
replace net_services_sup= 1 if id_plateforme ==1005 
replace net_services_contract= 0  if id_plateforme ==1005 
replace net_services_confiance = 0 if id_plateforme ==1005 
replace net_services_autre = 0 if id_plateforme ==1005 


replace net_services_pratiques = 0 if id_plateforme ==1009 
replace net_services_produits= 1 if id_plateforme ==1009 
replace net_services_mark = 0 if id_plateforme ==1009 
replace net_services_sup= 1 if id_plateforme ==1009 
replace net_services_contract= 0  if id_plateforme ==1009 
replace net_services_confiance = 1 if id_plateforme ==1009 
replace net_services_autre = 1 if id_plateforme ==1009 
replace net_services_other = "Collaboration entre les entrepreneurs"  if id_plateforme ==1009

replace net_services_pratiques = 1 if id_plateforme ==1054
replace net_services_produits= 1 if id_plateforme ==1054 
replace net_services_mark = 0 if id_plateforme ==1054 
replace net_services_sup= 1 if id_plateforme ==1054 
replace net_services_contract= 0 if id_plateforme == 1054 
replace net_services_confiance = 0 if id_plateforme ==1054 
replace net_services_autre = 1 if id_plateforme ==1054 
replace net_services_other = "Apprentissage de nouvelles techniques de production tels que des conseils pour les machines" if id_plateforme ==1054 


replace net_services_pratiques = 1 if id_plateforme ==1122 
replace net_services_produits= 1 if id_plateforme ==1122 
replace net_services_mark = 0 if id_plateforme ==1122 
replace net_services_sup= 1 if id_plateforme ==1122 
replace net_services_contract= 0  if id_plateforme ==1122 
replace net_services_confiance = 0 if id_plateforme ==1122 
replace net_services_autre = 0 if id_plateforme ==1122 


replace net_services_pratiques = 0 if id_plateforme ==1133 
replace net_services_produits= 1 if id_plateforme ==1133 
replace net_services_mark = 0 if id_plateforme ==1133 
replace net_services_sup= 1 if id_plateforme ==1133 
replace net_services_contract= 1  if id_plateforme ==1133 
replace net_services_confiance = 0 if id_plateforme ==1133 
replace net_services_autre = 0 if id_plateforme ==1133 


replace net_services_pratiques = 1 if id_plateforme == 1179 
replace net_services_produits= 1 if id_plateforme == 1179 
replace net_services_mark = 1 if id_plateforme == 1179 
replace net_services_sup= 0 if id_plateforme == 1179 
replace net_services_contract= 0  if id_plateforme == 1179 
replace net_services_confiance = 0 if id_plateforme == 1179 
replace net_services_autre = 0 if id_plateforme == 1179 

replace net_services_pratiques = 0 if id_plateforme == 1197
replace net_services_produits= 1 if id_plateforme ==1197
replace net_services_mark = 0 if id_plateforme ==1197
replace net_services_sup= 0 if id_plateforme ==1197 
replace net_services_contract= 1  if id_plateforme ==1197 
replace net_services_confiance = 1 if id_plateforme == 1197
replace net_services_autre = 0 if id_plateforme == 1197


replace net_services_pratiques = 1 if id_plateforme ==1224
replace net_services_produits= 1 if id_plateforme ==1224
replace net_services_mark = 1 if id_plateforme ==1224
replace net_services_sup= 1 if id_plateforme ==1224
replace net_services_contract= 1  if id_plateforme ==1224
replace net_services_confiance = 1 if id_plateforme ==1224
replace net_services_autre = 1 if id_plateforme ==1224
replace net_services_other = "Collaboration avec d'autres entreprises" if id_plateforme ==1224


replace net_services_pratiques = 1 if id_plateforme ==1019
replace net_services_produits= 1 if id_plateforme ==1019
replace net_services_mark = 1 if id_plateforme ==1019
replace net_services_sup= 0 if id_plateforme ==1019
replace net_services_contract= 0  if id_plateforme ==1019
replace net_services_confiance = 1 if id_plateforme ==1019
replace net_services_autre = 1 if id_plateforme ==1019
replace net_services_other = "avoir des contacts pour echanger les call for applications des fond d'investissement." if id_plateforme ==1019


replace net_services_pratiques = 0 if id_plateforme ==1043
replace net_services_produits= 1 if id_plateforme ==1043
replace net_services_mark = 1 if id_plateforme ==1043
replace net_services_sup= 1 if id_plateforme ==1043
replace net_services_contract= 1  if id_plateforme ==1043
replace net_services_confiance = 1 if id_plateforme ==1043
replace net_services_autre = 1 if id_plateforme ==1043
replace net_services_other = "Collaboration entre les entrepreneurs. Elle a donnée l'exemple de si sa machine tombe panne, elle peut utiliser celle d'un autre entrepreneur du meme secteur. " if id_plateforme ==1043

replace net_services_pratiques = 1 if id_plateforme ==1046
replace net_services_produits= 1 if id_plateforme ==1046
replace net_services_mark = 1 if id_plateforme ==1046
replace net_services_sup= 1 if id_plateforme ==1046
replace net_services_contract= 1  if id_plateforme ==1046
replace net_services_confiance = 1 if id_plateforme ==1046
replace net_services_autre = 0 if id_plateforme ==1046


replace net_services_pratiques = 0 if id_plateforme ==1087
replace net_services_produits= 1 if id_plateforme ==1087
replace net_services_mark = 1 if id_plateforme ==1087
replace net_services_sup= 1 if id_plateforme ==1087
replace net_services_contract= 0  if id_plateforme ==1087
replace net_services_confiance = 0 if id_plateforme ==1087
replace net_services_autre = 0 if id_plateforme ==1087

replace net_services_pratiques = 1 if id_plateforme ==1096
replace net_services_produits= 1 if id_plateforme ==1096
replace net_services_mark = 1 if id_plateforme ==1096
replace net_services_sup= 1 if id_plateforme ==1096
replace net_services_contract= 0  if id_plateforme ==1096
replace net_services_confiance = 1 if id_plateforme ==1096
replace net_services_autre = 0 if id_plateforme ==1096

replace net_services_pratiques = 0 if id_plateforme ==1107
replace net_services_produits= 0 if id_plateforme ==1107
replace net_services_mark = 1 if id_plateforme ==1107
replace net_services_sup= 1 if id_plateforme ==1107
replace net_services_contract= 0  if id_plateforme ==1107
replace net_services_confiance = 0 if id_plateforme ==1107
replace net_services_autre = 0 if id_plateforme ==1107

replace net_services_pratiques = 1 if id_plateforme ==1112
replace net_services_produits= 1 if id_plateforme ==1112
replace net_services_mark = 1 if id_plateforme ==1112
replace net_services_sup= 1 if id_plateforme ==1112
replace net_services_contract= 0  if id_plateforme ==1112
replace net_services_confiance = 1 if id_plateforme ==1112
replace net_services_autre = 0 if id_plateforme ==1112

replace net_services_pratiques = 1 if id_plateforme ==1117
replace net_services_produits= 0 if id_plateforme ==1117
replace net_services_mark = 1 if id_plateforme ==1117
replace net_services_sup= 1 if id_plateforme ==1117
replace net_services_contract= 1 if id_plateforme ==1117
replace net_services_confiance = 1 if id_plateforme ==1117
replace net_services_autre = 0 if id_plateforme ==1117

replace net_services_pratiques = 0 if id_plateforme ==1138
replace net_services_produits= 1 if id_plateforme ==1138
replace net_services_mark = 1 if id_plateforme ==1138
replace net_services_sup= 1 if id_plateforme ==1138
replace net_services_contract= 1  if id_plateforme ==1138
replace net_services_confiance = 1 if id_plateforme ==1138
replace net_services_autre = 1 if id_plateforme ==1138
replace net_services_other = " Partenariat avec un autre entrepreneur pour elargir le cercle de reseau professionnel" if id_plateforme ==1138

replace net_services_pratiques = 1 if id_plateforme ==1151
replace net_services_produits= 1 if id_plateforme ==1151
replace net_services_mark = 1 if id_plateforme ==1151
replace net_services_sup= 1 if id_plateforme ==1151
replace net_services_contract= 0  if id_plateforme ==1151
replace net_services_confiance = 1 if id_plateforme ==1151
replace net_services_autre = 0 if id_plateforme ==1151

replace net_services_pratiques = 0 if id_plateforme ==1191
replace net_services_produits= 1 if id_plateforme ==1191
replace net_services_mark = 1 if id_plateforme ==1191
replace net_services_sup= 1 if id_plateforme ==1191
replace net_services_contract= 1  if id_plateforme ==1191
replace net_services_confiance = 0 if id_plateforme ==1191
replace net_services_autre = 0 if id_plateforme ==1191

replace net_services_pratiques = 1 if id_plateforme ==1195
replace net_services_produits= 1 if id_plateforme ==1195
replace net_services_mark = 0 if id_plateforme ==1195
replace net_services_sup= 0 if id_plateforme ==1195
replace net_services_contract= 1 if id_plateforme ==1195
replace net_services_confiance = 1 if id_plateforme ==1195
replace net_services_autre = 0 if id_plateforme ==1195

replace net_services_pratiques = 1 if id_plateforme ==1205
replace net_services_produits= 1 if id_plateforme ==1205
replace net_services_mark = 0 if id_plateforme ==1205
replace net_services_sup= 1 if id_plateforme ==1205
replace net_services_contract= 1 if id_plateforme ==1205
replace net_services_confiance = 1 if id_plateforme ==1205
replace net_services_autre = 1 if id_plateforme ==1205
replace net_services_other = "partage de matiere premiere en cas de besoin." if id_plateforme ==1205

replace net_services_pratiques = 1 if id_plateforme ==1234
replace net_services_produits= 1 if id_plateforme ==1234
replace net_services_mark = 0 if id_plateforme ==1234
replace net_services_sup= 1 if id_plateforme ==1234
replace net_services_contract= 1 if id_plateforme ==1234
replace net_services_confiance = 1 if id_plateforme ==1234
replace net_services_autre = 1 if id_plateforme ==1234

replace net_services_pratiques = 1 if id_plateforme ==1245
replace net_services_produits= 1 if id_plateforme ==1245
replace net_services_mark = 1 if id_plateforme ==1245
replace net_services_sup= 0 if id_plateforme ==1245
replace net_services_contract= 0 if id_plateforme ==1245
replace net_services_confiance = 1 if id_plateforme ==1245
replace net_services_autre = 0 if id_plateforme ==1245

replace net_services_pratiques = 1 if id_plateforme ==1248
replace net_services_produits= 1 if id_plateforme ==1248
replace net_services_mark = 1 if id_plateforme ==1248
replace net_services_sup= 0 if id_plateforme ==1248
replace net_services_contract= 1 if id_plateforme ==1248
replace net_services_confiance = 1 if id_plateforme ==1248
replace net_services_autre = 0 if id_plateforme ==1248

replace net_services_pratiques = 1 if id_plateforme ==1234
replace net_services_produits= 1 if id_plateforme ==1234
replace net_services_mark = 0 if id_plateforme ==1234
replace net_services_sup= 1 if id_plateforme ==1205
replace net_services_contract= 1 if id_plateforme ==1234
replace net_services_confiance = 1 if id_plateforme ==1234
replace net_services_autre = 1 if id_plateforme ==1234

replace net_services_pratiques = 1 if id_plateforme ==1234
replace net_services_produits= 1 if id_plateforme ==1234
replace net_services_mark = 0 if id_plateforme ==1234
replace net_services_sup= 1 if id_plateforme ==1205
replace net_services_contract= 1 if id_plateforme ==1234
replace net_services_confiance = 1 if id_plateforme ==1234
replace net_services_autre = 1 if id_plateforme ==1234












}











*************************************************************************
* Correct net size 
*************************************************************************
{

*** Account for the filter: if net_size3 ou net_size4 = 0, replace net_gender3 & net_gender4 == 0
forvalues x = 3(1)4 {
	replace net_gender`x' = 0 if net_size`x' == 0
}

*** Company specific corrections
* id 1000
replace net_size4 = 0 if id_plateforme ==1000
replace net_gender4 = 40 if id_plateforme == 1000

* id 1036
replace net_size4 = 10 if id_plateforme ==1036
replace net_size3 = 30 if id_plateforme ==1036

replace net_gender4 = 7 if id_plateforme ==1036
replace net_gender3 = 20 if id_plateforme ==1036

* id 1108
replace net_size4 = 10 if id_plateforme ==1108
replace net_size3 = 12 if id_plateforme ==1108 

replace net_gender4 = 9 if id_plateforme ==1108
replace net_gender3 = 10 if id_plateforme ==1108

* id 1193
replace net_size3 = 15 if id_plateforme ==1193 
replace net_size4 = 10 if id_plateforme ==1193 
replace net_gender3 = 7 if  id_plateforme==1193
replace net_gender4 = 6 if id_plateforme == 1193

}



*************************************************************************
*Correct export part 
*************************************************************************
* correct other reasons for not exporting
replace export_other ="des problemes qui survient à la finalisation de l'operation de l'exportation" if id_plateforme ==1054

* make corrections based on phone calls & audio records
replace export = "3" if id_plateforme == 1153 // voir fiche de correction version finale

replace export = "3" if id_plateforme == 1157 // suite logique de ses reponses a ca_exp & ca_exp_2024

replace export = "3" if id_plateforme == 1244 // suite logique de ses reponses a ca_exp & ca_exp_2024

replace export = "3" if id_plateforme == 1245 // voir fiche de correction version 2

replace export = "3" if id_plateforme == 1005 // voir fiche de correction version 2

replace export = "1" if id_plateforme == 1059 // voir fiche de suivi


* a revoir/verifier:1157, 1231, 1244

* taking into account filter (exp = 0)
foreach var of varlist exp_pays exp_pays_ssa clients clients_ssa clients_ssa_commandes {
	replace `var' = 0 if export == "/ 3 /"
}

*************************************************************************
*Correct financial part
*************************************************************************
{
// id_plateforme 1005 / entreprise n'est plus en activité depuis aout 2022 elle revient aux production aux mai 2024 elle à une perte de 17000 dt depuis aout 2022 jusquà maintenent donc les cA totale en 2023 0 est en 2024 elle à dit que dans le mois de mai (le mois de retour en production) est de 500 dt 
 
replace ca = 0 if id_plateforme == 1005
replace ca_2024 = 500 if id_plateforme == 1005
replace profit = -5700 if id_plateforme == 1005
replace profit_2024 = -5700 if id_plateforme == 1005

// id_plateforme 1049 / manque de la partie comptabilité / 29568688"Faux Num/ J'ai appelé Madame Samia, mais le manager a répondu. Il est en colere et ne veut ni répondre ni donner le téléphone à Madame Samia
local compta_vars "ca comp_ca2023_intervalles ca_2024 comp_ca2024_intervalles ca_exp ca_exp_2024 profit profit_2024 profit_2023_category_perte profit_2023_category_gain profit_2024_category_perte profit_2024_category_gain"

foreach var of local compta_vars {
	replace `var' = 888 if id_plateforme == 1049 
}

// id_plateforme 1138 / n'a pas donnée les bénéfices en 2024 (elle n'a pas aucun aidé combients)
replace profit_2024 = 999 if id_plateforme == 1138

// id_plateforme 1150 / elle a donné benefice 3000 exactement, mais comme 3000 inferieur à 5000 donc j'ai du mettre dans l'intervalle entre 0 et 9 999. ( pas besoin de retour dans la fiche de correction ) 
replace profit_2024 = 3000 if id_plateforme == 1150

// id_plateforme 1151 /	les benefices en 2024 =0  stable elle a dit jusqua juin est neant 
replace profit_2024 = 0 if id_plateforme == 1151

*id_plateforme 1132 // Refuses to give comptability
local compta_vars "ca comp_ca2023_intervalles ca_2024 comp_ca2024_intervalles ca_exp ca_exp_2024 profit profit_2024 profit_2023_category_perte profit_2023_category_gain profit_2024_category_perte profit_2024_category_gain"

foreach var of local compta_vars {
	replace `var' = 888 if id_plateforme == 1132 
}

	*id_plateforme 1167 // Has no idea about CA 2024
replace ca_2024 = 999 if id_plateforme == 1167

	*id_plateforme 1059 //  met3ametech avec des entrepreuners donc ell ne repond pas a q17 et elle n'a pas travaille  en 2024 donc elle ne peut pas repondre aux question sur les benefices + et 2023 mesajletech ni pertes ni benefices  et aussi cest une entreprise totalement exportatrice en 2023
	
replace profit = 0 if id_plateforme == 1059
replace profit_2024 = 0 if id_plateforme == 1059

	*1083 // lentreprise  ferme depuis 2 ans donc elle na pas donne le chiffres dafffaire et le matricule fiscale
local compta_vars "ca ca_2024 ca_exp ca_exp_2024 profit profit_2024"

foreach var of local compta_vars {
	replace `var' = 0 if id_plateforme == 1083 
}

*1190 // reste partie comptabilité et matriculle fiscale elle ne connait pas 
local compta_vars "ca ca_2024 ca_exp ca_exp_2024 profit profit_2024"

foreach var of local compta_vars {
	replace `var' = 0 if id_plateforme == 1083 
}

	*
	*1122 // maandhech des employées kolhom des vendeuses wyekhdmou mi temps
replace employes = 0 if id_plateforme == 1122

	*1196 // Il n'y a aucune personne qui travaille avec elle à plein temps
replace employes = 0 if id_plateforme == 1196

replace ca = 3500000 if id_plateforme ==1027 
replace ca_2024 = 1700000 if id_plateforme ==1027 
replace profit = 30000 if id_plateforme ==1134 
replace profit_2024 = 30000 if id_plateforme ==1134 

replace ca =2500000 if id_plateforme ==1147
replace ca_2024 =2300000 if id_plateforme == 1147 

replace profit = 30000 if id_plateforme == 1167
replace profit_2024 = 25000 if id_plateforme == 1167

replace ca_2024 = 3000 if id_plateforme == 1186 
 
*replace ca_2021 = 50000 if id_plateforme == 1203 

* 1061 //  ne connait pas ca exp 2024, on reduit le nb d'employés car ils ont reduit la production. 
replace employes = 2 if id_plateforme == 1061
replace ca_exp_2024 = 0 if id_plateforme ==1061

replace net_association = 1 if id_plateforme == 1088 

replace ca = 5000 if id_plateforme == 1102 
replace profit = 2000 if id_plateforme == 1102
replace ca_exp_2024 = 0 if id_plateforme ==1102

replace employes = 2 if id_plateforme == 1186 
replace ca_2024 = 3000 if id_plateforme == 1186
replace profit_2024 = 0 if id_plateforme == 1186
replace ca = 6000 if id_plateforme == 1186
replace profit = 0 if id_plateforme == 1186

replace ca_2024 = 8000 if id_plateforme == 1230
replace ca_exp = 0 if id_plateforme ==1153

replace ca_exp = 0 if id_plateforme == 1132 // repondu export_1 == 0
replace ca_exp = . if id_plateforme == 1049
replace ca_exp_2024 = 0 if id_plateforme == 1132 // repondu export_1 == 0
replace ca_exp_2024 = . if id_plateforme == 1049



* 1193 //  faillitte 

replace ca = 0 if id_plateforme == 1193  




*Entreprise ne veut pas donner CA
replace ca =. if id_plateforme == 1015
replace ca_exp =. if id_plateforme == 1015
replace ca_2024 =. if id_plateforme == 1015
replace ca_exp_2024 =. if id_plateforme == 1015
replace profit = . if id_plateforme==1015
replace profit_2024 = . if id_plateforme==1015
replace profit_2023_category_perte=. if id_plateforme==1015
replace profit_2023_category_perte=. if id_plateforme==1015
replace comp_ca2024_intervalles = . if id_plateforme==1015
replace comp_ca2023_intervalles = . if id_plateforme==1015


replace ca =. if id_plateforme == 1031
replace ca_exp =. if id_plateforme == 1031
replace ca_2024 =. if id_plateforme == 1031
replace ca_exp_2024 =. if id_plateforme == 1031
replace profit = . if id_plateforme==1031
replace profit_2024 = . if id_plateforme==1031
replace profit_2023_category_perte=. if id_plateforme==1031
replace profit_2023_category_perte=. if id_plateforme==1031
replace comp_ca2024_intervalles = . if id_plateforme==1031
replace comp_ca2023_intervalles = . if id_plateforme==1031

replace ca = 25000 if id_plateforme ==1140 
replace ca_2024 = 25000 if id_plateforme ==1140 
replace ca_exp_2024 =. if id_plateforme == 1140
replace ca_exp =. if id_plateforme == 1140 







}

*Correcting sources of management
{
gen man_source_formation = 0 if man_source_cons != .
replace man_source_formation = 1 if man_sources_other =="participation a des formations"
replace man_source_formation = 1 if man_sources_other =="a travers les formation"
replace man_source_formation = 1 if man_sources_other =="des formation des recherches"
replace man_source_formation = 1 if man_sources_other =="suite a la participation a des formation"
replace man_source_formation = 1 if man_sources_other =="mes études, les formations en leadership, intelligence émotionnel et management, des recherches"
replace man_source_formation = 1 if man_sources_other =="khdmet maa entreprises f holanda sur terrain+les formations en ligne/présentiel ++++++++++++++++"
replace man_source_formation = 1 if man_sources_other =="men des formations en ligne et présentiel et des programmes , des experiences taalamthom ++++++++++++++++++++++++++++"
replace man_source_formation = 1 if man_sources_other =="les formations en ligne / les missions b2b +++++++++++++++++++++++++++++++++"
replace man_source_formation = 1 if man_sources_other =="aamlet des formations de technologie des formations d'information ll équipe technique /des formations de marketing fl digital fl finance fl comptabilité"
replace man_source_formation = 1 if man_sources_other =="dawarat takwineya taalem les créations de l'entreprise / les programmes giz ++++++++++++++++++++++++++++++++++"
replace man_source_formation = 1 if man_sources_other =="Apprentissage de nouvelles strategies grace au formation de la GIZ"
replace man_source_formation = 1 if man_sources_other =="des formation cherket fehom"
replace man_source_formation = 1 if man_sources_other =="formatiions de giz w l'expérience"
replace man_source_formation = 1 if man_sources_other =="internet et par une formation entreprenariat et mangement agricole"
replace man_source_formation = 1 if man_sources_other =="des formation et des livres et de articles"
replace man_source_formation = 1 if man_sources_other =="formations de giz ++++++++++++++++++++++++++++++++++++"
replace man_source_formation = 1 if man_sources_other =="les formations"
replace man_source_formation = 1 if man_sources_other =="accompagnement , giz"
replace man_source_formation = 1 if man_sources_other =="le bureau de formations pic /les formation a utica"
replace man_source_formation = 1 if man_sources_other =="formation giz ,formations individuelles"
replace man_source_formation = 1 if man_sources_other =="les formations de giz"
replace man_source_formation = 1 if man_sources_other =="formation de giz"
replace man_source_formation = 1 if man_sources_other =="des formations+++"
replace man_source_formation = 1 if man_sources_other =="mel programmes tv / les formations présentiel / mel les publicités"
replace man_source_formation = 1 if man_sources_other =="formations , programme d'accompagnement"
replace man_source_formation = 1 if man_sources_other =="les formations en ligne avec giz ."
replace man_source_formation = 1 if man_sources_other =="elle meme fait la recherche sur internet et les formations en ligne +++++++++++++++++++++"
replace man_source_formation = 1 if man_sources_other =="les formations et les commandes ++++++++++++++++++++++++++++++++++++++++++++++"
replace man_source_formation = 1 if id_plateforme== 1038

replace man_source_even = 1 if id_plateforme== 1151
replace man_source_even = 1 if id_plateforme== 1247
replace man_source_even = 1 if man_sources_other =="giz et l'expérience personnel et les sociétés"


replace man_source_pdg = 1 if man_sources_other =="khdmet maa entreprises f holanda sur terrain+les formations en ligne/présentiel ++++++++++++++++"
replace man_source_pdg = 1 if id_plateforme== 1030
replace man_source_pdg = 1 if id_plateforme== 1035
replace man_source_pdg = 1 if man_sources_other =="giz et l'expérience personnel et les sociétés"
replace man_source_pdg = 1 if man_sources_other =="chambres national des femmes chefs d'entreprise"



replace man_source_cons = 1 if man_sources_other =="Apprentissage de nouvelles strategies grace à sa participation à deux sturctures d'accompagnement des entreprises qui sont: impact partner et afkar"
replace man_source_cons = 1 if id_plateforme== 1038
replace man_source_cons = 1 if man_sources_other =="accompagnement , giz"
replace man_source_cons = 1 if id_plateforme== 1151
replace man_source_cons = 1 if id_plateforme== 1215


}

*************************************************************************
* Correct Int_other & refus
************************************************************************
{

replace int_other = "Bonne idée mais probleme du temps" if int_other =="mochkolt ouaket 3ejebetha lfekra ama malkatech ouaket"
replace int_other = "J'ai rien trouvé d'important" if int_other =="Pas important"
replace int_other = "les procédures très compliquée mais elle veut revenir maintenant" if int_other =="les procédures très compliquée o theb tarjaa lel consortium"

}

***********************************************************************
* 	PART 5:  Convert data types to the appropriate format
***********************************************************************

***********************************************************************
* 	PART 6:  autres / miscellaneous adjustments
***********************************************************************
	* correct wrongly coded values for man_hr_obj

***********************************************************************
* 	PART 7: Translate the different opend ended questions in french 
***********************************************************************
{
	*products_other
replace products_other= "c'est une gammes contenant 4 produits: mixoil plusplus (poudre/liquide) /mixoil simple / mixoil liquide et poudre" if products_other =="c une gamme feha 4 produits : mixoil plusplus (poudre/liquide) /mixoil simple / mixoil liquide et poudre"
replace products_other= "huille de pépin de figues de barbarie" if products_other =="huille de pépin fils de barbarine"
replace products_other= "des miroirs fait avec du bois de palmier" if products_other =="les merroires . avec les bois de palmier"
replace products_other= "les conceptions graphiques" if products_other =="les conseptiens grafiques"
replace products_other= "les herbes aromatiques séchées (romarin, armoise, géranium)" if id_plateforme==1133
replace products_other= "maquillage: les crayons, les pinceaux, palette contouring" if products_other =="les creants / les panseaus/palette contouring"
replace products_other= "services ( consulting/ project management )" if products_other =="services ( consulting/ project management ) ++++++++++++++++++++++++++++++++"
replace products_other= "mélasse" if products_other =="milllasse"
*replace products_other= "mélasse" if products_other =="حولي و حايك" TBC id:1197
*replace products_other= "mélasse" if products_other =="la franche" TBC id:1234
replace products_other= "ERP odoo" if products_other =="le rp odoo" /*logiciel de comptabilité*/
replace products_other= "bouteille d'huile d'olive" if products_other =="bouiteille de huile de lolive"
replace products_other= "harissa et des épices" if products_other =="hrissaa et les épices +++++++++++++++++++++++++++++++++++"
replace products_other= "les patisseries traditionnelles" if products_other =="el halawiyet el ta9lidia"
replace products_other= "concasseur ammande et pistache" if products_other =="concaseur e mande et pistache"
replace products_other= "c'est une gamme composée de 4 produits : mixoil plusplus (poudre/liquide) /mixoil simple / mixoil liquide et poudre" if id_plateforme==1037
replace products_other= "contenus de formation digital" if id_plateforme==1046
replace products_other= "Elle a cessé la production d'insecticides depuis un an" if id_plateforme ==1035
replace products_other= "recrutement, assistance technique et  projets de développement" if id_plateforme ==1125
replace products_other= "sacs en cuire " if id_plateforme ==1126
replace products_other= "gel anti douleur,serum des cheuveux, mousse netoyant" if id_plateforme ==1182

}



{
*inno_exampl_produit1
replace inno_exampl_produit1 = "on fait des déplacements aux différentes régions et on fait des formations dans leurs locals" if inno_exampl_produit1 == "yamlou deplacement lel jihet o yamloulhom des formation lapart f locale mte3hom o ykadmou des servies o amlou amenagement *****************"
replace inno_exampl_produit1 = "la création et la diminution de prix , améloration de qualité du tissu: il travaille l'haut gamme mais aussi, maintenant, la gamme moyenne" if inno_exampl_produit1 == "la création et la diminution de prix , améloration de qualité tissue kenou yekhdmou ken haut gamme oualeou yekhdmou hata l moyen gamme"
replace inno_exampl_produit1 = "améliorations du chiffre d'affaire" if inno_exampl_produit1 == "améliorations de chiffre d'affaire **************************" /*TBC*/
replace inno_exampl_produit1 = "b2b, pause cafe ,evenement, site web , logiciel erp" if inno_exampl_produit1 == "b2b, pause cafe ,evenement, site web , logiciel erp +++++++++++++++++++++++++++++++++++++++++++" 
replace inno_exampl_produit1 = "gamme de maquillage , améliorations dans le laboratoire" if inno_exampl_produit1 == "gamme de maquillage , améliorations fl laboratoire ++++++++++++++++++++++++++++++++++++++++++++++" 
replace inno_exampl_produit1 = "on a augmenté le nombre d'employés, on a augmenté le rendement, on a rajouté de nouveaux articles (assiettes rondes/ pizza...)" if inno_exampl_produit1 == "zedna fl nombre des employés / kabarna fl rendement / zedou des articles (assiette rond/ pizza...)" 
replace inno_exampl_produit1 = "accompagnement et vulgarisation scientifique" if inno_exampl_produit1 == "accompagnement et vulgarisation scientifique +++++++++++++++++++++++++++++++++++++++++" 
replace inno_exampl_produit1 = "on a amélioré l'emballage, les étiquettes, la qualité du produit et on a fait des coffret cadeaux double/ simple" if inno_exampl_produit1 == "hasanet l'emballage/ hasanet fl les etiquette hasanet fl qualite produit /aamalet des coffret cadeaux double/simple +++++++++++++++++++++++++" 
replace inno_exampl_produit1 = "on a rajouté des machines afin d'améliorer la capacité de production / introduire une nouvelle gamme dans secteur décoration ( céramique artistique )" if inno_exampl_produit1 == "zedet fl les machines bech thasen fl capacité de production / introduire une nouvelle gamme fl secteur décoration ( céramique artistique )" 
replace inno_exampl_produit1 = "diversité des produits , je cible le consommateur, diversification des services" if inno_exampl_produit1 == "diversité des produits , je cible le consommateur, diversification des services ++++++++++++++++++++++++++++++++++++++++"  /*TBC*/
replace inno_exampl_produit1 = "j'ai changé l'entreprise avec laquelle je travaille avec: c'était une entreprise américaine et maintenant c'est devenue une entreprise allemande." if inno_exampl_produit1 == "badalt l'entreprise eli ttaamel maaha meli kenet entreprise américaine walet entreprise allemande"  
replace inno_exampl_produit1 = "sacs en 5k/10k/25k" if inno_exampl_produit1 == "sacs en 5k/10k/25k ++++++++++++++++++++++++++++++++++++++++++"  
replace inno_exampl_produit1 = "nous avons augmenter le nombre de produits et nous avons change l'emballage" if inno_exampl_produit1 == "zedna fel nombre de produit w badelto fel pacakage"  /*TBC*/
replace inno_exampl_produit1 = "marketing" if inno_exampl_produit1 == "marketing **********************************************************"  /*TBC*/
replace inno_exampl_produit1 = "la qualité de l'amande: une meilleure et plus bonne qualité" if inno_exampl_produit1 == "qualité amande: qualité kbira w behia ***********************"  /*TBC*/
replace inno_exampl_produit1 = "la qualité: j'ai fait de nouveaux partenariats" if inno_exampl_produit1 == "qualité : 3malt des partenariat nouvelles ******************"  /*TBC*/
replace inno_exampl_produit1 = "on a changé le logo et l'emballage + qualité espace ecologique en bois .decoration . formation ferme pedagogique" if inno_exampl_produit1 == "badalna logo w l embalage . callité espace ecologique en bois .decoration . formation ferme pedagogique" 
replace inno_exampl_produit1 = "matériaux de construction" if inno_exampl_produit1 == "matériaux de construction ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"  
replace inno_exampl_produit1 = "changement du logo et couleur personalisé et création des parfum sur mesure" if inno_exampl_produit1 == "changement du logo w couleur personamisé et création des parfum sur mesure ++++++++++++++++++++++++++++++++++++++++++++++++"  
replace inno_exampl_produit1 = "développement du mode de paiement" if inno_exampl_produit1 == "développement en mode de paiement **************************************"  /*TBC*/
replace inno_exampl_produit1 = "taille et couleur de produit" if inno_exampl_produit1 == "taille et coulleur de produit+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
replace inno_exampl_produit1 = "création et innovation de produit .changer la formation des produit" if inno_exampl_produit1 == "création et innovation de produit .changer la formation des produit +++++++++++++++++++++++++++++++++++++++++++++++++++"  /*TBC*/
replace inno_exampl_produit1 = "" if inno_exampl_produit1 == "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"  /*TBC*/
replace inno_exampl_produit1 = "regrouper l'usine et le lieu de stockage au même endroit/on a amélioré le produit dans la quantite et des differentes qualités; des nouvelles textures et un nouveau emballage" if inno_exampl_produit1 == "regrouper el ma3mel wel stokhage fi nafes leblasav /tawartou fi produit fel quantite et des different qualite des nouvelles texture et un nouveaux emballages"  
replace inno_exampl_produit1 = "des produits bio qui sont devenus plus bio à plus de 40%" if inno_exampl_produit1 == "des produit bio oualeou akther bio 40% bio aaaaaaaaaaaaaaaaaaaaaaaaaaaaa"  
replace inno_exampl_produit1 = "d'autres produits et services digitaux" if inno_exampl_produit1 == "d'autres produits et services digital ...,............................"  /*TBC*/
replace inno_exampl_produit1 = "on rajouté une nouvelle ligne de produits énérgétiques/ packs de produits/ des formations gratuites pour les femmes" if inno_exampl_produit1 == "zedou ligne mta3 produits energetique / packh de produit /des formations gratuite pour femmes"
replace inno_exampl_produit1 = "amélioration de la qualité du produit et changement du fournisseur" if inno_exampl_produit1 == "ameloration du qualite de produit fi tabdil le fourniseur" 
replace inno_exampl_produit1 = "de nouvelles solutions digitales, on a rajouté dans la quantité et de nouveaux partenariats en Afrique" if inno_exampl_produit1 == "des nouvelles solutions digitales zedou fel quantité et de nouveaux partenariat en affrique"  /*TBC*/
replace inno_exampl_produit1 = "on a un nouvel emballage carton,certification iso o des salariésresponsable qualité manajement o 2 nouveaux ouvriers" if inno_exampl_produit1 == "3aoudou embalage jdid carton certification iso o khadem jdod responsable qualité manajement o 2 ouvrier jdod" 
replace inno_exampl_produit1 = "changement de design" if inno_exampl_produit1 == "changement de design ****************************************" 
replace inno_exampl_produit1 = "changement de l'emballage extérieur des boites, tapis berbéres" if inno_exampl_produit1 == "changement de l'emballage extérieur des boites, tapis barbére , da5elna clim et zarbia dans le même produit*" 
replace inno_exampl_produit1 = "augmentation de ca" if inno_exampl_produit1 == "augmenation de ca ********************************" /*TBC*/
replace inno_exampl_produit1 = "on a amélioré l'emballage, je vois ce que les consommateurs veulent et j'améliore le produit et j'ai fait une diversification des articles (des choses qui sortent de l'ordinaire)" if inno_exampl_produit1 == "hasnet fl emballage/ je vois ce que les consommateurs veulent w thasen fl produit/ w aamlt diversification fl les articles ( hajet kharja mel l'ordinaire)"
replace inno_exampl_produit1 = "de la teinture, amélioration de la production à travers de nouvelles idées et création de chapeaux en paille" if inno_exampl_produit1 == "sebigha , tatawer mantouj men naheyet afkar jdid khedma zdet hajet medhalat ++++++++++++++++++++++++++++++++++++" /*TBC*/
replace inno_exampl_produit1 = "j'ai fait de nouvelles infusions destiné pour les femmes allaitantes / on a fait des améliorations dans la qualité de production/ on a rajouté dans production et qualité de la moringa" if inno_exampl_produit1 == "aamlt des infusions jdod destiné pour les femmes allaitante / aamelou améliorations fl qualité de production/ zedou fl production et qualité de la moringa" 
replace inno_exampl_produit1 = "sport et enfant" if inno_exampl_produit1 == "sport et enfant*********************************************" /*TBC*/
replace inno_exampl_produit1 = "développement des nouveaux produit" if inno_exampl_produit1 == "développement des nouveaux produit,............................" /*TBC*/
replace inno_exampl_produit1 = "changement de l' emballage et qualité de produit" if inno_exampl_produit1 == "changement de l' emballage et qualité de produit ++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
*replace inno_exampl_produit1 = "on a amélioré la production" if inno_exampl_produit1 == "hasanna fil masna3 w wafarna l9loub +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
replace inno_exampl_produit1 = "des nouvelles création des produits" if inno_exampl_produit1 == "des nouvelles création des produits ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/
replace inno_exampl_produit1 = "odoo et tecnologie web" if inno_exampl_produit1 == "odoo et tecnologie web ++++++++++++++++++++++++++++++++++++++++++" /*TBC*/
replace inno_exampl_produit1 = "l'emballage et le design/ dans le produit que nous avons transformé avec des sucres naturels/ innovation dans la diversité des produits en produisant des produits biologiques comme les graines de lin" if inno_exampl_produit1 == "fel emballage fel designe / fel produit 3awadhto b des sucres naturelles / innovation fel anwe3 mta3 bel produit ya3mlo des produits biologique kima zere3et ketene"
replace inno_exampl_produit1 = "la qualite de la chaine de production qui est devenue plus petite et la qualite de production" if inno_exampl_produit1 == "la qualite fel chaine de production radoha sghira o fel qualite de production"











*inno_exampl_produit2
replace inno_exampl_produit2 = "de nouveaux jouets en bois et d'autres ustensilles de cuisine" if inno_exampl_produit2 == "des nouvelles jouets en bois et des autres ustenside de cuisine ************"
replace inno_exampl_produit2 = "des etudes à l'étranger" if inno_exampl_produit2 == "des etudes a letranger aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
replace inno_exampl_produit2 = "de nouvelles formations de coiffure, ils ont rajouté un atelier de coifire et la possibilité de se déplacer dans les différentes régions pour faire les formations" if inno_exampl_produit2 == "des nouvelles formation de coiffure zedou atelier o de coiffure o f sociale zedou partie social mta3 jihet yetnaklou lel jihet o ya3mlou des formation"
replace inno_exampl_produit2 = "des jbeyeb (tenues traditionnelles masculines)" if inno_exampl_produit2 == "jbeyeb les liquette aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
replace inno_exampl_produit2 = "gel fixateur" if inno_exampl_produit2 == "gel fixateur **************************************************************************"
replace inno_exampl_produit2 = "on s'est concentré sur des services profesionnels" if inno_exampl_produit2 == "rakzou aala les services professionnels +++++++++++++++++++"
replace inno_exampl_produit2 = "concealer, eyeliner, blush, bodyblush" if inno_exampl_produit2 == "concilier , eyeliner , blush , bodyblush ++++++++++++++++++++++++++++++++++++++++++++ +++++++++++++++++++++++++++++++"
replace inno_exampl_produit2 = "services marketing en ligne/ on a travaillé sur l'image de marque/ site web en cours pour les ventes en ligne/ j'ai fait un logiciel interne personnalisé" if inno_exampl_produit2 == "services marketing en ligne / tkhdem aala l'image/ site web (en cours) pour les ventes en ligne/ aamlt logiciel interne personnalisée"
replace inno_exampl_produit2 = "le conseil" if inno_exampl_produit2 == "le conseil ++++++++++++++++++++++++++++++++++++++++++++"
replace inno_exampl_produit2 = "on a sorti une nouvelle gamme de produits de décoration et ont s'est concentré sur la céramique artistique" if inno_exampl_produit2 == "kharajna gamme jdida f les articles de decoration / rakazna aala ceramique artistique +++++++++++++++++++++++++++++++"
replace inno_exampl_produit2 = "produit publicitaires , importer des nouveaux produit naturels  et elle fait leurs chartes, elle fait des choses personnalisées en fonction de l'occasion ou de la demande du client" if inno_exampl_produit2 == "produit publicitaires , importer des nouveaux produit naturels w taamel les chartes met3hom , w taamel hajet personnalisé heya w l'occasion/ demande de client"
replace inno_exampl_produit2 = "l'astrotourisme" if inno_exampl_produit2 == "les astrotorisme .................................."
replace inno_exampl_produit2 = "des produits cosmétiques et ont diversifié les produits de décoration" if inno_exampl_produit2 == "des produit cosémitique amlou variation produit de décoration aaaaaaaaaaaaaaaaaaaaaa"
replace inno_exampl_produit2 = "tomates, piments, melons et citrouille" if inno_exampl_produit2 == "tomùate, pimon , dele3 ,9ra3***********************"
replace inno_exampl_produit2 = "des produit agro alimentaires" if inno_exampl_produit2 == "des produit agro alimentaires ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
replace inno_exampl_produit2 = "des bougies" if inno_exampl_produit2 == "des bougies ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
replace inno_exampl_produit2 = "déloppement dans export" if inno_exampl_produit2 == "déloppement fel export ********************************"
replace inno_exampl_produit2 = "parures et housses de lit" if inno_exampl_produit2 == "parure de lit et ouss de lit ++++++++++++++++++++++++++++++++++++++++++++++++++++++"
replace inno_exampl_produit2 = "produit en gré" if inno_exampl_produit2 == "produit en gré +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/
replace inno_exampl_produit2 = "de nouveaux sacs à main en cuir" if inno_exampl_produit2 == "des nouvelles sacs a main en cuire *****************************************************" 
replace inno_exampl_produit2 = "des nouvelles formes de produit" if inno_exampl_produit2 == "des nouvelles forme de produit ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/
replace inno_exampl_produit2 = "organisation d'évenements" if inno_exampl_produit2 == "organisation des evenements++++++++++++++++++++++++++++++++++" 
replace inno_exampl_produit2 = "lancement d'un nouveau produit : pour un cadeau (cookies de gourmandise)" if inno_exampl_produit2 == "lancement d'un nouveau produit : pour un cadeau (cookies m3a gourmandise)**********************************************************************************" 
replace inno_exampl_produit2 = "maquillage: les écrans, de noveaux mascaras, gloss et pinceaux" if inno_exampl_produit2 == "les crean /des nouveaux mascara et glosse et panceau" 
replace inno_exampl_produit2 = "des confitures, sauce tomate, jus de citronade" if inno_exampl_produit2 == "des coniftueres sauce tomate les jus citronade aaaaaaaaaaaaaaaaaaaaaa" 
replace inno_exampl_produit2 = "le marketing digital" if inno_exampl_produit2 == "le marketing digital....................................................." /*TBC*/
replace inno_exampl_produit2 = "des confitures de tomates sucrées + de nouveaux parfums pour les pâtes à tartiner" if inno_exampl_produit2 == "confutour deb tomate sucre/ des gouts jdod pour les pates a tartiner"
replace inno_exampl_produit2 = "sacs de soirée, accessoires de soirée" if inno_exampl_produit2 == "sacs de soiré /accesoire de soiré.........................................*"
replace inno_exampl_produit2 = "des solutions digitales" if inno_exampl_produit2 == "les solutions degitales....................................." /*TBC*/
replace inno_exampl_produit2 = "nouvelle conception et liaison intelligente" if inno_exampl_produit2 == "nouvelle conception et liaison intelligente ..........." /*TBC*/
replace inno_exampl_produit2 = "des articles de cadeaux, Haïk Kamraya, des sacs et des pochette sur taille de pc block note" if inno_exampl_produit2 == "les articles de cadeau haiek 9amraya des sacs et des pochette sur taille de pc block note"
replace inno_exampl_produit2 = "des abats-jours en laine et paille" if inno_exampl_produit2 == "abajoret bil 7alfa w souf *************************"
replace inno_exampl_produit2 = "j'ai fait une évolution avec la paille/ j'ai fait des chnagement avec le mais pour les personnes qui ont des maladies infectieuses et les personnes qui souhaitent faire un régime" if inno_exampl_produit2 == "aamlt évolution bel halfa/ aamlt halawiyet sihiya bel mais ll laabed eli aandha des maladies infectieuse w ll laabed eli theb taamel régime"
replace inno_exampl_produit2 = "des parasols et des drapaux de Tunisie avec de la paille " if inno_exampl_produit2 == "medhalat , aalam tounes bel halfa ++++++++++++++++++++++++++++++++++++++++++++++"
replace inno_exampl_produit2 = "j'ai travaillé des modèles traditionnels et modernes" if inno_exampl_produit2 == "خدمت موديلات قريبة للزمني و فيها حاجات مطورة و مواكبة للعصر" /*TBC*/
replace inno_exampl_produit2 = "service dans le domaine de sport" if inno_exampl_produit2 == "service dans le domaine de sport***********************************" /*TBC*/
replace inno_exampl_produit2 = "coffret cadeau" if inno_exampl_produit2 == "coffret cadeau *************************************" /*TBC*/
replace inno_exampl_produit2 = "le conseil, audit" if inno_exampl_produit2 == "le conseil, audit *************************************************" /*TBC*/
replace inno_exampl_produit2 = "changement de la quantité de produit .innovation de bssissa avec du chocolats et des fruits secs .et goutée pour les enfants" if inno_exampl_produit2 == "changement de la quantité de produit .innovation de bssissa avec du chocolats et des fruits secs .et goutée pour les enfants+++++++++++++++++++++"
replace inno_exampl_produit2 = "des nouvelles création des produits" if inno_exampl_produit2 == "des nouvelles création des produits ++++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/
replace inno_exampl_produit2 = "odoo et la partie marketing" if inno_exampl_produit2 == "odoo et la partie marketing ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/
replace inno_exampl_produit2 = "sucré  et salé avec une nouvelle texture/ le fondant" if inno_exampl_produit2 == "sucret salé b texture jdida / le fandant /***********" 
replace inno_exampl_produit2 = "mini chaine dolive" if inno_exampl_produit2 == "mini chaine dolive ***************************......................" /*TBC*/
replace inno_exampl_produit2 = "La poterie, la harissa, les épices arabes, la salade grillée et les vêtements traditionnels." if id_plateforme==1140


}




{
*inno_proc_other
replace inno_proc_other= "changement de l’emballage, introduction des nouveaux jouets et des nouvelle gammes" if inno_proc_other =="changement de l’emballage . introduction des nouveaux jouets et des nouvelle gammes **********"
replace inno_proc_other= "l'export à renforcer la formation" if inno_proc_other =="lexport kaouitou f formationn aaaaaaaaaaaaaaaaaaaaaaaaaa" /*TBC*/
replace inno_proc_other= "des formations pour les employés afin de garantir la durabilté des produits artisanaux" if inno_proc_other =="des formation lel employés bech todhmen el durabilté les produit artisanaux" 
replace inno_proc_other= "ils ont intégré du commercial et ont un nouvel canal de distribution" if inno_proc_other =="dakhlou el commercial oualew andhon un un canal de distrubtion ****************************" 
replace inno_proc_other= "aménagement, extension du laboratoire" if inno_proc_other =="aménagement, extension du laboratoire +++++++++++++" 
replace inno_proc_other= "ils ont fait des changements au niveau des offres et ont fait des changements dans les packs services" if inno_proc_other =="aamlou des changements au niveau des offres / w aamlt changement fl les packs services" 
replace inno_proc_other= "elle a l'intention d'introduire un planning des matières nouvelles afin de faciliter le travail et réduire le coût de production" if inno_proc_other =="planning bech dakhel bih des matieres jdoud bech tsahel khedma w thasen fl cout de production" 
replace inno_proc_other= "de nouveaux employes et de nouvelles matières ont été rajoutés" if inno_proc_other =="zedna des employés , zedna matériel jdid +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
replace inno_proc_other= "elle a changé l'organisation du management intérieur" if inno_proc_other =="badlt fl l'organisation de management haja intérieur" 
replace inno_proc_other= "par rapport aux communications plus networking , participation aux evenemnets d'ordre professionnel" if inno_proc_other =="par rapport aux communications plus networking , participation aux evenemnets d'ordre professionnel +++++++++++++++++++++++++++++++++" 
replace inno_proc_other= "elle a aggrandit l'espace de stockage et les touriste viennent pour voir l'expérience" if inno_proc_other =="kabaret fl stockage , ijiw les touriste ichoufou l'experiences" 
replace inno_proc_other= "elles ont travaillés sur des formations techniques (pratiques), ont rajouté des workshops pour les petits et se sont concentrés plus sur le digital" if inno_proc_other =="khdemna aala les formations technique (pratique) w zedna des workshop ll sghar / rakazna aala digitale akther +++++++++++++" 
replace inno_proc_other= "site web , sponsoring , les promotions, application mobile" if inno_proc_other =="site web , sponsoring , les promotions, application mobile ++++++++++++++++++++++++" 
replace inno_proc_other= "elle a fait un site web" if inno_proc_other =="aamalt site web +++++++++++++++++++++++++++++++++++++++++++++++++++" 
replace inno_proc_other= "elle a changé de local" if inno_proc_other =="changer local ************************************" 
replace inno_proc_other= "team building" if inno_proc_other =="team building ********************************************************" 
replace inno_proc_other= "les compétences de l'équipe et de nouveaux recrutements" if inno_proc_other =="les competences de lequippe et recrutement jdod............................" 
replace inno_proc_other= "mise en place de panneaux solaires pour génerer l'éclectricité dans sa ferme" if inno_proc_other =="paneau solaire pour electricté dans sa ferme ++++++++++++++++++++" 
replace inno_proc_other= "genre" if inno_proc_other =="genre +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/ 
replace inno_proc_other= "l'export" if inno_proc_other =="l' expot +++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/ 
replace inno_proc_other= "changement de local" if inno_proc_other =="changement de local++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
replace inno_proc_other= "aggrandissement de l'équipe et de nouveaux bureaux" if inno_proc_other =="agrandir l equipe neveau bureau +++++++++++++++++++++++++++++++++" 
replace inno_proc_other= "étude de marché à l'etranger" if inno_proc_other =="étude de marché à l'etranger****************************************" 
replace inno_proc_other= "ajout d'une nouvelle ligne de production + prospection de marché à l'étranger" if inno_proc_other =="zedou ligne de production / chofto des marche bara" 
replace inno_proc_other= "ils ont rajouté des marchés à l'international" if inno_proc_other =="zedou enfathou ala marchés international *****************************" 
replace inno_proc_other= "ajout d'une charte graphique, changement de l'emballage, changement du site web et de nouveaux catalogues" if inno_proc_other =="iso chart graphique kemla embalage kemel badlouh o site web o nouveaux catalogue" 
replace inno_proc_other= "elle a augmenté le nombre d'employés afin d'améliorer la production et augmenter la rapidité du traail + elle a travoué de nouvelles méthodes de travail où elle donne la majorité du travail aux employés et elle prends la responsabilité et s'occupe du suivi du travail" if inno_proc_other =="zedet chwaya khadema bech thasen fl production w tzid fl rapidité fl khedma / lkat nouvelles méthodes fl khedma maaneha taati ll khadema ykhdmou koul chay w prendre la responsabilité w heya taamel el suivi metaa khedma" 
*replace inno_proc_other= "ils ont rajouté des marchés à l'international" if inno_proc_other =="ghayart fl mantoujet aamalt midhalet ++++++++++++++++++++++++++++++++++++++++++" /*TBC*/ 
replace inno_proc_other= "actions de marketing" if inno_proc_other =="actions de marketing**********************************************" 
replace inno_proc_other= "le local a été aggrandi" if inno_proc_other =="kabarna fi local ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" 
replace inno_proc_other= "intégration de nouveaux matériaux" if inno_proc_other =="integration de nouveaux materieles**********************......................................." 

}




{
*inno_mot_other
replace inno_mot_other= "suite à des formations où elle a eu une idée sur les besoins que les gens ont et a pensé à faire des formations pour aider ces personnes en besoin" if inno_mot_other =="suite a des formation ykaounou fehom houma khdhet men andhom lfekra besoin men aned eness eli tkaouen fehom eli houma m aryef khammet tamlelhom formation bech thabbebhom f produit" 
replace inno_mot_other= "suite à un déjeuner avec le groupe projet pompate qui ont fait des remarques" if inno_mot_other =="ijini groupe projet pompate youfter hadheya yaatini des remarques nkhouha ++++++++++++++++++++++++++++" 
replace inno_mot_other= "par des recherches sur internet pour avoir des nouvelle méthodes de marketing / j'ai fait un site web pour les ventes en ligne / a travers des fournisseurs" if inno_mot_other =="par des recherches sur internet pour avoir des nouvelle méthodes de marketing / aamlt site web pour les ventes en ligne / a travers des fournisseurs" 
replace inno_mot_other= "l'inspiration provient des formations / je vois ce qui est demandé sur le marché, on fait des analyses et ont sort le produit par rapport à ce que le consommateur a besoin" if inno_mot_other =="l'inspiration men les formations / nchoufou chnowa el matloub fl marché w naamelou les analyses w nkharjou el produit par rapport ll consommateur chnowa hachtou" 
replace inno_mot_other= "en fonction de la demande du marché" if inno_mot_other =="heya w demande de marché ++++++++++++++++++++++++++++++++++" 
replace inno_mot_other= "réunion avec d'autres membres du consortium" if inno_mot_other =="réunion avec d’autre nombre du consortium" 
replace inno_mot_other= "du travail" if inno_mot_other =="mil 5edma" /*TBC*/ 
replace inno_mot_other= "à partir des réclamations qui se trouve dans le bilan" if inno_mot_other =="a partir mel les reclamation qui se trouve dans le billant"
replace inno_mot_other= "elle meme , famille amis , equipe de travail" if inno_mot_other =="elle meme , famille amis , equipe de travail ++++++++++++++"
replace inno_mot_other= "participation aux formations" if inno_mot_other =="participatin au les formation ++++++++++++++++++++++++++++++++++++++++"
replace inno_mot_other= "de l'equipe, recherche sur l' internet reseaux sociaux" if inno_mot_other =="de l'equipe recherche sur l' internet reseaux sociaux ++++++++++++++++++++++++++"
replace inno_mot_other= "son fils/ radio (express FM)" if inno_mot_other =="weldha / express fm"
replace inno_mot_other= "l'idée provient d'eux mêmes ou d'anciennes idées" if inno_mot_other =="fekra men 3andhom afkar kdima"
replace inno_mot_other= "de sa propre équipe" if inno_mot_other =="men son propres equipes"
replace inno_mot_other= "de la GIZ" if inno_mot_other =="mme ikram mel giz"
*replace inno_mot_other= "3d de bouzard" if inno_mot_other =="3d de bouzard" /*TBC*/ 
replace inno_mot_other= "c'est sa propre idée" if inno_mot_other =="fekrtha heya ++++++++++++++++++++++++++++++"
replace inno_mot_other= "programmes TV/ elle voit des photos par exemple de la télévision ou des publicités dans la rue" if inno_mot_other =="programme tv/ tchouf tsawer par exemple men television wala des publicités fl cheraa"
replace inno_mot_other= "les programmes d'appui" if inno_mot_other =="les programme d'appui +++++++++++++++++++++++++"
replace inno_mot_other= "les besoins du marché" if inno_mot_other =="besois du merchés +++++++++++++++++++++++++++++++++++++++++++++++++++++++"
replace inno_mot_other= "en fonction de la demande du marché" if inno_mot_other =="en facteur de la demande du marche"

*export_other
replace export_other= "l'export en Afrique est dur" if export_other =="f afrique lesxport s3ib"
replace export_other= "il n'y a pas de demande" if export_other =="mafammech demande"
replace export_other= "manque des ressources pour mettre une personne qui va s'occuper de l'export + elle n'a pas trouvé des stagières de commerce internationale pour les aider à faire des étude de marché pour l'export" if export_other =="manque des ressources pour mettre une personne yetlhé bel export malkatech des stagieres de commerce internationaux bech y3aounohom lel etude de marche pour l'export"
replace export_other= "ils préfèrent se concentrer sur le marché national" if export_other =="taw ihebou irakzou aala nationale akther"
replace export_other= "manque de ressources et de certifications d'autres pays" if export_other =="manque de ressources , certification men douwal okhra ++++++++++++++++++++++++++++++"
replace export_other= "ils n'ont pas la capacité de production requise" if export_other =="famech capacite de production"
replace export_other= "il n'y a pas d'opportunité" if export_other =="mafamech opportunité"
replace export_other= "elle a arrete la production" if export_other =="elle a arrete la production ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
replace export_other= "je n'ai pas de contrats, je ne pars pas aux foires de commerce, je n'ai pas de site web et je n'ai personne qui puisse s'occuper des activités d'export" if export_other =="aandich des contacts , manemchich les foires de commerce , aandich site web, aandich chkoun bech yaamali export +++++++++++++++++++++++"
replace export_other= "ils ont arrêté d'exporter, une proposition leur a été faite pour cette gamme afin de commmercialiser en Tunisie" if export_other =="maatech taamel,kaset w manajmouch ikamlou fl l'export / jethom proposition metaa gamme hedheya pour commercialiser en tunisie"
replace export_other= "il n'y a pas d'opportunité" if export_other =="famech des opportunités +++++++++++++++++++++++++"
replace export_other= "il n'y a pas d'opportunité" if export_other =="famech opportunité d'export"
replace export_other= "il a des opportunités d'export mais elle n'a pas terminé l'opération" if export_other =="fama des opportunités metaa exportation ama tkmelech l'operation +++++++++++++++++++++++++++++++++++++++++++++++++++++++++" /*TBC*/ 
replace export_other= "on na pas trouver les bonnes personnes dans les pays étrangers" if export_other =="on na pas trouver les bonnes personnes fel les pays étrangers"
replace export_other= "ils ne savent pas comment exporter: les procédures et les processus leurs font défaut, il manque les certifications, ils ont des clients et ne connaissent pas les étapes nécéssaires pour l'exportation" if export_other =="mayarfouch kifeh ysadrou les procedures l process kemla neksethom les certifcation o kol nekshom les client maoujoudin ama nekshom les etapes mta l'exportation"
replace export_other= "il n'y a pas de financement" if export_other =="famech financement financier"
replace export_other= "elle n'a pas l'accès à l'exporation, il n'y a pas d'opportunités et l'export une importante capacité de production qu'elle ne peut pas assurer." if export_other =="aandhech l’accès bech tsader w famech opportunité w zid ihebou aala quantité kbira ama heya matnajamech"


*man_sources_other
replace man_sources_other= "j'ai travaillé avec une entreprise néérlandaise sur terrain + les formations en ligne et en présentielles" if man_sources_other =="khdmet maa entreprises f holanda sur terrain+les formations en ligne/présentiel ++++++++++++++++"
replace man_sources_other= "je vois ce qui se passe sur le marché à l'échelle internationale et je m'inspire des nouveautés sur le marché internationales pour de nouvelles stratégies" if man_sources_other =="nchoufou chnowa derej fl marche a l’échelle international w hakeka tjina l'influence metaa des nouvelles stratégies"
replace man_sources_other= "j'ai appris des nouvelles stratégies à partir des formations en ligne et en présentiel, des programmes et des expériences passées" if man_sources_other =="men des formations en ligne et présentiel et des programmes , des experiences taalamthom ++++++++++++++++++++++++++++"
replace man_sources_other= "les formations en ligne / les missions b2b" if man_sources_other =="les formations en ligne / les missions b2b +++++++++++++++++++++++++++++++++"
replace man_sources_other= "les formations , des programmes de coaching sinon je fais des analyses et je vois ou je dois m’améliorer" if man_sources_other =="les formations , des programme de coaching sinon naamel les analyses w je vois ou je dois m’améliore"
replace man_sources_other= "elle lit beaucoup Science Nord d'où elle a appris la planification, le développement des stratégies et des idées" if man_sources_other =="takra barcha nord sciences taalmet menou planification/ developpement des strategie/ developpement des idees +++++++++++++++++++++++++++++++++++++++++++++++"
replace man_sources_other= "les formations professionnelles où elle a appris la création de l'entreprise et les programmes de la GIZ" if man_sources_other =="dawarat takwineya taalem les créations de l'entreprise / les programmes giz ++++++++++++++++++++++++++++++++++"
replace man_sources_other= "les formations de la GIZ et l'expérience" if man_sources_other =="formatiions de giz w l'expérience"
replace man_sources_other= "les formations de la GIZ" if man_sources_other =="formations de giz ++++++++++++++++++++++++++++++++++++"
replace man_sources_other= "les broadcasts sur Internet" if man_sources_other =="bodcast sur internet ++++++++++++++++++++++++++"
replace man_sources_other= "les études" if man_sources_other =="les etudes ++++++++++++++++++++++++++++"
replace man_sources_other= "une agence de communication qui suit le programme dream for use gg4 youth" if man_sources_other =="agence de communication heya teb3a proggrame dream for use gg4 youth" /*TBC */
replace man_sources_other= "l'inspiration de nouvelles stratégies provient d'elle-même" if man_sources_other =="l'inspiration tji men aandha"
replace man_sources_other= "des formations" if man_sources_other =="des formations+++"
replace man_sources_other= "des programmes TV / des formations présentielles / des publicités" if man_sources_other =="mel programmes tv / les formations présentiel / mel les publicités"
replace man_sources_other= "elle meme fait la recherche sur internet et les formations en ligne" if man_sources_other =="elle meme fait la recherche sur internet et les formations en ligne +++++++++++++++++++++"
replace man_sources_other= "les formations et les commandes" if man_sources_other =="les formations et les commandes ++++++++++++++++++++++++++++++++++++++++++++++"
replace man_sources_other= "j'ai étudié" if man_sources_other =="9rit"

*net_services_other
replace net_services_other= "elle a utilise ses contacts avec d'autres entrepreneurs pour faire des connaissances à travers eux" if net_services_other =="elle a utilise ses contacts avec d'autre entrepreneur pour faire des connaissances à travers eux+++++++++++++++++++++++++++++"
replace net_services_other= "établir des liens avec d'autres entrepreneures" if net_services_other =="faire des liens avec d'autre entrepreneures ++++++++++++++++++++++++++++++++++++++++++++"
replace net_services_other= "partage des formations et les sites" if net_services_other =="partage des formations et les sites ++++++++++++++++++++++++"
replace net_services_other= "comment pénétrer un nouveau marché" if net_services_other =="comment créer un nouveau marché"
replace net_services_other= "les compétitions, les événements et des formations" if net_services_other =="compétetions, les évenements, des formations"
replace net_services_other= "elle utilise ses contacts pour le partage d'expériences" if net_services_other =="estaamlet les contacts met3ha pour partage d'expériencess"

*int_ben1
replace int_ben1="Le travail sur soi-même" if int_ben1== "تعمل على روحك" 
replace int_ben1="" if int_ben1== "-" /*TBC*/
replace int_ben1="de nouveaux partenaires qui ont débuté à travailler avec moi" if int_ben1== "des partenaires walew yekhdmou meaya"
replace int_ben1="apprentissage procedures de l'export" if int_ben1 =="ta3alom les prorusses de l’export"
replace int_ben1 ="nouvelles connaissances" if int_ben1 =="bech tetaref ala abed jdod"
replace int_ben1 ="nouvelles connaissances" if int_ben1 =="t3arfet ala abed jdod"

*int_ben2
replace int_ben2="Le travail d'équipe" if int_ben2== "تعمل عالفريق متاعك" 
replace int_ben2="j'ai trouvé des chemins pour exportation et prospection" if int_ben2== "lkit des chemins pour exportation et prospection" 
replace int_ben2="j'ai appris beaucoup ded choses par rapport aux techniques" if int_ben2== "tet3alem barcha hajet fe les techniques"  /*TBC*/
replace int_ben2="nom de bons contacts au sein du consortium" if int_ben2== "non des contactes behin fel consortuim"
replace int_ben2="connaissances des marchés africains" if int_ben2== "connassances des marcheres aafricain"

*int_ben3
replace int_ben3="Travail sur le produit en restauration" if int_ben3== "تعمل عالمنتوج متاعم" 
replace int_ben3="expériences par rapport aux visites te permettent de faire des analyses / comparaison / évaluation des produits par rapport aux secteurs" if int_ben3== "expériences par rapport ll les visites ikhalik tnajem taamel les analyses / comparaison / évaluation des produits par rapport aux secteurs"
replace int_ben3="j'ai appris d'eux les procédures d'export et des techniques digitales" if int_ben3== "t3alamet menhom fel export o fel digitale"
replace int_ben3="des opportunités d'exposition en Arabie Saoudite" if int_ben3== "opportunité dexposition f saudi"
replace int_ben3 ="partenariat et expériences" if int_ben3=="charaka et expériences"
replace int_ben3 ="Travailler ensemble" if int_ben3=="oualeou yekhdmou maa badhhom"



*int_ben_autres
replace int_ben_autres="" if int_ben_autres== "+++++++++++++++++++++" /*TBC*/
replace int_ben_autres="financement" if int_ben_autres=="l9it chkoun ymawalni"

*int_incv1
replace int_incv1="L'entreprise a été victime d'injustice et n'a pas été inscrit dans le groupe malgré un dossier complet" if int_incv1== "تعرضت شركني لظلم وعدم التسجيل في المجموعة رغم مدي بملفي كامل وشامل" 
replace int_incv1="L'ambiance générale" if int_incv1== "jaw l3am" 
replace int_incv1="La methode de selection des entreprises" if int_incv1=="difficulté enou thatou les membres mabaadhhom meghir ma yakhtarou baadhhom"
replace int_incv1="Diversité des profils et caracteres des membres" if int_incv1=="les membres meandhomch nafes profil o mech nafes tbi3a"
replace int_incv1="Mal organisation du gie" if int_incv1=="l'organisation mta gie maajbthech mehish mnadhma"




*int_incv2
replace int_incv2="Je ne peux pas être d'accord avec les idées des participantes" if int_incv2== "matnajemesh twafe9 bin les aidées des participants" 
replace int_incv2="limitation des ressources financières" if int_incv2== "immitation des ressources financier" 
replace int_incv2="" if int_incv2== "++++++" /*TBC */
replace int_incv2="il y a une importante hétérogénéité au sein du consortium: certaines entreprises sont encores débutantes alors que d'autres sont bien établies depuis longtemps" if int_incv2== "les membres est trop élevés ykalak khater fama abed debuante o fama abed kdom barcha"
replace int_incv2="Malheureusement, il y une distinction régionale (entre le Sud et le Nord)" if int_incv2== "التميز بين الجنوب والشمال الاسف"
replace int_incv2="il n'y a pas de motivation pour l'équipe" if int_incv2== "mfamech motivation lel equipe"
replace int_incv2="Beaucoup de membres ont quitté le consortium à cause des conflits internes" if int_incv2=="barcha kharjou men consortium b houkem fama barcha machekel bin les membres du consortium"
replace int_incv2="conflit avec la giz, beaucoup d'idées qui ne sont pas d'accord entre giz et gie" if int_incv2=="les conflit mta giz barha macchekel maytfehmoush ala nafes les aidéés"



*int_incv3
replace int_incv3="" if int_incv3== "+++++++++++++"  /*TBC */
replace int_incv3="" if int_incv3 == "+++++"  /*TBC */
replace int_incv3="les formations qui ont été faites étaient une perte de temps car elles n'étaient pas stratégies car ils n'ont pas le même courant de pensée" if int_incv3 == "les formation eli amlhom perdre de temps khater mahomech stratégique khater houma déjà mouch nafes tafkir"  
replace int_incv3="Je n'en profiterai pas financièrement" if int_incv3 == "لن استفاد ماديا"  
replace int_incv3="Ca prends trop de temps de ma vie" if int_incv3 == "yekhou barcha wakt mn hyeti"  

*int_incv_autres
replace int_incv_autres="" if int_incv_autres =="+++++++++++++++++++"  /*TBC */
replace int_incv_autres="" if int_incv_autres =="++++"  /*TBC */
replace int_incv_autres="J'ai perdu mon temps et j'ai fait de gros efforts pour assister à toute la cérémonie, et finalement nous avons été victimes d'une grande injustice." if int_incv_autres =="ضيعت وقتي وبذلت مجهود كبير للحضور طيلة التكويل وفي الاخر نتعرض لظلم كبير"  
replace int_incv_autres="notre diversité nous a fait perdre beaucoup de temps et d'énergie pour fixer la meilleure stratégie pour le gie; cumul beaucoup de retard sur ma propre entreprise (voir même une stagnation pendant une longue période)" if int_incv_autres =="notre diversité nous a fait perdre beaucoup de temps et d'énergie pour fixer la meilleure stratégie pour le gie ==&gt; cumul beaucoup de retard sur ma propre entreprise (voir même une stagnation pendant une longue période)"  

*int_other
replace int_other= "elle a dit à quoi cela sert de participer au consortium lorsque elle a un service et pas un bien pour faire l'exportation. De plus, elle a une plateforme à l'échelle nationale (et non internationale) ce qui la pousse à avoir de nouvelles strategies pour pouvoir exporter si elle fait partie du consortium" if int_other =="kalt a quoi sert de participer au consortium wakteli heya aandha services mouch bien bech taamel l'exportation w zid heya aandha plateforme a l’échelle nationale mouch internationale (lezem tkoun internationale ) donc bech taamel l'exportation w tcherek fl consortium lezem des nouvelles stratégie"
replace int_other="" if int_other =="————————"  /*TBC */
replace int_other="elle n'est pas prete à participer au consortium" if int_other =="elle n'est pas prete a participer au consortium +++++++++++++++++++++++++++++++++++++"
replace int_other="pour des raisons légales: le consortium égigne que la gérante soit une femme alors que son co-gérant est un homme" if int_other=="pour des raisons légal / consortium oblige tkoun gérante totalement féminine w heya maaha rajel donc mays3dhech"
replace int_other="l'aggréssivité de certaines personnes, le comportement des entrepreneurs et la mauvaise organisation de la GIZ" if int_other =="grasivite des personnes le comportement des entrepreneur acause du mal organisation de giz"
replace int_other="elle ne peut pas faire partie du consortium car elle a des engagements familiaux" if int_other =="manajmtech nemchi aandi des engagements familiaux"
replace int_other="elle n'est pas disponible" if int_other =="n'est disponible +++++++++++++++++++++++++++++++++++"
replace int_other="lors de la sélection du groupe, il n'y a pas de transparence" if int_other =="fel selection du grouppe mefamech chafafia"	
}

***********************************************************************
* 	PART 8:  Destring remaining numerical vars
***********************************************************************

local destrvar ca ca_2024 profit profit_2024 ca_exp ca_exp_2024
foreach x of local destrvar { 
destring `x', replace
format `x' %25.0fc
}

***********************************************************************
* 	Part 8: Save the changes made to the data		  			
***********************************************************************
save "${el_intermediate}/el_intermediate", replace
