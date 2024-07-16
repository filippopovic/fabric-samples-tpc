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