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

	* create pdf document
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
gen share= (`r(N)'/181)*100
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
gen share= (`r(N)'/181)*100
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
gen share= (`r(N)'/181)*100
graph bar share, blabel(total, format(%9.2fc)) ///
	title("La part des entreprises avec reponses validés")
gr export validated_responses.png, replace
putpdf paragraph, halign(center) 
putpdf image validated_responses.png
putpdf pagebreak
drop share

*Type of support desired by firms
gr hbar (sum) support2 support6 support3 support4 support5 support1, blabel(total, format(%9.0fc)) ///
	legend (pos(3) row(6) label (1 "1: Virtual meetings") label(2 "2: Transport or accomodation") ///
	label(3 "3: Alternate location, e.g. by city") label(4 "4: Time slot before or after work") ///
	label(5 "5: Child care") label(6 "6: No need for support")) ///
	ytitle("number of firms", size(small)) ///
	name(support_options, replace)
gr export support_options.png, replace


gr bar (mean) age, over(support5) blabel(total, format(%9.1fc)) /* firms needing support with childcare are 2 years younger */
gr bar (mean) famille2, over(support5) blabel(total, format(%9.1fc)) /* & have half a child < 18 more */
gr bar (mean) w_ca2021, over(support5) blabel(total, format(%9.1fc)) /* & half CA in 2021 */
gr bar (mean) operation_export, over(support5) blabel(total, format(%9.1fc)) /* 10pp less likely exporter */
gr bar (mean) employes, over(support5) blabel(total, format(%9.1fc)) /* 10pp less likely exporter */

	
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
preserve
rename (att_strat1 att_strat2 att_strat3 att_strat4) (attstrat#), addnumber(1)
gen n= _n
reshape long attstrat, i(n)
label define _j 1 "Pas de stratégie d'exportation" 2 "les deux stratégies doit être cohérente" 3 "L'entreprise a une stratégie d'exportation" 4 "Autres" 
label values _j _j
graph hbar (sum) attstrat, over(_j, label relabel(2 "les deux stratégies doit être cohérente" 3 "L'entreprise a une stratégie d'exportation") sort(1) descending) bargap(100) asyvars showyvars ///
                           legend(off) blabel(total,format(%9.2fc) pos(outside)) yla(0(20)100) ///
                           graphregion(margin(55 2 2 2)) ylabel(, angle(forty_five) valuelabel) ///
                           title("Rôle du consortium dans l'établissement de la stratégie d'exportation", position(middle) size(small))

restore
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

preserve
tab att_voyage, g(att_voyage)
rename (att_voyage1 - att_voyage3) (attvoyage#), addnumber(1)
gen n= _n
reshape long attvoyage, i(n)
label define _j 1 "la participante ne peut pas voyager" 2 "la participante peut voyager" 3 "la participante peut voyager s'il y a un soutien financier"
label values _j _j
graph hbar (sum) attvoyage, over(_j, label relabel(1 "la participante ne peut pas voyager" 2 "la participante peut voyager" 3 "la participante peut voyager s'il y a un soutien financier") sort(1) descending) bargap(100) asyvars showyvars ///
                           legend(off) blabel(total,format(%9.2fc) pos(outside)) yla(0(20)100) ///
                           graphregion(margin(70 2 2 2)) ylabel(, angle(forty_five) valuelabel) ///
                           title("la possibilité de voyager pour la participante")

restore
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
***********************************************************************
* 	PART 7:  save pdf
***********************************************************************
	* change directory to progress folder

	* pdf
putpdf save "baseline_statistics", replace

