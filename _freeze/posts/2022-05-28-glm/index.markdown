---
title: glm
format: 
  hugo:
    code-fold: true
author: ''
date: '2022-05-28'
slug: []
categories: []
tags: []
description: 'Introduction to GLMs'
hideToc: no
enableToc: yes
enableTocContent: no
tocFolding: no
tocPosition: inner
tocLevels:
  - h2
  - h3
  - h4
series: ''
image: ~
libraries:
  - mathjax
execute: 
  code-fold: true
---


```
## ── Attaching packages ─────────────────────────────────────── tidyverse 1.3.1 ──
```

```
## ✔ ggplot2 3.3.6     ✔ purrr   0.3.4
## ✔ tibble  3.1.7     ✔ dplyr   1.0.9
## ✔ tidyr   1.2.0     ✔ stringr 1.4.0
## ✔ readr   2.1.2     ✔ forcats 0.5.1
```

```
## ── Conflicts ────────────────────────────────────────── tidyverse_conflicts() ──
## ✖ dplyr::filter() masks stats::filter()
## ✖ dplyr::lag()    masks stats::lag()
```




## Introductory example

## bla

::: panel-tabset
### Transforming OLS estimates



```r
preds_lm %>% 
  ggplot(aes(body_mass_g, bill_length_mm, col = correct)) +
  geom_jitter(size = 4, alpha = 0.6) +
  facet_wrap(vars(species)) +
  scale_color_manual(values = c('grey60', thematic::okabe_ito(3)[3])) +
  scale_x_continuous(breaks = seq(3000, 6000, 1000)) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = 'top', 
    panel.background = element_rect(color = 'black'),
    panel.grid.minor = element_blank()
  ) +
  labs(
    x = 'Body mass (in g)',
    y = 'Bill length (in mm)'
  )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-2-1.png" width="672" />


### Maximizing likelihood



```r
glm.mod <- glm(sex ~ body_mass_g + bill_length_mm + species, family = binomial, data = dat)

preds <- dat %>% 
  mutate(
    prob.fit = glm.mod$fitted.values,
    prediction = if_else(prob.fit > 0.5, 'male', 'female'),
    correct = if_else(sex == prediction, 'correct', 'incorrect')
  )


preds %>% 
  ggplot(aes(body_mass_g, bill_length_mm, col = correct)) +
  geom_jitter(size = 4, alpha = 0.6) +
  facet_wrap(vars(species)) +
  scale_x_continuous(breaks = seq(3000, 6000, 1000)) +
  scale_color_manual(values = c('grey60', thematic::okabe_ito(3)[3])) +
  theme_minimal(base_size = 10) +
  theme(
    legend.position = 'top', 
    panel.background = element_rect(color = 'black'),
    panel.grid.minor = element_blank()
  ) +
  labs(
    x = 'Body mass (in g)',
    y = 'Bill length (in mm)'
  )
```

<img src="{{< blogdown/postref >}}index_files/figure-html/unnamed-chunk-3-1.png" width="672" />

:::



Let me know what you think in the comments or simply hit the applause button below.

