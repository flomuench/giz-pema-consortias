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
use "$bl_final/bl_final", clear

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
gr hbar (sum) support1 - support6, blabel(total, format(%9.2fc)) legend (pos (6) label (1 "Pas besoin d'assistance") label(2 "Réunions virtuelles") label(3 "Changer l’endroit de rencontre, par exemple d’une ville à une autre") label(4 "Creneau avant ou apres du travail") label(5 "Garde d'enfants") label(6 "Support pour transport et hébergement")) ///
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

*Role of consortium in establishing export strategy
gr bar (sum) att_strat1 - att_strat4, scale(*.75) blabel(total, format(%9.2fc)) legend (pos (4) label (1 "La participante n'a pas de stratégie d'exportation") label(2 "la stratégie du consortium doit être cohérente avec sa stratégie") label(3 "L'entreprise a une stratégie d'exportation" ) label (4 "Autres")) ///
	title("Rôle du consortium dans l'établissement de la stratégie d'exportation")
gr export att_strat.png, replace
putpdf paragraph, halign(center) 
putpdf image att_strat.png
putpdf pagebreak

*Best mode of financial contribution of each member in the consortium
gr hbar (sum) att_cont1 - att_cont5, blabel(total, format(%9.2fc)) legend (pos (5) label (1 "Aucune contribution") label(2 "Une contribution fixe, forfaitaire") label(3 "Une contribution proportionnelle à la taille de chaque membre (selon CA)") label (4 "Une contribution au prorata du chiffre d’affaires réalisé à l’export") label(5 "Autres")) ///
	title("Meilleur mode de contribution financière de chaque membre du consortium")
gr export att_cont.png, replace
putpdf paragraph, halign(center) 
putpdf image att_cont.png
putpdf pagebreak

*Preferred day for meetings
gr hbar (sum) att_jour1 - att_jour7, blabel(total, format(%9.2fc)) legend (pos (7) label (1 "Lundi") label(2 "Mardi") label(3 "Mercredi") label(4 "Jeudi") label(5 "Vendredi") label(6 "Samedi") label(7 "Dimanche")) title("Jour préféré pour les réunions")
gr export att_jour.png, replace
putpdf paragraph, halign(center) 
putpdf image att_jour.png
putpdf pagebreak

*Preferred hours for meetings
gr hbar (sum) att_hor1 - att_hor5, blabel(total, format(%9.2fc)) legend (pos (5) label (1 "8:00h - 10:00h") label(2 "9:00h - 12:30h") label(3 "12:30h - 15:30h") label(4 "15:30h - 19:00h") label(5 "18:00h - 20:00h")) title("Heures préférées pour les réunions")
gr export att_hor.png, replace
putpdf paragraph, halign(center) 
putpdf image att_hor.png
putpdf pagebreak

*Availablibility for travel and participate in events in another city 
hist att_voyage, gap(40) xlabel(1 2 0, valuelabel)
graph export att_voyage.png, replace
putpdf paragraph, halign(center) 
putpdf image att_voyage.png
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
egen ca_95p = pctile(ca_2021), p(95)
graph bar ca_2021 if ca_2021<ca_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_ca2021.png
putpdf pagebreak

stripplot ca_2021 if ca_2021<ca_95p, over(pole) vertical
gr export strip_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_ca2021.png
putpdf pagebreak

     * variable ca_exp_2021:
egen ca_exp95p = pctile(ca_exp_2021), p(95)
graph bar ca_exp_2021 if ca_exp_2021<ca_exp95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_ca_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_ca_exp2021.png
putpdf pagebreak

stripplot ca_exp_2021 , over(pole) vertical
gr export strip_ca_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_ca_exp2021.png
putpdf pagebreak

     * variable profit_2021:
egen profit_95p = pctile(profit_2021), p(95)
graph bar profit_2021 if profit_2021<profit_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_profit_2021.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_profit_2021.png
putpdf pagebreak

stripplot profit_2021 if profit_2021<profit_95p, over(pole) vertical
gr export strip_profit_2021.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_profit_2021.png
putpdf pagebreak


     * variable inno_rd:
egen inno_rd_95p = pctile(inno_rd), p(95)
graph bar inno_rd if inno_rd<inno_rd_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_inno_rd.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_inno_rd.png
putpdf pagebreak

stripplot inno_rd if inno_rd<inno_rd_95p, over(pole) vertical
gr export strip_inno_rd.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_inno_rd.png
putpdf pagebreak

     * variable exprep_inv:
egen exprep_inv_95p = pctile(exprep_inv), p(95)
graph bar exprep_inv if exprep_inv<exprep_inv_95p, over(pole, sort(1)) blabel(total, format(%9.2fc))
gr export bar_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_exprep_inv.png
putpdf pagebreak

stripplot exprep_inv if exprep_inv<exprep_inv_95p, over(pole) vertical
gr export strip_exprep_inv.png, replace
putpdf paragraph, halign(center) 
putpdf image strip_exprep_inv.png
putpdf pagebreak

*scatter plots between CA and CA_Exp
scatter ca_exp_2021 ca_2021 if ca_2021<ca_95p & ca_exp_2021<ca_exp95p, title("Proportion des bénéfices d'exportation par rapport au bénéfice total")
gr export scatter_ca.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_ca.png
putpdf pagebreak

*scatter plots between CA_Exp and exprep_inv
scatter ca_exp_2021 exprep_inv if ca_exp_2021<ca_exp95p & exprep_inv<exprep_inv_95p, title("Part de l'investissement dans la préparation des exportations par rapport au CA à l'exportation")
gr export scatter_exprep.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_exprep.png
putpdf pagebreak

*scatter plots between CA and inno_rd
scatter ca_2021 inno_rd if inno_rd<inno_rd_95p & ca_2021<ca_95p, title("Proportion des investissements dans l'innovation (R&D) par rapport au chiffre d'affaires")
gr export scatter_exprep.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_exprep.png
putpdf pagebreak

*scatter plots by pole
forvalues x = 1(1)4 {
		* between CA and CA_Exp
twoway (scatter ca_2021 ca_exp_2021 if ca_2021<ca_95p & ca_exp_2021<ca_exp95p & pole == `x' , title("Proportion de CA exp par rapport au CA- pole`x'")) || ///
(lfit ca_2021 ca_exp_2021 if ca_2021<ca_95p & ca_exp_2021<ca_exp95p & pole == `x', lcol(blue))
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

graph bar mngtvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar markvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar exportmngt, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar exportprep, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar exportcombined, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar raw_mngtvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar raw_markvars, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar raw_exportmngt, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar raw_exportprep, over(pole, sort(1)) blabel(total, format(%9.2fc))
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

graph bar raw_exportcombined, over(pole, sort(1)) blabel(total, format(%9.2fc))
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
*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp, over(list_group, sort(1)) blabel(total, format(%9.2fc))
gr export bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_listexp.png
putpdf pagebreak		
***********************************************************************
* 	PART 5:  Comparing matched vs new data
***********************************************************************
egen ca20_95p = pctile(ca_2020), p(95)
twoway (scatter ca_2021 ca_2020 if ca_2021<ca_95p & ca_2020<ca20_95p, title("Correlation CA2021-2021 full sample<95p")) || ///
(lfit ca_2021 ca_2020 if ca_2021<ca_95p & ca_2020<ca20_95p, lcol(blue))
gr export old_new_ca_scatter.png, replace
putpdf paragraph, halign(center) 
putpdf image old_new_ca_scatter.png
putpdf pagebreak

egen exp20_95p = pctile(ca_exp2020), p(95)
twoway (scatter ca_exp_2021 ca_exp2020 if ca_exp_2021<ca_exp95p & ca_exp2020<exp20_95p, title("Correlation Export 2021-2020 full sample<95p")) || ///
(lfit ca_2021 ca_2020 if ca_2021<ca_exp95p & ca_2020<exp20_95p, lcol(blue))
gr export old_new_exp_scatter.png, replace
putpdf paragraph, halign(center) 
putpdf image old_new_exp_scatter.png
putpdf pagebreak

forvalues x = 1(1)4 {
		* between CA21 and CA exp
twoway (scatter ca_2021 ca_exp_2021 if ca_2021<ca_95p & ca_exp_2021<ca_exp95p & pole==`x', title("CA-Exp <95p for each pole")) || ///
(lfit ca_2021 ca_exp_2021 if ca_2021<ca_95p & ca_exp_2021<ca_exp95p & pole==`x', lcol(blue))
gr export caexp_cor_`x'.png, replace
putpdf paragraph, halign(center) 
putpdf image caexp_cor_`x'.png
putpdf pagebreak
}

forvalues x = 1(1)4 {
		* between exp21 and exp20
twoway (scatter ca_exp_2021 ca_exp2020 if ca_exp_2021<ca_exp95p & ca_exp2020<exp20_95p & pole==`x', title("Correlation Export<95p by pole")) || ///
(lfit ca_2021 ca_2020 if ca_2021<ca_exp95p & ca_2020<exp20_95p & pole==`x', lcol(blue))
gr export old_new_exps_scatter_`x'.png, replace
putpdf paragraph, halign(center) 
putpdf image old_new_exps_scatter_`x'.png
putpdf pagebreak
}

*/	
***********************************************************************
* 	PART 6:  Correlation of index variables with accounting data
***********************************************************************
twoway (scatter ca_exp_2021 exportmngt if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 exportmngt if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_exportmanag_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_exportmanag_exp2021.png
putpdf pagebreak

twoway (scatter ca_exp_2021 mngtvars if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 mngtvars if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_manageprac_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_manageprac_exp2021.png
putpdf pagebreak

twoway (scatter ca_exp_2021 exportcombined if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 exportcombined if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_expcombinedindex_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_expcombinedindex_exp2021.png
putpdf pagebreak

twoway (scatter ca_exp_2021 exportprep if ca_exp_2021<ca_exp95p) || ///
(lfit ca_exp_2021 exportprep if ca_exp_2021<ca_exp95p, lcol(blue))
gr export cor_expprep_exp2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_expprep_exp2021.png
putpdf pagebreak

twoway (scatter ca_2021 exportmngt if ca_2021<ca_95p) || ///
(lfit ca_2021 exportmngt if ca_2021<ca_95p, lcol(blue))
gr export cor_exportmanag_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_exportmanag_ca2021.png
putpdf pagebreak


twoway (scatter ca_2021 mngtvars if ca_2021<ca_95p) || ///
(lfit ca_2021 mngtvars if ca_2021<ca_95p, lcol(blue))
gr export cor_manageprac_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image cor_manageprac_ca2021.png
putpdf pagebreak

cd "$bl_output"

asdoc cor ca_2021 ca_exp_2021 profit_2021 exprep_inv inno_rd exportmngt mngtvars exportcombined, save(cor_matrix_bldata.doc) title(Correlation matrix of indices and 2021 data)
asdoc cor ca_2021 ca_2020 ca_2019 ca_2018 ca_exp_2021 ca_exp2020 ca_exp2020 ca_exp2019 ca_exp2018 profit_2021, save(cor_matrix_20182021.doc) title(2021 vs. 2018-2020 financial data)

tab ca_2021
tab ca_2020
tab ca_2019
tab ca_exp_2021
tab ca_exp2020
tab ca_exp2019

*There are less missing values for the newest data from 2021, so probably better to take this one*

***********************************************************************
* 	PART 7:  save pdf
***********************************************************************
	* change directory to progress folder

	* pdf
putpdf save "baseline_statistics", replace
