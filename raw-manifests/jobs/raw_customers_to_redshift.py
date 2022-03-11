import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node Raw Customers Data Catalog
RawCustomersDataCatalog_node1646919673225 = (
    glueContext.create_dynamic_frame.from_catalog(
        database="epam-lakeformation-demo-raw",
        table_name="customers",
        transformation_ctx="RawCustomersDataCatalog_node1646919673225",
    )
)

# Script generated for node Apply Mapping
ApplyMapping_node1646919681078 = ApplyMapping.apply(
    frame=RawCustomersDataCatalog_node1646919673225,
    mappings=[
        ("customer_id", "long", "id", "int"),
        ("first_name", "string", "firstname", "string"),
        ("last_name", "string", "lastname", "string"),
        ("gender", "string", "gender", "string"),
    ],
    transformation_ctx="ApplyMapping_node1646919681078",
)

# Script generated for node Amazon Redshift
pre_query = "drop table if exists public.stage_table_a70698b4e2374f5b9d34d2daf826c7a7;create table public.stage_table_a70698b4e2374f5b9d34d2daf826c7a7 as select * from public.customer where 1=2;"
post_query = "begin;delete from public.customer using public.stage_table_a70698b4e2374f5b9d34d2daf826c7a7 where public.stage_table_a70698b4e2374f5b9d34d2daf826c7a7.id = public.customer.id; insert into public.customer select * from public.stage_table_a70698b4e2374f5b9d34d2daf826c7a7; drop table public.stage_table_a70698b4e2374f5b9d34d2daf826c7a7; end;"
AmazonRedshift_node1646919718361 = glueContext.write_dynamic_frame.from_jdbc_conf(
    frame=ApplyMapping_node1646919681078,
    catalog_connection="redshift_connection",
    connection_options={
        "database": "test",
        "dbtable": "public.stage_table_a70698b4e2374f5b9d34d2daf826c7a7",
        "preactions": pre_query,
        "postactions": post_query,
    },
    redshift_tmp_dir=args["TempDir"],
    transformation_ctx="AmazonRedshift_node1646919718361",
)

job.commit()
