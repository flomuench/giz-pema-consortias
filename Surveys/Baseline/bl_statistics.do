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
set graphics off
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
	note("{it:N = 176}", size(small)) ///
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


***********************************************************************
* 	PART 3:  Statistics for donor report		  			
***********************************************************************
set scheme s1color


		* CA, CA export
gen w_ca2021_usd=w_ca2021/3
sum w_ca2021_usd,d
graph bar w_ca2021_usd, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("USD") ///
	ylabel (0(100000)200000 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
	gr export "$bl_output/donor/ca_mean.png", replace
	
sum age,d
graph bar age, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("Years") ///
	ylabel(0(1)9 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
	gr export "$bl_output/donor/age.png", replace

sum employes,d
graph bar employes, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of Employees") ///
	ylabel(0(2)22 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
	gr export "$bl_output/donor/employees.png", replace
	
sum exp_pays,d
graph bar exp_pays, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of countries") ///
	ylabel(0(1)2.5 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
	gr export "$bl_output/donor/export_countries2.png", replace

sum exp_pays,d
histogram(exp_pays) if exp_pays<10, width(1) frequency addlabels xlabel(0(1)8, nogrid) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of firms") ///
	xtitle("Number of export destinations") ///
	ylabel(0(20)100 , nogrid) ///
	text(100 `r(mean)' "Mean", size(vsmall) place(e)) ///
	text(100 `r(p50)' "Median", size(vsmall) place(e))
	gr export "$bl_output/donor/export_countries.png", replace

graph bar net_nb_dehors net_nb_fam, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT"))stack ///
	ytitle("Person") ///
	ylabel(0(2)16, nogrid) ///
	legend(order(1 "Non-family contacts" 2 "family contacts") pos(6))
	gr export "$bl_output/donor/network.png", replace

tw ///
	(kdensity net_nb_dehors, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(kdensity net_nb_fam, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	, ///
	title("{bf:Full sample}") ///
	xtitle("Distribution of family vs non-family contact", size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Non-Family contacts" 2 "Family contacts")) ///
	xlabel(0(20)100, nogrid) ///
	name(network_density, replace)
gr export "$bl_output/donor/network_density.png", replace

	
*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp, over(list_group, sort(1) relabel(1"non-sensitive" 2"sensitive option incl.")) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export "$bl_output/donor/bar_listexp.png", replace

	
*locus of control and initiative
graph hbar (mean) car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Competence to access financial sources") label(2 "Ability to manage the business") ///
	label(3 "Able to convince employees & partners") label(4 "Proactive problem confrontation") label(5 "Taking initiative when others do not") ///
	label(6 "Idenfication and pursue of opportunities")) ///
	ylabel(0(1)5, nogrid) 
	gr export "$bl_output/donor/initiative.png", replace
	
graph hbar (mean) car_loc_succ car_loc_env car_loc_insp, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Able to determine the success of her business") label(2 "Control over internal and external environment of the firm") ///
	label(3 "Inspiring other women to become better entrepreneurs") ) ///
	ylabel(0(1)5, nogrid) 
	gr export "$bl_output/donor/locuscontrol.png", replace
	
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

