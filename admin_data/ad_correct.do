***********************************************************************
* 			AQE adminstrative data corrections	  
***********************************************************************
*																	    
*	PURPOSE: Correct erroneous numerical variables' values					  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Load data  			  				  
* 	2) 		Automatic corrections
*	3)   	Encode categorical variables							  
*	4)  	Convert string to numerical variables				  
* 	5)     Save the changes made to the data			
*				      
*	Authors:  	Florian Muench & Amira Bouziri & Kaïs Jomaa & Ayoub Chamakhi 
*										  
*	ID variable: 	id (example: f101)			  					  
*	Requires: ad_intermediate.dta 	  								  
*	Creates:  ad_intermediate.dta			                          
*																	  
***********************************************************************
* 	PART 1:  Load data & Define non-response categories  			
***********************************************************************
use "${intermediate}/rct_rne_inter", clear
	
		* locals for numerical variables
local numvar ca_export_dt ca_local_dt resultatall_dt ca_ttc_dt total_wage moyennes export_value export_weight import_value import_weight net_job_creation
local numvarc  ca_export_dt ca_local_dt resultatall_dt ca_ttc_dt total_wage moyennes export_value export_weight import_value import_weight net_job_creation


***********************************************************************
* 	PART 2:  Automatic corrections
***********************************************************************



***********************************************************************
* 	PART 4:  Convert string to numerical variables after corrections  			
***********************************************************************
foreach x of local numvar {
destring `x', replace
format `x' %25.0fc
}

***********************************************************************
* 	PART 5: Save the changes made to the data		  			
***********************************************************************
save "${intermediate}/rct1_rne_inter", replace


  
