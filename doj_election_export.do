import excel "C:\Users\dyu\Dropbox\Violation paper\whistleblower paper\QTRACK_FOIA_Request_060313.xls", sheet("Case Information") firstrow clear
gen election_day = date(Election_Date, "MDY")
format election_day %tdnn/dd/CCYY
drop Docket_Number Relator_Attorney Relator_Attorney_Law_Firm Defense_Attorney Defense_Attorney_Law_Firm Election_Date

ren *, lower
ren relator_name wb_full_name
egen tag_cap = tag(caption)
keep if tag_cap

replace caption = "US ex rel Dilback, Harold v General Electric Co" if caption == "US ex rel Lefan, Dennis; Gibson, Jason v General Electric Co"

replace caption = "US ex rel Rose, Sean; Aquino, Mary et al v Stephens Institute" if caption == "US ex rel Rose, Sean; Aquino, Mary et al v Stephens Institute; Academy of Art University et al"

replace caption = "US ex rel Richardson, Daniel C v Bristol-Myers Squibb" if caption == "US ex rel Richardson, Daniel C v Bristol-Myers Squibb; Sanofi-Aventis et al"

replace caption = "US; States of California; Delaware; Florida et al ex rel Doe, Jane& Mary v PDL Biopharma Inc et al" if caption == "US; States of California; Delaware; Florida et al ex rel Doe, John & Mary v PDL Biopharma Inc et al"

replace caption = "US ex rel Edwin Dunteman v Baudendistel, Lawrence MD; Tenet Healthsystem Sl-HLC Inc; St. Louis University" if caption == "US Ex Rel Dunteman, Edwin v Tenet Hlth Sys Sl-Hlc Inc DBA St Louis Univ Hosp"

save "C:\Users\dyu\Dropbox\Violation paper\whistleblower paper\doj_election_decision.dta", replace