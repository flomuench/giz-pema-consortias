***********************************************************************
* 			        master do file, consortias			   	          *					  
***********************************************************************
*																	  
*	PURPOSE: master do file for replication from import to analysis 	
* 	of consortium registration data								  
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
set graphics off /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c


	* install packages
/* 
ssc install blindschemes, replace
ssc install groups, replace
ssc install ihstrans, replace
ssc install winsor2, replace
ssc install scheme-burd, replace
ssc install ranktest
net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
ssc install ivreg2, replace
ssc install estout, replace
ssc install coefplot, replace
*/

***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals
***********************************************************************
	* set first level globals for code and data
		* dynamic folder path to data


	* dynamic folder path for gdrive(data,output), github(code), backup(local computer)
	if c(os) == "Windows" {
	global master_gdrive = "C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/6-master"
	global master_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/master"
	global master_backup = "C:/Users/`c(username)'/Documents/consortia-back-up"
	global master_consortia_master ="C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
else if c(os) == "MacOSX" {
	global master_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/6-master"
	global master_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/master"
	global master_backup = "/Users/`c(username)'/Documents/consortia-back-up"
	global master_consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}

if c(os) == "Windows" {
	global bl_gdrive = "C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global bl_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/master"
	global bl_backup = "C:/Users/`c(username)'/Documents/consortia-back-up"
	global consortia_master ="C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
else if c(os) == "MacOSX" {
	global bl_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global bl_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/baseline"
	global bl_backup = "/Users/`c(username)'/Documents/consortia-back-up"
	global consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}

if c(os) == "Windows" {
	global regis_gdrive = "C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/1-registration"
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
global master_intermediate "${master_gdrive}/intermediate"
global master_final = "${master_gdrive}/final"
global master_checks = "${master_gdrive}/checks"
global master_output = "${master_gdrive}/output"

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
* 	PART 3: 	Run consortium do-files			  	 				  *
***********************************************************************
/*--------------------------------------------------------------------
	PART 3.1: Merge monitoring & pii data
----------------------------------------------------------------------*/		
if (1) do "${master_github}/merge.do"
/* --------------------------------------------------------------------
	PART 3.2: clean final raw registration + baseline 
----------------------------------------------------------------------*/		
if (1) do "${master_github}/master_clean.do"

/*
/* --------------------------------------------------------------------
	PART 3.3: Clean AQE intermediate data
----------------------------------------------------------------------*/
if (0) do "${aqe_github}/aqe_clean.do"
/* --------------------------------------------------------------------
	PART 3.4: Correct observations in AQE intermediate data
----------------------------------------------------------------------*/
if (0) do "${aqe_github}/aqe_correct.do"
/*--------------------------------------------------------------------
	PART 3.5: Generate variables in AQE intermediate data
----------------------------------------------------------------------*/
if (0) do "${aqe_github}/aqe_generate.do"


***********************************************************************
* 	PART 4: 	Run AQE analysis do-files
***********************************************************************
/* --------------------------------------------------------------------
	PART 4.1: Visualisations
----------------------------------------------------------------------*/		
if (0) do "${aqe_github}/aqe_visualisations.do"
/* --------------------------------------------------------------------
	PART 4.2: Regressions
----------------------------------------------------------------------*/
if (1) do "${aqe_github}/aqe_regressions.do"
