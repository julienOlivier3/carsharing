# Substitutional effects of regional carsharing offerings

In this project, I intend to analyze how the existence of a car sharing service in a region affects private transport (more precisely the number of newly registered passenger vehicles in the respective region). For now, I am working with two publicly available data sets:
1. information on the location of shared cars by [Bundesverband CarSharing](https://carsharing.de/cs-standorte)
2. panel information on the number of newly registered cars at regional level by the [Federal Motor Transport Authority](https://www.kba.de/DE/Statistik/Fahrzeuge/Neuzulassungen/neuzulassungen_inhalt.html). 

Gathering the data requires me to setup a scraping framework to collect information in which regions/cities car sharing services exist and which companies run these services. This information exists via the website of Bundesverband CarSharingbut is not available in a structured format (at least not publicly). So, a first step will be the development of a scraping framework (using rvest and RSelenium) which I am happy to share here.


To-Do:
- [x] Find a way to handle errors due to stale elements in Selenium. -> Solved for now by adding additonal sleep times after executing elements with Selenium.
- [ ] Contact the guys at the Federal Motor Transport Authority and check whether they provide data on the number of **newly registered** and **deregistered** cars also on the district (German: Gemeinde) level. So far, I could only find the **stock** of cars at this level of granularity.
- [ ] Use the Mannheim Enterprise Panel (MUP) to find out when (which year) the regional carsharing providers entered into the market.
- [x] Get mobility information (trail station exists, if exists size of trail station, ...) for districts.
- [ ] Get demographic information (population tec.) for districts.

Presentation:

Find a short presentation of the project idea [here](https://raw.githack.com/julienOlivier3/carsharing/main/03_Presentation/short_presentation.html).
