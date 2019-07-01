  #Install the requisite R packages for the rest of the script.
  # install.packages("assertthat")
  library(assertthat)
  library(pwdgsi)

  rm(list = ls())

  setwd("//pwdoows/oows/Watershed Sciences/GSI Monitoring/07 Databases and Tracking Spreadsheets/13 MARS Analysis Database/Scripts/Downloader/Baro Data Downloader")
  options(stringsAsFactors=FALSE)

  ##### Step 1: What SMP are you working with?
    # Change the SMP ID to tell the database what SMP you're using.
    ########################
    smp_id <- "8-1-1"
    ########################

    # Change the date boundaries to reflect the time period for which you want data
    # Data begins Jan 1 2016
    ### 30 days hath September, April, June and November
    ### All the rest have 31 (Except February)
    ####################################
    start_date <- lubridate::mdy("09-13-2018", tz = "EST")
    end_date <- lubridate::mdy("09-15-2018", tz = "EST")
    ####################################

    # What interval do you want for the final data?
    # Select 1 of "5 mins" or "15 mins"
    # It won't work if you type "Mins" or "minutes" or something like that.
    # So please don't do that.
    #################################
    data_interval <- "5 mins"
    #################################

  ##### Step 1.1: Make a connection to the MARS database
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
    test <- odbc::dbConnect(odbc::odbc(), "mars_testing")
    odbc::dbListTables(test) #If that didn't work, your DSN isn't working.
    odbc::dbDisconnect(test)

    mars <- odbc::dbConnect(odbc::odbc(), "mars_testing")
    smplist <- odbc::dbGetQuery(mars, "SELECT * FROM smpid_facilityid_componentid")
    smplocations <- odbc::dbGetQuery(mars, "SELECT * FROM smp_loc")

    # If this assert_that statement doesn't return TRUE, the datbase doesn't know about your SMP.
    assert_that(smp_id %in% smplist$smp_id, msg = "SMP ID does not exist in MARS database")

    # If this assert_that statement doesn't return TRUE, there isn't a GIS location of your SMP.
    assert_that(smp_id %in% smplocations$smp_id, msg = "SMP ID does not have a lat/long location in MARS")

  ##### Step 2: Find barometric data
    print(paste("Fetching baro data for SMP:", smp_id))
    barodata <- marsFetchBaroData(con = mars,
      target_id = smp_id,
      start_date = start_date,
      end_date = end_date,
      data_interval = data_interval
      )

    #Wrap SMP IDs with single quotes so Excel doesn't parse them as dates
    #barodata$baro_id <- sapply(barodata$baro_id, function(x) paste0("'", x, "'"))

    # Data summary
    for(i in 1){
      print(paste("Baro data for SMP:", smp_id))
      print(paste("Start Date:", dplyr::first(barodata$dtime_est)))
      print(paste("End Date:", dplyr::last(barodata$dtime_est)))
      print(paste("Data Length:", nrow(barodata)))
      print(paste("Number of Holes:", sum(!complete.cases(barodata[1:3]))))
      #print(paste("Data Sources:", paste(unique(barodata$baro_id), collapse = ", ")))
    }

  ##### Step 4: Save the data and close the connection
    odbc::dbDisconnect(mars)
     write.csv(barodata, file = paste0(paste(smp_id, start_date, "to", end_date, sep = "_"), ".csv"), row.names=FALSE)
