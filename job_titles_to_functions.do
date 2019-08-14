/*
job_titles_to_functions.do

Coding employees by "function" based on their job title

*/

gen wb_function = ""
#delimit ;
replace wb_function = "Administrator" if (inlist(job_title, "Administrator", "Assistant",
								"Administrative Director", "Office Manager", "Front Office Manager",
								"Practice Administrator", "Patient Coordinator", "Care Coordinator"))
										& wb_function == "";
replace wb_function = "Auditor" if strpos(lower(job_title), "auditor") > 0 & wb_function == "";
replace wb_function = "Consultant" if (inlist(job_title, "Consultant", "Consulting Electrical Engineer",
								"Consultant Pharmacist", "System Integration Consultant"))
										& wb_function == "";
replace wb_function = "Finance/Accounting" if (strpos(lower(job_title), "accounting") > 0
									| strpos(lower(job_title), "accountant") > 0
									| strpos(lower(job_title), "accounts recievable") > 0 /* spelled wrong on purpose */
									| strpos(lower(job_title), "billing") > 0
									| strpos(lower(job_title), "controller") > 0
									| strpos(lower(job_title), "finance") > 0
									| strpos(lower(job_title), "reimbursement") > 0
									| strpos(lower(job_title), "account") > 0
									| job_title == "Cfo")
										& wb_function == "";
replace wb_function = "Health Professional" if (inlist(job_title, "Md", "Medical Technician",
								"Home Care Aid", "D.P.M.")
									| strpos(lower(job_title), "clinical") > 0
									| strpos(lower(job_title), "nurse") > 0
									| strpos(lower(job_title), "pharmac") > 0
									| strpos(lower(job_title), "physician") > 0
									| strpos(lower(job_title), "surgeon") > 0
									| strpos(lower(job_title), "cardiologist") > 0
									| strpos(lower(job_title), "therapist") > 0)
										& wb_function == "";
replace wb_function = "HR" if (strpos(lower(job_title), "human resource") > 0
									| strpos(lower(job_title), "human relations") > 0)
										& wb_function == "";
replace wb_function = "IT" if (inlist(job_title, "Information Technology Global Director",
								"It Recruiter") > 0)
										& wb_function == "";
replace wb_function = "Legal/Compliance" if (strpos(lower(job_title), "compliance") > 0
									| job_title == "Paralegal")
										& wb_function == "";
replace wb_function = "Marketing" if strpos(lower(job_title), "market") > 0 & wb_function == "";
replace wb_function = "Sales" if strpos(lower(job_title), "sale") > 0 & wb_function == "";
replace wb_function = "Operations" if strpos(lower(job_title), "operati") > 0 & wb_function == "";
replace wb_function = "Quality Assurance" if strpos(lower(job_title), "quality") > 0 & wb_function == "";
replace wb_function = "Unspecified" if inlist(job_title, "Employed", "Employee") & wb_function == "";
replace wb_function = "Other Manager" if (strpos(lower(job_title), "president") > 0
									| strpos(lower(job_title), "manage") > 0
									| strpos(lower(job_title), "director") > 0
									| strpos(lower(job_title), "executive") > 0)
										& wb_function == "";
replace wb_function = "Other Employee" if wb_function == "" & wb_function == "";
#delimit cr
