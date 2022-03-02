***********************************************************************
* 			registration progress, eligibility, firm characteristics
***********************************************************************
*																	   
*	PURPOSE: 		check whether string answer to open questions are 														 
*					logical
*	OUTLINE:														  
*	1)				progress		  		  			
*	2)  			eligibility					 
*	3)  			characteristics							  
*																	  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta & regis_checks_survey_progress.do 	  
*	Creates:  regis_inter.dta			  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
	* import file
use "${regis_intermediate}/regis_inter", clear

	* set directory to checks folder
cd "$regis_progress"

	* create pdf document
putpdf begin 
putpdf paragraph

putpdf text ("Consortia: registration progress, elibility, firm characteristics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak

***********************************************************************
* 	PART 2:  Registration progress		  			
***********************************************************************
putpdf paragraph, halign(center) 
putpdf text ("Consortia: registration progress"), bold linebreak
putpdf paragraph, halign(center) 

{
	* total number of firms registered
graph bar (count) id_plateforme, blabel(total) ///
	title("Number of registered firms") note("Date: `c(current_date)'") ///
	ytitle("nombre d'enregistrement")
graph export responserate.png, replace
putpdf paragraph, halign(center)
putpdf image responserate.png
putpdf pagebreak


	* nombre d'enregistremnet par jour 
/*
gen datestring = string(dateinscription, "%td")
labmask dateinscription, values(datestring)
graph bar (count), over(dateinscription, label(angle(60) labsize(vsmall))) ///
	blabel(bar) ///
	ytitle("nombre d'enregistrement") ///
	xline(22586,  lpat(dash) lcolor(red)) ///
	addlabel addlabopts(mlabposition(12))
*/
	
format %-td dateinscription 
	graph twoway histogram dateinscription if dateinscription != ., frequency width(1) ///
			tlabel(20dec2021(1)03feb2022, angle(60) labsize(vsmall)) ///
			ytitle("nombre d'enregistrement") ///
			title("{bf:Campagne de communication: Enregistrement par jour}")
			*subtitle("{it: Envoie des emails en rouge}")
			*tline(22586 22592 22600 22609 22613, lcolor(red) lpattern(dash)) 
	gr export enregistrement_par_jour.png, replace
	putpdf paragraph, halign(center) 
	putpdf image enregistrement_par_jour.png
	putpdf pagebreak
		
	
	* communication channels
graph bar (count), over(moyen_com, sort(1) lab(labsize(tiny))) blabel(total) ///
	title("Enregistrement selon les moyens de communication") ///
	ytitle("nombre d'enregistrement") 
graph export moyen_com.png, replace 
putpdf paragraph, halign(center) 
putpdf image moyen_com.png
putpdf pagebreak

	* taille des entreprises selon chaines de com
graph box rg_fte, over(moyen_com, sort(1) lab(labsize(tiny))) blabel(total) ///
	title("Nombre des employés des entreprises selon moyen de communication") ///
	ytitle("Nombre des employés")

}

***********************************************************************
* 	PART 3:  Eligibility		  			
***********************************************************************
putpdf paragraph, halign(center) 
putpdf text ("Consortia: eligibility"), bold linebreak


	* distribution of ca and ca export 2018, 2019, 2020
set graphics on
histogram ca_mean if ca_mean < 666666 & ca_mean > 0, frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020") ///
	ytitle("Nombre d'entreprises") ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	xlabel(0 1 2 3 4 5 10 20 30 40 50 60 70 80, labsize(tiny) format(%9.0fc)) ///
	bin(80) ///
	xline(1.5) ///
	note("La ligne réprésentent le minimum selon les critères d'éligibilité (150.000 Dinar).", size(vsmall)) ///
	name(ca_mean, replace)
gr export ca_mean.png, replace
putpdf paragraph, halign(center) 
putpdf image ca_mean.png
putpdf pagebreak

histogram ca_mean if ca_mean < 15 & ca_mean > 0, frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020") ///
	ytitle("Nombre d'entreprises") ///
	xlabel(0 0.5 1 1.5 2 5 10 15, labsize(tiny) format(%9.1fc)) ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	bin(80) ///
	xline(1.5) ///
	note("La ligne réprésentent le minimum selon les critères d'éligibilité (150.000 Dinar).", size(vsmall)) ///
	name(ca_mean, replace)
gr export ca_mean_zoomin.png, replace
putpdf paragraph, halign(center) 
putpdf image ca_mean_zoomin.png
putpdf pagebreak


histogram ca_mean if ca_mean < 1.5 & ca_mean > 0, frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020") ///
	ytitle("Nombre d'entreprises") ///
	xlabel(0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5, labsize(tiny) format(%9.1fc)) ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	bin(80) ///
	note("Le minimum selon les critères d'éligibilité (150.000 Dinar).", size(vsmall)) ///
	name(ca_mean, replace)
gr export ca_mean_zoomin2.png, replace
putpdf paragraph, halign(center) 
putpdf image ca_mean_zoomin2.png
putpdf pagebreak


	/*
histogram ca_expmean < 666666, frequency addl ///
	title("Chiffre d'affaires export moyennes 2018-2020") ///
	
	ytitle("Nombre d'entreprises") ///
	xlabel(0 1 2 3 4 5 10 20 30 40 50, labsize(tiny) format(%9.0fc)) ///
	bin(50) ///
	xline(0.15) ///
	note("La ligne réprésentent le minimum selon les critères d'éligibilité (15.000 Dinar).", size(vsmall)) ///
	name(exp_ca, replace)
gr export ca_exp_mean.png, replace
putpdf paragraph, halign(center) 
putpdf image ca_exp_mean.png
putpdf pagebreak
*/

	* histogram for lower values of average CA
			* CA 2019
hist ca_2019 if ca_2019 < 2, w(0.1) frequency addl ///
	note("La ligne réprésentent le minimum selon les critères d'éligibilité (150.000 Dinar).", size(vsmall)) ///
	xline(1.5) xlabel(0(0.1)2)
			* CA moyenne trois années
hist ca_mean if ca_mean < 2, w(0.1) frequency addl ///
	xline(1.5) xlabel(0(0.1)2)

	* identifiant unique correct (oui ou non)
graph bar (count), over(id_admin_correct) blabel(total) ///
	title("Identifiant unique/matricule fiscal format correct") ///
	ytitle("nombre d'enregistrement")
graph export identifiant_correct.png, replace
putpdf paragraph, halign(center) 
putpdf image identifiant_correct.png
putpdf pagebreak
	
	* onshore vs. offshore
graph bar (count), over(rg_resident) blabel(total) ///
	title("Entreprises résidantes vs. non-résidantes") ///
	ytitle("nombre d'enregistrement")
graph export resident.png, replace
putpdf paragraph, halign(center) 
putpdf image resident.png
putpdf pagebreak
	
* Legal status
graph bar (count), over(rg_legalstatus) blabel(total) ///
	title("Statut juridique des entreprises") ///
	ytitle("nombre d'enregistrement")
graph export legalstatus.png, replace
putpdf paragraph, halign(center) 
putpdf image legalstatus.png
putpdf pagebreak

	* nombre des employés
histogram rg_fte, frequency addl ///
	title("Nombre des employés") ///
	xlabel(0(20)600,  labsize(tiny) format(%20.0fc)) ///
	bin(30) ///
	xline(6) xline(200) ///
	note("Les deux lignes réprésentent le min. et max. selon les critères d'éligibilité.", size(vsmall)) ///
	name(fte_full, replace)
	
histogram rg_fte if rg_fte <= 200, frequency addl ///
	title("Nombre des employés") ///
	subtitle("Entreprises ayantes <= 100 employés") ///
	xlabel(0(5)100,  labsize(tiny) format(%20.0fc)) ///
	bin(30) ///
	xline(6) ///
	note("La ligne réprésentent le minimum selon les critères d'éligibilité.", size(vsmall)) ///
	name(fte_100, replace)
	
gr combine fte_full fte_100
graph export fte.png, replace
putpdf paragraph, halign(center) 
putpdf image fte.png
putpdf pagebreak

histogram rg_fte if rg_fte <= 30, frequency addl ///
	title("Nombre des employés") ///
	subtitle("Entreprises ayantes <= 30 employés") ///
	xlabel(0(1)30,  labsize(tiny) format(%20.0fc)) ///
	bin(30) ///
	xline(6) ///
	note("La ligne réprésentent le minimum selon les critères d'éligibilité.", size(vsmall)) ///
	name(fte_30, replace)
graph export fte_zoom.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_zoom.png
putpdf pagebreak
	
	* export 
		* produit exportable = rg_produitexp
		* intention d'exporter = rg_intention
		* opération d'export = rg_oper_exp
local exportquestions "rg_produitexp rg_intention rg_oper_exp rg_expstatus"
foreach x of local exportquestions {
quietly graph bar (count), over(`x') blabel(total) ///
	ytitle("nombre d'enregistrement") name(`x', replace)
}
gr combine `exportquestions', ///
	title("{bf:Questions export}") ///
	subtitle("{it: Produit exportable (haute gauche), Intention d'exporter (haute droite), Operation d'export (bas gauche) et Régime export (bas droite)}", size(vsmall))
gr export export.png, replace
putpdf paragraph, halign(center) 
putpdf image export.png
putpdf pagebreak

	* age
stripplot age, jitter(4) vertical yline(2, lcolor(red)) ///
	ytitle("Age de l'entreprise") ///
	name(age_strip, replace)
histogram age if age >= 0, frequency addl ///
	ytitle("Age de l'entreprise") ///
	xlabel(0(2)80,  labsize(tiny) format(%20.0fc)) ///
	bin(40) ///
	xline(2, lcolor(red)) ///
	color(%30) ///
	name(age_hist, replace)	
gr combine age_strip age_hist, title("Age des entreprises") ///
	note("La ligne rouge répresente la valeur minimale pour être éligible.", size(vsmall))
graph export age.png, replace 
putpdf paragraph, halign(center) 
putpdf image age.png
putpdf pagebreak

	* online presence
graph bar (count), over(presence_enligne) blabel(total) ///
	title("Présence enligne") ///
	ytitle("nombre d'enregistrement")
graph export presence_enligne.png, replace
putpdf paragraph, halign(center) 
putpdf image presence_enligne.png
putpdf pagebreak
	
	* eligibility
		* including "operation d'export"
set graphics on
graph bar (count), over(eligible) blabel(total) ///
	title("Entreprises actuellement eligibles") ///
	subtitle("Opération d'export, CA et CA export") ///
	ytitle("nombre d'enregistrement") ///
	name(eligibles, replace) ///
	note("Chaque entreprise est éligible qui a fourni un matricul fiscal correct, CA moyenne 2018-2020 > 150 et 15 mille exp," "a >= 6 & < 200 employés, une produit exportable, l'intention d'exporter, " ">= 1 opération d'export, existe pour >= 2 ans et est résidente tunisienne.", size(vsmall) color(red))
gr export eligible.png, replace

/*graph bar (count), over(eligible_alt_sans_matricule) blabel(total) ///
	title("Entreprises actuellement eligibles") ///
	subtitle("Reduced eligibility criteria") ///
	ytitle("nombre d'enregistrement") ///
	name(eligibles_alt, replace) ///
	note("Chaque entreprise est éligible qui CA moyenne 2018-2020 >= 10 mille, a >= 4 & < 200 employés," "une produit exportable, l'intention d'exporter, et existe pour >= 1 ans et est résidente tunisienne.", size(vsmall) color(red))
gr export eligible_alt.png, replace*/

graph bar (count), over(eligible) blabel(total) ///
	title("Entreprises eligibles") ///
	subtitle("Final eligibility criteria") ///
	ytitle("nombre d'enregistrement") ///
	name(eligible_final, replace) ///
	note("Chaque entreprise est éligible lorsqu'elle a une produit exportable, l'intention d'exporter, et est résidente tunisienne.", size(vsmall) color(red))
gr export eligible_final.png, replace

set graphics off


		* just "intention d'export"
/*graph bar (count), over(eligible_intention) blabel(total) ///
	title("Entreprises actuellement éligibles") ///
	subtitle("Seulement intention d'export") ///
	ytitle("nombre d'enregistrement") ///
	name(eligible_intention, replace)
gr combine eligibles eligible_intention, title("{bf:Eligibilité des entreprises}")
graph export eligibles.png, replace
putpdf paragraph, halign(center) 
putpdf image eligibles.png
putpdf pagebreak */
		
		

/*	* eligibility online presence
graph bar (count), over(eligible) blabel(total) ///
	title("Entreprises actuellement eligibles") ///
	ytitle("nombre d'enregistrement") ///
	name(eligibles, replace) ///
	note(`"Chaque entreprise est éligible qui a fourni un matricul fiscal correct, a >= 6 & < 200 employés, une produit exportable, "' `"l'intention d'exporter, >= 1 opération d'export, existe pour >= 2 ans et est résidente tunisienne."', size(vsmall) color(red))
graph bar (count), over(eligible_presence_enligne) blabel(total) ///
	title("Entreprises potentiellement éligibles") ///
	ytitle("nombre d'enregistrement") ///
	name(eligible_enligne, replace)
gr combine eligibles eligible_enligne, title("{bf:Eligibilité des entreprises}")
graph export eligibles_enligne.png, replace
putpdf paragraph, halign(center) 
putpdf image eligibles_enligne.png
putpdf pagebreak
*/

***********************************************************************
* 	PART 4:  Characteristics
***********************************************************************
	* create a heading for the section in the pdf
putpdf paragraph, halign(center) 
putpdf text ("Consortia d'export PME femmes: firm characteristics"), bold linebreak

	* secteurs
/*
graph hbar (count), over(sector, sort(1)) blabel(total) ///
	title("Sector - Toutes les entreprises") ///
	ytitle("nombre d'entreprises") ///
	name(sector_tous, replace)
graph hbar (count) if eligible == 1, over(sector, sort(1)) blabel(total) ///
	title("Sector - Entreprises eligibles") ///
	ytitle("nombre d'entreprises") ///
	name(sector_eligible, replace)
*/

set graphics on
		* poles d'activité

graph hbar (count), over(subsector_corrige, sort(1) label(labsize(tiny) format(%-80s))) blabel(total, size(tiny))  ///
	title("Pole d'activité - Toutes les entreprises") ///
	ytitle("nombre d'entreprises") ///
	name(subsector_tous, replace)
gr export subsector_tous.png, replace
graph hbar (count) if eligible == 1, over(subsector_corrige, sort(1) label(labsize(tiny))) blabel(total, size(tiny))  ///
	title("Pôle d'activité - entreprises éligibles") ///
	subtitle("Reduced eligibility criteria") ///
	ytitle("nombre d'entreprises") ///
	name(subsector_eligible_alt, replace)
gr export subsector_eligible_alt.png, replace
graph combine subsector_tous subsector_eligible_alt, title("{bf: Distribution selon pôle d'activité}")
graph export poles.png, replace 
putpdf paragraph, halign(center) 
putpdf image poles.png
putpdf pagebreak

		* categories d'autres
set graphics on
graph hbar (count), over(autres, sort(1) label(labsize(tiny))) blabel(total, size(tiny)) ///
	title("Pole d'activité - catégorie autres") ///
	ytitle("nombre d'entreprises") ///
	name(autres, replace)
graph export sector_autres.png, replace 
putpdf paragraph, halign(center) 
putpdf image sector_autres.png
putpdf pagebreak	
set graphics off
	
	* gender
graph bar (count), over(rg_gender_rep) blabel(total) ///
	title("Genre répresentant(e) entreprise") subtitle("Toutes les PME enregistrées") ///
	ytitle("nombre d'enregistrement") ///
	name(gender_rep_tot, replace)
graph bar (count), over(rg_gender_rep) over(eligible) blabel(total, format(%-9.0fc)) ///
	title("Genre répresentant(e)") subtitle("Selon statut d'éligibilité") ///
	ytitle("pourcentage des entreprises") ///
	name(gender_rep_eligible, replace)
graph bar (count), over(rg_gender_pdg) blabel(total) ///
	title("Genre PDG entreprise") subtitle("Toutes les PME enregistrées") ///
	ytitle("nombre d'enregistrement") ///
	name(gender_ceo_tot, replace)
graph bar (count), over(rg_gender_pdg) over(eligible) blabel(total, format(%-9.0fc)) ///
	title("Gender of firm CEO") subtitle("Selon statut d'éligibilité") ///
	ytitle("pourcentage des entreprises") ///
	name(gender_ceo_eligible, replace)
gr combine gender_rep_tot gender_rep_eligible gender_ceo_tot gender_ceo_eligible, title("{bf:Genre des réprésentantes et des PDG}")
graph export gender.png, replace 
putpdf paragraph, halign(center) 
putpdf image gender.png
putpdf pagebreak
/*
	* distribution of firms by gender and subsector
graph hbar (count), over(subsector, sort(1) label(labsize(tiny))) over(rg_gender_rep) blabel(total, size(tiny)) ///
	title("Pôle d'activité - Toutes les PME enregistrées") ///
	ytitle("nombre d'entreprises") ///
	name(gender_ssector_tot, replace)
graph hbar (count) if eligible == 1, over(subsector, sort(1) label(labsize(tiny))) over(rg_gender_rep) blabel(total, size(tiny)) ///
	title("Pôle d'activité - PME éligibles") ///
	ytitle("nombre d'entreprises") ///
	name(gender_ssector_eligible, replace)
gr combine gender_ssector_tot gender_ssector_eligible, title("{bf:Genre des réprésentantes selon pôle d'activité}")
graph export gender_pole.png, width(1500) height(1500) replace
putpdf paragraph, halign(center) 
putpdf image gender_pole.png
putpdf pagebreak
*/
	* position du répresentant --> hbar
	
	* répresentation en ligne: ont un site web ou pas; ont un profil media ou pas
		* bar chart avec qutre bars et une légende; over(rg_siteweb) over(rg_media)
		
	* statut legal
	
	* nombre employés féminins rélatif à employés masculins
*graph bar rg_fte rg_fte_femmes
	
	* 

	
***********************************************************************
* 	PART 5:  Alternative eligibility
***********************************************************************
/*
putpdf paragraph, halign(center) 
putpdf text ("Eligibilité sous contraintes lachés"), bold linebreak

	* alternative eligibility
graph bar (count), over(eligible) blabel(total) ///
	title("Entreprises actuellement eligibles") ///
	ytitle("nombre d'enregistrement") ///
	name(eligibles, replace) ///
	note(`"Chaque entreprise est éligible qui a fourni un matricul fiscal correct, a >= 6 & < 200 employés, une produit exportable, "' `"l'intention d'exporter, >= 1 opération d'export, existe pour >= 2 ans et est résidente tunisienne."', size(vsmall) color(red))
graph bar (count), over(eligible_alternative) blabel(total) ///
	title("Entreprises éligibles sans opération d'export") ///
	ytitle("nombre d'enregistrement") ///
	note(`"Chaque entreprise est éligible qui a fourni un matricul fiscal correct, a >= 6 & < 200 employés, une produit exportable, "' `"l'intention d'exporter, existe pour >= 2 ans et est résidente tunisienne."', size(vsmall) color(green)) ///
	name(eligibles_alt, replace)
gr combine eligibles eligibles_alt, title("{bf:Eligibilité des entreprises sans opération d'export}")
graph export eligibles_alt.png, replace 
putpdf paragraph, halign(center) 
putpdf image eligibles_alt.png
putpdf pagebreak

	* alternative eligibility by sector and gender
graph hbar (count) if eligible == 1, over(subsector, sort(1) label(labsize(tiny))) over(rg_gender_rep) blabel(total, size(tiny)) ///
	title("Critères d'éligibilité actuelle") ///
	ytitle("nombre d'entreprises") ///
	name(gender_ssector_eligible, replace)
graph hbar (count) if eligible_alternative == 1, over(subsector, sort(1) label(labsize(tiny))) over(rg_gender_rep) blabel(total, size(tiny)) ///
	title("Critères d'éligibilités alternatives") ///
	ytitle("nombre d'entreprises") ///
	name(gender_ssector_eligible_alt, replace)
gr combine gender_ssector_eligible gender_ssector_eligible_alt, title("{bf:Eligibilité des entreprises sans opération d'export}")
graph export gender_sector_eligible_alt.png, replace
putpdf paragraph, halign(center) 
putpdf image gender_sector_eligible_alt.png

*/
	
***********************************************************************
* 	PART 2:  save pdf
***********************************************************************
	* change directory to progress folder
cd "$regis_progress"
	* pdf
putpdf save "consortium-progress-eligibility-characteristics", replace


***********************************************************************
* 	PART 3:  set environment for descriptive statistics of eligible firms
***********************************************************************
	* set directory to checks folder
cd "$regis_progress"

	* create pdf document
putpdf begin 
putpdf paragraph

putpdf text ("Consortia descriptive statistics of only eligible firms"), bold linebreak
putpdf text ("Eligible --> Tunisian residant, female CEO, intention to export & exportable product"), bold linebreak
putpdf text ("Date: `c(current_date)'"), bold linebreak

* number of eligble vs. ineligible firms
set graphics on
graph bar (count), over(eligible) blabel(total) ///
	title("Entreprises actuellement eligibles") ///
	ytitle("nombre d'enregistrement") ///
	name(eligible_final, replace) ///
	note("Chaque entreprise est éligible qui est dans un des 4 pôles, " "a l'intention d'exporter et un produit exportable, a une femme PDG et est résidente tunisienne.", size(vsmall) color(red))
graph export eligible_final.png, replace
putpdf paragraph, halign(center)
putpdf image eligible_final.png
putpdf pagebreak

	* restrict sample to only firms in 4 sectors eligible (femme pdg, residante, produit et intention export)
keep if eligible == 1

* number of firms by pole
graph hbar (count), over(pole, sort(1) label(labsize(tiny) format(%-80s))) blabel(total, size(tiny))  ///
	title("4 Poles d'activité") ///
	ytitle("nombre d'entreprises") ///
	name(pole, replace)
gr export pole.png, replace
putpdf paragraph, halign(center)
putpdf image pole.png
putpdf pagebreak


* sample descriptive statistics
	* number of employees
histogram rg_fte, frequency addl ///
	title("Nombre des employés") ///
	ytitle("nombre d'entreprises") ///
	xlabel(0(10)350,  labsize(tiny) format(%20.0fc)) ///
	bin(35) ///
	name(fte_eligible, replace)
	
histogram rg_fte if rg_fte <= 30, frequency addl ///
	title("Nombre des employés") ///
	ytitle("nombre d'entreprises") ///
	subtitle("Entreprises ayantes <= 30 employés") ///
	xlabel(0(1)30,  labsize(tiny) format(%20.0fc)) ///
	bin(30) ///
	name(fte_30_eligible, replace)
gr combine fte_eligible fte_30_eligible, name(fte_eligible, replace)
graph export fte_eligible.png, replace
putpdf paragraph, halign(center) 
putpdf image fte_eligible.png
putpdf pagebreak


	* CA, CA exp
histogram ca_mean if ca_mean < 666666 & ca_mean > 0, frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020") ///
	ytitle("Nombre d'entreprises") ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	xlabel(0 100 500 1000, labsize(tiny) format(%9.0fc)) ///
	bin(20) ///
	name(ca_mean, replace)
gr export ca_mean.png, replace
putpdf paragraph, halign(center) 
putpdf image ca_mean.png
putpdf pagebreak

histogram ca_mean if ca_mean < 15 & ca_mean > 0, frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020") ///
	ytitle("Nombre d'entreprises") ///
	xlabel(0 0.5 1 1.5 2 5 10 15, labsize(tiny) format(%9.1fc)) ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	bin(80) ///
	name(ca_mean, replace)
gr export ca_mean_zoomin.png, replace
putpdf paragraph, halign(center) 
putpdf image ca_mean_zoomin.png
putpdf pagebreak


histogram ca_mean if ca_mean < 1.5 & ca_mean > 0, frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020") ///
	ytitle("Nombre d'entreprises") ///
	xlabel(0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5, labsize(tiny) format(%9.1fc)) ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	bin(80) ///
	name(ca_mean, replace)
gr export ca_mean_zoomin2.png, replace
putpdf paragraph, halign(center) 
putpdf image ca_mean_zoomin2.png
putpdf pagebreak
	
	* capital social
histogram rg_capital if rg_capital < 10000000, frequency addl ///
	title("Capital Social") ///
	ytitle("nombre d'entreprises") ///
	xlabel(10000 100000 5000000 1000000, labsize(tiny) format(%9.1fc)) ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	bin(20) ///
	name(capital, replace)
gr export capital.png, replace
putpdf paragraph, halign(center) 
putpdf image capital.png
putpdf pagebreak
	
	
	* age
stripplot age, jitter(4) vertical yline(2, lcolor(red)) ///
	ytitle("Age de l'entreprise") ///
	name(age_strip, replace)
histogram age if age >= 0, frequency addl ///
	ytitle("Age de l'entreprise") ///
	xlabel(0(1)60,  labsize(tiny) format(%20.0fc)) ///
	bin(60) ///
	color(%30) ///
	name(age_hist, replace)	
gr combine age_strip age_hist, title("Age des entreprises")
graph export age.png, replace 
putpdf paragraph, halign(center) 
putpdf image age.png
putpdf pagebreak


	* legal status
graph bar (count), over(rg_legalstatus) blabel(total) ///
	title("Statut juridique des entreprises") ///
	ytitle("nombre d'enregistrement")
graph export legalstatus.png, replace
putpdf paragraph, halign(center) 
putpdf image legalstatus.png
putpdf pagebreak


local pole1 "agro-alimentaire"
local pole2 "artisanat et cosmétique"
local pole3 "service"
local pole4 "TIC"

* characteristics by pole 
forvalues x = 1(1)4 {
		* FTE
	histogram rg_fte if pole == `x', frequency addl ///
	title("Nombre des employés - `pole`x''") ///
	ytitle("nombre d'entreprises") ///
	xlabel(0(10)350,  labsize(tiny) format(%20.0fc)) ///
	bin(35) ///
	name(fte, replace)

		* CA, CA export
	histogram ca_mean if ca_mean < 666666 & ca_mean > 0 & pole == `x', frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020  - `pole`x''") ///
	ytitle("Nombre d'entreprises") ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	xlabel(0 100 500 1000, labsize(tiny) format(%9.0fc)) ///
	bin(20) ///
	name(ca_mean, replace)	
	gr export ca_mean.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ca_mean.png
	putpdf pagebreak

	histogram ca_mean if ca_mean < 15 & ca_mean > 0 & pole == `x' , frequency addl ///
		title("Chiffre d'affaires moyennes 2018-2020  - `pole`x''") ///
		ytitle("Nombre d'entreprises") ///
		xlabel(0 0.5 1 1.5 2 5 10 15, labsize(tiny) format(%9.1fc)) ///
		xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
		bin(80) ///
		name(ca_mean, replace)
	gr export ca_mean_zoomin.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ca_mean_zoomin.png
	putpdf pagebreak

	histogram ca_mean if ca_mean < 1.5 & ca_mean > 0 & pole == `x', frequency addl ///
		title("Chiffre d'affaires moyennes 2018-2020  - `pole`x''") ///
		ytitle("Nombre d'entreprises") ///
		xlabel(0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1 1.1 1.2 1.3 1.4 1.5, labsize(tiny) format(%9.1fc)) ///
		xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
		bin(80) ///
		name(ca_mean, replace)
	gr export ca_mean_zoomin2.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ca_mean_zoomin2.png
	putpdf pagebreak
		
		* capital social
	histogram rg_capital if rg_capital < 10000000 & pole == `x', frequency addl ///
		title("Capital Social  - `pole`x''") ///
		ytitle("nombre d'entreprises") ///
		xlabel(10000 100000 5000000 1000000, labsize(tiny) format(%9.1fc)) ///
		xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
		bin(20) ///
		name(capital, replace)
	gr export capital.png, replace
	putpdf paragraph, halign(center) 
	putpdf image capital.png
	putpdf pagebreak
		
		
		* age
	stripplot age if pole == `x', jitter(4) vertical yline(2, lcolor(red)) ///
		ytitle("Age de l'entreprise") ///
		name(age_strip, replace)
	histogram age if age >= 0 & pole == `x', frequency addl ///
		ytitle("Age de l'entreprise") ///
		xlabel(0(1)60,  labsize(tiny) format(%20.0fc)) ///
		bin(60) ///
		color(%30) ///
		name(age_hist, replace)	
	gr combine age_strip age_hist, title("Age des entreprises - `pole`x''")
	graph export age.png, replace 
	putpdf paragraph, halign(center) 
	putpdf image age.png
	putpdf pagebreak

		* legal status
	graph bar (count) if pole == `x', over(rg_legalstatus) blabel(total) ///
		title("Statut juridique des entreprises - `pole`x''") ///
		ytitle("nombre d'enregistrement")
	graph export legalstatus.png, replace
	putpdf paragraph, halign(center) 
	putpdf image legalstatus.png
	putpdf pagebreak
	

}

***********************************************************************
* 	PART 4:  save pdf
***********************************************************************
set graphics off
	* change directory to progress folder
cd "$regis_progress"
	* pdf
putpdf save "consortium-pme-eligible-descriptives", replace



