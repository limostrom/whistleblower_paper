/*

Fixing/Double checking wb_raised_issue_internally == "NO" or ""


*/

cap cd "C:\Users\lmostrom\Dropbox\Violation paper\whistleblower paper\"

include wb_data_clean.do

keep if inlist(wb_raised_issue_internally, "NO", "") & internal == 1

sort caption
keep case_id caption wb_full_name job_title_at_fraud_firm wb_raised_issue_internally ///
	audit billing colleague direct_supervisor gov hotline hr legalcompliance relevantdirector topmanager ///
	response_* retaliation_*
	
export excel "employee_wbs_not_raised_internally.xls", first(variables)

*================================================================================

include wb_data_clean.do

keep if wb_raised_issue_internally == "YES" & internal == 1

sort caption
keep case_id caption wb_full_name job_title_at_fraud_firm wb_raised_issue_internally ///
	audit billing colleague direct_supervisor gov hotline hr legalcompliance relevantdirector topmanager ///
	response_* retaliation_*
	
export excel "employee_wbs_raised_internally.xls", first(variables)

*================================================================================

include wb_data_clean.do

keep if internal == 1
keep if gvkey != .

*gen fyear = year(received_date)
*merge m:1 gvkey fyear using "../../Compustat.dta", nogen keep(3) keepus(sic)

replace conm = "EXXON CORP" if gvkey == 4503
replace conm = "AMERIGROUP CORP" if gvkey == 145367

gsort -wb_raised_issue_internally -mgmt_class wb_full_name
br wb_full_name conm mgmt_class wb_raised_issue_internally

export excel wb_full_name conm mgmt_class received_date ///
			wb_start_year_at_firm1 wb_end_year_at_firm1 wb_raised_issue_internally ///
	using "employee_wbs_from_public_firms-for_linkedin.xls", first(variables) replace
