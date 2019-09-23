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
local run_1E 0
local run_1F 1
local run_2 0
local run_3A 0
local run_3B 0
local run_3CD 0
local run_4A 0
local run_4BC 0
local run_4DEF 0
local run_all 0
local run_4BOld 0
local run_3ANew 0
*---------------------------
global name dyu
*global name lmostrom

cap cd "C:\Users\$name\Dropbox\Violation paper\whistleblower paper\"


*-------------------------------------------------------------------------------
local wd: pwd // saves local of current working directory, C:\Users\[]
if substr("`wd'", 10, 2) == "lm" { // if on Lauren's computer
		include "C:/Users/lmostrom/Documents/GitHub/whistleblower_paper/assign_global_filepaths.do"
}
if substr("`wd'", 10, 2) == "dy" { // if on Dolly's computer
	include "C:/Users/dyu/Desktop/whistleblower_paper/assign_global_filepaths.do"
}

include "$repo/wb_data_clean.do"

	egen wb_id = group(wb_full_name)
	egen alleg_id = group(wb_full_name caption)
*-------------------------------------------------------------------------------
* ================================== TABLE 1 ================================== *
* Panel A
if `run_1A' == 1 | `run_all' == 1 {
*------------------------------------
preserve // -- Load in full QTRACK FOIA Request dataset
	import excel "$dropbox/QTRACK_FOIA_Request_060313.xls", first case(lower) clear
	keep caption relator_name
	egen tag_caption = tag(caption)
	egen tag_rel = tag(relator_name)
	egen tag_alleg = tag(caption relator_name)
	tab tag_caption, subpop(tag_caption)
		local N_case = `r(N)'
	tab tag_rel, subpop(tag_rel)
		local N_wb = `r(N)'
	tab tag_alleg, subpop(tag_alleg)
		local N_alleg = `r(N)'

	mat A = (`N_case', ., `N_wb', `N_alleg') // full sample of allegations, first row of table
restore

*Initiate second row
mat A = (A \ 0, 0, 0, 0)

*Third row
foreach col in caption wb_id alleg_id {
	preserve
		egen tag_`col' = tag(`col')
		collapse (sum) tag_`col'
			local N_`col': dis tag_`col' // number of unique cases, firms, or whistleblowers
	restore
}

	preserve // -- Counting unique firms ---
		keep caption
			duplicates drop
		*Split caption to pull out all firm names & count unique firms
		split caption, gen(capsplit) p(" v ") // pull list of defendants out of caption
			gen def_pos = strpos(capsplit1, " v. ") + 4 if capsplit2 == ""
			replace capsplit2 = substr(capsplit1, def_pos, .) if def_pos > 4 & def_pos != . // i.e. strpos > 0
		split capsplit2, gen(defendant) p("; ") // separate multiple defendants
		reshape long defendant, i(caption) j(j)
			drop if defendant == ""
		replace defendant = upper(defendant) // in case upper/lower case differences
		drop if strpos(defendant, ", ") > 0 // probably a person
		egen tag_firm = tag(defendant)
		collapse (sum) tag_firm
			local N_firms: dis tag_firm
	restore // ------------------------------

mat A = (A \ `N_caption', `N_firms', `N_wb_id', `N_alleg_id')

*Replace second row as difference between rows 1 and 3
	forval j = 1/4 { // loop through columns 1-4
		mat A[2,`j'] = A[1,`j'] - A[3,`j'] 
			// less cases without court filings
	}
	
local i = 5 // going to refer to row 6
foreach if_st in "if internal == 1" /* less external whistleblowers */ ///
				 "if internal == 1 & gvkey != ." /* less private firms */ ///
				 "if internal == 1 & gvkey != . & at != . & roacurrent != . & lev != ." /* less missing from Compustat*/  {
	foreach col in caption wb_id alleg_id { 
		if "`col'" == "caption" local a = 1 // column numbers for matrix
		if "`col'" == "wb_id" local a = 3
		if "`col'" == "alleg_id" local a = 4

		preserve
			keep `if_st'
			egen tag_`col' = tag(`col')
			collapse (sum) tag_`col'
				local N`a': dis tag_`col'
		restore
	}
	if `i' == 5 {
		preserve // -- Counting unique firms ---
			keep `if_st'
				keep caption
				duplicates drop
			*Split caption to pull out all firm names & count unique firms
			split caption, gen(capsplit) p(" v ") // pull list of defendants out of caption
				gen def_pos = strpos(capsplit1, " v. ") + 4 if capsplit2 == ""
				replace capsplit2 = substr(capsplit1, def_pos, .) if def_pos > 4 & def_pos != . // i.e. strpos > 0
			split capsplit2, gen(defendant) p("; ") // separate multiple defendants
			reshape long defendant, i(caption) j(j)
				drop if defendant == ""
			replace defendant = upper(defendant) // in case upper/lower case differences
			drop if strpos(defendant, ", ") > 0 // probably a person
			egen tag_firm = tag(defendant)
			collapse (sum) tag_firm
				local N2: dis tag_firm
		restore // -----------------------------
	}
	if inlist(`i',7,9) {
		preserve
			keep `if_st'
			egen tag_gvkey = tag(gvkey)
			collapse (sum) tag_gvkey
				local N2: dis tag_gvkey
		restore
	}

	mat A = (A \ 0, 0, 0, 0) // add empty row for "sample used for Tables X-Y" to be filled in
	local i_2 = `i' - 2 // row number 2 rows up
	local i_1 = `i' - 1 // row number 1 row up
	
	forval j = 1/4 { // loop through columns 1-3
		mat A[`i_1',`j'] = A[`i_2',`j'] - `N`j''
			// sample used for Tables X-Y = (previous sample size) - (less [...] sample size)
	}

	mat A = (A \ `N1', `N2', `N3', `N4') // add row for "less [...]"
	
	local i = `i' + 2 // do this 2 more rows down next time
}

preserve
	drop _all // clear dataset in memory but keep matrices saved in memory
	svmat2 A, names(cases unique_firms unique_wbs unique_allegations) // load matrix A in as a dataset
		foreach var in cases unique_firms unique_wbs unique_allegations {
			tostring `var', force replace
			replace `var' = "(" + `var' + ")" if _n == 2 | _n == 4 | _n == 6 | _n == 8
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
	codebook wb_id
	collapse (count) cases = case_id (mean) settled avg_settlement = settlement ///
			 (sum) tot_settlements = settlement, by(wb_type) fast
	gsort -cases
		local leftcol "wb_type" // need to set these locals for add_total_row_and_pct_col_to_table.do
		local tab_cols "cases" // the columns you need to calculate "% of total" for
		include "$repo/add_total_row_and_pct_col_to_table.do"
		tostring avg_settlement tot_settlements, replace force format(%9.1f)
		replace settled = settled * 100
		tostring settled, replace force format(%9.1f)
		replace avg_settlement = "$" + avg_settlement
			replace avg_settlement = "" if avg_settlement == "$."
		replace tot_settlements = "$" + tot_settlements
		replace settled = settled + "%"
			replace settled = "" if settled == ".%"
		order wb_type cases cases_pct_str settled avg_settlement tot_settlements
	export excel "$dropbox/draft_tables.xls", sheet("1.B") sheetrep first(var)
restore
} // end Panel B ---------------------------------------------------------------

*------------------------------------
* Panel C
if `run_1C' == 1 | `run_all' == 1 {
*------------------------------------
preserve
	keep if internal == 1 & gvkey != .
	egen tag_caption = tag(caption)
	tab fyear if tag_caption, matcell(C) matrow(rC)
	mat C = (rC, C)
	drop _all
	svmat2 C, names(year pub_cases)
	tempfile pub 
	save `pub', replace 
restore 
preserve 
	keep if internal == 1 
	egen tag_caption = tag(caption) 
	tab fyear if tag_caption, matcell(C) matrow(rC) 
	mat C = (rC, C) 
	drop _all 
	svmat2 C, names(year all_cases) 
	merge 1:1 year using `pub', nogen assert(1 3)
		local leftcol "year"  // need to set these locals for add_total_row_and_pct_col_to_table.do
		local tab_cols "all_cases pub_cases" // the column you need to calculate "% of total" for
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
		egen tag_caption = tag(caption)
	merge m:1 caption using "$dropbox/gov_agencies_from_qtrack.dta", nogen keep(1 3) keepus(primary_agency)
	include "$repo/replace_agency_names.do"
	collapse (sum) pub_cases = tag_caption /*unique_firms = tag_gvkey unique_wbs = tag_wb_id*/ ///
		, by(primary_agency) fast
	g byte nonmiss = primary_agency != "Unknown"
	assert pub_cases != 0
	tempfile pub
	save `pub', replace
restore
preserve
	keep if internal == 1
		egen tag_caption = tag(caption)
	merge m:1 caption using "$dropbox/gov_agencies_from_qtrack.dta", nogen keep(1 3) keepus(primary_agency)
	include "$repo/replace_agency_names.do"
	collapse (sum) all_cases = tag_caption /*unique_firms = tag_gvkey unique_wbs = tag_wb_id*/ ///
		, by(primary_agency) fast
	g byte nonmiss = primary_agency != "Unknown"
	assert all_cases != 0
	merge 1:1 primary_agency using `pub', nogen
	gsort -nonmiss -all_cases -pub_cases
		drop nonmiss
		local leftcol "primary_agency" // need to set these locals for add_total_row_and_pct_col_to_table.do
		local tab_cols "all_cases pub_cases" // the column you need to calculate "% of total" for
		include "$repo/add_total_row_and_pct_col_to_table.do"
	export excel "$dropbox/draft_tables.xls", sheet("1.D") sheetrep first(var)
restore
} // end Panel D ---------------------------------------------------------------

*------------------------------------
* Panel E
if `run_1E' == 1 | `run_all' == 1 {
*------------------------------------
include "$repo/FamaFrench12.do"
include "$repo/assign_missing_famafrench.do"

preserve
bys gvkey: ereplace famafrench12 = mode(famafrench12)
keep if internal == 1 & gvkey != .
	egen tag_firm = tag(gvkey)
	egen tag_law = tag(caption)
collapse (sum) tag_firm tag_law, by(famafrench12)
mkmat famafrench12 tag_firm tag_law, mat(ff)

drop _all
svmat2 ff, names(industry firms lawsuits)
	assert industry != 8
	set obs 12
	replace industry = 8 if industry == .
	replace firms = 0 if firms == .
	replace lawsuits = 0 if lawsuits == .
	sort industry

	local leftcol "industry" // need to set these locals for add_total_row_and_pct_col_to_table.do
	local tab_cols "firms lawsuits" // the columns you need to calculate "% of total" for
	include "$repo/add_total_row_and_pct_col_to_table.do"

export excel "$dropbox/draft_tables.xls", sheet("1.E") sheetrep first(var)
restore
} // end Panel E ---------------------------------------------------------------

*------------------------------------
* Panel F
if `run_1F' == 1 | `run_all' == 1 {
*------------------------------------
preserve
keep if internal == 1 & gvkey != .
egen tag_firmyr = tag(gvkey fyear)
keep if tag_firm
keep gvkey fyear at roacurrent lev aqc
tempfile sample
save `sample', replace

use gvkey fyear at ni dltt aqc indfmt consol popsrc datafmt ///
		if indfmt == "INDL" & consol == "C" & popsrc == "D" & datafmt == "STD" ///
			& inrange(fyear, 1994, 2012) using "$dropbox/../../Compustat.dta", clear
isid gvkey fyear

gen roacurrent = ni/at*100
gen lev = dltt/at
drop ni dltt indfmt consol popsrc datafmt
destring gvkey, replace
drop if gvkey == . | fyear == .

append using `sample', keep(gvkey fyear at roacurrent lev aqc) gen(sample)

duplicates tag gvkey fyear, gen(dup)
drop if dup > 0 & sample == 0

isid gvkey fyear

mat tab1F = (., ., ., ., ., ., .)
foreach var of varlist fyear at roacurrent lev aqc {
	summ `var' if sample == 1, d
	ttest `var', by(sample)
	mat tab1F = (tab1F \ r(mean), r(t), r(min), r(p25), r(p50), r(p75), r(max))

	summ `var' if sample == 1, d
	mat tab1F = (tab1F \ r(mean), ., r(min), r(p25), r(p50), r(p75), r(max))
}

drop _all
mat rownames tab1F = "Variable" "Year" "Year" "Total_Assets" "Total_Assets" ///
					"ROA" "ROA" "Leverage" "Leverage" "Acquisitions" "Acquisitions"
svmat2 tab1F, names(mean t_stat min p25 p50 p75 max) rnames(rowname)
replace rowname = subinstr(rowname, "_", " ", .)

order rowname mean t_stat min p25 p50 p75 max
gsort rowname -t_stat
tostring mean min p25 p50 p75 max, replace format(%9.2f)
tostring t_stat, replace format(%9.4f)

foreach var of varlist mean min p25 p50 p75 max {
	replace `var' = "$" + `var' if rowname == "Total Assets"
	replace `var' = "%" + `var' if rowname == "ROA"
}


export excel "$dropbox/draft_tables.xls", sheet("1.F") sheetrep first(var)

restore

} // end Panel F ---------------------------------------------------------------

keep if internal == 1
	gen missing_job_title = job_title == ""
	bys wb_id (received_date): gen repeat_wb_all = _N > 1
	bys wb_id (received_date): gen repeat_wb_not1st = _n > 1

* ================================== TABLE 2 ================================== *
if `run_2' == 1 | `run_all' == 1 {
*------------------------------------
codebook wb_id
codebook case_id


* --- Male --- *
preserve // -- first do left side of table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlement=settlement, by(male)
	ren male male_int
	decode male_int, gen(male) // need string for row names
	egen obsA = total(allegations) // total observations not missing gender

	ren allegations allegationsA
	ren settlement settlementA
	ren settled settledA
		replace settledA = settledA * 100
	ren ave_settlement ave_settlementA
	mkmat obsA allegationsA settledA ave_settlementA settlementA, mat(all) rownames(male)
restore
preserve // -- now do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement (mean)settled ave_settlement=settlement, by(male)
	ren allegations allegationsP
	ren settlement settlementP
	ren settled settledP
		replace settledP = settledP * 100
	ren ave_settlement ave_settlementP
	egen obsP = total(allegationsP)
	mkmat obsP allegationsP settledP ave_settlementP settlementP, mat(public) // don't need row names because
								// this matrix is being appended to the right of the all matrix
restore

mat tab2A = (all[1,1], ., ., ., ., public[1,1], ., ., ., ., 1 \ /* put total non-missing obs on first line only, not under either gender */ ///
			., all[1,2..5], ., public[1,2..5],  1 \ /* leave obs empty, fill in allegations and settlements columns */ ///
			., all[2,2..5], ., public[2,2..5],  1)    /* leave obs empty, fill in allegations and settlements columns */
mat rownames tab2A = "Gender" "Female" "Male"
mat list tab2A // just to view so it looks right

* --- Management Rank --- *
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlement = settlement, by(mgmt_class missing_job_title)
	ren allegations allegationsP
	ren settlement settlementP
	ren settled settledP
		replace settledP = settledP * 100
	ren ave_settlement ave_settlementP
	egen obsP = total(allegationsP)
	tempfile public2C
	save `public2C', replace
restore
preserve // -- now do left side of table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlement = settlement, by(mgmt_class missing_job_title)
	egen obsA = total(allegations)
	ren allegations allegationsA
	ren settlement settlementA
	ren settled settledA
		replace settledA = settledA * 100
	ren ave_settlement ave_settlementA
	merge 1:1 mgmt_class using `public2C', assert(1 3)
	sort missing_job_title mgmt_class
		*br
		*pause
	mkmat obsA allegationsA settledA ave_settlementA settlementA ///
			obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(mgmt_class)
restore


*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/4 {
		local other_rows "`other_rows' ., all[`x',2..5], ., all[`x',7..10], 3" /* leave obs empty, fill in others */
		if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab2C = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 3 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat rownames tab2C = "Rank" "Rank_and_File" "Middle_Management" "Upper_Management" "No_Job_Title"
mat list tab2C


* --- Function --- *
preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlement = settlement, by(wb_function missing_job_title)
	ren allegations allegationsP
	ren settlement settlementP
	ren settled settledP
		replace settledP = settledP*100
	ren ave_settlement ave_settlementP
	egen obsP = total(allegationsP)
	tempfile public2D
	save `public2D', replace
restore
preserve // now do the left side of the table, "All Firms"
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlement = settlement, by(wb_function missing_job_title)
	merge 1:1 wb_function using `public2D', assert(1 3)
	egen obsA = total(allegations)
	ren allegations allegationsA
	ren settlement settlementA
	ren settled settledA
		replace settledA = settledA * 100
	ren ave_settlement ave_settlementA
	gsort missing_job_title -allegationsA -allegationsP
		*br
		*pause // to know what order row names should go in
	mkmat obsA allegationsA settledA ave_settlementA settlementA ///
			obsP allegationsP settledA ave_settlementP settlementP, mat(all) rownames(wb_function)
restore


*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/4 {
		local other_rows "`other_rows' ., all[`x',2..5], ., all[`x',7..10], 4" /* leave obs empty, fill in others */
		if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab2D = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 4 \  /* put total non-missing obs on first line only */ ///
			`other_rows')
mat rownames tab2D = "Function" "Operations" "Finance/Accounting" ///
						"Legal/Compliance" "No_Job_Title"
mat list tab2D



* --- Repeat Whistleblower --- *
preserve
	replace repeat_wb_all = 0 if  inlist(wb_full_name, "Doe, John", "Doe, Jane")
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlement=settlement, by(repeat_wb_all)
	egen obsA = total(allegations)
	ren allegations allegationsA
	ren settlement settlementA
	ren settled settledA
		replace settledA = settledA * 100
	ren ave_settlement ave_settlementA
	mkmat obsA allegationsA settledA ave_settlementA settlementA, mat(all) rownames(repeat_wb_all)
restore
preserve // -- now do right side of table, "Public Firms"
	replace repeat_wb_all = 0 if  inlist(wb_full_name, "Doe, John", "Doe, Jane")
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement (mean)settled ave_settlement=settlement, by(repeat_wb_all)
	ren allegations allegationsP
	ren settlement settlementP
	ren settled settledP
		replace settledP = settledP * 100
	ren ave_settlement ave_settlementP
	egen obsP = total(allegationsP)
	mkmat obsP allegationsP settledP ave_settlementP settlementP, mat(public)
restore

*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/2 {
		local other_rows "`other_rows' ., all[`x',2..5], ., public[`x',2..5], 5" /* leave obs empty, fill in others */
		if `x' < 2 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab2E = (all[1,1], ., ., ., ., public[1,1], ., ., ., ., 5 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat rownames tab2E = "Repeat_Whistleblowers" "1_Allegation_Only" "Multiple_Allegations"
mat list tab2E

*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab2 = (tab2A \ /*Age - tab2B \ */ tab2C \ tab2D \ tab2E)
	svmat2 full_tab2, names(obsA allegationsA settledA ave_settlementA settlementA ///
							obsP allegationsP settledP ave_settlementP settlementP subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsA" "allegationsP" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

		drop tot pct
	}
	foreach col of varlist settled? {
		tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
		drop `col'
	}
	* end %s of Total // -------------------------------------------------------
	order rowname obsA allegationsA allegationsA_pct_str settledA_pct_str ave_settlementA settlementA ///
				obsP allegationsP allegationsP_pct_str settledP_pct_str ave_settlementP settlementP
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Gender", "Age", "Rank", "Function", "Repeat_Whistleblowers", "Total")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	tostring settlementA, replace force format(%9.1f)
		replace settlementA = "$" + settlementA if settlementA != "."
	tostring settlementP, replace force format(%9.1f)
		replace settlementP = "$" + settlementP if settlementP != "."
	
	tostring ave_settlementA, replace force format(%9.1f)
		replace ave_settlementA = "$" + ave_settlementA if ave_settlementA != "."
	tostring ave_settlementP, replace force format(%9.1f)
		replace ave_settlementP = "$" + ave_settlementP if ave_settlementP != "."

	foreach var of varlist *_pct_str settlement? ave_settlement* {
		replace `var' = "" if `var' == "."
	}
	drop subtable
	export excel "$dropbox/draft_tables.xls", sheet("2") sheetrep first(var)
restore
} // end Table 2 ---------------------------------------------------------------	

* ================================== TABLE 3 ================================== *
* Panel A
if `run_3A' == 1 | `run_all' == 1 {
*------------------------------------
* --- Raised issue internally --- *
preserve // -- first do left side of table, "All Firms"
	collapse (count) allegations = case_id (mean) settled ave_settlementA = settlement (sum) settlement, by(wb_raised_issue_internally)
		assert wb_raised_issue_internally != ""
	egen obsA = total(allegations) // total observations
	ren allegations allegationsA
	ren settlement settlementA
	ren settled settledA
		replace settledA = settledA * 100
	mkmat obsA allegationsA settledA ave_settlementA settlementA, mat(all) rownames(wb_raised_issue_internally)
restore
preserve // -- now do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (count) allegations = case_id (mean) settled ave_settlementP = settlement (sum) settlement, by(wb_raised_issue_internally)
	drop if wb_raised_issue_internally == ""
	ren allegations allegationsP
	ren settlement settlementP
	ren settled settledP
		replace settledP = settledP * 100
	egen obsP = total(allegationsP)
	mkmat obsP allegationsP settledP ave_settlementP settlementP, mat(public) // don't need row names because
								// this matrix is being appended to the right of the all matrix
restore

mat tab3A1 = (all[1,1], ., ., ., ., public[1,1], ., ., ., ., 1 \ /* put total non-missing obs on first line only, not under either gender */ ///
			., all[1,2..5], ., public[1,2..5],  1 \ /* leave obs empty, fill in allegations and settlements columns */ ///
			., all[2,2..5], ., public[2,2..5],  1)    /* leave obs empty, fill in allegations and settlements columns */
mat rownames tab3A1 = "Reported_Internally_First" "No" "Yes"
mat list tab3A1 // just to view so it looks right

* --- Number of Internal Channels --- *
preserve // -- first do left side of table, "All Firms"
	keep if internal == 1 & wb_raised_issue_internally == "YES"
	replace n_reports = 3 if n_reports >= 3
	collapse (count) allegations = case_id (mean) settled ave_settlementA = settlement (sum) settlement, by(n_reports)
	egen obsA = total(allegations) // total observations
	ren allegations allegationsA
	ren settlement settlementA
	ren settled settledA
		replace settledA = settledA * 100
	mkmat obsA allegationsA settledA ave_settlementA settlementA, mat(all) rownames(n_reports)
restore
preserve // -- now do right side of table, "Public Firms"
	keep if internal == 1 & wb_raised_issue_internally == "YES"
	replace n_reports = 3 if n_reports >= 3
	keep if gvkey != .
	collapse (count) allegations = case_id (mean) settled ave_settlementP = settlement (sum) settlement, by(n_reports)
	ren allegations allegationsP
	ren settlement settlementP
	ren settled settledP
		replace settledP = settledP * 100
	egen obsP = total(allegationsP)
	mkmat obsP allegationsP settledP ave_settlementP settlementP, mat(public) // don't need row names because
								// this matrix is being appended to the right of the all matrix
restore

mat tab3A2 = (all[1,1], ., ., ., ., public[1,1], ., ., ., ., 2 \ /* put total non-missing obs on first line only, not under either gender */ ///
			., all[1,2..5], ., public[1,2..5],  2 \ /* leave obs empty, fill in allegations and settlements columns */ ///
			., all[2,2..5], ., public[2,2..5],  2 \ ///
			., all[3,2..5], ., public[3,2..5],  2 \ ///
			., all[4,2..5], ., public[4,2..5],  2)
mat rownames tab3A2 = "Number_of_Reported_Channels" "Unknown" "One" "Two" "Three_or_More"
mat list tab3A2 // just to view so it looks right

* --- Reasons for Not Reporting --- *
preserve // -- first do right side of table, "Public Firms"
	keep if internal == 1 & wb_raised_issue_internally == "NO"
	keep if gvkey != .
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlementP = settlement, by(reason_not_raised_internally)
	ren allegations allegationsP
	ren settlement settlementP
	ren settled settledP
		replace settledP = settledP*100
	egen obsP = total(allegationsP)
	tempfile public3A3
	save `public3A3', replace
restore
preserve // now do the left side of the table, "All Firms"
	keep if internal == 1 & wb_raised_issue_internally == "NO"
	collapse (count) allegations = case_id (sum) settlement (mean) settled ave_settlementA = settlement, by(reason_not_raised_internally)
	merge 1:1 reason_not_raised_internally using `public3A3', assert(1 3)
	egen obsA = total(allegations)
	ren allegations allegationsA
	ren settlement settlementA
	ren settled settledA
		replace settledA = settledA * 100
	gsort -allegationsA -allegationsP
		*br
		*pause // to know what order row names should go in
	mkmat obsA allegationsA settledA ave_settlementA settlementA obsP allegationsP settledP ave_settlementP settlementP, ///
				mat(all) rownames(reason_not_raised_internally)
restore

*store local string to input other all[] and public[] rows into the tab2 matrix
	local other_rows ""
	forval x=1/4 {
		local other_rows "`other_rows' ., all[`x',2..5], ., all[`x',7..10], 4" /* leave obs empty, fill in others */
		if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab3A3 = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 4 \  /* put total non-missing obs on first line only */ ///
			`other_rows')
mat rownames tab3A3 = "Reasons_for_Not_Reporting" "No_Information" "Fear_of_Retaliation" ///
						"Supervisors_Involved" "External_Parties_Already_Knew"
mat list tab3A3

*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab3A = (tab3A1 \ tab3A2 \ tab3A3)
	svmat2 full_tab3A, names(obsA allegationsA settledA ave_settlementA settlementA ///
							 obsP allegationsP settledP ave_settlementP settlementP subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsA" "allegationsP" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

		drop tot pct
	}
	foreach col of varlist settled? {
		tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
		drop `col'
	}
	* end %s of Total // -------------------------------------------------------
	order rowname obsA allegationsA allegationsA_pct_str settledA_pct_str ave_settlementA settlementA ///
				obsP allegationsP allegationsP_pct_str settledP_pct_str ave_settlementP settlementP
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Reported_Internally_First", "Number_of_Reported_Channels", "Reasons_for_Not_Reporting")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	foreach var in ave_settlementA settlementA ave_settlementP settlementP {
		tostring `var', replace force format(%9.1f)
			replace `var' = "$" + `var' if `var' != "."
	}
	
	foreach var of varlist *_pct_str *settlement? {
		replace `var' = "" if `var' == "."
	}
	drop subtable
	export excel "$dropbox/draft_tables.xls", sheet("3.A") sheetrep first(var)
restore
} // end Panel A ---------------------------------------------------------------

*Table 3A settled vs not settled 

if `run_3ANew' == 1 | `run_all' == 1{
	foreach subpanel in "a" "b" {       //bascially same panels for all/public
		preserve // -- first do right side of table, "settled"
			if "`subpanel'" == "b" keep if gvkey !=. 
			keep if internal == 1 & settled == 1
			collapse (count) allegations = case_id (mean) ave_settlementS = settlement (sum) settlement, by(wb_raised_issue_internally)
			assert wb_raised_issue_internally != ""
			egen obsS = total(allegations) // total observations
			ren allegations allegationsS
			ren settlement settlementS
			mkmat obsS allegationsS ave_settlementS settlementS, mat(settled)
			mat list settled
		restore
		preserve // -- now do left side of table, "not settled"
			if "`subpanel'" == "b" keep if gvkey !=.
			keep if settled == 0
			collapse (count) allegations = case_id, by(wb_raised_issue_internally)
			drop if wb_raised_issue_internally == ""
			ren allegations allegationsNS
			egen obsNS = total(allegations)
			mkmat obsNS allegationsNS, mat(not_settled) // don't need row names because
										// this matrix is being appended to the right of the all matrix
		restore
		preserve
			if "`subpanel'" == "b" keep if gvkey !=. 
			collapse (count) allegationsA = case_id (mean) settled, by(wb_raised_issue_internally)
			drop if wb_raised_issue_internally == ""
			egen obsA = total(allegationsA)
			ren settled settledA
				replace settledA = settledA * 100
			mkmat obsA settledA, mat(all)  rownames(wb_raised_issue_internally)
		restore
		mat tab3A`subpanel'1 = (all[1,1], ., not_settled[1,1], ., settled[1,1], ., ., ., 1\ /* put total non-missing obs on first line only, not under either gender */ ///
					., all[1,2], ., not_settled[1,2], ., settled[1,2..4],  1 \ /* leave obs empty, fill in allegations and settlements columns */ ///
					., all[2,2], ., not_settled[2,2], ., settled[2,2..4],  1)    /* leave obs empty, fill in allegations and settlements columns */
		mat rownames tab3A`subpanel'1 = "Reported_Internally_First" "No" "Yes"
		mat list tab3A`subpanel'1 // just to view so it looks right

		* --- Number of Internal Channels --- *
		preserve // -- first do right side of table, "Settled"
			if "`subpanel'" == "b" keep if gvkey != .
			keep if internal == 1 & wb_raised_issue_internally == "YES" & settled == 1
			replace n_reports = 3 if n_reports >= 3
			collapse (count) allegations = case_id (mean) ave_settlementS = settlement (sum) settlement, by(n_reports)
			egen obsS = total(allegations) // total observations
			ren allegations allegationsS
			ren settlement settlementS
			mkmat obsS allegationsS ave_settlementS settlementS, mat(settled)
		restore
		preserve // -- now do middle section of table, "Not settled"
			if "`subpanel'" == "b" keep if gvkey !=.
			keep if internal == 1 & wb_raised_issue_internally == "YES" & settled == 0
			replace n_reports = 3 if n_reports >= 3.
			collapse (count) allegations = case_id, by(n_reports)
			ren allegations allegationsNS
			egen obsNS = total(allegationsNS)
			mkmat obsNS allegationsNS, mat(not_settled) // don't need row names because
										// this matrix is being appended to the right of the all matrix
		restore
		preserve
			if "`subpanel'" == "b" keep if gvkey !=.
			collapse (count) allegationsA = case_id (mean) settled, by(n_reports)
			egen obsA = total(allegationsA)
			ren settled settledA
				replace settledA = settledA * 100
			mkmat obsA settledA, mat(all) rownames(n_reports)
		restore
		mat tab3A`subpanel'2 = (all[1,1], ., not_settled[1,1], ., settled[1,1], ., ., ., 2 \ /* put total non-missing obs on first line only, not under either gender */ ///
					., all[1,2], ., not_settled[1,2],., settled[1,2..4], 2 \ /* leave obs empty, fill in allegations and settlements columns */ ///
					., all[2,2], ., not_settled[2,2],., settled[2,2..4], 2 \ ///
					., all[3,2], ., not_settled[3,2],., settled[3,2..4], 2 \ ///
					., all[4,2], ., not_settled[4,2],., settled[4,2..4], 2)
		mat rownames tab3A`subpanel'2 = "Number_of_Reported_Channels" "Unknown" "One" "Two" "Three_or_More"
		mat list tab3A`subpanel'2 // just to view so it looks right

		* --- Reasons for Not Reporting --- *
		preserve // -- first do right side of table, "Settled"
			if "`subpanel'" == "b" keep if gvkey != .
			keep if internal == 1 & wb_raised_issue_internally == "NO" & settled == 1
			collapse (count) allegations = case_id (mean) ave_settlementS = settlement (sum) settlement, by(reason_not_raised_internally)
			egen obsS = total(allegations) // total observations
			ren allegations allegationsS
			ren settlement settlementS
			tempfile S
			save `S', replace
		restore
		preserve // -- now do middle section of table, "Not settled"
			if "`subpanel'" == "b" keep if gvkey !=.
			keep if internal == 1 & wb_raised_issue_internally == "NO" & settled == 0
			collapse (count) allegations = case_id, by(reason_not_raised_internally)
			ren allegations allegationsNS
			egen obsNS = total(allegationsNS)
			tempfile NS
			save `NS', replace
		restore
		preserve
			if "`subpanel'" == "b" keep if gvkey !=.
			keep if internal == 1 & wb_raised_issue_internally == "NO"
			collapse (count) allegationsA = case_id (mean) settled, by(reason_not_raised_internally)
			egen obsA = total(allegationsA)
			ren settled settledA
				replace settledA = settledA * 100
			merge 1:1 reason_not_raised_internally using `S', nogen 
			merge 1:1 reason_not_raised_internally using `NS', nogen 
			gsort -allegationsS -allegationsNS
			local N = _N
			mkmat obsA settledA obsNS allegationsNS obsS allegationsS ave_settlementS settlementS, mat(all) rownames(reason_not_raised_internally)
			pause
		restore
		
		local other_rows ""
		forval x=1/`N' {
			local other_rows "`other_rows' ., all[`x',2], .,all[`x',4], ., all[`x', 6..8], 3" /* leave obs empty, fill in others */
			if `x' < `N' local other_rows "`other_rows' \ " // add line break if not end
		}
		mat tab3A`subpanel'3 = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 3 \  ///
			`other_rows')
		if "`subpanel'" == "b" mat rownames tab3A`subpanel'3 = "Reasons_for_Not_Reporting"  ///
						"No_Information" "Fear_of_Retaliation" "External_Parties_Already_Knew" 
		if "`subpanel'" == "a" mat rownames tab3A`subpanel'3 = "Reasons_for_Not_Reporting"  ///
									"No_Information" "Fear_of_Retaliation" "Supervisors_Involve" "External_Parties_Already_Knew" 
		mat list tab3A`subpanel'3

		*--------------------------------------------
		* Now export to excel workbook
		preserve
			drop _all
			mat full_tab3A`subpanel' = (tab3A`subpanel'1 \ tab3A`subpanel'2 \ tab3A`subpanel'3)
			svmat2 full_tab3A`subpanel', names(obsA settledA obsNS allegationsNS obsS allegationsS ave_settlementS ///
									 		settlementS subtable) rnames(rowname)
			*Calculate %s of Total by subtable instead of overall // -------------------
			foreach col in "allegationsNS" "allegationsS" {	
				bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
				gen pct = `col'/tot*100 // "% of Total"

				tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
				replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

				drop tot pct
			}
			tostring settledA, gen(settledA_pct_str) format(%9.1f) force // percents for table
			replace settledA_pct_str = settledA_pct_str + "%" if !inlist(settledA_pct_str,".","0")
			drop settledA
			
			* end %s of Total // -------------------------------------------------------
			order rowname obsA settledA_pct_str obsNS allegationsNS allegationsNS_pct_str ///
						obsS allegationsS allegationsS_pct_str ave_settlementS settlementS
			replace rowname = "    " + rowname if ///
				!inlist(rowname, "Reported_Internally_First", "Number_of_Reported_Channels", "Reasons_for_Not_Reporting")
			replace rowname = subinstr(rowname, "_", " ", .)
			
			foreach var in ave_settlementS settlementS {
				tostring `var', replace force format(%9.1f)
					replace `var' = "$" + `var' if `var' != "."
			}
			
			foreach var of varlist *_pct_str *settlement? {
				replace `var' = "" if `var' == "."
			}
			drop subtable
			export excel "$dropbox/draft_tables.xls", sheet("3.ANew`subpanel'") sheetrep first(var)
		restore

	}
}



* Panel B
if `run_3B' == 1 | `run_all' == 1 {
*------------------------------------

local int_channels "int_auditor colleague direct_supervisor hotline hr legalcompliance top_management"
local ext_channels "ext_auditor gov ext_to_courts"
local ave_stlmts_int ""
foreach channel of local int_channels {
	local ave_stlmts_int "`ave_stlmts_int' ave_stlmt_`channel' = stlmt_`channel'"
}

local ave_stlmts_ext ""
foreach channel of local ext_channels {
	local ave_stlmts_ext "`ave_stlmts_ext' ave_stlmt_`channel' = stlmt_`channel'"
}

foreach var in `int_channels' `ext_channels' {
	gen stlmt_`var' = settlement if (`var' > 0)
	gen stld_`var' = settled if (`var' > 0)
}
*========== Table 3Ba (full & public, side by side) ==========*
* --- Internal Reporting Channel --- *

preserve // -- first do right side of table, "Public Firms"
	keep if gvkey != .
	collapse (sum) `int_channels' stlmt* (mean)  stld_* `ave_stlmts_int', fast
		drop stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor
		drop stld_gov stld_ext_to_courts stld_ext_auditor
	foreach var in `int_channels' {
		ren `var' n`var' // for reshape
	}
	gen i = _n
	reshape long n  stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
	egen obsP = total(n) // total observations not missing
	ren n allegationsP
	ren stlmt_ settlementP
	ren stld_ settledP
		replace settledP = settledP * 100
	ren ave_stlmt_ ave_settlementP
	tempfile public3B1
	save `public3B1', replace
restore
preserve // -- now do left side of table, "All Firms"
	collapse (sum) `int_channels' stlmt* (mean) stld_* `ave_stlmts_int', fast
		drop stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor
	foreach var in `int_channels' {
		ren `var' n`var' // for reshape
	}
	gen i = _n
	reshape long n stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
	gsort -n
	egen obsA = total(n)
	ren n allegationsA
	ren stlmt_ settlementA
	ren stld_ settledA
		replace settledA = settledA * 100
	ren ave_stlmt_ ave_settlementA
	merge 1:1 channel using `public3B1', nogen
	gsort -allegationsA -allegationsP
		br
		*pause
	mkmat obsA allegationsA settledA ave_settlementA settlementA ///
			obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(channel)
restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/7 {
		local other_rows "`other_rows' ., all[`x',2..5], .,all[`x',7..10], 1" /* leave obs empty, fill in others */
		if `x' < 7 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab3Ba1 = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 1 \ /* put total non-missing obs on first line only */ ///
			`other_rows')

mat rownames tab3Ba1 = "Internal_Reporting_Channel" "Top_Management" "Direct_Supervisor"  ///
				"Colleague" "Legal_Compliance" "HR" "Hotline" "Internal_Auditor"
mat list tab3Ba1

* --- External Reporting Channel --- *
forval section = 2/3 {
	preserve // -- first do right side of table, "Public Firms"
		keep if gvkey != .
		
		if `section' == 2 keep if wb_raised_issue_internally == "YES"
		if `section' == 3 keep if wb_raised_issue_internally == "NO"

		collapse (sum) `ext_channels' stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor ///
				 (mean) stld_gov stld_ext_to_courts stld_ext_auditor `ave_stlmts_ext', fast
		foreach var in `ext_channels' {
			ren `var' n`var' // for reshape
		}
		gen i = _n
		reshape long n stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
		egen obsP = total(n) // total observations not missing
		ren n allegationsP
		ren stlmt_ settlementP
		ren ave_stlmt_ ave_settlementP
		ren stld_ settledP
			replace settledP = settledP * 100
		tempfile public3B`section'
		save `public3B`section'', replace
	restore
	preserve // -- now do left side of table, "All Firms"
		if `section' == 2 keep if wb_raised_issue_internally == "YES"
		if `section' == 3 keep if wb_raised_issue_internally == "NO"

		collapse (sum) `ext_channels' stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor ///
				 (mean) stld_gov stld_ext_to_courts stld_ext_auditor `ave_stlmts_ext', fast
		foreach var in `ext_channels' {
			ren `var' n`var' // for reshape
		}
		gen i = _n
		reshape long n stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
		gsort -n
		egen obsA = total(n)
		ren n allegationsA
		ren stlmt_ settlementA
		ren stld_ settledA
			replace settledA = settledA * 100
		ren ave_stlmt_ ave_settlementA
		merge 1:1 channel using `public3B`section'', nogen
		gsort -allegationsA -allegationsP
			br
			*pause
		mkmat obsA allegationsA settledA ave_settlementA settlementA ///
				obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(channel)
	restore

	*store local string to input other all[] rows into the tab3 matrix
		local other_rows ""
		forval x=1/3 {
			local other_rows "`other_rows' ., all[`x',2..5], ., all[`x',7..10], `section'" /* leave obs empty, fill in others */
			if `x' < 3 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3Ba`section' = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., `section' \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat list tab3Ba`section'
	if `section' == 2 {
		mat tab3Ba2 = (., ., ., ., ., ., ., ., ., ., 2 \ tab3Ba2)
		mat rownames tab3Ba2 = "External_Reporting_Channel" "Internal_Reporters" ///
								"Straight_to_Court_System" "Government_Agency" "External_Auditor"
		mat list tab3Ba2
	}
	if `section' == 3 {
		mat rownames tab3Ba3 = "External_Only_Reporters" "Straight_to_Court_System" ///
								"Government_Agency" "External_Auditor"
		mat list tab3Ba3
	}


} //looping over section 2 & 3

*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab3Ba = (tab3Ba1 \ tab3Ba2 \ tab3Ba3)
	svmat2 full_tab3Ba, names(obsA allegationsA settledA ave_settlementA settlementA ///
								obsP allegationsP settledP ave_settlementP settlementP subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsA" "allegationsP" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

		drop tot pct
	}
	foreach col of varlist settled? {
		tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
		drop `col'
	}
	* end %s of Total // -------------------------------------------------------
	order rowname obsA allegationsA allegationsA_pct_str settledA_pct_str ave_settlementA settlementA ///
				obsP allegationsP allegationsP_pct_str settledP_pct_str ave_settlementP settlementP
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Internal_Reporting_Channel", "External_Reporting_Channel", ///
								"Internal_Reporters", "External_Only_Reporters")
	replace rowname = "  " + rowname if inlist(rowname, "Internal_Reporters", "External_Only_Reporters")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	foreach var of varlist *settlement? {
		tostring `var', replace force format(%9.1f)
		replace `var' = "$" + `var' if `var' != "."
	}
		
	foreach var of varlist *_pct_str *settlement? {
		replace `var' = "" if `var' == "."
	}
	drop subtable
	br
	*pause
	export excel "$dropbox/draft_tables.xls", sheet("3.Ba") sheetrep first(var)
restore


*========== Table 3Bbc (settled & not settled, full then public only) ==========*
* --- Internal Reporting Channel --- *
foreach subpanel in "b" "c"{  //b is full sample, c is public-firm only

	preserve // -- first do right side of table, "Settled"
		if "`subpanel'" == "c" keep if gvkey != .
		keep if settled == 1
		drop stlmt*
		foreach var in `int_channels' {
			gen stlmt_`var' = settlement if (`var' > 0)
		}
		collapse (sum) `int_channels' stlmt* (mean) `ave_stlmts_int', fast
		foreach var in `int_channels' {
			ren `var' n`var' // for reshape
		}
		gen i = _n
		reshape long n ave_stlmt_ stlmt_, i(i) j(channel) string
		egen obsS = total(n) // total observations not missing
		ren n allegationsS
		ren stlmt_ settlementS
		ren ave_stlmt_ ave_settlementS
		tempfile settled3B`subpanel'1
		save `settled3B`subpanel'1', replace
	restore

	preserve // -- now do left side of table, "Not settled"
		if "`subpanel'" == "c" keep if gvkey != .
		keep if settled == 0
		drop stlmt*
		foreach var in `int_channels'{
			gen stlmt_`var' = settlement if (`var' > 0)
		}
		collapse (sum) `int_channels', fast
		foreach var in `int_channels' {
			ren `var' n`var' // for reshape
		}
		gen i = _n
		reshape long n, i(i) j(channel) string
		gsort -n
		egen obsNS = total(n)
		ren n allegationsNS
		merge 1:1 channel using `settled3B`subpanel'1', nogen
		gsort -allegationsNS -allegationsS
			br
			*pause
		tempfile all3B`subpanel'1
		save `all3B`subpanel'1', replace
	restore
	preserve
		if "`subpanel'" == "c" keep if gvkey != .
		collapse (sum) `int_channels' (mean) stld_*, fast
		foreach var in `int_channels' {
			ren `var' n`var' // for reshape
		}
		gen i = _n
		reshape long n stld_, i(i) j(channel) string
		gsort -n 
		egen obsA = total(n)
		ren stld_ settledA
		replace settledA = settledA * 100
		merge 1:1 channel using `all3B`subpanel'1', nogen 
		gsort -allegationsNS -allegationsS
			br
			pause  //check for order of row names
		mkmat obsA settledA obsNS allegationsNS obsS allegationsS ave_settlementS settlementS, mat(all) rownames(channel)
	restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/7 {
		local other_rows "`other_rows' ., all[`x',2], ., all[`x',4], .,all[`x',6..8], 1" /* leave obs empty, fill in others */
		if `x' < 7 local other_rows "`other_rows' \ " // add line break if not end
	}
	mat tab3B`subpanel'1 = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 1 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
	mat list tab3B`subpanel'1

	if "`subpanel'" == "b" {
		mat rownames tab3B`subpanel'1 = "Internal_Reporting_Channel" "Top_Management" "Direct_Supervisor" ///
				"Colleague" "Legal_Compliance" "HR" "Hotline" "Internal_Auditor"
	}
	if "`subpanel'" == "c" {
		mat rownames tab3B`subpanel'1 = "Internal_Reporting_Channel" "Top_Management" ///
				"Direct_Supervisor" "Legal_Compliance" "Colleague" "HR" "Hotline" ///
				"Internal_Auditor"
	}
	mat list tab3B`subpanel'1

* --- External Reporting Channel --- *
	forval section = 2/3 {
		preserve // -- first do right side of table, "Settled"
			if "`subpanel'" == "c" keep if gvkey != .
			keep if settled == 1
			drop stlmt*
			foreach var in `ext_channels' {
				gen stlmt_`var' = settlement if (`var' > 0)
			}
			if `section' == 2 keep if wb_raised_issue_internally == "YES"
			if `section' == 3 keep if wb_raised_issue_internally == "NO"
			collapse (sum) `ext_channels' stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor ///
					 (mean) `ave_stlmts_ext', fast
			foreach var in `ext_channels' {
				ren `var' n`var' // for reshape
			}
			gen i = _n
			reshape long n ave_stlmt_ stlmt_, i(i) j(channel) string
			egen obsS = total(n) // total observations not missing
			ren n allegationsS
			ren stlmt_ settlementS
			ren ave_stlmt_ ave_settlementS
			tempfile settled3B`subpanel'`section'
			save `settled3B`subpanel'`section'', replace
		restore
		preserve // -- now do left side of table, "Not settled"
			if "`subpanel'" == "c" keep if gvkey != .
			keep if settled == 0
			if `section' == 2 keep if wb_raised_issue_internally == "YES"
			if `section' == 3 keep if wb_raised_issue_internally == "NO"
			collapse (sum) `ext_channels', fast
			foreach var in `ext_channels' {
				ren `var' n`var' // for reshape
			}
			gen i = _n
			reshape long n, i(i) j(channel) string
			gsort -n
			egen obsNS = total(n)
			ren n allegationsNS
			merge 1:1 channel using `settled3B`subpanel'`section'', nogen
			gsort -allegationsNS -allegationsS
				br
				*pause
			tempfile all3B`subpanel'`section'
			save `all3B`subpanel'`section'', replace 
		restore
		preserve // Now do total observations and % settled 
			if "`subpanel'" == "c" keep if gvkey != .
			if `section' == 2 keep if wb_raised_issue_internally == "YES"
			if `section' == 3 keep if wb_raised_issue_internally == "NO"
			collapse (sum) `ext_channels' (mean) stld_*, fast
			foreach var in `ext_channels' {
				ren `var' n`var' // for reshape
			}
			gen i = _n
			reshape long n stld_, i(i) j(channel) string
			gsort -n 
			egen obsA = total(n)
			ren stld_ settledA
			replace settledA = settledA * 100
			merge 1:1 channel using `all3B`subpanel'`section'', nogen 
			gsort -allegationsNS -allegationsS
				br
				*pause
			mkmat obsA settledA obsNS allegationsNS obsS allegationsS ave_settlementS settlementS, mat(all) rownames(channel)
		restore

		*store local string to input other all[] rows into the tab3 matrix
		local other_rows ""
		forval x=1/3 {
		local other_rows "`other_rows' ., all[`x',2], ., all[`x',4], .,all[`x',6..8], 2" /* leave obs empty, fill in others */
		if `x' < 3 local other_rows "`other_rows' \ " // add line break if not end
		}
		mat tab3B`subpanel'`section' = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 2 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
		mat list tab3B`subpanel'`section'

		if `section' == 2 {
			mat tab3B`subpanel'2 = (., ., ., ., ., ., ., ., 2 \ tab3B`subpanel'2)
			mat rownames tab3B`subpanel'2 = "External_Reporting_Channel" "Reported_Internally_First" ///
									"Straight_to_Court_System" "Government_Agency" "External_Auditor"
			mat list tab3B`subpanel'2
		}
		if `section' == 3 {
			mat rownames tab3B`subpanel'3 = "Directly_Reported_Externally" "Straight_to_Court_System" ///
									"Government_Agency" "External_Auditor"
			mat list tab3B`subpanel'3
		}
	}
*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab3B`subpanel' = (tab3B`subpanel'1 \ tab3B`subpanel'2 \ tab3B`subpanel'3)
	svmat2 full_tab3B`subpanel', names(obsA settledA obsNS allegationsNS obsS allegationsS ///
										ave_settlementS settlementS subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsNS" "allegationsS" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

		drop tot pct
	}
	
	tostring settledA, gen(settledA_pct_str) format(%9.1f) force // percents for table
	replace settledA_pct_str = settledA_pct_str + "%" if !inlist(settledA_pct_str,".","0")
	drop settledA
	
	* end %s of Total // -------------------------------------------------------
	order rowname obsA settledA_pct_str obsNS allegationsNS allegationsNS_pct_str ///
				obsS allegationsS allegationsS_pct_str ave_settlementS settlementS
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Internal_Reporting_Channel", "External_Reporting_Channel", ///
								"Internal_Reporters", "External_Only_Reporters")
	replace rowname = "  " + rowname if inlist(rowname, "Internal_Reporters", "External_Only_Reporters")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	foreach var of varlist *settlement? {
		tostring `var', replace force format(%9.1f)
		replace `var' = "$" + `var' if `var' != "."
	}
		
	foreach var of varlist *_pct_str *settlement? {
		replace `var' = "" if `var' == "."
	}
	drop subtable
	br
	*pause
	export excel "$dropbox/draft_tables.xls", sheet("3.B`subpanel'") sheetrep first(var)
restore

} //loop over subpanels b and c

*========== Table 3Bdef (full & public, by management class) ==========*
* --- Internal Reporting Channel --- *
foreach subpanel in "d" "e" "f" { // panels for lower, middle, upper management classes
	preserve // -- first do right side of table, "Public Firms"
		if "`subpanel'" == "d" keep if mgmt_class == "Lower"
		if "`subpanel'" == "e" keep if mgmt_class == "Middle"
		if "`subpanel'" == "f" keep if mgmt_class == "Upper"

		keep if gvkey != .
		collapse (sum) `int_channels' stlmt* (mean)  stld_* `ave_stlmts_int', fast
			drop stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor
			drop stld_gov stld_ext_to_courts stld_ext_auditor
		foreach var in `int_channels' {
			ren `var' n`var' // for reshape
		}
		gen i = _n
		reshape long n  stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
		egen obsP = total(n) // total observations not missing
		ren n allegationsP
		ren stlmt_ settlementP
		ren stld_ settledP
			replace settledP = settledP * 100
		ren ave_stlmt_ ave_settlementP
		tempfile public3B`subpanel'1
		save `public3B`subpanel'1', replace
	restore
	preserve // -- now do left side of table, "All Firms"
		if "`subpanel'" == "d" keep if mgmt_class == "Lower"
		if "`subpanel'" == "e" keep if mgmt_class == "Middle"
		if "`subpanel'" == "f" keep if mgmt_class == "Upper"

		collapse (sum) `int_channels' stlmt* (mean) stld_* `ave_stlmts_int', fast
			drop stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor
		foreach var in `int_channels' {
			ren `var' n`var' // for reshape
		}
		gen i = _n
		reshape long n stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
		gsort -n
		egen obsA = total(n)
		ren n allegationsA
		ren stlmt_ settlementA
		ren stld_ settledA
			replace settledA = settledA * 100
		ren ave_stlmt_ ave_settlementA
		merge 1:1 channel using `public3B`subpanel'1', nogen
		gsort -allegationsA -allegationsP
			br
			pause
		mkmat obsA allegationsA settledA ave_settlementA settlementA ///
				obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(channel)
	restore

	*store local string to input other all[] rows into the tab3 matrix
		local other_rows ""
		forval x=1/7 {
			local other_rows "`other_rows' ., all[`x',2..5], .,all[`x',7..10], 1" /* leave obs empty, fill in others */
			if `x' < 7 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3B`subpanel'1 = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 1 \ /* put total non-missing obs on first line only */ ///
				`other_rows')

	if "`subpanel'" == "d" {
		mat rownames tab3B`subpanel'1 = "Internal_Reporting_Channel" "Top_Management" "Direct_Supervisor" ///
									"Colleague" "Legal_Compliance" "HR" "Hotline" "Internal_Auditor"
	}

	if "`subpanel'" == "e"{
		mat rownames tab3B`subpanel'1 = "Internal_Reporting_Channel" "Top_Management" "Direct_Supervisor" ///
									"Legal_Compliance" "Colleague" "HR" "Hotline" "Internal_Auditor"
	}
	if "`subpanel'" == "f" {
		mat rownames tab3B`subpanel'1 = "Internal_Reporting_Channel" "Top_Management" "Legal_Compliance" "HR" ///
										"Hotline" "Internal_Auditor" " " " "
	}

	* --- External Reporting Channel --- *
	forval section = 2/3 {
		preserve // -- first do right side of table, "Public Firms"
			keep if gvkey != .
			
			if "`subpanel'" == "d" keep if mgmt_class == "Lower"
			if "`subpanel'" == "e" keep if mgmt_class == "Middle"
			if "`subpanel'" == "f" keep if mgmt_class == "Upper"

			if `section' == 2 keep if wb_raised_issue_internally == "YES"
			if `section' == 3 keep if wb_raised_issue_internally == "NO"

			collapse (sum) `ext_channels' stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor ///
					 (mean) stld_gov stld_ext_to_courts stld_ext_auditor `ave_stlmts_ext', fast
			foreach var in `ext_channels' {
				ren `var' n`var' // for reshape
			}
			gen i = _n
			reshape long n stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
			egen obsP = total(n) // total observations not missing
			ren n allegationsP
			ren stlmt_ settlementP
			ren ave_stlmt_ ave_settlementP
			ren stld_ settledP
				replace settledP = settledP * 100
			tempfile public3B`subpanel'`section'
			save `public3B`subpanel'`section'', replace
		restore
		preserve // -- now do left side of table, "All Firms"

			if "`subpanel'" == "d" keep if mgmt_class == "Lower"
			if "`subpanel'" == "e" keep if mgmt_class == "Middle"
			if "`subpanel'" == "f" keep if mgmt_class == "Upper"

			if `section' == 2 keep if wb_raised_issue_internally == "YES"
			if `section' == 3 keep if wb_raised_issue_internally == "NO"

			collapse (sum) `ext_channels' stlmt_gov stlmt_ext_to_courts stlmt_ext_auditor ///
					 (mean) stld_gov stld_ext_to_courts stld_ext_auditor `ave_stlmts_ext', fast
			foreach var in `ext_channels' {
				ren `var' n`var' // for reshape
			}
			gen i = _n
			reshape long n stld_ ave_stlmt_ stlmt_, i(i) j(channel) string
			gsort -n
			egen obsA = total(n)
			ren n allegationsA
			ren stlmt_ settlementA
			ren stld_ settledA
				replace settledA = settledA * 100
			ren ave_stlmt_ ave_settlementA
			merge 1:1 channel using `public3B`subpanel'`section'', nogen
			gsort -allegationsA -allegationsP
				br
				*pause
			mkmat obsA allegationsA settledA ave_settlementA settlementA ///
					obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(channel)
		restore

		*store local string to input other all[] rows into the tab3 matrix
			local other_rows ""
			forval x=1/3 {
				local other_rows "`other_rows' ., all[`x',2..5], ., all[`x',7..10], `section'" /* leave obs empty, fill in others */
				if `x' < 3 local other_rows "`other_rows' \ " // add line break if not end
			}
		mat tab3B`subpanel'`section' = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., `section' \ /* put total non-missing obs on first line only */ ///
					`other_rows')
		mat list tab3B`subpanel'`section'
		if `section' == 2 {
			mat tab3B`subpanel'2 = (., ., ., ., ., ., ., ., ., ., 2 \ tab3B`subpanel'2)
			mat rownames tab3B`subpanel'2 = "External_Reporting_Channel" "Internal_Reporters" ///
									"Straight_to_Court_System" "Government_Agency" "External_Auditor"
			mat list tab3B`subpanel'2
		}
		if `section' == 3 {
			mat rownames tab3B`subpanel'3 = "External_Only_Reporters" "Straight_to_Court_System" ///
									"Government_Agency" "External_Auditor"
			mat list tab3B`subpanel'3
		}
	}
	*--------------------------------------------
	* Now export to excel workbook
	preserve
		drop _all
		mat full_tab3B`subpanel' = (tab3B`subpanel'1 \ tab3B`subpanel'2 \ tab3B`subpanel'3)
		svmat2 full_tab3B`subpanel', names(obsA allegationsA settledA ave_settlementA settlementA ///
									obsP allegationsP settledP ave_settlementP settlementP subtable) rnames(rowname)
		*Calculate %s of Total by subtable instead of overall // -------------------
		foreach col in "allegationsA" "allegationsP" {	
			bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
			gen pct = `col'/tot*100 // "% of Total"

			tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

			drop tot pct
		}
		foreach col of varlist settled? {
			tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
			drop `col'
		}
		* end %s of Total // -------------------------------------------------------
		order rowname obsA allegationsA allegationsA_pct_str settledA_pct_str ave_settlementA settlementA ///
					obsP allegationsP allegationsP_pct_str settledP_pct_str ave_settlementP settlementP
		replace rowname = "    " + rowname if ///
			!inlist(rowname, "Internal_Reporting_Channel", "External_Reporting_Channel", ///
									"Internal_Reporters", "External_Only_Reporters")
		replace rowname = "  " + rowname if inlist(rowname, "Internal_Reporters", "External_Only_Reporters")
		replace rowname = subinstr(rowname, "_", " ", .)
		
		foreach var of varlist *settlement? {
			tostring `var', replace force format(%9.1f)
			replace `var' = "$" + `var' if `var' != "."
		}
			
		foreach var of varlist *_pct_str *settlement? {
			replace `var' = "" if `var' == "."
		}
		drop subtable
		br
		*pause
		export excel "$dropbox/draft_tables.xls", sheet("3.B`subpanel'") sheetrep first(var)
	restore
} // loop over subpanels def
} // end Panel B ---------------------------------------------------------------

*------------------------------------
* Panels C & D
if `run_3CD' == 1 | `run_all' == 1 {
foreach panel in "C" "D" {
foreach subpanel in "a" "b" {

* --- Male --- *
	preserve // -- first do left side of table, "Not Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 0
		collapse (count) allegations = case_id, by(male)
			assert male != .
		ren male male_int
		decode male_int, gen(male) // need string for row names
		egen obsNS = total(allegations) // total observations not missing gender
		ren allegations allegationsNS
		mkmat obsNS allegationsNS, mat(NS) rownames(male)
	restore
	preserve // -- now do right side of table, "Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 1
		collapse (count) allegations = case_id (mean) ave_settlement = settlement ///
					(sum) settlement, by(male)
			assert male != .
		ren male male_int
		decode male_int, gen(male) // need string for row names
		egen obsS = total(allegations) // total observations not missing gender
		ren allegations allegationsS
		mkmat obsS allegationsS ave_settlement settlement, mat(S) // don't need row names because
									// this matrix is being appended to the right of the all matrix
	restore
	preserve // -- now do % of cases settled column
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (mean) settled, by(male)
			assert male != .
		ren male male_int
		decode male_int, gen(male) // need string for row names
		egen obs = total(allegations) // total observations not missing gender
		replace settled = settled * 100
		mkmat obs settled, mat(full)
	restore

	mat tab3`panel'`subpanel'1 = (full[1,1], ., NS[1,1], ., S[1,1], ., ., ., 1 \ /* put total non-missing obs on first line only, not under either gender */ ///
				., full[1,2], ., NS[1,2], ., S[1,2..4], 1 \ /* leave obs empty, fill in allegations and settlements columns */ ///
				., full[2,2], ., NS[2,2], ., S[2,2..4], 1)    /* leave obs empty, fill in allegations and settlements columns */
	mat rownames tab3`panel'`subpanel'1 = "Gender" "Female" "Male"
	mat list tab3`panel'`subpanel'1 // just to view so it looks right

* --- Management Rank --- *
	preserve // -- first do right side of table, "Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 1
		collapse (count) allegations = case_id (mean) ave_settlement = settlement ///
					(sum) settlement, by(mgmt_class missing_job_title)
			assert mgmt_class != ""
		egen obsS = total(allegations) // total observations not missing gender
		ren allegations allegationsS
		tempfile s3`panel'`subpanel'3
		save `s3`panel'`subpanel'3', replace
	restore
	preserve // -- now do left side of table, "Not Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 0
		collapse (count) allegations = case_id, by(mgmt_class missing_job_title)
			assert mgmt_class != ""
		egen obsNS = total(allegations) // total observations not missing gender
		ren allegations allegationsNS
		tempfile ns3`panel'`subpanel'3
		save `ns3`panel'`subpanel'3', replace
	restore
	preserve // -- now do first column
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (mean) settled, by(mgmt_class missing_job_title)
			assert mgmt_class != ""
		egen obs = total(allegations) // total observations not missing gender
		replace settled = settled * 100

		merge 1:1 mgmt_class using `s3`panel'`subpanel'3', nogen
		merge 1:1 mgmt_class using `ns3`panel'`subpanel'3', nogen
		sort missing_job_title mgmt_class
			br
			*pause // to know what order to put the row labels in
		mkmat obs settled ///
				obsNS allegationsNS ///
				obsS allegationsS ave_settlement settlement, mat(all) rownames(mgmt_class)
	restore

	*store local string to input other all[] rows into the tab3b matrix
		local other_rows ""
		forval x=1/4 {
			local other_rows "`other_rows' ., all[`x',2], ., all[`x',4], ., all[`x',6..8], 3" /* leave obs empty, fill in others */
			if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3`panel'`subpanel'3 = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 3 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat rownames tab3`panel'`subpanel'3 = "Rank" "Rank_and_File" "Middle_Management" "Upper_Management" "No_Job_Title"
	mat list tab3`panel'`subpanel'3

* --- Function --- *
	preserve // -- first do right side of table, "Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 1
		collapse (count) allegations = case_id (mean) ave_settlement = settlement ///
					(sum) settlement, by(wb_function missing_job_title)
			assert wb_function != ""
		egen obsS = total(allegations) // total observations not missing gender
		ren allegations allegationsS
		tempfile s3`panel'`subpanel'4
		save `s3`panel'`subpanel'4', replace
	restore
	preserve // -- now do the left side of the table, "Not Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 0
		collapse (count) allegations = case_id, by(wb_function missing_job_title)
			assert wb_function != ""
		egen obsNS = total(allegations) // total observations not missing gender
		ren allegations allegationsNS
		tempfile ns3`panel'`subpanel'4
		save `ns3`panel'`subpanel'4', replace
	restore
	preserve // -- now do the first column for % settled
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (mean) settled, by(wb_function missing_job_title)
			assert wb_function != ""
		egen obs = total(allegations) // total observations not missing gender
		replace settled = settled * 100

		merge 1:1 wb_function using `s3`panel'`subpanel'4', nogen
		merge 1:1 wb_function using `ns3`panel'`subpanel'4', nogen
		gsort missing_job_title -allegationsS -allegationsNS
			br
			*pause // to know what order row names should go in
		mkmat obs settled ///
				obsNS allegationsNS ///
				obsS allegationsS ave_settlement settlement, mat(all) rownames(wb_function)
	restore


	*store local string to input other all[] and public[] rows into the tab2 matrix
		local other_rows ""
		forval x=1/4 {
			local other_rows "`other_rows' ., all[`x',2], ., all[`x',4], ., all[`x',6..8], 4" /* leave obs empty, fill in others */
			if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3`panel'`subpanel'4 = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 4 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	if "`panel'" == "C" | "`panel'" == "D" {
		mat rownames tab3`panel'`subpanel'4 = "Function" "Operations" "Finance/Accounting" "Legal/Compliance" "No_Job_Title"
	}

	mat list tab3`panel'`subpanel'4

* --- Repeat Whistleblower --- *
	preserve // first do left side of table, "Not Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 0
		collapse (count) allegations = case_id, by(repeat_wb_all)
			assert repeat_wb_all != .
		egen obsNS = total(allegations) // total observations not missing gender
		ren allegations allegationsNS
		tempfile ns3`panel'`subpanel'5
		save `ns3`panel'`subpanel'5', replace
	restore
	preserve // -- now do right side of table, "Settled"
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		keep if settled == 1
		collapse (count) allegations = case_id (mean) ave_settlement = settlement ///
					(sum) settlement, by(repeat_wb_all)
			assert repeat_wb_all != .
		egen obsS = total(allegations) // total observations not missing gender
		ren allegations allegationsS
		tempfile s3`panel'`subpanel'5
		save `s3`panel'`subpanel'5', replace
	restore
	preserve  // -- now do the first column for % settled
		if "`panel'" == "D" drop if gvkey == .
		if "`subpanel'" == "a" keep if wb_raised_issue_internally == "YES"
		if "`subpanel'" == "b" keep if wb_raised_issue_internally == "NO"
		collapse (count) allegations = case_id (mean) settled, by(repeat_wb_all)
			assert repeat_wb_all != .
		egen obs = total(allegations) // total observations not missing gender
		replace settled = settled * 100

		merge 1:1 repeat_wb_all using `s3`panel'`subpanel'5', nogen
		merge 1:1 repeat_wb_all using `ns3`panel'`subpanel'5', nogen
		gsort repeat_wb_all -allegationsS -allegationsNS
			br
			*pause // to know what order row names should go in
		mkmat obs settled ///
				obsNS allegationsNS ///
				obsS allegationsS ave_settlement settlement, mat(all) rownames(repeat_wb_all)
	restore

	*store local string to input other all[] and public[] rows into the tab2 matrix
		local other_rows ""
		forval x=1/2 {
			local other_rows "`other_rows' ., all[`x',2], ., all[`x',4], ., all[`x',6..8], 5" /* leave obs empty, fill in others */
			if `x' < 2 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab3`panel'`subpanel'5 = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 5 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat rownames tab3`panel'`subpanel'5 = "Repeat_Whistleblowers" "1_Allegation_Only" "Multiple_Allegations"
	mat list tab3`panel'`subpanel'5

*--------------------------------------------
* Now export to excel workbook
	preserve
		drop _all
		mat full_tab3`panel'`subpanel' = (tab3`panel'`subpanel'1 \ /*Age - tab3`panel'2 \*/ ///
								tab3`panel'`subpanel'3 \ tab3`panel'`subpanel'4 \ ///
								tab3`panel'`subpanel'5)
		svmat2 full_tab3`panel'`subpanel', names(obs settled ///
										obsNS allegationsNS ///
										obsS allegationsS ave_settlement settlement subtable) ///
										rnames(rowname)
		*Calculate %s of Total by subtable instead of overall // -------------------
		foreach col in "allegationsNS" "allegationsS" {	
			bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
			gen pct = `col'/tot*100 // "% of Total"

			tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word

			drop tot pct
		}
		foreach col of varlist settled {
			tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
			drop `col'
		}
		* end %s of Total // -------------------------------------------------------
		order rowname obs settled_pct_str ///
				obsNS allegationsNS allegationsNS_pct_str ///
				obsS allegationsS allegationsS_pct_str ave_settlement settlement
		replace rowname = "    " + rowname if ///
			!inlist(rowname, "Gender", "Age", "Rank", "Function", "Repeat_Whistleblowers")
		replace rowname = subinstr(rowname, "_", " ", .)
		
		foreach var of varlist *settlement {
			tostring `var', replace force format(%9.1f)
				replace `var' = "$" + `var' if `var' != "."
		}
			
		foreach var of varlist *_pct_str *settlement {
			replace `var' = "" if `var' == "."
		}
		drop subtable
		export excel "$dropbox/draft_tables.xls", sheet("3.`panel'`subpanel'") sheetrep first(var)
	restore

} // loop through panels C & D
} // end subpanels a & b
} // end Panels C & D

* ================================== TABLE 4 ================================== *
* Panel A
if `run_4A' == 1 | `run_all' == 1 {
*------------------------------------

*------------Descriptive statstistics on Retaliation-------------------*
preserve
	keep if wb_raised_issue_internally == "YES"
	collapse (count) allegationsA = case_id (mean) settled ave_settlementA = settlement (sum) settlement, by(n_retaliations)
	egen obsA = total(allegationsA)
	ren settled settledA
		replace settledA = settledA*100
	ren settlement settlementA
		br
		*pause
	mkmat obsA allegationsA settledA ave_settlementA settlementA, mat(all) rownames(n_retaliations)
restore
preserve
	keep if wb_raised_issue_internally == "YES"
	keep if gvkey != .
	collapse (count) allegationsP = case_id (mean) settled ave_settlementP = settlement (sum) settlement, by(n_retaliations)
	egen obsP = total(allegationsP)
	ren settled settledP
		replace settledP = settledP*100
	ren settlement settlementP
	mkmat obsP allegationsP settledP ave_settlementP settlementP, mat(public)
restore 

mat tab4A2 = (all[1,1], ., ., ., ., public[1,1], ., ., ., ., 2 \ /* put total non-missing obs on first line only, not under either gender */ /// 
			., all[1,2..5], ., public[1,2..5],  2 \ /* leave obs empty, fill in allegations and settlements columns */ /// 
			., all[2,2..5], ., public[2,2..5],  2 \ /// 
			., all[3,2..5], ., public[3,2..5],  2 \ /// 
			., all[4,2..5], ., public[4,2..5],  2) 
mat rownames tab4A2 = "Number_of_Retaliations_by_Firms" "None_Mentioned" "One" "Two" "Three_or_More"
mat list tab4A2

*Now export to excel workbook 

preserve 
	drop _all 
	mat full_tab4A = (tab4A2) 
	svmat2 full_tab4A, names(obsA allegationsA settledA ave_settlementA settlementA /// 
							 obsP allegationsP settledP ave_settlementP settlementP subtable) rnames(rowname) 
	*Calculate %s of Total by subtable instead of overall // ------------------- 
	foreach col in "allegationsA" "allegationsP" {	 
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total 
		gen pct = `col'/tot*100 // "% of Total" 
 
		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table 
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word 
 
		drop tot pct 
	} 
	foreach col of varlist settled? {
		tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table 
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")

		drop `col'
	}
	* end %s of Total // ------------------------------------------------------- 
	order rowname obsA allegationsA allegationsA_pct_str settledA_pct_str ave_settlementA settlementA /// 
				obsP allegationsP allegationsP_pct_str settledP_pct_str ave_settlementP settlementP 
	replace rowname = "    " + rowname if /// 
		!inlist(rowname, "Number_of_Responses_by_Firms", "Number_of_Retaliations_by_Firms") 
	replace rowname = subinstr(rowname, "_", " ", .) 
	 
	foreach var in ave_settlementA settlementA ave_settlementP settlementP { 
		tostring `var', replace force format(%9.1f) 
			replace `var' = "$" + `var' if `var' != "." 
	} 
	 
	foreach var of varlist *_pct_str *settlement? { 
		replace `var' = "" if `var' == "." 
	} 
	drop subtable 
	export excel "$dropbox/draft_tables.xls", sheet("4.A") sheetrep first(var) 
restore 
} // end Panel A --------------------------------------------------------------- 

*Panel B 
if `run_4BC' == 1 | `run_all' == 1 {
* --- Firm Response to Allegation --- *

foreach panel in "B" "C" {   //Nearly identi panels, for all/public firm samples
	foreach var of varlist response_* {
	local response = substr("`var'", 10, .)
	cap drop stlmt* stld*
	gen stld_`response' = settled if (`var' > 0)
	}
	preserve // -- first do right side of table, "settled"
		keep if wb_raised_issue_internally == "YES"
		if "`panel'" == "C" keep if gvkey != .
		keep if settled == 1
		foreach var of varlist response_*{
			local response = substr("`var'", 10, .)
			gen stlmt_`response' = settlement if (`var' > 0)
		}
		collapse (sum) response_* stlmt* (mean) ave_coverup =stlmt_coverup ave_ignored=stlmt_ignored ///
												ave_int_inv=stlmt_int_inv ave_unknown=stlmt_unknown, fast
		ren response_* n* // for reshape
		gen i = _n
		reshape long n ave_ stlmt_ , i(i) j(response) string
		egen obsS = total(n) // total observations not missing
		ren n allegationsS
		ren stlmt_ settlementS
		ren ave_ ave_settlementS
		tempfile settled4`panel'1
		save `settled4`panel'1', replace
	restore
	preserve // -- now do left side of table, "Not settled"
		keep if wb_raised_issue_internally == "YES"
		if "`panel'" == "C" keep if gvkey != .
		keep if settled == 0
		collapse (sum) response_*, fast
		ren response_* n* // for reshape
		gen i = _n
		reshape long n, i(i) j(response) string
		gsort -n
		egen obsNS = total(n)
		ren n allegationsNS
		merge 1:1 response using `settled4`panel'1', nogen
		gen missing_response = response == "unknown"
		gsort missing_response -allegationsS -allegationsNS
		br
		pause
		drop if allegationsNS == .
		tempfile all4`panel'1
		save `all4`panel'1', replace
	restore
	preserve
		keep if wb_raised_issue_internally == "YES" & internal == 1
		if "`panel'" == "C" keep if gvkey != .
		collapse (sum) response_* (mean) stld_*, fast 
		ren response_* n* // for reshape
		gen i = _n
		reshape long n stld_ , i(i) j(response) string
		egen obsA = total(n) // total observations not missing
		ren stld_ settledA
		replace settledA = settledA * 100
		merge 1:1 response using `all4`panel'1', nogen assert(1 3)
		gsort missing_response -allegationsS -allegationsNS
			br
			pause
	mkmat obsA settledA obsNS allegationsNS obsS allegationsS ave_settlementS settlementS, mat(all) rownames(response)
	restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/4 {
		local other_rows "`other_rows' ., all[`x',2], ., all[`x',4], .,all[`x',6..8], 1" /* leave obs empty, fill in others */
		if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
	}
	mat tab4`panel'1 = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 1 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
	mat list tab4`panel'1
	mat rownames tab4`panel'1 = "Response_to_Allegation" "Ignored" "Cover_Up" "Internal_Investigation" "None_Mentioned"

* --- Firm Retaliation Against Whistleblower --- *
	cap drop stld* stlmt*
	foreach var of varlist retaliation_* {
		local retaliation = substr("`var'", 13, .)
		gen stld_`retaliation' = settled if (`var' > 0)
	}
	preserve // -- first do right side of table, "Settled"
		keep if wb_raised_issue_internally == "YES" & internal == 1
		if "`panel'" == "C" keep if gvkey != .
		keep if settled == 1
		foreach var of varlist retaliation_* {
			local retaliation = substr("`var'", 13, .)
			gen stlmt_`retaliation' = settlement if (`var' > 0)
		}
		collapse (sum) retaliation_* stlmt* (mean) ave_fired=stlmt_fired ave_none=stlmt_none ave_harassed=stlmt_harassed ///
											   ave_threat=stlmt_threat ave_quit=stlmt_quit ave_demotion=stlmt_demotion ///
											   ave_suspension=stlmt_suspension ave_lawsuit=stlmt_lawsuit, fast
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n ave_ stlmt_ , i(i) j(retaliation) string
		egen obsS = total(n) // total observations not missing
		ren n allegationsS
		ren stlmt_ settlementS
		ren ave_ ave_settlementS
		tempfile settled4`panel'2
		save `settled4`panel'2', replace
	restore
	preserve // -- now do left side of table, "Not settled"
		keep if wb_raised_issue_internally == "YES" & internal == 1
		if "`panel'" == "C" keep if gvkey != .
		keep if settled == 0
		collapse (sum) retaliation_*, fast
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n, i(i) j(retaliation) string
		gsort -n
		egen obsNS = total(n)
		ren n allegationsNS
		merge 1:1 retaliation using `settled4`panel'2', assert(1 3)
		gen no_ret = retaliation == "none"
		gsort no_ret -allegationsS -allegationsNS
			br 
			pause
		drop if allegationsNS == .
		tempfile all4`panel'2
		save `all4`panel'2', replace
	restore 
	preserve
		keep if wb_raised_issue_internally == "YES" & internal == 1
		if "`panel'" == "C" keep if gvkey != .
		collapse (sum) retaliation_* (mean) stld_*, fast 
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n stld_ , i(i) j(retaliation) string
		egen obsA = total(n) // total observations not missing
		ren stld_ settledA
		replace settledA = settledA * 100
		merge 1:1 retaliation using `all4`panel'2', nogen assert(3)
		gsort no_ret -allegationsS -allegationsNS
			br
			pause
		mkmat obsA settledA obsNS allegationsNS obsS allegationsS ave_settlementS settlementS, mat(all) rownames(retaliation)
	restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/8 {
		local other_rows "`other_rows' ., all[`x',2], ., all[`x', 4], ., all[`x',6..8], 2" /* leave obs empty, fill in others */
		if `x' < 8 local other_rows "`other_rows' \ " // add line break if not end
	}
	mat tab4`panel'2 = (all[1,1], ., all[1,3], ., all[1,5], ., ., ., 2 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
	mat list tab4`panel'2
	mat rownames tab4`panel'2 = "Retaliation_Against_WB" "Fired" "Harassed" "Quit" "Threat" ///
				"Demotion" "Suspension" "Lawsuit" "None_Mentioned"
	cap drop stld_*

*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab4`panel' = (tab4`panel'1 \ tab4`panel'2)
	svmat2 full_tab4`panel', names(obsA settledA obsNS allegationsNS obsS ///
							allegationsS ave_settlementS settlementS subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsNS" "allegationsS" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
			// so the table can be pasted straight into word

		drop tot pct
	}

	tostring settledA, gen(settledA_pct_str) format(%9.1f) force // percents for table
	replace settledA_pct_str = settledA_pct_str + "%" if !inlist(settledA_pct_str,".","0")
	drop settledA
	
	* end %s of Total // -------------------------------------------------------
	order rowname obsA settledA_pct_str obsNS allegationsNS allegationsNS_pct_str obsS ///
							allegationsS allegationsS_pct_str ave_settlementS settlementS subtable
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Response_to_Allegation", "Retaliation_Against_WB")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	foreach var in ave_settlementS settlementS { 
		tostring `var', replace force format(%9.1f) 
			replace `var' = "$" + `var' if `var' != "." 
	} 
	 
	foreach var of varlist *_pct_str *settlement? { 
		replace `var' = "" if `var' == "." 
	} 
	drop subtable
	export excel "$dropbox/draft_tables.xls", sheet("4.`panel'") sheetrep first(var)
restore

}  //loop through panel B and C
}  // end Panel B & C---------------------------------------------------------------


* Alternative 4B, comment out if want settled v.s. non-settled

*Panel B
if `run_4BOld' == 1 | `run_all' == 1 {
* --- Firm Response to Allegation --- *
foreach var of varlist response_* {
	local response = substr("`var'", 10, .)
	gen stlmt_`response' = settlement * (`var' > 0)
	gen stld_`response' = settled * (`var' > 0)
}
preserve // -- first do right side of table, "Public Firms"
	keep if wb_raised_issue_internally == "YES" & internal == 1
	keep if gvkey != .
	collapse (sum) response_* stlmt* (mean) stld_* ave_coverup =stlmt_coverup ave_ignored=stlmt_ignored ///
											ave_int_inv=stlmt_int_inv ave_unknown=stlmt_unknown, fast
	ren response_* n* // for reshape
	gen i = _n
	reshape long n stld_ ave_ stlmt_ , i(i) j(response) string
	egen obsP = total(n) // total observations not missing
	ren n allegationsP
	ren stlmt_ settlementP
	ren ave_ ave_settlementP
	ren stld_ settledP
		replace settledP = settledP * 100
	tempfile public4B1
	save `public4B1', replace
restore
preserve // -- now do left side of table, "All Firms"
	keep if wb_raised_issue_internally == "YES"
	collapse (sum) response_* stlmt* (mean) stld_* ave_coverup =stlmt_coverup ave_ignored=stlmt_ignored ///
											ave_int_inv=stlmt_int_inv ave_unknown=stlmt_unknown, fast
	ren response_* n* // for reshape
	gen i = _n
	reshape long n stld_ ave_ stlmt_, i(i) j(response) string
	gsort -n
	egen obsA = total(n)
	ren n allegationsA
	ren stlmt_ settlementA
	ren ave_ ave_settlementA
	ren stld_ settledA
		replace settledA = settledA*100
	merge 1:1 response using `public4B1', assert(1 3)
	gen missing_response = response == "unknown"
	gsort missing_response -allegationsA -allegationsP
		br
		pause
		drop if allegationsA == .
	mkmat obsA allegationsA settledA ave_settlementA settlementA obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(response)
restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/4 {
		local other_rows "`other_rows' ., all[`x',2..5], .,all[`x',7..10], 1" /* leave obs empty, fill in others */
		if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab4B1 = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 1 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat list tab4B1
mat rownames tab4B1 = "Response_to_Allegation" "Ignored" "Cover_Up" "Internal_Investigation" "None_Mentioned"

* --- Firm Retaliation Against Whistleblower --- *
drop stlmt* stld*
foreach var of varlist retaliation_* {
	local retaliation = substr("`var'", 13, .)
	gen stlmt_`retaliation' = settlement * (`var' > 0)
	gen stld_`retaliation' = settled * (`var' > 0)
}
preserve // -- first do right side of table, "Public Firms"
	keep if wb_raised_issue_internally == "YES"
	keep if gvkey != .
	collapse (sum) retaliation_* stlmt* (mean) stld_* ave_fired=stlmt_fired ave_none=stlmt_none ave_harassed=stlmt_harassed ///
											   ave_threat=stlmt_threat ave_quit=stlmt_quit ave_demotion=stlmt_demotion ///
											   ave_suspension=stlmt_suspension ave_lawsuit=stlmt_lawsuit, fast
	ren retaliation_* n* // for reshape
	gen i = _n
	reshape long n stld_ ave_ stlmt_ , i(i) j(retaliation) string
	egen obsP = total(n) // total observations not missing
	ren n allegationsP
	ren stlmt_ settlementP
	ren ave_ ave_settlementP
	ren stld_ settledP
		replace settledP = settledP*100
	tempfile public4B2
	save `public4B2', replace
restore
preserve // -- now do left side of table, "All Firms"
	keep if wb_raised_issue_internally == "YES"
	collapse (sum) retaliation_* stlmt* (mean) stld_* ave_fired=stlmt_fired ave_none=stlmt_none ave_harassed=stlmt_harassed ///
											   ave_threat=stlmt_threat ave_quit=stlmt_quit ave_demotion=stlmt_demotion ///
											   ave_suspension=stlmt_suspension ave_lawsuit=stlmt_lawsuit, fast
	ren retaliation_* n* // for reshape
	gen i = _n
	reshape long n stld_ ave_ stlmt_ , i(i) j(retaliation) string
	gsort -n
	egen obsA = total(n)
	ren n allegationsA
	ren stlmt_ settlementA
	ren ave_ ave_settlementA
	ren stld_ settledA
		replace settledA = settledA*100
	merge 1:1 retaliation using `public4B2', assert(3)
	gen no_ret = retaliation == "none"
	gsort no_ret -allegationsA -allegationsP
		br
		pause
	mkmat obsA allegationsA settledA ave_settlementA settlementA obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(retaliation)
restore

*store local string to input other all[] rows into the tab3 matrix
	local other_rows ""
	forval x=1/8 {
		local other_rows "`other_rows' ., all[`x',2..5], .,all[`x',7..10], 2" /* leave obs empty, fill in others */
		if `x' < 8 local other_rows "`other_rows' \ " // add line break if not end
	}
mat tab4B2 = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 2 \ /* put total non-missing obs on first line only */ ///
			`other_rows')
mat list tab4B2
mat rownames tab4B2 = "Retaliation_Against_WB" "Fired" "Harassed" "Threat" "Quit" ///
				"Demotion" "Suspension" "Lawsuit" "None_Mentioned"
*--------------------------------------------
* Now export to excel workbook
preserve
	drop _all
	mat full_tab4B = (tab4B1 \ tab4B2)
	svmat2 full_tab4B, names(obsA allegationsA settledA ave_settlementA settlementA ///
							obsP allegationsP settledP ave_settlementP settlementP subtable) rnames(rowname)
	*Calculate %s of Total by subtable instead of overall // -------------------
	foreach col in "allegationsA" "allegationsP" {	
		bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
		gen pct = `col'/tot*100 // "% of Total"

		tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
			// so the table can be pasted straight into word

		drop tot pct
	}
	foreach col of varlist settled? {
		tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table
		replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
		drop `col'
	}
	* end %s of Total // -------------------------------------------------------
	order rowname obsA allegationsA allegationsA_pct_str settledA_pct_str ave_settlementA settlementA ///
				obsP allegationsP allegationsP_pct_str settledP_pct_str ave_settlementP settlementP
	replace rowname = "    " + rowname if ///
		!inlist(rowname, "Response_to_Allegation", "Retaliation_Against_WB")
	replace rowname = subinstr(rowname, "_", " ", .)
	
	foreach var in ave_settlementA settlementA ave_settlementP settlementP { 
		tostring `var', replace force format(%9.1f) 
			replace `var' = "$" + `var' if `var' != "." 
	} 
	 
	foreach var of varlist *_pct_str *settlement? { 
		replace `var' = "" if `var' == "." 
	} 
	drop subtable
	export excel "$dropbox/draft_tables.xls", sheet("Old 4.B") sheetrep first(var)
restore

} // end Panel B ---------------------------------------------------------------



* Panels DEF
if `run_4DEF' == 1 | `run_all' == 1 {
*------------------------------------
foreach panel in "D" "E" "F" { // --- These panels are nearly identical, just for different management classes

* --- Firm Response to Allegation --- *
	cap drop stlmt_* stld_*
	foreach var of varlist response_* {
		local response = substr("`var'", 10, .)
		gen stlmt_`response' = settlement if (`var' > 0)
		gen stld_`response' = settled if (`var' > 0)
	}
	preserve // -- first do Public firms
		if "`panel'" == "D" keep if mgmt_class == "Lower"
		if "`panel'" == "E" keep if mgmt_class == "Middle"
		if "`panel'" == "F" keep if mgmt_class == "Upper"
		
		keep if gvkey != . & wb_raised_issue_internally == "YES"

		collapse (sum) response_* stlmt* (mean) stld_* ave_coverup =stlmt_coverup ave_ignored=stlmt_ignored ///
											ave_int_inv=stlmt_int_inv ave_unknown=stlmt_unknown , fast
		ren response_* n* // for reshape
		gen i = _n
		reshape long n stld_ ave_ stlmt_, i(i) j(response) string
		egen obsP = total(n) // total observations not missing
		ren n allegationsP
		ren stlmt_ settlementP
		ren ave_ ave_settlementP
		ren stld_ settledP
			replace settledP = settledP*100
		tempfile public4`panel'1
		save `public4`panel'1', replace
	restore
	preserve // -- now do all firms
		if "`panel'" == "D" keep if mgmt_class == "Lower"
		if "`panel'" == "E" keep if mgmt_class == "Middle"
		if "`panel'" == "F" keep if mgmt_class == "Upper"
		
		keep if wb_raised_issue_internally == "YES"
		collapse (sum) response_* stlmt* (mean) stld_* ave_coverup =stlmt_coverup ave_ignored=stlmt_ignored ///
											ave_int_inv=stlmt_int_inv ave_unknown=stlmt_unknown , fast
		ren response_* n* // for reshape
		gen i = _n
		reshape long n stld_ ave_ stlmt_ , i(i) j(response) string
		egen obsA = total(n) // total observations not missing
		ren n allegationsA
		ren stlmt_ settlementA
		ren ave_ ave_settlementA
		ren stld_ settledA
			replace settledA = settledA*100		
		merge 1:1 response using `public4`panel'1', assert(3) nogen
		gen missing_response = response == "unknown"
		gsort missing_response -allegationsA -allegationsP
			br
			*pause
		mkmat obsA allegationsA settledA ave_settlementA settlementA ///
				obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(response)
	restore

	*store local string to input other all[] rows into the tab3 matrix
		local other_rows ""
		forval x=1/4 {
			local other_rows "`other_rows' ., all[`x',2..5], .,all[`x',7..10], 1" /* leave obs empty, fill in others */
			if `x' < 4 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab4`panel'1 = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 1 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat list tab4`panel'1
	if "`panel'" == "D" {
		mat rownames tab4`panel'1 = "Response_to_Allegation" "Ignored" "Cover_Up" "Internal_Investigation" "None_Mentioned"
	}
	if "`panel'" == "E" {
		mat rownames tab4`panel'1 = "Response_to_Allegation" "Ignored" "Cover_Up" "Internal_Investigation" "None_Mentioned"
	}
	if "`panel'" == "F" {
		mat rownames tab4`panel'1 = "Response_to_Allegation" "Ignored" "Cover_Up" "Internal_Investigation" "None_Mentioned"
	}

* --- Firm Retaliation Against Whistleblower --- *
	cap drop stlmt* stld_*
	foreach var of varlist retaliation_* {
		local retaliation = substr("`var'", 13, .)
		gen stlmt_`retaliation' = settlement if (`var' > 0)
		gen stld_`retaliation' = settled if (`var' > 0)
	}
	preserve // -- first do public firms
		if "`panel'" == "D" keep if mgmt_class == "Lower"
		if "`panel'" == "E" keep if mgmt_class == "Middle"
		if "`panel'" == "F" keep if mgmt_class == "Upper"
		
		keep if gvkey != . & wb_raised_issue_internally == "YES"

		collapse (sum) retaliation_* stlmt* (mean) stld_* ave_fired=stlmt_fired ave_none=stlmt_none ave_harassed=stlmt_harassed ///
											   ave_threat=stlmt_threat ave_quit=stlmt_quit ave_demotion=stlmt_demotion ///
											   ave_suspension=stlmt_suspension ave_lawsuit=stlmt_lawsuit , fast
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n stld_ ave_ stlmt_, i(i) j(retaliation) string
		egen obsP = total(n) // total observations not missing
		ren n allegationsP
		ren stlmt_ settlementP
		ren ave_ ave_settlementP
		ren stld_ settledP
			replace settledP = settledP*100
		tempfile public4`panel'2
		save `public4`panel'2', replace
	restore
	preserve // -- now do all firms
		if "`panel'" == "D" keep if mgmt_class == "Lower"
		if "`panel'" == "E" keep if mgmt_class == "Middle"
		if "`panel'" == "F" keep if mgmt_class == "Upper"
		
		keep if wb_raised_issue_internally == "YES"

		collapse (sum) retaliation_* stlmt* (mean) stld_* ave_fired=stlmt_fired ave_none=stlmt_none ave_harassed=stlmt_harassed ///
											   ave_threat=stlmt_threat ave_quit=stlmt_quit ave_demotion=stlmt_demotion ///
											   ave_suspension=stlmt_suspension ave_lawsuit=stlmt_lawsuit, fast
		ren retaliation_* n* // for reshape
		gen i = _n
		reshape long n stld_ ave_ stlmt_, i(i) j(retaliation) string
		egen obsA = total(n) // total observations not missing
		ren n allegationsA
		ren stlmt_ settlementA
		ren ave_ ave_settlementA
		ren stld_ settledA
			replace settledA = settledA * 100
		merge 1:1 retaliation using `public4`panel'2', assert(3) nogen
		gen no_ret = retaliation == "none"
		gsort no_ret -allegationsA -allegationsP
			br
			*pause
		mkmat obsA allegationsA settledA ave_settlementA settlementA ///
				obsP allegationsP settledP ave_settlementP settlementP, mat(all) rownames(retaliation)
	restore

	*store local string to input other all[] rows into the tab3 matrix
		local other_rows ""
		forval x=1/8 {
			local other_rows "`other_rows' ., all[`x',2..5], ., all[`x',7..10], 2" /* leave obs empty, fill in others */
			if `x' < 8 local other_rows "`other_rows' \ " // add line break if not end
		}
	mat tab4`panel'2 = (all[1,1], ., ., ., ., all[1,6], ., ., ., ., 2 \ /* put total non-missing obs on first line only */ ///
				`other_rows')
	mat list tab4`panel'2
	if "`panel'" == "D" {
		mat rownames tab4`panel'2 = "Retaliation_Against_WB" "Fired" "Harassed" "Threat" "Quit" ///
				"Demotion" "Suspension" "Lawsuit" "None_Mentioned"
	}
	if "`panel'" == "E" {
		mat rownames tab4`panel'2 = "Retaliation_Against_WB" "Fired" "Harassed" "Threat" "Demotion" "Quit" ///
				"Suspension" "Lawsuit" "None_Mentioned"
	}
	if "`panel'" == "F" {
		mat rownames tab4`panel'2 = "Retaliation_Against_WB" "Fired" "Harassed" "Threat" "Demotion" ///
				"Suspension" "Quit" "Lawsuit" "None_Mentioned"
	}

*--------------------------------------------
* Now export to excel workbook
	preserve
		drop _all
		mat full_tab4`panel' = (tab4`panel'1 \ tab4`panel'2)
		svmat2 full_tab4`panel', names(obsA allegationsA settledA ave_settlementA settlementA ///
										obsP allegationsP settledP ave_settlementP settlementP subtable) rnames(rowname)
		*Calculate %s of Total by subtable instead of overall // -------------------
		foreach col in "allegationsA" "allegationsP" {	
			bys subtable: egen tot = total(`col') // total cases, settlements, etc. to calculate % of total
			gen pct = `col'/tot*100 // "% of Total"

			tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
				// so the table can be pasted straight into word

			drop tot pct
		}
		foreach col of varlist settled? {
			tostring `col', gen(`col'_pct_str) format(%9.1f) force // percents for table
			replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0")
			drop `col'
		}
		* end %s of Total // -------------------------------------------------------
		order rowname obsA allegationsA allegationsA_pct_str settledA_pct_str ave_settlementA settlementA ///
					obsP allegationsP allegationsP_pct_str settledP_pct_str ave_settlementP settlementP
		replace rowname = "    " + rowname if ///
			!inlist(rowname, "Response_to_Allegation", "Retaliation_Against_WB")
		replace rowname = subinstr(rowname, "_", " ", .)
		
		tostring settlement?, replace force format(%9.1f)
			replace settlementA = "$" + settlementA if settlementA != "."
			replace settlementP = "$" + settlementP if settlementP != "."

		foreach var in ave_settlementA ave_settlementP { 
			tostring `var', replace force format(%9.1f) 
			replace `var' = "$" + `var' if `var' != "." 
		} 
	 
		foreach var of varlist *_pct_str *settlement* { 
			replace `var' = "" if `var' == "." 
		} 

		drop subtable
		export excel "$dropbox/draft_tables.xls", sheet("4.`panel'") sheetrep first(var)
	restore
} // end panel loop
} // end Panels D, E, and F ----------------------------------------------------------

