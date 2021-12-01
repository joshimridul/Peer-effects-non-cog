
/*==========================================================================

Title: 4_regressions.do 
Author: Mridul Joshi
Date: [2020-07-30 01:26]	

Description: Estimate the main regressions of the paper and produce tables

Key input: ${datadir}/regression_data.dta
Key output: Final latex tables 

===========================================================================*/




* ===================================================================== *
* -----------------    Data for dyadic regression     ----------------- *
* ===================================================================== *

import delimited "${datadir}/compmem.csv", clear 

gen aid = string(v1, "%11.0g")
rename componentsg2membership component 
drop v1 

tempfile component
save `component'
	


u "${datadir}/prefinal.dta", clear 


merge 1:1 aid using `component', gen(_mcomp)

keep if _mcomp == 3 




keep aid white black asian school_performance sex age grade_7_8 grade_9_10 grade_11_12 max_parent_edu smoke_drink scid component ///
	 moth_occ_* fath_occ_* sport_* club_?

tab scid, gen(sch_)
tab component, gen(comp_)


destring aid, replace 

ds aid, not

foreach v in `r(varlist)' {
	rename `v' `v'_aid 
}

tempfile dyad_aid
save `dyad_aid'


rename *_aid *_frid
rename aid fr_id

tempfile dyad_frid
 save `dyad_frid'

 

import delimited using "${datadir}/dyad_reg_data.csv", clear 

drop if aid == fr_id

merge m:1 aid using `dyad_aid', gen(_m1)

keep if _m1 == 3 

merge m:1 fr_id using `dyad_frid', gen(_m2)

keep if _m1 == 3 



* create absolute differences 

ds white_aid black_aid asian_aid school_performance_aid sex_aid age_aid grade_7_8_aid grade_9_10_aid grade_11_12_aid max_parent_edu_aid ///
smoke_drink_aid moth_occ_*_aid fath_occ_*_aid sport_*_aid club_?_aid


foreach v in `r(varlist)' {
	local t =subinstr("`v'", "_aid","",1)

	gen abs_`t' = abs(`t'_aid - `t'_frid)

}


eststo clear 

eststo: reg link abs_* comp_*

predict residual

save "${datadir}/dyadic_predicted.dta", replace 




** adjacency matrix 

import delimited using "${datadir}/adj_dir.csv", clear

drop in 1 
cap drop aid
rename v1 aid

spmat dta peer v2-v2309, id(aid) replace norm(row)


* covariates

u "${datadir}/dyadic_predicted.dta", clear 

collapse (mean) residual, by(aid)

keep aid residual

tempfile resi
save `resi'
 


u "${datadir}/regression_data.dta", clear 

destring aid, replace 


merge 1:1 aid using `resi', gen(_mresi)


cap destring aid, replace 

* ===================================================================== *
* -----------------      Create lagged variables      ----------------- *
* ===================================================================== *



ds conscientious emotional extravert white black asian native ///
   other_race school_performance sex age grade_7_8 grade_9_10 grade_11_12 ///
   max_parent_edu live_w_moth week_allowance dwelling_quality moth_occ_tech-fath_occ_miss ///
   hhsize moth_edu? sport_main sport_oth club_? health physical_att smoke_drink any_phy_cond indep


foreach v in `r(varlist)' {
	spmat lag double w`v' peer `v'
	spmat lag double w2`v' peer w`v'
	spmat lag double w`v'_dm peer `v'_dm
	spmat lag double w2`v'_dm peer w`v'_dm
	spmat lag double w3`v'_dm peer w2`v'_dm  
}


bys scid: egen mean_residual = mean(residual)
gen residual_dm = residual - mean_residual

drop mean_residual



* ===================================================================== *
* -----------------    Label variables for reg        ----------------- *
* ===================================================================== *

lab  var white_dm "White"
lab  var school_performance_dm "School performance (GPA)"
lab  var sex_dm "Female"
lab  var age_dm "Age"
lab  var grade_7_8_dm "Grades 7-8"
lab  var grade_9_10_dm "Grades 9-10"
lab  var dwelling_quality_dm "Residence building quality"
lab  var hhsize_dm "Household size"
lab  var max_parent_edu_dm "Parental education"
lab  var live_w_moth_dm  "Lives with mother"
lab  var smoke_drink_dm "Smokes or drinks"

lab  var wwhite_dm "Proportion white peers"
lab  var wschool_performance_dm "Peers' average GPA"
lab  var wsex_dm "Proportion female friends"
lab  var wage_dm "Peers' average age"
lab  var wgrade_7_8_dm "Proportion peers in grades 7-8"
lab  var wgrade_9_10_dm "Proportion peers in grades 9-10"
lab  var wdwelling_quality_dm "Peers' average residential building quality"
lab  var whhsize_dm "Peers' average household size"
lab  var wmax_parent_edu_dm "Peers' average parental education"
lab  var wlive_w_moth_dm "Proportion peers live with mother"
lab  var wsmoke_drink_dm "Proportion peers smoke or drink"


* ===================================================================== *
* -----------------     	  Emotional Stability     ----------------- *
* ===================================================================== *


eststo clear 

*** IV 
eststo: spreg gs2sls emotional_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer) het 

estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

predict pr_emot_iv_na , xb 


/* *** IV + Spatial errors 
eststo: spreg gs2sls emotional_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer) elmat(peer)

predict pr_emot_iv_au, xb 


*** ML 
eststo: spreg ml emotional_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer)

predict pr_emot_ml_na, xb  */


*** ML + Spatial errors
eststo: spreg ml emotional_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm, id(aid) dlmat(peer) elmat(peer) 


estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


predict pr_emot_ml_au, xb 

* ===================================================================== *
* -----------------     	  Extraversion            ----------------- *
* ===================================================================== *


*** IV 
eststo: spreg gs2sls extravert_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		 wdwelling_quality_dm hhsize_dm whhsize_dm  max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
	    fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm , id(aid) dlmat(peer) het 


estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


predict pr_extr_iv_na, xb 


/* *** IV + Spatial errors 
eststo: spreg gs2sls extravert_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer) elmat(peer)

predict pr_extr_iv_au, xb 


*** ML 
eststo: spreg ml extravert_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer)

predict pr_extr_ml_na, xb
 */

*** ML + Spatial errors
eststo: spreg ml extravert_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm , id(aid) dlmat(peer) elmat(peer) 

estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


predict pr_extr_ml_au, xb  



* ===================================================================== *
* -----------------     	  Conscientiousness       ----------------- *
* ===================================================================== *


*** IV 
eststo: spreg gs2sls conscientious_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm   smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer) het 

estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


predict pr_cons_iv_na, xb


*** IV + Spatial errors 
/* eststo: spreg gs2sls conscientious_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer) elmat(peer)

predict pr_cons_iv_au, xb
 */

*** ML 
/* eststo: spreg ml conscientious_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer)

predict pr_cons_ml_na, xb */


*** ML + Spatial errors
eststo: spreg ml conscientious_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm   smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm , id(aid) dlmat(peer) elmat(peer)


estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

predict pr_cons_ml_au, xb

esttab 


* ===================================================================== *
* -----------------     	  Save dataset            ----------------- *
* ===================================================================== *

save "${datadir}/postreg.dta", replace  


local varlab1 "2SLS"
local varlab2 "ML" 
local varlab3 "2SLS"
local varlab4 "ML"
local varlab5 "2SLS"
local varlab6 "ML"

#delimit ;

loc tablerow sex_dm age_dm white_dm school_performance_dm dwelling_quality_dm hhsize_dm max_parent_edu_dm live_w_moth_dm smoke_drink_dm
			 wsex_dm wage_dm wwhite_dm wschool_performance_dm wdwelling_quality_dm whhsize_dm wmax_parent_edu_dm wlive_w_moth_dm wsmoke_drink_dm _cons;

	esttab using "${outdir}/table_main.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{6}{>{\centering\arraybackslash}m{3.0cm}}}
		\toprule \toprule \\
		& \multicolumn{2}{c}{\textit{Emotional Stability}} & \multicolumn{2}{c}{\textit{Extraversion}} & \multicolumn{2}{c}{\textit{Conscientiousness}} \\\\ 
		& `varlab1' &`varlab2' &`varlab3' &`varlab4' &`varlab5' &`varlab6'\\")
		keep(`tablerow') order(`tablerow')	
	stats(N sch_fe grad_dum occu_dum club_dum, labels("" "School fixed effects" "Grade dummies" "Parent occupation dummies" "Extracurricular dummies") 
	fmt(%20s %20s)) 
	addnotes( 
    "Notes: Standard errors (in parentheses)."
    "* p<0.05, ** p<0.01, *** p<0.001" ) ;
#delimit cr




* ===================================================================== *
* -----------------    Instrument diagnostics         ----------------- *
* ===================================================================== *

destring scid, gen(school)

eststo clear 

eststo: ivreg2 emotional_dm white school_performance sex age grade_7_8 grade_9_10 grade_11_12 dwelling_quality hhsize max_parent_edu ///
	   live_w_moth smoke_drink sport_main sport_oth school_performance i.school fath_occ_man fath_occ_manual fath_occ_farm fath_occ_miss ///
	   (wemotional  = wwhite wschool_performance wsex wage wgrade_7_8 wgrade_9_10 wgrade_11_12 wdwelling_quality ///
	   whhsize wmax_parent_edu wlive_w_moth wsmoke_drink wsport_main wsport_oth wclub_? w2white w2school_performance ///
	   w2sex w2age w2grade_7_8 w2grade_9_10 w2grade_11_12 w2dwelling_quality w2hhsize w2max_parent_edu w2live_w_moth ///
	   w2smoke_drink w2sport_main w2sport_oth wfath_occ_man wfath_occ_manual wfath_occ_farm wfath_occ_miss w2fath_occ_man ///
	   w2fath_occ_manual w2fath_occ_farm w2fath_occ_miss ) 

estadd scalar anderson `e(idp)'
estadd scalar  fstat `e(widstat)'
estadd scalar  sarg `e(sarganp)'


eststo: ivreg2 extravert white school_performance sex age grade_7_8 grade_9_10 grade_11_12 dwelling_quality hhsize max_parent_edu ///
	   live_w_moth smoke_drink sport_main sport_oth school_performance i.school fath_occ_man fath_occ_manual fath_occ_farm fath_occ_miss ///
	   (wextravert  = wwhite wschool_performance wsex wage wgrade_7_8 wgrade_9_10 wgrade_11_12 wdwelling_quality ///
	   whhsize wmax_parent_edu wlive_w_moth wsmoke_drink wsport_main wsport_oth wclub_? w2white w2school_performance ///
	   w2sex w2age w2grade_7_8 w2grade_9_10 w2grade_11_12 w2dwelling_quality w2hhsize w2max_parent_edu w2live_w_moth ///
	   w2smoke_drink w2sport_main w2sport_oth wfath_occ_man wfath_occ_manual wfath_occ_farm wfath_occ_miss w2fath_occ_man ///
	   w2fath_occ_manual w2fath_occ_farm w2fath_occ_miss ) 

estadd scalar anderson `e(idp)'
estadd scalar fstat `e(widstat)'
estadd scalar sarg `e(sarganp)'


eststo: ivreg2 conscientious white school_performance sex age grade_7_8 grade_9_10 grade_11_12 dwelling_quality hhsize max_parent_edu ///
	   live_w_moth smoke_drink sport_main sport_oth school_performance i.school fath_occ_man fath_occ_manual fath_occ_farm fath_occ_miss ///
	   (wconscientious  = wwhite wschool_performance wsex wage wgrade_7_8 wgrade_9_10 wgrade_11_12 wdwelling_quality ///
	   whhsize wmax_parent_edu wlive_w_moth wsmoke_drink wsport_main wsport_oth wclub_? w2white w2school_performance ///
	   w2sex w2age w2grade_7_8 w2grade_9_10 w2grade_11_12 w2dwelling_quality w2hhsize w2max_parent_edu w2live_w_moth ///
	   w2smoke_drink w2sport_main w2sport_oth wfath_occ_man wfath_occ_manual wfath_occ_farm wfath_occ_miss w2fath_occ_man ///
	   w2fath_occ_manual w2fath_occ_farm w2fath_occ_miss ) 

estadd scalar anderson `e(idp)'
estadd scalar fstat `e(widstat)'
estadd scalar sarg `e(sarganp)'


#delimit ;

loc tablerow _cons;

	esttab using "${outdir}/instrument_diagnostic.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{3}{>{\centering\arraybackslash}m{3.0cm}}}
		\toprule \toprule \\
		& \textit{Emotional Stability} & \textit{Extraversion} & \textit{Conscientiousness} \\") 
		keep(`tablerow') order(`tablerow')	
	stats(anderson fstat sarg, labels("Anderson LM (p-value)" "Donald-Cragg F statistic" "Hansen J (p-value)") 
	fmt(%9.3f %9.3f %9.3f))
	addnotes();
#delimit cr




