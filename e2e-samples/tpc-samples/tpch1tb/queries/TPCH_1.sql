-- Query 1
SELECT
  L_RETURNFLAG,
  L_LINESTATUS,
  sum(L_QUANTITY) AS sum_qty,
  sum(L_EXTENDEDPRICE) AS sum_base_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS sum_disc_price,
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT) * (1 + L_TAX)) AS sum_charge,
  avg(L_QUANTITY) AS avg_qty,
  avg(L_EXTENDEDPRICE) AS avg_price,
  avg(L_DISCOUNT) AS avg_disc,
  count_big(*) AS count_order
FROM
  lineitem
WHERE
  L_SHIPDATE	<= dateadd(dd, -60, cast('1998-12-01'as date))
GROUP BY
  L_RETURNFLAG,
  L_LINESTATUS
ORDER BY
  L_RETURNFLAG,
  L_LINESTATUS
OPTION (LABEL = 'TPCH-Q1')