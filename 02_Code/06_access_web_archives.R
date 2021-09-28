library("tidyverse")

# Create list of working urls for all years in which locations have been archived
url <- "https://web.archive.org/web/20160323172157/https://carsharing.de/cs-standorte"

html <- read_html(url)

html %>% html_text() %>% 
  write_lines(here('01_Data/03_Carsharing/temp_2016.txt'))

# Look at temp_2016.txt to understand how parsing needs to be done in order to extract carsharing locations!