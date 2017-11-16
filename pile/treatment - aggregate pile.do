* ------------------------------------------ *
* Graphs of treatment effects - aggregate pile 
* Author: Chanwool Kim
* Date Created: 13 Sep 2017
* Last Update: 15 Nov 2017
* ------------------------------------------ *

clear all

* ------------ *
* Prepare matrix

foreach p of global programs {

cd "$pile_working"
use "`p'-home-agg-pile.dta", clear

* Create an empty matrix that stores ages, coefficients, p-values, lower CIs, and upper CIs.
qui matrix `p'R_1 = J(7, 5, .) // for randomisation variable
qui matrix `p'R_3 = J(9, 5, .) // for randomisation variable

qui matrix colnames `p'R_1 = `p'R_1num `p'R_1coeff `p'R_1lower `p'R_1upper `p'R_1pval
qui matrix colnames `p'R_3 = `p'R_3num `p'R_3coeff `p'R_3lower `p'R_3upper `p'R_3pval

local row_1 = 1
local row_3 = 1

	* Loop over rows to fill in values into the empty matrix.
	foreach r of global early_home_types {
		qui matrix `p'R_1[`row_1',1] = `row_1'
		
		capture confirm variable norm_home_`r'1y
			if !_rc {
			* Randomisation variable
			qui regress norm_home_`r'1y R $covariates if !missing(D)
			* r(table) stores values from regression (ex. coeff, var, CI).
			qui matrix list r(table)
			qui matrix r = r(table)

			qui matrix `p'R_1[`row_1',2] = r[1,1]
			qui matrix `p'R_1[`row_1',3] = r[5,1]
			qui matrix `p'R_1[`row_1',4] = r[6,1]
			qui matrix `p'R_1[`row_1',5] = r[4,1]
			
			local row_1 = `row_1' + 1
			}
			
			else {
			local row_1 = `row_1' + 1
			}
	}

	* Loop over rows to fill in values into the empty matrix.
	foreach r of global later_home_types {
		qui matrix `p'R_3[`row_3',1] = `row_3'
		
		capture confirm variable norm_home_`r'3y
			if !_rc {
			* Randomisation variable
			qui regress norm_home_`r'3y R $covariates if !missing(D)
			* r(table) stores values from regression (ex. coeff, var, CI).
			qui matrix list r(table)
			qui matrix r = r(table)

			qui matrix `p'R_3[`row_3',2] = r[1,1]
			qui matrix `p'R_3[`row_3',3] = r[5,1]
			qui matrix `p'R_3[`row_3',4] = r[6,1]
			qui matrix `p'R_3[`row_3',5] = r[4,1]
			
			local row_3 = `row_3' + 1
			}
			
			else {
			local row_3 = `row_3' + 1
			}
	}
		
cd "$pile_working"

svmat `p'R_1, names(col)
rename `p'R_1num row_1
keep row_1 `p'R_1coeff `p'R_1lower `p'R_1upper `p'R_1pval
keep if row_1 != .
save "`p'-pile-agg-1", replace

svmat `p'R_3, names(col)
rename `p'R_3num row_3
keep row_3 `p'R_3coeff `p'R_3lower `p'R_3upper `p'R_3pval
keep if row_3 != .
save "`p'-pile-agg-3", replace
}

cd "$pile_working"

use ehscenter-pile-agg-1, clear

foreach p of global programs {
	merge 1:1 row_1 using `p'-pile-agg-1, nogen nolabel
}

rename row_1 row
save agg-pile-1, replace

use ehscenter-pile-agg-3, clear

foreach p of global programs {
	merge 1:1 row_3 using `p'-pile-agg-3, nogen nolabel
}

rename row_3 row
save agg-pile-3, replace

* --------*
* Questions

cd "$pile_working"

use agg-pile-1, clear

tostring row, gen(scale_num)

replace scale = "Total Score" if scale_num == "1"
replace scale = "Parental Warmth" if scale_num == "2"
replace scale = "Parental Verbal Skills" if scale_num == "3"
replace scale = "Parental Lack of Hostility" if scale_num == "4"
replace scale = "Learning/Literacy" if scale_num == "5"
replace scale = "Activities/Outings" if scale_num == "6"
replace scale = "Developmental Advance" if scale_num == "7"

save agg-pile-1, replace

use agg-pile-3, clear

tostring row, gen(scale_num)

replace scale = "Total Score" if scale_num == "1"
replace scale = "Learning Stimulation" if scale_num == "2"
replace scale = "Access to Reading" if scale_num == "3"
replace scale = "Parental Verbal Skills" if scale_num == "4"
replace scale = "Parental Warmth" if scale_num == "5"
replace scale = "Home Exterior" if scale_num == "6"
replace scale = "Home Interior" if scale_num == "7"
replace scale = "Outings/Activities" if scale_num == "8"
replace scale = "Parental Lack of Hostility" if scale_num == "9"

save agg-pile-3, replace

* ----------------- *
* Execution - P-value

foreach age of numlist 1 3 {
	cd "$pile_working"
	use agg-pile-`age', clear
	
	foreach p of global programs {
		gen inv_`p'Rcoeff = `p'R_`age'coeff * -1
		gen `p'Rinsig = .
		gen `p'R0_1 = .
		gen `p'R0_05 = .
		replace `p'Rinsig = `p'R_`age'coeff if `p'R_`age'pval > 0.1
		replace `p'R0_1 = `p'R_`age'coeff if `p'R_`age'pval <= 0.1 & `p'R_`age'pval > 0.05
		replace `p'R0_05 = `p'R_`age'coeff if `p'R_`age'pval <= 0.05
	}
	
	cd "$pile_out"

	graph dot ehscenterRinsig ehscenterR0_1 ehscenterR0_05 ///
			  ehshomeRinsig ehshomeR0_1 ehshomeR0_05 ///
			  ehsmixedRinsig ehsmixedR0_1 ehsmixedR0_05 ///
			  ihdphighRinsig ihdphighR0_1 ihdphighR0_05 ///
			  ihdplowRinsig ihdplowR0_1 ihdplowR0_05 ///
			  abcRinsig abcR0_1 abcR0_05 ///
			  carebothRinsig carebothR0_1 carebothR0_05 ///
			  carehvRinsig carehvR0_1 carehvR0_05, ///
	marker(1,msize(large) msymbol(O) mlc(red) mfc(red*0) mlw(thin)) marker(2,msize(large) msymbol(O) mlc(red) mfc(red*0.5) mlw(thin)) marker(3,msize(large) msymbol(O) mlc(red) mfc(red) mlw(thin)) ///
	marker(4,msize(large) msymbol(T) mlc(red) mfc(red*0) mlw(thin)) marker(5,msize(large) msymbol(T) mlc(red) mfc(red*0.5) mlw(thin)) marker(6,msize(large) msymbol(T) mlc(red) mfc(red) mlw(thin)) ///
	marker(7,msize(large) msymbol(S) mlc(red) mfc(red*0) mlw(thin)) marker(8,msize(large) msymbol(S) mlc(red) mfc(red*0.5) mlw(thin)) marker(9,msize(large) msymbol(S) mlc(red) mfc(red) mlw(thin)) ///
	marker(10,msize(large) msymbol(T) mlc(green) mfc(green*0) mlw(thin)) marker(11,msize(large) msymbol(T) mlc(green) mfc(green*0.5) mlw(thin)) marker(12,msize(large) msymbol(T) mlc(green) mfc(green) mlw(thin)) ///
	marker(13,msize(large) msymbol(O) mlc(green) mfc(green*0) mlw(thin)) marker(14,msize(large) msymbol(O) mlc(green) mfc(green*0.5) mlw(thin)) marker(15,msize(large) msymbol(O) mlc(green) mfc(green) mlw(thin)) ///
	marker(16,msize(large) msymbol(O) mlc(blue) mfc(blue*0) mlw(thin)) marker(17,msize(large) msymbol(O) mlc(blue) mfc(blue*0.5) mlw(thin)) marker(18,msize(large) msymbol(O) mlc(blue) mfc(blue) mlw(thin)) ///
	marker(19,msize(large) msymbol(O) mlc(purple) mfc(purple*0) mlw(thin)) marker(20,msize(large) msymbol(O) mlc(purple) mfc(purple*0.5) mlw(thin)) marker(21,msize(large) msymbol(O) mlc(purple) mfc(purple) mlw(thin)) ///
	marker(22,msize(large) msymbol(T) mlc(purple) mfc(purple*0) mlw(thin)) marker(23,msize(large) msymbol(T) mlc(purple) mfc(purple*0.5) mlw(thin)) marker(24,msize(large) msymbol(T) mlc(purple) mfc(purple) mlw(thin)) ///
	over(scale, label(labsize(tiny)) sort(scale_num)) ///
	legend (order (3 "EHS-Center" 6 "EHS-Home" 9 "EHS-Mixed" 12 "IHDP-High" 15 "IHDP-Low" 18 "ABC" 21 "CARE-Both" 24 "CARE-Home") size(vsmall)) yline(0) ylabel(#6, labsize(vsmall)) ///
	graphregion(fcolor(white))

	graph export "agg_pile_R_`age'.pdf", replace
}
