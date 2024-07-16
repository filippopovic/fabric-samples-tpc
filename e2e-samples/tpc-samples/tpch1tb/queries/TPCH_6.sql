-- Query 6
SELECT
  sum(L_EXTENDEDPRICE * L_DISCOUNT) AS revenue
FROM
  lineitem
WHERE
  L_SHIPDATE	>= '1997-01-01'
	AND L_SHIPDATE	< dateadd (yy, 1, cast('1997-01-01' as date))
  AND L_DISCOUNT BETWEEN 0.08 - 0.01 AND 0.08 + 0.01 -- [DISCOUNT] +/- 0.01 - DISCOUNT is randomly selected within [0.02 .. 0.09]
  AND L_QUANTITY < 24 -- QUANTITY is randomly selected within [24 .. 25]
OPTION (LABEL = 'TPCH-Q6')