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
  AND O_ORDERDATE >= '1994-10-01' -- [DATE]
  AND O_ORDERDATE < '1995-01-01' -- [DATE] + interval '3' month
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