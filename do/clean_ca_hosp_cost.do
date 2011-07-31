/***
clean_ca_hosp_cost.do
***/
use "/Users/Angela/Desktop/Medicare/sas/new_hosp_cost_CA.dta", clear
drop FY_BGN_DT- ccr
gen FY_begin9 = date(beg_date_09, "MDY", 2050)
gen FY_end9 = date(end_date_09, "MDY", 2050)
gen FY_begin8 = date(beg_date_08, "MDY", 2050)
gen FY_end8 = date(end_date_08, "MDY", 2050)

format %td FY_begin8 FY_end8 FY_begin9 FY_end9
drop beg_date_09 end_date_09 beg_date_08 end_date_08
drop fac_no
rename npr_comp_09 npr_comp9
rename npr_ma_09 npr_ma9
rename npr_comp_08 npr_comp8 
rename npr_ma_08 npr_ma8

reshape long FY_begin FY_end npr_comp npr_ma, i(mprovno)
drop _j

fdasave "/Users/Angela/Desktop/Medicare/do/ca_hosp.xpt", replace rename vallabfile(none)
