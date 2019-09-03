/*
Fama French 12 Industries

*/

#delimit ;

gen famafrench12 = 1 if inrange(sic, 100, 999)
					| inrange(sic, 2000, 2399)
					| inrange(sic, 2700, 2749)
					| inrange(sic, 2770, 2799)
					| inrange(sic, 3100, 3199)
					| inrange(sic, 3940, 3989);

replace famafrench12 = 2 if inrange(sic, 2500, 2519)
					| inrange(sic, 2590, 2599)
					| inrange(sic, 3630, 3659)
					| inrange(sic, 3710, 3711)
					| inrange(sic, 3714, 3714)
					| inrange(sic, 3716, 3716)
					| inrange(sic, 3750, 3751)
					| inrange(sic, 3792, 3792)
					| inrange(sic, 3900, 3939)
					| inrange(sic, 3990, 3999);

replace famafrench12 = 3 if inrange(sic, 2520, 2589)
					| inrange(sic, 2600, 2699)
					| inrange(sic, 2750, 2769)
					| inrange(sic, 3000, 3099)
					| inrange(sic, 3200, 3569)
					| inrange(sic, 3580, 3629)
					| inrange(sic, 3700, 3709)
					| inrange(sic, 3712, 3713)
					| inrange(sic, 3715, 3715)
					| inrange(sic, 3717, 3749)
					| inrange(sic, 3752, 3791)
					| inrange(sic, 3793, 3799)
					| inrange(sic, 3830, 3839)
					| inrange(sic, 3860, 3899);

replace famafrench12 = 4 if inrange(sic, 1200, 1399)
					| inrange(sic, 2900, 2999);

replace famafrench12 = 5 if inrange(sic, 2800, 2829)
					| inrange(sic, 2840, 2899);

replace famafrench12 = 6 if inrange(sic, 3570, 3579)
					| inrange(sic, 3660, 3692)
					| inrange(sic, 3694, 3699)
					| inrange(sic, 3810, 3829)
					| inrange(sic, 7370, 7379);

replace famafrench12 = 7 if inrange(sic, 4800, 4899);

replace famafrench12 = 8 if inrange(sic, 4900, 4949);

replace famafrench12 = 9 if inrange(sic, 5000, 5999)
					| inrange(sic, 7200, 7299)
					| inrange(sic, 7600, 7699);

replace famafrench12 = 10 if inrange(sic, 2830, 2839)
					| inrange(sic, 3693, 3693)
					| inrange(sic, 3840, 3859);

replace famafrench12 = 11 if inrange(sic, 6000, 6999);

replace famafrench12 = 12 if famafrench12 == . & sic != .;

lab def ffindustries 1 "Consumer Non-Durables"
					 2 "Consumer Durables"
					 3 "Manufacturing"
					 4 "Energy - Oil, Gas, and Coal Extraction and Products"
					 5 "Chems  Chemicals and Allied Products"
					 6 "Business Equipment"
					 7 "Telecommunications"
					 8 "Utilities"
					 9 "Shops - Wholesale, Retail, and Some Services"
					 10 "Healthcare, Medical Equipment, and Drugs"
					 11 "Money Finance"
					 12 "Other Industries (e. g. Mines, Construction, Transportation)";

lab val famafrench12 ffindustries

#delimit cr