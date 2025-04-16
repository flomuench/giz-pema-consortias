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
*	Author:  	Florian Münch, Fabian Scheifele							    
*	ID variable: id_plateforme (id for firms), surveyround (panel time id)
***********************************************************************
* 	PART 1: 	Set standard settings & install packages			  
***********************************************************************
{	
	* set standard settings
version 15
clear all
graph drop _all
scalar drop _all
set more off
set varabbrev off // stops stata from referring to variables if only one part is the same
set graphics off /* switch off to on to display graphs */
capture program drop zscore /* drops the program programname */
qui cap log c

graph set window fontface "Times New Roman" // set font type in line with Latex document



*test 

	* install packages
/*
ssc install blindschemes, replace
ssc install groups, replace
ssc install ihstrans, replace
ssc install winsor2, replace
ssc install ietoolkit, replace
ssc install scheme-burd, replace
ssc install ranktest, replace
net install cleanplots, from("https://tdmize.github.io/data/cleanplots")
ssc install ivreg2, replace
ssc install estout, replace
ssc install coefplot, replace
ssc install missingplot, replace
ssc install nmissing, replace
ssc install reghfde, replace

	* if there are issues on new computer with ivreg2, error code: vcvorthog, execute the following:
	
   capture mata: mata drop m_calckw()
        capture mata: mata drop m_omega()
        capture mata: mata drop ms_vcvorthog()
        capture mata: mata drop s_vkernel()
        mata: mata mlib index

*/

	* set scheme for visualisations
set scheme burd 			// for presentation, coloured
* set scheme plotplain 		// for publication/paper, black/white

}

***********************************************************************
* 	PART 2: 	Prepare dynamic folder paths & globals
***********************************************************************
{
	* set first level globals for code and data
		* define user
	if "`c(username)'" == "amira.bouziri" |"`c(username)'" == "Admin" | ///
	"`c(username)'"  == "fabi-"| "`c(username)'" == "my rog" | ///
	"`c(username)'" == "ayoub" | "`c(username)'" == "Azra" | "`c(username)'" == "Guest"  {
	global person =  "G:/.shortcut-targets-by-id/1bVknNNmRT3qZhosLmEQwPJeB-O24_QKT"
	} 
	
	else if "`c(username)'" == "MUNCHFA" {
		global person = "G:/My Drive"
	}
	
	else if "`c(username)'" == "fmuench" {
		global person = "C:/Users/fmuench/Documents"
	}
	
	else {
	global person = "G:/Meine Ablage" 
}


	* dynamic folder path for gdrive(data,output), github(code)
	if c(os) == "Windows" {
	global github 		 = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias"
	global master_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/6-master"
	global master_github = "${github}/master"
	global master_consortia_master ="C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
else if c(os) == "MacOSX" {
	global github 		 = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias"
	global master_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/6-master"
	global master_github = "${github}/master"
	global master_consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}

		* ado-files
global ado_files = "${github}/ado_files"
sysdir set PLUS "${ado_files}"					// changes system directory for ado-files to local folder with ado categories

		* registration folder
if c(os) == "Windows" {
	global regis_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/1-registration"
	global regis_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/registration"
}
else if c(os) == "MacOSX" {
	global regis_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/1-registration"
	global regis_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/registration"
}

		* baseline folder
if c(os) == "Windows" {
	global bl_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global bl_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/master"
	global consortia_master ="C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
else if c(os) == "MacOSX" {
	global bl_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/2-baseline"
	global bl_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/baseline"
	global consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
		* midline folder
if c(os) == "Windows" {
	global ml_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/3-midline"
	global ml_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/master"
	global consortia_master ="C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
else if c(os) == "MacOSX" {
	global ml_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/3-midline"
	global ml_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/midline"
	global consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
		* endline folder
if c(os) == "Windows" {
	global el_gdrive = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/4-endline"
	global el_github = "C:/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/master"
	global consortia_master ="C:/Users/`c(username)'/Google Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}
else if c(os) == "MacOSX" {
	global el_gdrive = "/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/4-endline"
	global el_github = "/Users/`c(username)'/Documents/GitHub/giz-pema-consortias/surveys/endline"
	global consortia_master ="/Volumes/GoogleDrive/My Drive/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/"
}

* paths within gdrive
			* data
				* master
global master_intermediate "${master_gdrive}/intermediate"
global master_final = "${master_gdrive}/final"
global master_checks = "${master_gdrive}/checks"
global master_raw = "${master_gdrive}/raw"
global implementation = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/7-implementation"
global map = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/8-geolocation"
global harmonize = "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/data/9-harmonize"

                 *Endline
global el_raw = "${el_gdrive}/raw"
global el_intermediate "${el_gdrive}/intermediate"
global el_final = "${el_gdrive}/final"
global el_checks = "${el_gdrive}/checks"

				* midline
global ml_raw = "${ml_gdrive}/raw"
global ml_intermediate "${ml_gdrive}/intermediate"
global ml_final = "${ml_gdrive}/final"
global ml_checks = "${ml_gdrive}/checks"
				* baseline
global bl_raw = "${bl_gdrive}/raw"
global bl_intermediate "${bl_gdrive}/intermediate"
global bl_final = "${bl_gdrive}/final"
global bl_checks = "${bl_gdrive}/checks"

				* registration
global regis_raw = "${regis_gdrive}/raw"
global regis_intermediate "${regis_gdrive}/intermediate"
global regis_final = "${regis_gdrive}/final"
global regis_checks = "${regis_gdrive}/checks"

			* output (regression tables, figures)
				* baseline
global bl_output = "${bl_gdrive}/output"
global bl_figures = "${bl_output}/descriptive-statistics-figures"
global bl_progress = "${bl_output}/progress-eligibility-characteristics"

				* midline
global ml_output = "${ml_gdrive}/output"
global ml_figures = "${ml_output}/descriptive-statistics-figures"
global ml_progress = "${ml_output}/progress-eligibility-characteristics"

            	* endline
global el_output = "${el_gdrive}/output"
global el_figures = "${el_output}/descriptive-statistics-figures"
global el_progress = "${el_output}/progress-eligibility-characteristics"

				* map
global map_raw = "${map}/raw"
global map_output = "${map}/output"

				* master
global master_output =  "${person}/Research_GIZ_Tunisia_exportpromotion/1. Intervention III – Consortia/output"
global master_power = "${master_output}/power"
global master_regressiontables = "${master_output}/tables"
global master_figures = "${master_output}/figures"

* paths for latex paper (hosted on Github, synchronized with Overleaf)
if c(os) == "Windows" {
	global master_latex = "C:/Users/`c(username)'/Documents/GitHub/cf_paper"
			global figures_latex = "${master_latex}/Figures"
				global figures_confidence = "${figures_latex}/Empowerment"
				global figures_exports = "${figures_latex}/Exports"
				global figures_management = "${figures_latex}/Management Practices"
				global figures_network = "${figures_latex}/network"
				global figures_business = "${figures_latex}/compta"
				global figures_innovation = "${figures_latex}/innovation"
				global figures_attrition = "${figures_latex}/attrition"
				
				
			global tables_latex = "${master_latex}/Tables"
				global tables_confidence = "${tables_latex}/empowerment"
				global tables_exports = "${tables_latex}/export"
				global tables_kt = "${tables_latex}/knowledge_transfer"
				global tables_take_up = "${tables_latex}/take-up"
				global tables_network = "${tables_latex}/network"
				global tables_descriptives = "${tables_latex}/descriptives"
				global tables_business = "${tables_latex}/business"
				global tables_peer = "${tables_latex}/peer"
				global tables_attrition = "${tables_latex}/attrition"

}


		
			* set seeds for replication
set seed 8413195
set sortseed 8413195
		
}

***********************************************************************
* 	PART 3: 	Run consortium do-files			  	 				  *
***********************************************************************
{
/*--------------------------------------------------------------------
	PART 3.1: Merge monitoring & pii data
----------------------------------------------------------------------*/		
if (1) do "${master_github}/consortia_merge.do"
/*--------------------------------------------------------------------
	PART 3.2: List experiment randomization for midline + endline
	Creates: consortia_pii_inter
----------------------------------------------------------------------*/
if (1) do "${master_github}/consortia_list_experiment.do"
/* --------------------------------------------------------------------
	PART 3.3: Clean intermediate data
----------------------------------------------------------------------*/
if (1) do "${master_github}/consortia_clean.do"
/* --------------------------------------------------------------------
	PART 3.4: Correct intermediate data
----------------------------------------------------------------------*/
if (1) do "${master_github}/consortia_correct.do"
/*--------------------------------------------------------------------
	PART 3.5: Generate variables
	Creates: Final analysis & pii data set
----------------------------------------------------------------------*/
if (1) do "${master_github}/consortia_generate.do"
/*--------------------------------------------------------------------
	PART 3.6: Baseline power
----------------------------------------------------------------------*/		
if (0) do "${master_github}/consortia_power.do"
/*--------------------------------------------------------------------
	PART 3.7: Exports a list of participants with most important info (for survey institute or political partners)
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_export.do"
/*--------------------------------------------------------------------
	PART 3.8: Test coherence between survey rounds for midline
	Creates: fiche_de_correction
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_test_ml.do"
/*--------------------------------------------------------------------
	PART 3.9: Test coherence between survey rounds for endline
	Creates: fiche_de_correction
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_test_el.do"
/*--------------------------------------------------------------------
	PART 3.10: Creates a list of firms to recall
	Creates: fiche_d'appel
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_appel_el.do"
}

***********************************************************************
* 	PART 4: 	Run consortia analysis do-files
***********************************************************************
/* --------------------------------------------------------------------
	PART 4.1: Visualisations
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_visualisations_bl.do"
if (0) do "${master_github}/consortia_visualisations_ml.do"
if (0) do "${master_github}/consortia_visualisations_el.do"
/* --------------------------------------------------------------------
	PART 4.2: Regressions midline
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_regressions_ml.do"
/* --------------------------------------------------------------------
	PART 4.3: Regressions endline
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_regressions_el.do"
/* --------------------------------------------------------------------
	PART 4.2: Regressions midline
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_heterogeneity_ml.do"
/* --------------------------------------------------------------------
	PART 4.3: Regressions endline
----------------------------------------------------------------------*/
if (0) do "${master_github}/consortia_heterogeneity_el.do"

***********************************************************************
* 	PART 5: 	Run master map
***********************************************************************
if (0) do "${master_github}/master_map.do"
