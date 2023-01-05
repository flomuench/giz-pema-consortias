***********************************************************************
* 			Descriptive Statistics in master file with different survey rounds*					  
***********************************************************************
*																	  
*	PURPOSE: Understand the structure of the data from the different surveyr.					  
*																	  
*	OUTLINE: 	PART 1: Baseline and take-up
*				PART 2: Mid-line	  
*				PART 3: Endline 
*				PART 4: Intertemporal descriptive statistics															
*																	  
*	Authors:  	Florian Münch, Kaïs Jomaa, Ayoub Chamakhi & Amina Bousnina						    
*	ID variable: id_platforme		  					  
*	Requires:  	 ecommerce_data_final.dta

										  
***********************************************************************
* 	PART 1: Baseline and take-up statistics
***********************************************************************
use "${master_final}/consortia_master_final", clear
		
		* change directory to regis folder for merge with regis_final
cd "${master_gdrive}/output"



