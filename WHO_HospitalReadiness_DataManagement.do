clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

*This code was last updated on 5/19/2022 to update section B.4
*Based on the July 7, 2021 Q version 

*This code 
*1) imports and cleans Continuity of EHS dataset from Lime Survey,
*2) creates field check tables for data quality monitoring, and 
*3) creates indicator estimate data for dashboards and chartbook. 

*  DATA IN:	CSV file daily downloaded from Limesurvey 	
*  DATA OUT to chartbook: 
*		1. raw data (as is, downloaded from Limesurvey) in Chartbook  	
*		2. cleaned data with additional analytical variables in Chartbook and, for further analyses, as a datafile 
*		3. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	

*AT MINIMUM, FOUR parts must be updated per country-specific adaptation. See "MUST BE ADAPTED" below 

/* TABLE OF CONTENTS*/

* A. SETTING <<<<<<<<<<========== MUST BE ADAPTED: 1. directories and local
* B. Import and drop duplicate cases
*****B.1. Import raw data from LimeSurvey 
*****B.2. Export/save the data daily in CSV form with date 
*****B.3. Export the data to chartbook  
*****B.4. Drop duplicate cases 
* C. Cleaning - variables
*****C.1. Change var names to lowercase	
*****C.2. Change var names to make then coding friendly 
*****C.3. Find non-numeric variables and desting 
*****C.4. Recode yes/no & yes/no/NA
*****C.5. Label values 
* D. Create field check tables 
* E. Create analytical variables 
*****E.1. Country speciic code local <<<<<<<<<<========== MUST BE ADAPTED: 2. local per survey implementation and section 1 
*****E.2. Construct analysis variables <<<<<<<<<<========== MUST BE ADAPTED: 3. indicators  
*****E.2.A Rename detailed indicators ending with sub-question numbers with more friendly/intuitive names   
*****E.3. Merge with sampling weight <<<<<<<<<<========== MUST BE ADAPTED: 4. weight depending on sample design 
*****E.4. Export clean Respondent-level data to chart book 
* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book and dashboard

**************************************************************
* A. SETTING 
**************************************************************

*** Directory for this do file 
*cd "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*cd "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
cd "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/"

*** Directory for downloaded CSV data, if different from the main directory
*global downloadcsvdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"
*global downloadcsvdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\DownloadedCSV\"
global downloadcsvdir "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/ExportedCSV_FromLimeSurvey/"

*** Define a directory for the chartbook, if different from the main directory 
*global chartbookdir "C:\Users\ctaylor\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
*global chartbookdir "C:\Users\YoonJoung Choi\World Health Organization\BANICA, Sorin - HSA unit\2 Global goods & tools\2 HFAs\1 HFAs for COVID-19\4. Implementation support materials\4. Analysis and dashboards\"
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
import delimited "$downloadcsvdir/LimeSurvey_COVID19HospitalReadiness_EXAMPLE_R1.csv", case(preserve) clear /*THIS LINE ONLY FOR PRACTICE*/

*****B.2. Export/save the data daily in CSV form with date 	
export delimited using "$downloadcsvdir/LimeSurvey_COVID19HospitalReadiness_`country'_R`round'_$date.csv", replace
	
*****B.3. Export the data to chartbook  	
		
	codebook token Q101
	list Q1* if Q101==. | token=="" 
	***CHECK: this is an empty row. There should be none	

	/*MASK idenitifiable information*/
	foreach var of varlist Q1BSQ001comment Q102 Q103 Q108 Q1002 Q1003 {
		replace `var'=""
		}		
		replace Q109 =. 	
	
export excel using "$chartbookdir/WHO_COVID19HospitalReadiness_Chartbook_08.21.xlsx", sheet("Facility-level raw data") sheetreplace firstrow(variables) nolabel

*****B.4. Drop duplicate cases 

	lookfor id
	rename *id id
	codebook id 
	*****CHECK HERE: this is an ID variable generated by LimeSurvey, not facility ID. still there should be no missing*/	

	*****identify duplicate cases, based on facility code*/
	duplicates tag Q101, gen(duplicate) 
		
		/* YC edit starts 5/19/2022*/
		* must check string value and update
		* 	1. "mask" in the "clock" line for submitdate
		* 	2. "format" line for the submitdatelatest		
		*REFERENCE: https://www.stata.com/manuals13/u24.pdf
		codebook submitdate* 
				
		rename submitdate submitdate_string			
	gen double submitdate = clock(submitdate_string, "MDY hm") /*"clock" line in the standard code*/
	*gen double submitdate = clock(submitdate_string, "YMDhms") /*"clock" line with different mask*/
		format submitdate %tc 
		
		codebook submitdate*
		/* edit pauses*/
	
	list Q101 Q102 Q104 Q105 submitdate* startdate datestamp if duplicate!=0  
	*****CHECK HERE: In the model data, there is one duplicate for practice purpose. 
	
	*****drop duplicates before the latest submission */
	egen double submitdatelatest = max(submitdate) if duplicate!=0  , by(Q101) /*LATEST TIME WITHIN EACH DUPLICATE YC edit 6/29/2021*/					
		format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
		*format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
		
		list Q101 Q102 Q104 Q105 submitdate* if duplicate!=0 	
	
	/*YC edit 5/19/2022
		.                 list Q101 Q102 Q104 Q105 submitdate* if duplicate!=0    

			 +------------------------------------------------------------------------------------------+
			 | Q101   Q102   Q104   Q105     submitdate_string           submitdate    submitdatelatest |
			 |------------------------------------------------------------------------------------------|
		 10. |    .                        2022-05-17 02:36:27   17may2022 02:36:27   5/17/2022 2:40:28 |
		 92. |    .                        2022-05-17 02:40:28   17may2022 02:40:28   5/17/2022 2:40:28 |
			 +------------------------------------------------------------------------------------------+

		* In this real data example (not the mock data), the facility with "duplicates" has missing facility ID. 
		* data managers must check if this is a real facility or not. 
		* But, in principle, we delete data entries with missing facility ID. 
		
	*/	
		
	drop if duplicate!=0  & submitdate!=submitdatelatest 
	drop if Q101==. 
	
	*****confirm there's no duplicate cases, based on facility code*/
	duplicates report Q101,
	*****CHECK HERE: Now there should be no duplicate 
	
	drop duplicate submitdatelatest
	
**************************************************************
* C. Data cleaning - variables 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.1.a. Assess & keep timestamp data 
	
	*****drop detailed timstamp data but keep interviewtime (interview length in seconds)
	capture drop q*time 
	capture drop grouptime* 
	
	*REVISION: 4/20/2021
	*interviewtime is availabl in dataset only when directly downloaded from the server, not via export plug-in used in this code
	*thus below C.1.a is suppressed
	/*	
	codebook interviewtime 
	gen long interviewlength=round(interviewtime/60, 1) 
		lab var interviewlength "interview length in minutes"
		sum interviewlength
	*/
	
*****C.2. Change var names to drop odd elements "y" "sq" - because of Lime survey's naming convention 
	
	d *sq*
	
	rename (*ysq*) (*_*) /*when y is in the middle */
	rename (*sq) (*) /*when ending with sq - no need to */
	rename (*sqsq*) (*_*) /*replace double sq with _*/
	rename (*sq*) (*_*) /*replace sq with _*/
	
	rename (q701_*_a1) (q701_*_001)
	rename (q701_*_a2) (q701_*_002)
	
	rename (q201_*_a1) (q201_*_001)
	rename (q201_*_a2) (q201_*_002)

	lookfor sq
	
	d *t
	capture drop *t	
	
*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	sum q1*
	codebook q104 q105 q106 q114*
		
	foreach var of varlist q104 q105 q106 q114*{	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}
		
	sum q1*		
	
	*****************************	
	* Section 2
	*****************************
	sum q2* 
	d q2*				

	sum q2*
	codebook q204 q205* q207* q208
		
	foreach var of varlist q204 q205* q207*  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}	
		
	sum q2*		
	
	*****************************	
	* Section 3
	*****************************
	sum q3* /*all numeric*/
	d q3*				

	*****************************
	* Section 4: Therapeutics
	*****************************
	sum q4*
	foreach var of varlist q401* q402* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	d q4*				

	*****************************
	* Section 5
	*****************************
	sum q5*	
	codebook q503* q505* q507* q509*
	sum q503* q505* q507* q509*

	foreach var of varlist q503_001 - q503_011 q505* q507* q509*  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
	sum q5*	

	*****************************	
	* Section 6		
	**************************	
	sum q6*	
	d q6*

	codebook q602_* q604 
	
	foreach var of varlist q602_* q604  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	d q6*
	
	*****************************	
	* Section 7
	*****************************
	sum q7*	
	d q7*
	
	rename q702other q702_006 
	rename q703_other q703_006 
	
	codebook q703_* q704_*  

	foreach var of varlist q704_*   {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
	d q7*	
	
	*****************************		
	* Section 8: General Vaccine Readiness
	*****************************
	sum q8*
	codebook q807* q810* q811* 
	
	foreach var of varlist q807* q810* q811* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	d q8*
	
	*****************************		
	* Section 9: COVID-19 vaccine Readiness
	*****************************	
	sum q9*
	
	/*
	foreach var of varlist  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	*/
	
	d q9*	
		
	*****************************			
	* Section 10: interview results
	*****************************
	sum q10*

	foreach var of varlist q1001 q1004 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	d q10*
	
*****C.4. Recode yes/no 
	
	#delimit;
	sum
		q114_* 
		q202  q205_* q206   q207* q209 q210
		q501  q502  q503_* q504  q505_* q506
		q601 q602_* q603_* q604 q608* q611 q612 
		q702* q703* q704* q705 q706
		q801 q802 q805 q808 q812 q813 q814
		q903 q905_001 - q914
		; 
		#delimit cr

	#delimit;
	foreach var of varlist 
		q114_* 
		q202  q205_* q206   q207* q209 q210
		q501  q502  q503_* q504  q505_* q506
		q601 q602_* q603_* q604 q608* q611 q612 
		q702* q703* q704* q705 q706
		q801 q802 q805 q808 q812 q813 q814
		q903 q905_001 - q914
		{;	
		#delimit cr 
		recode `var' 2=0 /*no*/
		}	
							
*****C.5. Label values 

	#delimit;	
	
	lab define q104 
		1"1.Urban" 
		2"2.Rural";  
	lab values q104 q104; 
	
	lab define q105 
		1"1.Level2: Dispensary"
		2"2.Level3: Health Centre"
		3"3.Level4: Primary Hospital"
		4"4.Level5: Secondary level hospital and above"
		5"5.Level6: Tertiary level" ; 
	lab values q105 q105; /*corresponding to the model example context*/
	
	lab define q106 
		1"1.Government"
		2"2.Private"
		3"3.NGO"
		4"4.FBO"
		5"5.Other"; 
	lab values q106 q106; /*corresponding to the model example context*/
	
	lab define ppe
		1"1.Currently available for all health workers"
		2"2.Currently available only for some health workers"
		3"3.Currently unavailable for any health workers"
		4"4.Not applicable – never procured or provided" ;
	foreach var of varlist q502* {;
	lab values `var' ppe;	
	};		
	
	lab define availfunc 
		1"1.Yes, functional"
		2"2.Yes, but not functional"
		3"3.No";
	foreach var of varlist 
		q606 q803 q804 q901 q902 {;
	lab values `var' availfunc ;	
	};			

	lab define icepack 
		1"1.Yes, a set of ice packs for all cold boxes"
		2"1.Yes, a set of ice packs only for some cold boxes"
		3"3.No";
	foreach var of varlist q807 q810 {;
	lab values `var' icepack ;	
	};		
	
	lab define icepackfreeze 
		1"1.All"
		2"2.Only some"
		3"3.None-no functional freezer" ;
	lab values q811 icepackfreeze ;	
		
	lab define yesno 
		1"1. yes" 
		0"0. no"; 	
	foreach var of varlist 
		q114_* 
		q202  q205_* q206   q207* q209 q210
		q501  q502  q503_* q504  q505_* q506
		q601 q602_* q603_* q604 q608* q611 q612 
		q702* q703* q704* q705 q706
		q801 q802 q805 q808 q812 q813 q814
		q903 q905_001 - q914
		{;		
	labe values `var' yesno; 
	};
	
	lab define yesnona 
		1"1. yes" 
		2"2. no" 
		3"N/A"; 
	foreach var of varlist 
		q401_* q402_* 
		q503_* q602_* 
		{;		
	labe values `var' yesnona; 
	};
	
	lab define yesyesbutno 
		1"1. Yes, available" 
		2"2. Yes, but unavailable" 
		3"No"; 
	foreach var of varlist q904_* {;		
	labe values `var' yesyesbutno; 
	};	
	
	#delimit cr

**************************************************************
* D. Create field check tables for data quality check  
**************************************************************

* generates daily field check tables in excel

preserve

			gen updatedate = "$date"
	
	tabout updatedate using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", replace ///
		cells(freq col) h2("Date of field check table update") f(0 1) clab(n %)

			split submitdate_string, p(" ")
			gen date=date(submitdate_string1, "YMD") /* KECT - changed to YMD from MDY*/
			format date %td
						
	tabout submitdate_string1 using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Date of interviews (submission date, final)") f(0 1) clab(n %)
			
			gen xresult=q1004==1

			gen byte responserate= xresult==1
			label define responselist 0 "Not complete" 1 "Complete"
			label val responserate responselist

	tabout responserate using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Interview response rate") f(0 1) clab(n %) mi
	
	tabout q104 using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("number of interviews by area") f(0 1) clab(n %) mi
		
	tabout q105 using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("number of interviews by hospital type") f(0 1) clab(n %) mi		

	*REVISION: 4/20/2021		
	*suppress fieldcheck tables containing interviewlength
	/*			
			bysort xresult: sum interviewlength
			egen time_complete = mean(interviewlength) if xresult==1
			egen time_incomplete = mean(interviewlength) if xresult==0
				replace time_complete = round(time_complete, 1)
				replace time_incomplete = round(time_incomplete, 1)
		
	tabout time_complete using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among completed interviews") f(0 1) clab(n %)		
	tabout time_incomplete using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("Average interview length (minutes), among incomplete interviews") f(0 1) clab(n %)	
	*/
	
* Missing responses 

			capture drop missing
			gen missing=0
			foreach var of varlist q1004 {	
				replace missing=1 if `var'==.				
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("0. Missing survery results (among all interviews)") f(0 1) clab(n %)				
		
keep if xresult==1 /*the following calcualtes % missing in select questions among completed interviews*/		
	
capture drop missing
			gen missing=0
			foreach var of varlist q112 q113 {	
				replace missing=1 if `var'==.
				replace missing=. if q111!=1
				}		
			lab values missing yesno
			
	tabout missing using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("1. Missing number of beds when facility provides inpatient services (among completed interviews)") f(0 1) clab(n %)					

			capture drop missing
			gen missing=0
			foreach var of varlist q201_002_001 q201_002_002 {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno		

	tabout missing using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("2. Missing number of nurses (either the total number or the number who have been infected) (among completed interviews)") f(0 1) clab(n %)					
	
			capture drop missing
			gen missing=0
			foreach var of varlist q401_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("3. Missing medicines - in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)							
					
			capture drop missing
			gen missing=0
			foreach var of varlist q507_* {	
				replace missing=1 if `var'==.
				}		
			lab values missing yesno	

	tabout missing using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("4. Missing PPE item - in one or more of the tracer items (among completed interviews)") f(0 1) clab(n %)					
				
			capture drop missing
			gen missing=0
			foreach var of varlist q606 q607 {	
				replace missing=1 if `var'==.
				replace missing=. if q603_001!=0
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("5. Missing PCR capacity  (among completed interviews)") f(0 1) clab(n %)					
						
			capture drop missing
			gen missing=0
			foreach var of varlist q701_* {	
				replace missing=1 if `var'==.
				}					
			lab values missing yesno	

	tabout missing using "$chartbookdir/FieldCheckTable_COVID19Hospital_`country'_R`round'_$date.xls", append ///
		cells(freq col) h2("6. Missing entry in the number of equipment (either the total number or the number of functional) (among completed interviews)") f(0 1) clab(n %)					
			*/
			
restore
**************************************************************
* E. Create analytical variables 
**************************************************************

*****E.1. Country speciic code local 
	
	***** MUST REVIEW CODING FOR THE FOLLOWING FOUR GROUPS OF VARIABLES */
		/*
		zurban
		zlevel*
		zpub
		*/
	
	/*DEFINE LOCAL FOR THE FOLLOWING*/ 

		local urbanmin			 1 	
		local urbanmax			 1
		
		local minlow		 	 1 /*lowest code for lower-level facilities in Q105*/
		local maxlow		 	 2 /*highest code for lower-level facilities in Q105*/ 
		local minhigh		 	 3 /*lowest code for hospital/high-level facilities in Q105*/  
		local maxhigh			 5 /*highest code for hospital/high-level facilities in Q105*/ 
		local primaryhospital    3 /*district hospital or equivalent */	

		local maxtraining	     5 /*total number of training items asked in q207*/
		local maxtrainingsupport 9 /*total number of training/support items asked in q207*/
		
		local pubmin			 1
		local pubmax			 1
		
		local maxdrug 			 15 /*total medicines asked in q401*/ 
	
*****E.2. Construct analysis variables 

* give prefix z for background characteristics, which can be used as analysis strata     
* give prefix x for binary variables, which will be used to calculate percentage   
* give prefix y for integer/continuous variables, which will be used to calculate total

	*****************************
	* Section 1 
	*****************************
	
	gen country = "`country'"
	gen round =`round'
	
	gen long facilitycode=q101

	gen month = `month'
	gen year	=`year'
			
	foreach var of varlist q104 q105 q106{
		tab `var'
		}
		
	gen zurban	=q104>=`urbanmin' & q104<=`urbanmax'
	
	gen zlevel			=""
		replace zlevel	="Level2" if q105==1
		replace zlevel	="Level3" if q105==2
		replace zlevel	="Level4" if q105==3
		replace zlevel	="Level5" if q105==4
		replace zlevel	="Level6" if q105==5
	
	gen zlevel_hospital		=q105>=`minhigh' & q105<=`maxhigh'
	gen zlevel_primhospital	=q105==`primaryhospital'
	gen zlevel_low			=q105>=`minlow'  & q105<=`maxlow'
	
	gen zpub	=q106>=`pubmin' & q106<=`pubmax'
		
	lab define zurban 0"Rural" 1"Urban"
	lab define zlevel_hospital 0"Non-hospital" 1"Hospital"
	lab define zpub 0"Non-public" 1"Public"

	lab values zurban zurban
	lab values zlevel_hospital zlevel_hospital
	lab values zpub zpub
	
	lab var id "ID generated from Lime Survey"
	lab var facilitycode "facility ID from sample list" /*this will be used to merge with sampling weight, if relevant*/
	
	*****************************
	* Section 2: staffing & IMST
	*****************************

	egen staff_num_total_md=rowtotal(q201_001_001)
	egen staff_num_covid_md=rowtotal(q201_001_002)
	
	egen staff_num_total_nr=rowtotal(q201_002_001)
	egen staff_num_covid_nr=rowtotal(q201_002_002)

	egen staff_num_total_othclinical=rowtotal(q201_003_001 q201_004_001 q201_005_001 q201_006_001 q201_007_001  )
	egen staff_num_covid_othclinical=rowtotal(q201_003_002 q201_004_002 q201_005_002 q201_006_002 q201_007_002  )
	
	egen staff_num_total_clinical=rowtotal(staff_num_total_md staff_num_total_nr staff_num_total_othclinical)
	egen staff_num_covid_clinical=rowtotal(staff_num_covid_md staff_num_covid_nr staff_num_covid_othclinical)
	
	egen staff_num_total_nonclinical=rowtotal(q201_008_001 q201_009_001 q201_010_001 )
	egen staff_num_covid_nonclinical=rowtotal(q201_008_002 q201_009_002 q201_010_002 )
	
	egen staff_num_total_all=rowtotal(staff_num_total_clinical staff_num_total_nonclinical) 
	egen staff_num_covid_all=rowtotal(staff_num_covid_clinical staff_num_covid_nonclinical) 
		
	gen xstaff_covax = q201a==1
	gen staff_num_covaxany  = q201b
	gen staff_num_covaxfull = q201c
		replace staff_num_covaxany  =. if xstaff_covax!=1
		replace staff_num_covaxfull =. if xstaff_covax!=1
				
	gen xabsence=q202==1
	gen xabsence_medical=	q203_003==1 | q203_004==1 
	gen xabsence_structure=	q203_005==1 | q203_006==1 | q203_007==1 
	gen xabsence_social=	q203_008==1 | q203_009==1 | q203_010==1 
			
	gen xhr=q204==1
	gen xhr_shift=		q205_001==1
	gen xhr_increase=	q205_002==1 | q205_003==1 | q205_004==1 | q205_005==1 | q205_006==1 
	gen xhr_increase_exp=	q205_002==1 | q205_003==1 
	gen xhr_increase_new=	q205_004==1 | q205_005==1 | q205_006==1 
	gen xhr_secondment=	q205_007==1
	gen xhr_decrease=	q205_008==1
	
	gen xtraining=q206==1
	global itemlist "001 002 003 004 005 006 007 008 009"
	foreach item in $itemlist{	
		gen byte xtraining__`item' = q207_`item' ==1
		}		
		
		gen max=`maxtraining'
		egen temp=rowtotal(xtraining__001 xtraining__002 xtraining__003 xtraining__004 xtraining__005)
	gen xtraining_score	=100*(temp/max)
	gen xtraining_100 	=xtraining_score>=100
	gen xtraining_50 	=xtraining_score>=50
		drop max temp

		gen max=`maxtrainingsupport'
		egen temp=rowtotal(xtraining__*)
	gen xtrainingsupport_score	=100*(temp/max)
	gen xtrainingsupport_100	=xtrainingsupport_score>=100
	gen xtrainingsupport_50 	=xtrainingsupport_score>=50
		drop max temp		

	/*
	foreach var of varlist xabsence_*{
		replace `var'=, if xabsence!=1
		}
		
	foreach var of varlist xhr_*{
		replace `var'=, if xhr!=1
		}
		
	foreach var of varlist xtraining_* xtrainingsupport_*{
		replace `var'=, if xtraining!=1
		}	
	*/	
		
	sum staff* xabsence* xhr* xtraining* 	
	
	gen ximst		= q209==1
	gen ximst_fun	= q210==1
	
	*****************************
	* Section 3: bed capacity & staff
	*****************************

	gen byte xipt= q111==1
	gen byte xicu= q112>=1 & q112!=.
	lab var xipt "facilities providing IPT services"
	lab var xicu "facilities providing ICU services"
	
	gen ybed 			= q112
	gen ybed_icu 	 	= q113
		replace ybed_icu=0 if xipt==1 & xicu==0 /*assume 0 ICU beds if IPT provided but no ICU beds reported*/
	
	gen ybed_cap_covid 			= q301
	gen ybed_cap_covid_severe 	= q302
	gen ybed_cap_covid_critical = q303
	gen ybed_cap_covid_moderate = ybed_cap_covid - (ybed_cap_covid_severe + ybed_cap_covid_critical)
	gen ybed_cap_noncovid		= ybed - ybed_cap_covid 
		
	gen ybed_covid_night   = (q304 + q305)/2
	
	gen ybed_cap_isolation 	 = q306	
	gen ybed_convert_respiso = q307
	gen ybed_convert_icu 	 = q308
	
	gen xocc_lastnight 		 = 100* (q309 / ybed) /* % of beds occupied by any patients, last night */ 
	gen xocc_lastnight_covid = 100*(ybed_covid_night/ybed) /* % of beds occupied by COVID patients, last night */ 
	gen xcovid_occ_lastnight = 100*(ybed_covid_night/ybed_cap_covid) /* % of COVID beds occupied by COVID patients, last night  */ 
		
	*****************************
	* Section 4: Therapeutics
	*****************************
		
	global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015" 
	foreach item in $itemlist{	
		gen xdrug__`item' = q401_`item' ==1
		}		
		
		gen max=`maxdrug'
		egen temp=rowtotal(xdrug__*) 
	gen xdrug_score	=100*(temp/max)
	gen xdrug_100 	=xdrug_score>=100
	gen xdrug_50 	=xdrug_score>=50
		drop max temp
	
	global itemlist "001 002 003"
	foreach item in $itemlist{	
		gen xsupply__`item' = q402_`item' ==1
		}
		
		gen max=3
		egen temp=rowtotal(xsupply__*)  
	gen xsupp_score	=100*(temp/max)
	gen xsupp_100 	=xsupp_score>=100
	gen xsupp_50 	=xsupp_score>=50
		drop max temp


	*****************************
	* Section 5: IPC 
	*****************************
	
	gen xipcpp= q501==1
	
	gen xsafe= q502==1
	global itemlist "001 002 003 004 005 006 007 008 009 010 011" 
	foreach item in $itemlist{	
		gen xsafe__`item' = q503_`item' ==1
		}		
	
		gen max=11
		egen temp = rowtotal(xsafe__*)
	gen xsafe_score	=100*(temp/max)
	gen xsafe_100 	=xsafe_score>=100
	gen xsafe_50 	=xsafe_score>=50
		drop max temp
			
	gen xguideline= q504
	global itemlist "001 002 003 004 005 006" 
	foreach item in $itemlist{	
		gen xguideline__`item' = q505_`item' ==1
		}		
		
		gen max=6
		egen temp=	rowtotal(xguideline__*)
	gen xguideline_score	=100*(temp/max)
	gen xguideline_100 		=xguideline_score>=100
	gen xguideline_50 		=xguideline_score>=50
		drop max temp
				
	gen xppe= q506
	global itemlist "001 002 003 004 005 006" 
	foreach item in $itemlist{	
		gen xppe_allsome__`item' = q507_`item'==1 | q507_`item'==2
		}	

		gen max=6 
		egen temp=	rowtotal(xppe_allsome__*)
	gen xppe_allsome_score	=100*(temp/max)
	gen xppe_allsome_100 		=xppe_allsome_score>=100
	gen xppe_allsome_50 		=xppe_allsome_score>=50
		drop max temp
			
	global itemlist "001 002 003 004 005 006" 
	foreach item in $itemlist{	
		gen xppe_all__`item' = q507_`item'==1
		}						

		gen max=6
		egen temp=	rowtotal(xppe_all__*)
	gen xppe_all_score	=100*(temp/max)
	gen xppe_all_100 		=xppe_all_score>=100
	gen xppe_all_50 		=xppe_all_score>=50
		drop max temp

	gen xppedispose = q508==1 
		
	global itemlist "001 002 003 004 005" 	
	foreach item in $itemlist{	
		gen xipcitem__`item' = q509_`item'==1
		}						

		gen max=5
		egen temp=	rowtotal(xipcitem__*)
	gen xipcitem_score	=100*(temp/max)
	gen xipcitem_100 		=xipcitem_score>=100
	gen xipcitem_50 		=xipcitem_score>=50
		drop max temp
		
	sum xipc* xsafe* xguideline* xppe*

	*****************************
	* Section 6 : LAB
	*****************************
	
	gen xspcm		=q601==1
	global itemlist "001 002" 	
	foreach item in $itemlist{	
		gen xspcmitem__`item' = q602_`item'==1
		}							

		
		gen max=2
		egen temp=	rowtotal(xspcmitem__*) 
	gen xspcmitem_score	=100*(temp/max)
	gen xspcmitem_100 		=xspcmitem_score>=100
	gen xspcmitem_50 		=xspcmitem_score>=50
		drop max temp	
		
	gen xpcr 			= q603_001==1
	gen xpcr_equip		= q604==1
	gen xpcr_capacity 	= round(100*(q606/q607), 1)

	foreach var of varlist xpcr_*	{
		replace `var'=. if xpcr==0
		}	

	gen xrdt 			= q603_002==1
	gen xrdt_equip		= q608_001==1 & q608_002==1
	gen xrdt_capacity 	= round(100*(q609/q610), 1)
			
	foreach var of varlist xrdt_*	{
		replace `var'=. if xrdt==0
		}	

	gen xonsite= xpcr==1 | xrdt==1
	gen xonsite_waste= q611==1
	gen xonsite_equip= (xpcr_equip==1 | xrdt_equip==1) 
	gen xonsite_ready= xonsite_equip & xonsite_waste==1

	foreach var of varlist xonsite_*	{
		replace `var'=. if xonsite==0
		}	
		
	gen xoffsite			=(q603_001==0 & q603_002==0) /*test else where*/
	gen xoffsitetransport	=(q603_001==0 & q603_002==0) & q612==1	/*test else where + transportation*/
	
	gen xoffsitetime_1 =q613<=1 /*less than 1 days*/ 
	gen xoffsitetime_2 =q613<=2 /*less than 2 days*/ 
	gen xoffsitetime_3 =q613<=3 /*less than 3 days*/ 
	gen xoffsitetime_7 =q613<=4 /*less than 7 days*/ 
	
	foreach var of varlist xoffsitetime_*	{
		replace `var'=. if xoffsite==0
		}

		tab xoffsitetime_3 xonsite_ready, m
		
		gen max=2
		egen temp =  rowtotal(xspcmitem_100 xoffsitetime_3 xonsite_ready)
	gen xdiagcovid_score = 100*(temp/max)
	gen xdiagcovid_100	= xdiagcovid_score >=100
	gen xdiagcovid_50	= xdiagcovid_score >=50
		drop max temp

	*****************************
	* Section 7: Equipment 
	*****************************
	///* KEYC edit begins *//
	gen yequip_ventilator 		= q701_003_002
	gen yequip_noninvventilator = q701_004_002
	
		lab var yequip_ventilator "number of functioning equipment: ventilator"
		lab var yequip_noninvventilator "number of functioning equipment: non-invasive ventilator"
		
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xequip_anyfunction__`item' = q701_`item'_002>=1 
		}			
		
		gen max=4
		egen temp=rowtotal(xequip_anyfunction_*)
	gen xequip_anyfunction_score	=100*(temp/max)
	gen xequip_anyfunction_100		=xequip_anyfunction_score>=100
	gen xequip_anyfunction_50		=xequip_anyfunction_score>=50
		drop max temp				
				
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xequip_allfunction__`item' = q701_`item'_002>=1 & (q701_`item'_002 == q701_`item'_001)
		}			
		
		gen max=4
		egen temp=rowtotal(xequip_allfunction_*)
	gen xequip_allfunction_score	=100*(temp/max)
	gen xequip_allfunction_100		=xequip_allfunction_score>=100
	gen xequip_allfunction_50		=xequip_allfunction_score>=50
		drop max temp				
	
	global itemlist "003 004"
	foreach item in $itemlist{	
		gen xequip_anymalfunction__`item' = q701_`item'_001>=1 & (q701_`item'_002 != q701_`item'_001)
		}			

		egen temp=rowtotal(xequip_anymalfunction__003 xequip_anymalfunction__004)
	gen xequip_anymalfunction=temp>=1
		drop temp
	
	/*	
	global itemlist "001 002 003 004 005"
	foreach item in $itemlist{	
		gen xequip_allmalfunction__`item' = q701_`item'_002==0 & (q701_`item'_003>=1 & q701_`item'_003!=.)
		}			

		egen temp=rowtotal(xequip_allmalfunction_*)
	gen xequip_allmalfunction=temp==5
		drop temp		
	*/
	
	global itemlist "001 002 003 004 005 006"
	foreach item in $itemlist{	
		gen xequip_malfunction_reason__`item' = q702_`item'==1 | q703_`item'==1 
		}
	
		foreach var of varlist xequip_malfunction_reason__*{
			replace `var'=. if xequip_anymalfunction!=1
			}
	
	gen xoxygen_concentrator= q704_001==1 
	gen xoxygen_bulk 		= q704_002==1 
	gen xoxygen_cylinder	= q704_003==1 
	gen xoxygen_plant 		= q704_004==1   
	
		egen temp=rowtotal(xoxygen_*)
	gen xoxygensource	=temp>=1
		drop temp
	
	gen xoxygen_dist 		 = q705==1
	gen xoxygen_portcylinder = q706==1

	*****************************
	* Section 8: General vaccine
	*****************************

	gen xvac= q801==1 | q802==1
	
	gen xvac_av_fridge 			= q803==1 | q803==2
	gen xvac_avfun_fridge 		= q803==1 
	gen xvac_avfun_fridgetemp 	= q803==1 & q804==1
	
	gen xvac_av_coldbox	= q805==1
	
	gen xvac_avfun_coldbox_all		= q805==1 & (q806>=1 & q806!=.) & q807==1
	gen xvac_avfun_coldbox_all_full	= q805==1 & (q806>=1 & q806!=.) & q807==1 & q811==1
	
	gen yvac_avfun_coldbox_all		= q806 if xvac_avfun_coldbox_all==1
	gen yvac_avfun_coldbox_all_full	= q806 if xvac_avfun_coldbox_all==1 & q811==1
	
	gen xvac_av_carrier	= q808==1
	
	gen xvac_avfun_carrier_all		= q808==1 & (q809>=1 & q809!=.) & q810==1	
	gen xvac_avfun_carrier_all_full	= q808==1 & (q809>=1 & q809!=.) & q810==1 & q811==1	
	
	gen yvac_avfun_carrier_all		= q809 if xvac_avfun_carrier_all==1
	gen yvac_avfun_carrier_all_full	= q809 if xvac_avfun_carrier_all==1 & q811==1

	gen xvac_av_outreach = xvac_av_coldbox ==1 | xvac_av_carrier ==1  
	gen xvac_avfun_outreach_all_full = xvac_avfun_coldbox_all_full ==1 | xvac_avfun_carrier_all_full==1  
	
	gen xvac_sharp = q812==1
	
	gen xvac_aefikit = q813==1
	gen xvac_aefireport = q814==1
	
	foreach var of varlist xvac_av* yvac_av* xvac_sharp xvac_aefi*{
		replace `var'=. if xvac!=1
		}
		
	lab var xvac_av_fridge "has fridge"
	lab var xvac_avfun_fridge "has functioning fridge"
	lab var xvac_avfun_fridgetemp "has functioning fridge with temp log"
	
	lab var xvac_av_coldbox "has coldbox"
	lab var xvac_avfun_coldbox_all "has functioning coldbox, all"
	lab var xvac_avfun_coldbox_all_full "has functioning coldbox with icepacks, all"
	
	lab var xvac_av_carrier "has carrier"
	lab var xvac_avfun_carrier_all "has functioning carrier, all"
	lab var xvac_avfun_carrier_all_full "has functioning carrier with icepacks, all"

	*****************************
	* Section 9: COVID-19 vaccine
	*****************************
	
	/*
	*This part is HIDDEN cause these were created in the above section for the mock data 
	*In real, however, only section 8 OR 9 will be implemented. 
	*Open up this part, if section 9 is used. 
	*Delete this whole Section 9 if section 8 is used. 
	gen xvac_av_fridge 			= q901==1 | 901==2
	gen xvac_avfun_fridge 		= q901==1 
	gen xvac_avfun_fridgetemp 	= q901==1 & q902==1	
	*/
	
	gen xcovax=q903==1
	
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xcovax_offer__`item' = q904_`item'==1 | q904_`item'==2 
		gen xcovax_offerav__`item' = q904_`item'==1 
		}
		
	global itemlist "001 002 003 004"
	foreach item in $itemlist{	
		gen xcovax_train__`item' = q905_`item'==1
		}		
	
	gen xcovax_syr		=q906==1
	gen xcovax_sharp	=q907==1
	gen xcovax_strtemp	=q908==1
	gen xcovax_strtemp_w=q908==1 & q909==1
	
	gen xcovax_infrtrn		=q910==1
		replace xcovax_infrtrn = . if (q904_001==3 & q904_002==3 & q904_003==3) 
	gen xcovax_infside		=q911==1
	gen xcovax_infaewhat	=q912==1
	
	gen xcovax_aefikit 		= q913==1
	gen xcovax_aefireport 	= q914==1	
	
	foreach var of varlist xcovax_*{
		replace `var'=. if xcovax!=1
		}	
	
*****E.2.Addendum
**		Rename indicators ending with sub-question numbers with more friendly names. 
**		These names are used in the dashboard. 
**		Thus, it is important to ensure the indicator names are correct, if questionnaire is adapted beyond minimum requirements.
**		(Addendum on August 17, 2021)

		rename	xtraining__001	xtraining__ipc
		rename	xtraining__002	xtraining__ppe
		rename	xtraining__003	xtraining__triage
		rename	xtraining__004	xtraining__emerg
		rename	xtraining__005	xtraining__remote
		rename	xtraining__006	xtraining__mental
		rename	xtraining__007	xtraining__ss_ipc
		rename	xtraining__008	xtraining__ss_ppe
		rename	xtraining__009	xtraining__ss_c19cm
				
		rename	xdrug__001	xdrug__alcohol
		rename	xdrug__002	xdrug__chlorine
		rename	xdrug__003	xdrug__paracetamol
		rename	xdrug__004	xdrug__ampicillin
		rename	xdrug__005	xdrug__ceftriaxone
		rename	xdrug__006	xdrug__azithromycin
		rename	xdrug__007	xdrug__dexamethasone
		rename	xdrug__008	xdrug__tocilizumab
		rename	xdrug__009	xdrug__heparin
		rename	xdrug__010	xdrug__rocuronium
		rename	xdrug__011	xdrug__morphine
		rename	xdrug__012	xdrug__haloperidol
		rename	xdrug__013	xdrug__epinephrine
		rename	xdrug__014	xdrug__saline
		rename	xdrug__015	xdrug__oxygen
				
		rename	xsupply__001	xsupply__ivsets
		rename	xsupply__002	xsupply__nasalcanulae
		rename	xsupply__003	xsupply__facemasks
				
		rename	xsafe__001	xsafe__entrance_screening
		rename	xsafe__002	xsafe__staff_entrance
		rename	xsafe__003	xsafe__sep_room
		rename	xsafe__004	xsafe__triage_c19
		rename	xsafe__005	xsafe__isolatareas
		rename	xsafe__006	xsafe__triage_guidelines
		rename	xsafe__007	xsafe__distancing
		rename	xsafe__008	xsafe__hygiene_instructions
		rename	xsafe__009	xsafe__hygiene_stations
		rename	xsafe__010	xsafe__ppe
		rename	xsafe__011	xsafe__cleaning
				
		rename	xguideline__001	xguideline__screening
		rename	xguideline__002	xguideline__c19_manage
		rename	xguideline__003	xguideline__ppe
		rename	xguideline__004	xguideline__c19_surveillance
		rename	xguideline__005	xguideline__deadbody
		rename	xguideline__006	xguideline__waste
				
		rename	xppe_allsome__001	xppe_allsome__gown
		rename	xppe_allsome__002	xppe_allsome__gloves
		rename	xppe_allsome__003	xppe_allsome__goggles
		rename	xppe_allsome__004	xppe_allsome__faceshield
		rename	xppe_allsome__005	xppe_allsome__respirator
		rename	xppe_allsome__006	xppe_allsome__mask
				
		rename	xppe_all__001	xppe_all__gown
		rename	xppe_all__002	xppe_all__gloves
		rename	xppe_all__003	xppe_all__goggles
		rename	xppe_all__004	xppe_all__faceshield
		rename	xppe_all__005	xppe_all__respirator
		rename	xppe_all__006	xppe_all__mask
				
		rename	xipcitem__001	xipcitem__soap
		rename	xipcitem__002	xipcitem__sanitizer
		rename	xipcitem__003	xipcitem__biobag
		rename	xipcitem__004	xipcitem__boxes
		rename	xipcitem__005	xipcitem__bodybags
				
		rename	xspcmitem__001	xspcmitem__transport
		rename	xspcmitem__002	xspcmitem__swab
				
		rename	xoffsitetime_1	xoffsitetime_24hours
		rename	xoffsitetime_2	xoffsitetime_2days
		rename	xoffsitetime_3	xoffsitetime_3days
		rename	xoffsitetime_7	xoffsitetime_7days
				
		rename	xequip_anyfunction__001	xequip_anyfunction__xray
		rename	xequip_anyfunction__002	xequip_anyfunction__oximeters
		rename	xequip_anyfunction__003	xequip_anyfunction__vicu
		rename	xequip_anyfunction__004	xequip_anyfunction__vnoninv
				
		rename	xequip_allfunction__001	xequip_allfunction__xray
		rename	xequip_allfunction__002	xequip_allfunction__oximeters
		rename	xequip_allfunction__003	xequip_allfunction__vicu
		rename	xequip_allfunction__004	xequip_allfunction__vnoninv
				
		rename	xequip_anymalfunction__003	xequip_anymalfunction__vicu
		rename	xequip_anymalfunction__004	xequip_anymalfunction__vnoninv
				
		rename	xequip_malfunction_reason__001	xequip_malfunction_reason__inst
		rename	xequip_malfunction_reason__002	xequip_malfunction_reason__cons
		rename	xequip_malfunction_reason__003	xequip_malfunction_reason__staff
		rename	xequip_malfunction_reason__004	xequip_malfunction_reason__funds
		rename	xequip_malfunction_reason__005	xequip_malfunction_reason__power
		rename	xequip_malfunction_reason__006	xequip_malfunction_reason__other
				
		rename	 xcovax_offer__001	xcovax_offer__pfizer
		rename	 xcovax_offerav__001	xcovax_offerav__pfizer
		rename	 xcovax_offer__002	xcovax_offer__moderna
		rename	 xcovax_offerav__002	xcovax_offerav__moderna
		rename	 xcovax_offer__003	xcovax_offer__astra
		rename	 xcovax_offerav__003	xcovax_offerav__astra
		rename	 xcovax_offer__004	xcovax_offer__jj
		rename	 xcovax_offerav__004	xcovax_offerav__jj
				
		rename	 xcovax_train__001	xcovax_train__storage
		rename	 xcovax_train__002	xcovax_train__admin
		rename	 xcovax_train__003	xcovax_train__manage_adverse
		rename	 xcovax_train__004	xcovax_train__report_adverse
	
	sort facilitycode
	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 		
	
*****E.3. Merge with sampling weight 
***** MUST select/run Chunk A or B, depending on the sample design 
/*RUN this chunk A if there is samplingb weight*/
*CHUNK A BEGINS  

import excel "$chartbookdir/WHO_COVID19HospitalReadiness_Chartbook_08.21.xlsx", sheet("Weight") firstrow clear
	rename *, lower
		
	sort facilitycode
	merge facilitycode using COVID19HospitalReadiness_`country'_R`round'.dta, 
	
		tab _merge
		*****CHECK HERE: all should be 3 (i.e., match) by the end of the data collection*/
		drop _merge*
		
	sort id /*this is generated from Lime survey*/
	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 		
	
*CHUNK A ENDS

/*RUN this chunk B if there is NO samplingb weight
*CHUNK B BEGINS  	

	gen weight=1 

*CHUNK B BEGINS  
*/
	
*****E.4. Export clean facility-level data to chart book 
	
	save COVID19HospitalReadiness_`country'_R`round'.dta, replace 		

	export delimited using COVID19HospitalReadiness_`country'_R`round'.csv, replace 

	export excel using "$chartbookdir/WHO_COVID19HospitalReadiness_Chartbook_08.21.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
		
**************************************************************
* F. Create indicator estimate data 
**************************************************************

use COVID19HospitalReadiness_`country'_R`round'.dta, clear
	
	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	gen obs_ipt=1 	if xipt==1
	gen obs_icu=1 	if xicu==1
	gen obs_vac=1 	if xvac==1
	gen obs_covax=1 	if xcovax==1	
	
	gen obs_spcm=1 	if xspcm==1
	gen obs_pcr=1 	if xpcr==1
	gen obs_rdt=1 	if xrdt==1
	gen obs_onsite=1 	if xpcr==1 | xrdt==1
	gen obs_offsite=1 	if xoffsite==1
	
	/*
	gen xresult=q1004==1
	tab xresult, m
	keep if xresult==1
	drop xresult	
	*/
	
	save temp.dta, replace 

*****F.1. Calculate estimates  

	use temp.dta, clear
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed*  yequip* yvac*  [iweight=weight], by(country round month year  )
		gen group="All"
		gen grouplabel="All"
		keep obs* country round month year  group* x*  y* staff_num_* 
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed*  yequip* yvac*  [iweight=weight], by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="Rural" if zurban==0
			replace grouplabel="Urban" if zurban==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta, force
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed*  yequip* yvac*  [iweight=weight], by(country round month year   zlevel_hospital)
		gen group="Level"
		gen grouplabel=""
			replace grouplabel="Primary/Secondary" if zlevel_hospital==0
			replace grouplabel="Tertiary" if zlevel_hospital==1
		keep obs* country round month year  group* x*  y* staff_num_* 
			
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed*  yequip* yvac*  [iweight=weight], by(country round month year   zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="Non-public" if zpub==0
			replace grouplabel="Public" if zpub==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_COVID19HospitalReadiness_`country'_R`round'.dta		
		save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 
			
	***** convert proportion to %		
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
			* But, convert back variables that were incorrectly converted (e.g., occupancy rates, score)	
			foreach var of varlist xocc* xcovid_occ* *_capacity *_score {
				replace `var'=round(`var'/100, 1)	
				}		

	***** generate staff infection rates using the pooled data	
	global itemlist "md nr othclinical clinical nonclinical all" 
	foreach item in $itemlist{	
		gen staff_pct_covid_`item' = round(100* (staff_num_covid_`item' / staff_num_total_`item' ), 0.1)
		}	
		
	***** generate COVID-19 vaccine among staff using the pooled data	
		gen staff_pct_covaxany  = round(100*staff_num_covaxany  / staff_num_total_all, 1)
		gen staff_pct_covaxfull = round(100*staff_num_covaxfull / staff_num_total_all, 1)
	
	tab group round, m
	
	***** round the number of observations, in case sampling weight was used (edit 5/22/2021)
	foreach var of varlist obs*{
		replace `var' = round(`var', 1)
		}	

	***** organize order of the variables by section in the questionnaire  
	order country round year month group grouplabel obs* staff*
		
	sort country round group grouplabel
	
save summary_COVID19HospitalReadiness_`country'_R`round'.dta, replace 

export delimited using summary_COVID19HospitalReadiness_`country'_R`round'.csv, replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_COVID19HospitalReadiness_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"

export excel using "$chartbookdir/WHO_COVID19HospitalReadiness_Chartbook_08.21.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt

/* To check against R results
export delimited using "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/summary_COVID19HospitalReadiness_`country'_R`round'_Stata.csv", replace 
*/

erase temp.dta

END OF DATA CLEANING AND MANAGEMENT 

