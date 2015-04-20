# Shiny Server
Shiny Server is run here: http://tgax89.rhi.hi.is:3838/alice/
	
## Config
Update default config:

    sudo cp shiny-server.conf /etc/shiny-server/shiny-server.conf

## Commands
Start server

    sudo start shiny-server

Stop server

    sudo stop shiny-server

Restart server 

    sudo restart shiny-server

Reload 

    sudo reload shiny-server

Check status

    status shiny-server

## Installing packages
Shiny server is run as "shiny" user, and must therefore be set globally:

    sudo su - -c "R -e \"install.packages('shiny', repos='http://cran.rstudio.com/')\"
    sudo su - \
      -c "R -e \"install.packages('ggplot2', repos='http://cran.ism.ac.jp/')\""

