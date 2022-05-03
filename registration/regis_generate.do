***********************************************************************
* 			registration generate									  	  
***********************************************************************
*																	    
*	PURPOSE: generate registration variables				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1) sector
* 	2) gender
* 	3) onshore / offshore  							  
*	4) produit exportable  
*	5) intention d'exporter 			  
*	6) une opération d'export				  
*   7) export status  
*	8) age
*	9) eligibility	
*
*																	  															      
*	Author:  	Florian Muench & Kais Jomaa							  
*	ID variaregise: 	id (example: f101)			  					  
*	Requires: regis_inter.dta 	  								  
*	Creates:  regis_inter.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Define non-response categories  			
***********************************************************************
use "${regis_intermediate}/regis_inter", clear


***********************************************************************
* 	PART 2: factor variable sector & subsector 			  										  
***********************************************************************

/*label define sector_name 1 "Agriculture & Peche" ///
	2 "Artisanat" ///
	3 "Commerce international" ///
	4 "Industrie" ///
	5 "Services" ///
	6 "TIC" */
/*
label define subsector_name 1 "autres" ///
	2 "pôle d'activités agri-agroalimentaire" ///
	3 "pôle d'activités artisanat" ///
	4 "pôle d'activités cosmétiques" ///
	5 "pôle d'activités de Santé" ///
	6 "pôle d’activités de service conseil, education et formation" ///
	7 "pôle d’activités technologies de l’information et de la communication" ///
	8 "pôle d'activités textiles et habillement" ///
	9 "pôle de l'énergie durable et développement durable" ///
	10 "pôle d’activités technologies de l’information et de la communication" ///
	11 "sci"
		
*/
/*tempvar Sector
encode sector, gen(`Sector')
drop sector
rename `Sector' sector
lab values sector sector_name */

encode subsector_corrige, gen(subsector_corrige1)
*groups Subsector
drop subsector_corrige
rename subsector_corrige1 subsector_corrige
*lab values subsector subsector_name


format %-25.0fc *subsector_corrige

***********************************************************************
* 	PART 2: factor variable gender 			  										  
***********************************************************************
label define sex 1 "female" 0 "male"
tempvar Gender
encode rg_gender, gen(`Gender')
drop rg_gender
rename `Gender' rg_gender_rep
replace rg_gender = 0 if rg_gender == 2
lab values rg_gender sex

tempvar Genderpdg
encode rg_sex_pdg, gen(`Genderpdg')
drop rg_sex_pdg
rename `Genderpdg' rg_gender_pdg
replace rg_gender_pdg = 0 if rg_gender_pdg == 2
lab values rg_gender_pdg sex

***********************************************************************
* 	PART 3: factor variable onshore 			  										  
***********************************************************************
lab def onshore 1 "résidente" 0 "non résidente"
encode rg_onshore, gen(rg_resident)
replace rg_resident = 0 if rg_resident == 1
replace rg_resident = 1 if rg_resident == 2
drop rg_onshore
lab val rg_resident onshore
lab var rg_resident "HQ en Tunisie"

***********************************************************************
* 	PART 4: factor variable produit exportable		  										  
***********************************************************************
lab def exportable 1 "produit exportable" 0 "produit non exportable"
encode rg_exportable, gen(rg_produitexp)
replace rg_produitexp = 0 if rg_produitexp == 1
replace rg_produitexp = 1 if rg_produitexp == 2
drop rg_exportable
lab val rg_produitexp exportable
lab var rg_produitexp "Entreprise pense avoir un produit exportable"

***********************************************************************
* 	PART 5: factor variable intention exporter			  										  
***********************************************************************
lab def intexp 1 "intention export" 0 "pas d'intention à exporter"
encode rg_intexp, gen(rg_intention)
replace rg_intention = 0 if rg_intention == 1
replace rg_intention = 1 if rg_intention == 2
drop rg_intexp
lab val rg_intention intexp
lab var rg_intention "Entreprise a l'intention d'exporter dans les prochains 12 mois"

***********************************************************************
* 	PART 6: dummy une opération d'export			  										  
***********************************************************************
lab def oper_exp 1 "Opération d'export" 0 "Pas d'opération d'export"
encode rg_export, gen(rg_oper_exp)
replace rg_oper_exp = 0 if rg_oper_exp == 1
replace rg_oper_exp = 1 if rg_oper_exp == 2
drop rg_export
lab val rg_oper_exp oper_exp
lab var rg_oper_exp "Entreprise a realisé une opération d'export"

***********************************************************************
* 	PART 7: factor variable export status		  										  
***********************************************************************
encode rg_exportstatus, gen(rg_expstatus)
drop rg_exportstatus
lab var rg_expstatus "Régime d'export de l'entreprise"

***********************************************************************
* 	PART 7: labor and export labor productivity		  										  
***********************************************************************
gen exp_labor_productivity = ca_exp2020 / rg_fte
gen labor_productivity = ca_2020 / rg_fte



***********************************************************************
* 	PART 8: age
***********************************************************************
	* age
gen age = round((td(01feb2022)-date_created)/365.25,1)
order age, a(date_created)

	* year created
gen year_created = year(date_created), a(date_created)

***********************************************************************
* 	PART 8: dummy site web ou réseau social
***********************************************************************

gen presence_enligne = (rg_siteweb != "" | rg_media != ""), b(rg_siteweb)
lab def enligne 1 "présente enligne" 0 "ne pas présente enligne"
lab values presence_enligne enligne

***********************************************************************
* 	PART : chiffres d'affaires et chiffres d'affaires à l'export
***********************************************************************
	* change the units
/*
forvalues x = 2018(1)2020 {
	replace ca_`x' = ca_`x'/100000
	lab var ca_`x' "chiffres d'affaires `x' en 100.000"
	replace ca_exp`x' = ca_exp`x'/100000
	lab var ca_exp`x' "chiffres d'affaires export `x' en 100.000"
}
*/

format ca_* %12.2fc


	* generate average for 2018-2020
		* all three years
foreach x in ca_ ca_exp {
	egen `x'mean = rowmean(`x'2018 `x'2019 `x'2020)
}


* 1013 1066
***********************************************************************
* 	PART 10: eligibiliy dummy
***********************************************************************
		* eligibility criteria
gen pole = .
replace pole = 1 if subsector_corrige == 2
replace pole = 2 if subsector_corrige == 3 | subsector_corrige == 4
replace pole = 3 if subsector_corrige == 6 | subsector_corrige == 8
replace pole = 4 if subsector_corrige == 9

lab def pole 1 "agro-alimentaire" 2 "artisanat & cosmétique" 3 "service" 4 "TIC"
lab val pole pole
	
gen subsector_var = (pole < .)

replace rg_produitexp = 1 if rg_produitexp == .

gen eligible = (rg_intention == 1 & subsector_var == 1 & rg_gender_pdg == 1 & rg_resident == 1)
lab def eligible 1 "éligible" 0 "inéligible"
lab val eligible eligible

	    * eligibilite
replace eligible = 1 if id_plateforme == 1119
replace eligible = 1 if id_plateforme == 1218
replace eligible = 0 if id_plateforme == 1148
replace eligible = 1 if id_plateforme == 1117
replace eligible = 1 if id_plateforme == 1055
	

	* change to ineligible based on GIZ calls to verify the firms
foreach x in 1032 1053 1060 1078 1091 1145 1181 1187 1208 1212 1221 {
	replace eligible = 0 if id_plateforme == `x'
}


***********************************************************************
* 	PART 10: Surplus contact information from registration
***********************************************************************
	* show all the different duplicates that are also eligible (requires running gen.do first)
*browse if dup_firmname > 0 | dup_emailpdg > 0 & eligible_sans_matricule == 1

	* telephone numbers
/*
gen rg_telephone2 = ""
replace rg_telephone2 = "21698218074" if id_plateforme == 886
replace rg_telephone2 = "71380080" if id_plateforme == 190

		
	* email adresses
gen rg_email2 = ""
replace rg_email2 = "intissarmersni1987@gmail.com" if id_plateforme == 777
replace rg_email2 = "anoha.consulting@gmail.com" if id_plateforme == 886

	* physical adress
gen rg_adresse2 = ""
replace rg_adresse2 = "av ahmed mrad, cité des pins boumhel bassatine 2097" if id_plateforme == 497
replace rg_adresse2 = "rue de l'usine charguia2" if id_plateforme == 768
replace rg_adresse2 = "000, zi ettaamir, sousse 4003" if id_plateforme == 748

	* Other corrections
replace rg_position_rep= "senior consultant" if id_plateforme == 886

	* drop duplicates
drop if id_plateforme == 357
drop if id_plateforme == 610
drop if id_plateforme == 133

*Notes: 
*id_plateforme 398/414 are not duplicates (different companies belong to the same group)
*id_plateforme 503/515 are not duplicates (different companies belong to the same group)
*id_plateforme 658/675 are not duplicates (different companies belong to the same group)
*id_plateforme 205/274 are not duplicates (missing values)

*/


***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
	* set export directory
cd "$regis_intermediate"

	* save dta file
save "regis_inter", replace

