
/*==========================================================================

Title: 5_endogeneity_test.do 
Author: Mridul Joshi
Date: [2020-08-08 16:15]	

Description: Endogeneity analysis and robustness tests. Creates final tables

Key input: ${datadir}/postreg.dta
Key output: Final latex tables 

===========================================================================*/


u "${datadir}/postreg.dta", clear 


* ===================================================================== *
* -----------------      Create lagged variables      ----------------- *
* ===================================================================== *



gen epsil_cons_iv_na  = conscientious_dm - pr_cons_iv_na
gen epsil_emot_iv_na  = emotional_dm - pr_emot_iv_na
gen epsil_extr_iv_na  = extravert_dm - pr_extr_iv_na

keep aid epsil*

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

 

u "${datadir}/dyadic_predicted.dta", clear 



merge m:1 aid using `dyad_aid', gen(_mep1)

keep if _m1 == 3 

merge m:1 fr_id using `dyad_frid', gen(_mep2)

keep if _m1 == 3 



* create absolute differences 


foreach t in cons emot extr {
	foreach x in iv ml {
		foreach w in au na {

			cap gen abs_`t'_`x'_`w' = abs( epsil_`t'_`x'_`w'_aid  - epsil_`t'_`x'_`w'_frid)

		}
	}

}


keep if component_aid == component_frid
*keep if !inlist(scid_aid, "058", "077")
*keep if !inlist(component_aid, 4, 10)

recode link (1/. = 1)


eststo clear 

eststo: logit link abs_white abs_black abs_age abs_asian ///
		   abs_school_performance abs_smoke_drink abs_sex abs_sport_* abs_club_* abs_moth_occ_* ///
		   abs_fath_occ_* abs_grade_7_8 abs_grade_9_10 abs_grade_11_12 abs_max_parent_edu sch_*_aid

estadd local sch_fe "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


predict pred_q_log, xb 



eststo: reg link abs_white abs_black abs_age abs_asian ///
		   abs_school_performance abs_smoke_drink abs_sex abs_sport_* abs_club_* abs_moth_occ_* ///
		   abs_fath_occ_* abs_grade_7_8 abs_grade_9_10 abs_grade_11_12 abs_max_parent_edu sch_*_aid

estadd local sch_fe "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

predict resi_q_lpm, residuals 
lab var resi_q_lpm "Link formation residual"


lab var abs_sex "Sex" 
lab var abs_age "Age" 
lab var abs_white "White" 
lab var abs_black "Black" 
lab var abs_asian "Asian" 
lab var abs_school_performance "School Performance" 
lab var abs_smoke_drink "Smokes or drinks" 
lab var abs_max_parent_edu "Parental education"



local varlab1 "Logit"
local varlab2 "OLS" 


loc tablerow abs_sex abs_age abs_white abs_black abs_asian abs_school_performance abs_smoke_drink abs_max_parent_edu _cons


 #delimit ;
	esttab using "${outdir}/table_dyadic.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps 
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{2}{>{\centering\arraybackslash}m{3.0cm}}}
		\toprule \toprule \\
		\multicolumn{2}{c}{\textit{Dep Var: Link}} &   \\\\ 
		& `varlab1' &`varlab2' \\")
	keep(`tablerow') order(`tablerow')	
	stats(N sch_fe occu_dum club_dum, labels("" "School fixed effects" "Parent occupation dummies" "Extracurricular dummies") fmt(%20s %20s)) 
	addnotes( 
    "Notes: Standard errors (in parentheses)."
    "* p$<$0.05, ** p$<$0.01, *** p$<$0.001" ) ;
#delimit cr


xtile q_grp = pred_q, nq(100)



eststo clear 

foreach var of varlist abs_cons_iv_na abs_emot_iv_na abs_extr_iv_na {

	forval i = 30(10)40 {

		di "`var' | `i'"

		eststo: reg `var' pred_q_log sch_*_aid if link == 1 & q_grp < `i', vce(robust)
		estadd local sch_fe "Yes"


	}

}


lab var pred_q_log "Predicted probability"


local tablerow pred_q_log _cons

local varlab1 "$\tau$ = 0.30"
local varlab2 "$\tau$ = 0.40"

local head1 "Conscientiousness"
local head2 "Emotional Stability"
local head3 "Extraversion"


 #delimit ;
	esttab using "${outdir}/table_endo_test1.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps 
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{6}{>{\centering\arraybackslash}m{1.8cm}}}
		\toprule \toprule \\
		\multicolumn{2}{c}{\textit{Dep. var: residual difference}} && &  \\\\ 
		& \multicolumn{2}{c}{`head1'} & \multicolumn{2}{c}{`head2'} &  \multicolumn{2}{c}{`head3'} \\\\ 		
		Threshold & `varlab1' & `varlab2' & `varlab1' & `varlab2' & `varlab1' & `varlab2' \\")
	keep(`tablerow') order(`tablerow')	
	stats(N sch_fe, labels("" "School fixed effects") fmt(%20s %20s)) 
	addnotes( 
    "Notes: Robust standard errors are in parentheses."
    "* p$<$0.05, ** p$<$0.01, *** p$<$0.001" ) ;
#delimit cr
 

eststo clear 

foreach var of varlist abs_cons_iv_na abs_emot_iv_na abs_extr_iv_na {

	forval j = 90(-10)80 {

		di "`var' | `j'"

		eststo: reg `var' pred_q_log sch_*_aid if link == 0 & q_grp > `j', vce(robust)
		estadd local sch_fe "Yes"


	}
}


local tablerow pred_q_log _cons

local varlab1 "$\tau$ = 0.90"
local varlab2 "$\tau$ = 0.80"

local head1 "Conscientiousness"
local head2 "Emotional Stability"
local head3 "Extraversion"


 #delimit ;
	esttab using "${outdir}/table_endo_test2.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps 
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{6}{>{\centering\arraybackslash}m{1.8cm}}}
		\toprule \toprule \\
		\multicolumn{2}{c}{\textit{Dep. var: residual difference}} && &  \\\\ 
		& \multicolumn{2}{c}{`head1'} & \multicolumn{2}{c}{`head2'} &  \multicolumn{2}{c}{`head3'} \\\\ 		
		Threshold & `varlab1' & `varlab2' & `varlab1' & `varlab2' & `varlab1' & `varlab2' \\")
	keep(`tablerow') order(`tablerow')	
	stats(N sch_fe, labels("" "School fixed effects") fmt(%20s %20s)) 
	addnotes( 
    "Notes: Robust standard errors are in parentheses."
    "* p$<$0.05, ** p$<$0.01, *** p$<$0.001" ) ;
#delimit cr
 

gen prob_link30 = q_grp < 30 
sum prob_link30 if link == 1, meanonly 
local prob30: di %9.2f `r(mean)' 

gen prob_link40 = q_grp < 40 
sum prob_link40 if link == 1, meanonly 
local prob40: di %9.2f `r(mean)'

gen prob_link90 = q_grp > 90 
sum prob_link90 if link == 0, meanonly 
local prob90: di %9.2f `r(mean)'

gen prob_link80 = q_grp > 80 
sum prob_link80 if link == 0, meanonly 
local prob80: di %9.2f `r(mean)'


 cap file close problink
file open problink using "${outdir}/problink.tex", write replace
file write problink "\begin{tabular}{ccccc}  \toprule \toprule" _n      
file write problink "& \multicolumn{2}{c}{g_{ij}=0}  & \multicolumn{2}{c}{g_{ij}=1} \\ " _n
file write problink "& \tau = 40\% & \tau = 30\% & \tau = 90\% & \tau = 30\% \\ \midrule" _n
file write problink "P(q_{ij} < \tau | g_{ij}= 1) & `prob30' & `prob40' & x & x \\ " _n
file write problink "P(q_{ij} > \tau | g_{ij}= 0) & x & x & `prob90' & `prob80' \\ \bottomrule" _n
file write problink "\end{tabular}" _n 
file close problink 


drop prob_link??


*** add the probability of forming links 

preserve   

keep aid resi_q_lpm 
collapse (sum) resi_q_lpm, by(aid)

tempfile dyad_residual
save `dyad_residual'
 
restore


* ===================================================================== *
* -----------------    Control function approach      ----------------- *
* ===================================================================== *

use "${datadir}/postreg.dta", clear  

/*-----------------------------------------------------------
So here I need to just save the residuals from the previous
regression and add it to the outcome equation 
-----------------------------------------------------------*/

merge 1:1 aid using `dyad_residual' , gen(_mdyadres)

summ resi_q_lpm
replace resi_q_lpm = `r(mean)' if mi(resi_q_lpm)
lab var resi_q_lpm "Link formation residual"

eststo clear 


* emotional stability 
eststo: spreg ml emotional_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  resi_q_lpm , id(aid) dlmat(peer) elmat(peer)

estadd local con_ef  "Yes"
estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

* extraversion
eststo: spreg ml extravert_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  resi_q_lpm , id(aid) dlmat(peer) elmat(peer)


estadd local con_ef  "Yes"
estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


* conscientious
eststo: spreg ml conscientious_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  resi_q_lpm , id(aid) dlmat(peer) elmat(peer)


estadd local con_ef  "Yes"
estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

#delimit ;

loc tablerow wsex_dm wage_dm wwhite_dm wschool_performance_dm wdwelling_quality_dm whhsize_dm wmax_parent_edu_dm wlive_w_moth_dm wsmoke_drink_dm _cons;

	esttab using "${outdir}/table_controlf.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{3}{>{\centering\arraybackslash}m{4.0cm}}}
		\toprule \toprule \\
		& \textit{Emotional Stability} & \textit{Extraversion} & \textit{Conscientiousness} \\")
		keep(`tablerow') order(`tablerow')	
	stats(N sch_fe con_ef grad_dum occu_dum club_dum, labels("" "Contexual effects" "School fixed effects" "Grade dummies" "Parent occupation dummies" "Extracurricular dummies") 
	fmt(%20s %20s)) 
	addnotes( 
    "Notes: Standard errors (in parentheses)."
    "* p<0.05, ** p<0.01, *** p<0.001" ) ;
#delimit cr



* ===================================================================== *
* -----------------         Random Peers              ----------------- *
* ===================================================================== *

import delimited using "${datadir}/adj_rand.csv", clear

cap drop aid
rename v1 aid

spmat dta peer_rand v2-v2309, id(aid) replace norm(row)

use "${datadir}/postreg.dta", clear  

eststo clear 


* emotional stability 
eststo: spreg ml emotional_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm , id(aid) dlmat(peer_rand) //elmat(peer_rand)

estadd local con_ef  "Yes"
estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

* extraversion
eststo: spreg ml extravert_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer_rand) //elmat(peer_rand)


estadd local con_ef  "Yes"
estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


* conscientious
eststo: spreg ml conscientious_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm , id(aid) dlmat(peer_rand) //elmat(peer_rand)


estadd local con_ef  "Yes"
estadd local sch_fe  "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

#delimit ;

loc tablerow wsex_dm wage_dm wwhite_dm wschool_performance_dm wdwelling_quality_dm whhsize_dm wmax_parent_edu_dm wlive_w_moth_dm wsmoke_drink_dm _cons;

	esttab using "${outdir}/table_randompeers.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{3}{>{\centering\arraybackslash}m{4.0cm}}}
		\toprule \toprule \\
		& \textit{Emotional Stability} & \textit{Extraversion} & \textit{Conscientiousness} \\")
		keep(`tablerow') order(`tablerow')	
	stats(N sch_fe con_ef grad_dum occu_dum club_dum, labels("" "Contexual effects" "School fixed effects" "Grade dummies" "Parent occupation dummies" "Extracurricular dummies") 
	fmt(%20s %20s)) 
	addnotes( 
    "Notes: Standard errors (in parentheses)."
    "* p<0.05, ** p<0.01, *** p<0.001" ) ;
#delimit cr



* ===================================================================== *
* -----------------     	  Directed peers          ----------------- *
* ===================================================================== *

import delimited using "${datadir}/adj.csv", clear

rename v1 aid
drop in 1
spmat dta peer_undir v2-v2309, id(aid) replace norm(row)
use "${datadir}/postreg.dta", clear  

eststo clear 


* emotional stability 
eststo: spreg ml emotional_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm , id(aid) dlmat(peer_undir) elmat(peer_undir)

estadd local con_ef  "Yes"
estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

* extraversion
eststo: spreg ml extravert_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm  , id(aid) dlmat(peer_undir) elmat(peer_undir)


estadd local con_ef  "Yes"
estadd local sch_fe "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"


* conscientious
eststo: spreg ml conscientious_dm white_dm school_performance_dm sex_dm age_dm grade_7_8_dm grade_9_10_dm ///
		dwelling_quality_dm wwhite_dm wschool_performance_dm wsex_dm wage_dm wgrade_7_8_dm wgrade_9_10_dm ///
		wdwelling_quality_dm hhsize_dm whhsize_dm max_parent_edu_dm wmax_parent_edu_dm live_w_moth_dm wlive_w_moth_dm ///
		fath_occ_*_dm wfath_occ_*_dm  smoke_drink_dm wsmoke_drink_dm sport_main_dm sport_oth_dm wsport_main_dm wsport_oth_dm ///
		club_?_dm wclub_?_dm , id(aid) dlmat(peer_undir) elmat(peer_undir)


estadd local con_ef  "Yes"
estadd local sch_fe  "Yes"
estadd local grad_dum "Yes"
estadd local occu_dum "Yes"
estadd local club_dum "Yes"

#delimit ;

loc tablerow wsex_dm wage_dm wwhite_dm wschool_performance_dm wdwelling_quality_dm whhsize_dm wmax_parent_edu_dm wlive_w_moth_dm wsmoke_drink_dm _cons;

	esttab using "${outdir}/table_directed.tex",
		b(3) se booktabs star(* .1 ** .05 *** .01) nonotes nomtitles brackets replace label gaps
	prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{3}{>{\centering\arraybackslash}m{4.0cm}}}
		\toprule \toprule \\
		& \textit{Emotional Stability} & \textit{Extraversion} & \textit{Conscientiousness} \\")
		keep(`tablerow') order(`tablerow')	
	stats(N sch_fe con_ef grad_dum occu_dum club_dum, labels("" "Contexual effects" "School fixed effects" "Grade dummies" "Parent occupation dummies" "Extracurricular dummies") 
	fmt(%20s %20s)) 
	addnotes( 
    "Notes: Standard errors (in parentheses)."
    "* p<0.05, ** p<0.01, *** p<0.001" ) ;
#delimit cr



* ===================================================================== *
* -----------------     	 Descriptive Stats        ----------------- *
* ===================================================================== *

u "${datadir}/regression_data.dta", clear 
 

eststo sumstats1: estpost sum emotional extravert conscientious sex age white black asian any_phy_cond health religious ///
                  smoke_drink live_w_moth max_parent_edu school_performance hhsize grade_7_8 ///
                  grade_9_10 grade_11_12

#delimit ;

esttab sumstats1 using "$outdir/sumstats.tex", booktabs ///
		prehead("{\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}
		\begin{tabular}{@{\hskip\tabcolsep\extracolsep\fill}l*{5}{>{\centering\arraybackslash}m{2.0cm}}}
		\toprule \toprule \\")
		/*\textit{Variable} & \textit{Mean} & \textit{SD} % \textit{Min} & \textit{Max} \\") */
        label nonumbers cells("mean(fmt(%8.2f)) sd min(fmt(%8.0f)) max(fmt(%8.0f))") replace ;

#delimit cr 


