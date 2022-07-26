clear
clear matrix
clear mata
capture log close
set more off
numlabel, add

* Date of the combined COVID-19 HFA questionniare version: 26 July, 2022
* Date of last code update: 26 July, 2022

*This code 
*1) imports and cleans dataset from Lime Survey, and 
*2) creates indicator estimate data for dashboards and chartbook. 
*		=====> First Purple Tab in Chartbook: "Indicator estimate data"
*3) creates indicator estimate data for trend analysis. 
*		=====> Second Purple Tab in Chartbook: "All round data"
*4) conducts minimum data quality check /*NEW Section G*/. 

*  DATA IN:	CSV file daily downloaded from Limesurvey 	
*  DATA OUT: 
*		1. raw data (as is, downloaded from Limesurvey) 
*			=> CSV, dta, and green tab in Chartbook  	
*		2. cleaned data with additional analytical variables in Chartbook and, for further analyses, as a datafile 
*			=> CSV, dta, and blue tab in Chartbook  	
*		3. summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	
*			=> CSV, dta, and the first purple tab in Chartbook  	
*		4. ALL-ROUND summary estimates of indicators in Chartbook and, for dashboards, as a datafile 	
*			=> The second purple tab in Chartbook  	
*  NOTE OUT to log file for minimum data quality check  
*		1. DataCheck_CombinedCOVID19HFA_`country'_R`round'_$date.log

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
*****C.4. Recode yes/no 
*****C.5. Label values 
* D. Field check tables - dropped from the previous analysis code.  
* E. Create analytical variables 
*****E.1. Country speciic code local <<<<<<<<<<========== MUST BE ADAPTED: 2. local per survey implementation and section 1 
*****E.2. Construct analysis variables <<<<<<<<<<========== MUST BE ADAPTED: 3. indicators  
*		In addition to creating variables based on the revised questionnaire, it also does the following: 
*		(1) Rename detailed indicators ending with sub-question numbers with more friendly/intuitive names (Previously E.2.A), and 
*		(2) Create "global indicators" that were created at the HQ level after country analyses were completed.   
*			They can be found under "ADDITIONAL FROM "GLOBAL INDICATORS"" at the end of each section. 
*****E.3. Merge with sampling weight <<<<<<<<<<========== MUST BE ADAPTED: 4. weight depending on sample design 
*****E.4. Export clean Respondent-level data to chart book 
* F. Create and export indicator estimate data 
*****F.1. Calculate estimates 
*****F.2. Export indicator estimate data to chart book and dashboard
* G. MINIMUM data quality check 
* H. Append with previous "indicator estimate data" 

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
local round 			 3 /*round*/		
local year 			 	 2022 /*year of the mid point in data collection*/	
local month 			 8 /*month of the mid point in data collection*/				

local surveyid 			 969569 /*LimeSurvey survey ID*/

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

import delimited "$downloadcsvdir/LimeSurvey_CombinedHFA_EXAMPLE_R3.csv", case(preserve) clear /*THIS LINE ONLY FOR PRACTICE*/

*****B.2. Export/save the data daily in CSV form with date 	
export delimited using "$downloadcsvdir/LimeSurvey_CombinedCOVID19HFA_`country'_R`round'_$date.csv", replace
	
*****B.3. Export the data to chartbook  	

	/*MASK idenitifiable information for respondents.*/
	foreach var of varlist Q104 Q112  {
		replace `var'=""
		}		
	foreach var of varlist Q113 Q1002 Q1003 {
		replace `var'=.		
		}		
		
export excel using "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Facility-level raw data") sheetreplace firstrow(variables) nolabel

*****B.4. Drop duplicate cases 

	codebook Q101
	list Q101 - Q105 if Q101==. 
	*****CHECK HERE: 
	*		this is an empty row. There should be none	

	lookfor id
	rename *id id
	codebook id 
	*****CHECK HERE: 
	*		this is an ID variable generated by LimeSurvey, not facility ID.
	*		not user for analysis 
	*		still there should be no missing	
	drop id

	*****identify duplicate cases, based on facility code*/
	duplicates tag Q101, gen(duplicate) 
		
		/* 
		* must check string value and update
		* 	1. "mask" in the "clock" line for submitdate
		* 	2. "format" line for the submitdatelatest		
		* REFERENCE: https://www.stata.com/manuals13/u24.pdf
		* REFERENCE: https://www.stata.com/manuals13/ddatetime.pdf#ddatetime
		*/
		codebook submitdate 
				
		rename submitdate submitdate_string			
	gen submitdate = clock(submitdate_string, "MD20Y hm") /*"clock" line in the standard code*/
	*gen double submitdate = clock(submitdate_string, "MDY hm") /*"clock" line with different mask: 4-digit year*/
	*gen double submitdate = clock(submitdate_string, "YMDhms") /*"clock" line with different mask: with seconds*/
		format submitdate %tc 
		codebook submitdate*
			
	list Q101 Q105 submitdate if duplicate!=0  
	*****CHECK HERE: 
	*		In the model data, there is one facility that have three data entries for practice purpose. 

	*****drop duplicates before the latest submission */
	egen double submitdatelatest = max(submitdate) if duplicate!=0  , by(Q101) /*LATEST TIME WITHIN EACH DUPLICATE*/					
		format %tcnn/dd/ccYY_hh:MM submitdatelatest /*"format line without seconds*/
		*format %tcnn/dd/ccYY_hh:MM:SS submitdatelatest /*"format line with seconds*/
		
		sort Q101 submitdate
		list Q101 Q105 submitdate* if duplicate!=0 	

		/*
		. list Q101 submitdate* if duplicate!=0 
			 +-----------------------------------------------------------------+
			 |      Q101   submitdate_~g           submitdate   submitdatela~t |
			 |-----------------------------------------------------------------|
		 62. | 4.433e+09   7/23/22 22:20   23jul2022 22:19:49   7/24/2023 6:59 |
		 63. | 4.433e+09    7/24/23 9:00   24jul2023 09:00:47   7/24/2023 6:59 |
		 64. | 4.433e+09   7/24/23 19:00   24jul2023 18:59:21   7/24/2023 6:59 |
			 +-----------------------------------------------------------------+	
		*/	
		
	drop if duplicate!=0  & submitdate!=submitdatelatest 
	drop if Q101==. 
	
	*****confirm there's no duplicate cases, based on facility code*/
	duplicates report Q101,
	*****CHECK HERE: 
	*		Now there should be no duplicate 
	
	drop duplicate submitdatelatest
	
**************************************************************
* C. Data cleaning - variables 
**************************************************************

*****C.1. Change var names to lowercase
 
	rename *, lower

*****C.1.a. Assess and drop timestamp data 

	drop *time* 
	*interviewtime is availabl in dataset only when directly downloaded from the server, not via export plug-in used in this code
	*So, just do not deal with interview time for now. 

*****C.2. Change var names to drop odd elements "y" "sq" - because of Lime survey's naming convention 
	
	rename (*sq*) (*_*) /*replace sq with _*/
		
	rename (q201_*_a1) (q201_*_a)
	rename (q201_*_a2) (q201_*_b)

	rename (q501_*1) (q501_*_a)
	rename (q501_*2) (q501_*_b)
	
	rename (q505_*1) (q505_*_a)
	rename (q505_*2) (q505_*_b)
	
	lookfor sq
	lookfor a
	lookfor b
	
*****C.3. Find non-numeric variables and desting 

	*****************************
	* Section 1
	*****************************
	sum q1*
		
	foreach var of varlist q106 q107 q108 q110 {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}
		
	sum q1*			

	*****************************	
	* Section 2
	*****************************
	sum q2*	
		
	foreach var of varlist q208* q210*  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		replace `var' = "88" if `var'=="-oth-"
		destring `var', replace 
		}	
		
	sum q2*		
	
	*****************************	
	* Section 3
	*****************************
	sum q3*
		
	foreach var of varlist q302* q304* q305* q307*  {	
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q3*
	
	*****************************	
	* Section 4
	*****************************
	sum q4*
		
	foreach var of varlist q402* q403* q416* q418*   {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			

	sum q4*

	*****************************
	* Section 5
	*****************************
	sum q5*	
		
	foreach var of varlist q501* q502 q505* q507*  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q5*	

	*****************************	
	* Section 6		
	*****************************	
	sum q6*	
	
	foreach var of varlist q601* q602* q603* q604* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}				
		
	sum q6*		
	
	*****************************
	* Section 7
	*****************************
	sum q7*
		
	foreach var of varlist q701* q702*  {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}	
		
	sum q7*	
	
	*****************************	
	* Section 8
	*****************************
	sum q8*
		
	foreach var of varlist q804 q807* q808* 	{		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
		
	sum q8*

	*****************************		
	* Section 9
	*****************************
	sum q9*
			
	foreach var of varlist q904* q907 q908 q909* q911* {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}		
		
	sum q9*
	
	*****************************			
	* Section 10: interview results
	*****************************
	sum q100*	
	
	foreach var of varlist q1001 q1004 {		
		replace `var' = usubinstr(`var', "A", "", 1) 
		destring `var', replace 
		}			
	
	sum q100*	
	
*****C.4. Recode yes/no 

	#delimit;
	global varlistyesno "
		q109 q110
		q207 q208* q209 q210* q211 
		q301 q302* q303 q306 q307*
		q401 q404 q405 q406 q407 q412 q413 q415 q417 q418*
		q501_*_a q501_*_b q503* q504* q505_*_b q506 
		q601* q604*
		q702* q703 q704
		q801 q802 q803 q805 q806 
		q901 q905 q906 q910 q911* q912 q913 q914
		q1001
		"; 
		#delimit cr
	
	sum $varlistyesno

	foreach var of varlist $varlistyesno{
		recode `var' 2=0 /*no*/
		}	
							
*****C.5. Label values 
{
	#delimit;	
	
	lab define urbanrural
		1"1.Urban" 
		2"2.Rural";  
	lab values q106 urbanrural; 
	
	lab define sector 
		1"1.Government"
		2"2.Private for profit"
		3"3.Private not for profit"
		4"4.Other"; 
	lab values q108 sector; 
	
	lab define ipc
		1"1.Currently available for all health workers"
		2"2.Currently available only for some health workers"
		3"3.Currently unavailable for any health workers"
		4"4.Not applicable – never provided" ;
	foreach var of varlist q304* q305* {;
	lab values `var' ipc;	
	};	
	
	lab define mgmtcovid
		1"1.Yes to almost all patients"
		2"2.Yes but only to some patients"
		3"3.None of the patients";
	foreach var of varlist q402* q403* {;
	lab values `var' mgmtcovid;	
	};	
	
	lab define mgmtsevere
		1"1.Yes almost always"
		2"2.Yes but only at certain times of days"
		3"3.No, never able to provide the care"
		4"4.N/A";
	foreach var of varlist q416* {;
	lab values `var' mgmtsevere;	
	};	
	
	lab define optchange
		1"1.Much lower"
		2"2.Lower"
		3"3.Similar"
		4"4.Higher"
		5"5.Much higher";
	foreach var of varlist q502 {;
	lab values `var' optchange;	
	};	
	
	lab define outreachchange
		1"1.Yes changed, decreased"
		2"2.Yes changed, suspended"
		3"3.No change in frequency"
		4"4.Yes changed, increased"
		5"N/A";
	foreach var of varlist q507* {;
	lab values `var' outreachchange;	
	};			
	
	lab define availfunc 
		1"1.Yes, functional"
		2"2.Yes, but not functional"
		3"3.Unavailable";
	foreach var of varlist 
		q701* q807* q808* 
		q902 q903 q907 q908 {;
	lab values `var' availfunc ;	
	};	
	
	lab define pcrprocess
		1"1.Process specimens in the facility"
		2"2.Send specimens outside";
	foreach var of varlist q804 {;
	lab values `var' pcrprocess ;	
	};		

	lab define yesno 
		1"1.Yes" 
		0"0.No"; 	
	foreach var of varlist $varlistyesno {;		
	lab values `var' yesno; 
	};
	
	lab define yesnona 
		1"1.Yes" 
		2"2.No" 
		3"N/A"; 
	foreach var of varlist 
		q505_*_a
		q602* q603*
		{;		
	lab values `var' yesnona; 
	};
	
	lab define yesyesbutno 
		1"1.Yes, provided and available" 
		2"2.Yes, provided but unavailable" 
		3"3.Not provided"; 
	foreach var of varlist 
		q904* q909*
		{;		
	lab values `var' yesyesbutno; 
	};	
	
	lab define results
		1"1.COMPLETED"
		2"2.POSTPONED"
		3"3.PARTLY COMPLETED AND POSTPONED" 
		4"4.PARTLY COMPLETED"
		5"5.REFUSED"
		6"6.OTHER"; 
	lab values q1004 results; 
		
	#delimit cr
}
**************************************************************
* E. Create analytical variables 
**************************************************************

*****E.1. Country speciic code local 
	
	***** MUST REVIEW CODING FOR THE FOLLOWING VARIABLES AT MINIMUM */
		/*
		zurban
		zlevel*
		zpub
		*/
	
	/*DEFINE LOCAL FOR THE FOLLOWING*/ 
		
		local minlow		 	1 /*lowest code for lower-level facilities in q107*/
		local maxlow		 	1 /*highest code for lower-level facilities in q107*/ 
		local minhigh		 	2 /*lowest code for hospital/high-level facilities in q107*/  
		local maxhigh			4 /*highest code for hospital/high-level facilities in q107*/ 

		local pubmin			1
		local pubmax			1
	
*****E.2. Construct analysis variables 

* give prefix z for background characteristics, which can be used as analysis strata     
* give prefix x for binary variables, which will be used to calculate percentage   
* give prefix y for integer/continuous variables, which will be used to calculate total
* give prefix staff for a number of staff integer variables, which will be used to calculate total

	*****************************
	* Section 1 
	*****************************
	
	***** basic variables
	
		gen double facilitycode = q101
		lab var facilitycode "facility ID from sample list" 
		/*this will be used to merge with sampling weight, if relevant*/	

		gen country = "`country'"
		gen round 	=`round'
		gen month	=`month'
		gen year	=`year'
			
		gen zurban	=q106==1
		
		gen zlevel_hospital		=q107>=`minhigh' & q107<=`maxhigh'
		gen zlevel_low			=q107>=`minlow'  & q107<=`maxlow'

		gen zpub	=q108>=`pubmin' & q108<=`pubmax'

		gen zc19cm=q110==1 /*NEW*/
			/*
			*MOST IMPORTANT CHECK before data collection! 
			*DOUBLE CHECK q110, filter for green/blue shaded questions in the tool
			gen temp=0 
			capture confirm variable q109
				if !_rc {
				replace temp = 1 if zlevel_hospital==1 | q109==1  	
				}
				else{
					replace temp = 1 if zlevel_hospital==1 
				}			
			
			tab zc19cm temp, m 
			drop temp
			*/
				
		lab define zurban 0"Rural" 1"Urban"
		lab define zlevel_hospital 0"Non-hospital" 1"Hospital"
		lab define zpub 0"Non-public" 1"Public"
		lab define zc19cm 0"NOT eligible for C19CM questions" 1"eligible for C19CM questions"	

		lab values zurban zurban
		lab values zlevel_hospital zlevel_hospital
		lab values zpub zpub
		lab values zc19cm zc19cm

	*****************************
	* Section 2: Staffing: new infections, vaccination, and training
	*****************************

	***** staff: total number and total number infected by occupation groups
	
		egen staff_num_total_md=rowtotal(q201_001_a)
		egen staff_num_covidwk_md=rowtotal(q201_001_b)
		
		egen staff_num_total_nr=rowtotal(q201_002_a)
		egen staff_num_covidwk_nr=rowtotal(q201_002_b)

		egen staff_num_total_othclinical=rowtotal(q201_003_a q201_004_a q201_005_a q201_006_a q201_007_a q201_008_a )
		egen staff_num_covidwk_othclinical=rowtotal(q201_003_b q201_004_b q201_005_b q201_006_b q201_007_b q201_008_b )
		
		egen staff_num_total_clinical=rowtotal(staff_num_total_md staff_num_total_nr staff_num_total_othclinical)
		egen staff_num_covidwk_clinical=rowtotal(staff_num_covidwk_md staff_num_covidwk_nr staff_num_covidwk_othclinical)
		
		egen staff_num_total_nonclinical=rowtotal( q201_009_a q201_010_a )
		egen staff_num_covidwk_nonclinical=rowtotal( q201_009_b q201_010_b )
		
		egen staff_num_total_all=rowtotal(staff_num_total_clinical staff_num_total_nonclinical) 
		egen staff_num_covidwk_all=rowtotal(staff_num_covidwk_clinical staff_num_covidwk_nonclinical) 
	
	***** staff: covax
	
		gen staff_num_covaxany  = q202
		gen staff_num_covaxfull = q203
		gen staff_num_covaxbooster = q204 /*NEW*/
	
	***** staff: absence 
	
		gen staff_num_absensce = q205 /*NEW*/	
		gen staff_num_absensce_covid = q206 /*NEW*/	
		gen xabsence=q205>=1 & q205!=. 
		gen xabsence_covid=	q206>=1 & q206!=. /*NEW*/ 
		/*once adjusted for the reference period, it is SIMILAR to previous "xabsence_medical"*/
	
	***** staff: training, supportive supervision, and mental health support 
	
		gen xtraining = q207==1 | q209==1
		global itemlist "001 002 003 004 005 006 007"
		foreach item in $itemlist{	
			gen byte xtraining__`item' = q208_`item' ==1 /*select subitems changed*/
			}		
		
		global itemlist "001 002"
		foreach item in $itemlist{	
			gen byte xsupport__`item' = q210_`item' ==1 /*select subitems changed*/ 
			}		
			
		gen xtraining__mental = q211==1
	
			local varlist xtraining__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')				
		gen xtraining_score	=100*(temp/max)
		gen xtraining_100 	=xtraining_score==100
		gen xtraining_50 	=xtraining_score>=50
			drop max temp
						
			local varlist xtraining__001 - xtraining__007 xsupport__* xtraining__mental /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')				
		gen xtrainingsupport_score	=100*(temp/max)
		gen xtrainingsupport_100	=xtrainingsupport_score==100
		gen xtrainingsupport_50 	=xtrainingsupport_score>=50
			drop max temp		

	sum staff* xabsence* xtraining* xsupport* 	
	
	/***** name sub-items *****/
		rename	xtraining__001	xtraining__ppe
		rename	xtraining__002	xtraining__ipccleaning /*NEW*/ 
		rename	xtraining__003	xtraining__ipcscreening	/*NEW*/ 	
		rename	xtraining__004	xtraining__ipchand /*NEW*/ 
		rename	xtraining__005	xtraining__triage	
		rename	xtraining__006	xtraining__emerg
		rename	xtraining__007	xtraining__remote

		rename	xsupport__001	xtraining__ss_ipc
		rename	xsupport__002	xtraining__ss_c19cm		
	
	*****************************
	* Section 3: Infection prevention and control
	*****************************
	
	***** IPC measures implemented
		gen xsafe= q301==1
		global itemlist "001 002 003 004 005 006 007"
		foreach item in $itemlist{	
			gen xsafe__`item' = q302_`item' ==1
			}		
						
			local varlist xsafe__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')	
		gen xsafe_score	=100*(temp/max)
		gen xsafe_100 	=xsafe_score==100
		gen xsafe_50 	=xsafe_score>=50
			drop max temp
	
	***** PPE and IPC items
		global itemlist "001 002 003 004 005"
		foreach item in $itemlist{	
			gen xppe_all__`item' = q304_`item'==1
			}						

			local varlist xppe_all__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			
		gen xppe_all_score	=100*(temp/max)
		gen xppe_all_100 		=xppe_all_score==100
		gen xppe_all_50 		=xppe_all_score>=50
			drop max temp
			
		global itemlist "001 002 003 004"	
		foreach item in $itemlist{	
			gen xipcitem__`item' = q305_`item'==1
			}						

			local varlist xipcitem__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			
		gen xipcitem_score	=100*(temp/max)
		gen xipcitem_100 		=xipcitem_score==100
		gen xipcitem_50 		=xipcitem_score>=50
			drop max temp	
		
	***** IPC guideliens 
		gen xguideline= q306
		global itemlist "001 002 003 004 005 006 007"
		foreach item in $itemlist{	
			gen xguideline__`item' = q307_`item' ==1
			}		
			
			local varlist xguideline__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			
		gen xguideline_score	=100*(temp/max)
		gen xguideline_100 		=xguideline_score==100
		gen xguideline_50 		=xguideline_score>=50
			drop max temp
			
	sum xsafe* xppe* xipc* xguideline*
	
	/***** name sub-items *****/
		rename	xsafe__001	xsafe__staff_entrance
		rename	xsafe__002	xsafe__entrance_screening			
		rename	xsafe__003	xsafe__screening_c19 /*NEW*/
		/* similar to previous xsafe__triage_c19, but not really...*/
		rename	xsafe__004	xsafe__distancing
		rename	xsafe__005	xsafe__hygiene_instructions
		rename	xsafe__006	xsafe__hygiene_stations
		rename	xsafe__007	xsafe__cleaning
							
		rename	xppe_all__001	xppe_all__mask
		rename	xppe_all__002	xppe_all__respirator
		rename	xppe_all__003	xppe_all__gloves
		rename	xppe_all__004	xppe_all__gown		
		rename	xppe_all__005	xppe_all__goggles
				
		rename	xipcitem__001	xipcitem__soap
		rename	xipcitem__002	xipcitem__sanitizer
		rename	xipcitem__003	xipcitem__biobag
		rename	xipcitem__004	xipcitem__boxes

		rename	xguideline__001	xguideline__screening
		rename	xguideline__002	xguideline__c19 /*NEW*/
		rename	xguideline__003	xguideline__ppe
		rename	xguideline__004	xguideline__masking /*NEW*/
		rename	xguideline__005	xguideline__c19_surveillance
		rename	xguideline__006	xguideline__envcleaning /*NEW*/
		rename	xguideline__007	xguideline__waste
		
	***** ADDITIONAL FROM "GLOBAL INDICATORS"

		*recalculate PPE with only masks, gloves, and respirators
		egen xxppe_total	= rowtotal(xppe_all__mask xppe_all__gloves xppe_all__respirator)
		gen xppe_essential_all_100	= xxppe_total==3
		gen xppe_essential_all_score= xxppe_total/3
			drop xxppe_total

		*recalculate PPE with only masks and gloves
		egen xxppe_total	 	= rowtotal(xppe_all__mask xppe_all__gloves)
		gen xppe_mask_glove_all_100 	= xxppe_total==2
		gen xppe_mask_glove_all_score	= xxppe_total/2
			drop xxppe_total		
		
		*recalculate IPC items without body bags
		egen xxipcitem_total	= rowtotal(xipcitem__soap xipcitem__sanitizer xipcitem__boxes xipcitem__biobag)
		gen xipcitem_nobodybag_100	= xxipcitem_total==4 /*same with xipcitem_100 in the combined version*/
		gen xipcitem_nobodybag_score= xxipcitem_total/4	 /*same with xipcitem_score in the combined version*/
			drop xxipcitem_total		
	
	*****************************
	* Section 4: Availability of services for COVID-19 case management
	*****************************	

	***** PT with suspected/confirmed C19 at primary care setting 
	
		gen xcvd_pt = q401==1 /*suspected or confirmed*/ 

		global itemlist "001 002 003 004 005 006 007"
		foreach item in $itemlist{	
			gen xcvd_pt__`item' 	= xcvd_pt==1 & q402_`item'==1 /* ALWAYS*/
			}	
		
			local varlist xcvd_pt__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			 
		gen xcvd_pt_score	=100*(temp/max)
		gen xcvd_pt_100 	=xcvd_pt_score==100
		gen xcvd_pt_50 		=xcvd_pt_score>=50
			drop max temp		
				
			foreach var of varlist xcvd_pt*{
				replace `var'=. if zc19cm==1 /*missing if C19CM facilities*/
				}
			foreach var of varlist xcvd_pt__* xcvd_pt_score xcvd_pt_100 xcvd_pt_50 {
				replace `var'=. if xcvd_pt==0 /*missing if no patients with suspected C19*/
				}
				
		* only among primary care facilities 
		
		rename	xcvd_pt__001	xcvd_pt__triage /*NEW*/
		rename	xcvd_pt__002	xcvd_pt__o2_measure
		rename	xcvd_pt__003	xcvd_pt__progmarker /*NEW*/
		rename	xcvd_pt__004	xcvd_pt__covax /*NEW*/
		rename	xcvd_pt__005	xcvd_pt__home_isolate
		rename	xcvd_pt__006	xcvd_pt__refer
		rename	xcvd_pt__007	xcvd_pt__antiviral				
		
	***** PT with suspected/confirmed C19 at hospitals /*NEW*/
	
		gen xcvd_optpt = q401==1 /*suspected and confirmed*/ 

		global itemlist "001 002 003 004 005"
		foreach item in $itemlist{	
			gen xcvd_optpt__`item' 	= xcvd_optpt==1 & q403_`item'==1 /* ALWAYS*/
			}	
			
			local varlist xcvd_optpt__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			 
		gen xcvd_optpt_score	=100*(temp/max)
		gen xcvd_optpt_100 		=xcvd_optpt_score==100
		gen xcvd_optpt_50 		=xcvd_optpt_score>=50
			drop max temp		
		
			foreach var of varlist xcvd_optpt*{
				replace `var'=. if zc19cm==0 /*missing if NON C19CM facilities*/
				}
			foreach var of varlist xcvd_optpt__* xcvd_optpt_score xcvd_optpt_100 xcvd_optpt_50 {
				replace `var'=. if xcvd_optpt==0 /*missing if no patients with suspected/confirmed C19*/
				}			
				
		* only among hospitals 
		rename	xcvd_optpt__001	xcvd_optpt__triage 
		rename	xcvd_optpt__002	xcvd_optpt__o2_measure
		rename	xcvd_optpt__003	xcvd_optpt__progmarker 
		rename	xcvd_optpt__004	xcvd_optpt__covax 
		rename	xcvd_optpt__005	xcvd_optpt__antiviral					
			
	***** PT with suspected/confirmed C19: ALL facilities, Primary or Hospitals /*NEW*/
		
		gen xopt_covid = xcvd_pt==1 | xcvd_optpt==1
			
		gen	xopt_covid__triage 	 	 =	xcvd_pt__triage 	 ==1 |	xcvd_optpt__triage 	 ==1  
		gen	xopt_covid__o2_measure	 =	xcvd_pt__o2_measure	 ==1 |	xcvd_optpt__o2_measure	 ==1  
		gen	xopt_covid__progmarker 	 =	xcvd_pt__progmarker  ==1 |	xcvd_optpt__progmarker  ==1  
		gen	xopt_covid__covax 		 =	xcvd_pt__covax 	 	 ==1 |	xcvd_optpt__covax 	 ==1  
		gen xopt_covid__antiviral	 =  xcvd_pt__antiviral 	 ==1 |  xcvd_optpt__antiviral==1 

			foreach var of varlist xopt_covid__* {
				replace `var'=. if xopt_covid==0 /*missing if no C19 OPT*/
				}		

	***** ER
	
		gen xer = q404==1 & q405==1 
		/*NOTE: can be stricter than previous xer, since two questions are used*/

		gen xer_triage = q406==1 /*NEW*/
		
			replace xer_triage=. if xer==0 /*missing if no ER*/
	
	***** IPT: general & COVID19		

		gen byte xipt= q407==1
		lab var xipt "facilities providing IPT services"
		
		gen ybed 			= q408
		gen ybed_icu 	 	= q409
			
		gen ybed_night   = q410
		gen ybed_icu_night   = q411 /*NEW*/
		
		gen xipt_surveillance = q412 /*NEW*/
			
		gen byte xipt_covid= q413==1 /*NEW*/
		lab var xipt_covid "facilities providing IPT services for C19 patients"
		
		gen ybed_covid_night   = q414
		
			foreach var of varlist xipt* ybed*{
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}
			foreach var of varlist ybed*{
				replace `var'=. if xipt==0 /*missing if no IPT*/
				}	
			foreach var of varlist ybed_covid_night {
				replace `var'=. if xipt_covid==0 /*missing if no IPT for C19 patients*/
				}					
		
	***** IPT: severe/critical C19 cases		
	
		gen xcvd_ptsevere = q415==1  /*NEW*/
		
		global itemlist "001 002 003 004 005"
		foreach item in $itemlist{	
			gen xcvd_ptsevere__`item' 	= xcvd_ptsevere==1 & q416_`item'==1 /* ALWAYS*/ /*NEW*/
			}	
						
			local varlist xcvd_ptsevere__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')			 			
		gen xcvd_ptsevere_score	=100*(temp/max)
		gen xcvd_ptsevere_100 	=xcvd_ptsevere_score==100
		gen xcvd_ptsevere_50 	=xcvd_ptsevere_score>=50
			drop max temp		
		
		gen xcvd_ptsevere_notable = q417==1 
		
		gen xcvd_ptsevere_repurpose	= q418_001==1 
		gen xcvd_ptsevere_refer		= q418_002==1 

			foreach var of varlist xcvd_ptsevere*{
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}
			foreach var of varlist xcvd_ptsevere_*{
				replace `var'=. if xcvd_ptsevere==0 /*missing if no patients with severe/critical C19*/
				}					
		
	/***** name sub-items *****/
		
		rename	xcvd_ptsevere__001	xcvd_ptsevere__oxygen /*NEW*/
		rename	xcvd_ptsevere__002	xcvd_ptsevere__intubation /*NEW*/
		rename	xcvd_ptsevere__003	xcvd_ptsevere__ventilation /*NEW*/
		rename	xcvd_ptsevere__004	xcvd_ptsevere__iv /*NEW*/
		rename	xcvd_ptsevere__005	xcvd_ptsevere__glucosetest /*NEW*/
	
	
	*****************************
	* Section 5: Delivery and utilization of essential health services
	*****************************
		
	***** strategy change  /*NEW - ALL in Q502*/
	
		gen xstever_reduce_reduce	= q501_001_a==1 | q501_002_a==1 | q501_003_a==1
		gen xstever_reduce_redirect	= q501_004_a==1
		gen xstever_reduce_priority	= q501_005_a==1
		gen xstever_reduce_combine	= q501_006_a==1
		
		gen xstever_self			= q501_007_a==1
		gen xstever_home			= q501_008_a==1
		gen xstever_remote			= q501_009_a==1 
		gen xstever_prescription	= q501_010_a==1 | q501_011_a==1 | q501_012_a==1 
	
		gen xstmonth_reduce_reduce	= q501_001_b==1 | q501_002_b==1 | q501_003_b==1
		gen xstmonth_reduce_redirect= q501_004_b==1
		gen xstmonth_reduce_priority= q501_005_b==1
		gen xstmonth_reduce_combine	= q501_006_b==1

		gen xstmonth_self			= q501_007_b==1
		gen xstmonth_home			= q501_008_b==1
		gen xstmonth_remote			= q501_009_b==1 
		gen xstmonth_prescription	= q501_010_b==1 | q501_011_b==1 | q501_012_b==1 	
			
		global itemlist	"reduce_reduce reduce_redirect reduce_priority reduce_combine self home remote prescription" 
		foreach item in $itemlist {
			*tab xstmonth_`item' xstever_`item', m
			replace xstmonth_`item'=. if xstever_`item'==0
			}

	***** OPT change
		gen xopt_lower 	= q502==1 | q502==2 /*NEW*/
		gen xopt_similar= q502==3  /*NEW*/
		gen xopt_higher	= q502==4 | q502==5 /*NEW*/

		global itemlist "011 012 021 022 023 024 025 026 031 032 033 034 035 036 037 038 039"
		*global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 013 014 015 016 017" 	
		foreach item in $itemlist{			
			gen xopt_lower_reason__`item' = q503_`item'
			}
		
		global itemlist "001 002 003 004 005 006 007 008" 	
		foreach item in $itemlist{	
			gen xopt_higher_reason__`item' = q504_`item'
			}

		global varlist "xopt_lower"
		foreach var in $varlist {
			gen `var'_reason_epi	 	= `var'==1 & (`var'_reason__011==1 | `var'_reason__012==1 ) /*NEW*/
			gen `var'_reason_comdemand  = `var'==1 & (`var'_reason__021==1 | `var'_reason__022==1  | `var'_reason__026==1  ) 
			gen `var'_reason_enviro 	= `var'==1 & (`var'_reason__023==1 | `var'_reason__024==1 )
			gen `var'_reason_cost	 	= `var'==1 & (`var'_reason__025==1 | `var'_reason__038==1 ) /*NEW*/
			gen `var'_reason_intention	= `var'==1 & (`var'_reason__031==1 | `var'_reason__032==1 | `var'_reason__033==1 | `var'_reason__034==1 )
			gen `var'_reason_disruption = `var'==1 & (`var'_reason__035==1 | `var'_reason__036==1 | `var'_reason__037==1 | `var'_reason__039==1 ) /*REVISED CODE: 37 & 39 added*/			
			}		
			
		global varlist "xopt_higher"
		foreach var in $varlist {
			gen `var'_reason_covidnow 	= `var'==1 & (`var'_reason__001==1 | `var'_reason__004==1  )
			gen `var'_reason_seasonal	= `var'==1 & (`var'_reason__002==1 ) /*NEW*/
			gen `var'_reason_gbv	    = `var'==1 & (`var'_reason__003==1 ) 
			gen `var'_reason_covidafter = `var'==1 & (`var'_reason__005==1 | `var'_reason__006==1 | `var'_reason__007==1 )
			/*NOTE: this is kept since comp data available, but prefer below two NEW indicators*/
			gen `var'_reason_catchup = `var'==1 & (`var'_reason__005==1 | `var'_reason__006==1 ) /*NEW*/
			gen `var'_reason_genpromo = `var'==1 & (`var'_reason__007==1 ) /*NEW*/
			
			}		
		
		foreach var of varlist xopt_lower_reason*{
			replace `var'=. if xopt_lower==0
			}
			
		foreach var of varlist xopt_higher_reason*{
			replace `var'=. if xopt_higher==0
			}			
			
			rename	xopt_lower_reason__011	xopt_lower_reason__less_ari
			rename	xopt_lower_reason__012	xopt_lower_reason__seasonal
			
			rename	xopt_lower_reason__021	xopt_lower_reason__changerecs
			rename	xopt_lower_reason__022	xopt_lower_reason__fear
			rename	xopt_lower_reason__023	xopt_lower_reason__lockdown
			rename	xopt_lower_reason__024	xopt_lower_reason__transport
			rename	xopt_lower_reason__025	xopt_lower_reason__costtrans /*NEW*/
			rename	xopt_lower_reason__026	xopt_lower_reason__othercom
			
			rename	xopt_lower_reason__031	xopt_lower_reason__servreduc
			rename	xopt_lower_reason__032	xopt_lower_reason__disrupt
			rename	xopt_lower_reason__033	xopt_lower_reason__hours
			rename	xopt_lower_reason__034	xopt_lower_reason__closure
			rename	xopt_lower_reason__035	xopt_lower_reason__drugs
			rename	xopt_lower_reason__036	xopt_lower_reason__staff
			rename	xopt_lower_reason__037	xopt_lower_reason__longwait	/*NEW*/
			rename	xopt_lower_reason__038	xopt_lower_reason__costserv	/*NEW*/
			rename	xopt_lower_reason__039	xopt_lower_reason__otherfac	

			rename	xopt_higher_reason__001	xopt_higher_reason__more_ari
			rename	xopt_higher_reason__002	xopt_higher_reason__seasonal /*NEW*/
			rename	xopt_higher_reason__003	xopt_higher_reason__gbv
			rename	xopt_higher_reason__004	xopt_higher_reason__redirect
			rename	xopt_higher_reason__005	xopt_higher_reason__backlog
			rename	xopt_higher_reason__006	xopt_higher_reason__react
			rename	xopt_higher_reason__007	xopt_higher_reason__comms
			rename	xopt_higher_reason__008	xopt_higher_reason__other			
				
	***** backlog /*ALL NEW*/
	
		global itemlist "001 002 003 004"
		foreach item in $itemlist{	
			gen xbacklogever__`item' = q505_`item'_a==1 
			replace xbacklogever__`item' = . if q505_`item'_a==3 
			}
		foreach item in $itemlist{	
			gen xbacklogmonth__`item' = q505_`item'_b==1 
			replace xbacklogmonth__`item' = . if q505_`item'_b==3
			}			
		
		global itemlist	"001 002 003 004" 
		foreach item in $itemlist {
			replace xbacklogmonth__`item'=. if xbacklogever__`item'==0
			}
			
		global itemlist "xbacklogever xbacklogmonth"	
		foreach item in $itemlist{	
			egen `item'_any=rowtotal(`item'__*) 	
			replace `item'_any = 1 if `item'_any>=2 & `item'_any!=.
			}	
		
		global itemlist "xbacklogever xbacklogmonth"
		foreach item in $itemlist{
			replace `item'_any=. if  `item'__001==. & ///
								`item'__002==. & ///
								`item'__003==. & ///
								`item'__004==. /*missing if N/A for all four services*/
			}		
		
			rename xbacklogever__001  xbacklogever__routine
			rename xbacklogever__002  xbacklogever__ncd
			rename xbacklogever__003  xbacklogever__infectiou
			rename xbacklogever__004  xbacklogever__elecsurg			

			rename xbacklogmonth__001  xbacklogmonth__routine
			rename xbacklogmonth__002  xbacklogmonth__ncd
			rename xbacklogmonth__003  xbacklogmonth__infectiou
			rename xbacklogmonth__004  xbacklogmonth__elecsurg
			
	***** community outreach
	
		gen xout = q506==1
		
		global itemlist "001 002 003 004 005"
		foreach item in $itemlist{	
			gen xout_decrease__`item' = q507_`item'==1 |  q507_`item'==2
			}

		egen temp=rowtotal(xout_decrease__*) 
		gen xout_decrease= temp>=1	
		drop temp
		
			foreach var of varlist xout_*{
				replace `var'=. if xout==0
				}
				
			rename	xout_decrease__001	xout_decrease__immun
			rename	xout_decrease__002	xout_decrease__malaria
			rename	xout_decrease__003	xout_decrease__ntd
			rename	xout_decrease__004	xout_decrease__cbc
			rename	xout_decrease__005	xout_decrease__home 				
		
	*****************************
	* Section 6: Medicines and supplies
	*****************************
	
	* QUESTION TO CHELSEA: 
	* should use use just "xdrug" for all mediciens or different prefixes like below?? 
	* trying to see what would be helpful for comparability
	* we can have both systems. see at the end of this section. pros and cons... 
				
		global itemlist "001 002 003 004 005 006 "
		foreach item in $itemlist{	
			gen xdrugc19__`item' = q601_`item' ==1 /*NEW? - TBD*/
			}			

		global itemlist "001 002 003 004 005 006 007 008 009 010 011 012 " 
		foreach item in $itemlist{	
			gen xdrughosp__`item' = q602_`item' ==1 /*NEW? - TBD*/
			}		
			
		global itemlist "001 002 003 004 005 006 007 008 009 " 
		foreach item in $itemlist{	
			gen xdrugehs__`item' = q603_`item' ==1 /*NEW? - TBD*/
			}		
			
		global itemlist "001 002 003"
		foreach item in $itemlist{	
			gen xsupphosp__`item' = q604_`item' ==1
			}
					
		global itemlist "drugc19 drughosp drugehs supphosp"
		foreach item in $itemlist{				
					
				local varlist x`item'__* /*indicators for the summary metrics*/ 
					preserve
					keep `varlist'
					d, short
					restore
				gen max=`r(k)'
				egen temp=rowtotal(`varlist')					
			gen x`item'_score	=100*(temp/max)
			gen x`item'_100 	=x`item'_score==100
			gen x`item'_50 		=x`item'_score>=50
				drop max temp
			}		
			
				foreach var of varlist xdrugc19* xdrughosp* xsupphosp*{
					replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
					}		
					
			rename	xdrugc19__001	xdrugc19__dexamethasone
			rename	xdrugc19__002	xdrugc19__molnupiravir /*NEW*/
			rename	xdrugc19__003	xdrugc19__baracitanib /*NEW*/
			rename	xdrugc19__004	xdrugc19__casirivimab /*NEW*/
			rename	xdrugc19__005	xdrugc19__tocilizumab /*NEW*/
			rename	xdrugc19__006	xdrugc19__heparin /*NOT new - more specific than "Heparin" but not really differen (DH 7/12/2022)*/
			
			rename	xdrughosp__001	xdrughosp__alcohol
			rename	xdrughosp__002	xdrughosp__chlorine
			rename	xdrughosp__003	xdrughosp__paracetamol
			rename	xdrughosp__004	xdrughosp__ampicillin
			rename	xdrughosp__005	xdrughosp__ceftriaxone
			rename	xdrughosp__006	xdrughosp__azithromycin
			rename	xdrughosp__007	xdrughosp__rocuronium  /*NOT new - fully comparable as both are covered by “ … other neuromuscular blocker (injectable)” (DH 7/12/2022)*/
			rename	xdrughosp__008	xdrughosp__morphine
			rename	xdrughosp__009	xdrughosp__haloperidol
			rename	xdrughosp__010	xdrughosp__epinephrine			
			rename	xdrughosp__011	xdrughosp__oxytocin			
			rename	xdrughosp__012	xdrughosp__oxygen	
			
			rename	xdrugehs__001	xdrugehs__salbutamol
			rename	xdrugehs__002	xdrugehs__metformin
			rename	xdrugehs__003	xdrugehs__hydrochlorothiazide
			rename	xdrugehs__004	xdrugehs__carbamazapine
			rename	xdrugehs__005	xdrugehs__amoxicillin_tabs		
			rename	xdrugehs__006	xdrugehs__magnesiumsulphate
			rename	xdrugehs__007	xdrugehs__artemether
			rename	xdrugehs__008	xdrugehs__efavirenz
			rename	xdrugehs__009	xdrugehs__isoniazid
					
			rename	xsupphosp__001	xsupphosp__ivsets
			rename	xsupphosp__002	xsupphosp__nasalcanulae
			rename	xsupphosp__003	xsupphosp__facemasks		
		
		* TBD: Create/Clone medicines and supply individual indicators that have prefixes same with old indicators?? 
		
		global itemlist "xdrugc19 xdrughosp xdrugehs"
		foreach item in $itemlist{				
			foreach var of varlist `item'__*{
				clonevar x`var' = `var'
			}		
		}
		
			foreach var of varlist xsupphosp__*{
				clonevar x`var' = `var'
			}		
			
			rename (xxdrugc19__*) (xdrug__*) 
			rename (xxdrughosp__*) (xdrug__*) 
			rename (xxdrugehs__*) (xdrug__*) 
			rename (xxsupphosp__*) (xsupply__*) 
			
	*****************************
	* Section 7 : Equipment for COVID-19 case management
	*****************************

	***** Equipment 
		
		global itemlist "001 002 003 004"
		foreach item in $itemlist{	
			gen xequip_anyfunction__`item' = q701_`item'==1 
			}			
			
			local varlist xequip_anyfunction__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xequip_anyfunction_score	=100*(temp/max)
		gen xequip_anyfunction_100		=xequip_anyfunction_score==100
		gen xequip_anyfunction_50		=xequip_anyfunction_score>=50
			drop max temp				

			rename	xequip_anyfunction__001	xequip_anyfunction__xray
			rename	xequip_anyfunction__002	xequip_anyfunction__oximeters
			rename	xequip_anyfunction__003	xequip_anyfunction__vicu
			rename	xequip_anyfunction__004	xequip_anyfunction__vnoninv			
		
			/*NOTE: depending on sample design, 			
			"xequip_anyfunction__xray" may be same with 
			"ximage_avfun__xray" AMONG HOSPITALS in old CEHS
			*/
		
	***** Oxygen
	
		gen xoxygen_concentrator= q702_001==1 
		gen xoxygen_bulk 		= q702_002==1 
		gen xoxygen_cylinder	= q702_003==1 
		gen xoxygen_plant 		= q702_004==1   
		
			egen temp=rowtotal(xoxygen_*)
		gen xoxygensource	=temp>=1
			drop temp
		
		gen xoxygen_dist 		 = q703==1
		gen xoxygen_portcylinder = q704==1
	
			foreach var of varlist xequip* xoxygen* {
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}			

	***** ADDITIONAL FROM "GLOBAL INDICATORS"
		
		*calculate cross tabs of having ventilator BY TYPE	
		gen xequip_novent_anyfunction		= xequip_anyfunction__vicu==0 & xequip_anyfunction__vnoninv==0
		gen xequip_bothvent_anyfunction		= xequip_anyfunction__vicu==1 & xequip_anyfunction__vnoninv==1
		gen xequip_onlyinvvent_anyfunction	= xequip_anyfunction__vicu==1 & xequip_anyfunction__vnoninv==0
		gen xequip_onlyninvvent_anyfunction	= xequip_anyfunction__vicu==0 & xequip_anyfunction__vnoninv==1
		gen xequip_eithervent_anyfunction	= xequip_anyfunction__vicu==1 | xequip_anyfunction__vnoninv==1

		*create index with EITHER ventilator plus oxygen and oximeters
			local varlist xoxygensource xequip_eithervent_anyfunction xequip_anyfunction__oximeters 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xequip_anyvent_oxy_oximtr_score	=100*(temp/max)
		gen xequip_anyvent_oxy_oximtr_100	=xequip_anyvent_oxy_oximtr_score==100
			drop max temp		
		
		*create index with BOTH ventilator plus oxygen and oximeters
			local varlist xoxygensource xequip_bothvent_anyfunction xequip_anyfunction__oximeters
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xequip_bothvent_oxy_oximtr_score=100*(temp/max)
		gen xequip_bothvent_oxy_oximtr_100	=xequip_bothvent_oxy_oximtr_score==100
			drop max temp	
			
			foreach var of varlist xequip* xoxygen* {
				replace `var'=. if zc19cm==0 /*missing if NOT C19CM facilities*/
				}	
				
	*****************************
	* Section 8 : Diagnostics
	*****************************

	***** COVID diagnostics 
	
		gen xspcm	= q801==1
		gen xrdt 	= q802==1	
		gen xpcr 	= q803==1 & q804==1 /*OR IS IT NEW? SHOULD WE GIVE A DIFFERENT NAME? - TBD*/ 
		gen xonsite	= xpcr==1 | xrdt==1
		
		gen xpcr_equip	= q805==1
		gen xpcr_supply	= q806==1 /*NEW*/ 
				
		foreach var of varlist xpcr_*	{
			replace `var'=. if xpcr==0 /*missing if no PCR*/
			}	

		/*NOTE: 
		Ah, we used different names for very similar indicators between CEHS and C19CM.
		Clone those vars to facilitate trend analysis, in case. 
		*/ 	
		clonevar xcvd_test_pcr = xrdt 
		clonevar xcvd_test_rdt = xpcr 

	***** EHS diagnostics 		

		global itemlist "001 002 003 004 005 006" 
		foreach item in $itemlist{	
			gen xdiag_av_a`item' 	= q807_`item'<=2 
			}	
		foreach item in $itemlist{	
			gen xdiag_avfun_a`item' = q807_`item'<=1
			}			
			
		global itemlist "001 002 003 004"
		foreach item in $itemlist{	
			gen xdiag_av_h`item' 	= q808_`item'<=2		
			}		
		foreach item in $itemlist{	
			gen xdiag_avfun_h`item' = q808_`item'<=1		
			}					
							
			local varlist xdiag_avfun_a* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')						
		gen xdiagbasic_score	=100*(temp/max)
		gen xdiagbasic_100 	=xdiagbasic_score==100
		gen xdiagbasic_50 	=xdiagbasic_score>=50
			drop max temp
			
			
			local varlist xdiag_avfun_a* xdiag_avfun_h* /*indicators for the summary metrics: for hospitals*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen maxhospital=`r(k)'
			egen temphospital=rowtotal(`varlist')	
			
			local varlist xdiag_avfun_a* /*indicators for the summary metrics: for non-hospitals*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen maxnonhospital=`r(k)'
			egen tempnonhospital=rowtotal(`varlist')	
			
			gen max=.
				replace max=maxnonhospital  if zlevel_hospital!=1 /*non-hospital*/
				replace max=maxhospital 	if zlevel_hospital==1 /*hospital*/
			gen temp=.
				replace temp=tempnonhospital if zlevel_hospital!=1 /*non-hospital*/
				replace temp=temphospital 	if zlevel_hospital==1 /*hospital*/
		gen xdiag_score	=100*(temp/max)
		gen xdiag_100 	=xdiag_score==100
		gen xdiag_50 	=xdiag_score>=50
			drop max* temp*
			
		foreach var of varlist xdiag_av_h* xdiag_avfun_h* {
			replace `var'=. if zlevel_hospital==0 /*missing if NOT hospital*/
			}				
			
			rename	xdiag_av_a001	xdiag_av__bloodglucose
			rename	xdiag_av_a002	xdiag_av__urineglucose
			rename	xdiag_av_a003	xdiag_av__urineprotein
			rename	xdiag_av_a004	xdiag_av__pregnancy
			rename	xdiag_av_a005	xdiag_av__hbg /*NEW - revised*/
			rename	xdiag_av_a006	xdiag_av__malaria
			
			rename	xdiag_av_h001	xdiag_av__h_hiv
			rename	xdiag_av_h002	xidag_av__h_tb
			rename	xdiag_av_h003	xdiag_av__h_bloodtype
			rename	xdiag_av_h004	xdiag_av__h_bloodcreatine
			
			rename	xdiag_avfun_a001	xdiag_avfun__bloodglucose
			rename	xdiag_avfun_a002	xdiag_avfun__urineglucose
			rename	xdiag_avfun_a003	xdiag_avfun__urineprotein
			rename	xdiag_avfun_a004	xdiag_avfun__pregnancy
			rename	xdiag_avfun_a005	xdiag_avfun__hbg /*NEW - revised*/
			rename	xdiag_avfun_a006	xdiag_avfun__malaria

			rename	xdiag_avfun_h001	xdiag_avfun__h_hiv
			rename	xdiag_avfun_h002	xidag_avfun__h_tb
			rename	xdiag_avfun_h003	xdiag_avfun__h_bloodtype
			rename	xdiag_avfun_h004	xdiag_avfun__h_bloodcreatine
			
	***** ADDITIONAL FROM "GLOBAL INDICATORS"
	
		*create cross-tabs of doing PCR, RDT, both, neither
		gen xcovid_diag_none		= xpcr==0 & xrdt==0
		gen xcovid_diag_pcr_only	= xpcr==1 & xrdt==0
		gen xcovid_diag_rdt_only	= xpcr==0 & xrdt==1
		gen xcovid_diag_pcr_and_rdt	= xpcr==1 & xrdt==1

		foreach var of varlist xcovid_diag_*	{
			replace `var'=. if xspcm==0 /*missing if no test at all*/
			}
			
		gen xcovid_diag_pcr_or_rdt	=xcovid_diag_none==0 /*this is same with above "xonsite" */
			
	*****************************
	* Section 9: Vaccination
	*****************************

	***** Childhood immunization 

		gen xvaccine_child=q901==1 
		gen xvac= q901==1 
		/*NOTE:
		Technically not same with previous "xvac", which included child AND adult vaccination. 
		But, practically, it will be close to identical - 
		since child vaccination is almost universally available - in low resource settings, at least. 
		*/
		
		gen xvac_av_fridge 			= q902==1 | q902==2
		gen xvac_avfun_fridge 		= q902==1 
		gen xvac_avfun_fridgetemp 	= q902==1 & q903==1

		global itemlist "001 002 003 004 005 006 007"
		foreach item in $itemlist{	
			gen xvaccine__`item' = q904_`item' ==1
			}	
		
			local varlist xvaccine__* /*indicators for the summary metrics*/ 
				preserve
				keep `varlist'
				d, short
				restore
			gen max=`r(k)'
			egen temp=rowtotal(`varlist')					
		gen xvac_score	=100*(temp/max)
		gen xvac_100 	=xvac_score==100
		gen xvac_50 	=xvac_score>=50
			drop max temp

		gen xvac_syrstockout = q905==1
		
			rename	xvaccine__001	xvaccine__mcv
			rename	xvaccine__002	xvaccine__dtp
			rename	xvaccine__003	xvaccine__polio_oral /*NEW*/
			rename	xvaccine__004	xvaccine__polio_inj /*NEW*/
			rename	xvaccine__005	xvaccine__bcg
			rename	xvaccine__006	xvaccine__pneumo
			rename	xvaccine__007	xvaccine__hpv /*NEW*/
		
		foreach var of varlist xvac_* xvaccine__*  {	
			replace `var'	=. if xvaccine_child!=1 /*missing if no child vaccine services*/
			}		

	***** COVAX
	
		gen xcovax = q906==1
		
		gen xcovax_av_fridge 			= q907==1 | q907==2 /*NEW*/
		gen xcovax_avfun_fridge 		= q907==1  /*NEW*/
		gen xcovax_avfun_fridgetemp 	= q907==1 & q908==1 /*NEW*/		
		
		*global itemlist "001 002 003 004 005 006 007"
		global itemlist "001 002 003 004 005"
		foreach item in $itemlist{	
			gen xcovax_offer__`item' = q909_`item'==1 | q909_`item'==2 
			gen xcovax_offerav__`item' = q909_`item'==1 
			}
			
		gen xcovax_report = q910==1 
		
		global itemlist "001 002 003 004"
		foreach item in $itemlist{	
			gen xcovax_train__`item' = q911_`item'==1
			}		
		
		gen xcovax_syrstockout	=q912==1 /*NEW*/ 

		foreach var of varlist xcovax_*{
			replace `var'=. if xcovax!=1 /*missing if no COVID-19 vaccine services*/
			}			
			
			rename	 xcovax_offer__001	xcovax_offer__pfizer
			rename	 xcovax_offerav__001	xcovax_offerav__pfizer
			rename	 xcovax_offer__002	xcovax_offer__moderna
			rename	 xcovax_offerav__002	xcovax_offerav__moderna
			rename	 xcovax_offer__003	xcovax_offer__astra
			rename	 xcovax_offerav__003	xcovax_offerav__astra
			rename	 xcovax_offer__004	xcovax_offer__jj
			rename	 xcovax_offerav__004	xcovax_offerav__jj
			rename	 xcovax_offer__005	xcovax_offer__covishiled
			rename	 xcovax_offerav__005	xcovax_offerav__covishiled
			/*
			rename	 xcovax_offer__006	xcovax_offer__sinopharm
			rename	 xcovax_offerav__006	xcovax_offerav__sinopharm	
			rename	 xcovax_offer__007	xcovax_offer__sinovac
			rename	 xcovax_offerav__007	xcovax_offerav__sinovac
			*/
			
			rename	 xcovax_train__001	xcovax_train__storage
			rename	 xcovax_train__002	xcovax_train__admin
			rename	 xcovax_train__003	xcovax_train__manage_adverse
			rename	 xcovax_train__004	xcovax_train__report_adverse			

	***** AEFI 
		
		gen xaefikit 		= q913==1 /*NEW - but this will be very similar to "xvac_aefikit"*/
		gen xaefireport 	= q914==1 /*NEW - but this will be very similar to "xvac_aefireport"*/	
		
		foreach var of varlist xaefi*{
			replace `var'=. if xvaccine_child==0 & xcovax==0 /*missing if no vaccine services*/
			}	
			
	***** ADDITIONAL FROM "GLOBAL INDICATORS"
	
		*Get information on COVAX
		egen numb_offer	 = rowtotal(xcovax_offer__*)
		gen xcovax_offer = numb_offer>=1
			drop numb_offer
			
		egen numb_avail	 = rowtotal(xcovax_offerav__*)
		gen xcovax_avail = numb_avail>=1
			drop numb_avail

		gen xcovax_offer_avail=1
			replace xcovax_offer_avail=0 if xcovax_offer==1 & xcovax_avail==0
			replace xcovax_offer_avail=. if xcovax_offer==0
			
		foreach var of varlist xcovax_avail xcovax_offer xcovax_offer_avail {
			replace `var'=. if xcovax!=1 /*missing if no COVID-19 vaccine services*/
			}			

	sort facilitycode
	save CombinedCOVID19HFA_`country'_R`round'.dta, replace 		
	
*****E.3. Merge with sampling weight 
***** MUST select/run Chunk A or B, depending on the sample design 
/*RUN this chunk A if there is samplingb weight*/
*CHUNK A BEGINS  

import excel "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Weight") firstrow clear
	rename *, lower

		sum weight
		*****CHECK HERE: 
		*		check if weight distribution is normalized with mean=1 
		*		if not, we have to rescale so that the mean of sampling weight==1

		replace weight=weight / r(mean) /*if already normalized, this line does not change anything*/
			
		sum weight
	
	sort facilitycode	
	merge facilitycode using CombinedCOVID19HFA_`country'_R`round'.dta, 
	
		tab _merge
		*****CHECK HERE: 
		*		all should be 3 (i.e., match) by the end of the data collection*/

		drop _merge*
		
	sort facilitycode /*this is generated from Lime survey*/
	save CombinedCOVID19HFA_`country'_R`round'.dta, replace 		
	
*CHUNK A ENDS

/*RUN this chunk B if there is NO samplingb weight
*CHUNK B BEGINS  	

	gen weight=1 

*CHUNK B BEGINS  
*/
	
*****E.4. Export clean facility-level data to chart book 
	
	save CombinedCOVID19HFA_`country'_R`round'.dta, replace 		

	export delimited using CombinedCOVID19HFA_`country'_R`round'.csv, replace 

	export excel using "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Facility-level cleaned data") sheetreplace firstrow(variables) nolabel
		
**************************************************************
* F. Create indicator estimate data 
**************************************************************

use CombinedCOVID19HFA_`country'_R`round'.dta, clear
	
	***** To get the total number of observations per relevant part 
	
	gen obs=1 	
	gen obs_c19cm=1 		if zc19cm==1
	
	gen obs_cvd_pt=1 		if xcvd_pt==1 		/*PRIMARY-level facilities that had seen patients with suspected/confirmed C19*/
	gen obs_opt_covid=1 	if xopt_covid==1 	/*facilities that provide OPT services for patients with suspected/confirmed C19*/
	gen obs_er=1 			if xer==1 			/*facilities that provide 24-hour staffed ER services*/
	gen obs_ipt=1 			if xipt==1			/*facilities that provide IPT services*/
	gen obs_ipt_covid=1 	if xipt_covid==1 	/*facilities that provide IPT services for patients with C19*/
	gen obs_ipt_cvdptsev=1 	if xcvd_ptsevere==1 /*facilities that provide services for patients with severe or critical C19*/

	gen obs_pcr=1 			if xpcr==1 			/*facilities that conduct PCR on site*/
	
	gen obs_vac=1 			if xvac==1
	gen obs_covax=1 		if xcovax==1	
	
	/*
	gen xresult=q1004==1
	tab xresult, m
	keep if xresult==1
	drop xresult	
	*/
	
	save temp.dta, replace 

*****F.1. Calculate estimates  

	use temp.dta, clear
	
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed* [iweight=weight], by(country round month year  )
		gen group="All"
		gen grouplabel="All"
		keep obs* country round month year  group* x*  y* staff_num_* 
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed* [iweight=weight], by(country round month year   zurban)
		gen group="Location"
		gen grouplabel=""
			replace grouplabel="Rural" if zurban==0
			replace grouplabel="Urban" if zurban==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta, force
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 

	use temp.dta, clear
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed* [iweight=weight], by(country round month year   zlevel_hospital)
		gen group="Level"
		gen grouplabel=""
			replace grouplabel="Non-hospital" if zlevel_hospital==0
			replace grouplabel="Hospital" if zlevel_hospital==1
		keep obs* country round month year group* x*  y* staff_num_* 
			
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 
		
	use temp.dta, clear
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed* [iweight=weight], by(country round month year   zpub)
		gen group="Sector"
		gen grouplabel=""
			replace grouplabel="Non-public" if zpub==0
			replace grouplabel="Public" if zpub==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta		
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 
		
	use temp.dta, clear	
	collapse (count) obs* (mean) x*  (sum) staff_num_* ybed* [iweight=weight], by(country round month year   zc19cm)
		gen group="C19CM eligibility"
		gen grouplabel=""
			replace grouplabel="non-C19CM (or CEHS) facilities" if zc19cm==0
			replace grouplabel="C19CM facilities" if zc19cm==1
		keep obs* country round month year  group* x*  y* staff_num_* 
		
		append using summary_CombinedCOVID19HFA_`country'_R`round'.dta		
		save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 		
		
	erase temp.dta	
			
	***** convert proportion to %		
	foreach var of varlist x*{
		replace `var'=round(`var'*100, 1)	
		}
			* But, convert back variables that were incorrectly converted (e.g., score)	
			foreach var of varlist *_score {
				replace `var'=round(`var'/100, 1)	
				}		

	***** generate staff infection rates using the pooled data	
	global itemlist "md nr othclinical clinical nonclinical all" 
	foreach item in $itemlist{	
		gen staff_pct_covidwk_`item' = round(100* (staff_num_covidwk_`item' / staff_num_total_`item' ), 0.1)
		}	
		
	***** generate COVID-19 vaccine among staff using the pooled data	
		gen staff_pct_covaxany  = round(100*staff_num_covaxany  / staff_num_total_all, 1)
		gen staff_pct_covaxfull = round(100*staff_num_covaxfull / staff_num_total_all, 1)
	
	tab group round, m
	
	***** round the number of observations, in case sampling weight was used
	foreach var of varlist obs*{
		replace `var' = round(`var', 1)
		}	

	***** organize order of the variables by section in the questionnaire  
	gen module = "Combined" /*module tag for appending all summary data later*/
	order module country round year month group grouplabel obs* staff*
		
	sort module country round year month group grouplabel
	
save summary_CombinedCOVID19HFA_`country'_R`round'.dta, replace 

export delimited using summary_CombinedCOVID19HFA_`country'_R`round'.csv, replace 

*****F.2. Export indicator estimate data to chartbook AND dashboard

use summary_CombinedCOVID19HFA_`country'_R`round'.dta, clear

	gen updatedate = "$date"

	local time=c(current_time)
	gen updatetime=""
	replace updatetime="`time'"

export excel using "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Indicator estimate data") sheetreplace firstrow(variables) nolabel keepcellfmt

/* To check against R results
export delimited using "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/3.AnalysisPlan/summary_CombinedCOVID19HFA_`country'_R`round'_Stata.csv", replace 
*/

**************************************************************
* G. MINIMUM data quality check 
**************************************************************

capture log close
log using DataCheck_CombinedCOVID19HFA_`country'_R`round'_$date.log, replace

*** Minimum red-flag indicators will be listed. So, the shorter log, the better.  

use summary_CombinedCOVID19HFA_`country'_R`round'.dta, clear	

	sort group grouplabel

*** 1. Estimates exceeding boundaries 
	/*
	Estimates for percent or score (0-100) that exceed boundaris.  
	For example, xdrug_100 MUST BE BETWEEN 0 and 100.  
	*/
			foreach var of varlist x* *_score staff_pct_*{
				list group grouplabel `var' if `var'<0 | (`var'>100 & `var'!=.)
			}			

*** 2. Comparing more vs. less restrictive indicators: all vs. half of the tracer items 
	/*
	Pairs where more restrictive indicator is higher than less restrictive indicator
	For example, xdrug_100 MUST BE ALWAYS EQUAL TO OR LOWER THAN xdrug_100
	*/
	
			*d *_100 /*NOTE: get the list of variables ending with _100 and adjust itemlist as needed */
			
			#delimit;
			global itemlist "
				xtraining xtrainingsupport 
				xsafe xppe_all xipcitem xguideline 
				xcvd_pt xcvd_optpt xcvd_ptsevere
				xdrugc19 xdrughosp xdrugehs xsupphosp 
				xequip_anyfunction xdiagbasic xdiag 
				xvac
				" ;
				#delimit cr
			foreach item in $itemlist{	
				list group grouplabel `item'_100 `item'_50  if `item'_100 > `item'_50
			}			   

*** 3. Comparing more vs. less restrictive indicators: more 
	/*
	Pairs where more restrictive indicator is higher than less restrictive indicator
	For example, xcovax_offerav__jj MUST BE ALWAYS EQUAL TO OR LOWER THAN xcovax_offer__jj
	*/
		
			list group grouplabel xdiagbasic_score xdiag_score  ///
				if xdiagbasic_score > xdiag_score  
				
			*global itemlist "pfizer moderna astra jj covishiled sinopharm sinovac"
			global itemlist "pfizer moderna astra jj covishiled"
			foreach item in $itemlist{	
				list group grouplabel xcovax_offerav__`item' xcovax_offer__`item' ///
					if xcovax_offerav__`item' > xcovax_offer__`item' 
			}	
	
log close

**************************************************************
* H. Append with previous "indicator estimate data" 
**************************************************************

/*

* This section is to facilitate trend analysis for select key indicators. 
* HQ WILL CREATE the "lavender" tab (i.e., "Indicator estimate data PAST") for each country. 
* This lavender tab includes key indicator estimates from all previous rounds. 
* Further, for indicators that are common in both C19CM and CEHS tools, HQ calculated the indicators using pulled facility-level data.
* THe "global" data are in the sharepoint folder, "1. Database"

	/*
	https://worldhealthorg-my.sharepoint.com/:f:/r/personal/banicag_who_int/Documents/HSA%20unit/4%20Databases,%20analyses%20%26%20dashboards/2%20HFAs%20for%20COVID-19/1%20Database?csf=1&web=1&e=Tqv9Ul
	*/
	
use "~/Dropbox/0 iSquared/iSquared_WHO/ACTA/5.Dashboard/1 Database/combined_new_elements.dta", clear
	keep if country=="Ghana" /*using Ghana as an example*/
	replace country = "`country'"

	*order module country round year month group grouplabel obs*
	order module country round year month group grouplabel 
			
	export excel using "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Indicator estimate data PAST") sheetreplace firstrow(variables) nolabel keepcellfmt

*/

import excel "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Indicator estimate data PAST") firstrow clear
	
	save temp.dta, replace
	
import excel "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("Indicator estimate data") firstrow clear
		
		d, short
		*local indicatorlist = "`r(varlist)'"
		*d `indicatorlist'
				
	append using temp.dta
		
		d, short
				
export excel using "$chartbookdir/WHO_CombinedCOVID19HFA_ChartbookTest.xlsx", sheet("All round data") sheetreplace firstrow(variables) nolabel keepcellfmt		

erase temp.dta
	
END OF DATA CLEANING AND MANAGEMENT 
