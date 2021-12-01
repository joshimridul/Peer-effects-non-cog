
/*==========================================================================

Title: 1_clean.do 
Author: Mridul Joshi
Date: [2020-03-21 17:37]	

Key input: ${rawdir}/Romantic Pair Files/rnomins1.dta
		   ${rawdir}/School Files/Inschool.dta
		   $rawdir/In Home Interview Files/allwave1.dta


Key output: ${datadir}/1_friendship.dta
			${datadir}/2_relevant_variables.dta


Description: The do-file cleans the Add-health dataset to produce a
student-level ds of noncognitive skills and other covariates 

===========================================================================*/



* ===================================================================== *
* -----------------     	  Add section head        ----------------- *
* ===================================================================== *


u "${rawdir}/Romantic Pair Files/rnomins1.dta" , clear 

keep if dat == 1 

drop rr_aid1-dat

* long dataset of friends by male/female 
reshape long mf_aid ff_aid, i(aid) j(rank_original) str

* long dataset of friends
rename mf_aid friend_id1 
rename ff_aid friend_id0 

reshape long friend_id, i(aid rank_original) j(sex)

lab def sex 0 "female" 1 "male"
lab val sex sex 

* friends not in sample schools 
replace friend_id = "" if inlist(friend_id, "77777777", "88888888", "99999999")

drop if aid == friend_id
drop if mi(friend_id)

bys aid sex (rank_original): gen rank = _n
bys aid: gen no_of_friends = _N

drop rank_original

tempfile friends
save `friends'


* ===================================================================== *
* -----------------         In-school survey          ----------------- *
* ===================================================================== *

use "${rawdir}/School Files/Inschool.dta", clear 

drop if mi(aid)

tempfile athome
save `athome'
 
 
* ===================================================================== *
* -----------------           Full dataset            ----------------- *
* ===================================================================== *


*** school information file 

use "$rawdir/School Files\Schinfo.dta", clear 

keep if sat_schl == 1 
keep scid sat_schl

tempfile schoolinfo
save `schoolinfo'



use "$rawdir/In Home Interview Files/allwave1.dta", clear  

merge m:1 scid using `schoolinfo', gen(_msch)


* keep only the saturation sample 
keep if _msch == 3 


*** merge at-home and in-school survey 
merge 1:1 aid using `athome', gen(_mhome)

keep if _mhome == 3 


tempfile full
save `full'
 
* all students in the saturation sample 
keep aid 
gen friend_id = aid // to merge in with the friend dataset 
duplicates drop 

tempfile allstud
save `allstud'
 

* ===================================================================== *
* -----------------  Merge with the friends data      ----------------- *
* ===================================================================== *

u `full', clear 

merge 1:m aid using `friends', gen(_mfs)

keep if  _mfs ==2 | _mfs == 3 
gen ind_sat_nominator =  _mfs == 3 


merge m:1 friend_id using `allstud', gen(_mf2)
gen ind_sat_nominee =  _mf2 == 3 


keep if _mfs == 3 & _mf2 == 3 


tempfile athome_noms
save `athome_noms'
		

keep aid sex friend_id rank

save "${datadir}/1_friendship.dta", replace 

export delimited using "${datadir}/1_friendship.csv", replace 



* ===================================================================== *
* -----------------    Outcomes and covariates data   ----------------- *
* ===================================================================== *

u `full', clear 

#delimit ; 

keep 
/*** identifiers ***/

/* individual level identifier */
aid 

/* school identifier */
scid 


/*** variables to generate outcomes ***/

/* Conscientiousness*/
h1pf18 h1pf21 h1pf20 h1pf19  

/* s62f h1fs5 h1fs18 s46c h1fs7 */

/* Extraversion */
s62o s62b s62e 


/* Neuroticism */
h1pf36 h1pf32 h1pf34 h1pf30 h1pf33 h1pf35

/* s60k s60m s60l h1fs15 h1fs1 */


/*** covariates ***/

/* race */
s6a-s6e

/* gpa */
s10a s10b s10c s10d

/* sex */
s2 

/* age */
s1 

/* grade dummies */
s3 

/* mother educ */
s12 

/* father educ */
s18 

/* lives with mother/father */
s11 s12 

/* allowance per week */
h1ee8

/* residential building quality */
h1ir10

/* religiousness */
h1re3 

/* parental occupation dummies */
s14 s20 

/* household size */
s27 

/* physical development */
h1mp4 

/* Sports */
s44a18-s44a29

/* Other extra-curricular */
s44a1-s44a17 s44a30-s44a33

/* health */
h1gh1

/* physical attractivness */
h1ir1 h1ir3 


/* smoking and drinking */
h1to3 h1to13 


/* physical condition */
h1pl1 


/* relaxed parents */
h1wp1


/* impulsivity */
h1pf16 h1ir19 h1ed7; 




#delimit cr


duplicates drop 


* ===================================================================== *
* ------------   Full dataset of outcomes + covariates  --------------- *
* ===================================================================== *

save "${datadir}/2_relevant_variables.dta", replace 










