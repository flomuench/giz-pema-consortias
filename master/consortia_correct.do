***********************************************************************
* 			consortia master do files: correct 
***********************************************************************
*																	  
*	PURPOSE: correct values in merged data			  
*																	  
*	OUTLINE: 	PART I: PII data
*					PART 1: clean regis_final	  
*
*				PART II: Analysis data
*					PART 3: 
*																	  
*	Author:  	Florian Münch, Fabian Scheifele & Siwar Hakim							    
*	ID variable: id_email		  					  
*	Requires:  	 regis_final.dta bl_final.dta 										  
*	Creates:     regis_final.dta bl_final.dta
***********************************************************************
********************* 	I: PII data ***********************************
***********************************************************************
{	
***********************************************************************
* 	PART 1:    correct leading & trailing spaces	  
***********************************************************************
use "${master_intermediate}/consortium_pii_inter", clear

*remove leading and trailing white space
{
ds, has(type string) 
local strvars "`r(varlist)'"
foreach x of local strvars {
replace `x' = stritrim(strtrim(`x'))
}
}
***********************************************************************
* 	PART 2:   	update matricule fiscale based on national registry
***********************************************************************
{

replace nom_rep="Nesrine dhahri" if id_plateforme==1040
replace firmname="zone art najet omri" if id_plateforme==1133
replace nom_rep="najet omri" if id_plateforme==1133
replace firmname="flav'or" if id_plateforme==1150
replace firmname="Al chatti Agro" if id_plateforme== 1041

replace matricule_fiscale = upper(matricule_fiscale)
export excel id_plateforme firmname date_created matricule_fiscale nom_rep rg_adresse codepostal site_web using "${master_gdrive}/matricule_consortium", firstrow(var) replace

*dummies whether matricule is correct or where it is a matricule of a physical person rather than company
gen matricule_fisc_incorrect=0
gen matricule_physique=0

replace matricule_physique = 1 if id_plateforme == 983
replace matricule_physique = 1 if id_plateforme == 986
replace matricule_physique = 1 if id_plateforme == 989
replace matricule_physique = 1 if id_plateforme == 990
replace matricule_physique = 1 if id_plateforme == 1004
replace matricule_physique = 1 if id_plateforme == 1005
replace matricule_physique = 1 if id_plateforme == 1015
replace matricule_physique = 1 if id_plateforme == 1020
replace matricule_physique = 1 if id_plateforme == 1030
replace matricule_physique = 1 if id_plateforme == 1031
replace matricule_physique = 1 if id_plateforme == 1043
replace matricule_physique = 1 if id_plateforme == 1054
replace matricule_physique = 1 if id_plateforme == 1074
replace matricule_physique = 1 if id_plateforme == 1107
replace matricule_physique = 1 if id_plateforme == 1122
replace matricule_physique = 1 if id_plateforme == 1123
replace matricule_physique = 1 if id_plateforme == 1126
replace matricule_physique = 1 if id_plateforme == 1133
replace matricule_physique = 1 if id_plateforme == 1135
replace matricule_physique = 1 if id_plateforme == 1140
replace matricule_physique = 1 if id_plateforme == 1143
replace matricule_physique = 1 if id_plateforme == 1155
replace matricule_physique = 1 if id_plateforme == 1162
replace matricule_physique = 1 if id_plateforme == 1192
replace matricule_physique = 1 if id_plateforme == 1196
replace matricule_physique = 1 if id_plateforme == 1199
replace matricule_physique = 1 if id_plateforme == 1201
replace matricule_physique = 1 if id_plateforme == 1210
replace matricule_physique = 1 if id_plateforme == 1201
replace matricule_physique = 1 if id_plateforme == 1210
replace matricule_physique = 1 if id_plateforme == 1201
replace matricule_physique = 1 if id_plateforme == 1210
replace matricule_physique = 1 if id_plateforme == 1222
replace matricule_physique = 1 if id_plateforme == 1230
replace matricule_physique = 1 if id_plateforme == 1231
replace matricule_physique = 1 if id_plateforme == 1159
replace matricule_physique = 1 if id_plateforme == 997
replace matricule_physique = 1 if id_plateforme == 1134
replace matricule_physique = 1 if id_plateforme == 1169
replace matricule_physique = 1 if id_plateforme == 1248
replace matricule_physique = 1 if id_plateforme == 1245
replace matricule_physique = 1 if id_plateforme == 1128



replace matricule_fisc_incorrect=1 if id_plateforme == 1013
replace matricule_fisc_incorrect=1 if id_plateforme == 1081
replace matricule_fisc_incorrect=1 if id_plateforme == 1083
replace matricule_fisc_incorrect=1 if id_plateforme == 1094
replace matricule_fisc_incorrect=1 if id_plateforme == 1095
replace matricule_fisc_incorrect=1 if id_plateforme == 1182
replace matricule_fisc_incorrect=1 if id_plateforme == 1190
replace matricule_fisc_incorrect=1 if id_plateforme == 1193
replace matricule_fisc_incorrect=1 if id_plateforme == 1197
replace matricule_fisc_incorrect=1 if id_plateforme == 1214


*now replace these two variables for the firms where the ID is not findable on registre-entreprise.tn 
*or physical
replace matricule_fiscale = "0601414N" if id_plateforme == 1033
replace matricule_fiscale = "0334058Y" if id_plateforme == 1092
replace matricule_fiscale = "1680517R" if id_plateforme == 1110
replace matricule_fiscale = "1479684C" if id_plateforme == 1136
replace matricule_fiscale = "0002171D" if id_plateforme == 1137
replace matricule_fiscale = "1585453H" if id_plateforme == 1108
replace matricule_fiscale = "1175102E" if id_plateforme == 1153
replace matricule_fiscale = "1140685D" if id_plateforme == 1161
replace matricule_fiscale = "0448240Y" if id_plateforme == 1159
replace matricule_fiscale = "1225272C" if id_plateforme == 994
replace matricule_fiscale = "1677629Z" if id_plateforme == 997
replace matricule_fiscale = "1721782L" if id_plateforme == 1036
replace matricule_fiscale = "1219150E?" if id_plateforme == 1095
replace matricule_fiscale = "854949V" if id_plateforme == 1128
replace matricule_fiscale = "1463126T" if id_plateforme == 1134
replace matricule_fiscale = "1795325T" if id_plateforme == 1146
replace matricule_fiscale = "1748667A" if id_plateforme == 1191
replace matricule_fiscale = "1610602Z" if id_plateforme == 1205
replace matricule_fiscale = "0111519V" if id_plateforme == 1248
replace matricule_fiscale = "1542155Q" if id_plateforme == 1150

}

***********************************************************************
* 	PART 3:   	Change of contact information
***********************************************************************
{
*change also firmname or representatives name if difference found in registry
replace firmname = "el maarifaa ennasr" if id_plateforme == 1033
replace firmname = "zayta" if id_plateforme == 994
replace firmname = "STE AMIRI DE HUILE D'OLIVE KAIROUAN" if id_plateforme == 1036
replace firmname = "decopalm" if id_plateforme == 1128
replace firmname = "bio valley" if id_plateforme == 1191
replace firmname = "Eleslek" if id_plateforme == 1240

replace email_pdg = "myriamjemai9@gmail.com" if id_plateforme == 1218
replace email_pdg = "samia.guissouma.mokni@gmail.com" if id_plateforme == 1049
replace email_pdg = "gharbisabra2711@gmail.com" if id_plateforme == 1244
replace email_pdg = "ndeconsultings@gmail.com" if id_plateforme == 1225
replace email_pdg = "yasmineyosra6@gmail.com" if id_plateforme == 1242
replace email_pdg = "chaloueh.essia8@gmail.com" if id_plateforme == 1168
replace email_pdg = "contact@nakawabio.com" if id_plateforme == 1074
replace email_pdg = "maouia.belkhodja.alia@gmail.com" if id_plateforme == 1010
replace email_pdg = "bso.productrice@gmail.com" if id_plateforme == 1108

replace tel_pdg = "98945250" if id_plateforme == 1117
replace tel_pdg = "29891161" if id_plateforme == 1045
replace tel_pdg = "33613306178" if id_plateforme == 1170

replace nom_rep = "Fathiya bin Abdul Mawla" if id_plateforme == 1159

replace rg_adresse = "boutique numero 11 Village artisanal Castila 2200 Tozeur" ///
if id_plateforme == 1128

gen mothercompany= ""
replace mothercompany ="Cloudvisualart" if id_plateforme == 1057
gen comment =""
replace comment = "Matricule fiscale is from Ziyad ben Abbas" if id_plateforme==1169

}

***********************************************************************
* 	PART 5:  export matricule fiscal for admin data from CEPEX
***********************************************************************
export excel id_plateforme matricule_fiscale firmname matricule_fisc_incorrect using"${master_gdrive}/matricule_consortium_cepex", replace firstrow(var)



***********************************************************************
* 	PART: save consortia pii data
***********************************************************************
save "${master_intermediate}/consortium_pii_inter", replace

}

***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
{
use "${master_intermediate}/consortium_inter", clear


***********************************************************************
* 	PART 1:  change pole information
***********************************************************************
*Adding pole information for the midline

foreach var in pole{
bysort id_plateforme (surveyround): replace `var' = `var'[_n-1] if `var' == .
}

replace pole = 3 if id_plateforme == 1001
replace pole = 3 if id_plateforme == 1134
replace pole = 3 if id_plateforme == 1163
replace pole = 1 if id_plateforme == 1230
replace pole = 3 if id_plateforme == 998

***********************************************************************
* 	PART 2:  Correct old accounting values
***********************************************************************
{
{

/* replacing 0 with .
local vars "ca ca_exp"

foreach var of local vars {
	forvalues year = 2018(1)2019 {
		replace `var'_`year' = . if year_created < `year'	& `var'_`year' == 0
	}
}
*/	
		* Correcting ca
replace ca_2018 = 800000 if id_plateforme == 991
replace ca_2019 = 1400000 if id_plateforme == 991

replace ca_2019 = 1700000 if id_plateforme == 995

replace ca_2018 = 33000 if id_plateforme == 1013
replace ca_2019 = 45000 if id_plateforme == 1013
replace ca_2020 = 123000 if id_plateforme == 1013

replace ca_2020 = 10000 if id_plateforme == 1019

replace ca_2020 = 3000 if id_plateforme == 1020

replace ca_2020 = 2420209 if id_plateforme == 1027
replace ca_2019 = 138826 if id_plateforme == 1027

replace ca_2020 = 60000 if id_plateforme == 1030
replace ca_2019 = 25000 if id_plateforme == 1030

replace ca_2018 = 100000 if id_plateforme == 1035
replace ca_2019 = 80000 if id_plateforme == 1035
replace ca_2020 = 6000 if id_plateforme == 1035

replace ca_2018 = 40000 if id_plateforme == 1041
replace ca_2019 = 150000 if id_plateforme == 1041
replace ca_2020 = 250000 if id_plateforme == 1041

replace ca_2020 = 1000000 if id_plateforme == 1042
replace ca_2019 = 1000000 if id_plateforme == 1042

replace ca_2018 = 295000 if id_plateforme == 1043
replace ca_2019 = 550000 if id_plateforme == 1043
replace ca_2020 = 300000 if id_plateforme == 1043

replace ca_2019 = 20000 if id_plateforme == 1044
replace ca_2020 = 25000 if id_plateforme == 1044

replace ca_2018 = 150000 if id_plateforme == 1074
replace ca_2019 = 250000 if id_plateforme == 1074
replace ca_2020 = 200000 if id_plateforme == 1074

replace ca_2020 = 300000 if id_plateforme == 1087

replace ca_2019 = 113280 if id_plateforme == 1088
replace ca_2020 = 75831 if id_plateforme == 1088

replace ca_2018 = 26423000 if id_plateforme == 1092
replace ca_2019 = 29749000 if id_plateforme == 1092
replace ca_2020 = 25864000 if id_plateforme == 1092

replace ca_2020 = 147000 if id_plateforme == 1096

replace ca_2020 = 5000 if id_plateforme == 1108

replace ca_2019 = 100000 if id_plateforme == 1110
replace ca_2020 = 37000 if id_plateforme == 1110

replace ca_2018 = 256000 if id_plateforme == 1117
replace ca_2019 = 376000 if id_plateforme == 1117
replace ca_2020 = 176000 if id_plateforme == 1117

replace ca_2018 = 2847421 if id_plateforme == 1119
replace ca_2019 = 3792943 if id_plateforme == 1119
replace ca_2020 = 3904562 if id_plateforme == 1119

replace ca_2019 = 15000 if id_plateforme == 1123

replace ca_2019 = 150000 if id_plateforme == 1154
replace ca_2020 = 20000 if id_plateforme == 1154

replace ca_2019 = 21100 if id_plateforme == 1157
replace ca_2020 = 38500 if id_plateforme == 1157

replace ca_2020 = 4500 if id_plateforme == 1245

replace ca_2018 = 189869 if id_plateforme == 1242
replace ca_2019 = 103050 if id_plateforme == 1242
replace ca_2020 = 86627 if id_plateforme == 1242

replace ca_2018 = 2663000 if id_plateforme == 1240
replace ca_2019 = 1502130 if id_plateforme == 1240
replace ca_2020 = 82630 if id_plateforme == 1240

replace ca_2018 = 0 if id_plateforme == 1231
replace ca_2019 = 50000 if id_plateforme == 1231
replace ca_2020 = 100000 if id_plateforme == 1231

replace ca_2018 = 5000 if id_plateforme == 1210
replace ca_2019 = 20000 if id_plateforme == 1210
replace ca_2020 = 20000 if id_plateforme == 1210

replace ca_2018 = 70000 if id_plateforme == 1197
replace ca_2019 = 25000 if id_plateforme == 1197
replace ca_2020 = 55000 if id_plateforme == 1197

replace ca_2018 = 20000 if id_plateforme == 1193
replace ca_2019 = 10000 if id_plateforme == 1193
replace ca_2020 = 20000 if id_plateforme == 1193

replace ca_2018 = 8000 if id_plateforme == 1192
replace ca_2019 = 4000 if id_plateforme == 1192
replace ca_2020 = 3000 if id_plateforme == 1192

replace ca_2018 = 4500 if id_plateforme == 1186
replace ca_2019 = 2000 if id_plateforme == 1186
replace ca_2020 = 1000 if id_plateforme == 1186


replace ca_2019 = 20000 if id_plateforme == 1182
replace ca_2020 = 45000 if id_plateforme == 1182

replace ca_2019 = 89056 if id_plateforme == 1178
replace ca_2020 = 250670 if id_plateforme == 1178

replace ca_2018 = . if id_plateforme == 1168 // verify after midline response
replace ca_2019 = . if id_plateforme == 1168
replace ca_2020 = . if id_plateforme == 1168

replace ca_2018 = 10000 if id_plateforme == 1162
replace ca_2019 = 20000 if id_plateforme == 1162
replace ca_2020 = 5500 if id_plateforme == 1162

replace ca_2018 = 120000 if id_plateforme == 1159
replace ca_2019 = 50000 if id_plateforme == 1159

replace ca_2019 = 150000 if id_plateforme == 1154
replace ca_2020 = 20000 if id_plateforme == 1154
}

{
		* Correcting ca_exp
replace ca_exp2020 = 1500000 if id_plateforme == 995

replace ca_exp2020 = 15960 if id_plateforme == 1027

replace ca_exp2019 = 80000  if id_plateforme == 1041
replace ca_exp2020 = 220000  if id_plateforme == 1041

replace ca_exp2019 = 7000  if id_plateforme == 1042
replace ca_exp2020 = 8000  if id_plateforme == 1042

replace ca_exp2019 = 20000  if id_plateforme == 1044
replace ca_exp2020 = 25000  if id_plateforme == 1044

replace ca_exp2018 = 75000  if id_plateforme == 1074
replace ca_exp2019 = 100000  if id_plateforme == 1074
replace ca_exp2020 = 50000  if id_plateforme == 1074

replace ca_exp2020 = 147000 if id_plateforme == 1096

replace ca_exp2019 = 0  if id_plateforme == 1110
replace ca_exp2020 = 100000  if id_plateforme == 1110

replace ca_exp2018 = 13000  if id_plateforme == 1117
replace ca_exp2019 = 26000  if id_plateforme == 1117
replace ca_exp2020 = 5000  if id_plateforme == 1117

replace ca_exp2018 = 2649925  if id_plateforme == 1119
replace ca_exp2019 = 3441390  if id_plateforme == 1119
replace ca_exp2020 = 3380415  if id_plateforme == 1119

replace ca_exp2018 = 497078  if id_plateforme == 1137
replace ca_exp2019 = 265972  if id_plateforme == 1137
replace ca_exp2020 = 42790  if id_plateforme == 1137

replace ca_exp2019 = 150000  if id_plateforme == 1154

replace ca_exp2018 = 300000  if id_plateforme == 1158
replace ca_exp2019 = 400000  if id_plateforme == 1158

replace ca_exp2018 = 80000  if id_plateforme == 1159

replace ca_exp2019 = 5000  if id_plateforme == 1162

replace ca_exp2020 = 800000  if id_plateforme == 1170

replace ca_exp2018 = 2100  if id_plateforme == 1186

replace ca_exp2018 = 0  if id_plateforme == 1197
replace ca_exp2019 = 800  if id_plateforme == 1197
replace ca_exp2020 = 4000  if id_plateforme == 1197

replace ca_exp2019 = 1329000  if id_plateforme == 1219
replace ca_exp2020 = 480000  if id_plateforme == 1219

replace ca_exp2019 = 25000  if id_plateforme == 1222
replace ca_exp2020 = 25000  if id_plateforme == 1222

replace ca_exp2020 = 2000  if id_plateforme == 1231

replace ca_exp2020 = 3000  if id_plateforme == 1245
}

		* correct baseline responses
{
replace profit = 5000 if id_plateforme == 986 & surveyround == 1
replace profit = 35000 if id_plateforme == 1084 & surveyround == 1
replace profit = 50000 if id_plateforme == 1098 & surveyround == 1

replace ca = 16000 if id_plateforme == 1054 & surveyround == 1

replace ca = 1000000 if id_plateforme == 1008 & surveyround == 1

replace ca = 150000 if id_plateforme == 1244 & surveyround == 1
replace profit = 50000 if id_plateforme == 1244 & surveyround == 1

replace ca = 40000 if id_plateforme == 1259 & surveyround == 1
replace profit = 9000 if id_plateforme == 1259 & surveyround == 1

replace ca = 62000 if id_plateforme == 1097 & surveyround == 1
replace ca_exp = 30000 if id_plateforme == 1097 & surveyround == 1
replace profit = 21000 if id_plateforme == 1097 & surveyround == 1

replace ca_exp = 0 if id_plateforme == 1244 & surveyround == 1 // logical consequence as no export operation

}

}

***********************************************************************
* 	PART 3:  	Replace all MV codes with real missing values for Y outcomes for later regression
***********************************************************************
{
local network "net_nb_f net_nb_m net_nb_fam net_nb_dehors net_nb_qualite net_coop_pos"
local empowerment "car_loc_exp car_efi_fin1 car_efi_nego car_efi_conv car_init_prob car_init_init car_init_opp car_loc_succ car_loc_env car_loc_insp" 
local mp "man_ind_awa man_fin_per_fre man_hr_obj man_hr_feed man_pro_ano man_fin_enr man_fin_profit man_fin_per man_mark_prix man_mark_div man_mark_clients man_mark_offre man_mark_pub  man_hr_pro man_fin_num"
local innovation "inno_commerce inno_lieu inno_process inno_produit"
local export_readiness "exp_pra_foire exp_pra_sci exp_pra_rexp exp_pra_cible exp_pra_mission exp_pra_douane exp_pra_plan exprep_norme exp_inv exprep_couts exp_pays exp_afrique ssa_action1 ssa_action2 ssa_action3 ssa_action4 ssa_action5"
local business_performance "ca_exp ca profit profit employes"
local ys `network' `empowerment' `mp' `innovation' `export_readiness' `business_performance'

foreach var of local ys {
		replace `var' = . if inlist(`var', -777, -888, -999)
}

 *For financial data: replace "Don't know (-999) and refusal with missing value"

local finvars ca ca_exp ca_2024 ca_exp_2024 profit profit_2024 clients_ssa_commandes clients_ssa clients exp_pays exp_pays_ssa employes car_empl1 car_empl2


foreach var of local  finvars {
	replace `var' = . if `var' == -999
	replace `var' = . if `var' == -888
	replace `var' = . if `var' == -777
	replace `var' = . if `var' == -666
	replace `var' = . if `var' == 999
	replace `var' = . if `var' == 888
	replace `var' = . if `var' == 777
	replace `var' = . if `var' == 666
	replace `var' = . if `var' == 1234
	replace `var' = . if `var' == -1234
	}

}
***********************************************************************
* 	PART 4: Filter caused replacements
***********************************************************************

foreach var of varlist support2-support6 {
	replace `var' = 0 if support1 == 1
}

***********************************************************************
* 	Part 5: Homogenize products		  			
***********************************************************************
{
gen product_hom1 = ""  
replace product_hom1 ="dates" if ustrregexm(produit1,"dates")
replace product_hom1 ="dates" if ustrregexm(produit1,"dattes")
replace product_hom1 ="huiles essentielles" if ustrregexm(produit1,"huile")
replace product_hom1 ="huiles essentielles" if ustrregexm(produit1,"huide")
replace product_hom1 ="huiles essentielles" if ustrregexm(produit1,"huil")
replace product_hom1 ="huile d'olive" if ustrregexm(produit1,"olive")
replace product_hom1 ="tomate" if ustrregexm(produit1,"tomate")
replace product_hom1 ="tomate" if ustrregexm(produit1,"tomate concentre")
replace product_hom1 ="tomate" if ustrregexm(produit1,"tomate séchée")
replace product_hom1 ="plante" if ustrregexm(produit1,"alliés plante") 
replace product_hom1 ="plante" if ustrregexm(produit1,"extraits de plantes")
replace product_hom1 ="plante" if ustrregexm(produit1,"fleur de capucine")
replace product_hom1 ="plante" if ustrregexm(produit1,"pépinières production")
replace product_hom1 ="fruits" if ustrregexm(produit1,"fruit")
replace product_hom1 ="fruits" if ustrregexm(produit1,"fruit")
replace product_hom1 ="légumes" if ustrregexm(produit1,"légumes")
replace product_hom1 ="légumes" if ustrregexm(produit1,"légumes")
replace product_hom1 ="légumes" if ustrregexm(produit1,"légumes séchés (ail séché, oignon séché..)")
replace product_hom1 ="patisserie" if ustrregexm(produit1,"patisserie saine et allegee, bio")
replace product_hom1 ="epicerie" if ustrregexm(produit1,"épices")

replace product_hom1 ="formation" if ustrregexm(produit1,"formation")
replace product_hom1 ="formation" if ustrregexm(produit1,"training") 
replace product_hom1 ="formation" if ustrregexm(produit1,"coaching talents")
replace product_hom1 ="formation" if ustrregexm(produit1,"atelleirs scientifiques en ligne")
replace product_hom1 ="conseil" if ustrregexm(produit1,"conseil")
replace product_hom1 ="conseil" if ustrregexm(produit1,"accompagnement projets excellence opérationnelle")
replace product_hom1 ="conseil" if ustrregexm(produit1,"etudes") 
replace product_hom1 ="conseil" if ustrregexm(produit1,"l'accempagnement entreprises")
replace product_hom1 ="accesoire sac" if ustrregexm(produit1,"sac")
replace product_hom1 ="accesoire sac" if ustrregexm(produit1,"sac pour ordinateurs")
replace product_hom1 ="développement " if ustrregexm(produit1,"développement & intégration digital")
replace product_hom1 ="développement " if ustrregexm(produit1,"développement web")
replace product_hom1 ="développement " if ustrregexm(produit1,"développement logiciels")
replace product_hom1 ="développement " if ustrregexm(produit1,"intégration et développements erps") 
replace product_hom1 ="développement " if ustrregexm(produit1,"business process outsourcing") 
replace product_hom1 ="développement " if ustrregexm(produit1,"swift smart report application bancaire")
replace product_hom1 ="développement " if ustrregexm(produit1,"vente de solution logiciel") 
replace product_hom1 ="développement " if ustrregexm(produit1,"logiciel de gestion commerciadesktop")
replace product_hom1 ="digital" if ustrregexm(produit1,"création contenus digital") 
replace product_hom1 ="digital" if ustrregexm(produit1,"communication digital")
replace product_hom1 ="parfum " if ustrregexm(produit1,"parfum")
replace product_hom1 ="parfum " if ustrregexm(produit1,"diffuseurs de parfum") 
replace product_hom1 ="education " if ustrregexm(produit1,"education") 
replace product_hom1 ="education " if ustrregexm(produit1,"educanet") 
replace product_hom1 ="education " if ustrregexm(produit1,"enseignement de base") 
replace product_hom1 ="ceramique" if ustrregexm(produit1,"art de la table / table en porcelaine") 
replace product_hom1 ="ceramique " if ustrregexm(produit1,"poterie") 
replace product_hom1 ="ceramique" if ustrregexm(produit1,"art de table") 
replace product_hom1 ="ceramique" if ustrregexm(produit1,"saladier") 
replace product_hom1 ="textile" if ustrregexm(produit1,"vetement pour homme / femme / enfant") 
replace product_hom1 ="textile" if ustrregexm(produit1,"trousses cuir/ similicuir/ tissus") 


}

}

***********************************************************************
*	PART 6: Management - weighting
***********************************************************************	
* Management number of indicators monitored
* given we changed survey question design, calculate sum of monitored indicators (at ml we asked for the sum directly)
egen temp_man_ind = rowtotal(man_fin_per_ind man_fin_per_pro man_fin_per_qua man_fin_per_sto man_fin_per_emp man_fin_per_liv), missing
replace man_fin_num = 0 if surveyround == 3 & (temp_man_ind == 0)
replace man_fin_num = 0.33 if surveyround == 3 & (temp_man_ind > 0 & temp_man_ind <= 2)
replace man_fin_num = 0.66 if surveyround == 3 & (temp_man_ind > 2 & temp_man_ind <= 4)
replace man_fin_num = 1 if surveyround == 3 & (temp_man_ind > 4 & temp_man_ind <= 6)

drop temp_man_ind

*fix the weighting of baseline frequency questions so that it does not bias the z-score
replace man_hr_obj = 0.25 if man_hr_obj == 1 & surveyround == 1
replace man_hr_obj = 0.5 if man_hr_obj == 2 & surveyround == 1
replace man_hr_obj = 0.75 if man_hr_obj == 3 & surveyround == 1
replace man_hr_obj = 1 if man_hr_obj == 4 & surveyround == 1

replace man_hr_feed = 0.25 if man_hr_feed == 1 & surveyround == 1
replace man_hr_feed = 0.5 if man_hr_feed == 2 & surveyround == 1
replace man_hr_feed = 0.75 if man_hr_feed == 3 & surveyround == 1
replace man_hr_feed = 1 if man_hr_feed == 4 & surveyround == 1

replace man_pro_ano = 0.25 if man_pro_ano == 1 & surveyround == 1
replace man_pro_ano = 0.5 if man_pro_ano == 2 & surveyround == 1
replace man_pro_ano = 0.75 if man_pro_ano == 3 & surveyround == 1
replace man_pro_ano = 1 if man_pro_ano == 4 & surveyround == 1

replace man_fin_per = 0.25 if man_fin_per == 1 & surveyround == 1
replace man_fin_per = 0.5 if man_fin_per == 2 & surveyround == 1
replace man_fin_per = 0.75 if man_fin_per == 3 & surveyround == 1
replace man_fin_per = 1 if man_fin_per == 4 & surveyround == 1

***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_intermediate}/consortium_inter", replace
