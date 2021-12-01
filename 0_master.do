
/*==========================================================================

Title: 0_master.do 
Author: Mridul Joshi
Date: [2020-07-18 15:02]	

Description: Master do-file to run the other do-files 

===========================================================================*/

version 16.0
clear all
set more off
pause off
cap log close 

* ===================================================================== *
* -----------------     	  Set path globals        ----------------- *
* ===================================================================== *

global basedir "C:/Users/Mridul Joshi/Google Drive/Dissertation"
global rawdir "${basedir}/1_Raw/ADDSTATA"
global dodir "${basedir}/2_Do"
global datadir "${basedir}/4_Data"
global outdir "${basedir}/5_Output"


* ===================================================================== *
* -----------------     Executing do-files/ r-script  ----------------- *
* ===================================================================== *

* extracts the list of friends and the variables needed for the study 

do "${dodir}/1_clean.do"



* produces the dyadic data and directed and undirected adjacency matrices [R-Script]

cd "$basedir/3_Rscripts"
shell "C:/Program Files/R/R-3.6.3/bin/Rscript.exe" "1_create_adj.R"



* creates composite variables and the final dataset for running the analysis 

do "${dodir}/2_create_final_variables.do"



* demean the variables and remove components smaller than 4 

do "${dodir}/3_addfixedeffects.do"



* run main regressions

do "${dodir}/4_regressions.do"



* run endogeneity analysis and other robustness checks

do "${dodir}/5_endogeneity_test.do"




