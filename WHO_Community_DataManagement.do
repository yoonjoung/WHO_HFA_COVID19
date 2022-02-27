clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code was last updated on 2/27/2022
*1) imports and cleans Continuity of EHS dataset from Lime Survey, 
*	created based on the October 29, 2021 Q version
*2) creates field check tables for data quality monitoring, and 
*3) creates indicator estimate data for dashboards and chartbook. 

*  DATA IN:	CSV file daily downloaded from Limesurvey 	
*  DATA OUT to chartbook: 
*		1. raw data (as is, downloaded from Limesurvey) in Chartbook  	
*		2. cleaned data with additional analytical variables in Chartbook and, for further analyses, as a datafile 
*		3. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	

*AT MINIMUM, THREE parts must be updated per country-specific adaptation. See "MUST BE ADAPTED" below 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: 1. directories and local
* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey 
*****B.2. Export/save the data daily in CSV form with date 
*****B.3. Export the data to chartbook  
*****B.4. Drop duplicate cases 
* C. Data cleaning - variables
*****C.1. Change var names to lowercase	
*****C.2. Change var names to make then coding friendly 
*****C.3. Find non-numeric variables and desting 
*****C.4. Recode yes/no & yes/no/NA
*****C.5. Label values 
* D. Create field check tables 
* E. Create analytical variables 
*****E.1. Country speciic code local <<<<<<<<<<========== MUST BE ADAPTED: 2. local per survey implementation and section 1 
*****E.2. Construct analysis variables <<<<<<<<<<========== MUST BE ADAPTED: 3. country specific staffing - section 2 
*****E.2.A Rename detailed indicators ending with sub-question numbers with more friendly/intuitive names
*****E.3. Export clean Respondent-level data to chart book 
* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book and dashboard

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
*cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*cd "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan"
cd "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/"

*** Directory for downloaded CSV data, if different from the main directory
*global downloadcsvdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"
*global downloadcsvdir "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan\ExportedCSV_FromLimeSurvey"
global downloadcsvdir "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/ExportedCSV_FromLimeSurvey/"

*** Define a directory for the chartbook, if different from the main directory 
*global chartbookdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*global chartbookdir "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\3.AnalysisPlan"
global chartbookdir "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/"

*** Define local macro for the survey 
local country	 		 COUNTRYNAME /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2020 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/				

local surveyid 			 777777 /*LimeSurvey survey ID*/

*** local macro for analysis: no change needed  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)

**************************************************************
* B. Import and drop duplicate cases
**************************************************************
	
*****B.1. Import raw data from LimeSurvey 
*import delimited using "https://who.my-survey.host/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear
*import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear
	/*
	
	NOTE
	
	For the URL, we need to use part of the country overview page for the data server. For example, suppose the overview page link looks like this for a country named YYY:
	https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&country=YYY&password=XXXXXXXXX.

	Replace part of the link before plugins with the part in the country-specific link. So, the code should be: 

	import delimited using "https://extranet.who.int/dataformv3/index.php/plugins/direct?plugin=CountryOverview&docType=1&sid=`surveyid'&language=en&function=createExport", case(preserve) clear

	*/
import delimited "$downloadcsvdir/LimeSurvey_Community_EXAMPLE_R1.csv", case(preserve) clear  /*THIS LINE ONLY FOR PRACTICE*/
		
*****B.2. Export/save the data daily in CSV form with date 
export delimited using "$downloadcsvdir/LimeSurvey_Community_`country'_R`round'_$date.csv", replace 

*****B.3. Export the data to chartbook  	
	
	codebook token Q105
	list Q1* if Q105==. | token=="" 
	*****CHECK: this is an empty row. There should be none	
	
	*****MASK idenitifiable information*/
	foreach var of varlist Q101 Q107 Q7011 Q7012{
		replace `var'=""
		}		
		replace Q106=. 

export excel using "$chartbookdir/WHO_Community_Chartbook_Feb2022.xlsx", sheet("Respondent-level raw data") sheetreplace firstrow(variables) nolabel
	
*****B.4. Drop duplicate cases 
	
	lookfor id
	rename *id id
	codebook id 
	*****CHECK HERE: this is an ID variable generated by LimeSurvey, not facility ID. still there should be no missing*/	

	*****identify duplicate cases, based on RESPONDENT code*/
	duplicates tag Q105, gen(duplicate) 
				
		rename submitdate submitdate_string			
	gen double submitdate = clock(submitdate_string, "MDY hm")
		format submitdate %tc
				
	list Q105 Q106 submitdate* startdate datestamp if duplicate==1 
	*****CHECK HERE: In the model data, there is one duplicate for practice purpose. 
		
	*****drop duplicates before the latest submission */
	egen double submitdatelatest = max(submitdate) if duplicate==1, by(Q105) /*LATEST TIME WITHIN EACH DUPLICATE YC edit 6/29/2021*/
						
		format %tcnn/dd/ccYY_hh:MM submitdatelatest
		
		list Q105 Q106 submitdate* if duplicate==1	
	
	drop if duplicate==1 & submitdate!=submitdatelatest 

	*****confirm there's no duplicate cases, based on facility code*/
	duplicates report Q105
	*****CHECK HERE: Now there should be no duplicate 
	
	drop duplicate submitdatelatest
	
**************************************************************
* C. Destring and recoding 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.1.a. Assess timestamp data 
		
	***** drop detailed timstamp data but keep interviewtime (interview length in seconds)
	drop q*time 
	drop grouptime* 
	
	*REVISION: 4/20/2021
	*interviewtime is availabl in dataset only when directly downloaded from the server, not via export plug-in used in this code
	*thus below C.1.a is suppressed
	/*
	codebook interviewtime 
	gen long interviewlength=round(interviewtime/60, 1) 
		lab var interviewlength "interview length in minutes"
		sum interviewlength
	*/
	
*****C.2. Change var names to drop unnecessary elements e.g., "sq" - because of Lime survey's naming convention 
	
	d *sq*
	
	rename (*sq*) (*_*) /*replace sq with _*/
	
	lookfor sq

*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	sum q1*
	codebook q108 q109 q111 q113 q114
										
	foreach var of varlist q108 q109 q111 q113 q114  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}
		
	d q1*	
		
	*****************************	
	* Section 2
	*****************************
	sum q2*
	codebook q201_*

	foreach var of varlist q201_*{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	d q2*		

	*****************************	
	* Section 3
	*****************************
	sum q3*
	*rename q303_09 q303_009 
	codebook q302 
		
	foreach var of varlist q302 {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
	
	d q3*
	
	*****************************	
	* Section 4 - option 2 in the October 29 version Q
	*****************************
	
	* Few countries would need to choose option 1 
	* If option 1 is truly needed, refer to the older analysis code. 
	
	sum q4*

	codebook q401 q402 q403 q405
	
	foreach var of varlist q401 q402 q403 q405{		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	
	d q4*
		
	*****************************
	* Section 5 - deleted in the October 29 version Q
	*****************************
			
	*****************************			
	* Section 6
	*****************************
	
	sum q6*

	codebook q601a q602 q604 q605 q607_* q608 q609 
	
	foreach var of varlist q601a q602 q604 q605 q607_* q608 q609 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	d q6*		
	
	*****************************			
	* Section 7
	*****************************
	sum q7*
	codebook q701 q704
	
	foreach var of varlist q701 q704 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
				
*****C.4. Recode yes/no 
	
	#delimit;
	sum		
		q301_*  q303_* q304_* 
		q403 q404_* q405 q406_*
		q601* q603_* q606_* q608
		; 
		#delimit cr
	
	#delimit;
	foreach var of varlist 
		q301_*  q303_* q304_* 
		q403 q404_* q405 q406_*
		q601* q603_* q606_* q608
		{; 
		#delimit cr		
		recode `var' 2=0 /*no*/
		}

*****C.5. Label values 

	#delimit;	
	
	lab define yesno 1"1. yes" 0"0. no"; 	
	foreach var of varlist 
		q301_*  q303_* q304_* 
		q403 q404_* q405 q406_*
		q601* q603_* q606_* q608
		{; 
	labe values `var' yesno; 
	};		

	lab define sex
		1"1.Male" 
		2"2.Female"
		3"3.Not responded";  
	lab values q111 sex; 

	lab define occupation
		1"1.Commnity leader" 
		2"2.Community health officer"
		3"3.Commuunity health volunteer"
		4"4.Civil society/NGOs";  
	lab values q113 occupation; 
			
	lab define area
		1"1.Urban"
		2"2.Rural";
	lab values q114 area; 			  
	
	lab define people3
		1"1.Most people"
		2"2.Some peoople"
		3"3.Few people"; 
	foreach var of varlist q201_*{;	
		lab values `var' people3;
		};
	
	lab define q302
		1"1.Remained stable"
		2"2.Moderately affected"
		3"3.Strongly affected"; 
	lab values q302 q302; 
	
	lab define people4
		1"1.Most peoople"
		2"2.Some people – more than half"
		3"3.Some people – less than half" 
		4"4.Few people" ;
	foreach var of varlist q401 q402 q403{;	
		lab values `var' people4;
		};
		
	lab define q602
		1"1.No risk"
		2"2.Slight"
		3"3.Moderate"
		4"4.High"
		5"5.Very high";  
	lab values q602 q602; 
	
	lab define q604
		1"1.Never"
		2"2.Sometimes"
		3"3.Often";  
	lab values q604 q604; 	
				
	lab define q605
		1"1.Most support"
		2"2.Some support"
		3"3.Little support";  
	lab values q605 q605; 	
	
	lab define q607
		1"1.Slightly reduced"
		2"2.Substantially reduced or suspended"
		3"3.Increased"
		4"3.No change";  	
	foreach var of varlist q607_* {;	
		lab values `var' q607;
		};

	#delimit cr
	
**************************************************************
* D. Create field check tables for data quality check  
**************************************************************	

* generates daily field check tables in excel

preserve

			gen updatedate = "$date"
	
	tabout updatedate using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", replace ///
		cells(freq col) h2("Date of field check table update") f(0 1) clab(n %)

			split submitdate_string, p(" ")
			gen date=date(submitdate_string1, "MDY") 
			format date %td
						
	tabout submitdate_string1 using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Date of interviews (submission date, final)") f(0 1) clab(n %)
			
			gen xresult=q704==1
			
			gen byte responserate= xresult==1
			label define responselist 0 "Not complete" 1 "Complete"
			label val responserate responselist

	tabout responserate using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Interview response rate") f(0 1) clab(n %)
	
	tabout q114 using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by area") f(0 1) clab(n %)
		
	tabout q113 using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by respondent occupation") f(0 1) clab(n %)		

	*REVISION: 4/20/2021		
	*suppress fieldcheck tables containing interviewlength
	/*	
			bysort xresult: sum interviewlength
			egen time_complete = mean(interviewlength) if xresult==1
			egen time_incomplete = mean(interviewlength) if xresult==0
				replace time_complete = round(time_complete, 1)
				replace time_incomplete = round(time_incomplete, 1)

	tabout time_complete using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among completed interviews") f(0 1) clab(n %)		
	tabout time_incomplete using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among incomplete interviews") f(0 1) clab(n %)	
	*/
	
* Missing responses 

			capture drop missing
			gen missing=0
			foreach var of varlist q704 {	
				replace missing=1 if `var'==.				
				}		
			lab values missing yesno		
			
	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("0. Missing survery results (among all interviews)") f(0 1) clab(n %)									

keep if xresult==1 /*the following calcualtes % missing in select questions among completed interviews*/		

			capture drop missing
			gen missing=0
			foreach var of varlist q201_* {	
				replace missing=1 if `var'==.
				}			
			lab values missing yesno

	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("1. Missing unmet need responses in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					
	
			capture drop missing
			gen missing=0
			foreach var of varlist q303_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q302==1
			tab missing, m	
			lab values missing yesno		
			
	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("2. Missing reason for unmet need during the pandemic in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q402 q403 {	
				replace missing=1 if `var'==.
				}		
			tab missing, m
			lab values missing yesno		

	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("4. Missing vaccine demand among adults, when applicable (among completed interviews)") f(0 1) clab(n %)					
	
			capture drop missing
			gen missing=0
			foreach var of varlist q404_* {	
				replace missing=1 if `var'==.
				}		
				replace missing=. if q402==1 
			lab values missing yesno		

	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("5. Missing reasons for no vaccine demand in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q603_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q602<=2
			lab values missing yesno		

	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("8. Missing reasons for risks (among completed interviews)") f(0 1) clab(n %)			
				
			capture drop missing
			gen missing=0
			foreach var of varlist q604 {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("9. Missing CHW stigma (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q606_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q605==1
			lab values missing yesno		

	tabout missing using "$chartbookdir/FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("10. Missing support needed (among completed interviews)") f(0 1) clab(n %)					
	
restore

**************************************************************
* E. Create analytical variables 
**************************************************************

*****E.1. Country specific code local 
		
		local urbanmin			 1 	
		local urbanmax			 1
				
		local chwmin			 2
		local chwmax			 3
				
*****E.2. Construct analysis variables 

	*****************************
	* Section 1 
	*****************************
	
	gen country = "`country'"
	gen round =`round'
	
	gen respondentcode=q105  

	gen month	=`month'
	gen year	=`year'

	*gen zsex	
	gen zchw	=q113>=`chwmin' & q113<=`chwmax'
	gen zurban	=q114>=`urbanmin' & q114<=`urbanmax'   
	
	lab define zchw 0"non CHWs" 1"CHWs"
	lab values zchw zchw
	
	lab define zurban 0"Rural" 1"Urban"
	lab values zurban zurban
	
	lab var id "ID generated from Lime Survey"

	*****************************
	* Section 2: need and use 
	*****************************

	global itemlist "001 002 003 004 005 006 007 008 009 010"

	foreach item in $itemlist{	
		gen xunmetsomemost__`item' 	= q201_`item'>=2 & q201_`item'!=.
		}			
	foreach item in $itemlist{	
		gen xunmetmost__`item' 	= q201_`item'==3 
		}	
	
	foreach item in xunmetsomemost xunmetmost{	
		egen `item'_num=rowtotal(`item'__*) 
		gen `item' = `item'_num>=1 

		egen `item'_urgent_num=rowtotal(`item'__001) 
		gen `item'_urgent = `item'_urgent_num>=1 
		
		egen `item'_chronic_num=rowtotal(`item'__003 `item'__004) 
		gen `item'_chronic = `item'_chronic_num>=1 		
		
		egen `item'_rmch_num=rowtotal(`item'__006 `item'__007 `item'__008 `item'__009) 
		gen `item'_rmch = `item'_rmch_num>=1 	
		
		*egen `item'_hivtb_num=rowtotal(`item'__010) 
		*gen `item'_hivtb = `item'_hivtb_num>=1 	
	}
	
	gen xunmetsome = xunmetsomemost - xunmetmost
	
	foreach item in urgent chronic rmch {	
		gen xunmetsome_`item' = xunmetsomemost_`item' - xunmetmost_`item'
		}
	
	drop *_num
	sum xunmet*
		
	*****************************
	* Section 3: barriers 
	*****************************
	
	***** Pre-COVID barriers

	gen xbar_pre_demand =0
	gen xbar_pre_info =0
	gen xbar_pre_phacc =0
	gen xbar_pre_fin =0
	gen xbar_pre_qinput =0
	gen xbar_pre_qexp =0
	gen xbar_pre_admin =0

		/*	
		RESPONSE OPTIONS FROM THE QUESTIONNAIRE 
		
		Informational and cultural reasons
		xbar_pre_info 1.	Not knowing about available services 
		xbar_pre_demand 2.	Traditional or folk medicines preferred 
		xbar_pre_demand 3.	Religious Affiliation 

		Physical access and cost reasons 
		xbar_pre_phacc 4.	Health facility too far 
		xbar_pre_phacc 5.	Lack of transportation to facilities 
		xbar_pre_phacc 6.	Lack of transportation for referral between facilities
		xbar_pre_fin 7.	Service fees too high 
		xbar_pre_fin 8.	Informal payments or bribe expected 

		Facility reasons 
		xbar_pre_qinput 9.	Perceived lack of health workers at facilities 
		xbar_pre_qinput 10.	Perceived lack of medicines at facilities
		xbar_pre_qinput 11.	Perceived lack of equipment at facilities
		xbar_pre_qexp 12.	Perceived lack of culturally/religiously sensitive services
		xbar_pre_qexp 13.	Disrespectful providers at facilities 
		xbar_pre_qexp 14.	Mistrust against providers or facilities 
		xbar_pre_qexp 15.	Discrimination against certain communities 
		xbar_pre_admin 16.	In convenient opening hours 
		xbar_pre_admin 17.	Long wait time 
		xbar_pre_admin 18.	Administrative requirements that exclude certain people (e.g. registration in local area, citizenship) 
		*/		
		
		foreach item in 002 003 {	
			replace xbar_pre_demand =1 	if q301_`item'==1
			}		
		foreach item in 001 {	
			replace xbar_pre_info =1 	if q301_`item'==1
			}	
		foreach item in 004 005 006 {	
			replace xbar_pre_phacc =1 	if q301_`item'==1
			}		
		foreach item in 007 008 {	
			replace xbar_pre_fin =1 	if q301_`item'==1
			}			
		foreach item in 009 010 011 {	
			replace xbar_pre_qinput =1 	if q301_`item'==1
			}			
		foreach item in 012 013 014 015 {	
			replace xbar_pre_qexp =1 	if q301_`item'==1
			}					
		foreach item in 016 017 018 {	
			replace xbar_pre_admin =1 	if q301_`item'==1
			}	
			
	***** Overall barriers during COVID "affected/deteriorated" 
	
	gen byte xbar_covid = q302>=2 & q302!=.
	
	***** During COVID barriers  
	
	gen xbar_covid_fear =0
	gen xbar_covid_rec =0
	gen xbar_covid_info =0
	gen xbar_covid_phacc =0
	gen xbar_covid_fin =0
	gen xbar_covid_admin =0
	gen xbar_covid_qinput =0
	gen xbar_covid_qexp =0
	
		/*	
		RESPONSE OPTIONS FROM THE QUESTIONNAIRE 
		
		Information, perception, and government recommendations reasons
		xbar_covid_fear 1.	Fear of getting infected with COVID-19 at facilities 
		xbar_covid_fear 2.	Fear of getting infected with COVID-19 by leaving house 
		xbar_covid_fear 3.	Stigma associated with COVID-19
		xbar_covid_rec 4.	Recommendations to the public to avoid facility visits for mild illness during the pandemic
		xbar_covid_rec 5.	Recommendations to the public to delay routine care visits until further notice during the pandemic
		xbar_covid_info 6.	Not knowing where to seek care during the pandemic 
		Physical access and cost reasons
		xbar_covid_phacc 7.	Lockdown/curfew or stay-at-home order 
		xbar_covid_phacc 8.	Disruption in public transportation
		xbar_covid_fin 9.	Household income dropped during the pandemic
		xbar_covid_fin 10.	Lost health insurance during the pandemic 
		xbar_covid_fin 11.	Higher cost because of unavailability of regular care provider (e.g. need to go to providers who charge higher fees)
		Facility reasons
		xbar_covid_admin 12.	Facility closure due to COVID-19
		xbar_covid_admin 13.	Reduced or changed opening hours at facilities due to COVID-19
		xbar_covid_admin 14.	Provision of specific services suspended at facilities due to COVID-19
		xbar_covid_qinput 15.	Disrupted or poor service provision at facilities due to COVID-19 (limited availability of medicines, commodities, and staff)
		xbar_covid_qexp 16.	Longer wait time at facilities because of current crisis context 
		xbar_covid_fear 17.	Fear of being quarantined  
		18.	Other, specify _________________

		*/	
		foreach item in 001 002 003 017 {	
			replace xbar_covid_fear =1 	if q303_`item'==1
			}		
		foreach item in 004 005 {	
			replace xbar_covid_rec =1 	if q303_`item'==1
			}		
		foreach item in 006 {	
			replace xbar_covid_info =1 	if q303_`item'==1
			}	
		foreach item in 007 008 {	
			replace xbar_covid_phacc =1 	if q303_`item'==1
			}		
		foreach item in 009 010 011 {	
			replace xbar_covid_fin =1 	if q303_`item'==1
			}			
		foreach item in 012 013 014 {	
			replace xbar_covid_admin =1 	if q303_`item'==1
			}					
		foreach item in 015 {	
			replace xbar_covid_qinput =1 	if q303_`item'==1
			}			
		foreach item in 016 {	
			replace xbar_covid_qexp =1 	if q303_`item'==1
			}	
						
	***** Source of care 
	
	global itemlist "001 002 003 004 005 006 007 008 009 010 011"
	foreach item in $itemlist{	
		gen xsource__`item' 		= q304_`item'==1
		}	
		
	gen xsource_trained	=0
		foreach item in 001 002 003 004 005 006 007 008  {	
			replace xsource_trained	=1 	if q304_`item'==1 /*COUNTRY-SPECIFIC MUST BE ADAPTED*/
			}		
			

	*****************************
	* Section 4: vaccine 
	*****************************
	
	gen byte xconcern_most 		= q401<=1
	gen byte xconcern_mostsome 	= q401<=2
	
	gen byte xvac_adult_most 	= q402<=1
	gen byte xvac_adult_mostsome= q402<=2
	
	
	/* 2/25/2022 eidt starts */
	*no more xvac_child_* and, thus, xvac_most*	
	
	gen byte xvac_noaccess 	= q403==1 
	
	global itemlist "001 002 003 004 005 006 007"
	foreach item in $itemlist{	
		gen xvac_noaccess_reason__`item' 		= q404_`item'==1
		}		
	
	/*
	
	RESPONSE OPTIONS FROM QUESTIONNAIRE
	
	1. Not yet eligible for the COVID-19 vaccine, and waiting to become eligible  
	2. It is too far to visit a vaccination site or facility  
	3. There are too many people at a vaccination site and wait time is too long 
	4. There are not enough staff at a vaccination site and wait time is too long  
	5. It is difficult to make an app for the vaccination 
	6. Concerned about cost  
	7. Other 
	*/
	gen	xvac_noaccess_reason_eligible = xvac_noaccess_reason__001==1
	gen	xvac_noaccess_reason_distance	= xvac_noaccess_reason__002==1 
	gen	xvac_noaccess_reason_wait 	= xvac_noaccess_reason__003==1 | xvac_noaccess_reason__004==1
	gen	xvac_noaccess_reason_app 		= xvac_noaccess_reason__005==1 
	gen	xvac_noaccess_reason_cost		= xvac_noaccess_reason__006==1 	

	foreach var of varlist xvac_noaccess_reason* {
		replace `var' = . if xvac_noaccess !=1
		}
	
	gen byte xvac_nowant 	= q405==1 
	
	/* 2/25/2022 eidt endss */
	
	global itemlist "001 002 003 004 005 006 007 008"
	foreach item in $itemlist{	
		gen xvac_reason__`item' 		= q406_`item'==1
		}		
	
	/*
	
	RESPONSE OPTIONS FROM QUESTIONNAIRE
	
	1.	Not concerned about getting infected with COVID-19 
	2.	Uncertain if the COVID-19 vaccine will be effective 
	3.	Concerned about side effects of the COVID-19 vaccine
	4.	Do not want to go to facilities for fear of getting infected with COVID-19
	5.	General mistrust/opposition against any vaccine
	6.	Too busy to get vaccinated
	7.	Concerned about cost 
	8.	Other, specify _________________
	*/
	gen	xvac_reason_noconcern 	= xvac_reason__001==1
	gen	xvac_reason_exposure	= xvac_reason__004==1 
	gen	xvac_reason_anticovac 	= xvac_reason__002==1 | xvac_reason__003==1
	gen	xvac_reason_antivac 	= xvac_reason__005==1 
	gen	xvac_reason_time 		= xvac_reason__006==1 
	gen	xvac_reason_cost 		= xvac_reason__007==1 

	foreach var of varlist xvac_reason*{
		replace `var' = . if xvac_nowant !=1
		}
	
	sum xvac*
		
	*****************************
	* Section 5: Community assets and vulnerabilities - dropped in October 29, 2021 version
	*****************************	
		
	*****************************
	* Section 6: CHW service provision 
	*****************************
	
	/* 2/25/2022 eidts */
	* no more xknowledge 
	* new q601*
	* q603_003
	* new sub quesitons in q606
	* q6080 & q609	
	
	gen byte xtraining = q601a==1
	
	global itemlist "001 002 003"
	foreach item in $itemlist{	
		gen xtraining__`item' 	= q601b_`item'==1
		}						
	
	gen byte xrisk_modhigh	=q602>=3 & q602!=.
	gen byte xrisk_high	=q602>=4 & q602!=.

	global itemlist "001 002 003 004 005 006 007"
	foreach item in $itemlist{	
		gen xrisk_reason__`item' 		= q603_`item'==1
		}					
	
	gen byte xstigma	=q604>=2 & q604!=.
	
	gen byte xsupport_most		=q605<=1
	gen byte xsupport_somemost	=q605<=2
	
	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012"
	foreach item in $itemlist{	
		gen xsupportneed__`item' 		= q606_`item'==1
		}
		
	****************************************************************************
	*REVISION 2021/10/25 based on feedback from the Ghana team 
	*replace with missing if not applicable 
	*this is my oversight. we should change this - just like in other reasons questions*/
	foreach var of varlist xrisk_reason__*{ 
		replace `var'=. if xrisk_modhigh==0
		}
	
	*END OF REVISION 2021/10/25 
	****************************************************************************				
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xsrvc_reduced__`item' 		= q607_`item'<=2
		}		
	foreach item in $itemlist{	
		gen xsrvc_increased__`item' 	= q607_`item'==3
		}				
	foreach item in $itemlist{	
		gen xsrvc_nochange__`item' 		= q607_`item'==4
		}		
	*exclude facilities that do not provide this service in calculation*	
	foreach item in $itemlist{	
		replace xsrvc_reduced__`item' 		=. if q607_`item'==5 
		replace xsrvc_increased__`item' 	=. if q607_`item'==5
		replace xsrvc_nochange__`item' 		=. if q607_`item'==5
		}		
	
	gen byte xself_covax_any	=q608==1 
	gen byte xself_covax_full	=q608==1 & q609<=2
	
	
*****E.2.Addendum
**		Rename indicators ending with sub-question numbers with more friendly names. 
**		These names are used in the dashboard. 
**		Thus, it is important to ensure the indicator names are correct, if questionnaire is adapted beyond minimum requirements.
**		(Addendum on August 17, 2021)

		rename	xunmetsomemost__001	xunmet__urgent
		rename	xunmetsomemost__002	xunmet__electsurg
		rename	xunmetsomemost__003	xunmet__chronicmeds
		rename	xunmetsomemost__004	xunmet__testing
		rename	xunmetsomemost__005	xunmet__mental
		rename	xunmetsomemost__006	xunmet__fp
		rename	xunmetsomemost__007	xunmet__anc
		rename	xunmetsomemost__008	xunmet__sba
		rename	xunmetsomemost__009	xunmet__immun
		rename	xunmetsomemost__010	xunmet__homebased
				
		rename	xunmetmost__001	xunmetmost__urgent
		rename	xunmetmost__002	xunmetmost__electsurg
		rename	xunmetmost__003	xunmetmost__chronicmeds
		rename	xunmetmost__004	xunmetmost__testing
		rename	xunmetmost__005	xunmetmost__mental
		rename	xunmetmost__006	xunmetmost__fp
		rename	xunmetmost__007	xunmetmost__anc
		rename	xunmetmost__008	xunmetmost__sba
		rename	xunmetmost__009	xunmetmost__immun
		rename	xunmetmost__010	xunmetmost__homebased
				
		rename	xsource__001	xsource__chw
		rename	xsource__002	xsource__healthpost
		rename	xsource__003	xsource__hospital
		rename	xsource__004	xsource__pharm
		rename	xsource__005	xsource__c19testcentre
		rename	xsource__006	xsource__c19phone
		rename	xsource__007	xsource__othertrained
		rename	xsource__008	xsource__traditional
		rename	xsource__009	xsource__internet
		rename	xsource__010	xsource__other
		rename	xsource__011	xsource__none
		
		rename	xvac_noaccess_reason__001		xvac_noaccess_reason__eligible
		rename	xvac_noaccess_reason__002		xvac_noaccess_reason__distance
		rename	xvac_noaccess_reason__003		xvac_noaccess_reason__waitcrowd
		rename	xvac_noaccess_reason__004		xvac_noaccess_reason__waitstaff
		rename	xvac_noaccess_reason__005		xvac_noaccess_reason__app
		rename	xvac_noaccess_reason__006		xvac_noaccess_reason__cost
		rename	xvac_noaccess_reason__007		xvac_noaccess_reason__other
		
		rename	xvac_reason__001	xvac_reason__notconcerned
		rename	xvac_reason__002	xvac_reason__uncertain
		rename	xvac_reason__003	xvac_reason__sideeffects
		rename	xvac_reason__004	xvac_reason__avoidfacilities
		rename	xvac_reason__005	xvac_reason__mistrust
		rename	xvac_reason__006	xvac_reason__toobusy
		rename	xvac_reason__007	xvac_reason__cost
		rename	xvac_reason__008	xvac_reason__other
		
		rename  xtraining__001		xtraining__spread
		rename  xtraining__002		xtraining__mask
		rename  xtraining__003		xtraining__covax
		
		rename	xrisk_reason__001	xrisk_reason__manypeople
		rename	xrisk_reason__002	xrisk_reason__ppelack
		rename	xrisk_reason__003	xrisk_reason__novax
		rename	xrisk_reason__004	xrisk_reason__age
		rename	xrisk_reason__005	xrisk_reason__hours
		rename	xrisk_reason__006	xrisk_reason__transport
		rename	xrisk_reason__007	xrisk_reason__public
				
		rename	xsupportneed__001	xsupportneed__monetary
		rename	xsupportneed__002	xsupportneed__ppe
		rename	xsupportneed__003	xsupportneed__supp
		*rename	xsupportneed__004	xsupportneed__traincovid
		rename	xsupportneed__004	xsupportneed__tc_protection	
		rename	xsupportneed__005	xsupportneed__tc_prevention
		rename	xsupportneed__006	xsupportneed__tc_vax
		rename	xsupportneed__007	xsupportneed__tc_management
		rename	xsupportneed__008	xsupportneed__tc_othercovid
		
		rename	xsupportneed__009	xsupportneed__trainother
		rename	xsupportneed__010	xsupportneed__trans
		rename	xsupportneed__011	xsupportneed__insurance
		rename	xsupportneed__012	xsupportneed__other
				
		rename	xsrvc_reduced__001	xsrv_reduced__immune
		rename	xsrvc_reduced__002	xsrv_reduced__malaria
		rename	xsrvc_reduced__003	xsrv_reduced__ntd
		rename	xsrvc_reduced__004	xsrv_reduced__tb
		rename	xsrvc_reduced__005	xsrv_reduced__home
				
		rename	xsrvc_increased__001	xsrv_increased__immune
		rename	xsrvc_increased__002	xsrv_increased__malaria
		rename	xsrvc_increased__003	xsrv_increased__ntd
		rename	xsrvc_increased__004	xsrv_increased__tb
		rename	xsrvc_increased__005	xsrv_increased__home
				
		rename	xsrvc_nochange__001	xsrv_nochange__immune
		rename	xsrvc_nochange__002	xsrv_nochange__malaria
		rename	xsrvc_nochange__003	xsrv_nochange__ntd
		rename	xsrvc_nochange__004	xsrv_nochange__tb
		rename	xsrvc_nochange__005	xsrv_nochange__home

	sort id
	save Community_`country'_R`round'.dta, replace 		

	export delimited using Community_`country'_R`round'.csv, replace 
	
*****E.3. Export clean Respondent-level data to chart book 

	export excel using "$chartbookdir/WHO_Community_Chartbook_Feb2022.xlsx", sheet("Respondent-level cleaned data") sheetreplace firstrow(variables) nolabel
		
**************************************************************
* F. Create indicator estimate data 
**************************************************************

use Community_`country'_R`round'.dta, clear
	
	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	gen obs_chw=1 if zchw==1 	
	*gen obs_vacreason=1 if xvac_most!=1
	gen obs_vacreason=1 if xvac_adult_most!=1 /*2/25/2022 no more xvac_most, since we ask about adults only*/
	
	****************************************************************************
	*REVISION 2021/10/25 based on feedback from the Ghana team 
	*CREATE ADDITIONAL "OBS" VARIABLES TO HAVE CORRECT DENOMINATORS IN THE CHARTBOOK 

	gen obs_riskreason=1 		if xrisk_modhigh==1 /*moderate OR high OR very high*/

	*END OF REVISION 2021/10/25 
	****************************************************************************		
	save temp.dta, replace 

*****F.1. Calculate estimates 

	use temp.dta, clear
	collapse (count) obs* (mean) x* , by(country round month year  )
		gen group="All"
		gen grouplabel="All"
		keep obs* country round month year  group* x* 
		save summary_Community_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x* , by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="1.1 Rural" if zurban==0
			replace grouplabel="1.2 Urban" if zurban==1
		keep obs* country round month year  group* x* 
		
		append using summary_Community_`country'_R`round'.dta, force
		save summary_Community_`country'_R`round'.dta, replace 		
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* , by(country round month year   zchw)
		gen group="Occupation"
		gen grouplabel=""
			replace grouplabel="2.1 non CHWs" if zchw==0
			replace grouplabel="2.2 CHWs" if zchw==1
		keep obs* country round month year  group* x* 
		
		append using summary_Community_`country'_R`round'.dta, force
		save summary_Community_`country'_R`round'.dta, replace 
	
	***** convert proportion to %
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
			
	tab grouplabel round, m
	
	/*
	***** round the number of observations, in case sampling weight was used (edit 5/22/2021)
	* But this is not relevant for the community KIS design. 
	foreach var of varlist obs*{
		replace `var' = round(`var', 1)
		}	
	*/
	
	***** organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs* 
		
	sort country round group grouplabel

save summary_Community_`country'_R`round'.dta, replace 

export delimited using summary_Community_`country'_R`round'.csv, replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_Community_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$chartbookdir/WHO_Community_Chartbook_Feb2022.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt

/*
* To check against R results
export delimited using "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/summary_Community_`country'_R`round'_Stata.csv", replace 
*/

erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

