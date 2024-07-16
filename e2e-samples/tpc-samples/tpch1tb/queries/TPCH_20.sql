-- Query 20
SELECT
  S_NAME,
  S_ADDRESS
FROM
  supplier,
  nation
WHERE
  S_SUPPKEY IN (
    SELECT
      PS_SUPPKEY
    FROM
      partsupp
    WHERE
      PS_PARTKEY IN (
        SELECT
          P_PARTKEY
        FROM
          part
        WHERE
          P_NAME LIKE 'sky%' -- [COLOR]
      )
      AND PS_AVAILQTY > (
        SELECT
          0.5 * sum(L_QUANTITY)
        FROM
          lineitem
        WHERE
          L_PARTKEY = PS_PARTKEY
          AND L_SUPPKEY = PS_SUPPKEY
					AND L_SHIPDATE	>= '1997-01-01'
					AND L_SHIPDATE	< dateadd(yy,1,cast('1997-01-01' as date))
      )
  )
  AND S_NATIONKEY = N_NATIONKEY
  AND N_NAME = 'ARGENTINA' -- [NATION]
ORDER BY
  S_NAME
OPTION (LABEL = 'TPCH-Q20')