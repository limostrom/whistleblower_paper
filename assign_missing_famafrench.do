/*
Code Fama-French Industries for Companies Missing SIC

*/

#delimit ;
replace famafrench12 = 10 /* healthcare */ 
						if inlist(conm, "BROOKWOOD HEALTH SRVCS INC",
										"CAREMARK",
										"COMMUNITY HEALTH COMPUTING",
										"CONTINENTAL MEDICAL SYSTEMS",
										"CRITICAL CARE AMER INC",
										"DIAGNOSTIC MEDICAL INSTR INC",
										"FAMILY HEALTH SYSTEMS INC",
										"HEALTHCARE USA INC",
										"MEDCO GROUP INC")
						| inlist(conm, "MILLENNIUM PHARMACEUTICALS",
										"NATIONAL HEALTH ENTERPRISES",
										"NATIONAL MEDICAL CARE",
										"ORTHOPEDIC SERVICES INC",
										"PROVIDENCE HEALTH CARE INC",
										"QUALITY CARE INC",
										"UNITED MEDICAL CORP");

replace famafrench12 = 9 /* Retail/Services */ if conm == "HORIZON CORP";

replace famafrench12 = 3 /* Manufacturing */ 
						if inlist(conm, "KANE INDUSTRIES INC",
										"KAPLAN INDUSTRIES INC");

replace famafrench12 = 12 /* Other - Engineering & Construction */
						if conm == "METCALF & EDDY COS INC";

replace famafrench12 = 7 /* Telecommunications */ if conm == "METROMEDIA INC";

replace famafrench12 = 11 /* Finance/Insurance */ if conm == "UNITED HOME LIFE INS CO";

replace famafrench12 = 4 /* Energy */ if conm == "WESTINGHOUSE CANADA INC";

#delimit cr