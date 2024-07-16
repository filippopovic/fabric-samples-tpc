# Data types

This document contains list of all tables, columns and data types used in benchmarks:

- [TPC-H data types](#tpc-h-data-types)

- [TPC-DS data types](#tpc-ds-data-types)



## TPC-H data types

| Table    | Column          | TPCH 1TB                 |
| -------- | --------------- | ------------------------ |
| customer | C_CUSTKEY       | bigint NOT NULL          |
| customer | C_NAME          | varchar(25) NOT NULL     |
| customer | C_ADDRESS       | varchar(40) NOT NULL     |
| customer | C_NATIONKEY     | int NOT NULL             |
| customer | C_PHONE         | char(15) NOT NULL        |
| customer | C_ACCTBAL       | decimal(12, 2) NOT  NULL |
| customer | C_MKTSEGMENT    | char(10) NOT NULL        |
| customer | C_COMMENT       | varchar(117) NOT NULL    |
| lineitem | L_ORDERKEY      | bigint NOT NULL          |
| lineitem | L_PARTKEY       | bigint NOT NULL          |
| lineitem | L_SUPPKEY       | bigint NOT NULL          |
| lineitem | L_LINENUMBER    | int NOT NULL             |
| lineitem | L_QUANTITY      | decimal(12, 2) NOT  NULL |
| lineitem | L_EXTENDEDPRICE | decimal(12, 2) NOT  NULL |
| lineitem | L_DISCOUNT      | decimal(12, 2) NOT  NULL |
| lineitem | L_TAX           | decimal(12, 2) NOT  NULL |
| lineitem | L_RETURNFLAG    | char(1) NOT NULL         |
| lineitem | L_LINESTATUS    | char(1) NOT NULL         |
| lineitem | L_SHIPDATE      | date NOT NULL            |
| lineitem | L_COMMITDATE    | date NOT NULL            |
| lineitem | L_RECEIPTDATE   | date NOT NULL            |
| lineitem | L_SHIPINSTRUCT  | char(25) NOT NULL        |
| lineitem | L_SHIPMODE      | char(10) NOT NULL        |
| lineitem | L_COMMENT       | varchar(44) NOT NULL     |
| nation   | N_NATIONKEY     | int NOT NULL             |
| nation   | N_NAME          | char(25) NOT NULL        |
| nation   | N_REGIONKEY     | bigint NOT NULL          |
| nation   | N_COMMENT       | varchar(152) NOT NULL    |
| orders   | O_ORDERKEY      | bigint NOT NULL          |
| orders   | O_CUSTKEY       | bigint NOT NULL          |
| orders   | O_ORDERSTATUS   | char(1) NOT NULL         |
| orders   | O_TOTALPRICE    | decimal(12, 2) NOT  NULL |
| orders   | O_ORDERDATE     | date NOT NULL            |
| orders   | O_ORDERPRIORITY | char(15) NOT NULL        |
| orders   | O_CLERK         | char(15) NOT NULL        |
| orders   | O_SHIPPRIORITY  | int NOT NULL             |
| orders   | O_COMMENT       | varchar(79) NOT NULL     |
| part     | P_PARTKEY       | bigint NOT NULL          |
| part     | P_NAME          | varchar(55) NOT NULL     |
| part     | P_MFGR          | char(25) NOT NULL        |
| part     | P_BRAND         | char(10) NOT NULL        |
| part     | P_TYPE          | varchar(25) NOT NULL     |
| part     | P_SIZE          | int NOT NULL             |
| part     | P_CONTAINER     | char(10) NOT NULL        |
| part     | P_RETAILPRICE   | decimal(12, 2) NOT  NULL |
| part     | P_COMMENT       | varchar(23) NOT NULL     |
| partsupp | PS_PARTKEY      | bigint NOT NULL          |
| partsupp | PS_SUPPKEY      | bigint NOT NULL          |
| partsupp | PS_AVAILQTY     | int NOT NULL             |
| partsupp | PS_SUPPLYCOST   | decimal(12, 2) NOT  NULL |
| partsupp | PS_COMMENT      | varchar(199) NOT NULL    |
| region   | R_REGIONKEY     | bigint NOT NULL          |
| region   | R_NAME          | char(25) NOT NULL        |
| region   | R_COMMENT       | varchar(152) NOT NULL    |
| supplier | S_SUPPKEY       | bigint NOT NULL          |
| supplier | S_NAME          | char(25) NOT NULL        |
| supplier | S_ADDRESS       | varchar(40) NOT NULL     |
| supplier | S_NATIONKEY     | int NOT NULL             |
| supplier | S_PHONE         | char(15) NOT NULL        |
| supplier | S_ACCTBAL       | decimal(12, 2) NOT  NULL |
| supplier | S_COMMENT       | varchar(101) NOT NULL    |



## TPC-DS data types

