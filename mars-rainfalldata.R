#Install the requisite R packages for the rest of the script.
#install.packages(c("tidyverse", "lubridate", "magrittr", "assertthat", "padr", "RODBC", "zoo"))

#dplyr stuff
library(tidyverse)
library(lubridate)
library(magrittr)
library(assertthat)
library(padr)
library(pwdgsi)

#Other Stuff
library(odbc)
rm(list = ls())

setwd("//pwdoows/oows/Watershed Sciences/GSI Monitoring/07 Databases and Tracking Spreadsheets/13 MARS Analysis Database/Scripts/Downloader/Rainfall Data Downloader")
options(stringsAsFactors=FALSE)


##### Step 1: What SMP are you working with?
  # Change the SMP ID to tell the database what SMP you're using.
  ########################
  smp_id <- "394-3-1"
  ########################

##### Step 2: What time period are you searching for?
  # Change the date boundaries to show the time period for which you want data
  ### 30 days hath September, April, June and November
  ### All the rest have 31 (Except February)
  ####################################
  start_date <- mdy("04-01-2019")
  end_date <- mdy("05-01-2019")
  daylightsavings <- FALSE #Correct for Daylight Savings Time?
                           #When doing QAQC, this should be FALSE
  ####################################

##### Step 3: Make a connection to the MARS database
  #To read from the MARS database, first set up an ODBC connection to the MARS database
  #In order to do that, you need a PostgreSQL driver
  #You can get that here: https://ftp.postgresql.org/pub/odbc/versions/msi/psqlodbc_09_06_0500.zip
  #Install that file (and reboot if necessary)

  #Then, open the start menu and search for ODBC. You'll want something that looks like "Set up ODBC data sources"
  #Create a new "User DSN" using the PostgreSQL Unicode driver
  #Then, fill the setup screen out in the following way

  # Data Source: mars
  # Description: MARS database
  # Database: mars
  # SSL Mode: Disable
  # Port: 5432
  # Server: 28-ARATHEFFE2.water.gov
  # username: mars_readonly
  # password: ihatepostgrespermissions

  #Then click "Test" to see if the connection works

  #The end result should look like this: "//pwdoows/oows/Watershed Sciences/GSI Monitoring/08 Memos/12 MARS database/Successful Connection.png"
  test <- dbConnect(odbc::odbc(), "mars_testing")
  dbListTables(test) #If that didn't work, your DSN isn't working.
  dbDisconnect(test)

  mars <- dbConnect(odbc::odbc(), "mars_testing")
  smplist <- dbGetQuery(mars, "SELECT * FROM smpid_facilityid_componentid")
  smplocations <- dbGetQuery(mars, "SELECT * FROM smp_loc")

  # If this assert_that statement doesn't return TRUE, the datbase doesn't know about your SMP.
  assert_that(smp_id %in% smplist$smp_id, msg = "SMP ID does not exist in MARS database")

  # If this assert_that statement doesn't return TRUE, there isn't a GIS location of your SMP.
  assert_that(smp_id %in% smplocations$smp_id, msg = "SMP ID does not have a lat/long location in MARS")

##### Step 4: Find rainfall data
  for(i in 1){
    print(paste("Fetching rainfall data for SMP:", smp_id))
    rainfalldata <- marsFetchRainGageData(con = mars,
      target_id = smp_id,
      start_date = start_date,
      end_date = end_date,
      daylightsavings = daylightsavings)

    if(!exists("rainfalldata")){
      stop("No rainfall data was found.")
    }

    # Data summary
    print(paste("Rainfall data for SMP:", smp_id))
    print(paste("Start Date:", first(rainfalldata$dtime_est)))
    print(paste("End Date:", last(rainfalldata$dtime_est)))
    print(paste("Number of events:", length(unique(rainfalldata$event_id[!is.na(rainfalldata$event_id)]))))
    print(paste("Data Length:", nrow(rainfalldata)))

    write.csv(rainfalldata, file = paste0("rainfalldata_", paste(smp_id, start_date, "to", end_date, sep = "_"), ".csv"), row.names=FALSE)
  }

##### Step 5: Save the data and close the connection
  dbDisconnect(mars)

