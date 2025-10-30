from pyspark.sql import SparkSession

# Create a SparkSession
spark = SparkSession.builder \
    .appName("DataCleaner") \
    .getOrCreate()


# 1 Membaca file CSV dari HDFS
df = (
    spark.read
        .option("header", "true")  # baris pertama berisi nama kolom
        .csv("/census2021/ada/ada.csv")  # lokasi file di HDFS
)

# 3 Mengganti nama kolom yang memiliki tanda '+' agar lebih bersih
for old_name in df.columns:
    new_name = old_name.replace("+", "")
    if new_name != old_name:
        df = df.withColumnRenamed(old_name, new_name)

# 4 Memilih subset kolom yang penting saja
selected_columns = [
    "GEO_NAME",
    "CHARACTERISTIC_ID",
    "CHARACTERISTIC_NAME",
    "C1_COUNT_TOTAL",
    "C2_COUNT_MEN",
    "C3_COUNT_WOMEN",
]
df_reduced = df.select(*selected_columns)

# 7 Menulis hasil daftar yang sudah dibersihkan ke HDFS
(
    df_reduced.coalesce(1)
        .write
        .option("header", "true")
        .mode("overwrite")
        .csv("/census2021/ada/clean.csv")
)
