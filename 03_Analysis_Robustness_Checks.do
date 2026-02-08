/* ==================================================================== */
/* 03_Analysis_Robustness_Checks.do                                     */
/* Purpose: Robustness Checks with Professional English Tables          */
/* ==================================================================== */

clear all
set more off
/* 👇 Update this path to your local directory */
local data_path "E:/Y/PISA数据库/STU"

/* Define Controls (Matches main analysis) */
local controls "gender z_escs z_homesch z_pe_classes z_t_training z_stratio z_soiaict z_belong"

/* ==================================================================== */
/* Part 1: Data Preparation & Merging */
/* ==================================================================== */

/* --- A. Process Nordic Data --- */
import delimited "`data_path'/PISA2018_Nordic_FULL_v4.csv", clear case(preserve)
rename *, lower
capture rename st004d01t gender
capture rename pv1math pv1math
capture rename w_fstuwt w_fstuwt
keep pv1math `controls' z_digisport w_fstuwt cntschid
gen region = 1
tostring cntschid, replace
replace cntschid = "N_" + cntschid
tempfile nordic
save "`nordic'"

/* --- B. Process China Hong Kong Data --- */
import delimited "`data_path'/PISA2018_HKG_FULL_v4.csv", clear case(preserve)
rename *, lower
capture rename st004d01t gender
keep pv1math `controls' z_digisport w_fstuwt cntschid
gen region = 0
tostring cntschid, replace
replace cntschid = "HK_" + cntschid

/* --- C. Append and Label --- */
append using "`nordic'"
encode cntschid, gen(school_id)
label define reg_lab 1 "Nordic" 0 "China Hong Kong"
label values region reg_lab

/* ==================================================================== */
/* Part 2: Running Models */
/* ==================================================================== */

/* --- Check 1: Quintile Regression (Dummy Variable Approach) --- */
/* Create 5 groups based on Digital Sports frequency */
xtile digi_group = z_digisport, nq(5)

/* Run Model: Reference group is Hong Kong (region=0) and Quintile 1 (Low) */
mixed pv1math i.region##i.digi_group `controls' [pw=w_fstuwt] || school_id:, mle
est store Rob_Quintile

/* Plot (Optional Visual Check) */
margins region#digi_group
marginsplot, ///
    plot1opts(lcolor(red) lpattern(solid)) plot2opts(lcolor(blue) lpattern(dash)) ///
    title("Robustness Check 1: Quintile Analysis") ///
    xtitle("Digital Sports Groups") ytitle("Math Score") ///
    legend(order(1 "China Hong Kong" 2 "Nordic")) name(Check_Quintile, replace)

/* --- Check 2: Trimmed Sample Analysis (Outliers Removed) --- */
/* Define Normal Sample: |Z| <= 2.5 */
gen normal_sample = 1 if abs(z_digisport) <= 2.5
replace normal_sample = 0 if abs(z_digisport) > 2.5

/* Run Model */
mixed pv1math i.region##c.z_digisport##c.z_digisport `controls' ///
    if normal_sample == 1 [pw=w_fstuwt] || school_id:, mle
est store Rob_Trimmed

/* Plot (Optional Visual Check) */
margins region, at(z_digisport=(-2(0.2)2.5))
marginsplot, recast(line) noci ///
    plot1opts(lcolor(red)) plot2opts(lcolor(blue) lpattern(dash)) ///
    title("Robustness Check 2: Trimmed Sample") ///
    legend(order(1 "China Hong Kong" 2 "Nordic")) name(Check_Trimmed, replace)

/* ==================================================================== */
/* Part 3: Exporting Beautiful Tables (The Magic Part) */
/* ==================================================================== */

/* 🛠️ Define Professional English Labels Mapping */
/* This maps the ugly internal names to clean academic English */
local nice_labels ///
    1.region "Nordic (Main Effect)" ///
    2.digi_group "Quintile 2 (Low-Mid)" ///
    3.digi_group "Quintile 3 (Mid)" ///
    4.digi_group "Quintile 4 (Mid-High)" ///
    5.digi_group "Quintile 5 (High)" ///
    1.region#2.digi_group "Nordic x Quintile 2" ///
    1.region#3.digi_group "Nordic x Quintile 3" ///
    1.region#4.digi_group "Nordic x Quintile 4" ///
    1.region#5.digi_group "Nordic x Quintile 5" ///
    z_digisport "Digital Sports (Linear)" ///
    c.z_digisport#c.z_digisport "Digital Sports Sq. (Quadratic)" ///
    1.region#c.z_digisport "Nordic x Digital Sports" ///
    1.region#c.z_digisport#c.z_digisport "Nordic x Squared Term" ///
    gender "Gender (Male)" ///
    z_escs "ESCS" ///
    z_homesch "Academic ICT Use (Outside School)" ///
    z_pe_classes "PE Classes Frequency" ///
    z_t_training "Teacher ICT Training" ///
    z_stratio "Student-Teacher Ratio" ///
    z_soiaict "Social ICT Perception" ///
    z_belong "Sense of Belonging" ///
    _cons "Constant"

/* 📤 Export Table */
esttab Rob_Quintile Rob_Trimmed using "Table_Robustness_Final.rtf", replace ///
    rtf label nogaps compress ///
    mtitles("Model 1: Quintile Regression" "Model 2: Trimmed Sample (|Z|<2.5)") ///
    title("Table: Robustness Checks for Non-linear Associations") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N bic, fmt(0 2) labels("Observations" "BIC")) ///
    coeflabels(`nice_labels') ///
    drop(0.region 1.digi_group 0.region#* 1.region#1.digi_group) /* Drop reference groups to keep it clean */

display "✅ 完美英文表格已生成！请打开 Table_Robustness_Final.rtf 查看。"