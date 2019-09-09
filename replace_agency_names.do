/*
replace_agency_names.do

For Table 1 Panel D
*/

replace primary_agency = "Department of Health and Human Services" if primary_agency == "HHS"
replace primary_agency = "Department of Defense" if primary_agency == "DOD"
replace primary_agency = "General Services Administration" if primary_agency == "GSA"
replace primary_agency = "Department of Education" if primary_agency == "Education, Dept of"
replace primary_agency = "Department of the Interior" if primary_agency == "Interior, Dept of"
replace primary_agency = "Department of Energy" if primary_agency == "Energy, Dept of"
replace primary_agency = "Department of Homeland Security" if primary_agency == "Homeland Security"
replace primary_agency = "Department of Housing and Urban Development" if primary_agency == "HUD"
replace primary_agency = "Department of the Treasury" if primary_agency == "Treasury, Dept of"
replace primary_agency = "US Postal Service" if primary_agency == "Postal Service"
replace primary_agency = "Department of State" if primary_agency == "State, Dept of"
replace primary_agency = "Department of Veterans' Affairs" if primary_agency == "DVA"
replace primary_agency = "Department of Labor" if primary_agency == "Labor, Dept of"
replace primary_agency = "Department of Transportation" if primary_agency == "DOT"
replace primary_agency = "Department of Justice" if primary_agency == "Justice, Dept of"
replace primary_agency = "Agency for International Development" if primary_agency == "Agcy for Intnl Dev"
replace primary_agency = "Federal Communications Commission" if primary_agency == "FCC"
replace primary_agency = "Environmental Protection Agency" if primary_agency == "EPA"
replace primary_agency = "Social Security Administration" if primary_agency == "SSA"
replace primary_agency = "Department of Agriculture" if primary_agency == "Agriculture, Dept of"
replace primary_agency = "Equal Employment Opportunity Commission" if primary_agency == "EEOC"
replace primary_agency = "Department of Commerce" if primary_agency == "Commerce, Dept of"
replace primary_agency = "Tennessee Valley Authority" if primary_agency == "TVA"
replace primary_agency = "Office of Personnel Management" if primary_agency == "OPM"
replace primary_agency = "Federal Deposit Insurance Corporation" if primary_agency == "FDIC"
replace primary_agency = "Federal Reserve System" if primary_agency == "Fed Reserve Sys Bd"
replace primary_agency = "Small Business Administration" if primary_agency == "SBA"
replace primary_agency = "Nuclear Regulatory Commission" if primary_agency == "NRC"
replace primary_agency = "National Foundation on the Arts and Humanities" if primary_agency == "Natl Found Arts/Hum"
replace primary_agency = "Export-Import Bank of the US" if primary_agency == "Exp-Imp Bank of US"
replace primary_agency = "Office of the President" if primary_agency == "Exec Ofc/President"
replace primary_agency = "Unknown" if inlist(primary_agency, "", "Agcy Unk/Not Applic")

