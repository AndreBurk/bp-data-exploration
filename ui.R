
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(markdown)

shinyUI(navbarPage("Dashboard",
    tabPanel("Prices",
             sidebarLayout(
                 sidebarPanel(
                     h3("Gas price overview for Europe."),
                     br(),
                     selectInput("currency", "Select output currency:", choices = c("Euro", "USD"), selected = "Euro"),
                     h6(textOutput("fx")),
                     selectInput("unit", "Select output energy unit:", choices = c("MWh", "1000m3"), selected = "MWh"),
                     numericInput("confactor", "Conversion factor (in MWh/1000m3):", min = 5, max = 15, value = 11.1, step = 0.01),
                     p("For thermal 29.3071 kWh/therm is used."),
                     br(),
                     actionButton("updatebutton", "Update!"),
                     p("Click the button to update the table."),
                     p("(Can take a brief moment.)"),
                     br(),
                     h5("Sources:"),
                     h6("The data is taken from PEGAS and CEGH for the prices. FX rates are taken via Quandl."),
                     h6(a("PEGAS/Powernext", href = "http://www.powernext.com")),
                     h6(a("CEGH", href = "http://www.cegh.at")),
                     h6(a("Quandl for FX", href = "https://www.quandl.com/data/CURRFX?keyword=")),
                     width = 3
                 ),
                 mainPanel(
                     htmlOutput("ptable")
                 )
             )
    ),
    tabPanel("BP data plot",
             sidebarLayout(
                 sidebarPanel(
                     h3("Google Motion Chart"),
                     p("(Loading can take a moment.)"),
                     br(),
                     h5("Sources:"),
                     h6("Visualization of the statistical energy workbook from BP."),
                     h6(a("Link to BP", href = "http://www.bp.com/en/global/corporate/about-bp/energy-economics/statistical-review-of-world-energy.html")),
                     h6("The data was downloaded via Quandl."),
                     h6(a("Link to BP database on Quandl", href = "https://www.quandl.com/data/BP?keyword=")),
                     h6("The processed and here used dataset can be found on github called 'bp-country-data.csv' (area summations like 'total world' were removed)."),
                     h6(a("GitHub repository", href = "https://github.com/AndreBurk/bp-data-exploration")),
                     width = 2
                 ),
                 mainPanel(
                     htmlOutput("motionPlot")
                 )
             )
    ),
    tabPanel("World map",
             sidebarLayout(
                 sidebarPanel(
                     h3("Google Geo Map"),
                     br(),
                     selectInput("category", "Select Category from BP dataset:", choices = c("Biofuel Production - Daily Average (Kboed)", "Biofuel Production - Oil Equivalent (Ktoe)", "Carbon Dioxide (CO2) Emmissions (Mt)", "Coal Consumption - Oil Equivalent (Mtoe)", "Coal Production (Mt)", "Coal Production - Oil Equivalent (Mtoe)", "Electricity Generation (TWh)", "Geothermal and Biomass Power Consumption (TWh)", "Geothermal and Biomass Power Consumption - Oil Equivalent (Mtoe)", "Geothermal Power Capacity (MW)", "Hydroelectric Consumption (TWh)", "Hydroelectric Consumption - Oil Equivalent (Mtoe)", "Natural Gas Consumption (Bcm)", "Natural Gas Consumption - Daily Average (Bcf)", "Natural Gas Consumption - Oil Equivalent (Mtoe)", "Natural Gas Production (Bcm)", "Natural Gas Production - Daily Average (Bcf)", "Natural Gas Production - Oil Equivalent (Mtoe)", "Nuclear Power Consumption (TWh)", "Nuclear Power Consumption - Oil Equivalent (Mtoe)", "Oil Consumption (Mt)", "Oil Consumption - Daily Average (Kbd)", "Oil Production (Mt)", "Oil Production - Daily Average (Kbd)", "Oil Refinery Capacity (Kbd)", "Oil Refinery Throughputs (Kbd)", "Primary Energy Consumption - Oil Equivalent (Mtoe)", "Proved Natural Gas Reserves (Tcm)", "Proved Oil Reserves (KMb)", "Solar Power Capacity (MW)", "Solar Power Consumption (TWh)", "Solar Power Consumption - Oil Equivalent (Mtoe)", "Wind Power Capacity (MW)", "Wind Power Consumption (TWh)", "Wind Power Consumption - Oil Equivalent (Mtoe)"), selected = "Natural Gas Consumption (Bcm)"),
                     sliderInput("Year", "Select year:", min = 1965, max = 2013, value = 2013, step = 1, sep = "", animate = TRUE),
                     width = 3
                 ),
                 mainPanel(
                     htmlOutput("world")
                 )
             )
    )
))
