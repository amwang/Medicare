set more off
set mem 20g
set matsize 11000
use iv_rcc, clear

gen charge0 = (totchrg==1)
gen cost0 = (cost==1)
gen rev0 = (revenue==1)
gen poschrg = (totchrg>1)
gen poscost = (cost>1)
gen posrev = (revenue>1)
drop if cost>1 & revenue==1

estpost sum if poschrg==1
esttab using sum.rtf, cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(1)) max(fmt(0))") nomtitle nonumber append