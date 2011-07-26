local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/

clear all
capture log close
set more off
set mem 10g
set matsize 11000
cd `path'
/*
forval r=11/11	{
	fdause stata`r'
	compress
	save stata`r', replace
	use stata`r', clear
	*drop all alaska observations
	drop if pzip>=99000 & pzip<100000
	drop if substr(mprovno,1,2)=="02"
	*loving, tx ssa=="45762"
	drop if pzip==79754
	
	merge m:1 mprovno using aha_sysid, norep nogen keep(1 3) keepusing(sysid)
	gen hchar8 = (sysid~="")
	drop sysid

	*construct interaction variables
	local ages a7074jan a7579jan a8089jan a9099jan
	local case female black fb
	local age_or_case `ages' `case'
	local age_x_case female_* black_* fb_*
	local ctrl1 ctrl1*
	local ctrl2 ctrl2*

	gen fb = female*black

	foreach var of varlist `age_or_case' {
		forval n=1/8 {
		gen byte ctrl1_hchar`n'_`var' = `var'*hchar`n'
		}
	}

	foreach var of varlist `ages' {
		gen byte female_`var'= `var'*female
		gen byte black_`var'=`var'*black
		gen byte fb_`var'=`var'*fb
	}

	foreach var of varlist `age_x_case' {
		forval n=1/8 {
		gen byte ctrl2_hchar`n'_`var' = `var'*hchar`n'
		}
	}

	local diffdist dd*
	*construct differential distance percentile

	foreach dd of varlist `diffdist' {
		sum `dd', d
		if `r(N)'==0 {
			drop `dd'
			disp "dropped `dd' for missing data"
		}
		else {
			gen byte p`dd'a = (`dd' < `r(p25)')
			gen byte p`dd'b = (`dd' >= `r(p25)' & `dd' < `r(p50)')
		}
	}

	drop ctrl1_hchar3* ctrl2_hchar3*
	drop ctrl1_hchar6* ctrl2_hchar6*
	save analysis`r', replace

	*beginning of regressions
	clogit choice pdd* `ctrl1' `ctrl2' [fw=count], group(id)
	predict phat_ij, pc1
	estimates save analysis, append
}
*/

*new run after dropping loving, tx
forval r=11/11 {
	/*
	*create hospital-level dataset to merge in bed number
	use analysis`r', clear
	duplicates drop mprovno, force
	keep mprovno hchar* beds
	save tmp_hosp`r', replace
	desc

	*load regression results into memory
	est use analysis, number(15)
	use analysis`r', clear

	*create phat: probability of a positive outcome
	predict phat_ij, pc1

	keep mprovno pzip phat_ij count
	compress
	expand count

	*begin hospital market structure variable calculations
	*I. HHI_pat_k_star calculation
	*1. generate ahat_jk
	*a. numerator: collapse phat to zip and hospital level (var: pzip, mprovno, sum_phat_kj, count_kj)
	collapse (sum) sum_phat_kj=phat_ij (count) count_kj=count, by(pzip mprovno)
	save tmp_sum_phat_kj, replace
	*b. denominator: collapse 1a. to zip level (var: pzip, sum_phat_k, count_k)
	collapse (sum) sum_phat_k=sum_phat_kj (count) count_k=count_kj, by(pzip)
	save tmp_sum_phat_k, replace
	*c. calculate ahat_jk (zip-hospital level) (var: pzip, mprovno, sum_phat_kj, sum_phat_k, count_kj, count_k, ahat_jk, sq_ahat_jk)
	merge 1:m pzip using tmp_sum_phat_kj, nogen norep
	gen ahat_jk = sum_phat_kj/sum_phat_k
	gen sq_ahat_jk = ahat_jk^2
	save tmp_ahat_jk, replace

	*2. generate HHI_pat_k using 1c. to zip-level (var: HHI_pat_k, count_k, pzip)
	collapse (sum) sum_sq_ahat_k=sq_ahat_jk (count) count_k=count_kj, by(pzip)
	rename sum_sq_ahat_k HHI_pat_k
	save tmp_HHI_pat_k, replace

	*3. generate bhat_kj
	*a. denominator: collapse 1a. to hosp-level (var: sum_phat_j, count_j, mprovno)
	use tmp_sum_phat_kj, clear
	collapse (sum) sum_phat_j=sum_phat_kj (count) count_j=count_kj, by(mprovno)
	save tmp_sum_phat_j, replace
	*b. calculate bhat_kj (zip hospital level) (var: pzip, mprovno, sum_phat_kj, count_kj, sum_phat_j, count_j, bhat_kj)
	use tmp_sum_phat_kj, clear
	merge m:1 mprovno using tmp_sum_phat_j, nogen norep
	gen bhat_kj = sum_phat_kj/sum_phat_j
	save tmp_bhat_kj, replace

	*4. generate HHI_hosp_j (hosp level) (var: HHI_hosp_j, count_j, mprovno)
	merge m:1 pzip using tmp_HHI_pat_k, nogen norep
	gen HHI_hosp_kj= bhat_kj*HHI_pat_k
	collapse (sum) HHI_hosp_j=HHI_hosp_kj (count) count_j=count_kj, by(mprovno)
	save tmp_HHI_hosp_j, replace

	*5. generate HHI_pat_k_star (zip-level) (var: HHI_pat_k_star, count_k, pzip)
	merge 1:m mprovno using tmp_ahat_jk, nogen norep
	gen HHI_pat_jk_star= ahat_jk*HHI_hosp_j
	collapse (sum) HHI_pat_k_star=HHI_pat_jk_star (count) count_k=count_kj, by(pzip)
	save tmp_HHI_pat_k_star, replace

	*III. hosp_char_h_pat_k_star calculations
	use tmp_hosp`r', clear
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	save tmp_hosp`r'_ahat_jk, replace

	*1. calculate sum_ahat_jk_Z_`h'_j for each hospital characteristic
	forval h=1/8 {
		use tmp_hosp`r'_ahat_jk, clear
		*a. calculate ahat_jk_Z_`h'_j (zip hosptial level)
		rename hchar`h' Z_`h'_j
		gen ahat_jk_Z_`h'_j = ahat_jk*Z_`h'_j
		*b. calculate sum_ahat_jk_Z_h_j (zip level)
		collapse (sum) sum_ahat_jk_Z_`h'_j=ahat_jk*Z_`h'_j (count) count_k=count_kj, by(pzip)
		save tmp_sum_ahat_jk_Z_`h'_j, replace
		*c. merge all the new calculations to one file (zip level)
		if `h'==1 {
			save tmp_sum_ahat_jk_Z_j, replace
		}
		else {
			use tmp_sum_ahat_jk_Z_j, clear
			merge 1:1 pzip using tmp_sum_ahat_jk_Z_`h'_j, keepusing(sum_ahat_jk_Z_`h'_j) nogen norep
			save, replace
		}
	}

	*2. calculate sum_bhat_kj_sum_ahat_jk_Z_`h'_j (hosp level)
	merge 1:m pzip using tmp_bhat_kj, keepusing(bhat_kj count_kj mprovno) nogen norep
	save tmp_hosp`r'_ahat_jk_bhat_kj, replace

	forval h=1/8 {
		use tmp_hosp`r'_ahat_jk_bhat_kj, clear
		*a. calculate bhat_kj_sum_ahat_jk_Z_`h'_j (zip hospital level)
		gen bhat_kj_sum_ahat_jk_Z_`h'_j = bhat_kj*sum_ahat_jk_Z_`h'_j
		*b. calculate sum_bhat_kj_sum_ahat_jk_Z_`h'_j (hosp level)
		collapse (sum) sum_bhat_kj_sum_ahat_jk_Z_`h'_j=bhat_kj_sum_ahat_jk_Z_`h'_j (count) count_j=count_kj, by(mprovno)
		save tmp_sum_bhat_kj_sum_ahat_jk_Z_`h'_j, replace
		*c. merge all the new calculations to one file (hosp level)
		if `h'==1 {
			save tmp_sum_bhat_kj_sum_ahat_jk_Z_j, replace
		}
		else {
			use tmp_sum_bhat_kj_sum_ahat_jk_Z_j, clear
			merge 1:1 mprovno using tmp_sum_bhat_kj_sum_ahat_jk_Z_`h'_j, keepusing(sum_bhat_kj_sum_ahat_jk_Z_`h'_j) nogen norep
			save, replace
		}
	}

	*3. calculate hosp_char_`h'_pat_k_star (zip level)
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	save tmp_hosp`r'_ahat_jk_bhat_kj_ahat_jk, replace

	forval h=1/8 {
		use tmp_hosp`r'_ahat_jk_bhat_kj_ahat_jk, clear
		*a. calculate hosp_char_`h'_pat_jk_star (zip hospital level)
		gen hosp_char_`h'_pat_jk_star = ahat_jk*sum_bhat_kj_sum_ahat_jk_Z_`h'_j
		*b. calculate hosp_char_`h'_pat_k_star (zip level)
		collapse (sum) hosp_char_`h'_pat_k_star=hosp_char_`h'_pat_jk_star (count) count_k=count_kj, by(pzip)
		save tmp_hosp_char_`h'_pat_k_star, replace
		*c. merge all the new calculations to one file (zip level)
		if `h'==1 {
			save tmp_hosp_char_pat_k_star, replace
		}
		else {
			use tmp_hosp_char_pat_k_star, clear
			merge 1:1 pzip using tmp_hosp_char_`h'_pat_k_star, keepusing(hosp_char_`h'_pat_k_star) nogen norep
			save, replace
		}
	}
	*/
	**create zip-level market structure file
	use tmp_HHI_pat_k_star, clear
	merge 1:1 pzip using tmp_hosp_char_pat_k_star, keepusing(hosp_char*) nogen
	keep pzip HHI_pat_k_star hosp_char*
	save region11, replace
}

*new CAP measure
forval r=1/14 {
	*create hospital-level dataset to merge in bed number
	use analysis`r', clear
	duplicates drop mprovno, force
	keep mprovno hchar* beds
	save tmp_hosp`r', replace
	desc

	*load regression results into memory
	est use analysis, number(`r')
	use analysis`r', clear

	*create phat: probability of a positive outcome
	predict phat_ij, pc1

	keep mprovno pzip phat_ij count
	compress
	expand count
	
	*begin hospital market structure variable calculations
	*I. HHI_pat_k_star calculation
	*1. generate ahat_jk
	*a. numerator: collapse phat to zip and hospital level (var: pzip, mprovno, sum_phat_kj, count_kj)
	collapse (sum) sum_phat_kj=phat_ij (count) count_kj=count, by(pzip mprovno)
	save tmp_sum_phat_kj, replace
	*b. denominator: collapse 1a. to zip level (var: pzip, sum_phat_k, count_k)
	collapse (sum) sum_phat_k=sum_phat_kj (count) count_k=count_kj, by(pzip)
	save tmp_sum_phat_k, replace
	*c. calculate ahat_jk (zip-hospital level) (var: pzip, mprovno, sum_phat_kj, sum_phat_k, count_kj, count_k, ahat_jk, sq_ahat_jk)
	merge 1:m pzip using tmp_sum_phat_kj, nogen norep
	gen ahat_jk = sum_phat_kj/sum_phat_k
	gen sq_ahat_jk = ahat_jk^2
	save tmp_ahat_jk, replace
	
	*3. generate bhat_kj
	*a. denominator: collapse 1a. to hosp-level (var: sum_phat_j, count_j, mprovno)
	use tmp_sum_phat_kj, clear
	collapse (sum) sum_phat_j=sum_phat_kj (count) count_j=count_kj, by(mprovno)
	save tmp_sum_phat_j, replace
	*b. calculate bhat_kj (zip hospital level) (var: pzip, mprovno, sum_phat_kj, count_kj, sum_phat_j, count_j, bhat_kj)
	use tmp_sum_phat_kj, clear
	merge m:1 mprovno using tmp_sum_phat_j, nogen norep
	gen bhat_kj = sum_phat_kj/sum_phat_j
	save tmp_bhat_kj, replace
	
	
	*II. CAP_pat_k_star calculations
	*1. generate CAP_pat_k (zip level) (var: CAP_pat_k, count_k, pzip)
	use tmp_hosp`r', clear
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk sum_phat_kj count_kj pzip) nogen norep
	gen CAP_pat_jk= ahat_jk*beds/sum_phat_kj
	collapse (sum) CAP_pat_k=CAP_pat_jk (count) count_k=count_kj, by(pzip)
	save tmp_CAP_pat_k, replace

	*2. generate CAP_pat_k_star 
	*a. calculate sum_bhat_kj_CAP_pat_k (hosp level) (var: sum_bhat_kj_CAP_pat_k, count_j, mprovno)
	merge 1:m pzip using tmp_bhat_kj, keepusing(bhat_kj count_kj mprovno) nogen norep
	gen bhat_kj_CAP_pat_k= bhat_kj*CAP_pat_k
	collapse (sum) sum_bhat_kj_CAP_pat_k=bhat_kj_CAP_pat_k (count) count_j=count_kj, by(mprovno)
	save tmp_sum_bhat_kj_CAP_pat_k, replace
	*b. calculate CAP_pat_k_star (zip level) (var: CAP_pat_k_star, count_k, pzip)
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	gen ahat_jk_sum_bhat_kj_CAP_pat_k = ahat_jk*sum_bhat_kj_CAP_pat_k
	rename ahat_jk_sum_bhat_kj_CAP_pat_k CAP_pat_jk_star
	collapse (sum) CAP_pat_k_star=CAP_pat_jk_star (count) count_k=count_kj, by(pzip)
	save tmp_CAP_pat_k_star, replace

	if `r'==1 {
		save cap, replace
	}
	else {
		append using cap
		save cap, replace
	}
	
}

use hosp_mrkt_zip, clear
drop CAP*
drop if pzip==79754
merge 1:1 pzip using cap, keepusing(CAP_pat_k_star) nogen
merge 1:1 pzip using region11, update replace nogen
