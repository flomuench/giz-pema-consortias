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

	* create word document
putpdf begin 
putpdf paragraph

putpdf text ("E-commerce training: registration progress, elibility, firm characteristics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak


***********************************************************************
* 	PART 2:  Registration progress		  			
***********************************************************************
putpdf paragraph, halign(center) 
putpdf text ("E-commerce training: registration progress")

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
graph twoway histogram dateinscription, frequency width(1) ///
		tlabel(02nov2021(1)07dec2021, angle(60) labsize(vsmall)) ///
		ytitle("nombre d'enregistrement") ///
		title("{bf:Campagne de communication: Enregistrement par jour}") ///
		subtitle("{it: Envoie des emails en rouge}") ///
		tline(22586 22592 22600 22609 22613, lcolor(red) lpattern(dash)) 
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
putpdf text ("E-commerce training: eligibility"), bold linebreak

{
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
	
	* nombre des employés
histogram rg_fte, frequency addl ///
	title("Nombre des employés") ///
	subtitle("Toutes les entreprises enregistrées") ///
	xlabel(0(20)600,  labsize(tiny) format(%20.0fc)) ///
	bin(30) ///
	xline(6) xline(200) ///
	note("Les deux lignes réprésentent le min. et max. selon les critères d'éligibilité.", size(vsmall)) ///
	name(fte_full, replace)
	
histogram rg_fte if rg_fte <= 200, frequency addl ///
	title("Nombre des employés") ///
	subtitle("Entreprises ayantes <= 200 employés") ///
	xlabel(0(5)200,  labsize(tiny) format(%20.0fc)) ///
	bin(30) ///
	xline(6) xline(200) ///
	note("Les deux lignes réprésentent le min. et max. selon les critères d'éligibilité.", size(vsmall)) ///
	name(fte_200, replace)
	
gr combine fte_full fte_200
graph export fte.png, replace
putpdf paragraph, halign(center) 
putpdf image fte.png
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
stripplot rg_age, jitter(4) vertical yline(2, lcolor(red)) ///
	ytitle("Age de l'entreprise") ///
	name(age_strip, replace)
histogram rg_age if rg_age >= 0, frequency addl ///
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
graph bar (count), over(eligible) blabel(total) ///
	title("Entreprises actuellement eligibles") ///
	ytitle("nombre d'enregistrement") ///
	name(eligibles, replace) ///
	note(`"Chaque entreprise est éligible qui a fourni un matricul fiscal correct, a >= 6 & < 200 employés, une produit exportable, "' `"l'intention d'exporter, >= 1 opération d'export, existe pour >= 2 ans et est résidente tunisienne."', size(vsmall) color(red))
graph bar (count), over(eligible_sans_matricule) blabel(total) ///
	title("Entreprises potentiellement éligibles") ///
	ytitle("nombre d'enregistrement") ///
	name(potentiellement_eligible, replace)
gr combine eligibles potentiellement_eligible, title("{bf:Eligibilité des entreprises}")
graph export eligibles.png, replace
putpdf paragraph, halign(center) 
putpdf image eligibles.png
putpdf pagebreak

	* eligibility online presence
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

}
***********************************************************************
* 	PART 4:  Characteristics
***********************************************************************
	* create a heading for the section in the pdf
putpdf paragraph, halign(center) 
putpdf text ("E-commerce training: firm characteristics"), bold linebreak

	* secteurs
graph hbar (count), over(sector, sort(1)) blabel(total) ///
	title("Sector - Toutes les entreprises") ///
	ytitle("nombre d'entreprises") ///
	name(sector_tous, replace)
graph hbar (count) if eligible == 1, over(sector, sort(1)) blabel(total) ///
	title("Sector - Entreprises eligibles") ///
	ytitle("nombre d'entreprises") ///
	name(sector_eligible, replace)
graph hbar (count), over(subsector, sort(1) label(labsize(tiny))) blabel(total, size(tiny)) ///
	title("Subsector - Toutes les entreprises") ///
	ytitle("nombre d'entreprises") ///
	name(subsector_tous, replace)
graph hbar (count) if eligible == 1, over(subsector, sort(1) label(labsize(tiny))) blabel(total, size(tiny)) ///
	title("Subsector - Toutes les entreprises") ///
	ytitle("nombre d'entreprises") ///
	name(subsector_eligible, replace)
gr combine sector_tous sector_eligible subsector_tous subsector_eligible , title("{bf: Distribution sectorielle}")
graph export sector.png, replace 
putpdf paragraph, halign(center) 
putpdf image sector.png
putpdf pagebreak
	
	* gender
graph bar (count), over(rg_gender_rep) blabel(total) ///
	title("Genre répresentant(e) entreprise") subtitle("Toutes les PME enregistrées") ///
	ytitle("nombre d'enregistrement") ///
	name(gender_rep_tot, replace)
graph bar (count), over(rg_gender_rep) over(eligible) blabel(total, format(%-9.0fc)) ///
	title("Gender of firm representative") subtitle("Selon statut d'éligibilité") ///
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

	* distribution of firms by gender and subsector
graph hbar (count), over(subsector, sort(1) label(labsize(tiny))) over(rg_gender_rep) blabel(total, size(tiny)) ///
	title("Subsector - Toutes les PME enregistrées") ///
	ytitle("nombre d'entreprises") ///
	name(gender_ssector_tot, replace)
graph hbar (count) if eligible == 1, over(subsector, sort(1) label(labsize(tiny))) over(rg_gender_rep) blabel(total, size(tiny)) ///
	title("Subsector - PME éligibles") ///
	ytitle("nombre d'entreprises") ///
	name(gender_ssector_eligible, replace)
gr combine gender_ssector_tot gender_ssector_eligible, title("{bf:Genre des réprésentantes selon secteur}")
graph export gender_sector.png, width(1500) height(1500) replace
putpdf paragraph, halign(center) 
putpdf image gender_sector.png
putpdf pagebreak
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
	
***********************************************************************
* 	PART 6:  save pdf
***********************************************************************
	* change directory to progress folder
cd "$regis_progress"
	* pdf
putpdf save "progress-eligibility-characteristics", replace

	* export excel with list of firms that we need to contact for them to correct
		* their matricule fiscal
cd "$regis_checks"
export excel potentially_eligible if eligible == 0 & eligible_sans_matricule == 1, firstrow(var) replace
