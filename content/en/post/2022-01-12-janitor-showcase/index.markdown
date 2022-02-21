---
title: 'Showcasing the janitor package'
author: ''
date: '2022-01-12'
slug: []
categories: []
tags: []
description: 'I demonstrate a couple of functions from the janitor package I find quite useful'
hideToc: no
enableToc: yes
enableTocContent: no
tocFolding: no
tocPosition: inner
tocLevels:
  - h2
  - h3
  - h4
series: ~
image: ~
libraries:
  - mathjax
---



The `janitor` package contains only a little number of functions but nevertheless
it is surprisingly convenient.
I never really fully appreciated its functionality until I took a look into the documentation.
Of course, other packages can achieve the same thing too but `janitor` makes
a lot of tasks easy.
Thus, here is a little showcase.

## Clean column names

As everyone working with data knows, data sets rarely come in a clean format.
Often, the necessary cleaning process already starts with the column names.
Here, take this data set from TidyTuesday, week 41.


```r
nurses <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2021/2021-10-05/nurses.csv')
names(nurses)
##  [1] "State"                                          
##  [2] "Year"                                           
##  [3] "Total Employed RN"                              
##  [4] "Employed Standard Error (%)"                    
##  [5] "Hourly Wage Avg"                                
##  [6] "Hourly Wage Median"                             
##  [7] "Annual Salary Avg"                              
##  [8] "Annual Salary Median"                           
##  [9] "Wage/Salary standard error (%)"                 
## [10] "Hourly 10th Percentile"                         
## [11] "Hourly 25th Percentile"                         
## [12] "Hourly 75th Percentile"                         
## [13] "Hourly 90th Percentile"                         
## [14] "Annual 10th Percentile"                         
## [15] "Annual 25th Percentile"                         
## [16] "Annual 75th Percentile"                         
## [17] "Annual 90th Percentile"                         
## [18] "Location Quotient"                              
## [19] "Total Employed (National)_Aggregate"            
## [20] "Total Employed (Healthcare, National)_Aggregate"
## [21] "Total Employed (Healthcare, State)_Aggregate"   
## [22] "Yearly Total Employed (State)_Aggregate"
```

These column names are intuitively easy to understand but not necessarily easy to process
by code as there are white spaces and other special characters.
Therefore, I accompany most data input by `clean_names()` from the `janitor` package.


```r
library(janitor)
library(dplyr) # load for pipe %>%  and later wrangling
names(nurses %>% clean_names)
##  [1] "state"                                       
##  [2] "year"                                        
##  [3] "total_employed_rn"                           
##  [4] "employed_standard_error_percent"             
##  [5] "hourly_wage_avg"                             
##  [6] "hourly_wage_median"                          
##  [7] "annual_salary_avg"                           
##  [8] "annual_salary_median"                        
##  [9] "wage_salary_standard_error_percent"          
## [10] "hourly_10th_percentile"                      
## [11] "hourly_25th_percentile"                      
## [12] "hourly_75th_percentile"                      
## [13] "hourly_90th_percentile"                      
## [14] "annual_10th_percentile"                      
## [15] "annual_25th_percentile"                      
## [16] "annual_75th_percentile"                      
## [17] "annual_90th_percentile"                      
## [18] "location_quotient"                           
## [19] "total_employed_national_aggregate"           
## [20] "total_employed_healthcare_national_aggregate"
## [21] "total_employed_healthcare_state_aggregate"   
## [22] "yearly_total_employed_state_aggregate"
```

Did you see what happened?
White spaces were converted to `_` and parantheses were removed.
Even the `%` signs were converted to `percent`.
Now, these labels are easy to understand AND process by code.
This does not mean that you are finished cleaning but at least now the columns
are more accessible.

## Remove empty and or constant columns and rows

Data sets come with empty or superfluous rows or columns are not a rare sighting. 
This is especially true if you work with Excel files because there will be a lot of empty
cells.
Take a look at the dirty Excel data set from janitor's [GitHub page](https://github.com/sfirke/janitor/blob/main/dirty_data.xlsx).
It looks like this when you open it with Excel.

<img src="dirty_data.PNG" width="751" />

Taking a look just at this picture we may notice a couple of things.

- First, [Jason Bourne](https://en.wikipedia.org/wiki/Jason_Bourne) is teaching at a school. 
I guess being a trained assassin qualifies him to teach physical education.
Also - and this is just a hunch - undercover work likely earned him his "Theater" certification.

- Second, the header above the actual table will be annoying, so we must skip the first line
when we read the data set.

- Third, the column names are not ideal but we know how to deal with that by now.

- Fourth, there are empty rows and columns we can get rid of.

- Fifth, there is a column that contains only 'YES'.
Therefore it contains no information at all and can be removed.

So, let us read and clean the data.
The `janitor` package will help us with `remove_empty()` and `remove_constant()`.


```r
xl_file <- readxl::read_excel('dirty_data.xlsx', skip = 1) %>% 
  clean_names() %>%
  remove_empty() %>% 
  remove_constant()
xl_file
## # A tibble: 12 x 9
##    first_name   last_name employee_status subject    hire_date percent_allocated
##    <chr>        <chr>     <chr>           <chr>          <dbl>             <dbl>
##  1 Jason        Bourne    Teacher         PE             39690              0.75
##  2 Jason        Bourne    Teacher         Drafting       43479              0.25
##  3 Alicia       Keys      Teacher         Music          37118              1   
##  4 Ada          Lovelace  Teacher         <NA>           38572              1   
##  5 Desus        Nice      Administration  Dean           42791              1   
##  6 Chien-Shiung Wu        Teacher         Physics        11037              0.5 
##  7 Chien-Shiung Wu        Teacher         Chemistry      11037              0.5 
##  8 James        Joyce     Teacher         English        36423              0.5 
##  9 Hedy         Lamarr    Teacher         Science        27919              0.5 
## 10 Carlos       Boozer    Coach           Basketball     42221             NA   
## 11 Young        Boozer    Coach           <NA>           34700             NA   
## 12 Micheal      Larsen    Teacher         English        40071              0.8 
## # ... with 3 more variables: full_time <chr>, certification_9 <chr>,
## #   certification_10 <chr>
```

Here, `remove_empty()` defaulted to remove, both, rows and colums.
If we wish, we can change that by setting e.g. `which = 'rows'`.

Now, we may also want to see the `hire_data` in a sensible format.
For example, in this dirty data set, Jason Bourne was hired on `39690`.
Luckily, our `janitor` can make sense of it all.


```r
xl_file %>% 
  mutate(hire_date = excel_numeric_to_date(hire_date))
## # A tibble: 12 x 9
##    first_name   last_name employee_status subject    hire_date  percent_allocat~
##    <chr>        <chr>     <chr>           <chr>      <date>                <dbl>
##  1 Jason        Bourne    Teacher         PE         2008-08-30             0.75
##  2 Jason        Bourne    Teacher         Drafting   2019-01-14             0.25
##  3 Alicia       Keys      Teacher         Music      2001-08-15             1   
##  4 Ada          Lovelace  Teacher         <NA>       2005-08-08             1   
##  5 Desus        Nice      Administration  Dean       2017-02-25             1   
##  6 Chien-Shiung Wu        Teacher         Physics    1930-03-20             0.5 
##  7 Chien-Shiung Wu        Teacher         Chemistry  1930-03-20             0.5 
##  8 James        Joyce     Teacher         English    1999-09-20             0.5 
##  9 Hedy         Lamarr    Teacher         Science    1976-06-08             0.5 
## 10 Carlos       Boozer    Coach           Basketball 2015-08-05            NA   
## 11 Young        Boozer    Coach           <NA>       1995-01-01            NA   
## 12 Micheal      Larsen    Teacher         English    2009-09-15             0.8 
## # ... with 3 more variables: full_time <chr>, certification_9 <chr>,
## #   certification_10 <chr>
```

## Rounding 

To my ~~surprise~~ shock, R uses some unexpected rounding rule.
In my world, whenever a number ends in `.5`, standard rounding would round up.
Apparently, R uses something called *banker's rounding* that in these cases 
rounds towards the next *even* number.
Take a look.


```r
round(seq(0.5, 4.5, 1))
## [1] 0 2 2 4 4
```

I would expect that the rounded vector contains the integers from one to five.
Thankfully, `janitor` offers a convenient rounding function.


```r
round_half_up(seq(0.5, 4.5, 1))
## [1] 1 2 3 4 5
```

Ok, so that gives us a new function for rounding towards integers.
But what is really convenient is that `janitor` can `round_to_fraction`s.


```r
round_to_fraction(seq(0.5, 2.0, 0.13), denominator = 4)
##  [1] 0.50 0.75 0.75 1.00 1.00 1.25 1.25 1.50 1.50 1.75 1.75 2.00
```

Here, I rounded the numbers to the next quarters (`denominator = 4`) but of course
any fraction is possible. 
You can now live the dream of rounding towards arbitrary fractions.


## Find matches in multiple characteristics

In my opinion, the `get_dupes()` function is really powerful.
It allows us to find "similar" observations in a data set based on certain characteristics.
For example, the `starwars` data set from `dplyr`  contains a lot of information 
on characters from the Star Wars movies.
Possibly, we want to find out which characters are similar w.r.t. to certain traits.


```r
starwars %>% 
  get_dupes(eye_color, hair_color, skin_color, sex, homeworld) %>% 
  select(1:8)
## # A tibble: 7 x 8
##   eye_color hair_color skin_color sex    homeworld dupe_count name        height
##   <chr>     <chr>      <chr>      <chr>  <chr>          <int> <chr>        <int>
## 1 blue      black      yellow     female Mirial             2 Luminara U~    170
## 2 blue      black      yellow     female Mirial             2 Barriss Of~    166
## 3 blue      blond      fair       male   Tatooine           2 Luke Skywa~    172
## 4 blue      blond      fair       male   Tatooine           2 Anakin Sky~    188
## 5 brown     brown      light      female Naboo              3 Cordé          157
## 6 brown     brown      light      female Naboo              3 Dormé          165
## 7 brown     brown      light      female Naboo              3 Padmé Amid~    165
```

So, Luke and Anakin Skywalker are similar to one another. 
Who would have thought that.
Sadly, I don't enough about Star Wars to know whether the other matches are similarly 
"surprising".
In any case, the point here is that we can easily find matches according to 
arbitrarily many characteristics.
Conveniently, these characteristics are the first columns of the new output and 
we get a `dupe_count`.


Alright, this concludes our little showcase.
In the `janitor` package, there is another set of `tabyl()` functions. 
These are meant to improve base R's `table()` functions. 
Since I rarely use that function I did not include it but if you use `table()` frequently, 
then you should definitely [check out tabyl()](http://sfirke.github.io/janitor/articles/tabyls.html).
