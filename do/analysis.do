/***
analysis.do

do file for constructing and running choice regressions

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: stata1.xpt-stata14.xpt
		
output: stata1.dta-stata14.dta
		analysis.ster

***/

local size 100
local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/`size'/statanew

clear
clear matrix
capture log close
set more off
set mem 8g
set matsize 11000
cd `path'
capture erase "analysis.ster"

forval r=1/14	{
	fdause stata`r'
	compress
	save stata`r', replace
	use stata`r', clear
	*drop all alaska observations
	drop if pzip>=99000 & pzip<100000
	drop if substr(mprovno,1,2)=="02"
	
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
