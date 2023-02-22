WITH CTE AS (
SELECT a.material, qty, b.brand, b.pu, COUNT(*) as cnt, b.ct
FROM [ivy.sd.fact.order] as a
	LEFT JOIN [ivy.mm.dim.mtrl] as b on a.material = b.material
	LEFT JOIN [ivy.mm.dim.shiptoparty] as c on a.shiptoparty = c.shiptoparty
WHERE b.salesdiv = 'div1' and a.act_date > = DATEADD(year ,DATEDIFF(year,0,GETDATE())-1,0) and gross_amt <> 0 and qty <> 0 and c.cg_key = 'TR' and b.pu = 'NPU' and b.brand = 'GF'
GROUP BY  a.material,qty, b.brand, b.pu, b.ct
),
CTE2 AS (
SELECT CTE.*, SUM(cnt) OVER (PARTITION BY material) as tot
FROM CTE
),
CTE3 AS (
SELECT *, ROUND(CTE2.cnt/CAST(CTE2.tot as float),5) as ratio
FROM CTE2
),
CTE4 AS (
SELECT *,
	CASE WHEN CTE3.qty > = CTE3.ct THEN	CTE3.ratio ELSE NULL END AS 'bigger'
FROM CTE3
GROUP BY CTE3.material, CTE3.qty, CTE3.brand, CTE3.pu, CTE3.cnt, CTE3.ct, CTE3.tot, CTE3.ratio
)
SELECT *, SUM(bigger) OVER (PARTITION BY material) subtotal
FROM CTE4
ORDER BY material, qty asc