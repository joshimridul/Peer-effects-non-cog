
/*==========================================================================

Title: 3_addfixedeffects.do 
Author: Mridul Joshi
Date: [2020-08-24 19:26]	

Description: Demeans the variables used in the analysis and removes small
network components (<4)

Key input: ${datadir}/compmem.csv, ${datadir}/prefinal.dta
Key output: ${datadir}/regression_data.dta

===========================================================================*/


import delimited "${datadir}/compmem.csv", clear 

gen aid = string(v1, "%11.0g")
rename componentsg2membership component 
drop v1 

tempfile component
save `component'
	

u "${datadir}/prefinal.dta", clear 


merge 1:1 aid using `component', gen(_mcomp)


keep if _mcomp == 3 


tab fath_edu, gen(fath_ed_) mi
tab moth_edu, gen(moth_ed_) mi


ds conscientious emotional extravert white black asian native ///
   other_race school_performance sex age grade_7_8 grade_9_10 grade_11_12 ///
   max_parent_edu live_w_moth week_allowance dwelling_quality moth_occ_tech-fath_occ_miss ///
   hhsize moth_edu* sport_* club_* health physical_att smoke_drink any_phy_cond indep impulsive?

foreach v in `r(varlist)' {
	bys scid: egen mean_`v' = mean(`v')
	gen `v'_dm = `v' - mean_`v'

	drop mean_`v'
}


save "${datadir}/regression_data.dta", replace 


