# case 1 v
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("CensusAnalysis").getOrCreate()
df = (spark.read
      .option("header", "true")
      .option("inferSchema", "true")
      .csv("hdfs:///census2021/ada/clean.csv"))

df.printSchema()
print("Jumlah baris:", df.count())

# case 2 v
from pyspark.sql.functions import col, sum
gender_df = df.select("GEO_NAME",
                      col("C2_COUNT_MEN").cast("int").alias("Men"),
                   col("C3_COUNT_WOMEN").cast("int").alias("Women"))
totals = gender_df.agg(sum("Men").alias("TotalMen"),
                       sum("Women").alias("TotalWomen"))
totals.show()

# case 3 v

df.createOrReplaceTempView("census")
result = spark.sql("""
    SELECT GEO_NAME as Province,
           SUM(C1_COUNT_TOTAL) as TotalPopulation
    FROM census
    GROUP BY GEO_NAME
    ORDER BY TotalPopulation DESC
""")
result.show(10)