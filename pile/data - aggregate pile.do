* --------------------------------------- *
* Data for aggregate pile treatment effects
* Author: Chanwool Kim
* Date Created: 13 Sep 2017
* Last Update: 4 Mar 2018
* --------------------------------------- *

clear all

* EHS (by program type)

foreach t of global ehs_type {
	cd "$data_home"
	use "ehs`t'-home-agg-merge.dta", clear

	rename norm_home_*14 norm_home_*1y
	rename norm_home_*36 norm_home_*3y
	
	rename ppvt36 ppvt3y
	
	cd "$pile_working"
	save ehs`t'-home-agg-pile, replace
}

* IHDP

cd "$data_home"
use "ihdp-home-agg-merge.dta", clear

rename norm_home_*12 norm_home_*1y
rename norm_home_*36 norm_home_*3y

rename ppvt36 ppvt3y
rename sb36 sb3y
	
cd "$pile_working"
save ihdp-home-agg-pile, replace

* ABC

cd "$data_home"
use "abc-home-agg-merge.dta", clear

rename norm_home_*6	 norm_home_*6m
rename norm_home_*18 norm_home_*1y
rename norm_home_*42 norm_home_*3y

rename sb36 sb3y

cd "$pile_working"
save abc-home-agg-pile, replace

* CARE (by home visit & both)

foreach t of global care_type {
	cd "$data_home"
	use "care`t'-home-agg-merge.dta", clear

	rename norm_home_*18 norm_home_*1y
	rename norm_home_*42 norm_home_*3y
	
	rename sb36 sb3y
	
	cd "$pile_working"
	save care`t'-home-agg-pile, replace
}
