
# README ----

# FOR SRBP: there are six birding points at each site, two birding points along
# each of the three transects, yielding, for example, Tonto_mid_B1, Tonto_mid_B2
# (recall that there are three herp plots along each transect). To this point, a
# single birder (formerly Melanie), birded at all six points four times per
# year. The other two birders, birded at a single core site during the two
# regular birding seasons.

# SPATIAL DATA

# reml slots ----
getSlots("dataset")
  getSlots("distribution")
  getSlots("keywordSet")
    getSlots("keyword")
getSlots("dataTable")
getSlots("physical")
  getSlots("dataFormat")
    getSlots("textFormat")
  getSlots("size")
  getSlots("distribution")
    getSlots("online")
      getSlots("url")
getSlots("additionalInfo")
  getSlots("section")
  getSlots("para")
getSlots("metadataProvider")
  getSlots("individualName")
  getSlots("userId")
getSlots("creator")
  getSlots("individualName")
  getSlots("userId")

# libraries ----
library("EML")
library('RPostgreSQL')
library('RMySQL')
library('tidyverse')
library("tools")
library("readr")
library("readxl")
library("stringr")

# functions and working dir ----
source('~/Dropbox (ASU)/localRepos/dataPublishing/writeAttributesFn.R')
source('~/Dropbox (ASU)/localRepos/dataPublishing/createKMLFn.R')
source('~/Dropbox (ASU)/localRepos/dataPublishing/createdataTableFn.R')
source('~/Dropbox (ASU)/localRepos/dataPublishing/createDataTableFromFileFn.R')
source('~/Dropbox (ASU)/localRepos/dataPublishing/address_publisher_contact_language_rights.R')
source('~/Dropbox (ASU)/localRepos/dataPublishing/createOtherEntityFn.R')
setwd("~/db_asu/tempeTownLake/data_ready_to_process")

# DB connections ----
con <- dbConnect(MySQL(),
                 user='srearl',
                 password=.rs.askForPassword("Enter password:"),
                 dbname='lter34birds',
                 host='stegosaurus.gios.asu.edu')

prod <- dbConnect(MySQL(),
                 user='srearl',
                 password=.rs.askForPassword("Enter password:"),
                 dbname='gios2_production',
                 host='mysql.prod.aws.gios.asu.edu')

# pg <- dbConnect(dbDriver("PostgreSQL"),
#                 user="srearl",
#                 dbname="working",
#                 host="localhost",
#                 password=.rs.askForPassword("Enter password:"))

pg <- dbConnect(dbDriver("PostgreSQL"),
                user="srearl",
                dbname="caplter",
                host="stegosaurus.gios.asu.edu",
                password=.rs.askForPassword("Enter password:"))

# dataset details to set first ----
projectid <- 641
packageIdent <- 'knb-lter-cap.641.1'
pubDate <- '2016-12-20'

# data processing ----

# SRBP BIRDS

# 2016-12-02. The meaning of 'flying' in the birds table is unclear. There are
# 1962 records where flying = 1. All of these except for two records have
# distance = FT. However, not all records where distance = FT have a distance =
# 1 (any any value for that matter). Adding confusion, in her metadata, Corinna
# has listed that flying = NULL is true, but then what would be the meaning of
# flying = 0, and that would mean that most birds were flying. I am not certain,
# but my impression is that flying was a precursor to FT. A "flying" option is
# not on the current datasheet, nor on an earlier one revised in 2004. I am
# going to omit flying from the publication of these data as I think it is more
# confusing than helpful (and I cannot explain its meaning).

# note that this select statement does not include wind speed, wind dir, air
# temp, or cloud cover as those variables have not been collected for a long
# time and are not relevant to the more recent SRBP observations

srbp_birds <- dbGetQuery(con, "
SELECT
  sites.site_code,
  surveys.survey_date,
  surveys.time_start,
  surveys.time_end,
  surveys.observer,
  surveys.notes AS survey_notes,
  surveys.human_activity_notes,
  surveys.wind,
  surveys.precipitation,
  surveys.disturbances,
  surveys.sight_obstruct,
  surveys.noise_level,
  surveys.site_condition,
  surveys.non_bird_species,
  bird_taxons.code,
  bird_taxons.common_name,
  birds.distance,
  birds.bird_count,
  birds.notes AS observation_notes,
  birds.seen,
  birds.heard,
  birds.direction,
  birds.QCcomment
FROM lter34birds.surveys
JOIN lter34birds.sites ON (surveys.site_id = sites.site_id)
JOIN lter34birds.birds ON (surveys.survey_id = birds.survey_id)
JOIN lter34birds.bird_taxons ON (birds.bird_taxon_id = bird_taxons.id)
WHERE 
  sites.sample LIKE 'SRBP'
ORDER BY survey_date
LIMIT 500000;")

srbp_birds[srbp_birds == ''] <- NA # lots of missing values, convert to NA

# pulling this code out separately owing to its verbosity for a singular 
# purpose: getting the intials of the observers and presenting those instead of
# the full name
srbp_birds <- srbp_birds %>% 
  mutate(observer = toupper(observer)) %>% 
  separate(observer, c("name1", "name2"), " ", remove = T) %>% 
  mutate(init1 = str_extract(name1, "\\b\\w")) %>% 
  mutate(init2 = str_extract(name2, "\\b\\w")) %>% 
  unite(observer_initials, init1, init2, sep = "", remove = T) 

srbp_birds <- srbp_birds %>% 
  mutate(reach = str_extract(site_code, "^[^_]+")) %>% 
  mutate(reach = as.factor(reach)) %>% 
  mutate(survey_date = as.Date(survey_date)) %>% 
  mutate(wind = as.factor(wind)) %>% 
  mutate(precipitation = as.factor(precipitation)) %>% 
  mutate(disturbances = as.factor(disturbances)) %>% 
  mutate(noise_level = as.factor(noise_level)) %>% 
  mutate(distance = as.factor(distance)) %>% 
  mutate(seen = as.factor(seen)) %>% 
  mutate(heard = as.factor(heard)) %>% 
  mutate(direction = as.factor(direction)) %>% 
  select(site_code, reach, survey_date:time_end, observer_initials, survey_notes:QCcomment)
  
writeAttributes(srbp_birds) # write data frame attributes to a csv in current dir to edit metadata
srbp_birds_desc <- "bird survey sampling details (site, reach, date, time, observer, site conditions, and notes) and birds surveyed (type, number, distance from observer, behavior)"
  
reach <- c(Tonto = "Salt River, Tonto National Forest, near Usery Road",
           Priest = "Salt River flood channel, east of Priest Drive and west of Tempe Town Lake dam",
           Price = "Salt River, by Price Drain, northeast of the loop 101 and loop 202 intersection",
           Rio = "Salt River at Rio Salado; Central Ave, north of Broadway Rd",
           Ave35 = "Salt River at 35th Ave north of Broadway Rd",
           Ave67 = "Salt River at 67th Ave north of Southern Ave",
           BM = "Baseline and Meridian Wildlife Area; Salt River at 115th Ave northeast of Phoenix International Raceway")
wind <- c(none = "no perecptible wind",
          light = "light wind",
          gusts = "wind gusts")
precipitation <- c(none = "no precipitation",
                   light_rain = "light rain")
disturbances <- c(`0` = "no perceptible disturbance to observer or in the vicinity during the survey",
                  `1` = "disturbance occurred during the survey")
noise_level <- c(none = "no noise during survey",
                 low = "low level noise during the survey",
                 high = "high level of noise during the survey")
distance <- c(`0-5` = "bird observed within zero to five meters of observer",
              `5-10` = "bird observed five to ten meters from observer",
              `10-20` = "bird observed ten to twenty meters from observer",
              `20-40` = "bird observed twenty to forty meters from observer",
              `>40` = "bird observed forty or more meters from observer",
              FT = "bird is seen flying through the count area below the tallest structure or vegetation, and not observed taking off or landing")
seen <- c(`0` = "bird not identified by sight",
          `1` = "bird identified by sight")
heard <- c(`0` = "bird not identified by sound",
           `1` = "bird identified by sound")
direction <- c(NW = "north west",
               S = "south",
               N = "north",
               NE = "north east",
               SE = "south east",
               W = "west",
               SW = "south west",
               E = "east")

listOfFactors <- sapply(srbp_birds, is.factor)
trueList <- which(listOfFactors)

srbp_birds_factors <- data.frame()
for(i in 1:length(trueList)) {
factor_elements <- get(names(trueList)[i])
temp_frame <- rbind(
  data.frame(
    attributeName = names(trueList)[i],
    code = names(factor_elements),
    definition = unname(factor_elements)
  ))
srbp_birds_factors <- rbind(srbp_birds_factors, temp_frame)
}

srbp_birds_DT <- createDTFF(dfname = srbp_birds,
                            factors = srbp_birds_factors,
                            description = srbp_birds_desc)

# SRBP_REACH_CHARACTERISTICS

# not enough detail concerning the SRBP sites in the lter34.sites table to 
# warrant pulling that information. However, SRBP reach characteristics are
# relevant so we will publish those details

srbp_reach_characteristics <- dbGetQuery(con, "
SELECT 
  s.site_code
FROM lter34birds.sites s
WHERE 
  s.sample LIKE 'SRBP'
ORDER BY site_code;") %>% 
  mutate(reach = str_extract(site_code, "^[^_]+")) %>% 
  select(site_code, reach)

herps_reach_chars <- dbGetQuery(pg,"
SELECT 
  reach,
  urbanized, 
  restored, 
  water
FROM herpetofauna.river_reaches;")

srbp_reach_characteristics <- inner_join(srbp_reach_characteristics, herps_reach_chars, by = c("reach")) %>% 
  mutate(reach = as.factor(reach)) %>% 
  mutate(urbanized = as.factor(urbanized)) %>% 
  mutate(restored = as.factor(restored)) %>% 
  mutate(water = as.factor(water)) 

reach <- c(Tonto = "Salt River, Tonto National Forest, near Usery Road",
           Priest = "Salt River flood channel, east of Priest Drive and west of Tempe Town Lake dam",
           Price = "Salt River, by Price Drain, northeast of the loop 101 and loop 202 intersection",
           Rio = "Salt River at Rio Salado; Central Ave, north of Broadway Rd",
           Ave35 = "Salt River at 35th Ave north of Broadway Rd",
           Ave67 = "Salt River at 67th Ave north of Southern Ave",
           BM = "Baseline and Meridian Wildlife Area; Salt River at 115th Ave northeast of Phoenix International Raceway")
urbanized <- c(urban = "in urban area",
               NonUrban = "outside urban area")
restored <- c(Restored = "site received active restoration",
              NotRestored = "site has not been restored")
water <- c(Ephemeral = "water in channel intermittently",
           Perennial = "water in channel continuously")

writeAttributes(srbp_reach_characteristics) # write data frame attributes to a csv in current dir to edit metadata
srbp_reach_characteristics_desc <- "Salt River reach location of each sampling site, and general characteristics of that portion of the river where sampling is conducted"

listOfFactors <- sapply(srbp_reach_characteristics, is.factor)
trueList <- which(listOfFactors)

srbp_reach_characteristics_factors <- data.frame()
for(i in 1:length(trueList)) {
factor_elements <- get(names(trueList)[i])
temp_frame <- rbind(
  data.frame(
    attributeName = names(trueList)[i],
    code = names(factor_elements),
    definition = unname(factor_elements)
  ))
srbp_reach_characteristics_factors <- rbind(srbp_reach_characteristics_factors, temp_frame)
}

srbp_reach_characteristics_DT <- createDTFF(dfname = srbp_reach_characteristics,
                            factors = srbp_reach_characteristics_factors,
                            description = srbp_reach_characteristics_desc)
  
# spatial data ----

# Get the bird survey locations. Here we are extracting these data from the 
# database as opposed to using an existing shapefile as I am presenting only the
# most up-to-date location information (as opposed to the locations and their 
# changes through time). Double-check the query, it worked with the small number
# of SRBP sites with updated locations at the time these were pulled but not sure
# its accuracy when the data are more complicated (e.g., a given location having
# moved multiple times) and note that I am using only year to reflect the most 
# recent location, if a site moved twice in a year, month would have to be 
# considered as well. Also note that I had to include blh.end_date_year in the
# query to be able to include it in the HAVING clause.

# as with the herp plots, I am struggling as to whether it is appropriate to
# even make the exact points public information from a disturbance standpoint,
# but also a too-much-knowledge about the organisms standpoint. Finally, now
# that we are tracking the movement of plots through time, that would have to be
# encapsulated in this publication so as not to confuse a researcher thinking
# that all data necessarily come from the same location. Taken together, I think
# the better approach is to make a polygon that encapsulates all points (curent
# and historical) at each reach. This provides a user with a reasonable 
# understanding of the location, but obscures (slightly, anyway) the exact 
# position details.

# see core birds for the query if you want only the current sites

srbp_bird_locations <- dbGetQuery(con, "
SELECT 
  s.site_code,
  blh.lat,
  blh.`long`
FROM lter34birds.birds_location_histories blh
JOIN lter34birds.sites s ON (s.site_id = blh.site_id)
WHERE 
  s.sample LIKE 'SRBP'
ORDER BY site_code;") %>% 
  mutate(reach = str_extract(site_code, "^[^_]+")) %>% 
  select(reach, lat, long)

# convert tabular data to kml
library("sp")
library("rgdal")
coordinates(srbp_bird_locations) <- c("long", "lat")
proj4string(srbp_bird_locations) <- CRS("+init=epsg:4326")
# srbp_bird_locations <- spTransform(srbp_bird_locations, CRS("+proj=longlat +datum=WGS84")) 
# spTransform not required here as already in WGS 84
writeOGR(srbp_bird_locations, "srbp_bird_locations.kml", layer = "srbp_bird_locations", driver = "KML")

# in QGIS
# add the kml file > convex hull (field = reach) > convert to kml (be sure to name fields)

kml_desc <- "bird survey locations at select locations along the Salt River in the greater Phoenix metropolitan area; polygons reflect the combined area of all bird survey locations (current and historic) at each river reach"
srbp_bird_locations <- createKML(kmlobject = 'srbp_bird_locations.kml',
                                 description = kml_desc)


# title and abstract ----
title <- 'Point-count bird censusing: long-term monitoring of bird abundance and diversity along the Salt River in the greater Phoenix metropolitan area, ongoing since 2013'

abstract <- "Waterways are often the focus of restoration efforts in urban areas. In arid regions, passive discharge of urban water sources may stimulate the recovery or growth of wetland and riparian features in dewatered or ephemeral aquatic systems. In the greater Phoenix metropolitan area (GPMA), sections of the Salt and Gila Rivers have been the targets of active restoration through seeding, planting, and irrigation. At the same time, revegetation has occurred in some sections of the rivers in response to runoff from urban water sources (e.g., storm drains). This dataset catalogs the results of bird surveys conducted at several locations along the Salt River in and around the GPMA beginning in March 2013. Monitoring locations focus on reaches of the river with different characteristics, including: (1) urbanized with perennial water and actively restored (n=2 reaches), (2) urbanized with perennial water and passively restored (n=2 reaches), (3) urbanized with ephemeral water but not restored (n=2 reaches), and (4) non-urban reference areas with perennial water (n=1 reach). This program expands on bird monitoring that the CAP LTER conducts at other locations in and around the GPMA, and complements herpetological surveys that are performed at these locations along the Salt River where the bird surveys are performed. This is a long-term monitoring effort of the CAP LTER with on-going data collection." 


# people ----

# Paige

paige <- dbGetQuery(prod, "
SELECT
	people.first_name,
	people.last_name,
	people.email,
	people_address.institution,
	people_address.department
FROM gios2_production.people
JOIN gios2_production.people_address ON (people.person_id = people_address.person_id)
WHERE 
  people.last_name LIKE 'warren' AND
  people.first_name LIKE 'paige';")

paige_name <- new('individualName',
                  givenName = paige$first_name,
                  surName = paige$last_name)

paigeWarren <- new('creator',
                   individualName = paige_name,
                   organizationName = paige$institution,
                   electronicMailAddress = paige$email)

# Dan

dan <- dbGetQuery(prod, "
SELECT
	people.first_name,
	people.last_name,
	people.email,
	people_address.institution,
	people_address.department
FROM gios2_production.people
JOIN gios2_production.people_address ON (people.person_id = people_address.person_id)
WHERE 
  people.last_name LIKE 'childers' AND
  people.first_name LIKE 'dan'
;")

dan_name <- new('individualName',
                givenName = dan$first_name,
                surName = dan$last_name)

danChilders <- new('creator',
                   individualName = dan_name,
                   organizationName = dan$institution,
                   electronicMailAddress = dan$email)

# Heather

heather <- dbGetQuery(prod, "
SELECT
	people.first_name,
	people.last_name,
	people.email,
	people_address.institution,
	people_address.department
FROM gios2_production.people
JOIN gios2_production.people_address ON (people.person_id = people_address.person_id)
WHERE 
  people.last_name LIKE 'bateman'
;")

heather_name <- new('individualName',
                    givenName = heather$first_name,
                    surName = heather$last_name)

heatherBateman <- new('creator',
                      individualName = heather_name,
                      organizationName = heather$institution,
                      electronicMailAddress = heather$email)

# Stevan

stevan <- dbGetQuery(prod, "
SELECT
	people.first_name,
	people.last_name,
	people.email,
	people_address.institution,
	people_address.department
FROM gios2_production.people
JOIN gios2_production.people_address ON (people.person_id = people_address.person_id)
WHERE people.last_name LIKE 'earl'
;")

stevan_name <- new('individualName',
                   givenName = stevan$first_name,
                   surName = stevan$last_name)

stevan_orcid <- new('userId',
                    'http://orcid.org/0000-0002-4465-452X',
                    directory = 'orcid.org')

stevanEarl <- new('metadataProvider',
                   individualName = stevan_name,
                   organizationName = stevan$institution,
                   electronicMailAddress = stevan$email,
                   userId = stevan_orcid)


creators <- c(as(heatherBateman, 'creator'),
              as(danChilders, 'creator'),
              as(paigeWarren, 'creator'))

metadataProvider <-c(as(stevanEarl, 'metadataProvider'))

# keywords ----
keywordSet <-
  c(new("keywordSet",
        keywordThesaurus = "LTER controlled vocabulary",
        keyword =  c("urban",
                     "birds",
                     "species abundance",
                     "species composition",
                     "communities",
                     "community composition")),
    new("keywordSet",
        keywordThesaurus = "LTER core areas and CAP LTER IRTs",
        keyword =  c("disturbance patterns",
                     "population studies",
                     "adapting to city life")),
    new("keywordSet",
        keywordThesaurus = "Creator Defined Keyword Set",
        keyword =  c("aves",
                     "avifauna",
                     "Salt River")),
    new("keywordSet",
        keywordThesaurus = "CAPLTER Keyword Set List",
        keyword =  c("cap lter",
                     "cap",
                     "caplter",
                     "central arizona phoenix long term ecological research",
                     "arizona",
                     "az",
                     "arid land"))
    )


# methods and coverages ---- 

# here referencing lterBirds_46_methods.md, but easier to pull the alreaay
# nicely formatted methods from earlier versions, or from core or pass birds
methods <- set_methods("lterBirds_46_methods.md")

begindate <- as.character(min(srbp_birds$survey_date))
enddate <- as.character(max(srbp_birds$survey_date))
geographicDescription <- "CAP LTER study area"
coverage <- set_coverage(begin = begindate,
                         end = enddate,
                         # sci_names = c("Salix spp",
                         #               "Ambrosia deltoidea"),
                         geographicDescription = geographicDescription,
                         west = -112.305, east = -111.609,
                         north = +33.56, south = +33.3825)

# construct the dataset ----

# address, publisher, contact, and rights come from a sourced file

# XML DISTRUBUTION
  xml_url <- new("online",
                 onlineDescription = "CAPLTER Metadata URL",
                 url = paste0("https://sustainability.asu.edu/caplter/data/data-catalog/view/", packageIdent, "/xml/"))
metadata_dist <- new("distribution",
                 online = xml_url)

# DATASET
dataset <- new("dataset",
               title = title,
               creator = creators,
               pubDate = pubDate,
               metadataProvider = metadataProvider,
               intellectualRights = rights,
               abstract = abstract,
               keywordSet = keywordSet,
               coverage = coverage,
               contact = contact,
               methods = methods,
               distribution = metadata_dist,
               dataTable = c(srbp_birds_DT,
                             srbp_reach_characteristics_DT),
               otherEntity = c(srbp_bird_locations))

# construct the eml ----

# ACCESS
allow_cap <- new("allow",
                 principal = "uid=CAP,o=LTER,dc=ecoinformatics,dc=org",
                 permission = "all")
allow_public <- new("allow",
                    principal = "public",
                    permission = "read")
lter_access <- new("access",
                   authSystem = "knb",
                   order = "allowFirst",
                   scope = "document",
                   allow = c(allow_cap,
                             allow_public))

# CUSTOM UNITS
# standardUnits <- get_unitList()
# unique(standardUnits$unitTypes$id) # unique unit types

# custom_units <- rbind(
#   data.frame(id = "microsiemenPerCentimeter",
#              unitType = "conductance",
#              parentSI = "siemen",
#              multiplierToSI = 0.000001,
#              description = "electric conductance of lake water in the units of microsiemenPerCentimeter"),
# data.frame(id = "nephelometricTurbidityUnit",
#            unitType = "unknown",
#            parentSI = "unknown",
#            multiplierToSI = 1,
#            description = "(NTU) ratio of the amount of light transmitted straight through a water sample with the amount scattered at an angle of 90 degrees to one side"))
# unitList <- set_unitList(custom_units)

eml <- new("eml",
           packageId = packageIdent,
           scope = "system",
           system = "knb",
           access = lter_access,
           dataset = dataset)

# write the xml to file ----
write_eml(eml, "knb-lter-cap.641.1.xml")
