if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse)

carsharing_locations <- read_delim(file = "01_Data/03_Carsharing/scraping_sample.txt", delim = '\t')

length(unique(carsharing_locations$provider))
length(unique(carsharing_locations$provider_id))

carsharing_districts <- carsharing_locations %>% 
  filter(!is.na(provider)) %>% 
  distinct(district, provider)

carsharing_providers <- carsharing_districts %>%
  distinct(provider)

carsharing_providers %>% 
  mutate(id = row.names(.)) %>% 
  select(id, provider) %>% 
  write_delim("01_Data/03_Carsharing/carsharing_providers.txt", delim = "\t")
