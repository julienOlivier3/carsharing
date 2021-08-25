# carsharing
Project on the substitutional effects of regional charsharing offers on private transportation

In this project, I intend to analyze how the existence of a carsharing service in a region affects private transport (more precisely the number of newly registered vehicles in the respective region). For now, I am working with two publicly available datasets (information on the location of shared cars by Bundesverband CarSharing: https://carsharing.de/cs-standorte-ol3-v7 and panel information on the number of newly registered cars at regional level by the Federal Motor Transport Authority: https://www.kba.de/DE/Statistik/Fahrzeuge/Neuzulassungen/neuzulassungen_inhalt.html?nn=2601598). Gathering the data requires me to setup a scraping framework to collect information in which regions/cities car sharing services exist and which companies run these services. This information exists but is not available in a structured format (at least not publicly). So, a first step will be the development of a scraping framework (using rvest and RSelenium) which I am happy to share here.


To-Do:
- find a way to handle errors due to stale elements in Selenium.
- contact the guys at the Federal Motor Transport Authority and check whether they provide data on the number of **newly registered** and **deregistered** cars also on the district (German: Gemeinde) level. So far, I could only find the **stock** of cars at this level.
- Use the Mannheim Enterprise Panel (MUP) to find out when (which year) the regional carsharing providers entered into the market.
