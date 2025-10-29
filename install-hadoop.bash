#!/bin/bash

# atur working directory 
cd ~

sudo apt-get -y update

# install java (package ini akan otomatis memilih arsitektur yang benar)
sudo apt install -y openjdk-17-jdk

# --- Deteksi JAVA_HOME secara dinamis ---
# Mencari path instalasi Java yang sebenarnya via symbolic link
export JAVA_HOME=$(dirname $(dirname $(readlink -f /etc/alternatives/java)))

# Periksa apakah JAVA_HOME berhasil ditemukan
if [ -z "$JAVA_HOME" ]; then
    echo "Error: Gagal mendeteksi JAVA_HOME secara otomatis."
    echo "Silakan atur secara manual dan jalankan lagi."
    exit 1
fi

echo "JAVA_HOME berhasil terdeteksi di: $JAVA_HOME"

# install ssh
sudo apt-get -y install openssh-client openssh-server
sudo apt-get -y install ssh pdsh

# konfigurasikan ssh
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys


# --- PERBAIKAN: Deteksi Arsitektur untuk Unduhan Hadoop ---
ARCH=$(uname -m)
HADOOP_VERSION="3.4.2"

if [ "$ARCH" = "aarch64" ]; then
    echo "Mendeteksi arsitektur aarch64 (arm64). Menggunakan lean build."
    HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}-aarch64-lean.tar.gz"
    HADOOP_TARBALL="hadoop-${HADOOP_VERSION}-aarch64-lean.tar.gz"
    HADOOP_DIR="hadoop-${HADOOP_VERSION}-aarch64-lean"
else
    echo "Mendeteksi arsitektur $ARCH (diasumsikan amd64). Menggunakan build standar."
    HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
    HADOOP_TARBALL="hadoop-${HADOOP_VERSION}.tar.gz"
    HADOOP_DIR="hadoop-${HADOOP_VERSION}"
fi

# install hadoop
wget -c $HADOOP_URL
tar -xvzf $HADOOP_TARBALL
# -----------------------------------------------------------------


# --- PERBAIKAN: Gunakan variabel HADOOP_DIR dinamis ---
export HADOOP_HOME=~/$HADOOP_DIR
export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export HADOOP_CLASSPATH=$JAVA_HOME/lib/tools.jar
# -----------------------------------------------------------------

# hadoop data
sudo mkdir -p /opt/hadoop_data/namenode
sudo mkdir -p /opt/hadoop_data/datanode
sudo chown -R $USER:$USER /opt/hadoop_data


# konfigurasikan hadoop
cd $HADOOP_CONF_DIR # Gunakan variabel HADOOP_CONF_DIR

cat << EOF > core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
</configuration>
EOF


cat << EOF > hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
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


cat << 'EOF' > mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name> <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOF


cat << EOF > yarn-site.xml
<?xml version="1.0"?>
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

# --- PERBAIKAN: Tambahkan HADOOP_DIR dinamis ke .bashrc ---
# Cek agar tidak menambahkan baris duplikat jika skrip dijalankan lagi
if ! grep -q "HADOOP_HOME" ~/.bashrc; then
  echo "Menambahkan environment variables ke ~/.bashrc..."
  cat << EOF >> ~/.bashrc

# Hadoop Variables
export JAVA_HOME=$JAVA_HOME
export HADOOP_CLASSPATH=\$JAVA_HOME/lib/tools.jar
export HADOOP_HOME=~/$HADOOP_DIR
export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin
export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
EOF
fi
# -----------------------------------------------------------------------------------


# --- PERBAIKAN: Gunakan variabel $JAVA_HOME dinamis di hadoop-env.sh ---
cat << EOF >> $HADOOP_CONF_DIR/hadoop-env.sh

export PDSH_RCMD_TYPE=ssh
export JAVA_HOME=$JAVA_HOME
EOF
# --------------------------------------------------------------------

# Inisiasi Hadoop Distributed File System (HDFS)
# Perintah ini sekarang akan berhasil karena variabel telah di-ekspor di dalam skrip
echo "Memformat HDFS Namenode..."
hdfs namenode -format

# Jalankan hadoop
echo "Menjalankan semua layanan Hadoop..."
start-all.sh

echo "Instalasi selesai. Anda bisa cek layanan dengan perintah 'jps'."