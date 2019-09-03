/*

wb_tables_create.do

See /whistleblower paper/drafts/Manuscript draft_v4.docx for instructions

*/

set more off
clear all
set scheme s1color, perm
pause off

*---------------------------
local run_1A 0
local run_1B 0
local run_1C 0
local run_1D 0
local run_2 0
local run_3A 0
local run_3BC 0
local run_4A 0
local run_4BC 0
local run_5 1
local run_all 0
*---------------------------

cap cd "C:\Users\lmostrom\Dropbox\Violation paper\whistleblower paper\"


*-------------------------------------------------------------------------------
include "$repo/wb_data_clean.do"
	egen wb_id = group(wb_full_name)
	egen tag_case_id = tag(case_id)
	egen tag_gvkey = tag(gvkey)
	egen tag_wb_id = tag(wb_id)
*-------------------------------------------------------------------------------
* ================================== TABLE 1 ================================== *
* Panel A
if `run_1A' == 1 | `run_all' == 1 {
*------------------------------------
preserve // -- Load in full QTRACK FOIA Request dataset
	import excel "$dropbox/QTRACK_FOIA_Request_060313.xls", first case(lower) clear
	keep caption relator_name
	egen tag_case = tag(caption)
	egen tag_rel = tag(relator_name)
	tab tag_case, subpop(tag_case)
		local N_case = `r(N)'
	tab tag_rel, subpop(tag_rel)
		local N_wb = `r(N)'

	mat A = (`N_case', ., `N_wb') // full sample of allegations, first row of table
restore

*Initiate second row
mat A = (A \ 0, 0, 0)

*Third row
foreach col in case_id gvkey wb_id { 
	tab tag_`col', subpop(tag_`col')
	local N_`col' = `r(N)' // number of unique cases, firms, or whistleblowers
}
mat A = (A \ `N_case_id', `N_gvkey', `N_wb_id')

*Replace second row as difference between rows 1 and 3
	forval j = 1/3 { // loop through columns 1-3
		mat A[2,`j'] = A[1,`j'] - A[3,`j'] 
			// less cases without court filings
	}
	
local i = 5 // going to refer to row 5
foreach if_st in "if inlist(internal, 0, .)" /* less external whistleblowers */ ///
				 "if internal == 1 & gvkey == ." /* less private firms */ {
	foreach col in case_id gvkey wb_id { 
		tab tag_`col' `if_st', subpop(tag_`col')
		local N_`col' = `r(N)' // number of unique cases, firms, or whistleblowers
	}
	mat A = (A \ `N_case_id', `N_gvkey', `N_wb_id') // add row for "less [...]"
	
	mat A = (A \ 0, 0, 0) // add empty row for "sample used for Tables X-Y" to be filled in
	local i_2 = `i' - 2 // row number 2 rows up
	local i_1 = `i' - 1 // row number 1 row up
	
	forval j = 1/3 { // loop through columns 1-3
		mat A[`i',`j'] = A[`i_2',`j'] - A[`i_1',`j'] 
			// sample used for Tables X-Y = (previous sample size) - (less [...] sample size)
	}
	local i = `i' + 2 // do this 2 more rows down next time
}

preserve
	drop _all // clear dataset in memory but keep matrices saved in memory
	svmat2 A, names(cases unique_firms unique_wbs) // load matrix A in as a dataset
		foreach var in cases unique_firms unique_wbs {
			tostring `var', force replace
			replace `var' = "(" + `var' + ")" if _n == 2 | _n == 4 | _n == 6
		}
		replace unique_firms = "" if inlist(unique_firms, ".", "(.)")
	export excel "$dropbox/draft_tables.xls", sheet("1.A") sheetrep first(var)
restore
} // end Panel A ---------------------------------------------------------------

*------------------------------------
* Panel B
if `run_1B' == 1 | `run_all' == 1 {
*------------------------------------
preserve
	keep if gvkey != .
	codebook wb_id 
	collapse (count) cases = case_id (mean) avg_settlement = settlement ///
			 (sum) tot_settlements = settlement, by(wb_type) fast
	gsort -cases
		local leftcol "wb_type" // need to set these locals for add_total_row_and_pct_col_to_table.do
		local tab_cols "cases tot_settlements" // the columns you need to calculate "% of total" for
		include "$repo/add_total_row_and_pct_col_to_table.do"
		tostring avg_settlement tot_settlements, replace force format(%9.1f)
		replace avg_settlement = "$" + avg_settlement
			replace avg_settlement = "" if avg_settlement == "$."
		replace tot_settlements = "$" + tot_settlements
		order wb_type cases cases_pct_str avg_settlement tot_settlements tot_settlements_pct_str
	export excel "$dropbox/draft_tables.xls", sheet("1.B") sheetrep first(var)
restore
} // end Panel B ---------------------------------------------------------------

*------------------------------------
* Panel C
if `run_1C' == 1 | `run_all' == 1 {
*------------------------------------
preserve
	keep if internal == 1 & gvkey != .
	tab fyear if tag_case_id, matcell(C) matrow(rC)
	mat C = (rC, C)
	drop _all
	svmat2 C, names(year cases)
		local leftcol "year"  // need to set these locals for add_total_row_and_pct_col_to_table.do
		local tab_cols "cases" // the column you need to calculate "% of total" for
		include "$repo/add_total_row_and_pct_col_to_table.do"
	export excel "$dropbox/draft_tables.xls", sheet("1.C") sheetrep first(var)
restore
} // end Panel C ---------------------------------------------------------------

*------------------------------------
* Panel D
if `run_1D' == 1 | `run_all' == 1 {
*------------------------------------
preserve
keep if internal == 1 & gvkey != .
merge m:1 caption using "$dropbox/gov_agencies_from_qtrack.dta", nogen keep(1 3) keepus(primary_agency)
include "$repo/replace_agency_names.do"
collapse (sum) cases = tag_case_id /*unique_firms = tag_gvkey unique_wbs = tag_wb_id*/ ///
	, by(primary_agency) fast
g byte nonmiss = primary_agency != "Unknown"
drop if cases == 0
gsort -nonmiss -cases
	drop nonmiss
	local leftcol "primary_agency" // need to set these locals for add_total_row_and_pct_col_to_table.do
	local tab_cols "cases" // the column you need to calculate "% of total" for
	include "$repo/add_total_row_and_pct_col_to_table.do"
export excel "$dropbox/draft_tables.xls", sheet("1.D") sheetrep first(var)
restore
} // end Panel D ---------------------------------------------------------------

keep if internal == 1
include "$repo/job_titles_to_functions.do"
	gen other_function = inlist(wb_function, "Other Employee", "Other Manager", "Unspecified")
	bys wb_id (received_date): gen repeat_wb_all = _N > 1
	bys wb_id (received_date): gen repeat_wb_not1st = _n > 1

* ================================== TABLE 2 ================================== *
if `run_2' == 1 | `run_all' == 1 {
*------------------------------------
codebook wb_id
codebook case_id

* --- Male --- *
preserve // -- first do left side of table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement, by(male)
	ren male male_int
	decode male_int, gen(male) // need string for row names
	egen obsA = total(allegations) // total observations not missing gender
	ren allegations allegationsA
	ren settlement settlementA
	mkmat obsA allegationsA settlementA, mat(all) rownames(male)
restore
preserve // -- now do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement, by(male)
	ren allegations allegationsP
	ren settlement settlementP
	egen obsP = total(allegationsP)
	mkmat obsP allegationsP settlementP, mat(public) // don't need row names because
								// this matrix is being appended to the right of the all matrix
restore

mat tab2A = (all[1,1], ., ., public[1,1], ., ., 1 \ /* put total non-missing obs on first line only, not under either gender */ ///
			., all[1,2..3], ., public[1,2..3],  1 \ /* leave obs empty, fill in allegations and settlements columns */ ///
			., all[2,2..3], ., public[2,2..3],  1)    /* leave obs empty, fill in allegations and settlements columns */
mat rownames tab2A = "Gender" "Female" "Male"
mat list tab2A // just to view so it looks right

* --- Age --- *
/*** only one observation from this subset has age filled in so I'm skipping this
preserve // -- first do left side of table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement, by(wb_age_bin)
		drop if wb_age_bin == .
	ren wb_age_bin age_bin_int
	decode age_bin_int, gen(wb_age_bin) // need string for row names
	egen obsA = total(allegations) // total observations not missing gender
	ren allegations allegationsA
	ren settlement settlementA
	sort wb_age_bin
	mkmat obsA allegationsA settlementA, mat(all) rownames(wb_age_bin)
restore
preserve // -- now do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement, by(wb_age_bin)
		drop if wb_age_bin == .
	ren wb_age_bin age_bin_int
	decode age_bin_int, gen(wb_age_bin) // need string to check if all age ranges are covered
		* make sure there are observations for each age range
		set obs 7
		levelsof wb_age_bin, local(age_bins) s(",")
		foreach range in "18-19" "20-29" "30-39" "40-49" "50-59" "60-69" "70-79" {
			if !inlist("`range'", `age_bins') {	// if no obs for that age bin	
				bys wb_age_bin: replace wb_age_bin = "`range'" if wb_age_bin == "" & _n == 1
				// add an empty row for that age bin so the matrices line up correctly
			}
		}
	ren allegations allegationsP
		replace allegationsP = 0 if allegationsP == .
	ren settlement settlementP
		replace settlementP = 0 if settlementP == .
	egen obsP = total(allegationsP)
	sort wb_age_bin
	mkmat obsP allegationsP settlementP, mat(public) // don't need row names because
								// this matrix is being appended to the right of the all matrix
restore
*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/7 {
		local other_rows "`other_rows' ., all[`x',2..3], ., public[`x',2..3], 2" /* leave obs empty, fill in others */
		if `x' < 7 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab2B = (all[1,1], ., ., public[1,1], ., ., 2 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat list tab2B
mat rownames tab2B = "Age" "18-19" "20-29" "30-39" "40-49" "50-59" "60-69" "70-79"
*/
* --- Management Rank --- *
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement, by(mgmt_class)
		drop if mgmt_class == ""
	ren allegations allegationsP
	ren settlement settlementP
	egen obsP = total(allegationsP)
	tempfile public2C
	save `public2C', replace
restore
preserve // -- now do left side of table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement, by(mgmt_class)
		drop if mgmt_class == ""
	egen obsA = total(allegations)
	ren allegations allegationsA
	ren settlement settlementA
	merge 1:1 mgmt_class using `public2C', assert(3)
		*br
		*pause
	mkmat obsA allegationsA settlementA obsP allegationsP settlementP, mat(all) rownames(mgmt_class)
restore


*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/3 {
		local other_rows "`other_rows' ., all[`x',2..3], ., all[`x',5..6], 3" /* leave obs empty, fill in others */
		if `x' < 3 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab2C = (all[1,1], ., ., all[1,4], ., ., 3 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat rownames tab2C = "Rank" "Rank_and_File" "Middle_Management" "Upper_Management"
mat list tab2C

* --- Function --- *
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement, by(wb_function other_function)
		drop if wb_function == ""
	ren allegations allegationsP
	ren settlement settlementP
	egen obsP = total(allegationsP)
	tempfile public2D
	save `public2D', replace
restore
preserve // now do the left side of the table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement, by(wb_function other_function)
		drop if wb_function == ""
	merge 1:1 wb_function using `public2D', assert(1 3)
	egen obsA = total(allegations)
	ren allegations allegationsA
	ren settlement settlementA
	gsort other_function -allegationsA
		*br
		*pause // to know what order row names should go in
	mkmat obsA allegationsA settlementA obsP allegationsP settlementP, mat(all) rownames(wb_function)
restore


*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/14 {
		local other_rows "`other_rows' ., all[`x',2..3], ., all[`x',5..6], 4" /* leave obs empty, fill in others */
		if `x' < 14 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab2D = (all[1,1], ., .,all[1,4], ., ., 4 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat rownames tab2D = "Function" "Health_Professional" "Finance/Accounting" "Sales" ///
				"Operations" "Quality_Assurance" "Administrator" "Legal/Compliance" ///
				 "Auditor" "Marketing" "Consultant" "HR" "IT" ///
				"Other_Employee" "Other_Manager"
mat list tab2D

* --- Repeat Whistleblower --- *
preserve
	replace repeat_wb_all = 0 if  inlist(wb_full_name, "Doe, John", "Doe, Jane")
	collapse (count) allegations = case_id (sum) settlement, by(repeat_wb_all)
	egen obsA = total(allegations)
	ren allegations allegationsA
	ren settlement settlementA
	mkmat obsA allegationsA settlementA, mat(all) rownames(repeat_wb_all)
restore
preserve // -- now do right side of table, "Public Firms"
	replace repeat_wb_all = 0 if  inlist(wb_full_name, "Doe, John", "Doe, Jane")
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement, by(repeat_wb_all)
	ren allegations allegationsP
	ren settlement settlementP
	egen obsP = total(allegationsP)
	mkmat obsP allegationsP settlementP, mat(public)
restore

*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/2 {
		local other_rows "`other_rows' ., all[`x',2..3], ., public[`x',2..3], 5" /* leave obs empty, fill in others */
		if `x' < 2 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab2E = (all[1,1], ., ., public[1,1], ., ., 5 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat rownames tab2E = "Repeat_Whistleblowers" "1_Allegation_Only" "Multiple_Allegations"
mat list tab2E

*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab2 = (tab2A \ /*Age - tab2B \ */ tab2C \ tab2D \ tab2E)
	svmat2 full_tab2, names(obsA allegationsA settlementA obsP allegationsP settlementP subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsA" "settlementA" "allegationsP" "settlementP" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

		drop tot pct
	}
	* end %s of Total // -------------------------------------------------------
	order rowname obsA allegationsA allegationsA_pct_str settlementA settlementA_pct_str ///
				obsP allegationsP allegationsP_pct_str settlementP settlementP_pct_str
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Gender", "Age", "Rank", "Function", "Repeat_Whistleblowers", "Total")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	tostring settlementA, replace force format(%9.1f)
		replace settlementA = "$" + settlementA if settlementA != "."
	tostring settlementP, replace force format(%9.1f)
		replace settlementP = "$" + settlementP if settlementP != "."
		
	foreach var of varlist *_pct_str settlement? {
		replace `var' = "" if `var' == "."
	}
	drop obsP subtable
	export excel "$dropbox/draft_tables.xls", sheet("2") sheetrep first(var)
restore
} // end Table 2 ---------------------------------------------------------------	

* ================================== TABLE 3 ================================== *
* Panel A
if `run_3A' == 1 | `run_all' == 1 {
*------------------------------------
* --- Raised issue internally --- *
preserve // -- first do left side of table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement, by(wb_raised_issue_internally)
		drop if wb_raised_issue_internally == ""
	egen obsA = total(allegations) // total observations not missing gender
	ren allegations allegationsA
	ren settlement settlementA
	mkmat obsA allegationsA settlementA, mat(all) rownames(wb_raised_issue_internally)
restore
preserve // -- now do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement, by(wb_raised_issue_internally)
	drop if wb_raised_issue_internally == ""
	ren allegations allegationsP
	ren settlement settlementP
	egen obsP = total(allegationsP)
	mkmat obsP allegationsP settlementP, mat(public) // don't need row names because
								// this matrix is being appended to the right of the all matrix
restore

mat tab3A1 = (all[1,1], ., ., public[1,1], ., ., 1 \ /* put total non-missing obs on first line only, not under either gender */ ///
			., all[1,2..3], ., public[1,2..3],  1 \ /* leave obs empty, fill in allegations and settlements columns */ ///
			., all[2,2..3], ., public[2,2..3],  1)    /* leave obs empty, fill in allegations and settlements columns */
mat rownames tab3A1 = "Reported_Internally_First" "No" "Yes"
mat list tab3A1 // just to view so it looks right

* --- Internal Reporting Channel --- *
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

local int_channels "int_auditor billing colleague direct_supervisor hotline hr legalcompliance relevantdirector topmanager"
local ext_channels "ext_auditor gov ext_to_courts"

foreach var in `int_channels' `ext_channels' {
	gen stlmt_`var' = settlement * (`var' > 0)
}
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (sum) `int_channels' stlmt*, fast
		drop stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor
	foreach var in `int_channels' {
		ren `var' n`var' // for reshape
	}
	gen i = _n
	reshape long n stlmt_, i(i) j(channel) string
	egen obsP = total(n) // total observations not missing
	ren n allegationsP
	ren stlmt_ settlementP
	tempfile public3A2
	save `public3A2', replace
restore
preserve // -- now do left side of table, "All Firms"
	collapse (sum) `int_channels' stlmt*, fast
		drop stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor
	foreach var in `int_channels' {
		ren `var' n`var' // for reshape
	}
	gen i = _n
	reshape long n stlmt_, i(i) j(channel) string
	gsort -n
	egen obsA = total(n)
	ren n allegationsA
	ren stlmt_ settlementA
	merge 1:1 channel using `public3A2', assert(3)
	gsort -allegationsA
		br
		*pause
	mkmat obsA allegationsA settlementA obsP allegationsP settlementP, mat(all) rownames(channel)
restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/9 {
		local other_rows "`other_rows' ., all[`x',2..3], .,all[`x',5..6], 2" /* leave obs empty, fill in others */
		if `x' < 9 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab3A2 = (all[1,1], ., ., all[1,4], ., ., 2 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat list tab3A2
mat rownames tab3A2 = "Internal_Reporting_Channel" "Direct_Supervisor" "Top_Manager" ///
				"Relevant_Director" "Colleague" "Legal_Compliance" "HR" "Billing" ///
				"Hotline" "Internal_Auditor"

* --- External Reporting Channel --- *
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (sum) `ext_channels' stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor, fast
	foreach var in `ext_channels' {
		ren `var' n`var' // for reshape
	}
	gen i = _n
	reshape long n stlmt_, i(i) j(channel) string
	egen obsP = total(n) // total observations not missing
	ren n allegationsP
	ren stlmt_ settlementP
	tempfile public3A3
	save `public3A3', replace
restore
preserve // -- now do left side of table, "All Firms"
	collapse (sum) `ext_channels' stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor, fast
	foreach var in `ext_channels' {
		ren `var' n`var' // for reshape
	}
	gen i = _n
	reshape long n stlmt_, i(i) j(channel) string
	gsort -n
	egen obsA = total(n)
	ren n allegationsA
	ren stlmt_ settlementA
	merge 1:1 channel using `public3A3', assert(3)
	gsort -allegationsA
		br
		*pause
	mkmat obsA allegationsA settlementA obsP allegationsP settlementP, mat(all) rownames(channel)
restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/3 {
		local other_rows "`other_rows' ., all[`x',2..3], .,all[`x',5..6], 3" /* leave obs empty, fill in others */
		if `x' < 3 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab3A3 = (all[1,1], ., ., all[1,4], ., ., 3 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat list tab3A3
mat rownames tab3A3 = "External_Reporting_Channel" "Straight_to_Court_System" ///
				"Government_Agency" "External_Auditor"

*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab3A = (tab3A1 \ tab3A2 \ tab3A3)
	svmat2 full_tab3A, names(obsA allegationsA settlementA obsP allegationsP settlementP subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsA" "settlementA" "allegationsP" "settlementP" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

		drop tot pct
	}
	* end %s of Total // -------------------------------------------------------
	order rowname obsA allegationsA allegationsA_pct_str settlementA settlementA_pct_str ///
				obsP allegationsP allegationsP_pct_str settlementP settlementP_pct_str
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Reported_Internally_First", "Internal_Reporting_Channel", "External_Reporting_Channel")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	tostring settlementA, replace force format(%9.1f)
		replace settlementA = "$" + settlementA if settlementA != "."
	tostring settlementP, replace force format(%9.1f)
		replace settlementP = "$" + settlementP if settlementP != "."
		
	foreach var of varlist *_pct_str settlement? {
		replace `var' = "" if `var' == "."
	}
	drop obsP subtable
	export excel "$dropbox/draft_tables.xls", sheet("3.A") sheetrep first(var)
restore
} // end Panel A ---------------------------------------------------------------

*------------------------------------
* Panels B & C
if `run_3BC' == 1 | `run_all' == 1 {
foreach panel in "B" "C" {

* --- Male --- *
	preserve // -- first do left side of table, "Internal"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "YES"
		collapse (count) allegations = case_id (sum) settlement, by(male)
			drop if male == .
		ren male male_int
		decode male_int, gen(male) // need string for row names
		egen obsI = total(allegations) // total observations not missing gender
		ren allegations allegationsI
		ren settlement settlementI
		mkmat obsI allegationsI settlementI, mat(int) rownames(male)
	restore
	preserve // -- now do right side of table, "External"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (sum) settlement, by(male)
			drop if male == .
		ren allegations allegationsE
		ren settlement settlementE
		egen obsE = total(allegationsE)
		mkmat obsE allegationsE settlementE, mat(ext) // don't need row names because
									// this matrix is being appended to the right of the all matrix
	restore

	mat tab3`panel'1 = (int[1,1], ., ., ext[1,1], ., ., 1 \ /* put total non-missing obs on first line only, not under either gender */ ///
				., int[1,2..3], ., ext[1,2..3],  1 \ /* leave obs empty, fill in allegations and settlements columns */ ///
				., int[2,2..3], ., ext[2,2..3],  1)    /* leave obs empty, fill in allegations and settlements columns */
	mat rownames tab3`panel'1 = "Gender" "Female" "Male"
	mat list tab3`panel'1 // just to view so it looks right

* --- Age --- *
/*	**** only one observation from this subset has age filled in so I'm skipping this
	preserve // -- first do left side of table, "Internal"
		keep if wb_raised_issue_internally == "YES"
		collapse (count) allegations = case_id (sum) settlement, by(wb_age_bin)
			drop if wb_age_bin == .
		ren wb_age_bin age_bin_int
		decode age_bin_int, gen(wb_age_bin) // need string for row names
			* make sure there are observations for each age range
			set obs 7
			levelsof wb_age_bin, local(age_bins) s(",")
			foreach range in "18-19" "20-29" "30-39" "40-49" "50-59" "60-69" "70-79" {
				if !inlist("`range'", `age_bins') {	// if no obs for that age bin	
					bys wb_age_bin: replace wb_age_bin = "`range'" if wb_age_bin == "" & _n == 1
					// add an empty row for that age bin so the matrices line up correctly
				}
			}
		egen obsI = total(allegations) // total observations not missing gender
		ren allegations allegationsI
		ren settlement settlementI
		sort wb_age_bin
		mkmat obsI allegationsI settlementI, mat(int) rownames(wb_age_bin)
	restore
	preserve // -- now do right side of table, "External"
		keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (sum) settlement, by(wb_age_bin)
			drop if wb_age_bin == .
		ren wb_age_bin age_bin_int
		decode age_bin_int, gen(wb_age_bin) // need string to check if all age ranges are covered
			* make sure there are observations for each age range
			set obs 7
			levelsof wb_age_bin, local(age_bins) s(",")
			foreach range in "18-19" "20-29" "30-39" "40-49" "50-59" "60-69" "70-79" {
				if !inlist("`range'", `age_bins') {	// if no obs for that age bin	
					bys wb_age_bin: replace wb_age_bin = "`range'" if wb_age_bin == "" & _n == 1
					// add an empty row for that age bin so the matrices line up correctly
				}
			}
		ren allegations allegationsE
			replace allegationsE = 0 if allegationsE == .
		ren settlement settlementE
			replace settlementE = 0 if settlementE == .
		egen obsE = total(allegationsE)
		sort wb_age_bin
		br
		*pause
		mkmat obsE allegationsE settlementE, mat(ext) // don't need row names because
									// this matrix is being appended to the right of the all matrix
	restore
	*store local string to input other all[] and public[] rows into the tab2 matrix
		local other_rows ""
		forval x=1/7 {
			local other_rows "`other_rows' ., int[`x',2..3], ., ext[`x',2..3], 2" /* leave obs empty, fill in others */
			if `x' < 7 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3`panel'2 = (int[1,1], ., ., ext[1,1], ., ., 2 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat list tab3`panel'2
	mat rownames tab3`panel'2 = "Age" "18-19" "20-29" "30-39" "40-49" "50-59" "60-69" "70-79"
*/
* --- Management Rank --- *
	preserve // -- first do right side of table, "External"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (sum) settlement, by(mgmt_class)
			drop if mgmt_class == ""
		ren allegations allegationsE
		ren settlement settlementE
		egen obsE = total(allegationsE)
		tempfile ext3`panel'3
		save `ext3`panel'3', replace
	restore
	preserve // -- now do left side of table, "Internal"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "YES"
		collapse (count) allegations = case_id (sum) settlement, by(mgmt_class)
			drop if mgmt_class == ""
		egen obsI = total(allegations)
		ren allegations allegationsI
		ren settlement settlementI
		merge 1:1 mgmt_class using `ext3`panel'3', assert(1 3)
		sort mgmt_class
			br
			*pause // to know what order to put the row labels in
		mkmat obsI allegationsI settlementI obsE allegationsE settlementE, mat(all) rownames(mgmt_class)
	restore


	*store local string to input other all[] rows into the tab3b matrix
		local other_rows ""
		forval x=1/3 {
			local other_rows "`other_rows' ., all[`x',2..3], ., all[`x',5..6], 3" /* leave obs empty, fill in others */
			if `x' < 3 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3`panel'3 = (all[1,1], ., ., all[1,4], ., ., 3 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat rownames tab3`panel'3 = "Rank" "Rank_and_File" "Middle_Management" "Upper_Management"
	mat list tab3`panel'3

* --- Function --- *
	preserve // -- first do right side of table, "External"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (sum) settlement, by(wb_function other_function)
			drop if wb_function == ""
		ren allegations allegationsE
		ren settlement settlementE
		egen obsE = total(allegationsE)
		tempfile ext3`panel'4
		save `ext3`panel'4', replace
	restore
	preserve // now do the left side of the table, "Internal"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "YES"
		collapse (count) allegations = case_id (sum) settlement, by(wb_function other_function)
			drop if wb_function == ""
		merge 1:1 wb_function using `ext3`panel'4', assert(1 3)
		egen obsI = total(allegations)
		ren allegations allegationsI
		ren settlement settlementI
		gsort other_function -allegationsI -allegationsE
			br
			*pause // to know what order row names should go in
		mkmat obsI allegationsI settlementI obsE allegationsE settlementE, mat(all) rownames(wb_function)
	restore


	*store local string to input other all[] and public[] rows into the tab2 matrix
		local other_rows ""
		forval x=1/14 {
			local other_rows "`other_rows' ., all[`x',2..3], ., all[`x',5..6], 4" /* leave obs empty, fill in others */
			if `x' < 14 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3`panel'4 = (all[1,1], ., .,all[1,4], ., ., 4 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	if "`panel'" == "B" {
		mat rownames tab3`panel'4 = "Function" "Health_Professional" "Finance/Accounting" "Sales" ///
					"Quality_Assurance" "Operations" "Legal/Compliance" "Auditor" ///
					"Administrator" "Marketing" "Consultant" "HR" "IT" ///
					"Other_Employee" "Other_Manager"
	}
	if "`panel'" == "C" {
		mat rownames tab3`panel'4 = "Function" "Sales" "Health_Professional" "Finance/Accounting" ///
					"Quality_Assurance" "Operations" "Auditor" "Legal/Compliance" ///
					"Consultant" "Administrator" "Marketing" "HR" "IT" ///
					"Other_Employee" "Other_Manager"
	}
	mat list tab3`panel'4

* --- Repeat Whistleblower --- *
	preserve // first do left side of table, "Internal"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "YES"
		replace repeat_wb_all = 0 if inlist(wb_full_name, "Doe, John", "Doe, Jane")
		collapse (count) allegations = case_id (sum) settlement, by(repeat_wb_all)
		egen obsI = total(allegations)
		ren allegations allegationsI
		ren settlement settlementI
		mkmat obsI allegationsI settlementI, mat(int) rownames(repeat_wb_all)
	restore
	preserve // -- now do right side of table, "External"
		if "`panel'" == "C" drop if gvkey == .
		keep if wb_raised_issue_internally == "NO"
		replace repeat_wb_all = 0 if inlist(wb_full_name, "Doe, John", "Doe, Jane")
		collapse (count) allegations = case_id (sum) settlement, by(repeat_wb_all)
		ren allegations allegationsE
		ren settlement settlementE
		egen obsE = total(allegationsE)
		set obs 2 // just in case there are no repeat WBs
			*br
			*pause
		mkmat obsE allegationsE settlementE, mat(ext)
	restore

	*store local string to input other all[] and public[] rows into the tab2 matrix
		local other_rows ""
		forval x=1/2 {
			local other_rows "`other_rows' ., int[`x',2..3], ., ext[`x',2..3], 5" /* leave obs empty, fill in others */
			if `x' < 2 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3`panel'5 = (int[1,1], ., ., ext[1,1], ., ., 5 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat rownames tab3`panel'5 = "Repeat_Whistleblowers" "1_Allegation_Only" "Multiple_Allegations"
	mat list tab3`panel'5

*--------------------------------------------
* Now export to excel workbook
	preserve
		drop _all
		mat full_tab3`panel' = (tab3`panel'1 \ /*Age - tab3`panel'2 \*/ ///
								tab3`panel'3 \ tab3`panel'4 \ tab3`panel'5)
		svmat2 full_tab3`panel', names(obsI allegationsI settlementI obsE allegationsE settlementE subtable) rnames(rowname)
		*Calculate %s of Total by subtable instead of overall // -------------------
		foreach col in "allegationsI" "settlementI" "allegationsE" "settlementE" {	
			bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
			gen pct = `col'/tot*100 // "% of Total"

			tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

			drop tot pct
		}
		* end %s of Total // -------------------------------------------------------
		order rowname obsI allegationsI allegationsI_pct_str settlementI settlementI_pct_str ///
					obsE allegationsE allegationsE_pct_str settlementE settlementE_pct_str
		replace rowname = "    " + rowname if ///
			!inlist(rowname, "Gender", "Age", "Rank", "Function", "Repeat_Whistleblowers", "Total")
		replace rowname = subinstr(rowname, "_", " ", .)
		
		tostring settlement?, replace force format(%9.1f)
			replace settlementI = "$" + settlementI if settlementI != "."
			replace settlementE = "$" + settlementE if settlementE != "."
			
		foreach var of varlist *_pct_str settlement? {
			replace `var' = "" if `var' == "."
		}
		drop obsE subtable
		export excel "$dropbox/draft_tables.xls", sheet("3.`panel'") sheetrep first(var)
	restore

} // loop through panels B & C
} // end Panel B

* ================================== TABLE 4 ================================== *
* Panel A
if `run_4A' == 1 | `run_all' == 1 {
*------------------------------------

* --- Firm Response to Allegation --- *
foreach var of varlist response_* {
	local response = substr("`var'", 10, .)
	gen stlmt_`response' = settlement * (`var' > 0)
}
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (sum) response_* stlmt*, fast
	ren response_* n* // for reshape
	gen i = _n
	reshape long n stlmt_, i(i) j(response) string
	egen obsP = total(n) // total observations not missing
	ren n allegationsP
	ren stlmt_ settlementP
	tempfile public4A1
	save `public4A1', replace
restore
preserve // -- now do left side of table, "All Firms"
	collapse (sum) response_* stlmt*, fast
	ren response_* n* // for reshape
	gen i = _n
	reshape long n stlmt_, i(i) j(response) string
	gsort -n
	egen obsA = total(n)
	ren n allegationsA
	ren stlmt_ settlementA
	merge 1:1 response using `public4A1', assert(3)
	gsort -allegationsA
		br
		*pause
		drop if allegationsA == .
	mkmat obsA allegationsA settlementA obsP allegationsP settlementP, mat(all) rownames(response)
restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/6 {
		local other_rows "`other_rows' ., all[`x',2..3], .,all[`x',5..6], 1" /* leave obs empty, fill in others */
		if `x' < 6 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab4A1 = (all[1,1], ., ., all[1,4], ., ., 1 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat list tab4A1
mat rownames tab4A1 = "Response_to_Allegation" "Ignored" "Unknown" "Cover_Up" "Internal_Investigation" ///
				"Dismissal/Retaliation" "Suspension"

* --- Firm Retaliation Against Whistleblower --- *
drop stlmt*
foreach var of varlist retaliation_* {
	local retaliation = substr("`var'", 13, .)
	gen stlmt_`retaliation' = settlement * (`var' > 0)
}
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (sum) retaliation_* stlmt*, fast
	ren retaliation_* n* // for reshape
	gen i = _n
	reshape long n stlmt_, i(i) j(retaliation) string
	egen obsP = total(n) // total observations not missing
	ren n allegationsP
	ren stlmt_ settlementP
	tempfile public4A2
	save `public4A2', replace
restore
preserve // -- now do left side of table, "All Firms"
	collapse (sum) retaliation_* stlmt*, fast
	ren retaliation_* n* // for reshape
	gen i = _n
	reshape long n stlmt_, i(i) j(retaliation) string
	gsort -n
	egen obsA = total(n)
	ren n allegationsA
	ren stlmt_ settlementA
	merge 1:1 retaliation using `public4A2', assert(3)
	gsort -allegationsA
		br
		*pause
	mkmat obsA allegationsA settlementA obsP allegationsP settlementP, mat(all) rownames(retaliation)
restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/7 {
		local other_rows "`other_rows' ., all[`x',2..3], .,all[`x',5..6], 2" /* leave obs empty, fill in others */
		if `x' < 7 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab4A2 = (all[1,1], ., ., all[1,4], ., ., 2 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat list tab4A2
mat rownames tab4A2 = "Retaliation_Against_WB" "Fired" "None" "Harassed" "Threat" "Quit" ///
				"Demotion" "Lawsuit"
*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab4A = (tab4A1 \ tab4A2)
	svmat2 full_tab4A, names(obsA allegationsA settlementA obsP allegationsP settlementP subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsA" "settlementA" "allegationsP" "settlementP" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
			// so the table can be pasted straight into word

		drop tot pct
	}
	* end %s of Total // -------------------------------------------------------
	order rowname obsA allegationsA allegationsA_pct_str settlementA settlementA_pct_str ///
				obsP allegationsP allegationsP_pct_str settlementP settlementP_pct_str
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Response_to_Allegation", "Retaliation_Against_WB")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	tostring settlementA, replace force format(%9.1f)
		replace settlementA = "$" + settlementA if settlementA != "."
	tostring settlementP, replace force format(%9.1f)
		replace settlementP = "$" + settlementP if settlementP != "."
		
	foreach var of varlist *_pct_str settlement? {
		replace `var' = "" if `var' == "."
	}
	drop obsP subtable
	export excel "$dropbox/draft_tables.xls", sheet("4.A") sheetrep first(var)
restore

} // end Panel A ---------------------------------------------------------------

* Panels B & C
if `run_4BC' == 1 | `run_all' == 1 {
*------------------------------------
foreach panel in "B" "C" { // --- These panels are nearly identical, just drop private firms for C

	if "`panel'" == "C" drop if public_firm != 1

* --- Firm Response to Allegation --- *
	cap drop stlmt_*
	foreach var of varlist response_* {
		local response = substr("`var'", 10, .)
		gen stlmt_`response' = settlement * (`var' > 0)
	}
	preserve // -- first do Upper Management
		keep if mgmt_class == "Upper"
		collapse (sum) response_* stlmt*, fast
		ren response_* n* // for reshape
		gen i = _n
		reshape long n stlmt_, i(i) j(response) string
		egen obsU = total(n) // total observations not missing
		ren n allegationsU
		ren stlmt_ settlementU
		tempfile public4`panel'1U
		save `public4`panel'1U', replace
	restore
	preserve // -- now do Middle Management
		keep if mgmt_class == "Middle"
		collapse (sum) response_* stlmt*, fast
		ren response_* n* // for reshape
		gen i = _n
		reshape long n stlmt_, i(i) j(response) string
		egen obsM = total(n) // total observations not missing
		ren n allegationsM
		ren stlmt_ settlementM
		tempfile public4`panel'1M
		save `public4`panel'1M', replace
	restore
	preserve // -- now do Rank & File
		keep if mgmt_class == "Lower"
		collapse (sum) response_* stlmt*, fast
		ren response_* n* // for reshape
		gen i = _n
		reshape long n stlmt_, i(i) j(response) string
		egen obsL = total(n) // total observations not missing
		ren n allegationsL
		ren stlmt_ settlementL
		merge 1:1 response using `public4`panel'1M', assert(3) nogen
		merge 1:1 response using `public4`panel'1U', assert(3) nogen
		gsort -allegationsL -allegationsM -allegationsU
			br
			*pause
		mkmat obsL allegationsL settlementL ///
				obsM allegationsM settlementM ///
				obsU allegationsU settlementU, mat(all) rownames(response)
	restore

	*store local string to input other all[] rows into the tab3 matrix
		local other_rows ""
		forval x=1/6 {
			local other_rows "`other_rows' ., all[`x',2..3], .,all[`x',5..6], ., all[`x',8..9], 1" /* leave obs empty, fill in others */
			if `x' < 6 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab4`panel'1 = (all[1,1], ., ., all[1,4], ., ., all[1,7], ., ., 1 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat list tab4`panel'1
	if "`panel'" == "B" {
		mat rownames tab4`panel'1 = "Response_to_Allegation" "Ignored" "Unknown" "Cover_Up" ///
						"Internal_Investigation" "Suspension" "Dismissal/Retaliation"  
	}
	if "`panel'" == "C" {
		mat rownames tab4`panel'1 = "Response_to_Allegation" "Ignored" "Cover_Up" "Unknown" ///
						"Internal_Investigation" "Suspension" "Dismissal/Retaliation" 
	}

* --- Firm Retaliation Against Whistleblower --- *
	drop stlmt*
	foreach var of varlist retaliation_* {
		local retaliation = substr("`var'", 13, .)
		gen stlmt_`retaliation' = settlement * (`var' > 0)
	}
	preserve // -- first do Upper Management
		keep if mgmt_class == "Upper"
		collapse (sum) retaliation_* stlmt*, fast
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n stlmt_, i(i) j(retaliation) string
		egen obsU = total(n) // total observations not missing
		ren n allegationsU
		ren stlmt_ settlementU
		tempfile public4`panel'2U
		save `public4`panel'2U', replace
	restore
	preserve // -- now do Middle Management
		keep if mgmt_class == "Middle"
		collapse (sum) retaliation_* stlmt*, fast
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n stlmt_, i(i) j(retaliation) string
		egen obsM = total(n) // total observations not missing
		ren n allegationsM
		ren stlmt_ settlementM
		tempfile public4`panel'2M
		save `public4`panel'2M', replace
	restore
	preserve // -- now do Rank & File
		keep if mgmt_class == "Lower"
		collapse (sum) retaliation_* stlmt*, fast
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n stlmt_, i(i) j(retaliation) string
		egen obsL = total(n) // total observations not missing
		ren n allegationsL
		ren stlmt_ settlementL
		merge 1:1 retaliation using `public4`panel'2M', assert(3) nogen
		merge 1:1 retaliation using `public4`panel'2U', assert(3) nogen
		gsort -allegationsL -allegationsM -allegationsU
			br
			*pause
		mkmat obsL allegationsL settlementL ///
				obsM allegationsM settlementM ///
				obsU allegationsU settlementU, mat(all) rownames(retaliation)
	restore

	*store local string to input other all[] rows into the tab3 matrix
		local other_rows ""
		forval x=1/7 {
			local other_rows "`other_rows' ., all[`x',2..3], .,all[`x',5..6], ., all[`x',8..9], 2" /* leave obs empty, fill in others */
			if `x' < 7 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab4`panel'2 = (all[1,1], ., ., all[1,4], ., ., all[1,7], ., ., 2 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat list tab4`panel'2
	mat rownames tab4`panel'2 = "Retaliation_Against_WB" "Fired" "None" "Harassed" "Threat" ///
					"Quit" "Demotion" "Lawsuit"
*--------------------------------------------
* Now export to excel workbook
	preserve
		drop _all
		mat full_tab4`panel' = (tab4`panel'1 \ tab4`panel'2)
		svmat2 full_tab4`panel', names(obsL allegationsL settlementL ///
										obsM allegationsM settlementM ///
										obsU allegationsU settlementU subtable) rnames(rowname)
		*Calculate %s of Total by subtable instead of overall // -------------------
		foreach col in "allegationsL" "settlementL" ///
						"allegationsM" "settlementM" ///
						"allegationsU" "settlementU" {	
			bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
			gen pct = `col'/tot*100 // "% of Total"

			tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
				// so the table can be pasted straight into word

			drop tot pct
		}
		* end %s of Total // -------------------------------------------------------
		order rowname obsL allegationsL allegationsL_pct_str settlementL settlementL_pct_str ///
					obsM allegationsM allegationsM_pct_str settlementM settlementM_pct_str ///
					obsU allegationsU allegationsU_pct_str settlementU settlementU_pct_str
		replace rowname = "    " + rowname if ///
			!inlist(rowname, "Response_to_Allegation", "Retaliation_Against_WB")
		replace rowname = subinstr(rowname, "_", " ", .)
		
		tostring settlement?, replace force format(%9.1f)
			replace settlementL = "$" + settlementL if settlementL != "."
			replace settlementM = "$" + settlementM if settlementM != "."
			replace settlementU = "$" + settlementU if settlementU != "."
			
		foreach var of varlist *_pct_str settlement? {
			replace `var' = "" if `var' == "."
		}
		drop obsM obsU subtable
		export excel "$dropbox/draft_tables.xls", sheet("4.`panel'") sheetrep first(var)
	restore
} // end panel loop
} // end Panels B & C ----------------------------------------------------------

* ================================== TABLE 5 ================================== *
if `run_5' == 1 | `run_all' == 1 {
*------------------------------------
include "$repo/FamaFrench12.do"

tab famafrench12, matcell(m5c2) matrow(m5c1)
mat m5 = (m5c1, m5c2)
	mat list m5

preserve
drop _all
svmat2 m5, names(industry allegations)
	assert industry != 8
	set obs 12
	replace industry = 8 if industry == .
	replace allegations = 0 if allegations == .
	sort industry

	local leftcol "industry" // need to set these locals for add_total_row_and_pct_col_to_table.do
	local tab_cols "allegations" // the columns you need to calculate "% of total" for
	include "$repo/add_total_row_and_pct_col_to_table.do"

export excel "$dropbox/draft_tables.xls", sheet("5") sheetrep first(var)
restore
}