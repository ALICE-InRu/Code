library(DBI)
library(RMySQL)

source('psw.R') # this is a way to avoid committing your password.
#You can have an r file (added to .gitignore) with the line
#psw <- "mypassword", which you can call later from the code.

m<-dbDriver("MySQL");
conALICE<-dbConnect(m,user='hei2',password=psw["ALICE"],host='tgax89.rhi.hi.is',dbname='ALICE');
conCHESHIRE<-dbConnect(m,user='hei2',password=psw["CHESHIRE"],host='tgax89.rhi.hi.is',dbname='CHESHIRE');

## list the tables in the database
dbListTables(conCHESHIRE)
dbListTables(conALICE)

# dbDisconnect(conn) #always disconnect at the end.
