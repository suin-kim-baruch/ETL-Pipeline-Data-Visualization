DECLARE @MDATE DATETIME
		,@Cust VARCHAR(10)		
	SET @Cust = 0011223344
	SET @MDATE = (
			SELECT MAX(ACT_DATE)
	FROM [ivy.sd.fact.pos]
	WHERE shiptoparty = @Cust
			)
	WITH
		ft
		AS
		(
			SELECT T1.shiptoparty
			, T1.upc
			, t3.[description]
			, t3.company
			, t3.division
			, t1.act_date
			, sum(t1.gross_amt) sales
			, sum(t1.qty) qty
			FROM [ivy.sd.fact.pos] T1
				LEFT JOIN [ivy.mm.dim.shiptoparty_pos] T2 ON T1.shiptoparty = T2.shiptoparty
				LEFT JOIN [ivy.mm.dim.posupc] T3 ON T1.upc = T3.upc
			WHERE YEAR(@MDATE) - 1 <= YEAR(ACT_DATE)
				AND MONTH(act_date) <= MONTH(@MDATE)
				AND T1.shiptoparty = @Cust
			GROUP BY T1.shiptoparty
			,T1.upc
			,t3.[description]
			,t3.company
			,t3.division
			,t1.act_date
		)
		,
		yrsum
		AS
		(
			SELECT FT.UPC
			, FT.[description]
			, FT.company
			, FT.division
			, YEAR(FT.act_date) YR
			, SUM(FT.sales) YRSales
			, SUM(FT.qty) YRQty
			FROM FT
			GROUP BY FT.upc
			,YEAR(FT.act_date)
			,FT.[description]
			,FT.company
			,FT.division
		)
		,
		sum
		AS
		(
			SELECT t1.upc
			, T1.[description]
			, T1.company
			, T3.extmg
			, t1.YRSales LYSales
			, t2.YRSales CYSales
			, CASE 
				WHEN t1.YRSales IS NULL
					OR t1.YRSales = 0
					THEN 0
				ELSE (t2.YRSales - t1.YRSales) / t1.YRSales
				END AS YoYGrowthSales
			, t1.YRQty LYQty
			, t2.YRQty CYQty
			, CASE 
				WHEN t1.YRQty IS NULL
					OR t1.YRQty = 0
					THEN 0
				ELSE (t2.YRQty - t1.YRQty) / t1.YRQty
				END AS YoYGrowthQty
			FROM yrsum t1
				LEFT JOIN yrsum t2 ON t1.yr = t2.yr - 1
					AND t1.upc = t2.upc
				LEFT JOIN [ivy.mm.dim.div_pos] t3 ON t1.division = t3.division
		)
		,
		fpvt
		AS
		(
			SELECT *
			FROM (
			SELECT upc
				, act_date
				, sales
				FROM FT
			) t2
		pivot(sum(sales) FOR act_date IN (
					[2022-01-01]
					,[2022-02-01]
					,[2022-03-01]
					,[2022-04-01]
					,[2022-05-01]
					,[2022-06-01]
					,[2022-07-01]
					,[2022-08-01]
					,[2022-09-01]
					,[2022-10-01]
					,[2022-11-01]
					,[2022-12-01]
					
					)) pvt
		)
	SELECT t1.*
		, [2022-01-01]
		, [2022-02-01]
		, [2022-03-01]
		, [2022-04-01]
		, [2022-05-01]
		, [2022-06-01]
		, [2022-07-01]
		, [2022-08-01]
		,[2022-09-01]
					,[2022-10-01]
					,[2022-11-01]
					,[2022-12-01]
	FROM sum t1
		LEFT JOIN fpvt t2 ON t1.upc = t2.upc
	ORDER BY t1.CYSales DES