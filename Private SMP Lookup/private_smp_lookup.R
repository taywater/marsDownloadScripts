#Install the requisite R packages for the rest of the script.
#install.packages("assertthat")

library(pwdgsi)
library(assertthat)

rm(list = ls())


options(stringsAsFactors=FALSE)

##### Step 1: What Tracking Number(s) (eg FY16-WAKE-4282-01) are you working with?
  # Change the Tracking Number below to tell the database what SMPs to find.
  # Use c("####", "####") to add more than one Tracking Number
  ########################
  tracking_numbers <- "FY17-PASC-4472-01"
    
  ########################

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

  test <- odbc::dbConnect(odbc::odbc(), "mars")
  odbc::dbListTables(test) #If that didn't work, your DSN isn't working.
  odbc::dbDisconnect(test)
  
  mars <- odbc::dbConnect(odbc::odbc(), "mars")

##### Step 2: Look up the SMPs

  privateSMPs <- pwdgsi::marsFetchPrivateSMPRecords(con = mars, tracking_numbers = tracking_numbers)
  print(privateSMPs)


##### Step 3: Close the database.
  odbc::dbDisconnect(mars)
  

  