library(rvest)
library(glue)
library(foreach)

election_dates <- c("26.09.2021", "24.09.2017", "22.09.2013", "27.09.2009", "18.09.2005", "22.09.2002", "27.09.1998") %>% 
  parse_date("%d.%m.%Y")

# Scrape data from Allensbach institute
allensbach_url <- "https://www.wahlrecht.de/umfragen/allensbach.htm"
allensbach_splits <- c(2002, 2005, 2009, 2013, 2017, 2021)
extract_allensbach <- function(year = 2021) {
  if (year %in% allensbach_splits[-length(allensbach_splits)]) {
    url <- str_replace(allensbach_url, ".htm", glue("/{year}.htm"))
  } else {
    url <- allensbach_url
  }
  
  table <- read_html(url) %>% 
    html_nodes("table") %>% 
    html_table() %>% 
    pluck(2) 
  
  last_col <- which(colnames(table) == "Sonstige")
  
  table <- table[-(1:3), c(1, 3:last_col)] 
  colnames(table)[1] <- "date"
  
  table %>% 
    mutate(across(
      .cols = -date,
      .fns = ~(parse_number(., na = "–") / 1000)
    )) %>% 
    mutate(date = readr::parse_date(date, "%d.%m.%Y"))
  
}

allensbach <- foreach (year = allensbach_splits) %do% {
  extract_allensbach(year)
} %>% 
  bind_rows() 
allensbach <- allensbach %>% 
  mutate(institute = "allensbach", .before = 1)

## Scrape data from Emnid institute
emnid_splits <- c(1998:2008, 2013, 2021)
emnid_url <- "https://www.wahlrecht.de/umfragen/emnid.htm"
extract_emnid <- function(year = 2021) {
  if (year %in% emnid_splits[-length(emnid_splits)]) {
    url <- str_replace(emnid_url, ".htm", glue("/{year}.htm"))
  } else {
    url <- emnid_url
  }
  
  table <- read_html(url) %>% 
    html_nodes("table") %>% 
    html_table() %>% 
    pluck(2) 
  
  if (year != 2013) {
    last_col <- which(colnames(table) == "Sonstige")
    table <- table[-(1:3), c(1, 3:last_col)] 
    colnames(table)[1] <- "date"
  } else {
    last_col <- which(table[1, ] == "Sonstige")
    colnames(table) <- c(
      "date", 
      table[1, 2:last_col] %>% unlist() %>% unname()
    )
    table <- table[-(1:4), c(1, 3:last_col)] 
  }
  
  table %>% 
    mutate(across(
      .cols = -date,
      .fns = ~(parse_number(., na = "–") / 100)
    )) %>% 
    mutate(date = str_replace(date, "(\\*)+", "")) %>% 
    mutate(date = str_replace(date, "Wahl 1998", "27.09.1998")) %>%
    mutate(date = readr::parse_date(date, "%d.%m.%Y"))
  
}

emnid <- foreach (year = emnid_splits) %do% {
  extract_emnid(year)
} %>% 
  bind_rows() 
emnid <- emnid %>% mutate(institute = "emnid", .before = 1)

troublesome_dates <- c("13.09.2005") %>% 
  parse_date("%d.%m.%Y") %>% 
  c(election_dates)

emnid[emnid$date %in% troublesome_dates, -(1:2)] <- 
  emnid[emnid$date %in% troublesome_dates, -(1:2)] / 10

emnid[emnid$date %in% parse_date("10.09.2005", "%d.%m.%Y"), c("CDU/CSU", "SPD")] <- 
  emnid[emnid$date %in% parse_date("10.09.2005", "%d.%m.%Y"), c("CDU/CSU", "SPD")] / 10


allensbach_longer <- allensbach %>% 
  pivot_longer(cols = -c(1, 2), names_to = "party", values_to = "votes") 

emnid_longer <- emnid %>% 
  pivot_longer(cols = -c(1, 2), names_to = "party", values_to = "votes") 

combined <- bind_rows(allensbach_longer, emnid_longer)

write_csv(combined, "allensbach_emnid_votes.csv")
