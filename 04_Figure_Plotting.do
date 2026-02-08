/* ==================================================================== */
/* 04_Figure_Plotting.do                                                */
/* Purpose: Generate Figure 1 (Combined 4-Panel Plot)                   */
/* ==================================================================== */

clear all
set more off
/* Update this path to your local directory */
local data_path "E:/Y/PISA数据库/STU"

/* Define Variables */
local all_vars "PV1MATH PV1READ PV1SCIE W_FSTUWT CNTSCHID GENDER z_ESCS z_HOMESCH z_DIGISPORT z_PE_CLASSES z_T_TRAINING z_STRATIO z_SOIAICT z_BELONG"

/* ==================================================================== */
/* 1. Data Preparation (Nordic + China Hong Kong) */
/* ==================================================================== */

/* --- Process Nordic Data --- */
import delimited "`data_path'/PISA2018_Nordic_FULL_v4.csv", clear case(preserve)
keep `all_vars'
rename *, lower
gen region = 1
tostring cntschid, replace
replace cntschid = "N_" + cntschid

/* Calculate Total Achievement (Mean of Z-scores) */
egen z_m = std(pv1math)
egen z_r = std(pv1read)
egen z_s = std(pv1scie)
gen z_total = (z_m + z_r + z_s) / 3
tempfile nordic_data
save "`nordic_data'"

/* --- Process China Hong Kong Data --- */
import delimited "`data_path'/PISA2018_HKG_FULL_v4.csv", clear case(preserve)
keep `all_vars'
rename *, lower
gen region = 0
tostring cntschid, replace
replace cntschid = "HK_" + cntschid

/* Calculate Total Achievement */
egen z_m = std(pv1math)
egen z_r = std(pv1read)
egen z_s = std(pv1scie)
gen z_total = (z_m + z_r + z_s) / 3

/* --- Append and Label --- */
append using "`nordic_data'"
encode cntschid, gen(school_id)
label define reg_lab 1 "Nordic" 0 "China Hong Kong"
label values region reg_lab

/* ==================================================================== */
/* 2. Plotting Configuration */
/* ==================================================================== */

/* Define plot style: Red Solid (HK), Blue Dash (Nordic), No CI, No Y-axis title */
local plot_opts "recast(line) noci plot1opts(lcolor(red) lpattern(solid)) plot2opts(lcolor(blue) lpattern(dash)) yline(0, lcolor(gray) lwidth(thin)) xtitle("Frequency (Z)")"

/* ==================================================================== */
/* 3. Generate Sub-plots */
/* ==================================================================== */

/* [A] Total Achievement (With Legend inside, right side) */
mixed z_total i.region##c.z_digisport##c.z_digisport gender z_escs z_homesch z_pe_classes z_t_training z_stratio z_soiaict z_belong || school_id:, mle
margins region, at(z_digisport=(-2(0.2)3)) predict(fitted)

marginsplot, `plot_opts' ///
    title("A. Total Achievement") ///
    ytitle("Predicted Score") ///
    legend(order(1 "China Hong Kong" 2 "Nordic") ring(0) pos(3) region(lstyle(none)) cols(1)) ///
    name(Graph_A, replace)

/* [B] Reading (No Legend) */
mixed z_r i.region##c.z_digisport##c.z_digisport gender z_escs z_homesch z_pe_classes z_t_training z_stratio z_soiaict z_belong || school_id:, mle
margins region, at(z_digisport=(-2(0.2)3)) predict(fitted)

marginsplot, `plot_opts' ///
    title("B. Reading") ///
    ytitle(" ") ///
    legend(off) ///
    name(Graph_B, replace)

/* [C] Science (No Legend) */
mixed z_s i.region##c.z_digisport##c.z_digisport gender z_escs z_homesch z_pe_classes z_t_training z_stratio z_soiaict z_belong || school_id:, mle
margins region, at(z_digisport=(-2(0.2)3)) predict(fitted)

marginsplot, `plot_opts' ///
    title("C. Science") ///
    ytitle("Predicted Score") ///
    legend(off) ///
    name(Graph_C, replace)

/* [D] Math (No Legend) */
mixed z_m i.region##c.z_digisport##c.z_digisport gender z_escs z_homesch z_pe_classes z_t_training z_stratio z_soiaict z_belong || school_id:, mle
margins region, at(z_digisport=(-2(0.2)3)) predict(fitted)

marginsplot, `plot_opts' ///
    title("D. Math") ///
    ytitle(" ") ///
    legend(off) ///
    name(Graph_D, replace)

/* ==================================================================== */
/* 4. Combine and Export */
/* ==================================================================== */

graph combine Graph_A Graph_B Graph_C Graph_D, ///
    title("Non-linear Effects Across Subjects") ///
    ycommon xcommon ///
    name(Final_Combined_Plot, replace)

graph export "Figure1_Combined_4_Panels.png", replace width(2000)


