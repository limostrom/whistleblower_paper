/*

wb_data_import.do

Imports some excel sheets as stata datasets

*/


import excel "QTRACK_FOIA_Request_060313.xls", ///
	sheet("Settlement Judgment Information") cellrange(A2) first case(lower) clear
collapse (sum) total_federal_recovery relator_share (max) settlement_judgment_date, by(caption)
save total_settlements_from_qtrack.dta, replace

import excel "QTRACK_FOIA_Request_060313.xls", ///
	sheet("Case Information") first case(lower) clear
egen tagged = tag(caption primary_agency)
keep if tagged
duplicates tag caption, gen(dup)
	drop if dup & election_decision == "Declined" // one case w/ both DoD & Energy, but energy did not pursue it
keep caption primary_agency
save gov_agencies_from_qtrack.dta, replace

import excel "settlement.xlsx", first case(lower) clear
collapse (sum) total_federal_recovery relator_share, by(caption)
*merge 1:1 caption using total_settlements, update // 14 diagreements
save total_settlements.dta, replace
