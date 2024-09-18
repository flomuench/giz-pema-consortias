***********************************************************************
* 			Consortia field experiment:  diagnostic								  		  
***********************************************************************
*																	   
*	PURPOSE: Create a diagnostic for consortia and export preparedness scores to share with the firms			  								  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Adapt variables for diagnostic scores
*	2)		Automate writing of reports 
*   3)		Save														  
*
*																 																      *
*	Author:  	Kaïs Jomaa												  
*	ID variable: 	id_plateforme			  									  
*	Requires:		bl_final.dta
*	Creates:		
*																	  

***********************************************************************
* 	PART Start: Import the dataqsdsqdsq
***********************************************************************

	* import data
use "${master_final}/consortium_final", clear

**********************************************************************
* 	PART 1:  Final adaptation for diagnostics to be sent to firms 

***********************************************************************

/* --------------------------------------------------------------------
	PART 1.2: Create scores (with overall and sector averages)
----------------------------------------------------------------------*/

* First, management practices index: 
egen man_index_raw= rowtotal(man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv man_fin_per_fre man_fin_pra_bud man_fin_pra_pro man_fin_pra_dis man_ind_awa) if surveyround ==3
g man_index = (man_index_raw/11)*100 if surveyround ==3
egen avg_man_index = mean(man_index) if surveyround ==3
egen sectoral_avg_man_index = mean(man_index) if surveyround ==3, by(sector)

lab var man_index_raw "(Raw) sum of all management practices"
lab var man_index "Percentage of all management practices"
lab var avg_man_index "Average percentage of all management practices"
lab var sectoral_avg_man_index "Sectoral average percentage of all management practices"

*Second, innovation management index
egen inno_index_raw= rowtotal(inno_improve inno_new inno_proc_met inno_proc_log inno_proc_prix inno_proc_sup inno_proc_autres) if surveyround ==3
g inno_index = (inno_index_raw/7)*100 if surveyround ==3
egen avg_inno_index = mean(inno_index) if surveyround ==3
egen sectoral_avg_inno_index = mean(inno_index) if surveyround ==3, by(sector)

lab var inno_index_raw "(Raw) sum of innovation management practices"
lab var inno_index "Percentage of innovation management practices"
lab var avg_inno_index "Average percentage of all innovation management practices"
lab var sectoral_avg_inno_index "Sectoral average percentage of all innovation management practices"

* Thirdly, export preparedness practices 
egen eri_raw = rowtotal(exp_pra_rexp exp_pra_foire exp_pra_sci exp_pra_norme exp_pra_vent) if surveyround ==3
g expprep_diag = (eri_raw/5)*100 if surveyround ==3
egen avg_expprep_diag = mean(expprep_diag) if surveyround ==3
egen sectoral_avg_expprep_diag = mean(expprep_diag) if surveyround ==3, by(sector)

lab var eri_raw "Raw sum of all export preparadness practices"
lab var expprep_diag "Percentage of all export preparadness practices"
lab var avg_expprep_diag "Average percentage of all export preparadness practices"
lab var sectoral_avg_expprep_diag "Sectoral average percentage of all export preparadness practices"

*Fourthly, number of export countries
egen avg_exp_pays_diag = mean(exp_pays) if surveyround ==3
egen sectoral_avg_exp_pays_diag = mean(exp_pays) if surveyround ==3, by(sector)

lab var avg_exp_pays_diag "Average of number of export countries"
lab var sectoral_avg_exp_pays_diag "Sectoral average of number of export countries"

*Fifhtly 

*Sixthly, employer productivity
replace comp_ca2023 = . if comp_ca2023 == 999
replace comp_ca2023 = . if comp_ca2023 == 888
replace comp_ca2023 = . if comp_ca2023 == 777
replace comp_ca2023 = . if comp_ca2023 == 666
replace comp_ca2023 = . if comp_ca2023 == 1234

gen productivity_2023 = (comp_ca2023/employes) if surveyround ==3
egen avg_productivity_2023_diag = mean(productivity_2023) if surveyround ==3
egen sectoral_productivity_2023_diag = mean(productivity_2023) if surveyround ==3, by(sector)
 
lab var productivity_2023 "Company productivity: total turnover over total number of full-time employees" 
lab var avg_productivity_2023_diag "Average employee productivity"
lab var sectoral_productivity_2023_diag "Sectoral average employee productivity"


/* --------------------------------------------------------------------
	PART 1.3: Create deciles for each diagnostic score
----------------------------------------------------------------------*/
sort man_index
xtile man_index_decile = man_index if surveyround ==3, n(10)
lab var man_index_decile "Deciles for management practices"

sort inno_index
xtile inno_index_decile = inno_index if surveyround ==3, n(10)
lab var inno_index_decile "Deciles for innovation practices"

sort expprep_diag
xtile expprep_decile = expprep_diag if surveyround ==3, n(10)
lab var expprep_decile "Deciles for export preparadness score"

sort exp_pays
xtile exp_pays_decile = exp_pays if surveyround ==3, n(10)
lab var exp_pays_decile "Deciles for export countries"

sort productivity_2023
xtile productivity_2023_decile = productivity_2023 if surveyround ==3, n(10)
lab var productivity_2023_decile "Deciles for productivity"

	* Now create statements based on the deciles to be used in the text below 
*1) Performance managériale
gen man_index_raw_text = " "
replace man_index_raw_text = "Votre entreprise se situe dans les 10 % supérieurs en termes d'adoption de pratiques managériales." if man_index > 77.63158 & surveyround ==3
replace man_index_raw_text = "Votre entreprise se situe dans les 25 % supérieurs en termes d'adoption de pratiques managériales." if man_index>= 71.05264 & man_index < 77.63158 & surveyround ==3
replace man_index_raw_text = "Votre entreprise se situe juste au-dessus de la moyenne en termes d'adoption de pratiques managériales." if man_index>=48.82272 & man_index<71.05264 & surveyround ==3
replace man_index_raw_text = "Votre entreprise se situe juste en dessous de la moyenne en termes d'adoption de pratiques managériales." if man_index<48.82272 & man_index>27.63158 & surveyround ==3
replace man_index_raw_text = "Votre entreprise est classée dans les 25 % inférieurs en termes d'adoption de pratiques managériales." if man_index<=27.63158 &  man_index>10.52632  & surveyround ==3
replace man_index_raw_text = "Votre entreprise est classée dans les 10 % inférieurs en termes d'adoption de pratiques managériales." if man_index<=10.52632 | man_index==0 | man_index_decile < 1 & surveyround ==3
replace man_index_raw_text = "Vous n’avez pas répondu à cette question et ainsi nous ne pouvons pas calculer un score pour vous" if man_index==.

*2) Performance en terme d'innovation 
gen inno_index_raw_text = " "
replace inno_index_raw_text = "Votre entreprise se situe dans les 10 % supérieurs en termes d'innovation." if inno_index > 77.63158 & surveyround ==3
replace inno_index_raw_text = "Votre entreprise se situe dans les 25 % supérieurs en termes d'innovation." if inno_index>= 71.05264 & inno_index < 77.63158 & surveyround ==3
replace inno_index_raw_text = "Votre entreprise se situe juste au-dessus de la moyenne en termes d'innovation." if inno_index>=48.82272 & inno_index<71.05264 & surveyround ==3
replace inno_index_raw_text = "Votre entreprise se situe juste en dessous de la moyenne en termes d'innovation." if inno_index<48.82272 & inno_index>27.63158 & surveyround ==3
replace inno_index_raw_text = "Votre entreprise est classée dans les 25 % inférieurs en termes d'innovation." if inno_index<=27.63158 &  inno_index>10.52632  & surveyround ==3
replace inno_index_raw_text = "Votre entreprise est classée dans les 10 % inférieurs en termes d'innovation." if inno_index<=10.52632 | inno_index==0 | inno_index < 1 & surveyround ==3
replace inno_index_raw_text = "Vous n’avez pas répondu à cette question et ainsi nous ne pouvons pas calculer un score pour vous" if inno_index ==.

*3) Préparation et performance à l'export
gen expprep_text = " "
replace expprep_text = "Votre entreprise se situe dans les 10 % supérieurs en termes d'adoption de pratiques de préparation à l'exportation." if expprep_diag>=100 & surveyround ==3 
replace expprep_text = "Votre entreprise se situe dans les 25 % supérieurs en termes d'adoption de pratiques de préparation à l'exportation." if expprep_diag>=80 & expprep_diag < 100 & surveyround ==3
replace expprep_text = "Votre entreprise se situe juste au-dessus de la moyenne en termes d'adoption de pratiques de preparation à l'exportation." if expprep_diag>= 52.33083 & expprep_diag<80 & surveyround ==3
replace expprep_text = "Votre entreprise se situe juste en dessous de la moyenne en termes d'adoption de pratiques preparation à l'exportation." if expprep_diag< 52.33083 & expprep_diag>40 & surveyround ==3
replace expprep_text = "Votre entreprise est classée dans les 25 % inférieurs en termes d'adoption de pratiques de preparation à l'exportation." if expprep_diag<=40 &  expprep_diag>20 & surveyround ==3
replace expprep_text = "Votre entreprise est classée dans les 10 % inférieurs en termes d'adoption de pratiques de preparation à l'exportation." if expprep_diag<=20 | expprep_diag==0  & surveyround ==3
replace expprep_text = "Vous n’avez pas répondu à cette question et ainsi nous ne pouvons pas calculer un score pour vous" if expprep_diag==.

gen exp_pays_text = " "
replace exp_pays_text = "Votre entreprise se situe dans les 10 % supérieurs en termes de nombre de destinations pour l'export." if exp_pays_decile >=9 & surveyround ==3 
replace exp_pays_text = "Votre entreprise se situe dans les 25 % supérieurs en termes de nombre de destinations pour l'export." if exp_pays>=7 & exp_pays < 16 & surveyround ==3
replace exp_pays_text = "Votre entreprise se situe juste au-dessus de la moyenne en termes de nombre de destinations pour l'export." if exp_pays<=5 & exp_pays>7  & surveyround ==3
replace exp_pays_text = "Votre entreprise se situe juste en dessous de la moyenne en termes de nombre de destinations pour l'export." if exp_pays<5 & exp_pays>2 & surveyround ==3
replace exp_pays_text = "Votre entreprise est classée dans les 25 % inférieurs en termes de nombre de destinations pour l'export." if exp_pays<=2 &  exp_pays>1 & surveyround ==3
replace exp_pays_text = "Votre entreprise est classée dans les 10 % inférieurs en termes de pays d'export." if exp_pays<=1 | exp_pays==0 & surveyround ==3
replace exp_pays_text = "Vous n’avez pas répondu à cette question et ainsi nous ne pouvons pas calculer un score pour vous" if exp_pays==.

*4) Perfomance générale
gen productivity_2023_text = " "
replace productivity_2023_text = "Votre entreprise se situe dans les 10 % supérieurs en termes de productivité par employé." if productivity_2023>= 251473.9 & surveyround ==3 
replace productivity_2023_text = "Votre entreprise se situe juste au-dessus de la moyenne en termes de productivité par employé." if productivity_2023>=107454.9 & productivity_2023<100000 & surveyround ==3
replace productivity_2023_text = "Votre entreprise se situe juste en dessous de la moyenne en termes de productivité par employé." if productivity_2023<107454.9 & productivity_2023>177.6 & surveyround ==3
replace productivity_2023_text = "Votre entreprise est classée dans les 25 % inférieurs en termes de productivité par employé." if productivity_2023 <= 177.6 &  productivity_2023>12.10909 & surveyround ==3
replace productivity_2023_text = "Votre entreprise est classée dans les 10 % inférieurs en termes de productivité par employé." if productivity_2023 <= 12.109091 | (productivity_2023 == 0 & surveyround == 3)
replace productivity_2023_text = "Vous n’avez pas répondu à cette question et ainsi nous ne pouvons pas calculer un score pour vous" if productivity_2023==.

***********************************************************************
* 	PART 2:  	make a loop to automate document creation			  *
***********************************************************************
	
	* change directory for diagnostic files
cd "${master_output}/diagnostic"
set scheme s1color	 
set graphics off 
gen row_id = _n


levelsof id_plateforme if attest==1 & surveyround ==3, local(levels_id) 

set rmsg on

quietly{
	foreach x of local levels_id {
		noisily display "Working on `x' at $S_TIME"
		putdocx clear
		putdocx begin, font("Arial", 12) 
		putdocx paragraph, halign(center)
		putdocx image logos_cropped2.png, height (3 cm) linebreak
		putdocx paragraph, halign (center)
		putdocx text ("Scores du diagnostic - PEMA II GIZ “Entrepreneuriat Féminin et Consortium Femmes"), bold underline linebreak 
		putdocx paragraph
		putdocx text ("Chère cheffe d’entreprise,")
		putdocx paragraph
		putdocx text ("Nous réitérons nos remerciements pour votre participation et vos réponses pour le dernier diagnostic, à l’issue duquel, nous avons pu établir ce diagnostic.")
		 
		putdocx paragraph
		putdocx text ("Ce diagnostic prend la forme de plusieurs scores: un score de pratiques managériales, un score sur l'innovation, un score de préparation à l’export (établi grâce aux questions sur l’analyse de vos marchés cibles, la certification de vos produits ou services…), les pays d'exports et un score sur la productivité de votre entreprise.")
		putdocx paragraph
		putdocx paragraph
		putdocx text ("Ces scores ont été établis sur la base des réponses de plus de 200 entreprises ayant répondu aux différentes vagues de diagnostic.")
		putdocx paragraph
		putdocx text ("Ci-dessous  vous trouverez un graphique avec trois barres chacun:"), linebreak
		putdocx paragraph
		putdocx text ("		- La première (rouge) correspond au pourcentage de pratiques adoptées"), bold linebreak
		putdocx text ("		  par votre entreprise."), bold linebreak
		putdocx text ("		- La deuxième (orange) correspond au pourcentage moyen de pratiques"), bold linebreak
		putdocx text ("		  adoptées par l'ensemble des entreprises interrogées."), bold linebreak
		putdocx text ("		- La troisième (gris) correspond au pourcentage moyen de pratiques"), bold linebreak
		putdocx text ("		  adoptées par l'ensemble des entreprises interrogées dans votre secteur."), bold linebreak
		
		putdocx pagebreak
		putdocx paragraph,  font("Arial", 12)
		putdocx text ("Section 1: La performance managériale de l'entreprise"), bold

		putdocx paragraph
		putdocx text ("Le score des pratiques managériales a été construit sur l'adoption et la fréquence de certains indicateurs de performance, l'adoption de pratiques spécifiques de management (avoir budget écrit, distinction des comptes, incitations de performance aux employés) et de l'apprentissage de nouvelles stratégies de management."), linebreak
		putdocx paragraph
		
		graph    hbar man_index avg_man_index sectoral_avg_man_index if id_plateforme==`x', blabel(total, format(%9.0fc)) ///
				subtitle ("Pourcentage des activités adoptées") ///
				title ("Pratiques managériales") ///
				ysc(r(0 100)) ylab(0(10)100) ytitle("%") legend (pos (12) /// 
				lab(1 "Votre Score") lab(2 "Moyenne totale") lab(3 "Moyenne dans votre secteur")) ///
				bar (1 ,fc("208 33 36") lc("208 33 36")) ///
				bar (2 ,fc("241 160 40") lc("241 160 40")) /// 
				bar (3 ,fc("112 113 115") lc("112 113 115")) 
				
		gr export man_score_test_`x'.png, replace
		putdocx paragraph, halign(center) 

		putdocx image man_score_test_`x'.png, height (12 cm)

		preserve
		keep if id_plateforme==`x'
		putdocx paragraph
		putdocx text ("`=man_index_raw_text[_n]'"), linebreak
		restore
		
				putdocx pagebreak
		putdocx paragraph,  font("Arial", 12)
		putdocx text ("Section 2: Les innovations de l'entreprise"), bold

		putdocx paragraph
		putdocx text ("Le score sur l'innovation a été construit sur la base du nombre d'innovations que vous avez fait (produit, technologies, cannaux de marketing, tarification des produits, chaîne de valeur...)."), linebreak
		putdocx paragraph
		
		graph hbar inno_index avg_inno_index sectoral_avg_inno_index if id_plateforme==`x', blabel(total, format(%9.0fc)) ///
				title ("Nombre de pays d'export") ///
				ytitle("Nombre de pays") legend (pos (inside) /// 
				lab(1 "Votre Score") lab(2 "Moyenne totale") lab(3 "Moyenne dans votre secteur")) ///
				bar (1 ,fc("208 33 36") lc("208 33 36")) ///
				bar (2 ,fc("241 160 40") lc("241 160 40")) /// 
				bar (3 ,fc("112 113 115") lc("112 113 115")) 
				
		gr export inno_score_test_`x'.png, replace
		putdocx paragraph, halign(center) 
		putdocx image inno_score_test_`x'.png, height (10 cm)
		
		preserve
		keep if id_plateforme==`x'
		putdocx paragraph
		putdocx text ("`=inno_index_raw_text[_n]'"), linebreak
		restore
		
		putdocx pagebreak
		putdocx paragraph,  font("Arial", 12)
		putdocx text ("Section 3: Préparation et performance à l'export de l'entreprise"), bold

		putdocx paragraph
		putdocx text ("Le score de  préparation et performance à l'export a été construit sur la la base de la participation à des expositions/ foires commerciales internationales, l'expression d'intérérêt d'un acheteur potentiel, l'identification de partenaires commerciaux à l'étranger, la certification des produits selon des normes de qualité internationales et l'investissement d'une structure de vente."), linebreak
		putdocx paragraph
		

		graph hbar expprep_diag avg_expprep_diag sectoral_avg_expprep_diag if id_plateforme==`x', blabel(total, format(%9.0fc)) ///
				subtitle ("Pourcentage de activités adoptées") ///
				title ("Preparation des exportations") ///
				ysc(r(0 100)) ylab(0(10)100) ytitle("%") legend (pos (inside) /// 
				lab(1 "Votre Score") lab(2 "Moyenne totale") lab(3 "Moyenne dans votre secteur")) ///
				bar (1 ,fc("208 33 36") lc("208 33 36")) ///
				bar (2 ,fc("241 160 40") lc("241 160 40")) /// 
				bar (3 ,fc("112 113 115") lc("112 113 115")) 
				
		gr export exp_score_test_`x'.png, replace
		putdocx paragraph, halign(center) 
		putdocx image exp_score_test_`x'.png, height (10 cm)
		
		preserve
		keep if id_plateforme==`x'
		putdocx paragraph
		putdocx text ("`=expprep_text[_n]'"), linebreak
		restore 
		
		graph hbar exp_pays avg_exp_pays_diag sectoral_avg_exp_pays_diag if id_plateforme==`x', blabel(total, format(%9.0fc)) ///
				title ("Nombre de pays d'export") ///
				ytitle("Nombre de pays") legend (pos (inside) /// 
				lab(1 "Votre Score") lab(2 "Moyenne totale") lab(3 "Moyenne dans votre secteur")) ///
				bar (1 ,fc("208 33 36") lc("208 33 36")) ///
				bar (2 ,fc("241 160 40") lc("241 160 40")) /// 
				bar (3 ,fc("112 113 115") lc("112 113 115")) 
				
		gr export exp_pays_score_test_`x'.png, replace
		putdocx paragraph, halign(center) 
		putdocx image exp_pays_score_test_`x'.png, height (10 cm)
		
		preserve
		keep if id_plateforme==`x'
		putdocx paragraph
		putdocx text ("`=exp_pays_text[_n]'"), linebreak
		restore
		
		putdocx pagebreak
		putdocx paragraph,  font("Arial", 12)
		putdocx text ("Section 4: La perfomance générale de l'entreprise"), bold

		graph hbar productivity_2023 avg_productivity_2023_diag sectoral_productivity_2023_diag if id_plateforme==`x', blabel(total, format(%9.0fc)) ///
				title ("Productivité de l'entreprise") ///
				subtitle ("Chiffre d'affaires total sur le nombre total de salariés à temps plein") ///
				ytitle("Productivité") legend (pos (inside) /// 
				lab(1 "Votre Score") lab(2 "Moyenne totale") lab(3 "Moyenne dans votre secteur")) ///
				bar (1 ,fc("208 33 36") lc("208 33 36")) ///
				bar (2 ,fc("241 160 40") lc("241 160 40")) /// 
				bar (3 ,fc("112 113 115") lc("112 113 115")) 
				
		gr export productivity_score_test_`x'.png, replace
		putdocx paragraph, halign(center) 
		putdocx image productivity_score_test_`x'.png, height (10 cm)
		
		preserve
		keep if id_plateforme==`x'
		putdocx paragraph
		putdocx text ("`=productivity_2023_text[_n]'"), linebreak
		
		
		putdocx paragraph
		putdocx text ("Nous espérons que ces scores vous permettrons de vous situer parmi les entreprises dans votre secteur et en global."), linebreak 
		putdocx paragraph
		putdocx text ("Cordialement,"), linebreak 
		putdocx paragraph
		putdocx text ("Equipe PEMA"), linebreak bold

		//local name_file id_plateforme[`x']
		//display `name_file'
		putdocx save diagnostic_`x'.docx, replace

		restore
	}
}


set rmsg off
