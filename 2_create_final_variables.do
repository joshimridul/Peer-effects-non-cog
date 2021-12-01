
/*==========================================================================

Title: 2_create_final_variables.do 
Author: Mridul Joshi
Date: [2020-07-18 14:58]	

Description: This do-file creates the final variables required for the 
regressions. It conducts the IRT as well. 

Key input: ${datadir}/2_relevant_variables.dta
Key output: ${datadir}/prefinal.dta


===========================================================================*/


u "${datadir}/2_relevant_variables.dta", clear 


/* race */
gen white      = s6a
lab var white "White"

gen black      = s6b
lab var black "Black"

gen asian      = s6c
lab var asian "Asian"

gen native     = s6d
lab var native "Native American"

gen other_race = s6e 
lab var other_race "Other races"
drop s6a-s6e


/* gpa [higher is better] */

gen eng = s10a 
replace eng = . if  s10a==5 | s10a==7 | s10a==8 | s10a==9 
replace eng = 1 if  s10a==4
replace eng = 2 if  s10a==3
replace eng = 3 if  s10a==2
replace eng = 4 if  s10a==1

gen math = s10b 
replace math = . if  s10b==5 | s10b==7 | s10b==8 | s10b==9 
replace math = 1 if  s10b==4
replace math = 2 if  s10b==3
replace math = 3 if  s10b==2
replace math = 4 if  s10b==1

gen his = s10c 
replace his = . if  s10c==5 | s10c==7 | s10c==8 | s10c==9 
replace his = 1 if  s10c==4
replace his = 2 if  s10c==3
replace his = 3 if  s10c==2
replace his = 4 if  s10c==1

gen science = s10d 
replace science = . if  s10d==5 | s10d==7 | s10d==8 | s10d==9 
replace science = 1 if  s10d==4
replace science = 2 if  s10d==3
replace science = 3 if  s10d==2
replace science = 4 if  s10d==1

egen school_performance=rmean(eng math his science)

lab var school_performance "School performance (GPA)"

drop s10? eng math his science


/* sex */
gen sex = s2 
replace sex = . if  s2 ==9
replace sex = 1 if  s2 ==2  //female 
replace sex = 0 if  s2 ==1

lab var sex "Female"
lab def sex 1 "female" 0 "male"
lab val sex sex 

drop s2 

/* age */
gen age = s1 
lab var age "Age"

drop s1

/* grade dummies */
gen grade_7_8   = inrange(s3,7,8)
lab var grade_7_8 "Grades 7-8"

gen grade_9_10  = inrange(s3,9,10)
lab var grade_9_10 "Grades 9-10"

gen grade_11_12 = inrange(s3, 11,12)
lab var grade_11_12 "Grades 11-12"

gen grade_miss  = (s3 == 13 | s3 == 99 | s3 == .) 
lab var grade_miss "Grade missing"

drop s3 

/* mother educ */
gen moth_edu = s12 
replace moth_edu = 0 if s12==10 
replace moth_edu = 1 if  s12==1 | s12==2 
replace moth_edu = 2 if  s12==3 | s12==4 | s12==5 | s12==6 | s12==9  /*9 to modal cat*/
replace moth_edu = 3 if  s12==7 
replace moth_edu = 4 if  s12==8
replace moth_edu = . if  s12==97  | s12==99 | s12==11 

drop s12 

lab var moth_edu "Mother's education"


/* mother educ dummies*/
tab moth_edu, gen(moth_edu) mi


/* father educ */
gen fath_edu = s18 
replace fath_edu = 0 if s18==10 
replace fath_edu = 1 if  s18==1 | s18==2 
replace fath_edu = 2 if  s18==3 | s18==4 | s18==5 | s18==6 | s18==9  /*9 to modal cat*/
replace fath_edu = 3 if  s18==7 
replace fath_edu = 4 if  s18==8
replace fath_edu = . if  s18==97  | s18==99 | s18==11 

drop s18

lab var fath_edu "Father's education"


egen max_parent_edu = rowmax(moth_edu fath_edu )

lab var max_parent_edu "Parental education"


/* lives with mother */
gen live_w_moth = s11

lab def yesno 1 "Yes" 0 "No"
lab val live_w_moth yesno

lab var live_w_moth "Lives with mother"

drop s11 

/* allowance per week */
gen week_allowance = h1ee8
replace week_allowance = . if h1ee8 >=96

lab var week_allowance "Weekly allowance"
drop h1ee8



/* residential building quality [lower is worse] */
gen dwelling_quality = h1ir10
replace dwelling_quality = . if h1ir10 >=4
recode dwelling_quality (1=4) (2=3) (3=2) (4=1)

lab def dwell 1 "very poorly kept" 2 "poorly kept" 3 "fairly well-kept" 4 "very well-kept"
lab val dwelling_quality dwell 

lab var dwelling_quality "Residence building quality"
drop h1ir10

/* religiousness [smaller means more religious] */
recode h1re3 (7=4) (8=.)

g religious = 5 - h1re3 

lab def reli 1 "Never" 2 "Seldom" 3 "Often" 4 "Very often"
lab val religious reli 

lab var religious "Attend religious services"

drop h1re3 

/* parental occupation dummies */
gen moth_occ_tech= (s14 == 2  | s14 == 3  |s14 == 5)  
gen moth_occ_man= ( s14 == 4)
gen moth_occ_off_sales= ( s14 == 6|  s14 == 7 )
gen moth_occ_manual= (s14 == 9 | s14 == 10|  s14 == 11 | s14 == 12|  s14 == 13 )
gen moth_occ_mil= ( s14 == 14)
gen moth_occ_farm= ( s14 == 15)
gen moth_occ_other= ( s14 == 8)
gen moth_occ_miss= (s14 == 97  |s14 == 19 |s14 == 99 |s14 == 16 |s14 == 17 |s14 == 18 |s14 == 20 |s14 == .)

lab var  moth_occ_tech "Mother's occupation: Professional/technical"  
lab var  moth_occ_man "Mother's occupation: Manager"
lab var  moth_occ_off_sales "Mother's occupation: Office/sales"
lab var  moth_occ_manual "Mother's occupation: Manual worker"
lab var  moth_occ_mil "Mother's occupation: Military"
lab var  moth_occ_farm "Mother's occupation: Farming"
lab var  moth_occ_other "Mother's occupation: Other"
lab var  moth_occ_miss "Mother's occupation: Missing"

gen fath_occ_tech= (s20 == 2  | s20 == 3  |s20 == 5)
gen fath_occ_man= ( s20 == 4)
gen fath_occ_off_sales= ( s20 == 6|  s20 == 7 )
gen fath_occ_manual= (s20 == 9 | s20 == 10|  s20 == 11 | s20 == 12|  s20 == 13 )
gen fath_occ_mil= ( s20 == 14)
gen fath_occ_farm= ( s20 == 15)
gen fath_occ_other= ( s20 == 8)
gen fath_occ_miss = (s20 == 97  |s20 == 19 |s20 == 99 |s20 == 16 |s20 == 17 |s20 == 18 |s20 == 20 |s20 == .)

lab var  fath_occ_tech "Father's occupation: Professional/technical"  
lab var  fath_occ_man "Father's occupation: Manager"
lab var  fath_occ_off_sales "Father's occupation: Office/sales"
lab var  fath_occ_manual "Father's occupation: Manual worker"
lab var  fath_occ_mil "Father's occupation: Military"
lab var  fath_occ_farm "Father's occupation: Farming"
lab var  fath_occ_other "Father's occupation: Other"
lab var  fath_occ_miss "Father's occupation: Missing"

drop s14 s20 

/* household size */
gen hhsize = s27
replace hhsize = . if  s27==7  | s27==99

lab var hhsize "Household size"
drop s27 

/* physical development [1 is looks younger 3 = avg 5 = older] */
gen phy_dev = h1mp4 
replace phy_dev =. if h1mp4 > 5 

lab def phy_dev 1 "look younger than most" 2 "look younger than some" 3 "look about average" 4 "look older than some" 5 "look older than most"
lab val phy_dev phy_dev 

lab var phy_dev "Physical development"

drop h1mp4


/* Sports */

gen sport_main = (s44a18 == 1  | s44a19==1 | s44a21==1 | s44a23 == 1 | s44a27 == 1 )
lab var sport_main "Sports: Soccer/Basketball/Baseball/Volleyball"

gen sport_oth = (s44a20 == 1 | s44a22==1 | s44a24==1 | s44a25 ==1 | s44a26==1 | s44a28==1 | s44a29==1)
lab var sport_oth "Sports: Other sports"


drop s44a18-s44a29


/* Other extra-curricular */

gen club_1 = (s44a1 ==1 |  s44a2==1 |  s44a3==1 | s44a4==1 )
lab var club_1 "Extra-curricular: Foreign languages"

gen club_2 = (s44a8==1 | s44a7==1)
lab var club_2 "Extra-curricular: Debate and drama"

gen club_3 = (s44a5==1 | s44a6==1 | s44a10==1 | s44a11==1 | s44a12==1)
lab var club_3 "Extra-curricular: Academic"


gen club_4 = (s44a13==1 | s44a14==1 | s44a15==1 | s44a16==1)
lab var club_4 "Extra-curricular: Music and dance"


gen club_5 = (s44a30==1 | s44a31==1 | s44a32==1 | s44a33==1 )
lab var club_5 "Extra-curricular: Honor society/journals"


gen club_6 = (s44a17==1 | s44a9==1)
lab var club_6 "Extra-curricular: Other clubs"

drop s44a1-s44a17 s44a30-s44a33

 
/* health [higher is better] */

recode h1gh1 (6/. = .)
gen health = 6-h1gh1 

lab var health "Self-reported health"

lab define health 1 "Poor" 2 "Fair" 3 "Good" 4 "Very good" 5 "Excellent"

lab val health health

drop h1gh1 


/* physical attractivness */

recode h1ir1 h1ir3 (6/. =.)

replace h1ir1 = 6 - h1ir1 
replace h1ir3 = 6-  h1ir3 

egen physical_att = rmean(h1ir1 h1ir3)

lab var physical_att "Physical attractivness/ well-groomed"


drop h1ir1 h1ir3


/* smoking and drinking */

recode h1to3 h1to13 (6 = .) (7 = 0)

gen smoke_drink = (h1to3 ==1 | h1to13 == 1)
lab var smoke_drink "Smokes or drinks"

drop h1to3 h1to13 


/* physical condition */
recode h1pl1 (6/.=.)

gen any_phy_cond = h1pl1
lab var any_phy_cond "Difficulty using arms or legs"

drop h1pl1

/* relaxed parents */

recode h1wp1 (6=.) (8=.) (7=1) 

gen indep = h1wp1
lab var indep "Parents encourage own decision making"

drop h1wp1 


* impulsivity 
recode h1pf16 h1ir19 h1ed7 (6/. = .)

gen impulsive1 = 6 - h1pf16

gen impulsive2 = h1ir19
gen impulsive3 = h1ed7


* ===================================================================== *
* -----------------    Create outcome variables       ----------------- *
* ===================================================================== *

recode h1pf18 h1pf19 h1pf20 h1pf21 h1pf30 h1pf32 h1pf33 h1pf34 h1pf35 h1pf36 s62b s62e s62o (6/. =.)


*** Conscientiousness ( higher means more conscientious)

irt grm h1pf18 h1pf19 h1pf20 h1pf21

predict conscientious, latent 

lab var conscientious "Conscientiousness"




*** Emotional Stability (higher means less neurotic)  []

irt grm h1pf30 h1pf32 h1pf33 h1pf34 h1pf35 h1pf36

predict emotional, latent

lab var emotional "Emotional Stability"


*** Extraversion 

irt grm s62b s62e s62o

predict extravert, latent 

lab var extravert "Extraversion"



* ===================================================================== *
* -----------------     	  Chronbach's alpha       ----------------- *
* ===================================================================== *

* emotional stability
alpha h1pf30 h1pf32 h1pf33 h1pf34 h1pf35 h1pf36
loc alpha_em: di %9.2f `r(alpha)' 

* extraversion
alpha s62b s62e s62o 
loc alpha_ex: di %9.2f `r(alpha)' 

* conscientiousness
alpha h1pf18 h1pf19 h1pf20 h1pf21
loc alpha_co: di %9.2f `r(alpha)' 


cap file close chronbach
file open chronbach using "${outdir}/chronbach.tex", write replace
file write chronbach "\begin{tabular}{cc}  \toprule \toprule" _n      
file write chronbach " Index  & Chronbach's \alpha \\ \midrule" _n
file write chronbach " Emotional stability & `alpha_em' \\" _n
file write chronbach " Extraversion &  `alpha_ex' \\ " _n
file write chronbach " Conscientiousness & `alpha_co' \\ \bottomrule" _n
file write chronbach "\end{tabular}" _n 
file close chronbach 





drop h1pf18 h1pf19 h1pf20 h1pf21 h1pf30 h1pf32 h1pf33 h1pf34 h1pf35 h1pf36 s62b s62e s62o 

order aid scid conscientious emotional extravert, first 










** imputing missing values 

levelsof scid, loc(school)


foreach s in `school' {

	summ school_performance if scid == "`s'", d
	replace school_performance = `r(p50)' if scid == "`s'" & mi(school_performance)

	summ dwelling_quality if scid == "`s'", d
	replace dwelling_quality = `r(p50)' if scid == "`s'" & mi(dwelling_quality)

	summ max_parent_edu if scid == "`s'", d
	replace max_parent_edu = `r(p50)' if scid == "`s'" & mi(max_parent_edu)

	summ hhsize if scid == "`s'", d
	replace hhsize = `r(p50)' if scid == "`s'" & mi(hhsize)

    summ week_allowance if scid == "`s'", d
	replace week_allowance = `r(p50)' if scid == "`s'" & mi(week_allowance)

	summ impulsive1 if scid == "`s'", d
	replace impulsive1 = `r(p50)' if scid == "`s'" & mi(impulsive1)

	summ impulsive1 if scid == "`s'", d
	replace impulsive1 = `r(p50)' if scid == "`s'" & mi(impulsive1)

	summ impulsive1 if scid == "`s'", d
	replace impulsive1 = `r(p50)' if scid == "`s'" & mi(impulsive1)

}


replace live_w_moth = 1 if mi(live_w_moth)
replace age = 15 if mi(age)
replace sex = 1 if mi(sex)


replace grade_7_8  = 1 if grade_miss ==1 & age <=14
replace grade_9_10 = 1 if grade_miss ==1 & inrange(age,15,16)
replace grade_11_12  = 1 if grade_miss ==1 & age>= 17



save "${datadir}/prefinal.dta", replace 


