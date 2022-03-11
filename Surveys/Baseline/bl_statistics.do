***********************************************************************
* 			baseline progress, firm characteristics
***********************************************************************
*																	   
*	PURPOSE: 		Create statistics on firms
*	OUTLINE:														  
*	1)				progress		  		  			
*	2)  			eligibility					 
*	3)  			characteristics							  
*																	  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: bl_inter.dta 
*	Creates:  bl_inter.dta			  
*																	  
***********************************************************************
* 	PART 1:  set environment + create pdf file for export		  			
***********************************************************************
	* import file
use "${bl_intermediate}/bl_inter", clear

	* set directory to checks folder
cd "$bl_output"

	* create word document
putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortias: survey progress, firm characteristics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak


***********************************************************************
* 	PART 2:  Survey progress		  			
***********************************************************************
putpdf paragraph, halign(center) 
putpdf text ("consortias : baseline survey progress")

{
	* total number of firms that responded
graph bar (count) id_plateforme, blabel(total) ///
	title("Nombres des entreprises qui au moins ont commence à remplir") note("Date: `c(current_date)'") ///
	ytitle("Number of entries")
graph export responserate.png, replace
putpdf paragraph, halign(center)
putpdf image responserate.png
putpdf pagebreak

	
format %-td date 
graph twoway histogram date, frequency width(1) ///
		tlabel(04mar2022(1)01apr2022, angle(60) labsize(vsmall)) ///
		ytitle("responses") ///
		title("{bf:Baseline survey: number of responses}") 
gr export survey_response_byday.png, replace
putpdf paragraph, halign(center) 
putpdf image survey_response_byday.png
putpdf pagebreak
		
	
	* firms with complete entries
graph bar (count), over(miss) blabel(total) ///
	title("Nombre des entreprises avec reponses complète") 
gr export complete_responses.png, replace
putpdf paragraph, halign(center) 
putpdf image complete_responses.png
putpdf pagebreak
*/
	* firms with validated entries
graph bar (count),over(validation) blabel(total) ///
	title("Nombre des entreprises avec reponses validés")
gr export complete_responses.png, replace
putpdf paragraph, halign(center) 
putpdf image complete_responses.png
putpdf pagebreak

*Type of support desired by firms
gr hbar (sum) support1 - support6, blabel(total) legend (pos (6) label (1 "no support need") label(2 "virtual meetings") label(3 "Changer l’endroit de rencontre, par exemple d’une ville à une autre") label(4 "Creneau avant ou apres du travail") label(5 "garde d'enfance") label(6 "support pour transport et heberge")) ///
	title("Comment est-ce qu’on pourra vous faciliter la participation aux rencontres de consortium?")
gr export support.png, replace
putpdf paragraph, halign(center) 
putpdf image support.png
putpdf pagebreak

*Reasons why firms want to join the program
gr hbar (sum) att_adh1 - att_adh5, blabel(total) legend (pos (6) label (1 "Développer l’export ") label(2 "Accéder à des services d’accompagnement et de soutien à l'international") label(3 "Développer vos compétences en matière d’exportation") label (4 "Faire partie d’un réseau d’entreprise femmes pour apprendre des autres PDG femmes ") label(5 "Réduire les coûts d’exportation")) ///
	title("Pourquoi souhaitez-vous adhérer à ce programme ?")
gr export attents.png, replace
putpdf paragraph, halign(center) 
putpdf image attents.png
putpdf pagebreak


*Statistics with average time per survey
/*graph bar (mean) time_survey, blabel(total) ///
	title("Temps moyen pour remplir le sondage") 
gr export temps_moyen_sondage.png, replace
putpdf paragraph, halign(center) 
putpdf image temps_moyen_sondage.png
sum time_survey,d
putpdf paragraph
putpdf text ("Survey time statistics"), linebreak bold
putpdf text ("min. `: display %9.0g `r(min)'' minutes, max. `: display %9.0g `r(max)'' minutes & median `: display %9.0g `r(p50)'' minutes."), linebreak
putpdf pagebreak*/
}
*/

***********************************************************************
*** PART 3: Baseline descriptive statistics 		  			
***********************************************************************

*bar chart and boxplots of accounting variable by poles
graph bar ca_2021, over(pole)
gr export bar_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_ca2021.png
putpdf pagebreak

stripplot ca_2021 if ca_2021<ca_95p, over(pole) vertical
gr export strip_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_ca2021.png
putpdf pagebreak



*scatter plots between CA and CA_Exp


***********************************************************************
*** PART 4: Indices statistics	  			
***********************************************************************
*PLEASE ADAPT TO INDICES USED IN CONSORTIA and USE STRIPPLOTS & BARCHARTS RATHER THAN HIST


putpdf paragraph, halign(center) 
putpdf text ("consortias training: Z scores"), bold linebreak

	* Management practices Z-scores
	
hist mngtvars, ///
	title("Zscores of management practices questions") ///
	xtitle("Zscores")
graph export mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image mngtvars_zscores.png
putpdf pagebreak

graph mngtvars
gr export mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image mngtvars_zscores.png
putpdf pagebreak

stripplot mngtvars
gr export mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image mngtvars_zscores.png
putpdf pagebreak

	* Marketing practices Z-scores
	
hist markvars, ///
	title("Zscores of marketing practices questions") ///
	xtitle("Zscores")
graph export markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image markvars_zscores.png
putpdf pagebreak

graph markvars
gr export markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image markvars_zscores.png
putpdf pagebreak

stripplot markvars
gr export markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image markvars_zscores.png
putpdf pagebreak

	* Export management Z-scores
	
hist exportmngt, ///
	title("Zscores of export management questions") ///
	xtitle("Zscores")
graph export exportmngt_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportmngt_zscores.png
putpdf pagebreak

graph exportmngt
gr export exportmngt_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportmngt_zscores.png
putpdf pagebreak

stripplot exportmngt
gr export exportmngt_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportmngt_zscores.png
putpdf pagebreak

	* Export readiness Z-scores
	
hist exportprep, ///
	title("Zscores of export readiness questions") ///
	xtitle("Zscores")
graph export exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportprep_zscores.png
putpdf pagebreak

graph exportprep
gr export exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportprep_zscores.png
putpdf pagebreak

stripplot exportprep
gr export exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportprep_zscores.png
putpdf pagebreak

	* Combined export practices Z-scores
	
hist exportcombined, ///
	title("Zscores of combined export practices questions") ///
	xtitle("Zscores")
graph export exportcombined_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportcombined_zscores.png
putpdf pagebreak

graph exportcombined
gr export exportcombined_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportcombined_zscores.png
putpdf pagebreak

stripplot exportcombined
gr export exportcombined_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image exportcombined_zscores.png
putpdf pagebreak

	* For comparison, the 'raw' indices: 

	* Management practices Z-scores
	
hist raw_mngtvars, ///
	title("raw sum of all management practices scores") ///
	xtitle("Sum")
graph export raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_mngtvars.png
putpdf pagebreak

graph raw_mngtvars
gr export raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_mngtvars.png
putpdf pagebreak

stripplot raw_mngtvars
gr export raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_mngtvars.png
putpdf pagebreak

	* Marketing practices Z-scores
	
hist raw_markvars, ///
	title("Raw sum of all marketing practices questions") ///
	xtitle("Sum")
graph export raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_markvars.png
putpdf pagebreak

graph raw_markvars
gr export raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_markvars.png
putpdf pagebreak

stripplot raw_markvars
gr export raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_markvars.png
putpdf pagebreak

	* Export outcomes Z-scores

hist raw_exportmngt, ///
	title("Raw sum of all export management questions") ///
	xtitle("Sum")
graph export raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportmngt.png
putpdf pagebreak

graph raw_exportmngt
gr export raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportmngt.png
putpdf pagebreak

stripplot raw_exportmngt
gr export raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportmngt.png
putpdf pagebreak


	* Export readiness Z-scores
	
hist raw_exportprep, ///
	title("Raw sum of all export readiness questions") ///
	xtitle("Sum")
graph export raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportprep.png
putpdf pagebreak

graph raw_exportprep
gr export raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportprep.png
putpdf pagebreak

stripplot raw_exportprep
gr export raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportprep.png
putpdf pagebreak

	* Combined export practices Z-scores
	
hist raw_exportcombined, ///
	title("Raw sum of allcombined export practices questions") ///
	xtitle("Sum")
graph export raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportcombined.png
putpdf pagebreak

graph raw_exportcombined
gr export raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportcombined.png
putpdf pagebreak

stripplot raw_exportcombined
gr export raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportcombined.png
putpdf pagebreak

		
/***********************************************************************
* 	PART 4:  Firm characteristics
***********************************************************************
	* create a heading for the section in the pdf
putpdf paragraph, halign(center) 
putpdf text ("consortias training: firm characteristics"), bold linebreak

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

*/	
***********************************************************************
* 	PART 6:  save pdf
***********************************************************************
	* change directory to progress folder
cd "$bl_output"
	* pdf
putpdf save "baseline_statistics", replace
