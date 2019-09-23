/*

wb_data_clean.do

Opens master_dataset_bk, merges in other necessary variables from other datasets,
	codes job titles into management ranks, etc.

1.	Fix Data Errors
	a.  Add observations for WBs who were previously missing from the dataset
	b.  Drop observations that should not be in the dataset
	c.  Fix observations with incorrect names
	d.  Individually fix observations where the WB appears twice because they worked for
			more than one defendent
	e.  Merge in the corrected Excel files with options update replace to correct all other
			variables 
2.	Clean
	a.	Match the column “wb_raised_internally” from the dataset “issue internal”
		to that database just to make sure that master_dataset_bk is really up to date.
	b.	Data on case outcomes can be found in “qtrack_foia_request” and settlement
		info in “settlement”. You should be able to match that information based on “caption”
	c.	Aggregate job titles into upper (C_Suite, President, VP, etc), middle
		(“manager” in title), and low (everyone else) management
	d.	Group WBs' jobs into functions for comparison later
		
*/

pause on

local wd: pwd // saves local of current working directory, C:\Users\[]
if substr("`wd'", 10, 2) == "lm" { // if on Lauren's computer
		include "C:/Users/lmostrom/Documents/GitHub/whistleblower_paper/assign_global_filepaths.do"
}
if substr("`wd'", 10, 2) == "dy" { // if on Dolly's computer
	include "C:/Users/dyu/Desktop/whistleblower_paper/assign_global_filepaths.do"
}

*-------------------------------------------------------------------------------------------
* Load in CSVs to be merged as Stata datasets
import delimited "$dropbox/spreadsheets_for_merge/employee_wbs_single_firm_combined.csv", varn(1) clear
	drop v35 // yeah we don't know either
	duplicates drop // ??
	*Fix observations entered twice
	drop if caption == "US ex rel Trice, Charles D; Carbaugh, David R v Westinghouse Elec Corp et al" & ///
		wb_full_name == "Carbaugh, David R." & job_title_at_fraud_firm == "Corporate Planner and Rate Analyst"
		replace gov = 1 if caption == "US ex rel Trice, Charles D; Carbaugh, David R v Westinghouse Elec Corp et al" & ///
			wb_full_name == "Carbaugh, David R."
	drop if caption == "US ex rel Brummell, Kelly Stephens; Ames, Judi v Valir Health Mgt Solutions Inc et al" & ///
		wb_full_name == "Brummell, Kelly Stephens" & legalcompliance == 0
	drop if caption == "US ex rel Airan, Ramesh; Gonzalez, Lazaro; State of FL v University of Miami Inc" & ///
		wb_full_name == "Airan, Ramesh" & reason_not_raised_internally == ""
	save "$dropbox/spreadsheets_for_merge/employee_wbs_single_firm_combined.dta", replace
import delimited "$dropbox/spreadsheets_for_merge/employee_wbs_two_firms_combined.csv", varn(1) clear
	save "$dropbox/spreadsheets_for_merge/employee_wbs_two_firms_combined.dta", replace
*-------------------------------------------------------------------------------------------
use "$dropbox/master_dataset_bk.dta", clear
	drop if case_id == . & caption == "" & wb_full_name == ""
	gen fyear = year(received_date)

	merge 1:m caption wb_full_name using "$dropbox/master_dataset_v3_gvkey.dta", nogen ///
		keep(1 3) keepus(match_score gvkey conm)
	
	* to merge m:1 with Compustat:
		gen indfmt = "INDL" if gvkey != .
		gen datafmt = "STD" if gvkey != .
		gen popsrc = "D" if gvkey != .
		gen consol = "C" if gvkey != .

preserve // --- Compustat Merge -----------------------------------------
	use "Dropbox/Compustat.dta", clear
	drop if fyear == .
	destring gvkey, replace
	tempfile comp_nomiss_fyear
	save `comp_nomiss_fyear', replace

	bys gvkey: egen max_year = max(fyear)
	keep if fyear == max_year
		isid gvkey  indfmt datafmt popsrc consol
	tempfile comp_latest_year
	save `comp_latest_year', replace
restore 

	merge m:1 gvkey fyear indfmt datafmt popsrc consol using `comp_nomiss_fyear', nogen keep(1 3) keepus(sic)
	merge m:1 gvkey indfmt datafmt popsrc consol using `comp_latest_year', nogen update keep(1 3 4) keepus(sic)
// ----------------------------------------------------------------------
	destring sic, replace

	drop public_firm
	gen public_firm = (gvkey != .)

	ren unclear unclear_edu
	ren Unclear unclear_outcome
	ren *, lower
	ren no_retaliation retaliation_none // so consistent with other similar variables
	gen retaliation_quit = quit

	duplicates drop
*=============================================================================================
*									First fix data errors
*(a) Add missing WBs
	expand 2 if caption == "US ex rel Barnes, Tony; Borggreen, Raymond; Riche, Roger v Akal Security Inc" & ///
				wb_full_name == "Barnes, Tony", gen(exp)
		replace wb_full_name = "Borggreen, Raymond" if exp == 1
		drop exp
	expand 2 if caption == "US ex rel Barnes, Tony; Borggreen, Raymond; Riche, Roger v Akal Security Inc" & ///
				wb_full_name == "Barnes, Tony", gen(exp)
		replace wb_full_name = "Richie, Roger" if exp == 1
		drop exp
	expand 2 if caption == "US ex rel Batiste, Than v Rehabilitation Services of Baton Rouge LLC et al" & ///
				wb_full_name == "Vincent, Terryl", gen(exp)
		replace wb_full_name = "Batiste, Than" if exp == 1
		drop exp
	expand 2 if caption == "US ex rel Bintzler, Doug; Jordan, Michael et al  v Board of Trustees O/T University of Cincinnati" & ///
				wb_full_name == "Jordan, Michael", gen(exp)
		replace wb_full_name = "Song, Yonggen" if exp == 1
		drop exp
	expand 2 if caption == "US ex rel Brackett, Carl v Heart Center of East Alabama" & ///
				wb_full_name == "Brackett, Carl", gen(exp)
		replace wb_full_name = "Martin, Dana" if exp == 1
		replace job_title_at_fraud_firm = "" if exp == 1 // have to manually replace because it's empty; won't merge update
		drop exp
	expand 2 if caption == "US ex rel Freel, Hugh E; Lucie, Eric R v Unidyne Corp" & ///
				wb_full_name == "Freel, Hugh E.", gen(exp)
		replace wb_full_name = "Lucie, Eric" if exp == 1
		drop exp
	expand 2 if caption == "US ex rel Mattiace, Dianne; Cortese, Victoria v Greenberg, Melo & Dennis et al" & ///
				wb_full_name == "Mattiace, Dianne", gen(exp)
		replace wb_full_name = "Cortese, Victoria" if exp == 1
		drop exp
	expand 2 if caption == "US; States of California et al ex rel Doe, John; Roe, Jane v Par Pharmaceutical Companies Inc et al" & ///
				wb_full_name == "Doe, John", gen(exp)
		replace wb_full_name = "Doe, Jane" if exp == 1
		drop exp 
	expand 2 if caption == "US; States of Florida et al ex rel Heinzen, Joel MD et al v Health Mgt Associates Inc et al" & ///
				wb_full_name == "Heinzen, M.D., Joel", gen(exp)
		replace wb_full_name = "Bingham, Thomas" if exp == 1
		drop exp 
	expand 2 if caption == "US; States of Florida et al ex rel Heinzen, Joel MD et al v Health Mgt Associates Inc et al" & ///
				wb_full_name == "Heinzen, M.D., Joel", gen(exp)
		replace wb_full_name = "Rhead, M.D. Christopher" if exp == 1
		drop exp
	expand 2 if caption == "US; State of Texas ex rel Foerster, Lisa et al v Molina Healthcare Inc et al" ///
				& wb_full_name == "Munoz, Tamara", gen(exp)
		replace wb_full_name = "Reyna, Catherine" if exp == 1
		drop exp 
    expand 2 if caption == "US ex rel Cornett, Jack; Koral, Lawrence F v Crow Creek Tribal School; Duwayne et al", gen(exp)
    	replace wb_full_name = "Koral, Lawrence F." if exp == 1
    	drop exp
    expand 2 if caption == "US ex rel Fields, Faye; Craft, Ann v Sherman Health Systems; Health Visions Inc etal", gen(exp)
    	replace wb_full_name = "Craft, Ann" if exp == 1
    	drop exp
    expand 2 if caption == "US ex rel Kaczmarczyk, Darryl L; Pate, Michelle M et al v SCCI Health Service Corp D/B/A SCCI et al", gen(exp)
    	replace wb_full_name = "Pate, Michelle M." if exp == 1
    	drop exp
    expand 2 if caption == "US ex rel Kaczmarczyk, Darryl L; Pate, Michelle M et al v SCCI Health Service Corp D/B/A SCCI et al" & ///
    		wb_full_name == "Pate, Michelle M.", gen(exp)
    	replace wb_full_name = "Taylor, Theresa" if exp == 1
    	drop exp
	expand 2 if caption == "US ex rel Longville, Patricia; McCormick, Moses v Cnty of Summit; Cnty of Summit Bd of Mental et al" & ///
				wb_full_name == "Mccormick, Moses", gen(exp)
		replace wb_full_name = "Longville, Patricia" if exp == 1
		drop exp


*(b) Drop observations with missing case documents or nonsensical WBs 
*		(usually a combination of one WB's first name and another's last name)
	drop if wb_full_name == "Elaine; Boone" & ///
		caption == "US ex rel Bennett, Elaine; Boone, Donald P v Boston Scientific Corp F/K/A Guidant Corp"
	drop if wb_full_name == "Rockhill Pain Specialists, P.A." & ///
		caption == "US ex rel Hancock, Dan L et al v St Joseph Medical Center; SJ Pain Associates Inc et al"
	drop if wb_full_name == "Leflore, Stephan" & ///
		caption == "US; States of California, Delaware et al ex rel LeFlore, Stephani v CVS Caremark Corp"
	drop if wb_full_name == "Mcfadden, Renee" & ///
		caption == "US; State of Illinois ex rel Upton, Gloria et al v Family Health Network Inc; Bradley, Philip et al" 
	drop if wb_full_name == "Steele, Barbara" & ///
		caption == "US; State of Illinois ex rel Upton, Gloria et al v Family Health Network Inc; Bradley, Philip et al"
	drop if wb_full_name == "Tricia Nowak" & caption == "US ex rel Dodd, Enda v Medtronic Inc"
	drop if wb_full_name == "Thompson, Craig" & ///
		caption == "US ex rel Thompson, Craig MD v Lifepointhospitals Inc; Aswell, Charles Dr"
	drop if wb_full_name == "Peter Duprey" & conm == "HALLIBURTON CO" & ///
		caption == "US ex rel Duprey, Peter v Halliburton Inc; KBR Inc" // wholly owned subsidiary, didn't actually work for them
	drop if wb_full_name == "Carbaugh, David R." & conm == "" & ///
		caption == "US ex rel Trice, Charles D; Carbaugh, David R v Westinghouse Elec Corp et al"

*(c) Fix incorrect names and captions so the corrected excel files can be merged in on caption and wb_full_name
	
	*Caption names
	replace caption = "US ex rel Dilback, Harold v General Electric Co" if case_id == 351 & wb_full_name == "Lefan, Dennis"
	replace caption = "US ex rel Rose, Sean; Aquino, Mary et al v Stephens Institute" if case_id == 5047

	*WB names
	replace wb_full_name = "Dilback, Harold" if caption == "US ex rel Dilback, Harold v General Electric Co"
	replace wb_full_name = "Liter, Robert A." ///
		if caption == "US; States of Arkansas; California; Connecticut; Delaware et al ex rel Liter, Robert A v Abbott Labs"
	replace wb_full_name = "Justice, Alicia" if caption == "US; States of California; Delaware et al ex rel Justice, Alicia et al v Salix Pharmaceuticals Inc" & wb_full_name == "Alicia Justice" 
	replace wb_full_name = "Nunnally, James Dent" if caption == "US; Nunnally, Dent T v West Calcasieu Cameron Hospital"
	replace wb_full_name = "DeFatta, Mark" if caption == "US; DeFatta, Mark v United Parcel Service Inc; United Parcel Service Inc Ohio et al"
	replace wb_full_name = "Stafford-Payne, Kimberly" if caption == "US; Commonwealth of Virginia ex rel Johnson, Megan L et al v Universal Health Services Inc et al" & wb_full_name == "Kimberly Stafford-Payne, Ma"
	replace wb_full_name = "Woodward, Debbie" if caption == "US ex rel Woodward, Debbie v Danville Services of Utah LLC"
	replace wb_full_name = "Wilson, Geoffrey K." if caption == "US ex rel Willson, Geoffrey K v Alcatel-Lucent; Alcatel-Lucent USA Inc et al"
	replace wb_full_name = "Staton, Beth Anne" if caption == "US ex rel Staton, Robert & Beth Anne; McMurray, Mary Ellen v Southern Patient Care et al" & job_title_at_fraud_firm == "Marketing"
	replace wb_full_name = "Seymour, Debra" if caption == "US ex rel Seymour, Debra v Health Care Group Inc D/B/A Mount Royal Towers"
	replace wb_full_name = "Schweizer, Stephanie" if caption == "US ex rel Schweizer, Stephanie v Oce NV; Oce North America; Oce Imagistics et al"
	replace caption = "US ex rel Richardson, Daniel C v Bristol-Myers Squibb" if case_id == 603 & wb_full_name == "Richardson, Daniel C."
	replace wb_full_name = "Lewis, London" if caption == "US ex rel Paradies, Debora; Lewis, London; Manley, Roberta v AseraCare Inc et al" & job_title_at_fraud_firm == "Registered Nurse"
	replace wb_full_name = "Friddle,Comfort" if caption == "US ex rel Friddle, Comfort; Kennedy, Stephanie v Taylor, Bean & Whitaker Mortgage Corp et al" & job_title_at_fraud_firm == "Loan Processor"
	replace wb_full_name = "Landau, Barbara Jo" if caption == "US ex rel Roberts, Joyce; Nyetrae, Shirley; Landau, Barbara Jo; Buie, James v KRG Capital LLC et al" & wb_full_name == "Barbara Jo, Buie"
	replace wb_full_name = "Bruno, Karen" if caption == "US ex rel Bergin, Joanne; Bruno, Karen; Lee, Kenneth J v Ocean Health Initiatives Inc" & wb_full_name == "Karen Bruno"
	replace wb_full_name = "Cassaday, Frank M." if caption == "US ex rel Cassaday, Frank M v KBR Inc; Kellogg Brown & Root Services Inc et al" & case_id == 4277
	replace wb_full_name = "Coss, Beverly" if caption == "US ex rel Coss, Beverly v Northrop Grumman Inc" & case_id == 661
	replace wb_full_name = "Davis, Kathleen Kurtz" if caption == "US ex rel Davis, Kathleen Kurtz v Cape Cod Hosp" & case_id == 4384
	replace wb_full_name = "Gemtilello, Larry M. M.D." if caption == "US ex rel Gentilello, Larry M MD v University of Texas Southwestern Health Systems et al" & case_id == 4337
	replace wb_full_name = "Sun, Linnette" if caption == "US; States of Arkansas et al ex rel Sun, Linnette et al v Baxter Hemoglobin Therapeutics et al" & wb_full_name == "Linnette, Sun"
	replace wb_full_name = "Lammers, Bonnie" if wb_full_name == "Lamers, Bonnie" 



*(d) Fix observations where WB worked for more than one company
	replace internal = 0 if wb_full_name == "Mateski, Steven" & conm == "NORTHROP GRUMMAN CORP" & ///
		caption == "US ex rel Mateski, Steven v Raytheon Co; Northrop Grumman Corp"
	replace internal = 0 if wb_full_name == "Masters, Thomas R." & conm == "METROPOLITN MTG & SEC  -CL A" & ///
		caption == "US ex rel Masters, Thomas R v Sandifur, Cantwell Paul Jr; Metropolitan Mortgage & Securities Co Inc"
	replace internal = 0 if wb_full_name == "Kane, Tracy" & job_title == "" & ///
		caption == "US ex rel Kane, Tracy v Coastal Intnl Security Inc; CT Corp System"
	replace job_title_at_fraud_firm = "" if wb_full_name == "Masters, Thomas R." & conm == "METROPOLITN MTG & SEC  -CL A" & ///
		caption == "US ex rel Masters, Thomas R v Sandifur, Cantwell Paul Jr; Metropolitan Mortgage & Securities Co Inc"

*(e) Merge with update replace options to correct all other variables (reported internaly, response, retaliation, etc.)

	merge m:1 caption wb_full_name using "$dropbox/spreadsheets_for_merge/employee_wbs_single_firm_combined.dta", ///
			update replace keep(1 3 4 5)

	merge m:1 caption wb_full_name conm using "$dropbox/spreadsheets_for_merge/employee_wbs_two_firms_combined.dta", ///
			update replace gen(merge_conm)

	drop response_dismissal_or_retaliatio
	ren response_suspension retaliation_suspension
	replace job_title_at_fraud_firm = "" if internal == 0
	replace wb_full_name = "Morris, Lanis G" if wb_full_name == "Randy L, Morris" & ///
		caption == "US ex rel Little, Randy L; Morris, Lanis G v Eni Petroleum Co Inc; F/K/A Agip Petroleum Co et al"

	foreach var of varlist auditor billing colleague direct_supervisor gov hotline hr ///
							legalcompliance relevantdirector topmanager response_* retaliation_* {
		replace `var' = 1 if `var' > 0 // some marked how many times channel used; just want whether it was
		replace `var' = 0 if `var' == .
	}

	replace wb_raised_issue_internally = "NO" if inlist(wb_raised_issue_internally, ".", "", "NO ")
		replace gov = 1 if wb_raised_issue_internally == "Went to state regulator, her dad got punished"
			replace wb_raised_issue_internally = "NO" if wb_raised_issue_internally == "Went to state regulator, her dad got punished"
			replace wb_raised_issue_internally = "" if wb_raised_issue_internally == "Incomplete court files"
			replace wb_raised_issue_internally = "YES" if wb_raised_issue_internally == "YES-implicitly"

	replace reason_not_raised_internally = "no information" if (reason_not_raised_internally == "" | reason_not_raised_internally == "Added observation")
	replace reason_not_raised_internally = "resisted demands" if strpos(lower(reason_not_raised_internally), "resisted de") > 0

	include "$repo/code_missing_internal.do"

*=============================================================================================
	lab def genders 1 "Male" 0 "Female"
		lab val male genders
	replace internal = 1 if internal == . & wb_description_external == "Internal"

	replace internal = 1 if internal == . & wb_raised_issue_internally == "YES"
	*assert wb_raised_issue_internally != "YES" if internal == 0
	replace wb_raised_issue_internally = "NO" if internal == 0 & wb_raised_issue_internally == ""
	
	replace job_title_at_fraud_firm = job_title_at_fraud_firm + "; Government Program Auditor" ///
		if case_id == 2586 & wb_full_name == "Parikh, Girish"

merge m:1 caption using "$dropbox/total_settlements_from_qtrack.dta", nogen keepus(total_federal_recovery settlement_judgment_date) keep(1 3)
	ren total_federal_recovery settlement
	gen settled = settlement != . & settlement > 0
	replace settlement = settlement/1000000
		lab var settlement "Settlement ($ Millions)"


drop if internal == 0 & wb_raised_issue_internally == "YES"
append using "$dropbox/raised_yes_employee_no.dta"
	drop mgmt_class wb_type wb_age_bin // already exist in raised_yes_employee_no.dta

egen non_audit_reports = rowtotal(billing colleague direct_supervisor hotline hr legalcompliance relevantdirector topmanager)
replace int_auditor = auditor if auditor > 0 & wb_raised_issue_internally == "YES" ///
	& non_audit_reports == 0 & int_auditor == .
/* Initially ambiguous internal/external audit cases: 2586, 674*/
replace int_auditor = auditor if wb_raised_issue_internally == "YES" ///
	& non_audit_reports > 0 & inlist(case_id, 2586, 674) & int_auditor
drop non_audit_reports
replace ext_auditor = auditor if wb_raised_issue_internally == "NO" & ext_auditor == .
replace int_auditor = 0 if int_auditor == .
replace ext_auditor = 0 if ext_auditor == .
/* Case file missing; can't check internal or external auditor */
drop if caption == "US ex rel Tompkins, Jimmy M v Adham, Abdullah N; Lamarre, Louise; Olusola, Benedict O et al"
gen ext_to_courts = (ext_auditor == 0 & gov == 0)

*management classification
#delimit ;
gen mgmt_class = "Upper" if strpos(lower(job_title_at_fraud_firm), "ceo") > 0 |
							strpos(lower(job_title_at_fraud_firm), "cfo") > 0 |
							(strpos(lower(job_title_at_fraud_firm), "chief") > 0 &
								strpos(lower(job_title_at_fraud_firm), "officer") > 0) |
							strpos(lower(job_title_at_fraud_firm), "president") > 0 |
							strpos(lower(job_title_at_fraud_firm), "vp") > 0 |
							strpos(lower(job_title_at_fraud_firm), "board member") > 0;
replace mgmt_class = "Middle" if (strpos(lower(job_title_at_fraud_firm), "manager") > 0 |
							strpos(lower(job_title_at_fraud_firm), "director") > 0 |
							strpos(lower(job_title_at_fraud_firm), "supervisor") > 0 |
							strpos(lower(job_title_at_fraud_firm), "dean") > 0)
							& mgmt_class == "";
replace mgmt_class = "Lower" if mgmt_class == "" & internal == 1 & job_title != "";
replace mgmt_class = "No Job Title" if mgmt_class == "" & internal == 1;

/* Just to verify what job titles appear in each;
tab job_title if mgmt_class == "Upper";
tab job_title if mgmt_class == "Middle";
tab job_title if mgmt_class == "Lower";
*/
#delimit ;
*correct job functions of investigator
	replace wb_description_external = "Government Investigator" if case_id == 5603;
	replace wb_description_external = "Unspecified/Miscellaneous" if case_id == 500 & wb_full_name == "Roberts, Neal";
	replace wb_description_external = "Private Investigator" if case_id == 5624 & wb_full_name == "Dunlap, William";
	replace wb_description_external = "Federal Employee" if case_id == 749 & wb_full_name == "Oberg, Jon H.";
	replace wb_description_external = "Bankruptcy Trustee" if case_id == 537 & wb_full_name == "Koch, Dr. Ludwig";
	replace wb_description_external = "Government Senior Investigator" if case_id == 701;
	replace wb_description_external = "Private Investigator" if case_id == 551 & wb_full_name == "Burns, John";
	replace wb_description_external = "Private Investigator" if case_id == 288 & wb_full_name == "Fairbrother, Faith";
	replace wb_description_external = "Unspecified/Miscellaneous" if case_id == 595 & wb_full_name == "Crennen, Christopher";
	replace wb_description_external = "Unspecified" if case_id == 151 & wb_full_name == "Brian, Danielle";
	replace wb_description_external = "Unspecified" if case_id == 151 & wb_full_name == "Brock, Leonard";


gen wb_type = "(Former) Employee" if internal == 1;
replace wb_type = "External Auditor" if (strpos(lower(wb_description_external), "auditor") > 0 | ext_auditor == 1) & internal == 0;
replace wb_type = "Customer/Client" if (inlist(wb_description_external, "Customer", "Consumer")
								| strpos(lower(wb_description_external), "patient") > 0
								| strpos(lower(wb_description_external), "client") > 0)
								& internal == 0;
replace wb_type = "Business Partner" if inlist(wb_description_external, "Business Partner",
						"Business Partnership", "Business Relationship",
						"Ceo Of A Company That Went Into Various Business Agreements With Defendant")
								& internal == 0;
replace wb_type = "Competing Firm" if strpos(lower(wb_description_external), "competi") > 0
								& internal == 0;
replace wb_type = "Consultant" if strpos(lower(wb_description_external), "consultant") > 0
								& internal == 0;
replace wb_type = "Contractor" if strpos(lower(wb_description_external), "contract") > 0
								& internal == 0;
replace wb_type = "Government Employee" if (inlist(wb_description_external, "Employed With Fbi", "Usda Worker", "Federal Employee")
								| strpos(lower(wb_description_external), "government") > 0)
								& internal == 0;
replace wb_type = "Private Investigator" if (strpos(lower(wb_description_external), "private investigator") > 0
								| strpos(lower(wb_description_external), "investegator") > 0)
								& internal == 0;
replace wb_type = "Stockholder" if wb_description_external == "Stockholder";
replace wb_type = "Lawyer/Law Firm" if (strpos(lower(wb_description_external), "attorney") > 0
								| strpos(lower(wb_description_external), "law firm") > 0)
								& internal == 0;
replace wb_type = "Supplier" if wb_description_external == "Supplier";
replace wb_type = "Tenant" if wb_description_external == "Tenant";
replace wb_type = "Unspecified/Miscellaneous" if wb_type == "";
#delimit cr								

*-------------------------------------------
gen wb_age_bin = int(wb_age/10)*10
	lab def age_bins 10 "18-19" 20 "20-29" 30 "30-39" 40 "40-49" ///
						50 "50-59" 60 "60-69" 70 "70-79", replace
	lab val wb_age_bin age_bins
*-------------------------------------------

*zero real change for this one, think have already change case_id to 512
*replace case_id = 512 if case_id == 3498 ///
*	& caption == "US ex rel Teodoro, Mercedes & Tommy v Neocare Health Systems Inc F/K/A Neocare Healthcare et al"
	
include "$repo/job_titles_to_functions.do"

replace wb_function = "Legal/Compliance" if inlist(wb_function, "Auditor", "Quality Assurance")
replace wb_function = "Finance/Accounting" if wb_function == "Billing"
replace wb_function = "Operations" if inlist(wb_function, "Administrator", "HR", "IT", ///
							"Marketing", "Sales", "Consultant", "Health Professional")
replace wb_function = "No Job Title" if wb_function == "" & job_title == ""
assert wb_function != "" if internal == 1

drop response_dismissal_or_retaliatio response_suspension

*Making sure people who accused multiple firms within the same lawsuit are only in there once
duplicates tag caption wb_full_name, gen(dup)
	tab dup internal
	drop if dup == 1 & internal == 0
	drop dup
duplicates tag caption wb_full_name, gen(dup)
	tab dup internal
	drop if dup == 1 & fyear == .
	drop dup
duplicates tag caption wb_full_name, gen(dup)
	tab dup internal
	drop if dup == 1 & conm == ""
	drop dup

replace ext_auditor = 0 if ext_auditor == 1 & gov == 1 & internal == 1 // contacted DMH (gov) first

replace fyear = year(received_date) if fyear == .


*Naming raised internally consistently
replace wb_raised_issue_internally = "NO" if inlist(wb_raised_issue_internally, ".", "", "NO ", " ") // just one more time for good measure??

*Reporting channels, responses, and retaliations
	egen n_reports = rowtotal(auditor billing colleague direct_supervisor gov hotline hr ///
								legalcompliance relevantdirector topmanager)

	egen n_responses = rowtotal(response_coverup response_ignored response_int_inv)
		replace n_responses = 0 if n_responses == .
		replace response_unknown = 1 if n_responses == 0 & wb_raised_issue_internally == "YES"
		replace response_coverup = 0 if response_int_inv == 1
		replace response_ignored = 0 if response_int_inv == 1 | response_coverup == 1
		drop n_responses
		egen n_responses = rowtotal(response_coverup response_ignored response_int_inv response_unknown)
			assert n_responses == 1 if wb_raised_issue_internally == "YES"

	egen n_retaliations = rowtotal(retaliation_demotion retaliation_fired retaliation_harassed retaliation_lawsuit retaliation_threat retaliation_suspension)
		replace n_retaliations = 0 if n_retaliations == .
		replace n_retaliations = 3 if n_retaliations >= 3
		replace retaliation_none = 1 if n_retaliations == 0 & wb_raised_issue_internally == "YES"

#delimit ;
replace reason_not_raised_internally = "No Information" if inlist(reason_not_raised, "Added observation",
												"Added observation ", "", "no information");
replace reason_not_raised_internally = "Fear of Retaliation" if strpos(lower(reason_not_raised), "fear of ")
												| inlist(reason_not_raised, "Criticized by supervisor", "resisted demands",
													"hostile work environment", "colleague's complaint was ignored");
replace reason_not_raised_internally = "Supervisors Involved in Misconduct" if inlist(reason_not_raised,
												"claims they already knew", "fraud was widespread company policy",
												"superiors already knew", "Direct supervisor is defendant",
												"conducted informal audit");
replace reason_not_raised_internally = "External Parties Already Knew" if inlist(reason_not_raised, "talked to press",
												"OIG investigate before WB", "Support the other relator");
replace reason_not_raised_internally = "" if internal != 1 | wb_raised_issue_internally == "YES";
#delimit cr
fre wb_raised_issue_internally
fre reason_not_raised


/*Silenced because only need to do it sometimes
preserve
	keep if gvkey != . & internal == 1
	save "$dropbox/wb_cases_public.dta", replace
restore
*/

merge 1:1 caption wb_full_name using "$dropbox/wb_public_ma", nogen keepus(at roacurrent lev aqc) keep(1 3)