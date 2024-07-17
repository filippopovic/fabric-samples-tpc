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