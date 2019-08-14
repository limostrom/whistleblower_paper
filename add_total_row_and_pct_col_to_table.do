/*

add_total_row_and_pct_col_to_table.do

*/

local N = _N + 1
set obs `N' // add empty row to bottom of table (For "Total", 100%, etc.)

local column_order ""

foreach col of local tab_cols /* tab_cols assigned by calling do file */ {	
	egen tot = total(`col') // total cases, settlements, etc. to go at bottom of table
	gen pct = `col'/tot*100 // "% of Total"
		egen tot_pct = total(pct) // "100% to go at bottom of table

	tostring pct, gen(`col'_pct_str) format(%9.1f) force // percents for table
	replace `col'_pct_str = `col'_pct_str + "%" if !inlist(`col'_pct_str,".","0") // so the table can be pasted straight into word
	
	replace `col' = tot if _n == _N // fill in total number at bottom
	replace `col'_pct_str = string(tot_pct, "%9.1f") + "%" if _n == _N // fill in 100% at bottom

	drop tot pct tot_pct 
	local column_order "`column_order' `col' `col'_pct_str" // order columns as Number, Percent, Number, Percent, etc.
}

cap tostring `leftcol', replace force // in case rownames columns not already a string variable
replace `leftcol' = "Total" if _n == _N // fill in "Total" at bottom row of table
order `leftcol' `column_order' // order columns as Number, Percent, Number, Percent, etc.
