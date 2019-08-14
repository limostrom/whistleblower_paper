
gen wb_function2 = ""

replace wb_function2 = "Auditor" if strpos(lower(job_title_at_fraud_firm), "auditor") > 0 ///
									& wb_function2 == ""
replace wb_function2 = "Finance/Accouting" if (strpos(lower(job_title), "accounting") > 0 ///
									| strpos(lower(job_title), "accountant") > 0 ///
									| strpos(lower(job_title), "accounts recievable") > 0 ///
									| strpos(lower(job_title), "billing") > 0 ///
									| strpos(lower(job_title), "controller") > 0 ///
									| strpos(lower(job_title), "finance") > 0 ///
									| strpos(lower(job_title), "reimbursement") > 0 ///
									| strpos(lower(job_title), "account") > 0 ///
									| job_title == "Cfo") ///
										& wb_function2 == "";
replace wb_function2 = "General Consel/Legal" if (inlist(job_title_at_fraud_firm, ///
												"Consultant",  ///
												"Consulting Electrical Engineer", ///
												"Consultant Pharmacist", ///
												"System Integration Consultant")) 
												
replace wb_function2 = "General Consel/Legal" if (strpos(lower(job_title), "compliance") > 0 ///
									 | job_title == "paralegal") ///
										& wb_function2 == ""		
replace wb_function2 = "Health Professional" if (inlist(job_title, "Md", "Medical Technician", ///
								"Home Care Aid", "D.P.M.") ///
									| strpos(lower(job_title), "clinical") > 0 ///
									| strpos(lower(job_title), "nurse") > 0 ///
									| strpos(lower(job_title), "pharmac") > 0 ///
									| strpos(lower(job_title), "physician") > 0 ///
									| strpos(lower(job_title), "surgeon") > 0 ///
									| strpos(lower(job_title), "cardiologist") > 0 ///
									| strpos(lower(job_title), "therapist") > 0) ///
										& wb_function2 == "";										
replace wb_function2 = "HR" if (strpos(lower(job_title_at_fraud_firm), "human resources") > 0 ///
									| strpos(lower(job_title_at_fraud_firm), "human relations") > 0) ///
										& wb_function2 == ""
replace wb_function2 = "Operations" if strpos(lower(job_title), "operati") > 0 & wb_function2 == "" 
replace wb_function2 = "Sales" if strpos(lower(job_title), "sale") > 0 & wb_function2 == "";

replace wb_function2 = "Other" if job_title_at_fraud_firm != "" & wb_function2 == ""
replace wb_function2 = "Unspecified" if wb_function2 == ""
