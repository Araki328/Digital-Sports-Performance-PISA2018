/* ==================================================================== */
/* 05_Final_Analysis_and_Tables.do                                      */
/* Purpose: Full Control Models, Robust Plotting, and Table Generation    */
/* ==================================================================== */

clear all
set more off
/* Update this path to your local directory */
local data_path "E:/Y/PISA数据库/STU"

/* Define all necessary variables */
local all_vars "PV1MATH PV1READ PV1SCIE W_FSTUWT CNTSCHID GENDER z_ESCS z_HOMESCH z_DIGISPORT z_PE_CLASSES z_T_TRAINING z_STRATIO z_SOIAICT z_BELONG"

/* ==================================================================== */
/* Part 1: Data Preparation (Nordic + China Hong Kong) */
/* ==================================================================== */

/* --- Prepare Nordic Data --- */
import delimited "`data_path'/PISA2018_Nordic_FULL_v4.csv", clear case(preserve)
rename *, lower
/* Ensure raw variables exist if needed, otherwise keep Z-scores */
/* Note: The CSV likely contains both raw (e.g., escs) and z-scores (e.g., z_escs) */
gen region = 1
tostring cntschid, replace
replace cntschid = "N_" + cntschid
tempfile nordic_full
save "`nordic_full'"

/* --- Prepare China Hong Kong Data --- */
import delimited "`data_path'/PISA2018_HKG_FULL_v4.csv", clear case(preserve)
rename *, lower
gen region = 0
tostring cntschid, replace
replace cntschid = "HK_" + cntschid

/* --- Merge --- */
append using "`nordic_full'"
encode cntschid, gen(school_id)
label define reg_lab 1 "Nordic" 0 "China Hong Kong"
label values region reg_lab

/* Define Control Variables list */
local controls "gender z_escs z_homesch z_pe_classes z_t_training z_stratio z_soiaict z_belong"

/* ==================================================================== */
/* Part 2: Robust Threshold Analysis Plot (Math) */
/* ==================================================================== */

/* Run Full Control Model for Math */
mixed pv1math /// 
    i.region##c.z_digisport##c.z_digisport ///  /* Core Quadratic Interaction */
    `controls' ///                              /* Full Controls */
    [pw=w_fstuwt] || school_id:, mle

/* Plot the Robust Curve */
margins region, at(z_digisport=(-2(0.2)3))
marginsplot, ///
    recast(line) ///
    noci ///
    plot1opts(lcolor(red) lpattern(solid) lwidth(medium)) ///
    plot2opts(lcolor(blue) lpattern(dash) lwidth(medium)) ///
    title("Robust Threshold Analysis: Nordic vs China Hong Kong") ///
    subtitle("Controlled for School Environment & Social Perception") ///
    xtitle("Digital Sports Frequency (Z-score)") ///
    ytitle("Predicted Math Score (Adjusted)") ///
    yline(500, lcolor(gray) lwidth(thin)) ///
    legend(order(1 "China Hong Kong" 2 "Nordic") ring(0) pos(3) region(lstyle(none)) cols(1)) ///
    note("Adjusted for full covariates (SES, PE Classes, Teacher Training, etc.)") ///
    name(Robust_Curve_Fixed, replace)

graph export "Robust_U_Shape_Curve.png", replace width(2000)

/* ==================================================================== */
/* Part 3: Main Regression Tables (Table 1) */
/* ==================================================================== */

/* Define English Labels for Tables */
local nice_labels ///
    z_digisport "Digital Sports (Linear)" ///
    c.z_digisport#c.z_digisport "Digital Sports Sq. (Quadratic)" ///
    1.region#c.z_digisport "Nordic x Digital Sports" ///
    1.region#c.z_digisport#c.z_digisport "Nordic x DigSports Sq." ///
    gender "Gender" z_escs "ESCS" ///
    z_pe_classes "PE Classes" z_t_training "Teacher Training" ///
    z_homesch "Outside School ICT" z_stratio "Student-Teacher Ratio" ///
    z_soiaict "Social ICT Perception" z_belong "Sense of Belonging" ///
    1.digi_group "Group 1 (Low)" 2.digi_group "Group 2" 3.digi_group "Group 3" ///
    4.digi_group "Group 4" 5.digi_group "Group 5 (High)"

/* Calculate Total Achievement */
egen z_m = std(pv1math)
egen z_r = std(pv1read)
egen z_s = std(pv1scie)
gen z_total = (z_m + z_r + z_s) / 3

/* Run Models for All Subjects */
/* 1. Total Achievement */
mixed z_total i.region##c.z_digisport##c.z_digisport `controls' [pw=w_fstuwt] || school_id:, mle
est store M_Total

/* 2. Math */
mixed z_m i.region##c.z_digisport##c.z_digisport `controls' [pw=w_fstuwt] || school_id:, mle
est store M_Math

/* 3. Reading */
mixed z_r i.region##c.z_digisport##c.z_digisport `controls' [pw=w_fstuwt] || school_id:, mle
est store M_Read

/* 4. Science */
mixed z_s i.region##c.z_digisport##c.z_digisport `controls' [pw=w_fstuwt] || school_id:, mle
est store M_Scie

/* Export Table 1 */
esttab M_Total M_Math M_Read M_Scie using "Table_Threshold_Main.rtf", replace ///
    rtf label nogaps compress ///
    mtitles("Total Achievement" "Math" "Reading" "Science") ///
    title("Table 1: Non-linear Associations between Digital Sports and Academic Performance") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N bic, fmt(0 2) labels("N" "BIC")) ///
    coeflabels(`nice_labels') ///
    keep(z_digisport c.z_digisport#c.z_digisport 1.region#c.z_digisport 1.region#c.z_digisport#c.z_digisport `controls') 

/* ==================================================================== */
/* Part 4: Robustness Check Tables (Table 2) */
/* ==================================================================== */

/* Check 1: Quintile Grouping (Dummy Variable) */
xtile digi_group = z_digisport, nq(5)
mixed pv1math i.region##i.digi_group `controls' [pw=w_fstuwt] || school_id:, mle
est store Rob_Dummy

/* Check 2: Trimmed Sample (Excluding outliers) */
gen normal_sample = 1 if abs(z_digisport) <= 2.5
replace normal_sample = 0 if abs(z_digisport) > 2.5
mixed pv1math i.region##c.z_digisport##c.z_digisport `controls' ///
    if normal_sample == 1 [pw=w_fstuwt] || school_id:, mle
est store Rob_Trimmed

/* Export Table 2 */
esttab Rob_Dummy Rob_Trimmed using "Table_Robustness.rtf", replace ///
    rtf label nogaps compress ///
    mtitles("Check 1: Quintile Regression" "Check 2: Trimmed Sample") ///
    title("Table 2: Robustness Checks") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, fmt(0) labels("N")) ///
    coeflabels(`nice_labels') ///
    drop(_cons)

/* ==================================================================== */
/* Part 5: Descriptive Statistics Table */
/* ==================================================================== */

/* Define variables for descriptive table (Raw versions preferred if available) */
/* Assuming raw variables exist after 'rename *, lower' */
local sum_vars "pv1math pv1read pv1scie z_total z_digisport gender escs homesch pe_classes t_training stratio soiaict belong"

/* Calculate statistics by Region */
estpost summarize `sum_vars' if region == 0, listwise
est store HK

estpost summarize `sum_vars' if region == 1, listwise
est store Nordic

/* Export Descriptive Table */
esttab HK Nordic using "Table1_Descriptive_Statistics.rtf", replace ///
    rtf label nogaps compress ///
    title("Table 3: Descriptive Statistics by Region (Mean/SD)") ///
    mtitles("China Hong Kong" "Nordic Countries") ///
    cells("mean(fmt(2)) sd(fmt(2))") ///
    stats(N, fmt(0) labels("Observations")) ///
    noobs