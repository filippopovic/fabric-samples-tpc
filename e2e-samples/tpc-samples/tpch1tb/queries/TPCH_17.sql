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