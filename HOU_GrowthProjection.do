cd "C:\Users\MDL\Desktop\HOU_TREND"
use base.dta

//Specifying data origin, generating a trend variable from t=1.
//Generating a scatter plot of passengers/trend.
keep if origin=="HOU"
gen trend = (year-1993)*4 + quarter
scatter passenger trend

//Generating 4 dummy variables assigning values to respective quarters.
gen q1 = quarter == 1
gen q2 = quarter == 2
gen q3 = quarter == 3
gen q4 = quarter == 4

//Sorting dummy vars, regressing passengers/trend/dummy vars.
//Generating linear prediction of passenger data & predicted residuals.
sort quarter
reg passengers trend q1 q2 q3
predict passhat, xb
predict res, r

//Scatter plot of passengers against previously generated predictions.
//Scatter of residuals/trend.
//Restricted regression of passengers/trend.
scatter passengers passhat
scatter res trend
reg passengers trend

summarize rank year quarter passengers passhat trend q1 q2 q3 res

***************************

rename value gdppd
keep if origin=="HOU"
drop trend
gen trend = (year-1993)*4+quarter

replace passengers = passengers*10


//for income_x increments of 20 up to 200
//dividing each income to get real income
forv x=20(20)200  { 
replace income_`x' = income_`x'/(gdppd/100)
}

gen d1=quarter==1
gen d2=quarter==2
gen d3=quarter==3
gen d4=quarter==4

//before 911 dummy should be zero, once 9/11 dummy variable==1
//creates interaction dummy
gen d911=trend>35
gen inter=d911*trend


forv x=20(20)200 {
reg passengers income_`x' pop_`x' trend d2 d3 d4 d911 inter
gen r2_`x'=e(r2)
}

keep r2*
duplicates drop
gen ii=1
reshape long r2_, i(ii) j(distance)
line r2_distance, sort

//Picking regression with highest output from airport.
//Then picking regression for passenger best fit matched to distance.

clear
replace passengers = passengers*10
forv x=20(20)200 {
replace income_`x' = income_`x'/(gdppd/100)
}

keep if year===2009 & quarter==4
keep passengers pop_20 income_20 origin

sort pop_20
reg passengers pop_20 if _n<38
gen smallrss=e(rss)

reg passengers pop_20 if n>63
gen largerss=e(rss)

gen chi2 = largerss/smallrss

***************************

merge m:m year quarter origin using quar_inc_pop
rename _merge merged
drop if merged~=3

keep if origin=="HOU"
drop trend
gen trend = (year-1993)*4+quarter
tsset trend

reg passengers pop_40 income_40
predict res, r

tsline res

//Breush-Godfrey Test
//Ho: no serial autocorrelation
//Ha: serial autocorrelation

estat bgodfrey

reg passengers pop_40 income_40 L.passengers

estat bgodfrey 
//Chi value now small, reject null 
//H0: no positive serial correlation

***************************

merge 1:1 origin quarter year using "C:\Users\MDL\Desktop\HOU_TREND\quar_inc_pop.dta"

//merge data sets for airports
keep if origin=="HOU"
gen date_index = _n
//generates index numbers for dates from 1993q1 to 2009q4

tsset date_index
//declares data set as a time series
reg passengers income_40 L.passengers
//regression for passengers on income_40 and the lag of passengers
reg passengers income_40 L.passengers L.income_40
//regression for passengers on income_40 and lags for passengers and income_40
reg passengers income_40 L.passengers L2.passengers L.income_40
//regression for passengers on income_40, first and second order lags for
//passengers and the lag of income_40
reg passengers income_40 L.passengers L.income_40

//ADL (1,1) for Bgodfrey test
estat bgodfrey
//bgodfrey test on ADL(1,1) for autocorrelation
