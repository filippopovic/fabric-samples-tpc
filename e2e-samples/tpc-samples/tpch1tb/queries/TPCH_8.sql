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