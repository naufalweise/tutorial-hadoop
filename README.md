# Tutorial Big Data

##  VM


### Informasi VM
Nama VM: `bigdata-vm` <br>
username VM: `vboxuser` <br>
password VM: `bigdata` <br>
ip (host only): `192.168.56.50`<br>


### SSH Ke VM
Agar bisa copy paste, gunakan ssh untuk connect dari terminal windows/mac ke vm.
1. Buka command prompt di Windows/MAC anda
2. Jalankan command berikut
```
ssh vboxuser@192.168.56.50
```
3. Masukkan password VM

#### Troubleshoot: SSH Tidak Terinstall Di Windows
1. Buka Setting > System > Optional Featues 
2. Klik View Features
3. Klik See Available Features
4. Ketik SSH ke kolom search
5. Ceklis OpenSSH Client
6. Klik Add


### Menghidupkan Hadoop
Hidupkan hadoop sehabis menyalakan VM.
```
start-all.sh
```
Cek status node yang berjalan
```
jps
```
Contoh output bila semuanya berjalan
```
vboxuser@bigdata-vm-2:~$ jps
2643 SecondaryNameNode
2869 ResourceManager
2246 NameNode
2394 DataNode
3019 NodeManager
3358 Jps
```

## Hadoop

### Import Data Ke Hadoop

- Download Dataset
```
cd ~
wget -c --content-disposition "https://www12.statcan.gc.ca/census-recensement/2021/dp-pd/prof/details/download-telecharger/comp/GetFile.cfm?Lang=E&FILETYPE=CSV&GEONO=012"
sudo apt install unzip
unzip 98-401-X2021012_eng_CSV.zip
```

- [Info] Jalankan command berikut untuk melihat bagian awal isi file dataset:

```
head 98-401-X2021012_English_CSV_data.csv
```

- Masukkan file ke hdfs
```
hadoop fs -mkdir -p /census2021/ada
hadoop fs -put ./98-401-X2021012_English_CSV_data.csv /census2021/ada/ada.csv
```
- [Info] Jalankan command berikut untuk mengecek file yang sudah dimasukkan ke hdfs.
```
hadoop fs -ls -R /census2021
hadoop fs -head /census2021/ada/ada.csv
```

Contoh Output
```
nau@nau-vm:~$ hadoop fs -ls -R /census2021
2025-10-25 13:17:37,658 WARN util.NativeCodeLoader: Unable to load native-hadoop library for your platform... using builtin-java classes where applicable
drwxr-xr-x   - nau supergroup          0 2025-10-25 13:17 /census2021/ada
-rw-r--r--   1 nau supergroup 2415200889 2025-10-25 13:17 /census2021/ada/ada.csv
```

- [Info] Jalankan command berikut untuk melihat isi dataset yang berada di hdfs.
```
hadoop fs -head /census2021/ada/ada.csv
```

## Map Reduce

Anda akan membuat program penghitung baris (line count) menggunakan MapReduce. Fungsinya adalah menghitung jumlah baris di dalam suatu file.

- Buat folder line-count
```
cd ~
mkdir line-count
cd line-count
```
- Buat file mapper.py
```
#!/usr/bin/env python3
import sys
import io
input_stream = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8', errors='ignore')
for line in input_stream:
    print("total\t1")
```
- Buat file reducer
```
#!/usr/bin/env python3

import sys

current_key = None
total_count = 0

for line in sys.stdin:
    try:
        key, count_str = line.strip().split('\t', 1)
        count = int(count_str)
    except:
        continue # Skip baris yang formatnya tidak sesuai

    if key == current_key:
        total_count += count
    else:
        if current_key:
            # Output hasil dari key sebelumnya
            print(f"{current_key}\t{total_count}")
        current_key = key
        total_count = count

# Output key terakhir
if current_key:
    print(f"{current_key}\t{total_count}")
```

- Jalankan Program Line Count di Map Reduce
```
hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.4.2.jar \
    -D mapreduce.job.name="Python Line Count" \
    -files mapper.py,reducer.py \
    -mapper "mapper.py" \
    -combiner "reducer.py" \
    -reducer "reducer.py" \
    -input "/census2021/ada/ada.csv" \
    -output "/LineCount"
```


- Lihat hasil Output Line Count
```
hadoop fs -ls -R /LineCount
hadoop fs -cat /LineCount/part-00000
```

Contoh hasil output
```
Contoh Hasil Output
nau@nau-vm:~$ hadoop fs -head /LineCount/part-00000
total    14294224
```
Dapat dilihat bahwa total baris di dataset adalah 14294224.

## Spark

### Install Spark
Note: Skip bagian ini bila menggunakan OVA virtualbox yang diberikan.

### Praktik Spark

