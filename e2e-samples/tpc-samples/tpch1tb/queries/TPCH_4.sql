-- Query 4
SELECT
  O_ORDERPRIORITY,
  count_big(*) AS order_count
FROM
  orders
WHERE	
  O_ORDERDATE	>= '1997-03-01' AND
	O_ORDERDATE	< dateadd (mm, 3,  cast ('1997-03-01' as date)) 
  AND EXISTS (
    SELECT
      *
    FROM
      lineitem
    WHERE
      L_ORDERKEY = O_ORDERKEY
      AND L_COMMITDATE < L_RECEIPTDATE
  )
GROUP BY
  O_ORDERPRIORITY
ORDER BY
  O_ORDERPRIORITY
OPTION (LABEL = 'TPCH-Q4')