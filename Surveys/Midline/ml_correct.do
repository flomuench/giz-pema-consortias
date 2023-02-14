***********************************************************************
* 			consortias midline survey corrections                    *	
***********************************************************************
*																	    
*	PURPOSE: correct all incoherent responses				  							  
*																	  
*																	  
*	OUTLINE:														  
*	1)		Import data
*	2)	    Define non-response categories 		
*   3)		Use regular expressions to correct variables	  				  
* 	4) 		Manual correction (by variable not by row)
*	4)   	Replace string with numeric values						  
*	5)  	Convert data types to the appropriate format	  				  
*	6)  	autres / miscellaneous adjustments		  
*	7)		Destring remaining numerical vars
*	8)		Save the changes made to the data
*
*																	  															      
*	Author:  	Ayoub Chamakhi, Kais Jomaa, Amina Bousnina		 														  
*	ID variaregise: id_plateforme			  					  
*	Requires: ml_intermediate.dta 	  								  
*	Creates:  ml_intermediate.dta			                          
*	
																  
***********************************************************************
* 	PART 1:  Import data 			
***********************************************************************
use "${ml_intermediate}/ml_intermediate", clear

***********************************************************************
* 	PART 2:  Define non-response categories	 			
***********************************************************************

{
	* replace "-" with missing value
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
		replace `x' = "" if `x' == "-"
	}
	
scalar not_know    = -999
scalar refused     = -888

local not_know    = -999
local refused     = -888

	* replace, gen, label
gen check_again = 0
gen questions_needing_checks = ""
}

***********************************************************************
* 	PART 1.2:  Identify and remove duplicates 
***********************************************************************
sort id_plateforme heure
quietly by id_plateforme heure:  gen dup = cond(_N==1,0,_n)
drop if dup>1

/*duplicates report id_plateforme heuredébut
duplicates tag id_plateforme heuredébut, gen(dup)
drop if dup>1
*/


*Individual duplicate drops (where heure debut is not the same). If the re-shape
*command in bl_test gives an error it is because there are remaining duplicates,
*please check them individually and drop (actually el-amouri is supposed to that)
*drop if id_plateforme==1239 & heuredébut=="16:02:55"

*restore original order
*sort date heuredébut

***********************************************************************
* 	PART 3:  Automatic corrections
***********************************************************************
*2.1 Remove commas, dots, dt and dinar Turn zero, zéro into 0 for all numeric vars


	* amouri frogot to mention that 999 needs to have a - before in case of don't know
local 999vars ca ca_exp profit 
foreach var of local 999vars {
	replace `var' = "-999" if `var' == "999"
	replace `var' = "-888" if `var' == "888"
}

	* make manual changes
		* ca
replace ca="2600000" if ca=="deux milliards 600dt" 
replace ca="15000" if ca=="15milles dt"
replace ca="40000" if ca=="entre 30000 et 50000" // "moyenne"
replace ca="1300000" if id_plateforme == 991 // entreprise totalement exportatrice
replace ca="90000" if id_plateforme == 1000
replace ca="1000000" if id_plateforme == 1001   //	"un million de dinars"
replace ca="60000" if id_plateforme == 1010   
replace ca="95659" if id_plateforme == 1013
replace ca="700000" if id_plateforme == 1017
replace ca="3300000" if id_plateforme == 1027   
replace ca= "491233" if id_plateforme == 1028                                               
replace ca="1000000" if id_plateforme == 1033  	//	"plus d'un milliards de dinar"
replace ca="397358" if id_plateforme == 1049    // "120000 euros converti en dinars selon le cours du 31.01.2023"
replace ca="0" if id_plateforme == 1036 
replace ca="5000" if id_plateforme == 1133
replace ca="70000" if id_plateforme == 1146 
replace ca="1500000" if id_plateforme == 1147   
replace ca="16000" if id_plateforme == 1154
replace ca="32000" if id_plateforme == 1155
replace ca="-999" if id_plateforme == 1161
replace ca="-999" if id_plateforme == 1179
replace ca="150000" if id_plateforme == 1184
replace ca="14000" if id_plateforme == 1185
replace ca="4000" if id_plateforme == 1190
replace ca="1285000" if id_plateforme == 1195   
replace ca="15000" if id_plateforme == 1201

replace ca="700000" if id_plateforme == 1017
replace ca="0" if id_plateforme == 1083
replace ca="1600000" if id_plateforme == 1087
replace ca="4376000" if id_plateforme == 1119
replace ca="102000" if id_plateforme == 1153
replace ca="75000" if id_plateforme == 1159




replace ca="182000" if id_plateforme == 1239
replace ca="25000" if id_plateforme == 1242
replace ca="2000000" if id_plateforme == 1243
replace ca="300000" if id_plateforme == 1043
replace ca="1400000" if id_plateforme == 1240


		* profit
replace profit="27000" if id_plateforme == 1000		//    30% of total turnover
replace profit="300000" if id_plateforme == 1001		//    30% of total turnover
replace profit="2200" if id_plateforme == 1005		//    10% of total turnover
replace profit= "-999" if id_plateforme == 1010
replace profit= "7000" if id_plateforme == 1013 
replace profit="400000" if id_plateforme == 1027 
replace profit= "-999" if id_plateforme == 1028                                            
replace profit="-1000" if id_plateforme == 1133 	
replace profit="25000" if id_plateforme == 1188 	 //	   10% of total turnover
replace profit="-24000" if id_plateforme == 1035     //   -60% of total turnover
replace profit="375000" if id_plateforme == 1170     //    25% of total turnover
replace profit="108000" if id_plateforme == 1163     //    45% of total turnover
replace profit="119207" if id_plateforme == 1049   //    30% of total turnover
replace profit="300000" if id_plateforme == 1008     //    25% of total turnover
replace profit="-4450" if id_plateforme == 1031     //     -50% of total turnover
replace profit="-60000" if id_plateforme == 1041
replace profit="210000" if id_plateforme == 1045
replace profit="-17000" if id_plateforme == 1054
replace profit="4700" if id_plateforme == 1055		//    5% of total turnover
replace profit="192000" if id_plateforme == 1117    //    32% of total turnover
replace profit="27000" if id_plateforme == 1135		//    30% of total turnover
replace profit="40000" if id_plateforme == 1146
replace profit="375000" if id_plateforme == 1147    //    25% of total turnover
replace profit= "-999" if id_plateforme == 1151
replace profit="2000" if id_plateforme == 1154
replace profit="17000" if id_plateforme == 1155    
replace profit="-999" if id_plateforme == 1161
replace profit="-999" if id_plateforme == 1179
replace profit="-20000" if id_plateforme == 1183
replace profit="60000" if id_plateforme == 1043
replace profit="150000" if id_plateforme == 1087
replace profit="7500" if id_plateforme == 1210		// 30% of total turnover
replace profit="420000" if id_plateforme == 1240 	// 30% of total turnover
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
replace profit="30000" if id_plateforme == 1184                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
replace profit="2500" if id_plateforme == 1190
replace profit="0" if id_plateforme == 1195                                                                            
replace profit= "-999" if id_plateforme == 1201     

replace profit= "60000" if id_plateforme == 1043 
replace profit= "150000" if id_plateforme == 1087
replace profit= "-150000" if id_plateforme == 1119
replace profit="-12200" if id_plateforme == 1153	 //   -10% of total turnover
replace profit= "-45000" if id_plateforme == 1159
replace profit="7500" if id_plateforme == 1210       //    30% of total turnover
replace profit="420000" if id_plateforme == 1240     //    30% of total turnover
replace profit="48000" if id_plateforme == 1239
replace profit="6250" if id_plateforme == 1242


		* ca_exp
replace ca_exp="1300000" if id_plateforme == 991 // Augmentation de 30% par rapport à 2021
replace ca_exp="0" if id_plateforme == 1000
replace ca_exp="100000" if id_plateforme == 1001   //    10% of total turnover
replace ca_exp="960000" if id_plateforme == 1008   //     80% of total turnover
replace ca_exp="0" if id_plateforme == 1010
replace ca_exp="0" if id_plateforme == 1013
replace ca_exp="0" if id_plateforme == 1027
replace ca_exp="240097" if id_plateforme == 1028                              
replace ca_exp="12800" if id_plateforme == 1045    //    40% of total turnover
replace ca_exp="397358" if id_plateforme == 1049   //    "120000 euros converti en dinars selon le cours du 31.01.2023"
replace ca_exp="160000" if id_plateforme ==1087    //     10% of total turnover
replace ca_exp="4000" if id_plateforme == 1133
replace ca_exp="0" if id_plateforme == 1146 
replace ca_exp="0" if id_plateforme == 1147
replace ca_exp="1000" if id_plateforme == 1154
replace ca_exp="0" if id_plateforme == 1155     
replace ca_exp="-999" if id_plateforme == 1161
replace ca_exp="-999" if id_plateforme == 1179
replace ca_exp="0" if id_plateforme == 1184
replace ca_exp="7000" if id_plateforme == 1185 
replace ca_exp="1285000" if id_plateforme == 1195                                                                             
replace ca_exp="0" if id_plateforme == 1201

replace ca_exp="0" if id_plateforme == 1043
replace ca_exp="160000" if id_plateforme == 1087
replace ca_exp="20000" if id_plateforme == 1153
replace ca_exp="0" if id_plateforme == 1159
replace ca_exp="0" if id_plateforme == 1240

replace ca_exp="134000" if id_plateforme == 1239
replace ca_exp="160000" if id_plateforme == 1243
replace ca_exp="30000" if id_plateforme == 1248    //    "moyenne"


        *exprep_inv
replace exprep_inv= -888 if exprep_inv== 888
replace exprep_inv= 70000 if id_plateforme== 983
replace exprep_inv= 10000 if id_plateforme== 985 
replace exprep_inv= -999 if exprep_inv== 999 
replace exprep_inv= 1000 if id_plateforme== 1000 
replace exprep_inv= 5000 if id_plateforme== 1013
replace exprep_inv= 0 if id_plateforme== 1019
replace exprep_inv= 0 if id_plateforme== 1020

replace exprep_inv= 0 if id_plateforme== 1055 
replace exprep_inv= 1000 if id_plateforme== 1000
replace exprep_inv= 3000 if id_plateforme== 1043
replace exprep_inv= 1300 if id_plateforme== 1159
replace exprep_inv= 10000 if id_plateforme== 1240



replace exprep_inv= 14000 if id_plateforme == 1027
replace exprep_inv= 0 if id_plateforme== 1030               
replace exprep_inv= 8000 if id_plateforme== 1033
replace exprep_inv= 25000 if id_plateforme == 1045
replace exprep_inv= 2000 if id_plateforme== 1054  
replace exprep_inv= 0 if id_plateforme== 1055  
replace exprep_inv= 0 if id_plateforme== 1130 
replace exprep_inv= -999 if id_plateforme== 1140
replace exprep_inv= 30000 if id_plateforme == 1147              
replace exprep_inv= 0 if id_plateforme== 1150 
replace exprep_inv= 3000 if id_plateforme== 1151
replace exprep_inv=-888 if id_plateforme == 1161
replace exprep_inv= 0 if id_plateforme == 1184
replace exprep_inv= 0 if id_plateforme== 1224 
replace exprep_inv= 100000 if id_plateforme== 1231 
replace exprep_inv= 150000 if id_plateforme== 1243 
replace exprep_inv = 3000 if id_plateforme == 1043


		*ca_2021
replace ca_2021="40000" if id_plateforme == 1159  // "moyenne"

		* employes
replace employes = 3 if id_plateforme == 996
replace employes = 5 if id_plateforme == 997
replace employes = 38 if id_plateforme == 1027
replace employes = 600 if id_plateforme == 1092
replace employes = 40 if id_plateforme == 1033
replace employes = 1 if id_plateforme == 1036
replace employes = 34 if id_plateforme == 1020
replace employes = 7 if id_plateforme == 1041 
replace employes = 7 if id_plateforme == 1081
replace employes = 15 if id_plateforme == 1147
replace employes = 25 if id_plateforme == 1231
replace employes = 34 if id_plateforme == 1020

*car employes 

replace car_empl1 = 2 if id_plateforme == 996
replace car_empl1 = 35 if id_plateforme == 1027
replace car_empl1 = 37 if id_plateforme == 1033
replace car_empl1 = 13 if id_plateforme == 1147
replace car_empl1 = 20 if id_plateforme == 1231
replace car_empl1 =34 if id_plateforme == 1020
replace car_empl1 = 0 if id_plateforme == 1081 // seasonal employees

replace car_empl2 = 2 if id_plateforme == 996
replace car_empl2 = 27 if id_plateforme == 1027
replace car_empl2 = 20 if id_plateforme == 1033
replace car_empl2 = 13 if id_plateforme == 1147
replace car_empl2 = 21 if id_plateforme == 1231
replace car_empl2 =25 if id_plateforme == 1020


replace car_empl3 = 3 if id_plateforme == 996
replace car_empl3 = 38 if id_plateforme == 1027
replace car_empl3 = 40 if id_plateforme == 1033
replace car_empl3 = 15 if id_plateforme == 1147
replace car_empl3 = 25 if id_plateforme == 1231
replace car_empl3 =30 if id_plateforme == 1020


replace car_empl4 = 0 if id_plateforme == 996
replace car_empl4 = 0 if id_plateforme == 1027
replace car_empl4 = 0 if id_plateforme == 1033
replace car_empl4 = 0 if id_plateforme == 1147
replace car_empl4 = 0 if id_plateforme == 1231
replace car_empl4 = 0 if id_plateforme == 1081 // seasonal employees


  



		* ssa activites
replace ssa_action5 = 0 if id_plateforme == 1017
replace ssa_action4 = 0 if id_plateforme == 1054
replace ssa_action5 = 0 if id_plateforme == 1054
replace ssa_action5 = 0 if id_plateforme == 1159


	*export practices plan.
replace exp_pra_plan=1 if id_plateforme == 983 
replace exp_pra_mission = 0 if id_plateforme == 983
replace exp_pra_cible = 0 if id_plateforme == 983
replace exp_pra_mission = 0 if id_plateforme == 989
replace exp_pra_foire = 0 if id_plateforme == 1020 
replace exp_pra_sci = 0 if id_plateforme == 1020 
replace exp_pra_rexp = 0 if id_plateforme == 1020 
replace exp_pra_cible = 0 if id_plateforme == 1020 
replace exp_pra_mission = 0 if id_plateforme == 1020 
replace exp_pra_douane = 0 if id_plateforme == 1020 
replace exp_pra_plan = 0 if id_plateforme == 1020 
replace exp_pra_cible = 0 if id_plateforme == 1036
replace exp_pra_mission = 0 if id_plateforme == 1036
replace exp_pra_foire = 0 if id_plateforme == 1036 
replace exp_pra_cible = 0 if id_plateforme == 1055
replace exp_pra_mission = 0 if id_plateforme == 1054
replace exp_pra_foire = 0 if id_plateforme == 1054 
replace exp_pra_sci = 0 if id_plateforme == 1000
replace exp_pra_cible = 1 if id_plateforme == 1000
replace exp_pra_mission = 0 if id_plateforme == 1000
replace exp_pra_plan = 1 if id_plateforme == 1000
replace exp_pra_foire = 0 if id_plateforme == 1000
replace exp_pra_mission = 0 if id_plateforme == 1020
replace exp_pra_mission = 1 if id_plateforme == 1043
replace exp_pra_plan = 0 if id_plateforme == 1201
replace exp_pra_sci = 0 if id_plateforme == 1153
replace exp_pra_rexp = 0 if id_plateforme == 1153
replace exp_pra_cible = 0 if id_plateforme == 1153
replace exp_pra_rexp = 1 if id_plateforme == 1159
replace exp_pra_cible = 0 if id_plateforme == 1159
replace exp_pra_mission = 0 if id_plateforme == 1159
replace exp_pra_foire = 0 if id_plateforme == 1159
replace exp_pra_plan = 1 if id_plateforme == 1159
replace exp_pra_cible = 0 if id_plateforme == 1240
replace exp_pra_mission = 1 if id_plateforme == 1240
replace exp_pra_plan = 0 if id_plateforme == 1240
replace exp_pra_foire = 0 if id_plateforme == 1240


	* loop over all accounting variables with string
ds ca ca_exp profit ca_2021 ca_exp_2021 profit_2021, has(type string) 
local numvars_with_strings "`r(varlist)'"
foreach var of local numvars_with_strings {
    replace `var' = ustrregexra( `var',"dinars","")
    replace `var' = ustrregexra( `var',"dinar","")
    replace `var' = ustrregexra( `var',"milles","000")
    replace `var' = ustrregexra( `var',"mille","000")
	replace `var' = ustrregexra( `var',"millions","000000")
    replace `var' = ustrregexra( `var',"million","000000") 
    replace `var' = ustrregexra( `var',"dt","")
    replace `var' = ustrregexra( `var',"k","000")
    replace `var' = ustrregexra( `var',"dt","")
    replace `var' = ustrregexra( `var',"tnd","")
    replace `var' = ustrregexra( `var',"TND","")
	replace `var' = ustrregexra( `var',"DT","")
	replace `var' = ustrregexra( `var',"D","")
    replace `var' = ustrregexra( `var',"zéro","0")
    replace `var' = ustrregexra( `var',"zero","0")
    replace `var' = ustrregexra( `var'," ","")
    replace `var' = ustrregexra( `var',"un","1")
    replace `var' = ustrregexra( `var',"deux","2")
    replace `var' = ustrregexra( `var',"trois","3")
    replace `var' = ustrregexra( `var',"quatre","4")
    replace `var' = ustrregexra( `var',"cinq","5")
    replace `var' = ustrregexra( `var',"six","6")
    replace `var' = ustrregexra( `var',"sept","7")
    replace `var' = ustrregexra( `var',"huit","8")
    replace `var' = ustrregexra( `var',"neuf","9")
    replace `var' = ustrregexra( `var',"dix","10")
    replace `var' = ustrregexra( `var',"O","0")
    replace `var' = ustrregexra( `var',"o","0")
    replace `var' = ustrregexra( `var',"دينار تونسي","")
    replace `var' = ustrregexra( `var',"دينار","")
    replace `var' = ustrregexra( `var',"تونسي","")
    replace `var' = ustrregexra( `var',"د","")
    replace `var' = ustrregexra( `var',"de","")
    replace `var' = ustrregexra( `var',"d","")
    replace `var' = ustrregexra( `var',"na","")
    replace `var' = ustrregexra( `var',"r","")
    replace `var' = ustrregexra( `var',"m","000")
    replace `var' = ustrregexra( `var',"مليون","000000")
    replace `var' = subinstr(`var', ".", "",.)
    replace `var' = subinstr(`var', ",", ".",.)
    replace `var' = "`not_know'" if `var' =="je ne sais pas"
    replace `var' = "`not_know'" if `var' =="لا أعرف"

}


***********************************************************************
* 	PART 4:  Manual correction
***********************************************************************

* ssa activites
replace ssa_action1 = 1 if id_plateforme == 1033

replace ssa_action4 = 0 if id_plateforme == 1054


replace ssa_action5 = 0 if id_plateforme == 985
replace ssa_action5 = 0 if id_plateforme == 1017
replace ssa_action5 = 1 if id_plateforme == 1019
replace ssa_action5 = 0 if id_plateforme == 1030
replace ssa_action5 = 0 if id_plateforme == 1054
replace ssa_action5 = 1 if id_plateforme == 1130
replace ssa_action5 = 1 if id_plateforme == 1151
replace ssa_action5 = 0 if id_plateforme == 1184
replace ssa_action5 = 0 if id_plateforme == 1224


	*export practices plan.
replace exp_pra_plan=1 if id_plateforme == 983 
replace exp_pra_mission = 0 if id_plateforme == 983
replace exp_pra_cible = 0 if id_plateforme == 983

replace exp_pra_mission = 0 if id_plateforme == 989

replace exp_pra_cible = 0 if id_plateforme == 1009
replace exp_pra_plan=0 if id_plateforme == 1009 

replace exp_pra_cible = 0 if id_plateforme == 1019 
replace exp_pra_mission = 0 if id_plateforme == 1019

replace exp_pra_mission = 0 if id_plateforme == 1020
replace exp_pra_foire = 0 if id_plateforme == 1020 
replace exp_pra_sci = 0 if id_plateforme == 1020 
replace exp_pra_rexp = 0 if id_plateforme == 1020 
replace exp_pra_cible = 0 if id_plateforme == 1020 
replace exp_pra_douane = 0 if id_plateforme == 1020 
replace exp_pra_plan = 0 if id_plateforme == 1020 

replace exp_pra_cible = 1 if id_plateforme == 1027
replace exp_pra_mission = 1 if id_plateforme == 1027
replace exp_pra_foire = 1 if id_plateforme == 1027

replace exp_pra_sci = 0 if id_plateforme == 1030
replace exp_pra_mission = 0 if id_plateforme == 1030

replace exp_pra_mission = 1 if id_plateforme == 1033

replace exp_pra_cible = 0 if id_plateforme == 1036
replace exp_pra_mission = 0 if id_plateforme == 1036
replace exp_pra_foire = 0 if id_plateforme == 1036 

replace exp_pra_cible = 0 if id_plateforme == 1140 
replace exp_pra_mission = 1 if id_plateforme == 1140
replace exp_pra_foire = 1 if id_plateforme == 1140 

replace exp_pra_mission = 0 if id_plateforme == 1150

replace exp_pra_sci = 0 if id_plateforme == 1153 
replace exp_pra_rexp = 0 if id_plateforme == 1153 
replace exp_pra_cible = 0 if id_plateforme == 1153 

replace exp_pra_mission = 0 if id_plateforme == 1054
replace exp_pra_foire = 0 if id_plateforme == 1054

replace exp_pra_cible = 0 if id_plateforme == 1055

replace exp_pra_cible = 0 if id_plateforme == 1130
replace exp_pra_plan=0 if id_plateforme == 1130 

replace exp_pra_cible = 0 if id_plateforme == 1143

replace exp_pra_foire = 1 if id_plateforme == 1184 
replace exp_pra_sci = 0 if id_plateforme == 1184 
replace exp_pra_cible = 0 if id_plateforme == 1184 
replace exp_pra_plan = 0 if id_plateforme == 1184 

replace exp_pra_sci = 0 if id_plateforme == 1205 
replace exp_pra_rexp = 0 if id_plateforme == 1205 
replace exp_pra_cible = 0 if id_plateforme == 1205
replace exp_pra_foire = 0 if id_plateforme == 1205 
replace exp_pra_plan= 1 if id_plateforme == 1205 

replace exp_pra_foire = 0 if id_plateforme == 1224 
replace exp_pra_plan= 0 if id_plateforme == 1224
 
replace exp_pra_foire = 0 if id_plateforme == 1225 
replace exp_pra_sci = 0 if id_plateforme == 1225

replace exp_pra_sci = 0 if id_plateforme == 1000
replace exp_pra_mission = 0 if id_plateforme == 1000
replace exp_pra_foire = 0 if id_plateforme == 1000

replace exp_pra_mission = 0 if id_plateforme == 1020

replace exp_pra_plan = 0 if id_plateforme == 1201

replace exp_pra_cible = 0 if id_plateforme == 1240
replace exp_pra_plan = 0 if id_plateforme == 1240
replace exp_pra_foire = 0 if id_plateforme == 1240




***********************************************************************
* 	PART 6:  autres / miscellaneous adjustments
***********************************************************************
	* correct wrongly coded values for man_hr_pro
replace man_hr_pro = 0 if man_hr_pro == 0.25
replace man_hr_pro = 0.25 if man_hr_pro == 0.5
label values man_hr_pro label_promo

***********************************************************************
* 	PART 7:  Destring remaining numerical vars
***********************************************************************

local destrvar ca ca_exp profit ca_2021 ca_exp_2021 profit_2021 
foreach x of local destrvar { 
destring `x', replace
format `x' %25.0fc
}

***********************************************************************
* 	Part 8: Save the changes made to the data		  			
***********************************************************************
save "${ml_intermediate}/ml_intermediate", replace
