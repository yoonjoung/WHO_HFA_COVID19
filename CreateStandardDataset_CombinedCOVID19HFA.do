clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code creates "Model" datasets for the Combined HFA data. 
*	Country name = EXAMPLE
*	Round = 3 
*	To test Q version 2022/09/14 + NEW limesurvey generic version 2

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
cd "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/"

*** Define the Downloaded CSV folderes 
global DownloadedCSV "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/ExportedCSV_FromLimeSurvey/"

**************************************************************
* B. Import, select, expand and export 
**************************************************************

import delimited "$DownloadedCSV/results-survey259237.csv", case(preserve) clear

	* keep only actual data entry
	keep if Q101!=.
		codebook Q101
		
	* expand		
	expand 12
		codebook Q101
	
	* manuplate Q101
	set seed 38
	capture drop random
	generate random = runiformint(0,999)
	replace Q101 = int(Q101/1000)*1000 + random
		codebook Q101

	* keep only unique Q101
	sort Q101
	drop if Q101==Q101[_n-1]
		codebook Q101

	* CREATE a duplicate
	egen long temp=max(Q101) 
	expand 3 if Q101==temp
		codebook Q101
		
	list Q101 submitdate temp if Q101==temp 

		replace submitdate = "2022-09-16 23:59:15" if Q101==temp & Q101==Q101[_n-1]
		replace submitdate = "2022-09-17 09:07:59" if Q101==temp & Q101==Q101[_n-1] & Q101!=Q101[_n-2]
	list Q101 submitdate temp if Q101==temp 
	drop temp
	
		codebook Q101
		
export delimited using "$DownloadedCSV/LimeSurvey_CombinedHFA_EXAMPLE_R3.csv", replace 

**************************************************************
* C. manuplate yes/no answers - only for subquestions. 
**************************************************************


import delimited "$DownloadedCSV/LimeSurvey_CombinedHFA_EXAMPLE_R3.csv", case(preserve) clear

	capture drop random
	
	foreach var of varlist Q106 {
	set seed 38	
		generate random = runiform()
		replace `var' = "A2" if `var'=="A1" & random>=0.7
		drop random 
	}		
	
	#delimit; 
	foreach var of varlist 
		Q208SQ* Q210SQ* 
		Q302SQ* Q304SQ* Q305SQ* Q307SQ* 
		Q402SQ* Q415SQ* Q417SQ* 
		Q507SQ* 
		Q601SQ* Q602SQ* Q603SQ* Q604SQ* 
		Q701SQ* Q702SQ* 				
		Q807SQ* Q808SQ* 				 
		Q904SQ* Q909SQ* Q911SQ* 
		{
		;
		#delimit cr
	set seed 38
		generate random = runiform()
		replace `var' = "A2" if `var'=="A1" & random>=0.8
		drop random 
	}
	
	foreach var of varlist Q504SQ* {
	set seed 38
		generate random = runiform()
		replace `var' = 2 if `var'==1 & random>=0.8
		drop random 
	}	
	
	foreach var of varlist Q501SQ*2 Q505SQ*2 {
	set seed 38	
		generate random = runiform()
		replace `var' = "A1" if `var'=="A2" & random>=0.8
		drop random 
	}	
	
export delimited using "$DownloadedCSV/LimeSurvey_CombinedHFA_EXAMPLE_R3.csv", replace 	

**************************************************************
* C. create and normalize sampling weights
**************************************************************
	
import delimited "$DownloadedCSV/LimeSurvey_CombinedHFA_EXAMPLE_R3.csv", case(preserve) clear

	keep Q101
	rename Q101 facilitycode 
	sort facilitycode
	drop if facilitycode==facilitycode[_n-1]
	
	*gen weight=1

	set seed 38
	gen weight=rnormal(1, 0.1)
	sum weight
	replace weight = weight/r(mean)
	sum weight

*export excel using "WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Weight") sheetreplace firstrow(variables) nolabel keepcellfmt
export excel using "CombinedCOVID19HFA_Chartbook_draft.xlsx", sheet("Weight") sheetreplace firstrow(variables) nolabel keepcellfmt

**************************************************************
* D. Create another version with different submitdate with seconds
**************************************************************

import delimited "$DownloadedCSV/LimeSurvey_CombinedHFA_EXAMPLE_R3.csv", case(preserve) clear
	
	gen seconds = runiformint(10, 59)	
	tostring seconds, replace 
	gen test = submitdate + ":" + seconds
	*list submitdate seconds test
	replace submitdate = test
	*list submitdate seconds test
	drop seconds test
	
export delimited using "$DownloadedCSV/LimeSurvey_CombinedHFA_EXAMPLE_R3_V2.csv", replace
	
END OF DO FILE 
