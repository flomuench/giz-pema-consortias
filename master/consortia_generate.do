***********************************************************************
* 			consortia master do files: generate variables  
***********************************************************************
*																	  
*	PURPOSE: create variables based on merged data			  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*
*				PART II: Analysis data
*					PART 3: 
*																	  
*	Author:  	Fabian Scheifele & Siwar Hakim							    
*	ID variable: id_email		  					  
*	Requires:  	 regis_final.dta bl_final.dta 										  
*	Creates:     regis_final.dta bl_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************	
***********************************************************************
* 	PART 1:    clean & correct consortium contact_info	  
***********************************************************************
use "${master_gdrive}/contact_info_master", clear

***********************************************************************
* 	PART II.1:  generate dummy account contact information missing
***********************************************************************


***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
use "${master_raw}/consortium_raw", clear

***********************************************************************
* 	PART II.1:  generate take-up variable
***********************************************************************
	*  label variables from participation "presence_ateliers"
gen launching_event =.
replace launching_event= 1 if Webinaire_de_lancement == "Présente " & treatment == 1
replace launching_event= 1 if Webinaire_de_lancement == "présente" & treatment == 1
replace launching_event= 0 if Webinaire_de_lancement == "absente" & treatment == 1

gen workshop1_1 =.
replace workshop1_1= 1 if Rencontre1_Atelier1 == "Présente " & treatment == 1
replace workshop1_1= 1 if Rencontre1_Atelier1 == "présente" & treatment == 1
replace workshop1_1= 0 if Rencontre1_Atelier1 == "absente" & treatment == 1

gen workshop1_2 =.
replace workshop1_2= 1 if Rencontre1_Atelier2 == "Présente " & treatment == 1
replace workshop1_2= 1 if Rencontre1_Atelier2 == "présente" & treatment == 1
replace workshop1_2= 0 if Rencontre1_Atelier2 == "absente" & treatment == 1

gen workshop2_1 =.
replace workshop2_1= 1 if Rencontre2_Atelier1 == "Présente " & treatment == 1
replace workshop2_1= 1 if Rencontre2_Atelier1 == "présente" & treatment == 1
replace workshop2_1= 0 if Rencontre2_Atelier1 == "absente" & treatment == 1

gen workshop2_2 =.
replace workshop2_2= 1 if Rencontre2_Atelier2 == "Présente " & treatment == 1
replace workshop2_2= 1 if Rencontre2_Atelier2 == "présente" & treatment == 1
replace workshop2_2= 0 if Rencontre2_Atelier2 == "absente" & treatment == 1

gen workshop3_1 =.
replace workshop3_1= 1 if Rencontre3_Atelier1 == "Présente " & treatment == 1
replace workshop3_1= 1 if Rencontre3_Atelier1 == "présente" & treatment == 1
replace workshop3_1= 0 if Rencontre3_Atelier1 == "absente" & treatment == 1

gen workshop3_2 =.
replace workshop3_2= 1 if Rencontre3_Atelier2 == "Présente " & treatment == 1
replace workshop3_2= 1 if Rencontre3_Atelier2 == "présente" & treatment == 1
replace workshop3_2= 0 if Rencontre3_Atelier2 == "absente" & treatment == 1

lab def presence_status 0 "Absent" 1 "Present" 
lab values launching_event workshop1_1 workshop1_2 workshop2_1 workshop2_2 workshop3_1 workshop3_2 presence_status

drop Webinaire_de_lancement Rencontre1_Atelier1 Rencontre1_Atelier2 Rencontre2_Atelier1 Rencontre2_Atelier2 Rencontre3_Atelier1 Rencontre3_Atelier2

* Create take-up percentage per firm

***********************************************************************
* 	PART II.2:    Create missing variables for accounting number			  
***********************************************************************
gen profit_2021_missing=0
replace profit_2021_missing= 1 if profit_2021==.
replace profit_2021_missing= 1 if profit_2021==0

gen ca_2021_missing =0
replace ca_2021_missing= 1 if ca_2021==.
replace ca_2021_missing= 1 if ca_2021==0

gen ca_exp_2021_missing=0
replace ca_exp_2021_missing= 1 if ca_exp_2021==.



***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_final}/consortium_final", replace