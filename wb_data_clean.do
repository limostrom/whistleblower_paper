/*

wb_data_clean.do

Opens master_dataset_bk, merges in other necessary variables from other datasets,
	codes job titles into management ranks, etc.
	
1.	Clean
	a.	Match the column “wb_raised_internally” from the dataset “issue internal”
		to that database just to make sure that master_dataset_bk is really up to date.
	b.	Data on case outcomes can be found in “qtrack_foia_request” and settlement
		info in “settlement”. You should be able to match that information based on “caption”
	c.	Aggregate job titles into upper (C_Suite, President, VP, etc), middle
		(“manager” in title), and low (everyone else) management
		
*/

use master_dataset_bk, clear
	drop if case_id == . & caption == "" & wb_full_name == ""
	
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

*merge 1:1 caption wb_full_name using "issue internal.dta", replace keepus(wb_raisnogen
	// want no conflicts, only updates to missing values

merge m:1 caption using "total_settlements_from_qtrack.dta", nogen keepus(total_federal_recovery) keep(1 3)
	ren total_federal_recovery settlement
	gen settled = settlement != . & settlement > 0
	replace settlement = settlement/1000000
		lab var settlement "Settlement ($ Millions)"

merge 1:m caption wb_full_name using "master_dataset_v3_gvkey.dta", nogen ///
	keep(1 3) keepus(match_score gvkey conm)
	replace public_firm = 1 if public_firm == . & gvkey != .

replace wb_full_name = "Lammers, Bonnie" if wb_full_name == "Lamers, Bonnie" 

drop if internal == 0 & wb_raised_issue_internally == "YES"
append using raised_yes_employee_no
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
