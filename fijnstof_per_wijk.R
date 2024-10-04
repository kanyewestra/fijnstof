library(sf)
library(raster)
library(exactextractr)
library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# Berekening per wijk gebeurt als volgt: 
#Kort samengevat: het gemiddelde fijnstofniveau per wijk wordt berekend door 
#de waarden van alle rastercellen die (gedeeltelijk) binnen de wijk vallen, 
#te wegen op basis van het oppervlak van de cellen dat daadwerkelijk binnen 
#de wijk valt. Hierdoor krijg je een nauwkeurige schatting van het gemiddelde 
#fijnstofniveau per wijk, rekening houdend met de geometrie van de wijk.

#Rastercellen en polygonen: 
#De rastercellen in je fijnstofuitstootbestand hebben een bepaalde resolutie 
#(bijvoorbeeld 10x10 meter). Elke wijk in je shapefile bestaat uit een aantal
#van deze rastercellen, en de wijkgrenzen overlappen mogelijk niet perfect 
#met de rastercellen.

#Gewogen gemiddelde: 
#Voor elke wijk wordt gekeken naar alle rastercellen die (gedeeltelijk) binnen 
#die wijk vallen. De waarde van elke rastercel wordt gewogen op basis van de 
#oppervlakte van de cel die binnen de wijk valt. Dus als een rastercel 
#bijvoorbeeld voor 50% in een wijk ligt, dan draagt deze cel voor 50% bij 
#aan het gemiddelde.

#Berekening met exact_extract: 
#De exact_extract functie berekent dit gewogen gemiddelde automatisch. Als je 
#een rastercel hebt die bijvoorbeeld deels in de ene wijk en deels in een andere
#wijk ligt, wordt de bijdrage van die cel aan het gemiddelde verdeeld volgens
#het aandeel van de celoppervlakte dat in elke wijk ligt.




# Download de wijkgrenzen ----
#op https://www.cbs.nl/nl-nl/dossier/nederland-regionaal/geografische-data/wijk-en-buurtkaart-2023
# Sla die bestanden op op de /data locatie van dit R-bestand
# Run script

# Download de fijnstofdata ----
# op https://www.atlasleefomgeving.nl/kaarten?config=3ef897de-127f-471a-959b-93b7597de188&gm-z=3&gm-x=122959.04000000002&gm-y=469031.68&gm-b=1544180834512,true,1;1712051773894,true,0.8&layerFilter=Alle%20kaarten&use=piwiksectorcode
# kan je de kaartlaag downloaden. Je hebt het TIF-bestand dat daaruit voortkomt nodig.

# Laad het shapefile met wijkgrenzen en gemeentegrenzen ----
wijken <- st_read("data/wijken_2023_v1.shp")
gemeenten <- st_read("https://service.pdok.nl/cbs/gebiedsindelingen/2017/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeName=gemeente_gegeneraliseerd&outputFormat=json")

# Laad het raster bestand met fijnstofuitstoot ----
PM25 <- raster("data/rivm_nsl_20240401_gm_PM252022.tif")
PM10<- raster("data/rivm_nsl_20240401_gm_PM102022.tif")
per_wijk_pm10 <- exact_extract(PM10, wijken, 'mean', progress = FALSE)
per_gemeente_pm10 <- exact_extract(PM10, gemeenten, 'mean', progress = FALSE)

wijken$gem_fijnstof_pm10 <- per_wijk_pm10
gemeenten$gem_fijnstof_pm10 <- per_gemeente_pm10 

# Maak tabellen met wijken en gemeentetotaal (alleen Amersfoort) ----
wijken <- wijken %>%
  st_drop_geometry() %>%   # Verwijder de geometrie kolom
  filter(GM_NAAM == "Amersfoort") %>% 
  select(WK_NAAM, gem_fijnstof_pm10, WK_CODE) %>% 
  mutate(wijkcode = substr(WK_CODE, 7, 8), wijknaam = WK_NAAM) %>% 
  select(wijkcode, wijknaam, gem_fijnstof_pm10)

gemeenten <- gemeenten %>% 
  st_drop_geometry() %>%   # Verwijder de geometrie kolom
  filter(statnaam == "Amersfoort") %>% 
  select(statcode, statnaam, gem_fijnstof_pm10) 

# Bestanden opslaan
write.csv(tabel, "output/fijnstof_per_wijk.csv")
write.csv(gemeenten, "output/fijnstof_per_gemeente.csv")

# Voor bronvermelding: let op de read-me van de brondata (zie mapje data)
