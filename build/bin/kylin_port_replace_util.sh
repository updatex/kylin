#!/bin/bash
#exit if find error
# ============================================================================

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
function error() {
   SCRIPT="$0"           # script name
   LASTLINE="$1"         # line of error occurrence
   LASTERR="$2"          # error code
   echo "ERROR exit from ${SCRIPT} : line ${LASTLINE} with exit code ${LASTERR}"
   exit 1
}
trap 'error ${LINENO} ${?}' ERR


#check input parameters
if [ $# -eq 0 ]; then
  echo "Usage : port_offset_util.sh set PORT_OFFSET --> Modify all conflict ports base on a offset"
  echo "Usage : port_offset_util.sh reset --> Recover to original setting"
  exit 0
fi

#check kylin home
if [ -z "$KYLIN_HOME" ]
then
    echo 'Please make sure KYLIN_HOME has been set'
    exit 1
else
    echo "KYLIN_HOME is set to ${KYLIN_HOME}"
fi

#variables
TOMCAT_BACKUP_FILE="${KYLIN_HOME}/tomcat/conf/server.xml.backup"
TOMCAT_CONFIG_FILE="${KYLIN_HOME}/tomcat/conf/server.xml"
KYLIN_CONFIG_FILE="${KYLIN_HOME}/conf/kylin.properties"
KYLIN_BACKUP_FILE="${KYLIN_HOME}/conf/kylin.properties.backup"
TOMCAT_PORT_LIST=(9005 7070 9443 7443 9009)
KYLIN_DEFAULT_PORT=7070

if [ "$1" == "set" ] 
then
    OFFSET=$2
    echo "Port offset is : ${OFFSET}"

    #check config file exist
    if [ ! -f ${KYLIN_CONFIG_FILE} ] || [ ! -f ${TOMCAT_CONFIG_FILE} ]; then
        echo "Some of the config file not exist"
        exit 1
    fi

    #back or reset
    if [ ! -f ${KYLIN_BACKUP_FILE} ]; then  #backup if not exist
        cp -f ${KYLIN_CONFIG_FILE} ${KYLIN_BACKUP_FILE}
    else
        cp -r ${KYLIN_BACKUP_FILE} ${KYLIN_CONFIG_FILE} #reset if exist
    fi

    if [ ! -f ${TOMCAT_BACKUP_FILE} ]; then  #backup if not exist
        cp -f ${TOMCAT_CONFIG_FILE} ${TOMCAT_BACKUP_FILE}
    else
        cp -r ${TOMCAT_BACKUP_FILE} ${TOMCAT_CONFIG_FILE} #reset if exist
    fi

    #replace ports in kylin.properties
    new_kylin_port=`expr ${KYLIN_DEFAULT_PORT} + ${OFFSET}`

    sed -i "s/kylin.server.cluster-servers=\(.*\).*:\(.*\)/kylin.server.cluster-servers=\1:${new_kylin_port}/g" ${KYLIN_CONFIG_FILE}

    echo "New kylin port is : ${new_kylin_port}"

    #replace ports in server.xml

    for port in ${TOMCAT_PORT_LIST[@]}
    do
      new_port=`expr ${port} + ${OFFSET} `
      #echo "Replace old port : ${port} to new port : ${new_port}"
      sed -i "s/$port/${new_port}/g" ${TOMCAT_CONFIG_FILE}

    done
    echo "Files below modified:"
    echo ${KYLIN_CONFIG_FILE}
    echo ${TOMCAT_CONFIG_FILE}
elif [ "$1" == "reset" ]
then
    #reset kylin.properties
    cp  -f ${KYLIN_BACKUP_FILE} ${KYLIN_CONFIG_FILE}
    cp  -f ${TOMCAT_BACKUP_FILE} ${TOMCAT_CONFIG_FILE}
    rm  -f ${KYLIN_BACKUP_FILE}
    rm  -f ${TOMCAT_BACKUP_FILE}
    echo "Files below reset to original:"
    echo ${KYLIN_CONFIG_FILE}
    echo ${TOMCAT_CONFIG_FILE}
else
    echo "Unrecognized command"
    exit 1
fi
