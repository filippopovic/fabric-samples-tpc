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