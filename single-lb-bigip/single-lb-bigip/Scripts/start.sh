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

## Create blackbox.conf from a predefined string.
## Create logic to create each row we needed.  
## -->Could be multiple rows for each application.
## -->Maybe we should break this at the deployment level.
## -->Will need more logic for this.
ismaster=$1
masterhostname=$2
masteraddress=$3
masterpassword=$4
devicehostname=$5
deviceaddress=$6
basekey=$7
appname=$8
rownumber=$9
vipport=$10
protocol=$11
host=$12
location=$13
appport=$14
asmapptype=$15
asmlevel=$16
fqdn=$17
sslpkcs12=$18
sslpassphrase=$19

row1='"'$rownumber'":["'$vipport'","'$protocol'",["'$host'.'$location'.cloudapp.azure.com:'$appport'"],"","","","","","'$asmapptype'","'$asmlevel'","yes","yes","yes","wanlan","'$fqdn'","yes","","","","",""]'

deployment1='"deployment_'$appname'.'$location'.cloudapp.azure.com":{"traffic-group":"none","strict-updates":"disabled","variables":{"configuration__saskey":''"tAjn8Xuzelj9ps4HzRsHXqXznAIiHPFIzlSC08De2Zk=","configuration__saskeyname":"sharing-is-caring","configuration__eventhub":"event-horizon",''"configuration__eventhub_namespace":"event-horizon-ns","configuration__applianceid":"8A3ED335-F734-449F-A8FB-335B48FE3B50",''"configuration__logginglevel":"Alert","configuration__loggingtemplate":"CEF"},"tables":{"configuration__destination":{"column-names":[''"port","mode","backendmembers","monitoruser","monitorpass","monitoruri","monitorexpect","asmtemplate","asmapptype","asmlevel","l7ddos",''"ipintel","caching","tcpoptmode","fqdns","oneconnect","sslpkcs12","sslpassphrase","sslcert","sslkey","sslchain"],"rows":{'$row1'}}}}'

jsonfile='{"loadbalance":{"is_master":"'$ismaster'","master_hostname":"'$masterhostname'","master_address":"'$masteraddress'","master_password":"'$masterpassword'"'',"device_hostname":"'$devicehostname'","device_address":"'$deviceaddress'","device_password":"'$masterpassword'"},"bigip":{"application_name":"Azure Security F5 WAF"'',"ntp_servers":"1.pool.ntp.org 2.pool.ntp.org","ssh_key_inject":"false","change_passwords":"false","license":{"basekey":"'$basekey'"},''"modules":{"auto_provision":"true","ltm":"nominal","afm":"none","asm":"nominal"},"redundancy":{"provision":"false"},"network"'':{"provision":"false"},"iappconfig":{"f5.rome_waf":{"template_location":''"http://cdn-prod-ore-f5.s3-website-us-west-2.amazonaws.com/product/blackbox/staging/azure/f5.rome_waf.tmpl","deployments":{'$deployment1'}}}}}'

echo $jsonfile > /config/blackbox.conf



## Move the files and run them.
mv ./blackboxstartup.sh /config/blackboxstartup.sh
chmod u+x /config/blackboxstartup.sh
bash /config/blackboxstartup.sh
