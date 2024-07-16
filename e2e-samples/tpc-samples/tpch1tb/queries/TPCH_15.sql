-- Query 15
SELECT
  S_SUPPKEY,
  S_NAME,
  S_ADDRESS,
  S_PHONE,
  total_revenue
FROM
  supplier,
  (
    SELECT
      L_SUPPKEY AS supplier_no,
      sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
    FROM
      lineitem
    WHERE
      L_SHIPDATE	>= '1997-03-01'
	    AND L_SHIPDATE	< dateadd(mm, 3, cast ('1997-03-01' as date))
    GROUP BY
      L_SUPPKEY
  ) AS revenue0
WHERE
  S_SUPPKEY = supplier_no
  AND total_revenue = (
    SELECT
      max(total_revenue)
    FROM
      (
        SELECT
          L_SUPPKEY AS supplier_no,
          sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS total_revenue
        FROM
          lineitem
        WHERE
          L_SHIPDATE >= '1997-03-01'
          AND L_SHIPDATE < '1997-06-01'
        GROUP BY
          L_SUPPKEY
      ) revenue0
  )
ORDER BY
  S_SUPPKEY
OPTION (LABEL = 'TPCH-Q15')