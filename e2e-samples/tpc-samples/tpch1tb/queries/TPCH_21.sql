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