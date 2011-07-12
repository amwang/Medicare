clear all
cd /Users/Angela/Desktop/ANG/Desktop/Medicare/xwalks
insheet using "AGED08.txt", tab

gen ffs_spend=partapercapitawoimedshgme+partadsh/(partaenrollment*12)+partbpercapita
rename partapercapitawoimedshgme parta
rename partaenrollment partaenroll
rename partbpercapita partb
tostring code, gen(ssa) format(%05.0f)
keep ssa ffs_spend parta partadsh partaenroll partb
order ssa ffs_spend parta partadsh partaenroll partb
save ffs_spend, replace
outsheet using "ffs_spend.txt", replace

clear all
insheet using "cty_risk.txt", tab
rename cty ssa
merge 1:1 ssa using ffs_spend, nogen keep(3)
drop if ffs_spend==0
gen b_minus_ffs=benchmar-ffs_spend
gen b_div_ffs=benchmar/ffs_spend
save ffs, replace

clear all
insheet using "state_FIPS_ctytext_xwalk.csv"
gen county=countyname+", "+state
tostring stateansi, replace format(%02.0f)
tostring countyansi, replace format(%03.0f)
gen fips = stateansi+countyansi
keep county fips
save fips_county, replace

clear all
insheet using "SSA_FIPS_xwalk.txt", tab
tostring ssa fips, replace format(%05.0f)
merge m:1 fips using fips_county, keep(1 3) nogen
drop if substr(fips,1,2)=="02"
drop if substr(ssa,1,2)=="02"

merge 1:1 ssa using ffs, nogen
gsort -ffs_spend
save benchmark_new, replace
outsheet using "benchmark_new.txt", replace
