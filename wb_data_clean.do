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

include "Documents/GitHub/whistleblower_paper/assign_global_filepaths.do"

use master_dataset_bk, clear
	drop if case_id == . & caption == "" & wb_full_name == ""
	
	merge 1:m caption wb_full_name using "master_dataset_v3_gvkey.dta", nogen ///
		keep(1 3) keepus(match_score gvkey conm)
	replace public_firm = 1 if public_firm == . & gvkey != .

=============================================================================================
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
	expand 2 if caption == "US ex rel Longville, Patricia; McCormick, Moses v Cnty of Summit; Cnty of Summit Bd of Mental et al" & ///
				wb_full_name == "Mccormick, Moses", gen(exp)
		replace wb_full_name == "Longville, Patricia" if exp == 1
		drop exp

*(b) Drop observations with missing case documents or nonsensical WBs 
*		(usually a combination of one WB's first name and another's last name)
	drop if wb_full_name == "Elaine; Boone" & ///
		caption == "US ex rel Bennett, Elaine; Boone, Donald P v Boston Scientific Corp F/K/A Guidant Corp"
	drop if wb_full_name == "Rockhill Pain Specialists, P.A." & ///
		caption == "US ex rel Hancock, Dan L et al v St Joseph Medical Center; SJ Pain Associates Inc et al"
	drop if wb_full_name == "Thompson, Craig" & ///
		caption == "US ex rel Thompson, Craig MD v Lifepointhospitals Inc; Aswell, Charles Dr"

*(c) Fix incorrect names and captions so the corrected excel files can be merged in on caption and wb_full_name
	replace caption = "US ex rel Dilback, Harold v General Electric Co" if case_id == 351 & wb_full_name == "Lefan, Dennis"
		replace wb_full_name = "Dilback, Harold" if caption == "US ex rel Dilback, Harold v General Electric Co"

*(d) Fix observations where WB worked for more than one company
	replace internal = 0 if wb_full_name == Mateski, Steven" & conm == "NORTHROP GRUMMAN CORP" & ///
		caption == "US ex rel Mateski, Steven v Raytheon Co; Northrop Grumman Corp"
	replace internal = 0 if wb_full_name == "Masters, Thomas R." & conm == "METROPOLITN MTG & SEC  -CL A" & ///
		caption == "US ex rel Masters, Thomas R v Sandifur, Cantwell Paul Jr; Metropolitan Mortgage & Securities Co Inc"
	replace job_title_at_fraud_firm = "" if wb_full_name == "Masters, Thomas R." & conm == "METROPOLITN MTG & SEC  -CL A" & ///
		caption == "US ex rel Masters, Thomas R v Sandifur, Cantwell Paul Jr; Metropolitan Mortgage & Securities Co Inc"

*(e) Merge with update replace options to correct all other variables (reported internaly, response, retaliation, etc.)


	foreach var of varlist auditor billing colleague direct_supervisor gov hotline hr ///
							legalcompliance relevantdirector topmanager response_* retaliation_* {
		replace `var' = 1 if `var' > 0 // some marked how many times channel used; just want whether it was
	}

=============================================================================================
	ren unclear unclear_edu
	ren Unclear unclear_outcome
	ren *, lower
	ren no_retaliation retaliation_none // so consistent with other similar variables
	gen retaliation_quit = quit
	lab def genders 1 "Male" 0 "Female"
		lab val male genders
	replace internal = 1 if internal == . & wb_description_external == "Internal"
	replace internal = 1 if internal == . ///
		& !inlist(job_title_at_fraud_firm, "", "(Customer)", "Medical Patient (Not Employee)")
	replace internal = 1 if internal == . & wb_raised_issue_internally == "YES"
	*assert wb_raised_issue_internally != "YES" if internal == 0
	replace wb_raised_issue_internally = "NO" if internal == 0 & wb_raised_issue_internally == ""
	
	replace job_title_at_fraud_firm = job_title_at_fraud_firm + "; Government Program Auditor" ///
		if case_id == 2586 & wb_full_name == "Parikh, Girish"

merge m:1 caption using "total_settlements_from_qtrack.dta", nogen keepus(total_federal_recovery) keep(1 3)
	ren total_federal_recovery settlement
	gen settled = settlement != . & settlement > 0
	replace settlement = settlement/1000000
		lab var settlement "Settlement ($ Millions)"


replace wb_full_name = "Lammers, Bonnie" if wb_full_name == "Lamers, Bonnie" 

drop if internal == 0 & wb_raised_issue_internally == "YES"
append using "$dropbox/raised_yes_employee_no.dta"
	drop mgmt_class wb_type wb_age_bin // already exist in raised_yes_employee_no.dta
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
replace mgmt_class = "Lower" if mgmt_class == "" & job_title_at_fraud_firm != "";

/* Just to verify what job titles appear in each
tab job_title if mgmt_class == "Upper"
tab job_title if mgmt_class == "Middle"
tab job_title if mgmt_class == "Lower"
*/

gen wb_type = "(Former) Employee" if internal == 1;
replace wb_type = "Auditor" if strpos(lower(wb_description_external), "auditor") > 0
								& internal == 0;
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
replace wb_type = "Government" if (inlist(wb_description_external, "Behalf of Usa", "Employed With Fbi", "Usda Worker")
								| strpos(lower(wb_description_external), "government") > 0)
								& internal == 0;
replace wb_type = "Investigator" if (strpos(lower(wb_description_external), "investigator") > 0
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

include code_missing_internal.do									

*-------------------------------------------
gen wb_age_bin = int(wb_age/10)*10
	lab def age_bins 10 "18-19" 20 "20-29" 30 "30-39" 40 "40-49" ///
						50 "50-59" 60 "60-69" 70 "70-79", replace
	lab val wb_age_bin age_bins
*-------------------------------------------

replace case_id = 512 if case_id == 3498 ///
	& caption == "US ex rel Teodoro, Mercedes & Tommy v Neocare Health Systems Inc F/K/A Neocare Healthcare et al"
	



duplicates drop
