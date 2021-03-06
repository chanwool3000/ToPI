* -------------------------------------- *
* Graphs of treatment effects - aggregates
* Author: Chanwool Kim
* Date Created: 18 Feb 2017
* Last Update: 12 Sep 2017
* -------------------------------------- *

clear all
set more off

global data_ehs		: env data_ehs
global data_ihdp	: env data_ihdp
global data_abc		: env data_abc
global data_careboth	: env data_care
global data_carehv	: env data_care
global data_store	: env klmshare
global klmshare		: env klmshare

* --------------------------- *
* Define macros for abstraction

local programs				ehs ihdp abc careboth carehv

* EHS
local ehs_tests 			home
local ehs_home_types		ca total /*warm verb exenviro lang*/

* IHDP
local ihdp_tests 			home
local ihdp_home_types		ca total /*accept*/

* ABC
local abc_tests 			home
local abc_home_types		ca total /*nonpun toys var indep inv warm inenviro exenviro*/

* CARE (Both)
local careboth_tests 		home
local careboth_home_types	ca total /*nonpun toys var indep inv warm inenviro exenviro*/

* CARE (Home Visit)
local carehv_tests 			home
local carehv_home_types		ca total /*nonpun toys var indep inv warm inenviro exenviro*/

* ---------------------- *
* Define macros for graphs

local region				graphregion(color(white))

local xtitle				xtitle(Chronological Age)
local ytitle				ytitle(``t'_name' ``s'_name')

local ehs_xlabel			xlabel(12(12)130, labsize(small))
local ihdp_xlabel			xlabel(6(12)40, labsize(small))
local abc_xlabel			xlabel(0(12)100, labsize(small))
local careboth_xlabel		xlabel(0(12)100, labsize(small))
local carehv_xlabel			xlabel(0(12)100, labsize(small))

local ehs_end				36
local ihdp_end				36
local abc_end				60
local careboth_end			60
local carehv_end			60

local treatment				treat == 1
local t_mean				lcol(black) mcol(black)
local t_sd					lcol(black) lwidth(vthin) mcol(black) msize(vtiny) 

local control				treat == 0
local c_mean				lcol(gs5) lpattern(dash) mcol(gs5)
local c_sd					lcol(gs5) lwidth(vthin) mcol(gs5) msize(vtiny) 

local home_name 			HOME

local home_total_name		Total Score
local home_warm_name		Warmth Score
local home_verb_name		Parental Verbal Skills Score
local home_exenviro_name	External Environment Score
local home_lang_name		Language and Cognitive Stimulation Score
local home_accept_name		Acceptance Score
local home_nonpun_name		Nonpunitive Score
local home_toys_name		Appropriate Toys Score
local home_var_name			Variety Score
local home_indep_name		Fostering Independence Score
local home_inv_name			Maternal Involvement Score
local home_inenviro_name	Internal Environment Score

local legend				legend(order(1 2) label(1 Treatment) label(2 Control) position(7) region(color(white)))

* ------- *
* Execution

* Get data
foreach p of local programs {
cd "${data_`p'}"
use "`p'-home-agg.dta", clear

	drop norm*

	* Generate local to help reshape data wide -> long
	local vars_to_reshape

	foreach t of local `p'_tests {
		foreach s of local `p'_`t'_types {
			local vars_to_reshape 	`vars_to_reshape' 	`t'_`s'
		}
	}
	
	* Reshape the data 
	reshape long `vars_to_reshape', i(id) j(test_age)
	keep id treat test_age `vars_to_reshape' 

	* Calculate mean and sd of each test at each age by treatment and control
	preserve

	collapse (mean) `vars_to_reshape', by(treat test_age)
	gen N = _n
	tempfile mean
	save `mean'

	restore
	preserve

	collapse (sd) `vars_to_reshape', by(treat test_age)
	foreach v of varlist _all {
		rename `v' sd_`v'
	}
	gen N = _n

	merge 1:1 N using `mean', nogen
	tempfile sd
	save `sd'

	restore

	collapse (count) `vars_to_reshape', by(treat test_age)
	foreach v of varlist _all {
		rename `v' N_`v'
	}
	gen N = _n

	merge 1:1 N using `sd', nogen

	* Graph
	foreach t of local `p'_tests {
		replace `t'_ca = test_age if `t'_ca == .
		foreach s of local `p'_`t'_types {
			gen plus_`t'_`s' = `t'_`s' + 1.96 * (sd_`t'_`s'/sqrt(N_`t'_`s'))
			gen minus_`t'_`s' = `t'_`s' - 1.96 * (sd_`t'_`s'/sqrt(N_`t'_`s'))

			twoway (connected `t'_`s' `t'_ca 		if `treatment', `t_mean' xline(``p'_end')) 	///
					(connected `t'_`s' `t'_ca 		if `control', 	`c_mean') 	///
					(connected plus_`t'_`s' `t'_ca 	if `treatment', `t_sd') 	///
					(connected minus_`t'_`s' `t'_ca if `treatment', `t_sd') 	///
					(connected plus_`t'_`s' `t'_ca 	if `control', `c_sd') 		///
					(connected minus_`t'_`s' `t'_ca if `control', 	`c_sd' 		///
								`xtitle' ytitle(``t'_name' ``t'_`s'_name') 	///
								`legend' `region' ``t'_`s'_ylabel' ``p'_xlabel'	///
								``p'_`t'_`s'_text' name(`p'_`t'_`s', replace))
		
			cd "$data_store/fig"
			graph export "`p'_`t'_`s'.eps", replace
		}
	}
}

* ---------------------------------------- *
* Execution - Patch for normalised variables

* Get data
foreach p of local programs {
cd "${data_`p'}"
use "`p'-home-agg.dta", clear

	* Sort of a cheating way
	keep id treat norm_*
	rename norm_* *
	
	* Generate local to help reshape data wide -> long
	local vars_to_reshape

	foreach t of local `p'_tests {
		foreach s of local `p'_`t'_types {
			local vars_to_reshape 	`vars_to_reshape' 	`t'_`s'
		}
	}
	
	* Reshape the data 
	reshape long `vars_to_reshape', i(id) j(test_age)
	keep id treat test_age `vars_to_reshape' 

	* Calculate mean and sd of each test at each age by treatment and control
	preserve

	collapse (mean) `vars_to_reshape', by(treat test_age)
	gen N = _n
	tempfile mean
	save `mean'

	restore
	preserve

	collapse (sd) `vars_to_reshape', by(treat test_age)
	foreach v of varlist _all {
		rename `v' sd_`v'
	}
	gen N = _n

	merge 1:1 N using `mean', nogen
	tempfile sd
	save `sd'

	restore

	collapse (count) `vars_to_reshape', by(treat test_age)
	foreach v of varlist _all {
		rename `v' N_`v'
	}
	gen N = _n

	merge 1:1 N using `sd', nogen

	* Graph
	foreach t of local `p'_tests {
		replace `t'_ca = test_age if `t'_ca == .
		foreach s of local `p'_`t'_types {
			gen plus_`t'_`s' = `t'_`s' + 1.96 * (sd_`t'_`s'/sqrt(N_`t'_`s'))
			gen minus_`t'_`s' = `t'_`s' - 1.96 * (sd_`t'_`s'/sqrt(N_`t'_`s'))

			twoway (connected `t'_`s' `t'_ca 		if `treatment', `t_mean' xline(``p'_end')) 	///
					(connected `t'_`s' `t'_ca 		if `control', 	`c_mean') 	///
					(connected plus_`t'_`s' `t'_ca 	if `treatment', `t_sd') 	///
					(connected minus_`t'_`s' `t'_ca if `treatment', `t_sd') 	///
					(connected plus_`t'_`s' `t'_ca 	if `control', `c_sd') 		///
					(connected minus_`t'_`s' `t'_ca if `control', 	`c_sd' 		///
								`xtitle' ytitle(``t'_name' ``t'_`s'_name' Standardised) 	///
								`legend' `region' ``p'_xlabel'	///
								``p'_`t'_`s'_text' name(`p'_`t'_`s'_std, replace))
		
			cd "$data_store/fig"
			graph export "`p'_`t'_`s'_std.eps", replace
		}
	}
}
