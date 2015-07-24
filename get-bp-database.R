
# Short overview of how to get the BP database via Quandl and processing it for gvisMotionChart

library(Quandl)
## Quandl.auth()
library(RCurl)
library(lubridate)
library(doBy)
library(dplyr)
library(reshape2)

## loading csv file from Quandl for all available BP data on Quandl
## (the csv file was split by Quandl into 8 parts)
for(i in 1:8){
    temp <- tempfile()
    download.file(url = paste0("https://www.quandl.com/api/v2/datasets.csv?query=*&source_code=BP&per_page=300&page=", i),
                  destfile = temp, method = "curl")
    sub1 <- read.csv(temp, header = F)
    
    if(exists("sub1")){
        sub <- rbind(sub, sub1)
    } else {
        sub <- sub1
    }
}

## rename columns according to Quandl documentation
names(sub) <- c("Code", "Name", "Start_Date", "End_Date", "Frequency", "Last_Updated")

## separate price data from country specific data
## (defined as no country given in Name column)
price_data <- sub[grep("Price|Margin", sub$Name), ]
rownames(price_data) <- NULL

## country specific data
sub <- sub[-grep("Price|Margin", sub$Name), ]
sub[grep("Price|Margin", sub$Name), ]
rownames(sub) <- NULL

## save accessible BP data/codes overview
write.csv(sub, file = "bp-data.csv", row.names = FALSE)

## save price data codes
write.csv(price_data, file = "bp-price-data.csv", row.names = FALSE)


# "in case" loading BP code table
dat <- read.csv("bp-data.csv")

## download data for codes from Quandl
bp_data <- Quandl(as.character(dat$Code), type = "zoo", start_date = "1965-12-31", collapse = "annual")
names(bp_data) <- as.character(dat$Name)

## processing data for later visualization
country_data <- data.frame(description = rep(names(bp_data), each = nrow(bp_data)), year = rep(as.numeric(time(bp_data))), 
                           values = round(rep(bp_data), 2))
country_data$country <- as.character(sapply(strsplit(as.character(country_data$description), " - "), tail, 1))
country_data$description <- as.character(country_data$description)

country_data$category <- as.character(strsplit(country_data$description, paste0(" - ", country_data$country), fixed = TRUE))

## renaming countries for mapping and standardization
country_data$country <- gsub("Republic of Ireland", "Ireland", country_data$country)
country_data$country <- gsub("Russian Federation", "Russia", country_data$country)
country_data$country <- gsub("Russia (Kamchatka)", "Russia", country_data$country, fixed = TRUE)
country_data$country <- gsub("USA", "United States", country_data$country)
country_data$country <- gsub("Portugal (The Azores)", "Portugal", country_data$country, fixed = TRUE)
country_data$country <- gsub("France (Guadeloupe)", "France", country_data$country, fixed = TRUE)
country_data$country <- gsub("Rep. of Congo (Brazzaville)", "Republic of the Congo", country_data$country, fixed = TRUE)

## rearrange data - column for each variable
country_data <- dcast(country_data, year + country ~ category, value.var = "values")
country_data <- orderBy(~country, country_data)
rownames(country_data) <- NULL

## create country data table without "Total" values
total_rows <- grep("Total|Cent.|Other|Middle|Europe", country_data$country)
country_with_total <- country_data

## save country table with total values
write.csv(country_with_total, file = "bp-total-country-data.csv", row.names = FALSE)

# countries w/o total for later usage in app
country_data <- country_data[-c(1:49, total_rows), ]
rownames(country_data) <- NULL

## save data table
write.csv(country_data, file = "bp-country-data.csv", row.names = FALSE)
