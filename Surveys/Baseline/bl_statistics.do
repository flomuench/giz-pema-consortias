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
*use "${bl_intermediate}/bl_inter", clear

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
	* Share of firms that started the survey
count if survey_started==1
gen share= (`r(N)'/179)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("La part des entreprises qui au moins ont commence à remplir") note("Date: `c(current_date)'") ///
	ytitle("Number of entries")
graph export responserate.png, replace
putpdf paragraph, halign(center)
putpdf image responserate.png
putpdf pagebreak
drop share
	
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
count if survey_completed==1
gen share= (`r(N)'/179)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("La part des entreprises avec reponses complète") 
gr export complete_responses.png, replace
putpdf paragraph, halign(center) 
putpdf image complete_responses.png
putpdf pagebreak
drop share
*/
	* firms with validated entries
count if validation==1
gen share= (`r(N)'/179)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("La part des entreprises avec reponses validés")
gr export validated_responses.png, replace
putpdf paragraph, halign(center) 
putpdf image validated_responses.png
putpdf pagebreak
drop share

*Type of support desired by firms
gr hbar (sum) support1 - support6, blabel(total, format(%9.2fc)) legend (pos (6) label (1 "no support need") label(2 "virtual meetings") label(3 "Changer l’endroit de rencontre, par exemple d’une ville à une autre") label(4 "Creneau avant ou apres du travail") label(5 "garde d'enfance") label(6 "support pour transport et heberge")) ///
	title("Comment est-ce qu’on pourra vous faciliter la participation aux rencontres de consortium?")
gr export support.png, replace
putpdf paragraph, halign(center) 
putpdf image support.png
putpdf pagebreak

*Reasons why firms want to join the program
gr hbar (sum) att_adh1 - att_adh5, blabel(total, format(%9.2fc)) legend (pos (6) label (1 "Développer l’export ") label(2 "Accéder à des services d’accompagnement et de soutien à l'international") label(3 "Développer vos compétences en matière d’exportation") label (4 "Faire partie d’un réseau d’entreprise femmes pour apprendre des autres PDG femmes ") label(5 "Réduire les coûts d’exportation")) ///
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
* 	PART 3:  Statistics on numeric variables by pole 		  			
***********************************************************************
/*
putpdf paragraph, halign(center) 
putpdf text ("consortias : Statistics by pole")

forvalues x = 1(1)4 {

		* CA, CA export
	histogram ca_mean if ca_mean > 0 & pole == `x', frequency addl ///
	title("Chiffre d'affaires moyennes 2018-2020  - `pole`x''") ///
	ytitle("Nombre d'entreprises") ///
	xtitle("Chiffre d'affaires moyennes 2018-2020 (en unité de 100.000)") ///
	xlabel(, labsize(tiny) format(%9.0fc)) ///
	bin(20) ///
	name(ca_mean, replace)	
	gr export ca_mean.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ca_mean.png
	putpdf pagebreak

	histogram ca_mean if ca_mean < 150000 & ca_mean > 0 & pole == `x' , frequency addl ///
		title("Chiffre d'affaires moyennes 2018-2020  - `pole`x''") ///
		ytitle("Nombre d'entreprises") ///
		xlabel(, labsize(tiny) format(%9.1fc)) ///
		xtitle("Chiffre d'affaires moyennes 2018-2020") ///
		bin(80) ///
		name(ca_mean, replace)
	gr export ca_mean_zoomin.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ca_mean_zoomin.png
	putpdf pagebreak

	histogram ca_mean if ca_mean < 15000 & ca_mean > 0 & pole == `x', frequency addl ///
		title("Chiffre d'affaires moyennes 2018-2020  - `pole`x''") ///
		ytitle("Nombre d'entreprises") ///
		xlabel(, labsize(tiny) format(%9.1fc)) ///
		xtitle("Chiffre d'affaires moyennes 2018-2020") ///
		bin(80) ///
		name(ca_mean, replace)
	gr export ca_mean_zoomin2.png, replace
	putpdf paragraph, halign(center) 
	putpdf image ca_mean_zoomin2.png
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
*/
***********************************************************************
*** PART 3: Baseline descriptive statistics 		  			
***********************************************************************

*bar chart and boxplots of accounting variable by poles
     * variable ca_2021:
graph bar ca_2021 if ca_2021<ca_90p, over(pole, sort(1))
gr export bar_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_ca2021.png
putpdf pagebreak

stripplot ca_2021 if ca_2021<ca_90p, over(pole) vertical
gr export strip_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_ca2021.png
putpdf pagebreak

     * variable ca_exp_2021:
graph bar ca_exp_2021 if ca_exp_2021<ca_exp90p, over(pole, sort(1))
gr export bar_ca_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_ca_exp2021.png
putpdf pagebreak

stripplot ca_exp_2021 if ca_exp_2021<ca_exp90p, over(pole) vertical
gr export strip_ca_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_ca_exp2021.png
putpdf pagebreak

     * variable profit_2021:
	 
graph bar profit_2021 if profit_2021<profit_90p, over(pole, sort(1))
gr export bar_profit_2021.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_profit_2021.png
putpdf pagebreak

stripplot profit_2021 if profit_2021<profit_90p, over(pole) vertical
gr export strip_profit_2021.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_profit_2021.png
putpdf pagebreak


     * variable inno_rd:
	 
graph bar inno_rd if inno_rd<inno_rd_90p, over(pole, sort(1))
gr export bar_inno_rd.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_inno_rd.png
putpdf pagebreak

stripplot inno_rd if inno_rd<inno_rd_90p, over(pole) vertical
gr export strip_inno_rd.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_inno_rd.png
putpdf pagebreak

     * variable exprep_inv:
	 
graph bar exprep_inv if exprep_inv<exprep_inv_90p, over(pole, sort(1))
gr export bar_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_exprep_inv.png
putpdf pagebreak

stripplot exprep_inv if exprep_inv<exprep_inv_90p, over(pole) vertical
gr export strip_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_exprep_inv.png
putpdf pagebreak

*scatter plots between CA and CA_Exp
scatter ca_exp_2021 ca_2021 if ca_2021<ca_90p & ca_exp_2021<ca_exp90p, title("Proportion des bénéfices d'exportation par rapport au bénéfice total")
gr export scatter_ca.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_ca.png
putpdf pagebreak

*scatter plots between CA_Exp and exprep_inv
scatter ca_exp_2021 exprep_inv if ca_exp_2021<ca_exp90p & exprep_inv<exprep_inv_90p, title("Part de l'investissement dans la préparation des exportations par rapport au CA à l'exportation")
gr export scatter_exprep.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_exprep.png
putpdf pagebreak

*scatter plots between CA and inno_rd
scatter ca_2021 inno_rd if inno_rd<inno_rd_90p & ca_2021<ca_90p, title("Proportion des investissements dans l'innovation (R&D) par rapport au chiffre d'affaires")
gr export scatter_exprep.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_exprep.png
putpdf pagebreak

*scatter plots by pole
forvalues x = 1(1)4 {
		* between CA and CA_Exp
twoway scatter ca_2021 ca_exp_2021 if ca_2021<ca_90p & ca_exp_2021<ca_exp90p & pole == `x', title("Proportion de CA exp par rapport au CA- pole`x'")
gr export scatter_capole.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_capole.png
putpdf pagebreak
}

***********************************************************************
*** PART 4: Indices statistics	  			
***********************************************************************
*PLEASE ADAPT TO INDICES USED IN CONSORTIA and USE STRIPPLOTS & BARCHARTS RATHER THAN HIST


putpdf paragraph, halign(center) 
putpdf text ("consortias training: Z scores"), bold linebreak

	* Management practices Z-scores
	
hist mngtvars, title("Zscores of management practices questions") xtitle("Zscores")
graph export hist_mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_mngtvars_zscores.png
putpdf pagebreak

graph bar mngtvars, over(pole, sort(1))
gr export bar_mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_mngtvars_zscores.png
putpdf pagebreak

stripplot mngtvars, over(pole) vertical
gr export strip_mngtvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_mngtvars_zscores.png
putpdf pagebreak

	* Marketing practices Z-scores
	
hist markvars, title("Zscores of marketing practices questions") xtitle("Zscores")
graph export hist_markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_markvars_zscores.png
putpdf pagebreak

graph bar markvars, over(pole, sort(1))
gr export bar_markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_markvars_zscores.png
putpdf pagebreak

stripplot markvars, over(pole) vertical
gr export strip_markvars_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_markvars_zscores.png
putpdf pagebreak

	* Export management Z-scores
	
hist exportmngt, title("Zscores of export management questions") xtitle("Zscores")
graph export hist_exportmngt_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_exportmngt_zscores.png
putpdf pagebreak

graph bar exportmngt, over(pole, sort(1))
gr export bar_exportmngt_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_exportmngt_zscores.png
putpdf pagebreak

stripplot exportmngt, over(pole) vertical
gr export strip_exportmngt_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_exportmngt_zscores.png
putpdf pagebreak

	* Export readiness Z-scores
	
hist exportprep, title("Zscores of export readiness questions") xtitle("Zscores")
graph export hist_exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_exportprep_zscores.png
putpdf pagebreak

graph bar exportprep, over(pole, sort(1))
gr export bar_exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_exportprep_zscores.png
putpdf pagebreak

stripplot exportprep, over(pole) vertical
gr export strip_exportprep_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_exportprep_zscores.png
putpdf pagebreak

	* Combined export practices Z-scores
	
hist exportcombined, title("Zscores of combined export practices questions") xtitle("Zscores")
graph export hist_exportcombined_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_exportcombined_zscores.png
putpdf pagebreak

graph bar exportcombined, over(pole, sort(1))
gr export bar_exportcombined_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_exportcombined_zscores.png
putpdf pagebreak

stripplot exportcombined, over(pole) vertical
gr export strip_exportcombined_zscores.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_exportcombined_zscores.png
putpdf pagebreak

	* For comparison, the 'raw' indices: 

	* Management practices Z-scores
	
hist raw_mngtvars, title("raw sum of all management practices scores") xtitle("Sum")
graph export hist_raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image hist_raw_mngtvars.png
putpdf pagebreak

graph bar raw_mngtvars, over(pole, sort(1))
gr export bar_raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_mngtvars.png
putpdf pagebreak

stripplot raw_mngtvars, over(pole) vertical
gr export strip_raw_mngtvars.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_mngtvars.png
putpdf pagebreak

	* Marketing practices Z-scores
	
hist raw_markvars, title("Raw sum of all marketing practices questions") xtitle("Sum")
graph export raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_markvars.png
putpdf pagebreak

graph bar raw_markvars, over(pole, sort(1))
gr export bar_raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_markvars.png
putpdf pagebreak

stripplot raw_markvars, over(pole) vertical
gr export strip_raw_markvars.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_markvars.png
putpdf pagebreak

	* Export outcomes Z-scores

hist raw_exportmngt, title("Raw sum of all export management questions") xtitle("Sum")
graph export raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportmngt.png
putpdf pagebreak

graph bar raw_exportmngt, over(pole, sort(1))
gr export bar_raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_exportmngt.png
putpdf pagebreak

stripplot raw_exportmngt, over(pole) vertical
gr export strip_raw_exportmngt.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_exportmngt.png
putpdf pagebreak


	* Export readiness Z-scores
	
hist raw_exportprep, title("Raw sum of all export readiness questions") xtitle("Sum")
graph export raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportprep.png
putpdf pagebreak

graph bar raw_exportprep, over(pole, sort(1))
gr export bar_raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_exportprep.png
putpdf pagebreak

stripplot raw_exportprep, over(pole) vertical
gr export strip_raw_exportprep.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_exportprep.png
putpdf pagebreak

	* Combined export practices Z-scores
	
hist raw_exportcombined, title("Raw sum of allcombined export practices questions") xtitle("Sum")
graph export raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image raw_exportcombined.png
putpdf pagebreak

graph bar raw_exportcombined, over(pole, sort(1))
gr export bar_raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_raw_exportcombined.png
putpdf pagebreak

stripplot raw_exportcombined, over(pole) vertical
gr export strip_raw_exportcombined.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_raw_exportcombined.png
putpdf pagebreak

***********************************************************************
* 	PART 4:  List experiment
************************************************************************
*(something like graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
		
/***********************************************************************
* 	PART 5:  Firm characteristics
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
* 	PART 6:  Alternative eligibility
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
* 	PART 7:  save pdf
***********************************************************************
	* change directory to progress folder
cd "$bl_output"
	* pdf
putpdf save "baseline_statistics", replace
