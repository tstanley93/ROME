#!/bin/bash
###########################################################################
##       ffff55555                                                       ##
##     ffffffff555555                                                    ##
##   fff      f5    55         Deployment Script Version 0.0.1           ##
##  ff    fffff     555                                                  ##
##  ff    fffff f555555                                                  ##
## fff       f  f5555555             Written By: EIS Consulting          ##
## f        ff  f5555555                                                 ##
## fff   ffff       f555             Date Created: 12/02/2015            ##
## fff    fff5555    555             Last Updated: 12/02/2015            ##
##  ff    fff 55555  55                                                  ##
##   f    fff  555   5       This script will start the pre-configured   ##
##   f    fff       55       WAF configuration.                          ##
##    ffffffff5555555                                                    ##
##       fffffff55                                                       ##
###########################################################################
###########################################################################
##                              Change Log                               ##
###########################################################################
## Version #     Name       #                    NOTES                   ##
###########################################################################
## 11/23/15#  Thomas Stanley#    Created base functionality              ##
###########################################################################

echo $1
echo $2
echo $3
mv ./blackbox.conf /config/blackbox.conf
mv ./blackboxstartup.sh /config/blackboxstartup.sh
chmod u+x /config/blackboxstartup.sh
sh /config/blackboxstartup.sh
