/*
Whistleblower Data Summary Stats



2.	Tables
	a.	Industry distribution of firms in the data
	b.	Who are the whistleblowers?
		i.	Gender
		ii.	Age
		iii.	Management level
		iv.	Employees (internal) vs. auditors, customers, analysts, etc
	c.	How did they report?
		i.	Straight to government vs. reported internally first
			1.	Overall and by management level
			2.	Of those that reported internally first, what channels did they try?
	d.	What happened?
		i.	How did the company respond to internal reports?
		ii.	How did the company retaliate against the employee?
		iii.	How many cases were settled (i.e. were prosecuted successfully)
			& how big were the settlements?
			1.	By WB’s management level
			2.	By reporting internally first vs. going straight to the government
				a.	By internal reporting channel
			3.	Employees vs. analysts, auditors, customers, etc.
			4.	By gender
			5.	By age
*/


set more off
clear all
set scheme s1color, perm
pause on

cap cd "C:\Users\lmostrom\Dropbox\Violation paper\whistleblower paper\"
local log_name "wb_summ_stats-internalWBs_only"

*===============================================================================
*include wb_data_import
include wb_data_clean
*===============================================================================
egen tag_case = tag(case_id)

cap log close
log using "`log_name'.txt", text replace

dis "Healthcare-Related vs. Not Healthcare-Related"
fre healthcare_related if tag_case
dis "Internal Whistleblowers by Gender"
fre male if internal
dis "Internal Whistleblowers by Age Bin"
fre wb_age_bin if internal
dis "Internal Whistleblowers by Management Level"
fre mgmt_class if internal
dis "Employees vs. External Groups"
fre wb_type

dis "Issue Raised Internally First (Among Internal Whistleblowers)"
fre wb_raised_issue_internally if internal
dis "Issue Raised Internally First by Management Level (Among Internal Whistleblowers)"
tab wb_raised_issue_internally mgmt_class if internal
cap log close


local internal_mechanisms "auditor billing colleague direct_supervisor gov hotline hr legalcompliance relevantdirector topmanager"
	preserve
	keep if internal
	collapse (sum) `internal_mechanisms', by(wb_raised_issue_internally)
	foreach var of varlist `internal_mechanisms' {
		ren `var' n`var'
	}
	reshape long n, i(wb_raised_issue_internally) j(mechanism) string
	drop if n == 0
	gsort -wb_raised_issue_internally -n
	replace wb_raised_issue_internally = "not stated" if wb_raised_issue_internally == ""
	
	cap log close
	log using "`log_name'.txt", text append nomsg
	dis "Issue-Raising Channels by Internal/External (Among Internal Whistleblowers)"
	list
	cap log close
	
	restore

preserve // --- company's responses to issue
	keep if internal
	collapse (sum) response_*, fast
	gen id = _n
	ren response_* n*
	reshape long n, i(id) j(response) string
	drop id
	gsort -n
	replace response = "internal investigation" if response == "int_inv"
	egen tot = total(n)
	gen percent = n/tot*100
	drop tot
	
	cap log close
	log using "`log_name'.txt", text append nomsg
	dis "Company Responses to Internal Issues"
	list
	cap log close
	
restore

preserve // --- company's responses to issue by gender
	keep if internal
	collapse (sum) response_*, by(male) fast
	ren response_* n*
	reshape long n, i(male) j(response) string
		replace male = 2 if male == .
		lab def gender_lab 0 "Female" 1 "Male" 2 "Unknown"
		lab val male gender_lab
	reshape wide n, i(response) j(male)
		drop n2 // unknown gender, all 0 
		ren n0 Female
		ren n1 Male
	gsort -Male
	replace response = "internal investigation" if response == "int_inv"
	egen totM = total(Male)
	egen totF = total(Female)
	gen pct_Female = Female/totF*100
	gen pct_Male = Male/totM*100
	drop totM totF
	order response Male pct_Male Female pct_Female
	
	cap log close
	log using "`log_name'.txt", text append nomsg
	dis "Company Responses to Internal Issues by WB Gender"
	list
	cap log close
	
restore

preserve // --- company's retaliation against WB
	keep if internal
	collapse (sum) retaliation_*, fast
	gen id = _n
	ren retaliation_* n*
	reshape long n, i(id) j(retaliation) string
	drop id
	gsort -n
	egen tot = total(n)
	gen percent = n/tot*100
	drop tot

	cap log close
	log using "`log_name'.txt", text append nomsg
	dis "Retaliation & Quits"
	list
	cap log close
	
restore

preserve // --- company's retaliation against WB by gender
	keep if internal
	collapse (sum) retaliation_*, by(male) fast
	ren retaliation_* n*
	reshape long n, i(male) j(retaliation) string
		replace male = 2 if male == .
		lab def gender_lab 0 "Female" 1 "Male" 2 "Unknown"
		lab val male gender_lab
	reshape wide n, i(retaliation) j(male)
		drop n2 // unknown gender, all 0 
		ren n0 Female
		ren n1 Male
	gsort -Male
	egen totM = total(Male)
	egen totF = total(Female)
	gen pct_Female = Female/totF*100
	gen pct_Male = Male/totM*100
	drop totM totF
	order retaliation Male pct_Male Female pct_Female
	
	cap log close
	log using "`log_name'.txt", text append nomsg
	dis "Retaliation & Quits by WB Gender"
	list
	cap log close
	
restore

cap log close
log using "`log_name'.txt", text append nomsg
dis "Settled Cases"
dis "	Overall"
	fre settled if internal
	summ settlement if internal

dis "	by Management Level (Among Internal Whistleblowers)"
	tab settled mgmt_class  if internal
	bys mgmt_class: summ settlement  if internal
	graph box settlement if settled & internal, over(mgmt_class, tot lab(labsize(small))) ///
		noout title("by Management Level") subtitle("(Among Internal Whistleblowers)") name("mgmt_class", replace)
	graph export "settlement_boxplot_mgmt_class.png", replace as(png) hei(700) wid(1500)
dis "	by Gender (Among Internal Whistleblowers)"
	tab settled male if internal
	bys male: summ settlement if internal
	graph box settlement if settled & internal, over(male, tot lab(labsize(small))) ///
		noout title("by Gender")  subtitle("(Among Internal Whistleblowers)") name("gender", replace)
	graph export "settlement_boxplot_gender.png", replace as(png) hei(700) wid(1500)
dis "	by Age (Among Internal Whistleblowers)"
	tab settled wb_age_bin if internal
	bys wb_age_bin: summ settlement if internal
	graph box settlement if settled & internal, over(wb_age_bin, tot lab(labsize(small))) ///
		noout title("by Age Group") subtitle("(Among Internal Whistleblowers)") name("age", replace)
	graph export "settlement_boxplot_age.png", replace as(png) hei(700) wid(1500)
dis "	by Employee or External Group"
	tab settled wb_type
	bys wb_type: summ settlement
	graph box settlement if settled, over(wb_type, tot lab(labsize(small))) ///
		noout title("by Employee or External Group") name("type", replace)
	graph export "settlement_boxplot_emp_vs_ext.png", replace as(png) hei(700) wid(1500)
dis "	by Internal vs. External Reporting (Among Internal Whistleblowers)"
	tab settled wb_raised_issue_internally if internal
	bys wb_raised_issue_internally: summ settlement if internal
	graph box settlement if settled & internal, over(wb_raised_issue_internally, tot lab(labsize(small))) ///
		noout title("Raised Issue Internally") subtitle("(Among Internal Whistleblowers)") name("internal", replace)
	graph export "settlement_boxplot_raised_internal.png", replace as(png) hei(700) wid(1500)
dis "	by Reporting Channel (Among Internal Whistleblowers)"
	cap log close
	preserve
		keep if internal
		gen internal_mech = ""
		local internal_mechanisms "auditor billing colleague direct_supervisor gov hotline hr legalcompliance relevantdirector topmanager"
		foreach var of varlist `internal_mechanisms' {
			replace `var' = . if `var' == 0
		}
		egen n_channels = rownonmiss(`internal_mechanisms')
			qui summ n_channels
			local max_channels = `r(max)'
		foreach var of varlist `internal_mechanisms' {
			replace internal_mech = "`var'" if `var' != .
		}
		
		log using "`log_name'.txt", text append nomsg
		tab settled internal_mech
		bys internal_mech: summ settlement
		cap log close
		graph box settlement if settled & wb_raised_issue_internally == "YES", ///
			over(internal_mech, tot lab(alt labsize(small))) noout title("by Internal Channel") name("channel", replace)
		graph export "settlement_boxplot_internal_channel.png", replace as(png) hei(700) wid(1500)
	restore
		
		/*
		isid case_id wb_full_name
		expand n_channels, gen(dup) // create copies if used more than one
		bys case_id wb_full_name (dup): gen dup_id = dup+dup[_n-1]
			replace dup_id = 0 if dup_id == . & dup == 0
		foreach var of varlist `internal_mechanisms' {
			dis "max channels = `max_channels'"
			forval i=0/`max_channels' {
				
			}
		}
		*/
		
	



graph combine mgmt_class gender internal channel type /*age*/, r(3)
graph export "settlement_boxplots_combined.png", replace as(png) hei(1200) wid(1200)

