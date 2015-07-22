
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(RCurl)
library(googleVis)
library(Quandl)
library(XML)
library(stringr)
suppressMessages(library(gdata))
library(lubridate)
library(reshape2)

country_data <- tempfile()
download.file("https://raw.githubusercontent.com/AndreBurk/bp-data-exploration/master/bp-country-data.csv", destfile = country_data, method = "curl")
country_data <- read.csv(country_data)

names(country_data) <- c("year", "country", "Biofuel Production - Daily Average (Kboed)", "Biofuel Production - Oil Equivalent (Ktoe)", "Carbon Dioxide (CO2) Emmissions (Mt)", "Coal Consumption - Oil Equivalent (Mtoe)", "Coal Production (Mt)", "Coal Production - Oil Equivalent (Mtoe)", "Electricity Generation (TWh)", "Geothermal and Biomass Power Consumption (TWh)", "Geothermal and Biomass Power Consumption - Oil Equivalent (Mtoe)", "Geothermal Power Capacity (MW)", "Hydroelectric Consumption (TWh)", "Hydroelectric Consumption - Oil Equivalent (Mtoe)", "Natural Gas Consumption (Bcm)", "Natural Gas Consumption - Daily Average (Bcf)", "Natural Gas Consumption - Oil Equivalent (Mtoe)", "Natural Gas Production (Bcm)", "Natural Gas Production - Daily Average (Bcf)", "Natural Gas Production - Oil Equivalent (Mtoe)", "Nuclear Power Consumption (TWh)", "Nuclear Power Consumption - Oil Equivalent (Mtoe)", "Oil Consumption (Mt)", "Oil Consumption - Daily Average (Kbd)", "Oil Production (Mt)", "Oil Production - Daily Average (Kbd)", "Oil Refinery Capacity (Kbd)", "Oil Refinery Throughputs (Kbd)", "Primary Energy Consumption - Oil Equivalent (Mtoe)", "Proved Natural Gas Reserves (Tcm)", "Proved Oil Reserves (KMb)", "Solar Power Capacity (MW)", "Solar Power Consumption (TWh)", "Solar Power Consumption - Oil Equivalent (Mtoe)", "Wind Power Capacity (MW)", "Wind Power Consumption (TWh)", "Wind Power Consumption - Oil Equivalent (Mtoe)")

eurusd <- as.numeric(tail(Quandl("CURRFX/EURUSD/1", type = "zoo", start_date = Sys.Date()-10), 1))
eurgbp <- as.numeric(tail(Quandl("CURRFX/EURGBP/1", type = "zoo", start_date = Sys.Date()-10), 1))

shinyServer(function(input, output, session) {
    
    output$fx <- renderText({
        paste("Current:", round(eurusd, 4), "EUR/USD and", round(eurgbp, 4), "EUR/GBP")
    })
    
    ## Price table for price overview
    prices <- eventReactive(input$updatebutton, {
        ## Powernext/PEGAS
        webpage <- getURL("http://www.powernext.com")
        webpage <- readLines(tc <- textConnection(webpage)); close(tc)
        
        c <- grep("GPL|NCG|NBP|PEG|TRS|TTF|ZEE|ZTP|PSV", webpage)
        c1 <- grep("GPL DA|ZTP Month", webpage)
        c <- c[c >= c1[1] & c <= c1[2]]
        webpage <- webpage[sort(c(c, c + 1))]
        webpage <- htmlTreeParse(webpage, useInternalNodes = TRUE); rm(c); rm(c1)
        webpage <- xpathSApply(webpage, "//body//text()[not(ancestor::script)][not(ancestor::style)][not(ancestor::noscript)]", xmlValue)
        webpage <- gsub("\t", "", webpage)
        webpage <- gsub("\n", "", webpage)
        webpage <- trim(gsub("PEGAS Futures", "", webpage))
        webpage <- matrix(webpage[webpage != ""], ncol = 2, byrow = TRUE)
        webpage <- webpage[-grep(" WE | H | L ", webpage), ]
        webpage <- gsub(",", ".", webpage)
        
        # create the table
        pricetab <- data.frame(code = webpage[, 1], price = as.numeric(webpage[, 2]), market = as.character(sapply(strsplit(webpage[, 1], " "), head, 1)))
        pricetab$code <- as.character(pricetab$code)
        pricetab$market <- as.character(pricetab$market)
        pricetab$Delivery <- sapply(strsplit(pricetab$code, paste0(pricetab$market, " "), fixed = TRUE), tail, 1)
        pricetab$Delivery <- trim(gsub("Nord|Fin", "", pricetab$Delivery))
        
        # rearraging table
        pricetab <- dcast(pricetab, Delivery ~ market, value.var = "price")
        pricetab <- pricetab[c(3, 5, 4, 7, 6, 9, 8, 10, 1, 2), ]
        rownames(pricetab) <- NULL
        pricetab$CEGH <- as.numeric(NA)
        pricetab <- pricetab[, c("Delivery", "CEGH", "GPL", "NBP", "NCG", "PEG", "PSV", "TRS", "TTF", "ZEE", "ZTP")]
        
        # CEGH data
        ## DA
        webpage <- getURL("http://www.cegh.at/day-ahead-contracts")
        webpage <- readLines(tc <- textConnection(webpage)); close(tc)
                
        webpage <- webpage[431]
        webpage <- sapply(strsplit(trim(webpage), " "), head, 1)
        webpage <- ifelse(suppressWarnings(is.na(as.numeric(webpage))), 0, as.numeric(webpage))
        pricetab[1, "CEGH"] <- round(webpage, 2)
        
        ## Futures
        webpage <- getURL("http://www.cegh.at/gas-futures-market")
        webpage <- readLines(tc <- textConnection(webpage)); close(tc)
        # get different rows from CEGH page
        sub <- sapply(strsplit(trim(webpage[c(411, 615, 635, 838, 854, 870, 1029)]), " "), head, 1)
        sub <- ifelse(suppressWarnings(is.na(as.numeric(sub))), 0, as.numeric(sub))
        # second possible rows
        sub1 <- sapply(strsplit(trim(webpage[c(448, 695, 715, 953, 969, 985, 1166)]), " "), head, 1)
        sub1 <- ifelse(suppressWarnings(is.na(as.numeric(sub1))), 0, as.numeric(sub1))
        
        if(all(sub == 0) == TRUE){
            webpage <- sub1
        } else {
            webpage <- sub
        }
                
        pricetab[3:9, "CEGH"] <- round(webpage, 2)
        
        # price transformations
        pricetab[, c("NBP", "ZEE")] <- round(((pricetab[, c("NBP", "ZEE")]/eurgbp)/29.3071)/100*1000, 2)
        
        if(input$currency == "USD"){
            if(input$unit == "1000m3"){
                pricetab[, c("CEGH", "GPL", "NBP", "NCG", "PEG", "PSV", "TRS", "TTF", "ZEE", "ZTP")] <- round(pricetab[, c("CEGH", "GPL", "NBP", "NCG", "PEG", "PSV", "TRS", "TTF", "ZEE", "ZTP")]*input$confactor*eurusd, 2)
            } else {
                pricetab[, c("CEGH", "GPL", "NBP", "NCG", "PEG", "PSV", "TRS", "TTF", "ZEE", "ZTP")] <- round(pricetab[, c("CEGH", "GPL", "NBP", "NCG", "PEG", "PSV", "TRS", "TTF", "ZEE", "ZTP")]*eurusd, 2)
            }
        } else {
            if(input$unit == "1000m3"){
                pricetab[, c("CEGH", "GPL", "NBP", "NCG", "PEG", "PSV", "TRS", "TTF", "ZEE", "ZTP")] <- round(pricetab[, c("CEGH", "GPL", "NBP", "NCG", "PEG", "PSV", "TRS", "TTF", "ZEE", "ZTP")]*input$confactor, 2)
            } else {
                pricetab
            }
        }
                    
        ptab <- gvisTable(pricetab, options = list(width = 750))
        
        # table for market areas with DA prices
        areamap <- data.frame(Market = names(pricetab)[-1], DA_Price = as.numeric(pricetab[1,-1]))
        
        areamap$Country <- "NA"
        areamap$Market <- as.character(areamap$Market)
        
        # reduce market areas to one area per country
        areamap <- areamap[-grep("GPL|TRS|ZTP", areamap$Market), ]
        
        # rename double market areas
        areamap[grep("NCG", areamap$Market), "Market"] <- "NCG/GPL"
        areamap[grep("PEG", areamap$Market), "Market"] <- "PEG/TRS"
        areamap[grep("ZEE", areamap$Market), "Market"] <- "ZEE/ZTP"
        
        # name countries for market areas
        areamap[grep("CEGH", areamap$Market), "Country"] <- "Austria"
        areamap[grep("NBP", areamap$Market), "Country"] <- "United Kingdom"
        areamap[grep("NCG", areamap$Market), "Country"] <- "Germany"
        areamap[grep("PEG", areamap$Market), "Country"] <- "France"
        areamap[grep("PSV", areamap$Market), "Country"] <- "Italy"
        areamap[grep("TTF", areamap$Market), "Country"] <- "Netherlands"
        areamap[grep("ZEE", areamap$Market), "Country"] <- "Belgium"
        rownames(areamap) <- NULL
        
        # mapping for market areas
        areagvis <- gvisGeoChart(data = areamap, locationvar = "Country", colorvar = "DA_Price", hovervar = "Market", options = list(region = "150", width = "750px", height = "470px"))
        
        # plot merging
        gvisMerge(ptab, areagvis, horizontal = FALSE)
    })
    
    output$ptable <- renderGvis({
        progress <- shiny::Progress$new(session, min = 0, max = 1)
        on.exit(progress$close())
        
        progress$inc(amount = 0.1, message = "Calculation in progress", detail = "This may take a moment.")
                                
        prices()
    })
    
    output$motionPlot <- renderGvis({
        progress <- shiny::Progress$new(session, min = 0, max = 1)
        on.exit(progress$close())
        progress$inc(amount = 0.1, message = "Calculation in progress", detail = "This may take a moment.")
        
        gvisMotionChart(country_data, "country", "year", options = list(width = 960, height = 640))
        
    })

    
    ## world map output
    myyear <- reactive({
        input$Year
    })
    
    mycat <- reactive({
        input$category
    })
    
    output$world <- renderGvis({
        plot_data <- country_data[which(country_data$year == myyear()), c("country", mycat())]
        plot_data <- plot_data[!is.na(plot_data[, mycat()]), ]
        
        gvisGeoChart(data = plot_data, locationvar = "country", colorvar = mycat(), options = list(width = "960px", height = "640px"))
        
    })
})
