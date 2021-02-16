clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code 
*1) imports and cleans Continuity of EHS dataset from Lime Survey, 
*2) creates field check tables for data quality monitoring, and 
*3) creates indicator estimate data for dashboards and chartbook. 

*  DATA IN:	CSV file daily downloaded from Limesurvey 	
*  DATA OUT to chartbook: 
*		1. raw data (as is, downloaded from Limesurvey) in Chartbook  	
*		2. cleaned data with additional analytical variables in Chartbook and, for further analyses, as a datafile 
*		3. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	

*THREE parts must be updated per country-specific adaptation. See "MUST BE ADAPTED" below 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: 1. directories and local
* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey 
*****B.2. Drop duplicate cases 
* C. Destring and recoding 
*****C.1. Change var names to lowercase	
*****C.2. Change var names to make then coding friendly 
*****C.3. Find non-numeric variables and desting 
*****C.4. Recode yes/no & yes/no/NA
*****C.5. Label values 
* D. Create field check tables 
* E. Create analytical variables 
*****E.1. Country speciic code local <<<<<<<<<<========== MUST BE ADAPTED: 2. local per survey implementation and section 1 
*****E.2. Construct analysis variables <<<<<<<<<<========== MUST BE ADAPTED: 3. country specific staffing - section 2 
*****E.3. Export clean Respondent-level data to chart book 
* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book 

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file and a subfolder for "daily exported CSV file from LimeSurvey"  
cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\tools\Community"
*cd "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\Community"
dir

*** Define a directory for the chartbook, if different from the main directory 
global chartbookdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\tools\Community"
*global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\3 Country implementation & learning\1 HFAs for COVID-19\Kenya\Community"

*** Define local macro for the survey 
local country	 		 Kenya /*country name*/	
local round 			 1 /*round*/		
local year 			 	 2020 /*year of the mid point in data collection*/	
local month 			 12 /*month of the mid point in data collection*/				

*** local macro for analysis: no change needed  
local today=c(current_date)
local c_today= "`today'"
global date=subinstr("`c_today'", " ", "",.)


**************************************************************
* B. Import and drop duplicate cases
**************************************************************

*****B.1. Import raw data from LimeSurvey 

*import delimited 15122020_results-survey451568_codes_TEST.csv, case(preserve) clear 
*import delimited 17122020_results-survey451568_codes.csv, case(preserve) clear 
*import delimited 21122020_results-survey451568_codes.csv, case(preserve) clear
import delimited 04012021_results-survey451568_codes.csv, case(preserve) clear  

	gen import = "success" /*to confirm correct import of raw data to Chartbook*/

	/*mask ID information*/
	foreach var of varlist Q101 Q106 Q7011 Q7012 {
		replace `var'=""
		}		
	
	export excel using "$chartbookdir\KEN_Community_Chartbook.xlsx", sheet("Respondent-level raw data") sheetreplace firstrow(variables) nolabel

	drop import
	
***** Change var names to lowercase
 
	rename *, lower	

*****B.2. Drop duplicate cases 
	
	drop if ïid==.

	/*check duplicate cases, based on respondent code*/
	duplicates tag q105, gen(duplicate) 
				
		rename submitdate submitdate_string			
		gen double submitdate = clock(submitdate_string, "MDY hm")
		format submitdate %tc
				
		list q105 q106 submitdate* startdate datestamp if duplicate==1 
		
	/*drop duplicates before the latest submission*/ 
	egen double submitdatelatest = max(submitdate) if duplicate==1
						
		format %tcnn/dd/ccYY_hh:MM submitdatelatest
		
		list q105 q106 submitdate* if duplicate==1	
	
	drop if duplicate==1 & submitdate!=submitdatelatest 

	/*confirm there's no duplicate cases*/
	duplicates report q105 q106,
	
	drop duplicate submitdatelatest
	
**************************************************************
* C. Destring and recoding 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower
	
*****C.2. Change var names to drop unnecessary elements e.g., "sq" - because of Lime survey's naming convention 
	
	drop q*time /*timestamp var*/
	drop grouptime* 
	
	rename (*sq*) (*_*) /*replace sq with _*/

*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	sum q1*
	
	codebook q108 q109 q110 q111 q112  /* Lime survey error : question number shifted up by one*/ 
										/* KECT - I think that the error may be fixed, I've moved to what matches today's data*/
	foreach var of varlist q108 q109 q110 q111 q112  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}
		
	*****************************	
	* Section 2
	*****************************
	sum q2*
	codebook q201_*

	foreach var of varlist q201_*{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	

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
		
	*****************************	
	* Section 4
	*****************************
	sum q4*
	codebook q401 q402 q403
	
	foreach var of varlist q401 q402 q403  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	
	*****************************
	* Section 5
	*****************************
	sum q5*		
	codebook q501 q502* q504 
	
	foreach var of varlist q501 q502 q504   {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	*****************************			
	* Section 6
	*****************************
	sum q6*
	codebook q604 q606 q607 q609_* q611_* q612 q614 q615
	
	foreach var of varlist q604 q606 q607 q609_* q611_* q612 q614 q615 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	*****************************			
	* Section 7
	*****************************
	sum q7*
	codebook q701 q702
	
	foreach var of varlist q701 q702 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
				
*****C.4. Recode yes/no & yes/no/NA
	
	#delimit;
	sum		
		q301_*  q303_* q304_* q305 q306_* 
		q404_*
		q503_* q505_* 
		q601 q602 q603 q605_* q608_*
		q610 q613_*
		; 
		#delimit cr
	
	#delimit;
	foreach var of varlist 
		q301_*  q303_* q304_* q305 q306_* 
		q404_*
		q503_* q505_* 
		q601 q602 q603 q605_* q608_*
		q610 q613_*
		{; 
		#delimit cr		
	recode `var' 2=0 /*no*/
	}

*****C.5. Label values 

	#delimit;	
	
	lab define yesno 1"1. yes" 0"0. no"; 	
	foreach var of varlist 
		q301_*  q303_* q304_* q305 q306_* 
		q404_*
		q503_* q505_* 
		q601 q602 q603 q605_* q608_*
		q610 q613_*		
		{;	
	labe values `var' yesno; 
	};		
	
	lab define age
		1"1.Less than 25" 
		2"2.25-45"
		3"3.46-60"
		4"4.More than 60";  
	lab values q110 age; /*KE section 1 question number shifted - check*/  /*KECT - changed back to q110*/
	
	lab define occupation
		1"1.Commnity leader" 
		2"2.Community health officer"
		3"3.Commuunity health volunteer"
		4"4.Civil society/NGOs";  
	lab values q111 occupation; /*KE section 1 question number shifted - check*/ /*KECT - changed back to q111*/
	
		
	lab define area
		1"1.Urban"
		2"2.Rural";
	lab values q112 area; /*KE section 1 question number shifted - check*/
						  /*KECT the urban/rural question is showing up at Q112 (as it should) also based on paper version and responses, is only urban and rural, no periurban, so I've updated this*/	
	
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
	
	lab define q501
		1"1.Limited"
		2"2.Moderate"
		3"3.Significant";  
	lab values q501 q501; 
	
	lab define change
		1"1.Increased/enhanced"
		2"2.Remained stable"
		3"3.Decreased";  
	foreach var of varlist q502 q504 {;	
		lab values `var' change;
		};
		
	lab define q604
		1"1.No risk"
		2"2.Slight"
		3"3.Moderate"
		4"4.High"
		5"5.Very high";  
	lab values q604 q604; 
	
	lab define frequency
		1"1.Never"
		2"2.Sometimes"
		3"3.Often";  
	foreach var of varlist q606 q612 {;	
		lab values `var' frequency;
		};
				
	lab define q607
		1"1.Most support"
		2"2.Some support"
		3"3.Little support";  
	lab values q607 q607; 	
	
	lab define q609
		1"1.Slightly reduced"
		2"2.Substantially reduced or suspended"
		3"3.Increased"
		4"3.No change"
		5"3.Not applicable";  	
	foreach var of varlist q609_* {;	
		lab values `var' q609;
		};
	
	///*Kenya specific begins*///
	lab define q611
		1"1.Never"
		2"2.Sometimes"
		3"3.Always";  	
	foreach var of varlist q611_*  {;	
		lab values `var' q611;
		};		
	
	lab define q614
		1"1.Full recovery"
		2"2.Referred for hospital care"
		3"3.Some died at home"; /* THIS MUST BE CHANGED IN ROUND 2*/  
	lab values q614 q614; 	
	
	lab define q615
		1"1.Remained similar"
		2"2.Moderately increased"
		3"3.Highly increased"; 
	lab values q615 q615; 		
	///*END OF Kenya specific questions*///

	#delimit cr
	
**************************************************************
* D. Create field check tables for data quality check  
**************************************************************	

* generates daily field check tables in excel

preserve

			gen updatedate = "$date"
	
	tabout updatedate using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", replace ///
		cells(freq col) h2("Date of field check table update") f(0 1) clab(n %)

			split submitdate_string, p(" ")
			gen date=date(submitdate_string1, "MDY") 
			format date %td
						
	tabout submitdate_string1 using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Date of interviews (submission date, final)") f(0 1) clab(n %)
			
			gen xresult=q702==1
			
			gen byte responserate= xresult==1
			label define responselist 0 "Not complete" 1 "Complete"
			label val responserate responselist

	tabout responserate using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Interview response rate") f(0 1) clab(n %)
	
	tabout q111 using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by area") f(0 1) clab(n %)
		
	tabout q110 using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Number of completed interviews by respondent occupation") f(0 1) clab(n %)		

			gen double time = interviewtime/60	 /*interview length in minute*/
				replace time = int(time)
			format time %15.0f

			bysort xresult: sum time
			egen time_complete = mean(time) if xresult==1
			egen time_incomplete = mean(time) if xresult==0
				replace time_complete = round(time_complete, .1)
				replace time_incomplete = round(time_incomplete, .1)

	tabout time xresult using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Interview length (minutes): incomplete, complete, and total interviews") f(0 1) clab(n %)	
	tabout time_complete using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among completed interviews") f(0 1) clab(n %)		
	tabout time_incomplete using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among incomplete interviews") f(0 1) clab(n %)	

* Missing responses 

			capture drop missing
			gen missing=0
			foreach var of varlist q702 {	
				replace missing=1 if `var'==.				
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("0. Missing survery results (among all interviews)") f(0 1) clab(n %)									

keep if xresult==1 /*the following calcualtes % missing in select questions among completed interviews*/		
			
			capture drop missing
			gen missing=0
			foreach var of varlist q201_* {	
				replace missing=1 if `var'==.
				}			
			lab values missing yesno
			
	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("1. Missing unmet need responses in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q303_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q302==1
			tab missing, m	
			lab values missing yesno		
			
	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("2. Missing reason for unmet need during the pandemic in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					
		
			capture drop missing
			gen missing=0
			foreach var of varlist q306_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q305==0
			tab missing, m	
			lab values missing yesno	
			
	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("3. Missing marginalized population (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q402 q403 {	
				replace missing=1 if `var'==.
				}		
			tab missing, m
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("4. Missing vaccine demand among adults OR children, when applicable (among completed interviews)") f(0 1) clab(n %)					
	
			capture drop missing
			gen missing=0
			foreach var of varlist q404_* {	
				replace missing=1 if `var'==.
				}		
				replace missing=. if q402==1 & q403==1
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("5. Missing reasons for no vaccine demand in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q503_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q502!=1
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("6. Missing increased social initiatives (among completed interviews)") f(0 1) clab(n %)							

			capture drop missing
			gen missing=0
			foreach var of varlist q505_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q504!=1
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("7. Missing increased health initiatives (among completed interviews)") f(0 1) clab(n %)		
		
			capture drop missing
			gen missing=0
			foreach var of varlist q605_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q604<=2
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("8. Missing reasons for risks (among completed interviews)") f(0 1) clab(n %)			
				
			capture drop missing
			gen missing=0
			foreach var of varlist q606 {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("9. Missing CHW stigma (among completed interviews)") f(0 1) clab(n %)							
		
			capture drop missing
			gen missing=0
			foreach var of varlist q608_* {	
				replace missing=1 if `var'==.
				}	
				replace missing=. if q607==1
			lab values missing yesno		

	tabout missing using "$chartbookdir\FieldCheckTable_Community_`country'_R`round'_$date.xls", append ///
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
	
	gen respondentcode=q104 /*KE section 1 question number shifted - check*/ 

	gen month	=`month'
	gen year	=`year'

	*gen zsex	
	gen zchw	=q110>=`chwmin' & q110<=`chwmax'
	gen zurban	=q112>=`urbanmin' & q112<=`urbanmax'   /*KECT - changed to q112*/
	
	lab define zchw 0"non CHWs" 1"CHWs"
	lab values zchw zchw
	
	lab define zurban 0"Rural" 1"Urban"
	lab values zurban zurban
	
	lab var ïid "ID generated from Lime Survey"

	*****************************
	* Section 2: need and use 
	*****************************

	/*variable name change 1/19/2021 : changed some to somemost, created new some (only some)*/
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
		
		egen `item'_hivtb_num=rowtotal(`item'__010) 
		gen `item'_hivtb = `item'_hivtb_num>=1 	
	}
	
	gen xunmetsome = xunmetsomemost - xunmetmost
	
	foreach item in urgent chronic rmch hivtb{	
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

		/*	correct code using all response options. updated on 1/8/2021
		
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
			
		/*	code used for Charbook until 1/8/2021		
		foreach item in 002{	
			replace xbar_pre_demand =1 	if q301_`item'==1
			}		
		foreach item in 001{	
			replace xbar_pre_info =1 	if q301_`item'==1
			}	
		foreach item in 003 004 005{	
			replace xbar_pre_phacc =1 	if q301_`item'==1
			}		
		foreach item in 006 007{	
			replace xbar_pre_fin =1 	if q301_`item'==1
			}			
		foreach item in 008 009 010{	
			replace xbar_pre_qinput =1 	if q301_`item'==1
			}			
		foreach item in 011 012 013 014 016{	
			replace xbar_pre_qexp =1 	if q301_`item'==1
			}					
		foreach item in 015 017{	
			replace xbar_pre_admin =1 	if q301_`item'==1
			}	
		*/
		
	***** Overall barriers during COVID "affected/deteriorated" 
	
	gen byte xbar_covid = q302>=2 & q302!=.
	
	***** During COVID barriers /* Kenya Lime survey and paper Q mismatch 17 itmes in paper vs. 16 in online */ 
	
	gen xbar_covid_fear =0
	gen xbar_covid_rec =0
	gen xbar_covid_info =0
	gen xbar_covid_phacc =0
	gen xbar_covid_fin =0
	gen xbar_covid_admin =0
	gen xbar_covid_qinput =0
	gen xbar_covid_qexp =0
	
		/*	correct code using all response options. updated on 1/8/2021

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
			
		/*	code used for Charbook until 1/8/2021			
		foreach item in 001 002 016 {	
			replace xbar_covid_fear =1 	if q303_`item'==1
			}		
		foreach item in 003 004 {	
			replace xbar_covid_rec =1 	if q303_`item'==1
			}		
		foreach item in 005 {	
			replace xbar_covid_info =1 	if q303_`item'==1
			}	
		foreach item in 006 007 {	
			replace xbar_covid_phacc =1 	if q303_`item'==1
			}		
		foreach item in 008 009 010 {	
			replace xbar_covid_fin =1 	if q303_`item'==1
			}			
		foreach item in 011 012 013 {	
			replace xbar_covid_admin =1 	if q303_`item'==1
			}					
		foreach item in 014 {	
			replace xbar_covid_qinput =1 	if q303_`item'==1
			}			
		foreach item in 015 {	
			replace xbar_covid_qexp =1 	if q303_`item'==1
			}		
		*/
			
	***** Source of care 
	
	global itemlist "001 002 003 004 005 006 007 008 009 010 011"
	foreach item in $itemlist{	
		gen xsource__`item' 		= q304_`item'==1
		}	
		
	gen xsource_trained	=0
		foreach item in 001 002 003 004 005 006 007 008  {	
			replace xsource_trained	=1 	if q304_`item'==1
			}		
	* new var made on 1/8/2021. In Kenya, it's 100%. also mostly CHW, which can be real or biased report.  
		
	***** Equity
	
	gen byte xmargin = q305==1
	
	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016"
	foreach item in $itemlist{	
		gen xmargin__`item' 		= q306_`item'==1
		}	

	*****************************
	* Section 4: vaccine 
	*****************************
	
	gen byte xconcern_most 		= q401<=1
	gen byte xconcern_mostsome 	= q401<=2
	gen byte xconcern_some 		= q401==2
	
	gen byte xvac_adult_most 	= q402<=1
	gen byte xvac_adult_mostsome= q402<=2
	gen byte xvac_adult_some= q402==2	
	
	gen byte xvac_child_most 	= q403<=1
	gen byte xvac_child_mostsome= q403<=2
	gen byte xvac_child_some= q403==2
	
	gen byte xvac_most 		= xvac_adult_most==1 & xvac_child_most==1 /*most adults AND children*/	
	gen byte xvac_mostsome	= xvac_adult_mostsome==1 | xvac_child_mostsome==1 /*most/some adults OR children*/
	gen byte xvac_some		= xvac_most!=1 & xvac_mostsome==1 /*some adults OR children*/
	
	global itemlist "001 002 003 004 005 006 007"
	foreach item in $itemlist{	
		gen xvac_reason__`item' 		= q404_`item'==1
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
		replace `var' = . if xvac_most !=0
		}
	
	sum xvac*
		
	*****************************
	* Section 5: Community assets and vulnerabilities 
	*****************************	
	gen xeconimpact_mod =q501==2 | q501==3  /*KECT - this had & so it wasn't finding anything (cannot be both 2 and 3), changed | */
	gen xeconimpact_sig =q501==3  
	
	tab xeconimpact_mod xeconimpact_sig
	
	gen xinit_ses_increased = q502==1 
	gen xinit_ses_nochange = q502==2 
	gen xinit_ses_decreased = q502==3 
	
	global itemlist "001 002 003 004 005 006 007 008 009"  /*KECT - there are nine items so added 009 to this row*/
	foreach item in $itemlist{	
		gen xinit_ses_increased__`item' 		= q503_`item'==1
		}	

	gen xinit_health_increased = q504==1 
	gen xinit_health_nochange = q504==2 
	gen xinit_health_decreased = q504==3 
	
	global itemlist "001 002 003 004 005 006 007 008 009 010"  /*KECT - there are ten items so added 010 to this row*/
	foreach item in $itemlist{	
		gen xinit_health_increased__`item' 		= q505_`item'==1
		}	
	
	*****************************
	* Section 6: CHW service provision /* IN KENYA section 6 asked to all respondents */
	*****************************
	gen byte xknowledge			=q601==1
	gen byte xtrain_covid		=q602==1
	gen byte xtrain_covidhbc	=q603==1
	
	gen byte xrisk_mod	=q604>=3 & q604!=.
	gen byte xrisk_high	=q604>=4 & q604!=.

	global itemlist "001 002 003 004 005 006"
	foreach item in $itemlist{	
		gen xrisk_reason__`item' 		= q605_`item'==1
		}			
	
	gen byte xstigma	=q606>=2 & q606!=.
	
	gen byte xstigma_never	=q606==1
	gen byte xstigma_sometimes	=q606==2
	gen byte xstigma_often	=q606==3
	
	gen byte xsupport_most		=q607<=1
	gen byte xsupport_somemost	=q607<=2
	gen byte xsupport_some	=q607==2
	
	gen byte xsupportneed	=q607==2 | q607==3
	
	global itemlist "001 002 003 004 005 006 007"
	foreach item in $itemlist{	
		gen xsupportneed__`item' 		= q608_`item'==1
		}
		
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xsrvc_reduced__`item' 		= q609_`item'<=2
		}		
	foreach item in $itemlist{	
		gen xsrvc_increased__`item' 	= q609_`item'==3
		}				
	foreach item in $itemlist{	
		gen xsrvc_nochange__`item' 		= q609_`item'==4
		}		

	/*check level of NA 1/18/2021*/
	/*
	foreach item in $itemlist{	
		gen xsrvc_na__`item' 		= q609_`item'==5
		}			
		
	. sum xsrvc_na*

		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
	xsrvc_na~001 |         51    .0196078     .140028          0          1
	xsrvc_na~002 |         51    .0588235    .2376354          0          1
	xsrvc_na~003 |         51    .1372549    .3475404          0          1
	xsrvc_na~004 |         51    .0392157    .1960392          0          1
	xsrvc_na~005 |         51    .0392157    .1960392          0          1

	*/	
	
	/*fix denominators. giving missing if NA: updated 1/18/2021*/	
	foreach item in $itemlist{	
		replace xsrvc_reduced__`item' 		=. if q609_`item'==5
		replace xsrvc_increased__`item' 	=. if q609_`item'==5
		replace xsrvc_nochange__`item' 	=. if q609_`item'==5
		}				
	
	/*
	foreach var of varlist xknowledge xtrain* xrisk* xstigma xsupport* xsrvc* {
		replace `var' = . if zchw !=1
	}	
	*/
	
	*****************************
	* Section 6A: Home-based self isolation /* IN KENYA section 6-1 asked to all respondents */
	*****************************
	gen byte xhbc = q610==1
	
	global itemlist "001 002 003 004 005 006"
	foreach item in $itemlist{	
		gen xhbc_adhsome__`item' 		= q611_`item'==2 | q611_`item'==3
		gen xhbc_adhalways__`item' 		= q611_`item'==3			
		}	

	gen byte xhbc_stigma	=q612>=2 & q612!=.
	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xhbc_support__`item' 		= q613_`item'==1
		}			
		
	gen xhbc_outcome_recovery 	=  q614==1
	gen xhbc_outcome_ref 		=  q614==2
	gen xhbc_outcome_death 		=  q614==3
	
	gen xmortality_upmod	 =  q615==2 | q615==3
	gen xmortality_uphigh	 =  q615==3
	
	
	foreach var of varlist xhbc_* xmortality* {
		replace `var' = . if xhbc!=1
		}
		
	sort ïid
		
	gen interviewlength=interviewtime/60
	
	save Community_`country'_R`round'.dta, replace 		

	export delimited using Community_`country'_R`round'.csv, replace 
	
*****E.3. Export clean Respondent-level data to chart book 

	export excel using "$chartbookdir\KEN_Community_Chartbook.xlsx", sheet("Respondent-level cleaned data") sheetreplace firstrow(variables) nolabel
	
**************************************************************
* F. Create indicator estimate data 
**************************************************************

use Community_`country'_R`round'.dta, clear
	
	gen obs=1 	
	*gen obs_chw=1 if zchw==1 	
	gen obs_chw=1 /*in KENYA all asnwer the section 6, even though a few occupation are not CHWs*/
	gen obs_hbc=1 if xhbc==1
	gen obs_vacreason=1 if xvac_most!=1
	
	save temp.dta, replace 
		
*****F.1. Calculate estimates 

	use temp.dta, clear
	collapse (count) obs* (mean) x* interviewlength, by(country round month year  )
		gen group="All"
		gen grouplabel="All"
		keep obs* country round month year  group* x* interviewlength
		save summary_Community_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x* interviewlength, by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="1.1 Rural" if zurban==0
			replace grouplabel="1.2 Urban" if zurban==1
		keep obs* country round month year  group* x* interviewlength
		
		append using summary_Community_`country'_R`round'.dta, force
		save summary_Community_`country'_R`round'.dta, replace 		
		
	use temp.dta, clear
	collapse (count) obs* (mean) x* interviewlength , by(country round month year   zchw)
		gen group="Occupation"
		gen grouplabel=""
			replace grouplabel="2.1 non CHWs" if zchw==0
			replace grouplabel="2.2 CHWs" if zchw==1
		keep obs* country round month year  group* x* interviewlength
		
		append using summary_Community_`country'_R`round'.dta, force
		save summary_Community_`country'_R`round'.dta, replace 
	
	* convert proportion to %
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
	
		/* But, convert back variables that were incorrectly converted (e.g., occupancy rates, score)
				foreach var of varlist *_num {
					replace `var'=round(`var'/100, .1)
					}
		*/
			
	tab grouplabel round, m
	
	* organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs* 
		
	sort country round grouplabel
	
save summary_Community_`country'_R`round'.dta, replace 

export delimited using summary_Community_`country'_R`round'.csv, replace 
*export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\4.ShinyApp\Kenya\summary_Community_`country'_R`round'.csv", replace 


*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_Community_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"
	
export excel using "$chartbookdir\KEN_Community_Chartbook.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt
*export delimited using "C:\Users\YoonJoung Choi\Dropbox\0 iSquared\iSquared_WHO\ACTA\4.ShinyApp\Kenya\summary_Community_`country'_R`round'.csv", replace 

erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

