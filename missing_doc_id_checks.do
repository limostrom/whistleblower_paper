/*
missing_doc_id_checks.do


*/

cap cd "C:\Users\lmostrom\Dropbox\Violation paper\whistleblower paper\"
include wb_data_clean.do

gen missing_doc_id = doc_id == .
collapse (count) n_allegations = case_id (sum) n_miss_doc_id = missing_doc_id ///
		 (max) doc_id, by(caption) fast

assert n_miss_doc_id == 0 | n_miss_doc_id == n_allegations

br


