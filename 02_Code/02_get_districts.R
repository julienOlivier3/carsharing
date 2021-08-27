if (!require("pacman")) install.packages("pacman")
pacman::p_load(tidyverse, readxl, janitor)


districts <- readxl::read_excel("01_Data\\02_Bestand\\fz3_2021.xlsx", sheet = "FZ 3.1", range = "D9:D11215") %>% 
  clean_names()
  
districts <- districts %>% 
  mutate(district_clean = str_remove(plz_gemeinde, pattern = "\\,.*")) %>%  # drop some unwanted information in the district names
  filter(str_detect(district_clean, pattern = "\\d{5}")) %>% # drop entries not related to districts (basically subtotal infos)
  select(district_clean)




  