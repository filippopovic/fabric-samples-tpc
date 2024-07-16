-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')
GO

-- Query 2
SELECT
  TOP (100) S_ACCTBAL,
  S_NAME,
  N_NAME,
  P_PARTKEY,
  P_MFGR,
  S_ADDRESS,
  S_PHONE,
  S_COMMENT
FROM
  part,
  supplier,
  partsupp,
  nation,
  region
WHERE
  P_PARTKEY = PS_PARTKEY
  AND S_SUPPKEY = PS_SUPPKEY
  AND P_SIZE = 28
  AND P_TYPE LIKE '%STEEL'
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND PS_SUPPLYCOST = (
    SELECT
      min(PS_SUPPLYCOST)
    FROM
      partsupp,
      supplier,
      nation,
      region
    WHERE
      P_PARTKEY = PS_PARTKEY
      AND S_SUPPKEY = PS_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'MIDDLE EAST'
  )
ORDER BY
  S_ACCTBAL DESC,
  N_NAME,
  S_NAME,
  P_PARTKEY
OPTION (LABEL = 'TPCH-Q2')
GO

-- Query 3
SELECT
  TOP (10) L_ORDERKEY,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  O_ORDERDATE,
  O_SHIPPRIORITY
FROM
  customer,
  orders,
  lineitem
WHERE
  C_MKTSEGMENT = 'MACHINERY' -- [SEGMENT]
  AND C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND O_ORDERDATE < '1995-03-26' -- [DATE]
  AND L_SHIPDATE > '1995-03-26' -- [DATE]
  -- DATE is a randomly selected day within [1995-03-01 .. 1995-03-31].
GROUP BY
  L_ORDERKEY,
  O_ORDERDATE,
  O_SHIPPRIORITY
ORDER BY
  revenue DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q3')
GO

-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')
GO

-- Query 5
SELECT
  N_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  customer,
  orders,
  lineitem,
  supplier,
  nation,
  region
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
  AND L_SUPPKEY = S_SUPPKEY
  AND C_NATIONKEY = S_NATIONKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_REGIONKEY = R_REGIONKEY
  AND R_NAME = 'MIDDLE EAST'
  AND O_ORDERDATE >= '1997-01-01' -- [DATE]
  AND O_ORDERDATE < DATEADD(YY, 1, cast ('1997-01-01'as date)) -- [DATE] + INTERVAL '1' YEAR
GROUP BY
  N_NAME
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q5')
GO

-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')
GO

-- Query 7
SELECT
  supp_nation,
  cust_nation,
  l_year,
  sum(volume) AS revenue
FROM
  (
    SELECT
      n1.N_NAME AS supp_nation,
      n2.N_NAME AS cust_nation,
      YEAR(L_SHIPDATE) AS l_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume
    FROM
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND C_CUSTKEY = O_CUSTKEY
      AND S_NATIONKEY = n1.N_NATIONKEY
      AND C_NATIONKEY = n2.N_NATIONKEY
      AND (
        (
          n1.N_NAME = 'FRANCE' -- '[NATION1]'
          AND n2.N_NAME = 'GERMANY' -- '[NATION2]'
        )
        OR (
          n1.N_NAME = 'GERMANY'  -- '[NATION2]'
          AND n2.N_NAME = 'FRANCE' -- '[NATION1]'
        )
      )
      AND L_SHIPDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
  ) AS shipping
GROUP BY
  supp_nation,
  cust_nation,
  l_year
ORDER BY
  supp_nation,
  cust_nation,
  l_year
OPTION (LABEL = 'TPCH-Q7')
GO

-- Query 8
SELECT
  o_year,
  sum(
    CASE WHEN NATION = 'VIETNAM' THEN volume ELSE 0 END -- [NATION] = VIETNAM
  ) / sum(volume) AS mkt_share
FROM
  (
    SELECT
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) AS volume,
      n2.N_NAME AS NATION
    FROM
      part,
      supplier,
      lineitem,
      orders,
      customer,
      nation as n1,
      nation as n2,
      region
    WHERE
      P_PARTKEY = L_PARTKEY
      AND S_SUPPKEY = L_SUPPKEY
      AND L_ORDERKEY = O_ORDERKEY
      AND O_CUSTKEY = C_CUSTKEY
      AND C_NATIONKEY = n1.N_NATIONKEY
      AND n1.N_REGIONKEY = R_REGIONKEY
      AND R_NAME = 'ASIA' -- [REGION]
      AND S_NATIONKEY = n2.N_NATIONKEY
      AND O_ORDERDATE BETWEEN '1995-01-01'
      AND '1996-12-31'
      AND P_TYPE = 'ECONOMY BRUSHED COPPER' -- [TYPE]
  ) AS all_nations
GROUP BY
  o_year
ORDER BY
  o_year
OPTION (LABEL = 'TPCH-Q8')
GO

-- Query 9
SELECT
  NATION,
  o_year,
  sum(amount) AS sum_profit
FROM
  (
    SELECT
      N_NAME AS NATION,
      YEAR(O_ORDERDATE) AS o_year,
      L_EXTENDEDPRICE * (1 - L_DISCOUNT) - PS_SUPPLYCOST * L_QUANTITY AS amount
    FROM
      part,
      supplier,
      lineitem,
      partsupp,
      orders,
      nation
    WHERE
      S_SUPPKEY = L_SUPPKEY
      AND PS_SUPPKEY = L_SUPPKEY
      AND PS_PARTKEY = L_PARTKEY
      AND P_PARTKEY = L_PARTKEY
      AND O_ORDERKEY = L_ORDERKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND P_NAME LIKE '%sky%'
  ) AS profit
GROUP BY
  NATION,
  o_year
ORDER BY
  NATION,
  o_year DESC
OPTION (LABEL = 'TPCH-Q9')
GO

-- Query 10
SELECT
  TOP (20) C_CUSTKEY,
  C_NAME,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue,
  C_ACCTBAL,
  N_NAME,
  C_ADDRESS,
  C_PHONE,
  C_COMMENT
FROM
  customer,
  orders,
  lineitem,
  nation
WHERE
  C_CUSTKEY = O_CUSTKEY
  AND L_ORDERKEY = O_ORDERKEY
	AND O_ORDERDATE	>= '1994-10-01'
	AND O_ORDERDATE	< dateadd(mm, 3, cast('1994-10-01' as date ))
  AND L_RETURNFLAG = 'R'
  AND C_NATIONKEY = N_NATIONKEY
GROUP BY
  C_CUSTKEY,
  C_NAME,
  C_ACCTBAL,
  C_PHONE,
  N_NAME,
  C_ADDRESS,
  C_COMMENT
ORDER BY
  revenue DESC
OPTION (LABEL = 'TPCH-Q10')
GO

-- Query 11
SELECT
  PS_PARTKEY,
  sum(PS_SUPPLYCOST * PS_AVAILQTY) AS value
FROM
  partsupp,
  supplier,
  nation
WHERE
  PS_SUPPKEY = S_SUPPKEY
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'GERMANY' -- [NATION]
GROUP BY
  PS_PARTKEY
HAVING
  sum(PS_SUPPLYCOST * PS_AVAILQTY) > (
    SELECT
      sum(PS_SUPPLYCOST * PS_AVAILQTY) * (0.0001 / 1000)-- [FRACTION]
    FROM
      partsupp,
      supplier,
      nation
    WHERE
      PS_SUPPKEY = S_SUPPKEY
      AND S_NATIONKEY = N_NATIONKEY
      AND N_NAME = 'GERMANY' -- [NATION]
  )
ORDER BY
  value DESC
OPTION (LABEL = 'TPCH-Q11')
GO

-- Query 12
SELECT
  L_SHIPMODE,
  sum(
    CASE WHEN O_ORDERPRIORITY = '1-URGENT'
    OR O_ORDERPRIORITY = '2-HIGH' THEN 1 ELSE 0 END
  ) AS high_line_count,
  sum(
    CASE WHEN O_ORDERPRIORITY <> '1-URGENT'
    AND O_ORDERPRIORITY <> '2-HIGH' THEN 1 ELSE 0 END
  ) AS low_line_count
FROM
  orders,
  lineitem
WHERE
  O_ORDERKEY = L_ORDERKEY
  AND L_SHIPMODE IN ('FOB', 'REG AIR') -- [SHIPMODE1], [SHIPTMODE2]
  AND L_COMMITDATE < L_RECEIPTDATE
  AND L_SHIPDATE < L_COMMITDATE
	AND L_RECEIPTDATE	>= '1995-01-01'
	AND L_RECEIPTDATE	< dateadd(yy, 1,cast ('1995-01-01' as date))
GROUP BY
  L_SHIPMODE
ORDER BY
  L_SHIPMODE
OPTION (LABEL = 'TPCH-Q12')
GO

-- Query 13
SELECT
  c_count,
  count_big(*) AS custdist
FROM
  (
    SELECT
      C_CUSTKEY,
      count_big(O_ORDERKEY)
    FROM
      customer
      LEFT OUTER JOIN orders ON C_CUSTKEY = O_CUSTKEY
      AND O_COMMENT NOT LIKE '%express%deposits%' -- %[WORD1]%[WORD2]%
    GROUP BY
      C_CUSTKEY
  ) AS c_orders(C_CUSTKEY, c_count)
GROUP BY
  c_count
ORDER BY
  custdist DESC,
  c_count DESC
OPTION (LABEL = 'TPCH-Q13')
GO

-- Query 14
SELECT
  100.00 * sum(
    CASE WHEN P_TYPE LIKE 'PROMO%' THEN L_EXTENDEDPRICE * (1 - L_DISCOUNT) ELSE 0 END
  ) / sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS promo_revenue
FROM
  lineitem,
  part
WHERE
  L_PARTKEY = P_PARTKEY
	AND L_SHIPDATE	>= '1997-05-01'
	AND L_SHIPDATE	< dateadd(mm, 1,cast ('1997-05-01' as date))
OPTION (LABEL = 'TPCH-Q14')
GO

-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')
GO

-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')
GO

-- Query 17
SELECT
  sum(L_EXTENDEDPRICE) / 7.0 AS avg_yearly
FROM
  lineitem,
  part
WHERE
  P_PARTKEY = L_PARTKEY
  AND P_BRAND = 'Brand#55' -- [BRAND]
  AND P_CONTAINER = 'SM JAR' -- [CONTAINER]
  AND L_QUANTITY < (
    SELECT
      0.2 * avg(L_QUANTITY)
    FROM
      lineitem
    WHERE
      L_PARTKEY = P_PARTKEY
  )
OPTION (LABEL = 'TPCH-Q17')
GO

-- Query 18
SELECT
  TOP (100) C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE,
  sum(L_QUANTITY)
FROM
  customer,
  orders,
  lineitem
WHERE
  O_ORDERKEY IN (
    SELECT
      L_ORDERKEY
    FROM
      lineitem
    GROUP BY
      L_ORDERKEY
    HAVING
      sum(L_QUANTITY) > 314 -- [QUANTITY]
  )
  AND C_CUSTKEY = O_CUSTKEY
  AND O_ORDERKEY = L_ORDERKEY
GROUP BY
  C_NAME,
  C_CUSTKEY,
  O_ORDERKEY,
  O_ORDERDATE,
  O_TOTALPRICE
ORDER BY
  O_TOTALPRICE DESC,
  O_ORDERDATE
OPTION (LABEL = 'TPCH-Q18')
GO

-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')
GO

-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')
GO

-- Query 21
SELECT
  TOP (100) S_NAME,
  count_big(*) AS numwait
FROM
  supplier,
  lineitem as l1,
  orders,
  nation
WHERE
  S_SUPPKEY = l1.L_SUPPKEY
  AND O_ORDERKEY = l1.L_ORDERKEY
  AND O_ORDERSTATUS = 'F'
  AND l1.L_RECEIPTDATE > l1.L_COMMITDATE
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem AS l2
    WHERE
      l2.L_ORDERKEY = l1.L_ORDERKEY
      AND l2.L_SUPPKEY <> l1.L_SUPPKEY
  )
  AND NOT EXISTS (
    SELECT
      *
    FROM
      lineitem AS l3
    WHERE
      l3.L_ORDERKEY = l1.L_ORDERKEY
      AND l3.L_SUPPKEY <> l1.L_SUPPKEY
      AND l3.L_RECEIPTDATE > l3.L_COMMITDATE
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'VIETNAM' -- NATION
GROUP BY
  S_NAME
ORDER BY
  numwait DESC,
  S_NAME
OPTION (LABEL = 'TPCH-Q21')
GO

-- Query 22
SELECT
  cntrycode,
  count_big(*) AS numcust,
  sum(C_ACCTBAL) AS totacctbal
FROM
  (
    SELECT
      substring(C_PHONE, 1, 2) AS cntrycode,
      C_ACCTBAL
    FROM
      customer
    WHERE
      substring(C_PHONE, 1, 2) IN (
        '31',
        '17',
        '30',
        '24',
        '26',
        '34',
        '10'
      )
      AND C_ACCTBAL > (
        SELECT
          avg(C_ACCTBAL)
        FROM
          customer
        WHERE
          C_ACCTBAL > 0.00
          AND substring(C_PHONE, 1, 2) IN (
            '31',
            '17',
            '30',
            '24',
            '26',
            '34',
            '10'
          )
      )
      AND NOT EXISTS (
        SELECT
          *
        FROM
          orders
        WHERE
          O_CUSTKEY = C_CUSTKEY
      )
  ) AS custsale
GROUP BY
  cntrycode
ORDER BY
  cntrycode
OPTION (LABEL = 'TPCH-Q22')
GO

