/*
assign_global_filepaths.do

Figures out whether this is running on Lauren or Dolly's computer and
	saves globals for (i) the do file repository and (ii) the Dropbox folder
	for outputs

*/

cap cd "C:/Users/lmostrom/" // if on Lauren's computer
cap cd "C:/Users/yyu/" // if on Dolly's computer

global repo "Documents/GitHub/whistleblower_paper/"
gloabl dropbox "Dropbox/Violation paper/whistleblower paper/"
