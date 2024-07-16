-- Query 16
SELECT
  P_BRAND,
  P_TYPE,
  P_SIZE,
  count_big(DISTINCT PS_SUPPKEY) AS supplier_cnt
FROM
  partsupp,
  part
WHERE
  P_PARTKEY = PS_PARTKEY
  AND P_BRAND <> 'Brand#55' -- [BRAND]
  AND P_TYPE NOT LIKE 'STANDARD PLATED%' -- [TYPE]
  AND P_SIZE IN (
    47,
    11,
    39,
    5,
    23,
    43,
    35,
    28
  )
  AND PS_SUPPKEY NOT IN (
    SELECT
      S_SUPPKEY
    FROM
      supplier
    WHERE
      S_COMMENT LIKE '%Customer%Complaints%'
  )
GROUP BY
  P_BRAND,
  P_TYPE,
  P_SIZE
ORDER BY
  supplier_cnt DESC,
  P_BRAND,
  P_TYPE,
  P_SIZE
OPTION (LABEL = 'TPCH-Q16')