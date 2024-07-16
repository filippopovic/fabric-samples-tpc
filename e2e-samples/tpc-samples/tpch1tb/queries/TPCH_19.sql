-- Query 19
SELECT
  sum(L_EXTENDEDPRICE * (1 - L_DISCOUNT)) AS revenue
FROM
  lineitem,
  part
WHERE
  (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#55' -- [BRAND1]
    AND P_CONTAINER IN (
      'SM CASE',
      'SM BOX',
      'SM PACK',
      'SM PKG'
    )
    AND L_QUANTITY >= 9 -- [QUANTITY1]
    AND L_QUANTITY <= 9 + 10
    AND P_SIZE BETWEEN 1 AND 5
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#13' -- [BRAND2]
    AND P_CONTAINER IN (
      'MED BAG',
      'MED BOX',
      'MED PKG',
      'MED PACK'
    )
    AND L_QUANTITY >= 13 -- [QUANTITY2]
    AND L_QUANTITY <= 13 + 10
    AND P_SIZE BETWEEN 1 AND 10
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
  OR (
    P_PARTKEY = L_PARTKEY
    AND P_BRAND = 'Brand#22' -- [BRAND3]
    AND P_CONTAINER IN (
      'LG CASE',
      'LG BOX',
      'LG PACK',
      'LG PKG'
    )
    AND L_QUANTITY >= 20 -- [QUANTITY3]
    AND L_QUANTITY <= 20 + 10
    AND P_SIZE BETWEEN 1 AND 15
    AND L_SHIPMODE IN ('AIR', 'AIR REG')
    AND L_SHIPINSTRUCT = 'DELIVER IN PERSON'
  )
OPTION (LABEL = 'TPCH-Q19')