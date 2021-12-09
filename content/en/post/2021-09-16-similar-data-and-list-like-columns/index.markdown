---
title: Writing Versatile Functions with R
author: ''
date: '2021-09-16'
slug: []
categories: []
tags: []
description: "Using concepts like dot-dot-dot and curly-curly we create functions that are more versatile and can be used in multiple settings."
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



This week, I had to deal with two very similar tasks on two very similar but not identical data sets that required me to write a function that is versatile enough to deal with both data sets despite their subtle differences.
The differences that had to be accounted for mainly related to using functions in the two cases that relied on differently many arguments.
Also, some of the column names were different which meant that I could not hard-code the column names into the function I was creating.

Consequently, I had to use a few non-standard concepts (at least not standard to me) that enabled me to create the function which did everything I asked it to do.
Since these concepts seemed interesting to me, I decided to implement a small example resulting in this blog post.
Actually, I was even motivated to create a video for this blog post.
You can find it [on YouTube](https://youtu.be/L_sX-sL9aWM).







## What We Want To Achieve

The aim of this example is to write a function that can create two tibbles that are conceptually similar but do not necessarily use the same column names or compute the existing columns in the same way.
For this blog post, I have already set up two dummy data sets like that so that we can see what we want to do.  
Let's take a look at these data sets I creatively called `dat_A` and `dat_B`.


```r
library(tidyverse)
dat_A %>% head(3)
## # A tibble: 3 x 3
##      mu sigma dat             
##   <dbl> <dbl> <list>          
## 1    -1   1   <tibble [5 x 2]>
## 2    -1   1.5 <tibble [5 x 2]>
## 3    -1   2   <tibble [5 x 2]>
dat_B %>% head(3)
## # A tibble: 3 x 2
##   lambda dat             
##    <dbl> <list>          
## 1    0.5 <tibble [5 x 2]>
## 2    0.7 <tibble [5 x 2]>
## 3    0.9 <tibble [5 x 2]>
```


As you can see, each tibble contains a column `dat`.
This column consists of tibbles with multiple summarized stochastic processes which were simulated using parameters that are given by the remaining columns of `dat_A` and `dat_B`.

You probably have already noticed that the stochastic processes must have been simulated using differently many parameters since tibble A contains additional columns `mu` and `sigma` whereas tibble B can offer only one additional column `lambda`.
However, even if differently many and differently named parameters are used, the logic of the generating function needs to be the same:

1. Take parameters.
2. Simulate stochastic processes with these parameters.
3. Summarize processes

Thus, in step 1 the generating function which we want to code, needs to be versatile enough to handle different argument names and amounts.
Next, let's see what the `dat` column has in store for us.


```r
dat_A %>% pluck("dat", 1) %>% head(3)
## # A tibble: 3 x 2
##       n proc_mean
##   <int>     <dbl>
## 1     1    -1.01 
## 2     2    -0.958
## 3     3    -0.968
dat_B %>% pluck("dat", 1) %>% head(3)
## # A tibble: 3 x 2
##       n proc_variance
##   <int>         <dbl>
## 1     1          5.27
## 2     2          2.66
## 3     3          3.08
```

First of all, notice that I accessed the first tibble in the `dat` column using the super neat `pluck()` function.
In my opinion, this function is preferable to the clunky base R usage of `$` and `[[`, e.g. like `dat_A$dat[[1]]`.

As you can see, the tibbles that are saved in `dat` contain columns `n` and `proc_mean` resp. `proc_variance`.
As hinted at before, each row is supposed to represent a summary of the `n`-th realization of a stochastic process.

However, notice that the summary statistics in use are not the same!
The different column names `proc_mean` and `proc_variance` indicate that in tibble A the sample mean was used whereas tibble B contains sample variances.
Again, our function that generates `tib_A` and `tib_B` should be flexible enough to create differently named and differently computed columns.

## Helpful Concepts

Now that we know what we want to create, let us begin by learning how to handle differently many arguments and their varying names.

### dot-dot-dot

For these kinds of purposes, R offers the `...`-operator (pronounced dot-dot-dot).
Basically, it serves as a placeholder for everything you do not want to evaluate immediately.

For instance, have you ever wondered how `dplyr`'s `select()` function is able to select the correct column?[^yards-reused]
If you're thinking "No, but what's so special about this?", then you may want to notice that it is actually not that simple to define your own `select()` function even with the help of the `dplyr` function.

This is because defining an appropriate function to select two columns from, say, the `iris` data set cannot be done like this:


```r
my_select <- function(x, y) {select(iris, x, y)}
```

Now, if you want to use the function the same way you would use `dplyr::select()`, i.e. simply passing, say, `Sepal.Width, Sepal.Length` (notice no `""`) to your new function, it would look like this


```r
my_select(Sepal.Width, Sepal.Length)
#> Error: object 'Sepal.Width' not found
```

This error appears because at some point, R will try to evaluate the arguments as variables from your current environment.
But of course this variable is not present in your environment and only present within the `iris` data set.
Therefore, what `dplyr::select()` accomplishes is that it lets R know to evaluate the input argument only later on, i.e. when the variable from the data set is "available".

This is where `...` comes into play. 
It is not by chance that `select()` only has arguments `.data` and `...`. 
Here, `select()` uses that everything which is thrown into `...`, will be passed along to be evaluated later.
This can save our `my_select()` function, too.


```r
my_select <- function(...) {select(iris, ...)}
my_select(Sepal.Width, Sepal.Length) %>% head(3)
##   Sepal.Width Sepal.Length
## 1         3.5          5.1
## 2         3.0          4.9
## 3         3.2          4.7
```


Works like a charm!
This will help us to define a function that is flexible enough for our purposes.
Before we start with that, let us learn about another ingredient we will use.

### curly-curly

If we were to only select a single column from `iris` using our `my_select()` function, we could have also written the function using `{{ }}` (pronounced curly-curly).
It operators similar to `...` in the sense that it allows for later evaluation but applies this concept to specific variable.
Check out how that can be used here.


```r
my_select <- function(x) {select(iris, {{x}})}
my_select(Sepal.Width) %>% head(3)
##   Sepal.Width
## 1         3.5
## 2         3.0
## 3         3.2
```


What's more the curly-curly variables - curly-curlied variables (?) - can also be used later on for stuff like naming a new column.
For example, let us modify our previous function to demonstrate how that can be used.


```r
select_and_add <- function(x, y) {
  select(iris, {{x}}) %>% 
    mutate({{y}} := 5) 
  # 5 can be replaced by some meaningful calculation
}
select_and_add("Sepal.Width", "variable_y") %>% head(3)
##   Sepal.Width variable_y
## 1         3.5          5
## 2         3.0          5
## 3         3.2          5
```

Mind the colon!
Here, if you want to use `y` as column name later on you cannot use the standard `mutate()` syntax but have to use `:=` instead.

### Functional Programming

One last thing that we will use, is the fact that R supports functional programming.
Thus, we can use functions as arguments of other functions.
For instance, take a look at this super simple, yet somewhat useless wrapper function for illustration purposes.


```r
my_simulate <- function(n, func) {
  func(n)
}
set.seed(564)
my_simulate(5, rnorm)
## [1]  0.4605501 -0.7750968 -0.7159321  0.6882645 -2.0544591
```

As you just witnessed, I simply passed `rnorm` (without a call using `()`) to `my_simulate` as the `func` argument such that `rnorm` is used whenever `func` is called.
In our use case, this functionality can be used to simulate different stochastic processes (that may depend on different parameters).

## The Implementation

Alright, we have assembled everything we need in order to create our `simulate_and_summarize_proc()` function.
In this example, the simulation of the stochastic processes will consist of simply calling `rnorm()` or `rexp()` but, of course, these functions can be substituted with arbitrarily complex simulation functions.

We will use `n_simus` as the amount of realizations that are supposed to be simulated and each realization will be of length `TMax`.
Further, we will use `...` to handle an arbitrary amount of parameters that are supposed to be passed to `simulation_func`.
So, let's implement the simulation part first (detailed explanations below).


```r
simulate_and_summarize_proc <- 
  function(..., TMax, n_simus, simulation_func) {
    argslist <- list(n = TMax, ...) %>% 
      map(~rep(., n_simus))
    
    tibble(
      t = list(1:TMax),
      n = 1:n_simus,
      value = pmap(argslist, simulation_func)
    ) 
  }
set.seed(457)
simulate_and_summarize_proc(
  mean = 1,
  sd = 2,
  TMax = 200, 
  n_simus = 3, 
  simulation_func = rnorm # arguments -> n, mean, sd
) 
## # A tibble: 3 x 3
##   t               n value      
##   <list>      <int> <list>     
## 1 <int [200]>     1 <dbl [200]>
## 2 <int [200]>     2 <dbl [200]>
## 3 <int [200]>     3 <dbl [200]>
```


As you can see, this created three (simple) stochastic processes of length 200 using the parameters `mean = 1` and `sd = 2`.
We can validate that the correct parameters were used once we implement the summary functions.

First, let us address the tricky part in this function.
In order to pass a list of arguments to `pmap()` that are then used with `simulation_func`, we first need to rearrange the lists a bit.
After the first step, by simply putting everything from `...` into the list we have a list like this:


```r
list(n = 100, mean = 1, sd = 2) %>% str()
## List of 3
##  $ n   : num 100
##  $ mean: num 1
##  $ sd  : num 2
```

However, we will need to have each variable in the list repeated `n_simus` time in order to simulate more than one realization.
Thus, we use `map()` to replicate:


```r
list(n = 200, mean = 1, sd = 2) %>% 
  map(~rep(., 3)) %>% 
  str()
## List of 3
##  $ n   : num [1:3] 200 200 200
##  $ mean: num [1:3] 1 1 1
##  $ sd  : num [1:3] 2 2 2
```

Note that calling `rep()` without `map()` does not cause an error but does not  deliver the appropriate format:


```r
list(n = 100, mean = 1, sd = 2) %>% 
  rep(3) %>% 
  str()
## List of 9
##  $ n   : num 100
##  $ mean: num 1
##  $ sd  : num 2
##  $ n   : num 100
##  $ mean: num 1
##  $ sd  : num 2
##  $ n   : num 100
##  $ mean: num 1
##  $ sd  : num 2
```

Next, let us take the current output and implement the summary.
To do so, we will add another variables `summary_name` and `summary_func` to the function in order to choose a column name resp. a summary statistic. 

```r
simulate_and_summarize_proc <- 
  function(..., TMax, n_simus, simulation_func, summary_name, summary_func) {
    argslist <- list(n = TMax, ...) %>% 
      map(~rep(., n_simus))
    
    tibble(
      t = list(1:TMax),
      n = 1:n_simus,
      value = pmap(argslist, simulation_func)
    ) %>% # this part is added
      unnest(c(t, value)) %>% 
      group_by(n) %>%
      summarise({{summary_name}} := summary_func(value))
  }
set.seed(457)
simulate_and_summarize_proc(
  mean = 1,
  sd = 2,
  TMax = 200, 
  n_simus = 5, 
  simulation_func = rnorm, 
  summary_name = "mega_awesome_mean", 
  summary_func = mean
) 
## # A tibble: 5 x 2
##       n mega_awesome_mean
##   <int>             <dbl>
## 1     1             0.955
## 2     2             0.932
## 3     3             0.987
## 4     4             1.07 
## 5     5             1.15
```

Finally, we can use our super versatile function in combination with `map()` to create `dat_A` and `dat_B`.


```r
dat_A <- 
  expand_grid(
    mu = seq(-1, 1, 0.25),
    sigma = seq(1, 3, 0.5)
  ) %>% 
  mutate(dat = map2(
    mu, sigma, 
    ~simulate_and_summarize_proc(
      mean = .x, 
      sd = .y, 
      TMax = 200, 
      n_simus = 3, 
      simulation_func = rnorm, 
      summary_name = "proc_mean", 
      summary_func = mean
    )
  ))
  

dat_B <- 
  expand_grid(
    lambda = seq(0.5, 1.5, 0.2)
  ) %>% 
  mutate(dat = map(
    lambda, 
    ~simulate_and_summarize_proc(
      rate = .,
      TMax = 200, 
      n_simus = 3, 
      simulation_func = rexp, 
      summary_name = "proc_variance", 
      summary_func = var
    )
  ))
```

## Conclusion

So, we have seen that we can combine `{{ }}`,  `...` and functional programming to create highly versatile functions.
Of course, as always one might be tempted to say that one could have just programmed two different functions for our particular example.

However, this would cause a lot of code duplication because a lot of steps are essentially the same which is hard to debug and maintain.
Also, creating numerous functions does not scale well if we need to cover way more than two cases.

With that being said, I hope that you found this blog post helpful and if so, feel free to hit the comments or push the applause button below.
See you next time.

[^yards-reused]: If you have read my [YARDS lecture notes](https://yards.albert-rapp.de/index.html) and this sounds familiar to you, you are absolutely right.
I have reused and adapted a part of the "Choose Your Own Data Science Adventure"-chapter here.
