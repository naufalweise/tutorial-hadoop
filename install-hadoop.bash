#!/bin/bash

# atur working directory 
cd ~

sudo apt-get -y update

# install java
sudo apt install -y openjdk-17-jdk

# install ssh
sudo apt-get -y install openssh-client openssh-server
sudo apt-get -y install ssh pdsh

# konfigurasikan ssh
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys

# install hadoop
wget -c https://dlcdn.apache.org/hadoop/common/hadoop-3.4.2/hadoop-3.4.2.tar.gz
tar -xvzf hadoop-3.4.2.tar.gz

# hadoop data
sudo mkdir -p /opt/hadoop_data/namenode
sudo mkdir -p /opt/hadoop_data/datanode
sudo chown -R $USER:$USER /opt/hadoop_data


# konfigurasikan hadoop
cd ~/hadoop-3.4.2/etc/hadoop
cat << EOF > core-site.xml
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF


cat << EOF > hdfs-site.xml
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>

    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop_data/namenode</value>
    </property>

    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop_data/datanode</value>
    </property>
</configuration>

EOF


cat << EOF > mapred-site.xml
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:\$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOF


cat << EOF > yarn-site.xml
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
EOF

# Tambahkan enviromment variable ke .bashrc

cat << EOF >> ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export HADOOP_CLASSPATH=\$JAVA_HOME/lib/tools.jar
export HADOOP_HOME=~/hadoop-3.4.2
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
EOF



# Reload bashrc
source ~/.bashrc

#
cat << EOF >> $HADOOP_CONF_DIR/hadoop-env.sh
export PDSH_RCMD_TYPE=ssh
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
EOF

# Inisiasi Hadoop Distributed File System (HDFS)
hdfs namenode -format

# Jalankan hadoop
start-all.sh
