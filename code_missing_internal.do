/*

code_missing_internal.do

Code whistleblowers as internal or not based on the court filings if possible;
	also fill in wb job titles at fraud firm if possible

	-> choosing to replace individual cases so long as their values of internal
	are missing because we can't merge in on case_id (case_ids are not unique)
*/

#delimit ;
replace internal = 1 if internal == . & (inlist(case_id, 146,
														183,
														330,
														474,
														607,
														965,
														1090,
														1714,
														1821)
										| inlist(case_id, 2398,
														2609,
														2622,
														3417,
														3576,
														3599,
														3741,
														4314,
														4706,
														5503));
replace internal = 0 if internal == . & (inlist(case_id, 1698,
														1793,
														1892,
														2001)
										| inlist(case_id, 2259,
														/*2414,*/
														3686,
														4308,
														4688));
#delimit cr
replace internal = 1 if internal == . & case_id == 230 & wb_full_name == "Edwards, Linda"
replace internal = 1 if internal == . & case_id == 324 & ///
				inlist(wb_full_name, "Freeman, Billy D.", "Lovelace, David A.")
	replace internal = 0 if internal == . & case_id == 324 // probably would have been mentioned if they were employees
replace internal = 0 if internal == . & case_id == 2098 & ///
				wb_full_name == "Parker, John M."

replace job_title_at_fraud_firm = "Medical Director" if case_id == 183 ///
									& wb_full_name == "Butler, F Kevin"
replace job_title_at_fraud_firm = "National Account Manager" if case_id == 330 ///
									& wb_full_name == "Foster, John David"
replace job_title_at_fraud_firm = "Chief Executive Officer" if case_id == 474 ///
									& wb_full_name == "Thompson, Mark E."
replace job_title_at_fraud_firm = "Physician" if case_id == 607 ///
									& wb_full_name == "Gerth, M.D., Elias"
replace job_title_at_fraud_firm = "Accountant" if case_id == 965
	replace wb_full_name = "Carbaugh, David R." if case_id == 965 // Rel. Trice not actually listed in pdf file?
replace job_title_at_fraud_firm = "Billing Processor" if case_id == 1090 ///
									& wb_full_name == "Rodriguez, Alexis"

replace job_title_at_fraud_firm = "Team Leader" if case_id == 3599 ///
									& wb_full_name == "Gibbons, Kimberly L."
replace job_title_at_fraud_firm = "Tribe Members" if case_id == 3741 ///
									& wb_full_name == "Crocker, Lisa"
replace job_title_at_fraud_firm = "Occupational Therapist" if case_id == 4314 ///
									& wb_full_name == "Rey, Mario"
replace job_title_at_fraud_firm = "Medical billing specialist" if case_id == 4706 ///
									& wb_full_name == "Ford, Tiffany"
replace job_title_at_fraud_firm = "Anesthesia Doctor" if case_id == 5503 ///
									& wb_full_name == "Leff, David A."
									
replace wb_description_external = "Customer" if case_id == 1793 ///
									& wb_full_name == "Charlotte Murphy"
replace wb_description_external = "Family of deceased patient" if case_id == 1892 ///
									& wb_full_name == "Greenberg-Udell, Estelle"
replace wb_description_external = "Tenant" if case_id == 2001 ///
									& wb_full_name == "Schwarz, Karl W."
replace wb_description_external = "Prisoner/Customer" if case_id == 2259 ///
									& wb_full_name == "A/K/A Qadosh, Shaddia"
/*replace wb_description_external = "Customer" if case_id == 2414 ///
									& wb_full_name == ""*/
replace wb_description_external = "Customer" if case_id == 4308 ///
									& wb_full_name == "Null"
*------------------------------------------------------------
replace wb_raised_issue_internally = "YES" if wb_raised_issue_internally == "" ///
		& case_id == 2599 & wb_full_name == "Fields, Faye"
*------------------------------------------------------------
replace internal_explanation = "Former CFO, asked to step down following merger" ///
	if case_id == 230 & wb_full_name == "Edwards, Linda"
replace internal_explanation = "Missing court filing" ///
	if internal == . & inlist(case_id, 2962, 4086, 5517, 5624, 5627, 342)

replace internal_explanation = "Unclear in court filing" ///
	if internal_explanation == "" & internal == .

