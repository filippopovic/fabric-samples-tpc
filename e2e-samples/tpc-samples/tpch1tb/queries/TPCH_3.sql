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