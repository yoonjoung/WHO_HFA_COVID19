clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code creates "Model" datasets using Kenya Round 1 data. 
*	Country name = EXAMPLE
*	round = 1 

*Questionnare versions: 
*See latest here: C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\2. Modules
*	C19CM: 04/12/2021 - later changes are not critical for mock data 
*	CEHS: 03/22/2021 - later changes are not critical for mock data 
*	Community: 10/29/2021

*For each module,    
*	Section B: select 25% of obs randomly and multiply by 4
*				  fix unique ID
*				  create a dupliate for practice 		
*	Section C: drop Kenya specific quesitons and 
* 				  change question numbers based on modules as of January 16 2021
* 				  create further questions added since then, aligned with the latest version
* 				  generate fake sampling weight and export to the chartbook 

*Only for the hospital module 
* 	Section D: Bring Staffing and IPC/PPE data from CEHS to Hospital 

*Standard analysis do files use the "Model" datasets, 
*which are aligned with question numbers and type so that coding can be done.  

*Note on 2/25/2022: 
*YJ lost connection/direct-syncing with the sharepoint. Ugh... 
*Thus, creating mock data in local computer and uploading it to the share point...  

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
*cd "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards"
*cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards"
cd "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/"

*** Define the source data directory for Kenya (and as of 2/25/2022 AFGHANISTAN for community) 
* global mocksourcedir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\Tools"
* global mocksourcedir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\AFRO\Kenya\Round1\Tools"
global mocksourcedir "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/Mockdatasource/"

*** Define the Downloaded CSV folderes 
*global DownloadedCSV "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"
global DownloadedCSV "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/ExportedCSV_FromLimeSurvey/"


**************************************************************
* B. Import, select, expand and export 
**************************************************************

*****B.1. Case managment 
*import delimited "$mocksourcedir/Case-Mgmt/04012021_results-survey447349_codes.csv", case(preserve) clear
import delimited "$mocksourcedir/04012021_results-survey447349_codes.csv", case(preserve) clear

	set seed 38
	capture drop random
	generate random = runiform()
	keep if random<=0.25 
	expand 4
	drop random
	
	* FIX unique ID
	capture drop ïid
	capture drop id
	gen id = _n
	
	replace Q101 = id*1000000 + Q101
	codebook Q101
	
	* CREATE a duplicate
	egen long temp=max(Q101) 
	expand 2 if Q101==temp
	codebook Q101
	
	list Q101 submitdate temp if Q101==temp 
		replace submitdate = "12/21/2020 9:00" if Q101==temp & Q101==Q101[_n-1]
	list Q101 submitdate temp if Q101==temp 
	drop temp
	
	codebook Q101
	
export delimited using "$DownloadedCSV/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", replace 

*****B.2. CEHS 

*import delimited "$mocksourcedir/CEHS/04012021_results-survey769747_codes.csv", case(preserve) clear 
import delimited "$mocksourcedir/04012021_results-survey769747_codes.csv", case(preserve) clear 

	set seed 38
	capture drop random
	generate random = runiform()
	keep if random<=0.25 
	expand 4
	drop random

	* FIX unique ID
	lookfor id
	capture drop ïid
	capture drop id
	gen id = _n
	
	replace Q101 = id*1000000 + Q101
	codebook Q101
	
	* CREATE a duplicate
	egen long temp=max(Q101) 
	expand 2 if Q101==temp
	codebook Q101
	
	list Q101 submitdate temp if Q101==temp 
		replace submitdate = "12/18/2020 15:47" if Q101==temp & Q101==Q101[_n-1]
	list Q101 submitdate temp if Q101==temp 
	drop temp
	
	codebook Q101
	
export delimited using "$DownloadedCSV/LimeSurvey_CEHS_EXAMPLE_R1.csv", replace 

*****B.3. Community 

import delimited "$mocksourcedir/04012021_results-survey451568_codes.csv", case(preserve) clear  
*import excel "$mocksourcedir/WHO_Community_Chartbook_Afghanistan_02_22.xlsx", sheet("Respondent-level raw data") firstrow clear
*Afghanistan data are too clean. No missing... suspicious. Use the Kenya data back. 

	set seed 38
	capture drop random
	generate random = runiform()
	keep if random<=0.25 
	expand 4
	drop random

	* FIX unique ID
	lookfor id
	capture drop ïid
	capture drop id
	gen id = _n
	
	replace Q105 = runiformint(1,1000)
	replace Q105 = id*1000000 + Q105
	codebook Q105
				
	* CREATE a duplicate
	egen long temp=max(Q105) 
	expand 2 if Q105==temp
	codebook Q105
	
	list Q105 submitdate temp if Q105==temp 
		replace submitdate = "12/17/2020 9:47" if Q105==temp & Q105==Q105[_n-1]
	list Q105 submitdate temp if Q105==temp 
	drop temp		
	
	codebook Q105
	
export delimited using "$DownloadedCSV/LimeSurvey_Community_EXAMPLE_R1.csv", replace 

**************************************************************
* C. Drop Kenya specific questions & change question numbers as needed 
**************************************************************

*****C.1. Case managment 
import delimited "$DownloadedCSV/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", case(preserve) clear

	*** Section 1 
	drop Q103* Q109 Q110other Q113 Q114*
            
	rename Q102 XQ102 
	rename Q107 XQ107  
	rename Q108 XQ108  
	rename Q110 XQ110 
	rename Q111 XQ111  
	rename Q112 XQ112

	rename XQ110 Q102
	rename XQ102 Q103
	rename XQ111 Q107 
	rename XQ107 Q108  
	rename XQ108 Q109  	
	rename XQ112 Q110 

	rename Q115	Q111           
	rename Q116 Q112
	rename Q117 Q113
	rename Q118SQ001 Q114SQ001
	rename Q118SQ002 Q114SQ002

	*** Section 2 /*IMST now shifted to the end of the section 2, following staffing Q from CEHS*/ 
	rename Q201 Q209
	rename Q202sq Q210sq
	
	*** Section 3
	drop Q305b Q306b Q311t - Q314other
	
	generate random = rnormal(1, 0.3)
	replace Q310 = Q309*random 
	sum Q3*
	
	*** Section 4
	rename Q402SQ004 Q401SQ011 
	rename Q402SQ005 Q401SQ012
	
	gen Q401SQ013 = Q401SQ003
	gen Q401SQ014 = Q401SQ004
	
	gen Q401SQ015 = Q401SQ001	

	*** Section 5 /*keep IPC items, but bring all IPC/PPE questions from CEHS*/ 
	d Q5*
	
	drop Q501* Q502* 

	rename Q503SQ001 Q509SQ001
	rename Q503SQ002 Q509SQ003
	rename Q503SQ003 Q509SQ004
	rename Q503SQ004 Q509SQ005
	drop   Q503SQ005     
	rename Q503SQ006 Q509SQ002
	
	*** Section 6 
	
	drop *Time
	
	drop Q604 Q605 
	rename Q603 Q603SQ001
	
		capture drop random
		generate random = runiform()
	gen byte Q603SQ002 = random>=0.5
	
	rename Q608 Q604
	rename (*609*) (*605*)
	
		capture drop random
		generate random = runiform()
	gen byte Q608SQ001 = random>=0.4
	gen byte Q608SQ002 = random>=0.3
		
		capture drop random
		generate random = runiform(50, 200)	
	gen Q609 = int(random )
	gen Q610 = int(random*1.3) 
	
	foreach var of varlist Q608* Q609 Q610{
		replace `var' =. if Q603SQ002!=1
		}
	
		capture drop random
		generate random = runiform()
	gen byte Q611 = random>0.2
		replace Q611 =. if Q603SQ001!=1 & Q603SQ002!=1 

		capture drop random
		generate random = runiform()
	gen byte Q612 = random>0.1	
	gen Q613 = 5
		replace Q613=4 if random<0.5
		replace Q613=3 if random<0.3
		replace Q613=2 if random<0.1
		replace Q613=1 if random<0.05

	foreach var of varlist Q612 Q613{
		replace `var' =. if Q603SQ001==1 & Q603SQ002==1 
		}
			
	foreach var of varlist Q603SQ002 - Q613{
		replace `var' =. if Q601!=1
		}
		
	*** Section 7
	drop Q706* Q708* 
	rename Q707 Q706
	
	*** Section 8 
	
	drop Q8031
		
		/*new AEFI questions: 2/6/2021*/
		capture drop random
		generate random = runiform()
	gen byte Q813 = random>0.3
		capture drop random
		generate random = runiform()
	gen byte Q814 = random>0.4
	
	foreach var of varlist Q813 Q814{
		replace `var' =. if Q812==. 
		}

	*** Section 10 - /*section 9 is now section 10: 3/5/2021*/            
	rename Q901        Q1001 
	rename Q902        Q1002
	rename Q903        Q1003
	rename Q904        Q1004
	rename Q904other	Q1004other		
	
	*** Section 9 - /*NEW section on COVID-vaccine readiness: 3/5/2021*/ 
		capture drop random
		generate random = runiform()
	gen Q901=.
		replace Q901 = 1
		replace Q901 = 2 if random>0.9
		replace Q901 = 3 if random>0.98
		capture drop random
		generate random = runiform()
	gen Q902=.
		replace Q902 = 1
		replace Q902 = 2 if random>0.8
		replace Q902 = 3 if random>0.95
		replace Q902 = . if Q901==3		
		
		capture drop random
		generate random = runiform()	
	gen byte Q903 = random>0.25			
		
	foreach newvar in Q904SQ001 Q904SQ002 Q904SQ003 Q904SQ004 {	
			capture drop random
			generate random = runiform()
	gen `newvar' = . 
			replace `newvar' = 1
			replace `newvar' = 2 if random>0.6
			replace `newvar' = 3 if random>0.9
		}	
		
		capture drop random
		generate random = runiform()	
	gen byte Q905SQ001 = random>0.8
		capture drop random
		generate random = runiform()	
	gen byte Q905SQ002 = random>0.7
		capture drop random
		generate random = runiform()	
	gen byte Q905SQ003 = random>0.9
		capture drop random
		generate random = runiform()	
	gen byte Q905SQ004 = random>0.6

		capture drop random
		generate random = runiform()	
	gen byte Q906 = random>0.05
		capture drop random
		generate random = runiform()	
	gen Q907 = random>0.01
		capture drop random
		generate random = runiform()	
	gen byte Q908 = random>0.02		
		replace Q908 =0 if Q902!=1
		capture drop random
		generate random = runiform()	
	gen byte Q909 = random>0.05		
		replace Q909 =0 if Q902!=1
		
		capture drop random
		generate random = runiform()	
	gen byte Q910 = random>0.05		
		replace Q910 =. if (Q904SQ001==3 & Q904SQ002==3 & Q904SQ003==3) 
		
		capture drop random
		generate random = runiform()	
	gen byte Q911 = random>0.1			
		capture drop random
		generate random = runiform()	
	gen byte Q912 = random>0.15	
	
		capture drop random
		generate random = runiform()
	gen byte Q913 = random>0.3
		capture drop random
		generate random = runiform()
	gen byte Q914 = random>0.4
	
	foreach var of varlist Q904SQ001 - Q914{
		replace `var' =. if Q903==0 
		}	
	
		capture drop random
		
	*** De-identify 
		
	replace Q1BSQ001comment =" "
	replace Q103 =" "
	replace Q108 =" "
	replace Q109 =.
	replace Q1002 =" "
	replace Q1003 =" "
		
export delimited using "$DownloadedCSV/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", replace 
*export delimited using "$DownloadedCSV_YJ/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", replace 

	keep Q101
	rename Q101 facilitycode 
	sort facilitycode
	drop if facilitycode==facilitycode[_n-1]
	gen weight=1
		
export excel using "WHO_COVID19HospitalReadiness_Chartbook_08.21.xlsx", sheet("Weight") sheetreplace firstrow(variables) nolabel keepcellfmt

*****C.2. CEHS 

import delimited "$DownloadedCSV/LimeSurvey_CEHS_EXAMPLE_R1.csv", case(preserve) clear 

	*** Section 1 
	drop Q103* Q109 Q110other Q112month Q112year Q113 Q114*
            
	rename Q102 XQ102 
	rename Q107 XQ107  
	rename Q108 XQ108  
	rename Q110 XQ110 
	rename Q111 XQ111  
	rename Q112 XQ112

	rename XQ110 Q102
	rename XQ102 Q103
	rename XQ111 Q107 
	rename XQ107 Q108  
	rename XQ108 Q109  	
	rename XQ112 Q110 
	
	rename Q115	Q111           
	rename Q116 Q112
	rename Q117 Q113
	rename Q118SQ001 Q114SQ001
	rename Q118SQ002 Q114SQ002
	
	*** Section 2
	drop Q205ySQ009
	drop Q207ySQ010

		/* NEW staff vaccination questinos: 3/22/2021*/ 
		capture drop random
		generate random = runiform()	
	gen byte Q201a = random>0.4
	
		egen totalstaff = rowtotal(Q201*_A1)
		replace totalstaff = . if Q201a==0
		capture drop random
		generate random = runiform()
			replace random=random+0.3 if random<=0.2
			replace random=random-0.3 if random>=0.8
		
	gen Q201b = ceil(totalstaff*random)
	gen Q201c = ceil(totalstaff*random*0.8)
		
		sum Q201*_A1 Q201a totalstaff Q201b Q201c 	
		drop totalstaff
		
	*** Section 3 
	rename Q303H Q303
	drop Q3041*
	
	codebook Q305*
	
	gen Q305=.
		replace Q305=1 if Q305SQ001==1 & Q305SQ002==0
		replace Q305=2 if Q305SQ001==0 & Q305SQ002==1
		replace Q305=3 if Q305SQ001==1 & Q305SQ002==1
		replace Q305=4 if Q305SQ003==1
		replace Q305=5 if Q305SQ004==1
		
	drop Q305SQ*
	
	*** Section 4
	rename Q401H  Q401
	rename Q404H  Q404
	
	drop Q421H
	
	rename (*Q422*) (*Q421*)
	
	*** Section 5 /*revised Q503 series, 2/1/2021 */ 
	drop Q503sqSQ010 
	d Q503*
	
	rename (Q503sqSQ*) (XQ503sqSQ*)
	
	rename XQ503sqSQ001  Q503sqSQ001
	rename XQ503sqSQ002  Q503sqSQ007
	rename XQ503sqSQ003  Q503sqSQ008
	rename XQ503sqSQ004  Q503sqSQ006
	rename XQ503sqSQ005  Q503sqSQ005
	rename XQ503sqSQ006  Q503sqSQ002
	rename XQ503sqSQ007  Q503sqSQ009
	rename XQ503sqSQ008  Q503sqSQ010
	rename XQ503sqSQ009  Q503sqSQ011
	
		capture drop random
		generate random = runiform()
	gen byte Q503sqSQ003 =random<0.7
	gen byte Q503sqSQ004 =random<0.5
		drop random 
		
	*** Section 6
	
	drop Q6081 
	drop Q6091
	
	rename Q612H Q612
	rename Q613H Q613

	*** Section 7
	drop Q702SQ004 - Q702SQ007
	
		/*new seasonal influenza question: 5/12/2021*/ 
	gen Q703sqSQ006 = Q703sqSQ002
 
	*** Section 8 
	
	gen Q802sqSQ005 = Q802sqSQ004
	
	*** Section 9 
	drop Q9031
		
		/*new AEFI questions: 2/6/2021*/ 
		capture drop random
		generate random = runiform()
	gen byte Q913 = random>0.3
		capture drop random
		generate random = runiform()
	gen byte Q914 = random>0.4
	
	foreach var of varlist Q913 Q914{
		replace `var' =. if Q912==. 
		}
		
	*** Section 11 - NA no infrastructure.  
	
	*** Section 12 - section 11 is now section 12  /*section reordered: 3/22/2021*/           
	rename Q1101        Q1201 
	rename Q1102        Q1202
	rename Q1103        Q1203
	rename Q1104        Q1204
	rename Q1104other	Q1204other

	*** Section 10 - NEW section on COVID-vaccine readiness /*new AEFI questions: 3/22/2022*/ 
		capture drop random
		generate random = runiform()
	gen Q1001=.
		replace Q1001 = 1
		replace Q1001 = 2 if random>0.9
		replace Q1001 = 3 if random>0.98
		capture drop random
		generate random = runiform()
	gen Q1002=.
		replace Q1002 = 1
		replace Q1002 = 2 if random>0.8
		replace Q1002 = 3 if random>0.95
		replace Q1002 = . if Q1001==3		
		
		capture drop random
		generate random = runiform()	
	gen byte Q1003 = random>0.25			
		
	foreach newvar in Q1004SQ001 Q1004SQ002 Q1004SQ003 Q1004SQ004 {	
			capture drop random
			generate random = runiform()
	gen `newvar' = . 
			replace `newvar' = 1
			replace `newvar' = 2 if random>0.6
			replace `newvar' = 3 if random>0.9
		}	
		
		capture drop random
		generate random = runiform()	
	gen byte Q1005SQ001 = random>0.8
		capture drop random
		generate random = runiform()	
	gen byte Q1005SQ002 = random>0.7
		capture drop random
		generate random = runiform()	
	gen byte Q1005SQ003 = random>0.9
		capture drop random
		generate random = runiform()	
	gen byte Q1005SQ004 = random>0.6

		capture drop random
		generate random = runiform()	
	gen byte Q1006 = random>0.05
		capture drop random
		generate random = runiform()	
	gen Q1007 = random>0.01
		capture drop random
		generate random = runiform()	
	gen byte Q1008 = random>0.02		
		replace Q1008 =0 if Q1002!=1
		capture drop random
		generate random = runiform()	
	gen byte Q1009 = random>0.05		
		replace Q1009 =0 if Q1002!=1
		
		capture drop random
		generate random = runiform()	
	gen byte Q1010 = random>0.05		
		replace Q1010 =. if (Q1004SQ001==3 & Q1004SQ002==3 & Q1004SQ003==3) 
		
		capture drop random
		generate random = runiform()	
	gen byte Q1011 = random>0.1			
		capture drop random
		generate random = runiform()	
	gen byte Q1012 = random>0.15	
	
		capture drop random
		generate random = runiform()
	gen byte Q1013 = random>0.3
		capture drop random
		generate random = runiform()
	gen byte Q1014 = random>0.4
	
	foreach var of varlist Q1004SQ001 - Q1014{
		replace `var' =. if Q1003==0 
		}	
		
		capture drop random
	
	*** De-identify 
		
	replace Q1BSQ001comment =" "
	replace Q103 =" "
	replace Q108 =" "
	replace Q109 =" "
	replace Q1202 =" "
	replace Q1203 =" "
		
export delimited using "$DownloadedCSV/LimeSurvey_CEHS_EXAMPLE_R1.csv", replace 
*export delimited using "$DownloadedCSV_YJ/LimeSurvey_CEHS_EXAMPLE_R1.csv", replace 

	keep Q101
	rename Q101 facilitycode 
	sort facilitycode
	drop if facilitycode==facilitycode[_n-1]
	gen weight=1
		
export excel using "WHO_CEHS_Chartbook_10.21.xlsx", sheet("Weight") sheetreplace firstrow(variables) nolabel keepcellfmt

*****C.3. Community 

import delimited "$DownloadedCSV/LimeSurvey_Community_EXAMPLE_R1.csv", case(preserve) clear  

	
	*** Section 1 - OK
	
	drop Q103
	rename Q104 Q103 
	
	rename Q112 Q114
	rename Q111 Q113
	rename Q110 Q111 
		replace Q111="A1" if Q111=="A3"
		
	gen Q112 = runiformint(25, 60)	
	
	*** Section 3 - OK
	d Q305 Q306*
	drop Q305 Q306*
	
	*** Section 4
	*create Q405 & Q406 since afghanistan used option 1, ugh...  
	
	d Q40*
	codebook Q401 Q402 Q403
	rename Q401 Q403correct
	rename Q402 Q401
	rename Q403 Q402
	rename Q403correct Q403
		replace Q403="A2" if Q403=="A3" | Q403=="A4"		
		
		capture drop random
		generate random = runiform()
	gen Q405=.
		replace Q405 = 1
		replace Q405 = 2 if random>0.9
		tostring Q405, replace
		replace Q405 = "A" + Q405

		capture drop random
		generate random = runiform()	
	gen byte Q406SQ001 = random>0.8
		capture drop random
		generate random = runiform()	
	gen byte Q406SQ002 = random>0.7
		capture drop random
		generate random = runiform()	
	gen byte Q406SQ003 = random>0.9
		capture drop random
		generate random = runiform()	
	gen byte Q406SQ004 = random>0.6
		capture drop random
		generate random = runiform()	
	gen byte Q406SQ005 = random>0.8
		capture drop random
		generate random = runiform()	
	gen byte Q406SQ006 = random>0.7
		capture drop random
		generate random = runiform()	
	gen byte Q406SQ007 = random>0.9
		capture drop random
		generate random = runiform()	
	gen byte Q406SQ008 = random>0.2
	
	gen Q406other = "other responses" 
	
	foreach var of varlist Q406SQ*{
		replace `var'=. if Q405=="A2"
	}

	* drop section 5 
	capture drop Q5*
	
	
	* Section 6.... 
		
	rename Q601 Q601BSQ001
	rename Q602 Q601BSQ002
	rename Q603 Q601BSQ003
	
		capture drop random
		generate random = runiform()
	gen Q601A=.
		replace Q601A = 1
		replace Q601A = 2 if random>0.95
		tostring Q601A, replace
		replace Q601A = "A" + Q601A
	
	foreach var of varlist Q601BSQ*{
		replace `var'=. if Q601A=="A2"
	}	
			
	rename Q604 Q602 	
	rename (*Q605SQ*) (*Q603SQ*) 
	drop Q605other
	
		capture drop random
		generate random = runiform()	
	gen byte Q603SQ007 = random>0.7	
	
	rename Q606 Q604
	rename Q607 Q605
	rename (*Q608SQ*) (*Q606SQ*)
	
		capture drop random
		generate random = runiform()	
	gen byte Q606SQ009 = random>0.8
		capture drop random
		generate random = runiform()	
	gen byte Q606SQ010 = random>0.7
		capture drop random
		generate random = runiform()	
	gen byte Q606SQ011 = random>0.9
		capture drop random
		generate random = runiform()	
	gen byte Q606SQ012 = random>0.9
	
	gen Q606other = "other responses" 
	
	foreach var of varlist Q606SQ*{
		replace `var'=. if Q405=="A2"
	}
	
	rename (*Q609SQ*) (*Q607SQ*) 
	foreach var of varlist Q607SQ*{
		replace `var' ="A4" if  `var' == "A5" 
	}
		
	drop Q610 - Q613other
	
	rename Q614 Q608
	rename Q615 Q609
			
	*** Section 7
	
	rename (Q702*) (Q704*)	
	
	*** de-identify
	replace Q101 = " "
	replace Q106 = . 
	replace Q107 = " "
	replace Q7011 = " "
	replace Q7012 = " "
	
	/* End of 2/25/2022 edit*/
	
export delimited using "$DownloadedCSV/LimeSurvey_Community_EXAMPLE_R1.csv", replace 
*export delimited using "$DownloadedCSV_YJ/LimeSurvey_Community_EXAMPLE_R1.csv", replace 

**************************************************************
* D. Bring Staffing and IPC/PPE data from CEHS to Hospital (2/1/2021 revision)
**************************************************************
import delimited "$DownloadedCSV/LimeSurvey_CEHS_EXAMPLE_R1.csv", case(preserve) clear
	keep id Q5* Q2* /*keep sections 2 and 5*/
	drop *Time
	d 
	sort id
	save temp.dta, replace 

import delimited "$DownloadedCSV/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", case(preserve) clear
	
	d Q2* Q5*
	
	sort id
	merge id using temp.dta
	
	tab _merge, m
		keep if _merge==3
		drop _merge
	
	erase temp.dta
	
export delimited using "$DownloadedCSV/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", replace
*export delimited using "$DownloadedCSV_YJ/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", replace

END OF DO FILE 
