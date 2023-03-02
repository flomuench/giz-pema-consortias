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

replace matricule_fisc_incorrect=1 if id_plateforme == 1013
replace matricule_fisc_incorrect=1 if id_plateforme == 1081
replace matricule_fisc_incorrect=1 if id_plateforme == 1083
replace matricule_fisc_incorrect=1 if id_plateforme == 1094
replace matricule_fisc_incorrect=1 if id_plateforme == 1095
replace matricule_fisc_incorrect=1 if id_plateforme == 1128
replace matricule_fisc_incorrect=1 if id_plateforme == 1182
replace matricule_fisc_incorrect=1 if id_plateforme == 1190
replace matricule_fisc_incorrect=1 if id_plateforme == 1191
replace matricule_fisc_incorrect=1 if id_plateforme == 1193
replace matricule_fisc_incorrect=1 if id_plateforme == 1197
replace matricule_fisc_incorrect=1 if id_plateforme == 1214
replace matricule_fisc_incorrect=1 if id_plateforme == 1245


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
replace matricule_fiscale = "1755985E" if id_plateforme == 1185


***********************************************************************
* 	PART 3:   	Change of contact information
***********************************************************************
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



***********************************************************************
* 	PART 5:  export matricule fiscal for admin data from CEPEX
***********************************************************************
export excel id_plateforme matricule_fiscale firmname matricule_fisc_incorrect using"${master_gdrive}/matricule_consortium_cepex", replace firstrow(var)



***********************************************************************
* 	PART: save consortia pii data
***********************************************************************
save "${master_intermediate}/consortium_pii_inter", replace

***********************************************************************
********************* 	II: Analysis data *****************************
***********************************************************************	
use "${master_intermediate}/consortium_inter", clear


***********************************************************************
* 	PART 1:  change pole information
***********************************************************************
*Adding pole information for the midline

foreach var in pole{
bysort id_plateforme (surveyround): replace `var' = `var'[_n-1] if `var' == .
}

replace pole = 4 if id_plateforme == 1001
replace pole = 4 if id_plateforme == 1134
replace pole = 4 if id_plateforme == 1163
replace pole = 1 if id_plateforme == 1230
replace pole = 3 if id_plateforme == 998

***********************************************************************
* 	PART 2:  Correct old accounting values
***********************************************************************
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

		* correct baseline responses
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

***********************************************************************
* 	PART final save:    save as intermediate consortium_database
***********************************************************************
save "${master_intermediate}/consortium_inter", replace
