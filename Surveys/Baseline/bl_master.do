***********************************************************************
* 			master do file baseline survey, Export consortias				  *					  
***********************************************************************
*																	  
*	PURPOSE: make all data work reproducible from first import to analysis
* 	for all team members & outsiders								  
*																	  
*	OUTLINE: 	PART 1: Set standard settings & install packages	  
*				PART 2: Prepare dynamic folder paths & globals		  
*				PART 3: Run all do-files                          											  
*																	  
*	Author:  	Fabian Scheifele							    
*	ID variable: id_email		  					  
*	Requires:  	  										  
*	Creates:  master-data-consortias; 
***********************************************************************
* 	PART 1: 	Set standard settings & install packages			  
***********************************************************************

	* set standard settings
version 15
clear all
graph drop _all
scalar drop _all
set more off
set graphics on /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c

	* install packages
	/*
ssc install ietoolkit /* for iebaltab */
ssc install randtreat, replace /* for randtreat --> random allocation */
ssc install blindschemes, replace /* for plotplain --> scheme for graphic2al visualisations */
net install http://www.stata.com/users/kcrow/tab2docx
ssc install betterbar
ssc install mdesc 
ssc install reclink
ssc install matchit
ssc install strgroup
ssc install stripplot
net install http://www.stata.com/users/kcrow/tab2docx
ssc install labutil
ssc install asdoc
ssc install psmatch2
ssc install winsor
*/
*net from https://www.sealedenvelope.com/
*net install time.pkg

	* define graph scheme for visual outputs
set scheme plotplain

***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals			  	  *
***********************************************************************
		* define user
	if "`c(username)'" == "SIWAR" {
	global person =  "G:/.shortcut-targets-by-id/1bVknNNmRT3qZhosLmEQwPJeB-O24_QKT"
	} 
	
	else {
	global person = "C:/Users/`c(username)'/Google Drive" 
}
		* dynamic folder path for gdrive(data,output), github(code), backup(local computer)
if c(os) == "Windows" {
	global bl_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global bl_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/baseline"
	global bl_backup = "C:/Users/`c(username)'/Documents/consortia-back-up"
	global consortia_master ="${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data"
}
else if c(os) == "MacOSX" {
	global bl_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global bl_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/baseline"
	global bl_backup = "/Users/`c(username)'/Documents/consortia-back-up"
	global consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data"
}


if c(os) == "Windows" {
	global regis_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/1-registration"
	global regis_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/registration"
	global regis_backup = "C:/Users/`c(username)'/Documents/consortia-back-up"
}
else if c(os) == "MacOSX" {
	global regis_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/1-registration"
	global regis_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/registration"
	global regis_backup = "/Users/`c(username)'/Documents/consortia-back-up"
}

		* paths within gdrive
			* data
global bl_raw = "${bl_gdrive}/raw"
global bl_intermediate "${bl_gdrive}/intermediate"
global bl_final = "${bl_gdrive}/final"
global bl_checks = "${bl_gdrive}/checks"
global bl_output = "${bl_gdrive}/output"
global regis_raw = "${regis_gdrive}/raw"
global regis_intermediate "${regis_gdrive}/intermediate"
global regis_final = "${regis_gdrive}/final"
global regis_checks = "${regis_gdrive}/checks"

			* output (regression tables, figures)
global bl_output = "${bl_gdrive}/output"
global bl_figures = "${bl_output}/descriptive-statistics-figures"
global bl_progress = "${bl_output}/progress-eligibility-characteristics"


			* set seeds for replication
set seed 8413195
set sortseed 8413195
		

***********************************************************************

* 	PART 3: 	Run do-files for data cleaning & survey progress

***********************************************************************
/* --------------------------------------------------------------------
	PART 3.0: Import & raw data
----------------------------------------------------------------------*/		
if (1) do "${bl_github}/bl_import.do"
/* --------------------------------------------------------------------
	PART 3.1: Clean raw data & save as intermediate data
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_clean.do"
/* --------------------------------------------------------------------
	PART 3.2: Match to registration data
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_match.do"
/* --------------------------------------------------------------------
	PART 3.3: Correct & save intermediate data
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_correct.do"
/* --------------------------------------------------------------------
	PART 3.4: Generate variables for analysis or implementation
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_generate.do"
/* --------------------------------------------------------------------
	PART 3.5: export open text or number variables for RA check
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_open_question_checks.do"
/* --------------------------------------------------------------------
	PART 3.6: Perform logical checks
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_test.do"
/* --------------------------------------------------------------------
	PART 3.8: Export pdf with descriptive statistics on responses
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_statistics.do"
/* --------------------------------------------------------------------
	PART 3.9: Diagnostic
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_diagnostic.do"


/* --------------------------------------------------------------------
	PART 4.1: Stratification 
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_stratification.do"
/* --------------------------------------------------------------------
	PART 4.2: Randomisation 
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_randomisation_tests.do"
/* --------------------------------------------------------------------
	PART 4.3: Randomisation 
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_final_randomisation.do"

/* --------------------------------------------------------------------
	PART 4.4: Create indices
----------------------------------------------------------------------*/	
if (1) do "${bl_github}/bl_index.do"
