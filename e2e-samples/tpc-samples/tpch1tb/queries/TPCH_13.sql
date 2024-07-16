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