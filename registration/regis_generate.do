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
label define sector_name 1 "Agriculture & Peche" ///
	2 "Artisanat" ///
	3 "Commerce international" ///
	4 "Industrie" ///
	5 "Services" ///
	6 "TIC" 

label define subsector_name 1 "agriculture" ///
	2 "architecture" ///
	3 "artisanat" ///
	4 "assistance" ///
	5 "audit" ///
	6 "autres" ///
	7 "centre d'appel" ///
	8 "commerce international" ///
	9 "développement informatique" ///
	10 "enseignement" ///
	11 "environnement et formation" ///
	12 "industries diverses" ///
	13 "industries mécaniques et électriques" ///
	14 "industries agro-alimentaires" ///
	15 "industries chimiques" ///
	16 "industries des matériaux de construction, de la céramique et du verre" ///
	17 "industries du cuir et de la chaussure" ///
	18 "industries du textile et de l'habillement" ///
	19 "pêche" ///
	20 "réseaux et télécommunication" ///
	21 "services et études dans le domaine de batîment"

tempvar Sector
encode sector, gen(`Sector')
drop sector
rename `Sector' sector
lab values sector sector_name

tempvar Subsector
encode subsector, gen(`Subsector')
drop subsector
rename `Subsector' subsector
lab values subsector subsector_name


format %-25.0fc *sector

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
* 	PART 8: age
***********************************************************************
gen rg_age = round((td(30nov2021)-date_created)/365.25,2)
order rg_age, a(date_created)

***********************************************************************
* 	PART 8: dummy site web ou réseau social
***********************************************************************
gen presence_enligne = (rg_siteweb != "" | rg_media != ""), b(rg_siteweb)
lab def enligne 1 "présente enligne" 0 "ne pas présente enligne"
lab values presence_enligne enligne

***********************************************************************
* 	PART 10: eligibiliy dummy
***********************************************************************
gen eligible = (id_admin_correct == 1 & rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_oper_exp == 1 & rg_age>=2)
lab def eligible 1 "éligible" 0 "inéligible"
lab val eligible eligible

		* eligible if matricule fiscal is corrected
gen eligible_sans_matricule = (rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_oper_exp == 1 & rg_age>=2)
lab def eligible2 1 "éligible sans matricule" 0 "inéligible sans matricule"
lab val eligible_sans_matricule eligible2

		* alternative definition of eligibility
			* intention to export rather than one export operation
gen eligible_alternative = (rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_age>=2)
lab val eligible_alternative eligible

		* eligibility including also no webpage or social network
gen eligible_presence_enligne = (presence_enligne == 1 & id_admin_correct == 1 & rg_resident == 1 & rg_fte >= 6 & rg_fte <= 199 & rg_produitexp == 1 & rg_intention == 1 & rg_oper_exp == 1 & rg_age>=2)
lab def eligible_enligne 1 "éligible avec présence en ligne" 0 "éligible sans présence en ligne"
lab val eligible_presence_enligne eligible_enligne


***********************************************************************
* 	PART 10: Surplus contact information from registration
***********************************************************************
	* show all the different duplicates that are also eligible (requires running gen.do first)
*browse if dup_firmname > 0 | dup_emailpdg > 0 & eligible_sans_matricule == 1

	* telephone numbers

gen rg_telephone2 = ""
replace rg_telephone2 = "21698218074" if id_plateforme == 886
replace rg_telephone2 = "71380080" if id_plateforme == 190
replace rg_telephone2 = "29610014" if id_plateforme == 602
replace rg_telephone2 = "29352797" if id_plateforme == 724
replace rg_telephone2 = "29352797" if id_plateforme == 547
replace rg_telephone2 = "53115533" if id_plateforme == 640
replace rg_telephone2 = "20445577" if id_plateforme == 157
replace rg_telephone2 = "24813364" if id_plateforme == 122
replace rg_telephone2 = "20727887" if id_plateforme == 238
replace rg_telephone2 = "29753145" if id_plateforme == 833
replace rg_telephone2 = "29522462" if id_plateforme == 98
replace rg_telephone2 = "92554016" if id_plateforme == 521
replace rg_telephone2 = "29360507" if id_plateforme == 451
replace rg_telephone2 = "58440115" if id_plateforme == 315
replace rg_telephone2 = "23268260" if id_plateforme == 546
replace rg_telephone2 = "71409236" if id_plateforme == 254
replace rg_telephone2 = "51799006" if id_plateforme == 785
replace rg_telephone2 = "50163772" if id_plateforme == 340	
replace rg_telephone2 = "29333280" if id_plateforme == 725
replace rg_telephone2 = "98774548" if id_plateforme == 768
replace rg_telephone2 = "28841100" if id_plateforme == 748	
replace rg_telephone2 = "29210384" if id_plateforme == 658	
		
	* email adresses
gen rg_email2 = ""
replace rg_email2 = "intissarmersni1987@gmail.com" if id_plateforme == 777
replace rg_email2 = "anoha.consulting@gmail.com" if id_plateforme == 886
replace rg_email2 = "karim.architecte@yahoo.fr" if id_plateforme == 673
replace rg_email2 = "ccf.jeridi@planet.tn" if id_plateforme == 630
replace rg_email2 = "majdi.ameur@colmar.tn" if id_plateforme == 602
replace rg_email2 = "nejla.khadraoui@fameinternational.tn" if id_plateforme == 771
replace rg_email2 = "bilel.ghediri@allianceone.tn" if id_plateforme == 724
replace rg_email2 = "alaeddine.reguii@emcgroup.tn" if id_plateforme == 547
replace rg_email2 = "slim.tounsi@texpro-kgroup.com.tn" if id_plateforme == 564
replace rg_email2 = "eya.bs.bensalem@gmail.com" if id_plateforme == 157
replace rg_email2 = "ramzihamdi.ab@gmail.com" if id_plateforme == 801
replace rg_email2 = "emnacheikrouhou1@gmail.com" if id_plateforme == 122
replace rg_email2 = "benslimenjihed@gmail.com" if id_plateforme == 238	
replace rg_email2 = "harizisondes@gmail.com" if id_plateforme == 783		
replace rg_email2 = "saima.bousselmi@medivet.com.tn" if id_plateforme == 833	
replace rg_email2 = "sondeble@yahoo.fr" if id_plateforme == 762
replace rg_email2 = "a.abeidi@plastiform.com.tn" if id_plateforme == 98	
replace rg_email2 = "walid.elbenna@cuisina.com" if id_plateforme == 521	
replace rg_email2 = "110709ns@gmail.com" if id_plateforme == 451		
replace rg_email2 = "rh@portyasmine.com.tn" if id_plateforme == 408
replace rg_email2 = "commerciale@mahamoden.com.tn" if id_plateforme == 315
replace rg_email2 = "hana.hakim@outlook.com" if id_plateforme == 658
replace rg_email2 = "sami.habbachi.28@gmail.com" if id_plateforme == 754
replace rg_email2 = "hassen.bt@oliveoiltunisia.com" if id_plateforme == 546	
replace rg_email2 = "meskini.sihem@live.fr" if id_plateforme == 654
replace rg_email2 = "o.chamakhi@tuniship.net" if id_plateforme == 757
replace rg_email2 = "oriwoodtn@gmail.com" if id_plateforme == 865	
replace rg_email2 = "nourmedini76@gmail.com" if id_plateforme == 785
replace rg_email2 = "shayma.rahmeni@smarteo.tn" if id_plateforme == 340
replace rg_email2 = "azizaglass1@gmail.com" if id_plateforme == 725
replace rg_email2 = "asma.besbes2018@gmail.com" if id_plateforme == 768
replace rg_email2 = "lilnvfgng@gmail.com" if id_plateforme == 748
replace rg_email2 = "mouna.guermazi@soteca.com.tn" if id_plateforme == 658


	

	
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
drop if id_plateforme == 149
drop if id_plateforme == 809
drop if id_plateforme == 468
drop if id_plateforme == 605
drop if id_plateforme == 828
drop if id_plateforme == 684
drop if id_plateforme == 534
drop if id_plateforme == 639
drop if id_plateforme == 638
drop if id_plateforme == 641
drop if id_plateforme == 622
drop if id_plateforme == 621
drop if id_plateforme == 585
drop if id_plateforme == 159
drop if id_plateforme == 502
drop if id_plateforme == 881
drop if id_plateforme == 607
drop if id_plateforme == 236
drop if id_plateforme == 249
drop if id_plateforme == 835
drop if id_plateforme == 907
drop if id_plateforme == 362
drop if id_plateforme == 100
drop if id_plateforme == 173
drop if id_plateforme == 750
drop if id_plateforme == 348
drop if id_plateforme == 314
drop if id_plateforme == 659
drop if id_plateforme == 685
drop if id_plateforme == 272
drop if id_plateforme == 653
drop if id_plateforme == 811
drop if id_plateforme == 342
drop if id_plateforme == 155
drop if id_plateforme == 171
drop if id_plateforme == 278
drop if id_plateforme == 654
drop if id_plateforme == 817
drop if id_plateforme == 751
drop if id_plateforme == 775

*Notes: 
*id_plateforme 398/414 are not duplicates (different companies belong to the same group)
*id_plateforme 503/515 are not duplicates (different companies belong to the same group)
*id_plateforme 658/675 are not duplicates (different companies belong to the same group)
*id_plateforme 205/274 are not duplicates (missing values)


***********************************************************************
* 	Save the changes made to the data		  			
***********************************************************************
	* set export directory
cd "$regis_intermediate"

	* export file with potentially eligible companies
gen check = 0
replace check = 1 if id_admin_correct == 0 | presence_enligne == 0

preserve
	keep if eligible_sans_matricule == 1
	rename rg_siteweb site_web 
	rename rg_media reseaux_sociaux
	rename id_admin matricule_fiscale
	rename rg_resident onshore
	rename rg_fte employes
	rename rg_produitexp produit_exportable
	rename rg_intention intention_export
	rename rg_oper_exp operation_export
	rename date_created_str date_creation
	rename firmname nom_entreprise
	rename rg_codedouane code_douane
	rename rg_matricule matricule_cnss
	order nom_entreprise date_creation matricule_fiscale code_douane matricule_cnss operation_export 
	local varlist "nom_entreprise date_creation matricule_fiscale code_douane matricule_cnss operation_export site_web reseaux_sociaux onshore employes produit_exportable intention_export"
	export excel `varlist' using ecommerce_eligibes_pme if eligible_sans_matricule == 1, firstrow(var) replace
restore

	* save dta file
save "regis_inter", replace
