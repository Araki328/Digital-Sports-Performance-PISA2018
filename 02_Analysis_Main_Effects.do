/* ==================================================================== */
/* 02_Analysis_Main_Effects.do                                          */
/* Purpose: HLM Analysis for Main Effects and Moderation (HK vs Nordic) */
/* ==================================================================== */

clear all
set more off
/* Update this path to your local directory */
local data_path "E:/Y/PISA数据库/STU"

/* Define Subjects */
local subjects "math read scie"

/* Define Variable Groups */
local controls   "gender z_ESCS z_HOMESCH"
local env_vars   "z_PE_CLASSES z_T_TRAINING z_STRATIO z_SOIAICT z_BELONG"
local iv         "z_DIGISPORT"
local moderators "z_AUTICT z_INTICT"
local hk_extras  "z_BMI z_BODYIMA z_HEALTH_SELF z_EMOSUPP"

/* ==================================================================== */
/* Part 1: China Hong Kong Analysis */
/* ==================================================================== */
import delimited "`data_path'/PISA2018_HKG_FULL_v4.csv", clear case(preserve)

/* Variable Renaming & Formatting */
capture rename PV1MATH pv1math
capture rename PV1READ pv1read
capture rename PV1SCIE pv1scie
capture rename W_FSTUWT w_fstuwt
capture rename CNTSCHID cntschid
capture rename GENDER gender
capture rename st004d01t gender
capture destring cntschid, replace force

/* Loop through subjects */
foreach sub in `subjects' {
    /* Model 1: Main Effect */
    mixed pv1`sub' `controls' `env_vars' `hk_extras' `iv' `moderators' [pw=w_fstuwt] || cntschid:, mle
    est store HK_`sub'_Main
    
    /* Model 2: Moderation Effect */
    mixed pv1`sub' `controls' `env_vars' `hk_extras' c.`iv'##c.z_AUTICT c.`iv'##c.z_INTICT [pw=w_fstuwt] || cntschid:, mle
    est store HK_`sub'_Mod
}

/* ==================================================================== */
/* Part 2: Nordic Countries Analysis */
/* ==================================================================== */
import delimited "`data_path'/PISA2018_Nordic_FULL_v4.csv", clear case(preserve)

/* Variable Renaming & Formatting */
capture rename PV1MATH pv1math
capture rename PV1READ pv1read
capture rename PV1SCIE pv1scie
capture rename W_FSTUWT w_fstuwt
capture rename CNTSCHID cntschid
capture rename GENDER gender
capture rename st004d01t gender
capture destring cntschid, replace force

/* Nordic specific environment variables (excluding HK extras) */
local nordic_env "z_PE_CLASSES z_T_TRAINING z_STRATIO z_SOIAICT z_BELONG"

/* Loop through subjects */
foreach sub in `subjects' {
    /* Model 1: Main Effect */
    mixed pv1`sub' `controls' `nordic_env' `iv' `moderators' [pw=w_fstuwt] || cntschid:, mle
    est store NOR_`sub'_Main
    
    /* Model 2: Moderation Effect */
    mixed pv1`sub' `controls' `nordic_env' c.`iv'##c.z_AUTICT c.`iv'##c.z_INTICT [pw=w_fstuwt] || cntschid:, mle
    est store NOR_`sub'_Mod
}

/* ==================================================================== */
/* Part 3: Generate Tables */
/* ==================================================================== */
/* Ensure estout is installed: ssc install estout, replace */

cd "`data_path'"

/* Define English Labels for Tables */
local en_labels ///
    z_DIGISPORT "Digital Sports" ///
    z_T_TRAINING "Teacher ICT Training" ///
    z_SOIAICT "Social ICT Perception" ///
    z_AUTICT "ICT Autonomy" ///
    z_INTICT "ICT Interest" ///
    c.z_DIGISPORT#c.z_AUTICT "Interact: DigSport x Autonomy" ///
    c.z_DIGISPORT#c.z_INTICT "Interact: DigSport x Interest" ///
    gender "Gender (Boy)" ///
    z_ESCS "ESCS" ///
    z_PE_CLASSES "PE Classes"

/* Table 1: Main Effects across Subjects */
esttab HK_math_Main NOR_math_Main HK_read_Main NOR_read_Main HK_scie_Main NOR_scie_Main ///
    using "Table_1_Main_Effects.rtf", replace ///
    rtf label nogaps ///
    mtitles("HK(Math)" "Nordic(Math)" "HK(Read)" "Nordic(Read)" "HK(Sci)" "Nordic(Sci)") ///
    title("Table 1: Main Effects of Digital Sports across Subjects") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N bic, fmt(0 2) labels("N" "BIC")) ///
    coeflabels(`en_labels') ///
    keep(z_DIGISPORT z_T_TRAINING z_SOIAICT gender z_ESCS z_PE_CLASSES) 

/* Table 2: Moderation Effects across Subjects */
esttab HK_math_Mod NOR_math_Mod HK_read_Mod NOR_read_Mod HK_scie_Mod NOR_scie_Mod ///
    using "Table_2_Moderation_Effects.rtf", replace ///
    rtf label nogaps ///
    mtitles("HK(Math)" "Nordic(Math)" "HK(Read)" "Nordic(Read)" "HK(Sci)" "Nordic(Sci)") ///
    title("Table 2: Moderation Effects of ICT Autonomy and Interest") ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, fmt(0) labels("N")) ///
    coeflabels(`en_labels') ///
    keep(z_DIGISPORT c.z_DIGISPORT#c.z_AUTICT c.z_DIGISPORT#c.z_INTICT z_AUTICT z_INTICT)











