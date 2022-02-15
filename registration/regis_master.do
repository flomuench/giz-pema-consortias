***********************************************************************
* 			master do file registration, email experiment e-commerce 									  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible from first import to analysis
* 	for all team members & outsiders								  
*																	  
*	OUTLINE: 	PART 1: Set standard settings & install packages	  
*				PART 2: Prepare dynamic folder paths & globals		  
*				PART 3: Run all do-files                          
*																	  
*																	  
*	Author:  	Florian Münch							    
*	ID variable: id_email		  					  
*	Requires:  	  										  
*	Creates:  master-data-ecommerce; emailexperiment_population_regisle.dta		                                  
***********************************************************************
* 	PART 1: 	Set standard settings & install packages			  
***********************************************************************

	* set standard settings
version 15
clear all
graph drop _all
scalar drop _all
set more off
set graphics off /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c

	* install packages
	/*
ssc install ietoolkit /* for iebaltab */
ssc install randtreat, replace /* for randtreat --> random allocation */
ssc install blindschemes, replace /* for plotplain --> scheme for graphical visualisations */
net install http://www.stata.com/users/kcrow/tab2docx
ssc install betterbar
ssc install mdesc 
ssc install reclink
ssc install matchit
ssc install strgroup
ssc install stripplot
net install http://www.stata.com/users/kcrow/tab2docx
ssc install labutil
*/


	* define graph scheme for visual outputs
set scheme plotplain

***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals			  	  *
***********************************************************************

		* dynamic folder path for gdrive(data,output), github(code), backup(local computer)
if c(os) == "Windows" {
	global regis_gdrive = "C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/1-registration"
	global regis_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/registration"
	global regis_backup = "C:/Users/`c(username)'/Documents/consortia-back-up"
	global regis_data   = "C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data"

}
else if c(os) == "MacOSX" {
	global regis_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/1-registration"
	global regis_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/registration"
	global regis_backup = "/Users/`c(username)'/Documents/e-commerce-email-back-up"
	global regis_data   = "C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data"
}

		* paths within gdrive
			* data
global regis_raw = "${regis_gdrive}/raw"
global regis_intermediate "${regis_gdrive}/intermediate"
global regis_final = "${regis_gdrive}/final"
global regis_checks = "${regis_gdrive}/checks"


			* output (regression tables, figures)
global regis_output = "${regis_gdrive}/output"
global regis_figures = "${regis_output}/descriptive-statistics-figures"
global regis_progress = "${regis_output}/progress-eligibility-characteristics"

			
		* set seeds for replication
set seed 8413195
set sortseed 8413195
		

***********************************************************************
* 	PART 4: 	Run do-files for data cleaning & registration progress
***********************************************************************
/* --------------------------------------------------------------------
	PART 4.1: Import & raw data
----------------------------------------------------------------------*/		
if (1) do "${regis_github}/regis_import.do"
/* --------------------------------------------------------------------
	PART 4.2: Clean raw data & save as intermediate data
----------------------------------------------------------------------*/	
if (1) do "${regis_github}/regis_clean.do"
/* --------------------------------------------------------------------
	PART 4.3: Correct & save intermediate data
----------------------------------------------------------------------*/	
if (1) do "${regis_github}/regis_correct.do"
/* --------------------------------------------------------------------
	PART 4.4: Generate variables for analysis or implementation
----------------------------------------------------------------------*/	
if (1) do "${regis_github}/regis_generate.do"
/* --------------------------------------------------------------------
	PART 4.6: export open text or number variables for RA check
----------------------------------------------------------------------*/	
if (0) do "${regis_github}/regis_open_question_checks.do"
/* --------------------------------------------------------------------
	PART 4.7: Export pdf with number, characteristics & eligibility of registered firms
----------------------------------------------------------------------*/	
if (1) do "${regis_github}/regis_progress_eligibility_characteristics.do"
/* --------------------------------------------------------------------
	PART 4.7: Export pdf with number, characteristics & eligibility of registered firms
----------------------------------------------------------------------*/
if (0) do "${regis_github}/regis_test.do"
/* --------------------------------------------------------------------
	PART 4.8: De-identify and save as final for analysis
----------------------------------------------------------------------*/
if (0) do "${regis_github}/regis_deidentify.do"

