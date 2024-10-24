library(tidyverse)
library(finch)
library(vegan)
library(ggOceanMaps)
library(sf)
library(ggspatial)
library(sp)
library(geosphere)

shapefilesDir <- "data/raw_data/shapefiles/sharkweb_shapefiles/"
basin_shapefile <- "Havsomr_SVAR_2016_3b_CP1252.shp"
basin_names <- "sea_basin_utf8.txt"

# Read shapefiles and list of basin names
basins <- st_read(file.path(shapefilesDir, basin_shapefile))
basin_names <- read_delim(file.path(shapefilesDir, basin_names), 
                          delim = ";", 
                          col_names = TRUE, 
                          locale = locale(encoding = "UTF-8"))



syke_dwca <- dwca_read("data/raw_data/dwca-syke-zplank-v1.0.zip")

# event_syke <- read_tsv(syke_dwca$files$txt_files[1])
# occurrence_syke <- read_tsv(syke_dwca$files$txt_files[3])
# emof_syke <- read_tsv(syke_dwca$files$txt_files[2])

# event_syke <- read_tsv("data/raw_data/d6a04582-1fd2-4443-82ab-95fbccd3df74/")
occurrence_syke <- read_csv("data/raw_data/d6a04582-1fd2-4443-82ab-95fbccd3df74/Occurrence.csv")
emof_syke <- read_csv("data/raw_data/d6a04582-1fd2-4443-82ab-95fbccd3df74/MeasurementOrFact.csv")

all_syke <- occurrence_syke %>%
  left_join(emof_syke) %>%
  filter(measurementtype == "Abundance of biological entity specified elsewhere per unit volume of the water body")

coords <- all_syke %>%
  select(eventid, eventdate, decimallatitude, decimallongitude) %>% 
  distinct()

syke_diversity <- all_syke %>%
  group_by(eventid) %>%
  summarise(uniqueTaxa = length(unique(scientificname)),
            shannon = diversity(as.numeric(measurementvalue))) %>%
  left_join(coords) %>%
  rename(id = eventid,
         decimalLatitude = decimallatitude,
         decimalLongitude = decimallongitude,
         eventDate = eventdate) %>%
  mutate(origin = "SYKE")

# 
# 
# event_sel_syke <- event_syke %>%
#   select(id, eventID, parentEventID, eventDate, minimumDepthInMeters, maximumDepthInMeters, decimalLatitude, decimalLongitude)
# 
# emof_sel_syke <- emof_syke %>%
#   select(id, occurrenceID, measurementType, measurementValue, measurementUnit)
# 
# occurrence_sel_syke <- occurrence_syke %>%
#   select(id, occurrenceID, measurementType, measurementValue, measurementUnit)
# 
# all_syke <- emof_syke %>%
#   left_join(event_syke) %>%
#   filter(!is.na(decimalLatitude))




zooplankton_dwca <- dwca_read("data/raw_data/dwca-shark-zooplankton-nat-v1.8.zip")

event <- read_tsv(zooplankton_dwca$files$txt_files[1])
occurrence <- read_tsv(zooplankton_dwca$files$txt_files[2])
emof <- read_tsv(zooplankton_dwca$files$txt_files[3])

event_sel <- event %>%
  select(id, eventID, parentEventID, eventDate, verbatimLocality, minimumDepthInMeters, maximumDepthInMeters, decimalLatitude, decimalLongitude)

occurrence_sel <- occurrence %>%
  select(id, occurrenceID, measurementType, measurementValue, measurementUnit)

all <- occurrence_sel %>%
  left_join(event_sel) %>%
  left_join(emof)

abundance <- all %>%
  filter(measurementType == "Abundance") %>%
  group_by(id) %>%
  mutate(sample_sum = sum(as.numeric(measurementValue))) %>%
  ungroup()


### Poland Data https://ipt.vliz.be/eurobis/resource?r=pl_zo_monitoring

pl_dwca <- dwca_read("data/raw_data/dwca-pl_zo_monitoring-v1.0.zip")

occurrence_pl <- read_tsv(pl_dwca$files$txt_files[2])
emof_pl <- read_tsv(pl_dwca$files$txt_files[1])

# occurrence_pl_sel <- occurrence_pl %>%
#   select(id, occurrenceID, measurementType, measurementValue, measurementUnit)

all_pl <- occurrence_pl %>%
  left_join(emof_pl) %>%
  filter(measurementType == "abundance")


coords_pl <- all_pl %>%
  select(eventID, eventDate, decimalLatitude, decimalLongitude) %>%
  distinct()

pl_diversity <- all_pl %>%
  group_by(eventID) %>%
  summarise(uniqueTaxa = length(unique(scientificName)),
            shannon = diversity(as.numeric(measurementValue))) %>%
  left_join(coords_pl) %>%
  rename(id = eventID) %>%
  mutate(origin = "PL")



### Estonian Data https://ipt.vliz.be/eurobis/resource?r=zooplankton_data_estonian_territorial_waters_1993-2016

est_dwca <- dwca_read("data/raw_data/dwca-zooplankton_data_estonian_territorial_waters_1993-2016-v1.0.zip")

event_est <- read_tsv(est_dwca$files$txt_files[1])
occurrence_est <- read_tsv(est_dwca$files$txt_files[3]) %>%
  select(-decimalLatitude, -decimalLongitude, -eventDate)
emof_est <- read_tsv(est_dwca$files$txt_files[2])

# occurrence_pl_sel <- occurrence_pl %>%
#   select(id, occurrenceID, measurementType, measurementValue, measurementUnit)

event_est_sel <- event_est %>%
  select(id, eventID, eventDate, decimalLatitude, decimalLongitude)


all_est <- occurrence_est %>%
  left_join(emof_est) %>%
  left_join(event_est_sel) %>%
  filter(measurementType == "arvukus")


coords_est <- all_est %>%
  select(eventID, eventDate, decimalLatitude, decimalLongitude) %>%
  distinct()

est_diversity <- all_est %>%
  group_by(eventID) %>%
  mutate(measurementValue = as.numeric(measurementValue)) %>%
  filter(!is.na(measurementValue)) %>%
  summarise(uniqueTaxa = length(unique(scientificName)),
            shannon = diversity(as.numeric(measurementValue))) %>%
  left_join(coords_est) %>%
  rename(id = eventID) %>%
  mutate(origin = "EST")



### Danish data https://ipt.vliz.be/eurobis/resource?r=odam_zooplankton_1985

dk_dwca <- dwca_read("data/raw_data/dwca-odam_zooplankton_1985-v1.0.zip")

occurrence_dk <- read_tsv(dk_dwca$files$txt_files[2])
emof_dk <- read_tsv(dk_dwca$files$txt_files[1])

# occurrence_pl_sel <- occurrence_pl %>%
#   select(id, occurrenceID, measurementType, measurementValue, measurementUnit)

all_dk <- occurrence_dk %>%
  left_join(emof_dk) %>%
  filter(measurementType == "WaterAbund_BE007117....l.")


coords_dk <- all_dk %>%
  select(eventID, eventDate, decimalLatitude, decimalLongitude) %>%
  distinct()

dk_diversity <- all_dk %>%
  group_by(eventID) %>%
  summarise(uniqueTaxa = length(unique(scientificName)),
            shannon = diversity(as.numeric(measurementValue))) %>%
  left_join(coords_dk) %>%
  rename(id = eventID) %>%
  mutate(origin = "DK")




# Create basemap
baltic_sea_map <- basemap(
  limits = c(min(abundance$decimalLongitude) - 1, max(abundance$decimalLongitude) + 1, min(abundance$decimalLatitude) - 1, max(abundance$decimalLatitude) + 1),
  land.col = "#eeeac4",
  land.border.col = "black",
  rotate = TRUE,
  bathymetry = FALSE
)

# # Plot points on map
# map <- baltic_sea_map +
#   geom_spatial_point(
#     data = abundance,
#     aes(x = decimalLongitude, y = decimalLatitude, size = sample_sum),
#     pch = 21,
#     # size = 2,
#     fill = "red",
#     colour = "black"
#   ) +
#   scale_size_continuous(range = c(1, 10), name = "Abundance (ind/m3)")


# # Calculate alpha diversity
# data_diversity <- abundance %>%  
#   group_by(id) %>%
#   summarise(uniqueTaxa = length(unique(scientificName)),
#             shannon = diversity(as.numeric(measurementValue))) %>%
#   left_join(event)
# 
# save(data_diversity, file= "data/derived_data/data_diversity.rda")

diversity_all <- data_diversity %>%
  select(id, eventDate, uniqueTaxa, shannon, decimalLatitude, decimalLongitude) %>%
  mutate(origin = "SMHI") %>%
  rbind(syke_diversity) %>%
  rbind(pl_diversity) %>%
  rbind(est_diversity) %>%
  rbind(dk_diversity)

save(diversity_all, file= "data/derived_data/data_diversity_all.rda")

# Calculate mean
mean_diversity <- data_diversity %>%
  group_by(verbatimLocality) %>%
  summarise(shannon = mean(shannon, na.rm = TRUE),
            uniqueTaxa = mean(uniqueTaxa, na.rm = TRUE),
            decimalLongitude = mean(decimalLongitude, na.rm = TRUE),
            decimalLatitude = mean(decimalLatitude, na.rm = TRUE))



proWG = CRS("+proj=longlat +datum=WGS84")

cooridinates = diversity_all %>%
  dplyr::select(decimalLongitude, decimalLatitude) %>%
  distinct()

xy = SpatialPointsDataFrame(
  matrix(c(cooridinates$decimalLongitude,
           cooridinates$decimalLatitude), 
         ncol = 2), 
  data.frame(ID = seq(1:nrow(cooridinates))),
  proj4string = proWG)

mdist = distm(xy)

hc = hclust(as.dist(mdist), method = "complete")

# Define the maximum distance for clustering stations together

d = 20000

xy$clust = cutree(hc, h = d)

cooridinates = cooridinates %>%
  mutate("stationCluster" = xy$clust)

diversity_all = diversity_all %>%
  left_join(cooridinates, by = c("decimalLongitude", "decimalLatitude"))










# Calculate mean
mean_diversity <- diversity_all %>%
  mutate(position = paste(decimalLatitude, decimalLongitude)) %>%
  group_by(stationCluster) %>%
  summarise(shannon = mean(shannon, na.rm = TRUE),
            uniqueTaxa = mean(uniqueTaxa, na.rm = TRUE),
            decimalLongitude = mean(decimalLongitude, na.rm = TRUE),
            decimalLatitude = mean(decimalLatitude, na.rm = TRUE),
            origin = unique(origin))


# Set CRS of basin layer
basins <- st_set_crs(basins, 3006)

# Aggregate basins by the 17 sea basins
all_basins <- basins %>%
  group_by(BASIN_NR) %>%
  summarise(geometry = sf::st_union(geometry)) %>%
  ungroup()

# Change CRS
all_basins <- st_transform(all_basins, 4326)

# Add geometry information to data
data_diversity_coordinates <- diversity_all %>%
  mutate(lon = decimalLongitude,
         lat = decimalLatitude)

# Gather all unique positions
cords = data_diversity_coordinates %>%
  distinct(decimalLongitude, decimalLatitude, lat, lon)

# Convert data points to sf
points_sf <- st_as_sf(cords, coords = c("lon", "lat"), crs = st_crs(all_basins))

# Assign basin number by position
data_diversity_st <- st_join(points_sf, all_basins)

# Add sea basin name and create translate list
data_diversity_st <- data_diversity_st %>%
  as.data.frame() %>%
  left_join(basin_names) %>%
  select(-geometry, -BASIN_NR)

# Join with basin names
diversity_all <- diversity_all %>%
  left_join(data_diversity_st)

# Plot points on map
map <- baltic_sea_map +
  geom_spatial_point(
    data = mean_diversity,
    aes(x = decimalLongitude, y = decimalLatitude, size = uniqueTaxa),
    pch = 21,
    # size = 2,
    fill = "red",
    colour = "black"
  ) +
  scale_size_continuous(range = c(1, 10), name = "Species richness") +
  ggtitle("Average Zooplankton richness 1965-2023")


# Plot time series of abundance at each location
time_series <- ggplot(diversity_all, aes(x = eventDate, y = shannon)) +
  geom_point(aes(color = factor(location_sea_basin_en))) +
  scale_color_discrete() +
  labs(x = "Date", y = "Shannon index", title = "Zooplankton diversity", color = "Sea basin") +
  theme_minimal()

# Save map
ggsave(
  plot = time_series,
  path = "product/plots/",
  filename = "times_series_all.png",
  device = "png",
  dpi = 300,
  width = 7,
  height = 4
)

# Save map
ggsave(
  plot = map,
  path = "product/maps/",
  filename = "map_all.png",
  device = "png",
  dpi = 300,
  width = 7,
  height = 7
)


# Create basemap
baltic_sea_map <- basemap(
  limits = c(min(subset_all$decimalLongitude) - 1, max(subset_all$decimalLongitude) + 1, min(subset_all$decimalLatitude) - 1, max(subset_all$decimalLatitude) + 1),
  land.col = "#eeeac4",
  land.border.col = "black",
  rotate = TRUE,
  bathymetry = FALSE
)

# Plot points on map
map <- baltic_sea_map +
  geom_spatial_point(
    data = subset_all,
    aes(x = decimalLongitude, y = decimalLatitude, size = shannon),
    pch = 21,
    # size = 2,
    fill = "red",
    colour = "black"
  ) +
  scale_size_continuous(range = c(1, 10), name = "Shannon index") +
  ggtitle("Average Zooplankton shannon 2010")

# Save plot
ggsave("product/maps/sample_map.png",
       map,
       device = "png",
       bg = "white")