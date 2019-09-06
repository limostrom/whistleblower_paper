/*
job_titles_to_functions.do

Coding employees by "function" based on their job title

*/

gen wb_function = ""
#delimit ;

replace wb_function = "Auditor" if strpos(lower(job_title), "audit") > 0 & wb_function == "";
replace wb_function = "Legal/Compliance" if (strpos(lower(job_title), "compliance") > 0
									| inlist(job_title, "Paralegal", "Attorney")
									| strpos(lower(job_title), "litigation") > 0
									| strpos(lower(job_title), "six sigma green belt") > 0
									| strpos(lower(job_title), "investigat") > 0
									| strpos(lower(job_title), "contract specialist") > 0
									| strpos(lower(job_title), "freedom of information") > 0
									| strpos(lower(job_title), "government contract") > 0
									| strpos(lower(job_title), "cco; vice president of ethics") > 0)
										& wb_function == "";
replace wb_function = "Quality Assurance" if (strpos(lower(job_title), "quality") > 0
									| strpos(lower(job_title), "inspector") > 0)
										& wb_function == "";

replace wb_function = "Finance/Accounting" if (strpos(lower(job_title), "accounting") > 0
									| strpos(lower(job_title), "accountant") > 0
									| strpos(lower(job_title), "accounts recievable") > 0 /* spelled wrong on purpose */
									| strpos(lower(job_title), "controller") > 0
									| strpos(lower(job_title), "finance") > 0
									| strpos(lower(job_title), "financial analyst") > 0
									| strpos(lower(job_title), "financial assistant") > 0
									| strpos(lower(job_title), "financial planning") > 0
									| strpos(lower(job_title), "reimbursement") > 0
									| strpos(lower(job_title), "account") > 0
									| strpos(lower(job_title), "comptroller") > 0
									| strpos(lower(job_title), "chief executive officer") > 0
									| strpos(lower(job_title), "board member") > 0
									| strpos(lower(job_title), "board of directors") > 0
									| strpos(lower(job_title), "president/ceo") > 0
									| strpos(lower(job_title), "president/treasurer") > 0
									| strpos(lower(job_title), "revenue") > 0
									| inlist(job_title, "Cfo", "Ceo", "Chief Financial Officer",
													"Vice President; CFO", "Founder"))
										& wb_function == "";

replace wb_function = "Billing" if strpos(lower(job_title), "billing") > 0
									| strpos(lower(job_title), "billilng") > 0
									| strpos(lower(job_title), "biller") > 0
									| job_title == "Patient Financial Services";

replace wb_function = "Health Professional" if (inlist(job_title, "Md",	"Md; Partner", "Home Care Aid", "PDS Supervisor",
										"D.P.M.", "EMT", "Paitent Coordinator", "Surgicial Technologist", "Lcsw")
									| strpos(lower(job_title), "clinical") > 0
									| strpos(lower(job_title), "nurse") > 0
									| strpos(lower(job_title), "nursing") > 0
									| strpos(lower(job_title), "pharmac") > 0
									| strpos(lower(job_title), "physician") > 0
									| strpos(lower(job_title), "physican") > 0
									| strpos(lower(job_title), "surgeon") > 0
									| strpos(lower(job_title), "cardiologist") > 0
									| strpos(lower(job_title), "therap") > 0
									| strpos(lower(job_title), "psychiatr") > 0
									| strpos(lower(job_title), "orthopaed") > 0
									| (strpos(lower(job_title), "ob") > 0 & strpos(lower(job_title), "gyn") > 0)
									| strpos(lower(job_title), "medical") > 0
									| strpos(lower(job_title), "medicial") > 0
									| strpos(lower(job_title), "neurologist") > 0
									| strpos(lower(job_title), "dental") > 0
									| strpos(lower(job_title), "doctor") > 0
									| strpos(lower(job_title), "emergency medical technician") > 0
									| strpos(lower(job_title), "dermatologist") > 0
									| strpos(lower(job_title), "chiropractor") > 0
									| strpos(lower(job_title), "anesthesi") > 0
									| strpos(lower(job_title), "anaesthesi") > 0
									| strpos(lower(job_title), "coder") > 0
									| strpos(lower(job_title), "pain clinic") > 0
									| strpos(lower(job_title), "emergency room") > 0
									| strpos(lower(job_title), "hospital") > 0
									| strpos(lower(job_title), "hosiptal") > 0
									| strpos(lower(job_title), "psychologist") > 0
									| strpos(lower(job_title), "patholog") > 0
									| strpos(lower(job_title), "otolaryng") > 0
									| strpos(lower(job_title), "pharm.d") > 0
									| strpos(lower(job_title), "radiologist") > 0
									| strpos(lower(job_title), "radiation") > 0
									| strpos(lower(job_title), "substance abuse") > 0
									| strpos(lower(job_title), "orthoti") > 0
									| strpos(lower(job_title), "ophthalm") > 0
									| strpos(lower(job_title), "optometrist") > 0
									| strpos(lower(job_title), "oncolog") > 0
									| strpos(lower(job_title), "patient") > 0
									| strpos(lower(job_title), "phlebotomist") > 0
									| strpos(lower(job_title), "pediatric") > 0
									| strpos(lower(job_title), "podiatrist") > 0
									| strpos(lower(job_title), "prosthetic") > 0
									| strpos(lower(job_title), "hmo ") > 0
									| strpos(lower(job_title), "x-ray") > 0
									| strpos(lower(job_title), "wound care") > 0
									| strpos(lower(job_title), "clinic") > 0
									| strpos(lower(job_title), "audiologist") > 0
									| strpos(lower(job_title), "laboratory") > 0
									| strpos(lower(job_title), "medicare") > 0
									| strpos(lower(job_title), "pain management") > 0
									| strpos(lower(job_title), "paramedic") > 0
									| strpos(lower(job_title), "social worker") > 0
									| strpos(lower(job_title), "medicaid") > 0
									| strpos(lower(job_title), "counseling") > 0
									| strpos(lower(job_title), "conseling") > 0
									| strpos(lower(job_title), "health") > 0
									| strpos(lower(job_title), "iv infusion") > 0
									| strpos(lower(job_title), "laboratory") > 0
									| strpos(lower(job_title), "psych-social") > 0
									| strpos(lower(job_title), "rn case manager") > 0
									| strpos(lower(job_title), "hospice") > 0
									| strpos(lower(job_title), "endocrine") > 0
									| strpos(lower(job_title), "vascular") > 0
									| strpos(lower(job_title), "outreach lab") > 0
									| strpos(lower(job_title), "psd medic") > 0
									| strpos(lower(job_title), "referral coordinator") > 0
									| strpos(lower(job_title), "infection") > 0
									| strpos(lower(job_title), "surgery") > 0
									| strpos(lower(job_title), "burn, trauma") > 0
									| strpos(lower(job_title), "dentist") > 0
									| strpos(lower(job_title), "gcms technologist") > 0
									| strpos(lower(job_title), "neurosurg") > 0
									| strpos(lower(job_title), "althomatic assistant") > 0
									| strpos(lower(job_title), "cancer") > 0
									| strpos(lower(job_title), "diabetes") > 0
									| strpos(lower(job_title), "lab manager") > 0
									| strpos(lower(job_title), "lab processor") > 0
									| strpos(lower(job_title), "lab secretary") > 0
									| strpos(lower(job_title), "sleep lab") > 0
									| strpos(lower(job_title), "sleep technologist") > 0
									| strpos(lower(job_title), "saic scientist") > 0
									| inlist(job_title), "Practice Administrator", "Patient Coordinator",
													"Care Coordinator", "Mds Coordinator", "Mica Care Coordinator")
										& wb_function == "";

replace wb_function = "Administrator" if (inlist(job_title, "Administrator", "Assistant",
								"Administrative Director", "Office Manager", "Front Office Manager")
								| strpos(lower(job_title), "administrat") > 0
								| strpos(lower(job_title), "admininistrat") > 0)
										& wb_function == "";
replace wb_function = "Consultant" if (inlist(job_title, "Consultant", "Consulting Electrical Engineer",
								"Consultant Pharmacist", "System Integration Consultant"))
										& wb_function == "";
replace wb_function = "HR" if (strpos(lower(job_title), "human resource") > 0
									| strpos(lower(job_title), "human relations") > 0)
										& wb_function == "";
replace wb_function = "IT" if (inlist(job_title, "Information Technology Global Director",
								"It Recruiter") > 0)
										& wb_function == "";
replace wb_function = "Marketing" if strpos(lower(job_title), "market") > 0 & wb_function == "";
replace wb_function = "Sales" if strpos(lower(job_title), "sale") > 0 & wb_function == "";
replace wb_function = "Operations" if (strpos(lower(job_title), "operati") > 0
									| strpos(lower(job_title), "admission") > 0
									| strpos(lower(job_title), "professor") > 0
									| strpos(lower(job_title), "mechanic") > 0
									| strpos(lower(job_title), "engineer") > 0
									| strpos(lower(job_title), "truck driver") > 0
									| strpos(lower(job_title), "hvac") > 0)
									& wb_function == "";
	replace wb_function = "Operations" if wb_function == "" & internal == 1 & job_title != "";
#delimit cr

