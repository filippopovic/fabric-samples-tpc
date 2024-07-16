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