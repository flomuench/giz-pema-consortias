***********************************************************************
* 			Descriptive Statistics in master file *					  
***********************************************************************
*																	  
*	PURPOSE: Understand the structure of the data from the baseline					  
*																	  
*	OUTLINE: 	PART 1: Paths
*				PART 2: Baseline statistics	  

*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	 ecommerce_data_final.dta

										  
***********************************************************************
* 	PART 1: Paths
***********************************************************************
use "${master_final}/consortium_final", clear

		* change directory to regis folder for merge with regis_final
cd "${master_output}/figures"

		 
*correlation matrix of selected variables
*correlate ca_2021 ca_exp_2021 profit_2021 exprep_inv

set scheme s1color


***********************************************************************
* 	PART 1: Table 1
***********************************************************************
lab var exp_pays "Export countries"
	* by consortium & surveyround
table (var) (treatment) if surveyround == 1, nototals ///
	statistic(mean age employes ca exported exp_pays ca_exp ca_tun profit) ///
	statistic(sd age employes ca exported exp_pays ca_exp ca_tun profit) ///
	statistic(min age employes ca exported exp_pays ca_exp ca_tun profit) ///
	statistic(max age employes ca exported exp_pays ca_exp ca_tun profit) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.2fc fvproportion)
	
	
	table (var) () if surveyround == 1, nototals ///
	statistic(mean age employes ca exported exp_pays ca_exp ca_tun profit) ///
	statistic(sd age employes ca exported exp_pays ca_exp ca_tun profit) ///
	statistic(min age employes ca exported exp_pays ca_exp ca_tun profit) ///
	statistic(max age employes ca exported exp_pays ca_exp ca_tun profit) ///
	nformat(%9.0g  fvfrequency) ///
	nformat(%9.0fc mean sd min max)

***********************************************************************
* 	PART 2: Basline statistics
***********************************************************************

		* location of consortia members
graph hbar (count) if treatment == 1 & take_up == 1, over(gouvernorat, label(labs(vsmall))) by(pole, note("")) blabel(bar, format(%9.0fc)) ytitle("number of firms")
gr export location.png, replace


		* firm characteristics: differences between consortia
local network_vars "net_size net_nb_qualite net_coop_pos net_coop_neg"
local empowerment_vars "genderi female_efficacy female_loc"
local kt_vars "mpi innovations innovated"
local business_vars "sales profit employes"
local export_vars "eri exprep_couts exp_inv exported ca_exp"

{
local exp_status "exported exp_invested exp_afrique"
local financial "ca_w99 ca_exp_w99 costs_w99 profit_w99 profit_pos employes_w99"
local basic "presence_enligne tunis age capital_w99"
local innovation "inno_rd innovations innovated"
local network "net_nb_fam_w99 net_nb_dehors_w99 net_nb_qualite net_time net_coop_neg" // ml vars: net_nb_f net_nb_m
local obligations "famille1 famille2"
local expectations "att_adh1 att_adh2 att_adh3 att_adh4 att_adh5 att_strat1 att_strat2 att_strat3 att_cont1 att_cont2 att_cont3 att_cont4"
}

				* all firms
iebaltab `network_vars' `empowerment_vars' `kt_vars' `business_vars' `export_vars' if surveyround == 1 & id_plateforme != 1092, grpvar(pole) ftest savetex(baltab_consortia_bl) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
			 
			 
				* take-up: only firms that participate in consortium
					* list 1: `networks_var' `empowerment_vars' `kt_vars' `business_vars' `export_vars'
/*					* list 2: exp_status' eri `financial' `basic' `network' `innovation' mpi marki genderi `obligations' `expectations'
iebaltab `exp_status' eri `financial' `basic' `network' `innovation' mpi marki genderi `obligations' `expectations' if surveyround == 1 & id_plateforme != 1092 & take_up == 1, grpvar(pole) ftest save(baltab_consortia_take_up) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
*/			 
			 * drop-outs
iebaltab `exp_status' eri `financial' `basic' `network' `innovation' mpi marki genderi `obligations' `expectations' if surveyround == 1 & id_plateforme != 1092 & take_up == 0 & treatment == 1, grpvar(pole) ftest save(baltab_consortia_drop_out) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
			 
			 * digital consortium
				* `obligations' `expectations'
iebaltab `exp_status' eri `financial' `basic' `network' `innovation' mpi marki genderi if surveyround == 1 & id_plateforme != 1092 & cons_dig == 1 & treatment == 1, grpvar(take_up) ftest savetex(baltab_consortia_take_up_dig) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)
			 
			* all other consortia 
				* `obligations' `expectations'
iebaltab `exp_status' eri `financial' `basic' `network' `innovation' mpi marki genderi if surveyround == 1 & id_plateforme != 1092 & cons_dig == 0 & treatment == 1, grpvar(take_up) ftest savetex(baltab_consortia_take_up_row) replace ///
			 vce(robust) pttest rowvarlabels balmiss(mean) onerow stdev notecombine ///
			 format(%12.2fc)	 
{

* create word document
putpdf clear
putpdf begin 
putpdf paragraph

putpdf text ("Consortia: Baseline Statistics and firm characteristics"), bold linebreak

putpdf text ("Date: `c(current_date)'"), bold linebreak
putpdf paragraph, halign(center) 

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


*Type of support desired by firms
gr hbar (sum) support2 support6 support3 support4 support5 support1, blabel(total, format(%9.0fc)) ///
	legend (pos(3) row(6) label (1 "1: Virtual meetings") label(2 "2: Transport or accomodation") ///
	label(3 "3: Alternate location, e.g. by city") label(4 "4: Time slot before or after work") ///
	label(5 "5: Child care") label(6 "6: No need for support")) ///
	ytitle("number of firms", size(small)) ///
	note("{it:N = 176}", size(small)) ///
	name(support_options, replace)
gr export support_options.png, replace
putpdf paragraph, halign(center) 
putpdf image support_options.png
putpdf pagebreak


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

sum age,d
graph bar age, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("Years") ///
	ylabel(0(1)9 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
gr export age.png, replace
putpdf paragraph, halign(center) 
putpdf image age.png
putpdf pagebreak

sum employes,d
graph bar employes, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of Employees") ///
	ylabel(0(2)22 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
gr export employees.png, replace
putpdf paragraph, halign(center) 
putpdf image employees.png
putpdf pagebreak
	
sum exp_pays,d
graph bar exp_pays, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT")) ///
	yline(`r(mean)', lpattern(1)) yline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of countries") ///
	ylabel(0(1)2.5 , nogrid) ///
	text(`r(mean)' 0.1 "Mean", size(vsmall) place(n)) ///
	text(`r(p50)'  0.1 "Median", size(vsmall) place(n) )
gr export export_countries2.png, replace
putpdf paragraph, halign(center) 
putpdf image export_countries2.png
putpdf pagebreak
		
sum exp_pays,d
histogram(exp_pays) if exp_pays<10, width(1) frequency addlabels xlabel(0(1)8, nogrid) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of firms") ///
	xtitle("No. of export destinations") ///
	ylabel(0(20)100 , nogrid) ///
	text(100 `r(mean)' "Mean", size(vsmall) place(e)) ///
	text(100 `r(p50)' "Median", size(vsmall) place(e))
gr export export_countries.png, replace
putpdf paragraph, halign(center) 
putpdf image export_countries.png
putpdf pagebreak


	*Family vs non-family contact*
graph bar net_nb_dehors net_nb_fam, over(pole, relabel(1 "Agriculture" 2"Handcrafts& Cosmetics" 3"Services" 4"IT"))stack ///
	ytitle("Person") ///
	ylabel(0(2)16, nogrid) ///
	legend(order(1 "Non-family contacts" 2 "Family contacts") pos(6))
gr export network.png, replace
putpdf paragraph, halign(center) 
putpdf image network.png
putpdf pagebreak


graph bar (mean) net_nb_dehors net_nb_fam , blabel(total, format(%9.2fc) gap(-0.2))  ///
	title("Number of family vs non-family contacts") ///
	ylabel(0(1)11, nogrid) /// 
	legend(order(1 "Non-family contacts" 2 "Family contacts") pos(6))
gr export famcont.png, replace
putpdf paragraph, halign(center) 
putpdf image famcont.png
putpdf pagebreak
	
tw ///
	(kdensity net_nb_dehors if net_nb_dehors < 40, lp(l) lc(maroon) yaxis(2) bw(0.4)) ///
	(histogram net_nb_dehors if net_nb_dehors < 40, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	(kdensity net_nb_fam if net_nb_fam < 40, lp(l) lc(navy) yaxis(2) bw(0.4)) ///
	(histogram net_nb_fam if net_nb_fam < 40, freq w(.1) recast(scatter) msize(small) mc(green)) ///
	, ///
	xtitle("Distribution of family vs non-family contacts", size(vsmall)) ///
	ytitle("Densitiy", axis(2) size(vsmall)) ///	
	legend(symxsize(small) order(1 "Non-Family contacts" 2 "Family contacts")  pos(6) row(1)) ///
	xlabel(0(5)35, nogrid format(%9.0f)) ///
	name(network_density, replace)
gr export network_density.png, replace
putpdf paragraph, halign(center) 
putpdf image network_density.png
putpdf pagebreak


sum net_size,d
histogram(net_size) if net_size>0 & surveyround ==1 & net_size <60, width(5) frequency addlabels discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of firms") ///
	xtitle("No. of CEO") ///
	ylabel(0(10)70, nogrid format(%9.0f)) ///
	xlabel(0(5)55, nogrid format(%9.0f)) ///
	text(50 `r(mean)' "Mean", size(vsmall) place(e)) ///
	text(70 `r(p50)' "Median", size(vsmall) place(e))
gr export netsize_bl.png, replace
putpdf paragraph, halign(center) 
putpdf image netsize_bl.png
putpdf pagebreak

*graph bar list_exp, over(list_group) - where list_exp provides the number of confirmed affirmations).
graph bar listexp, over(list_group, sort(1) relabel(1"Non-sensitive" 2"Sensitive option incl.")) ///
	blabel(total, format(%9.2fc) gap(-0.2)) ///
ytitle("No. of affirmations") ///
ylabel(0(1)3.2, nogrid) 
gr export bar_listexp.png, replace
putpdf paragraph, halign(center) 
putpdf image bar_listexp.png
putpdf pagebreak

	
*locus of control and initiative	
graph hbar (mean) car_loc_insp car_loc_succ car_loc_env, blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Inspiring other women to become better entrepreneurs") label (2 "Able to determine the success of her business") ///
	label  (3 "Control over the internal and external environment of the firm") ) ///
	title("Locus of control for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid) 
gr export locuscontrol.png, replace
putpdf paragraph, halign(center) 
putpdf image locuscontrol.png
putpdf pagebreak
	
graph hbar (mean) car_init_init car_init_prob car_init_opp, blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(6) label(1 "Taking initiatives when others do not") label (2 "Proactive problem confrontations") ///
	label  (3 "Identification and pursue of opportunities") ) ///
	title("Locus of initiative for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid) 
	gr export "$bl_output/donor/initiative.png", replace
gr export initiative.png, replace
putpdf paragraph, halign(center) 
putpdf image initiative.png
putpdf pagebreak

	
	
graph hbar (mean) car_efi_conv car_efi_nego car_efi_fin1, blabel(total, format(%9.2fc) gap(-0.2)) ///
	legend (pos(6) row(9) label(1 "Manage to convince employees and partners to agree") label(2 "Negotiate the affairs of the company well") ///
	label(3 "Have the skills to access new sources of funding")size(vsmall)) ///
	title("Locus of entrepreuneurhsip for female entrepreuneurs") ///
	ylabel(0(1)5, nogrid)    
	gr export "$bl_output/donor/locus_efi.png", replace
gr export locus_efi.png, replace
putpdf paragraph, halign(center) 
putpdf image locus_efi.png
putpdf pagebreak
	
	
	
*Interactions between CEO	
graph bar (mean) net_coop_pos net_coop_neg, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Positive answers for the perception of interactions between CEOs") label(2 "Negative answers for the perception of interactions between CEOs")) ///
	title("Perception of interactions between CEOs") ///
	ylabel(0(1)3, nogrid) 
	gr export "$bl_output/donor/perceptions_interactions.png", replace
gr export perceptions_interactions.png, replace
putpdf paragraph, halign(center) 
putpdf image perceptions_interactions.png
putpdf pagebreak
	
graph hbar netcoop5 netcoop7 netcoop2 netcoop1 netcoop3 netcoop9 netcoop8 netcoop10 netcoop4 netcoop6, blabel(total, format(%9.2fc) gap(-0.2))  ///
	legend (pos(6) row(6) label (1 "Power") label(2 "Partnership") ///
	label(3 "Communicate") label(4 "Win") label(5 "Trust") ///
	label(6 "Connect") label(7 "Opponent") label(8 "Dominate") ///
	label(9 "Beat") label(10 "Retreat")) ///
	title("Perception of interactions between CEOs") ///
	ylabel(0(0.5)0.7, nogrid) 
gr export perceptions_interactions_details.png, replace
putpdf paragraph, halign(center) 
putpdf image perceptions_interactions_details.png
putpdf pagebreak

*Number of CEO met*

sum net_time,d
histogram net_time if net_time<35, width(5) frequency addlabels xlabel(0(5)35, nogrid format(%9.0f)) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of firms") ///
	xtitle("Number of other directors met during the last 12 months") ///
	ylabel(0(10)80 , nogrid) ///
	text(100 `r(mean)' "Mean", size(small) place(e)) ///
	text(100 `r(p50)' "Median", size(small) place(e))
gr export CEO_network.png, replace
putpdf paragraph, halign(center) 
putpdf image CEO_network.png
putpdf pagebreak	

*Quality of advice*
sum net_nb_qualite,d
histogram net_nb_qualite, width(1) frequency addlabels xlabel(0(1)10, nogrid format(%9.0f)) discrete ///
	xline(`r(mean)', lpattern(1)) xline(`r(p50)', lpattern(dash)) ///
	ytitle("No. of firms") ///
	xtitle("Quality of advice of the business network") ///
	ylabel(0(5)50 , nogrid) ///
	text(100 `r(mean)' "Mean", size(small) place(e)) ///
	text(100 `r(p50)' "Median", size(small) place(e))
gr export quality_advice.png, replace
putpdf paragraph, halign(center) 
putpdf image quality_advice.png
putpdf pagebreak		
	
*Management & Marketing practices
graph hbar (mean) man_pro_ano man_hr_feed man_fin_enr man_fin_per man_hr_obj, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Frequency of measuring anomalies in production") label(2 "Regular meetings with employees for feedback") ///
	label(3 "Registration of sales and purchases") label(4 "Frequency of examining financial performance") label(5 "Performance indicators for employees")) ///
	title("Management Practices") ///
	ylabel(0(1)4, nogrid) 
gr export managementpractices.png, replace
putpdf paragraph, halign(center) 
putpdf image managementpractices.png
putpdf pagebreak

graph hbar (mean) man_mark_offre man_mark_div man_fin_profit man_mark_prix man_mark_pub man_mark_clients, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(6) label (1 "Attract customers with a special offer") label(2 "Ask customers what other products they would like to be produced") label(3 "Knowing the profit per product/service") ///
	label(4 "Study the prices and/or products of one of competitors") label(5 "Advertising in any form") ///
	label(6 "Investigate why past customers have stopped buying from the company")) ///
	title("Management & Marketing Practices") ///
	ylabel(0(0.5)1, nogrid) 
gr export mgntmktpractices.png, replace
putpdf paragraph, halign(center) 
putpdf image mgntmktpractices.png
putpdf pagebreak

*Export management/readiness
graph hbar (mean) exp_pra_cible exp_pra_plan exp_pra_mission exp_pra_douane exp_pra_foire exp_pra_rexp exp_pra_sci, blabel(total, format(%9.1fc) gap(-0.2)) ///
	legend (pos(6) row(7) label (1 "Undertake an analysis of target export markets") label(2 "Maintain or develop an export plan") ///
	label(3 "Undertake a trade mission/travel to one of target markets") label(4 "Access the customs website") label(5 "Participate in international trade exhibitions/fairs") ///
	label(6 "Designate an employee in charge of export-related activities") label(7 "Engage or work with an international trading company")size(vsmall)) ///
	title("Export Readiness Practices") ///
	ylabel(0(0.2)1, nogrid)    
	gr export "$bl_output/donor/erp.png", replace
	gr export erp.png, replace
	putpdf paragraph, halign(center) 
	putpdf image erp.png
putpdf pagebreak

*Correlation between firm size & network size
scatter employes net_time  if employes <65 & net_time< 25.00 || lfit  employes net_time //
gr export scatter_network.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_network.png
putpdf pagebreak

*Correlation between firm size & management practice index
scatter employes net_nb_qualite if employes <65  || lfit  employes net_nb_qualite
gr export scatter_qua.png, replace
putpdf paragraph, halign(center) 
putpdf image scatter_qua.png
putpdf pagebreak

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

}

egen ca_95p = pctile(ca_2021), p(95)
kdensity ca if ca<ca_95p & ca> 0 & surveyround == 1,  ///
	title("", pos(12)) ///
	note("{it:Note: Total turnover in 20221 is winsorized at 95th percentile for visualisation.}", size(small)) ///
	xtitle ("Amount of total turnover in 2021") ///
	xlabel(0(300000)900000) ///
	ylabel(0(0.000002)0.000006)
gr export k_dens_ca2021.png, replace
putpdf paragraph, halign(center) 
putpdf image k_dens_ca2021.png
putpdf pagebreak

putpdf save "baseline_statistics", replace
}
