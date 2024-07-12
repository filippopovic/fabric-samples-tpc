# Data types

This document contains list of all tables, columns and data types used in benchmarks:

[TOC]



## TPC-H data types

| Table    | Column          | TPCH 1TB        |
| -------- | --------------- | --------------- |
| customer | C_CUSTKEY       | bigint          |
| customer | C_NAME          | varchar(25)     |
| customer | C_ADDRESS       | varchar(40)     |
| customer | C_NATIONKEY     | int             |
| customer | C_PHONE         | char(15)        |
| customer | C_ACCTBAL       | decimal(12, 2)  |
| customer | C_MKTSEGMENT    | char(10)        |
| customer | C_COMMENT       | varchar(117)    |
| lineitem | L_ORDERKEY      | bigint          |
| lineitem | L_PARTKEY       | bigint          |
| lineitem | L_SUPPKEY       | bigint          |
| lineitem | L_LINENUMBER    | int             |
| lineitem | L_QUANTITY      | decimal(12,  2) |
| lineitem | L_EXTENDEDPRICE | decimal(12, 2)  |
| lineitem | L_DISCOUNT      | decimal(12,  2) |
| lineitem | L_TAX           | decimal(12, 2)  |
| lineitem | L_RETURNFLAG    | char(1)         |
| lineitem | L_LINESTATUS    | char(1)         |
| lineitem | L_SHIPDATE      | date            |
| lineitem | L_COMMITDATE    | date            |
| lineitem | L_RECEIPTDATE   | date            |
| lineitem | L_SHIPINSTRUCT  | char(25)        |
| lineitem | L_SHIPMODE      | char(10)        |
| lineitem | L_COMMENT       | varchar(44)     |
| nation   | N_NATIONKEY     | int             |
| nation   | N_NAME          | char(25)        |
| nation   | N_REGIONKEY     | int             |
| nation   | N_COMMENT       | varchar(152)    |
| orders   | O_ORDERKEY      | bigint          |
| orders   | O_CUSTKEY       | bigint          |
| orders   | O_ORDERSTATUS   | char(1)         |
| orders   | O_TOTALPRICE    | decimal(12, 2)  |
| orders   | O_ORDERDATE     | date            |
| orders   | O_ORDERPRIORITY | char(15)        |
| orders   | O_CLERK         | char(15)        |
| orders   | O_SHIPPRIORITY  | int             |
| orders   | O_COMMENT       | varchar(79)     |
| part     | P_PARTKEY       | bigint          |
| part     | P_NAME          | varchar(55)     |
| part     | P_MFGR          | char(25)        |
| part     | P_BRAND         | char(10)        |
| part     | P_TYPE          | varchar(25)     |
| part     | P_SIZE          | int             |
| part     | P_CONTAINER     | char(10)        |
| part     | P_RETAILPRICE   | decimal(12,  2) |
| part     | P_COMMENT       | varchar(23)     |
| partsupp | PS_PARTKEY      | bigint          |
| partsupp | PS_SUPPKEY      | bigint          |
| partsupp | PS_AVAILQTY     | int             |
| partsupp | PS_SUPPLYCOST   | decimal(12, 2)  |
| partsupp | PS_COMMENT      | varchar(199)    |
| region   | R_REGIONKEY     | bigint          |
| region   | R_NAME          | char(25)        |
| region   | R_COMMENT       | varchar(152)    |
| supplier | S_SUPPKEY       | bigint          |
| supplier | S_NAME          | char(25)        |
| supplier | S_ADDRESS       | varchar(40)     |
| supplier | S_NATIONKEY     | int             |
| supplier | S_PHONE         | char(15)        |
| supplier | S_ACCTBAL       | decimal(12, 2)  |
| supplier | S_COMMENT       | varchar(101)    |



## TPC-DS data types

