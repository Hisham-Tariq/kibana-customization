#!/bin/bash
# Bash script to inject our custom Kibana configurations

debug='>> /var/log/customize-kibana.log 2>&1'

startService() {

    if [ -n "$(ps -e | egrep ^\ *1\ .*systemd$)" ]; then
        eval "systemctl restart $1.service ${debug}"
        if [  "$?" != 0  ]; then
            logger -e "${1^} could not be started."
            rollBack
            exit 1;
        else
            logger "${1^} started"
        fi
    elif [ -n "$(ps -e | egrep ^\ *1\ .*init$)" ]; then
        eval "chkconfig $1 on ${debug}"
        eval "service $1 start ${debug}"
        eval "/etc/init.d/$1 start ${debug}"
        if [  "$?" != 0  ]; then
            logger -e "${1^} could not be started."
            rollBack
            exit 1;
        else
            logger "${1^} started"
        fi
    elif [ -x /etc/rc.d/init.d/$1 ] ; then
        eval "/etc/rc.d/init.d/$1 start ${debug}"
        if [  "$?" != 0  ]; then
            logger -e "${1^} could not be started."
            rollBack
            exit 1;
        else
            logger "${1^} started"
        fi
    else
        logger -e "${1^} could not start. No service manager found on the system."
        exit 1;
    fi

}

# check the system type
if [ -n "$(command -v yum)" ]; then
    sys_type="yum"
    sep="-"
elif [ -n "$(command -v zypper)" ]; then
    sys_type="zypper"
    sep="-"
elif [ -n "$(command -v apt-get)" ]; then
    sys_type="apt-get"
    sep="="
fi


# check if git is installed
# check if git is installed
GitPath=$(which git)
if [ "$GitPath" == "" ];then
    echo "Git Not Found installing the git"
    if [ "${sys_type}" == "yum" ]; then
       eval "yum install git -y ${debug}"
    elif [ "${sys_type}" == "zypper" ]; then
       eval "zypper -n in git-core ${debug}"
    elif [ "${sys_type}" == "apt-get" ]; then
       eval "apt install git -y ${debug}"
    fi

    if [ -n "$(command -v git)" ];then
      echo "Git is successfully installed"
    else
      echo "Something went wrong in Git Installtion check /var/log/customize-kibana.log for more information"
      exit 1;
   fi
fi


#check if rsync is installed
RsyncPath=$(which rsync)
if [ "$RsyncPath" == "" ];then
    echo "Rsync Not Found installing the grsync"
    if [ "${sys_type}" == "yum" ]; then
       eval "yum install rsync -y ${debug}"
    elif [ "${sys_type}" == "zypper" ]; then
       eval "zypper -n in rsync ${debug}"
    elif [ "${sys_type}" == "apt-get" ]; then
       eval "apt-get install rsync -y ${debug}"
    fi

    if [ -n "$(command -v rsync)" ];then
      echo "Rsync is successfully installed"
    else
      echo "Something went wrong in Rsync Installtion check /var/log/customize-kibana.log for more information"
      exit 1;
   fi
fi


eval "git clone https://github.com/Hisham-Tariq/kibana-customization.git /tmp/kibana ${debug}"
if [ ! -d "/tmp/kibana" ];then
   echo "ERROR: Failed to clone the repository Kibana-Customization ${debug}"
   echo "Something went wrong check the /var/log/customize-kibana.log for more information"
else
   echo "Injecting the customizations..."
   eval "rsync -a /tmp/kibana/  /etc/kibana/"
   echo "Successfully Injected restarting the Kibana Please wait..."
   eval "rm -r /tmp/kibana"
   startService "kibana"
   echo "Kibana Service is started"
fi
