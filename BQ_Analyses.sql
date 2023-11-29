CREATE OR REPLACE TABLE postgis.State_Results AS (

SELECT * FROM `postgis.State_BSL` as A
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_id25x3 FROM `postgis.all_25x3CN`) as B ON B.bsl_id25x3=A.BSL_ID --served 25x3
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwire25x3 FROM `postgis.all_25x3CN`  WHERE tech IN ('Fiber','DSL','Cable')) as C ON C.bsl_idwire25x3=A.BSL_ID --served wireline 25x3
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwireless25x3 FROM `postgis.all_25x3CN` WHERE tech ='Fixed Wireless') as D ON D.bsl_idwireless25x3=A.BSL_ID --served wireless 25x3
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_id100x20 FROM `postgis.all_25x3CN` WHERE mxadactdwn>=100 AND mxadactup>=20) AS E ON E.bsl_id100x20=A.BSL_ID --served100x20
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwire100x20 FROM `postgis.all_25x3CN` WHERE ((mxadactdwn>=100 AND mxadactup>=20) AND tech in ('Fiber','DSL','Cable'))) AS F ON F.bsl_idwire100x20=A.BSL_ID --served100x20 wireline
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwireless100x20 FROM `postgis.all_25x3CN` WHERE ((mxadactdwn>=100 AND mxadactup>=20) AND tech='Fixed Wireless')) AS G ON G.bsl_idwireless100x20=A.BSL_ID --served100x20 wireless
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_id100x100  FROM `postgis.all_25x3CN` WHERE mxadactdwn>=100 AND mxadactup>=100) AS H ON H.bsl_id100x100=A.BSL_ID --served100x100
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwire100x100  FROM `postgis.all_25x3CN` WHERE ((mxadactdwn>=100 AND mxadactup>=100) AND tech in ('Fiber','DSL','Cable'))) AS I ON I.bsl_idwire100x100=A.BSL_ID --served100x100 wireline
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwireless100x100  FROM `postgis.all_25x3CN` WHERE ((mxadactdwn>=100 AND mxadactup>=100) AND tech='Fixed Wireless')) AS J ON J.bsl_idwireless100x100=A.BSL_ID --served100x100 wireless
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_id1Gx1G  FROM `postgis.all_25x3CN` WHERE mxadactdwn>=1000 AND mxadactup>=1000) AS K ON K.bsl_id1Gx1G=A.BSL_ID --served1000x1000
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwire1Gx1G  FROM `postgis.all_25x3CN` WHERE ((mxadactdwn>=1000 AND mxadactup>=1000) AND tech in ('Fiber','DSL','Cable'))) AS L ON L.bsl_idwire1Gx1G=A.BSL_ID --served1000x1000 wireline
LEFT JOIN (SELECT DISTINCT BSL_ID as bsl_idwireless1Gx1G FROM `postgis.all_25x3CN` WHERE ((mxadactdwn>=1000 AND mxadactup>=1000) AND tech='Fixed Wireless')) AS M ON M.bsl_idwireless1Gx1G=A.BSL_ID --served1000x1000 wireless

--max wireline speeds, dwn and up
LEFT JOIN (select tbl2.bsl_id as maxwireBSL, tbl2.mxadactdwn as maxwiredown, max(tbl2.mxadactup) as maxwireup from 
(select bsl_id, max(mxadactdwn) as Value1 
from `postgis.all_25x3CN`
where (tech='Fiber' OR tech='DSL' OR tech='Cable')
group by bsl_id) tbl1 
inner join (Select * FROM `postgis.all_25x3CN` WHERE tech='Fiber' OR tech='DSL' OR tech='Cable')tbl2 on tbl2.bsl_id =tbl1.bsl_id and tbl2.mxadactdwn= tbl1.Value1
group by tbl2.bsl_id, tbl2.mxadactdwn) AS N ON N.maxwireBSL=A.BSL_ID

--max wireless speeds, dwn and up
LEFT JOIN (select tbl2.bsl_id as maxwirelessBSL, tbl2.mxadactdwn as maxwirelessdown, max(tbl2.mxadactup) as maxwirelessup from 
(select bsl_id, max(mxadactdwn) as Value1 
from `postgis.all_25x3CN`
where tech='Fixed Wireless'
group by bsl_id) tbl1 
inner join (Select * FROM `postgis.all_25x3CN` WHERE tech='Fixed Wireless')tbl2 on tbl2.bsl_id =tbl1.bsl_id and tbl2.mxadactdwn= tbl1.Value1
group by tbl2.bsl_id, tbl2.mxadactdwn) AS O ON O.maxwirelessBSL=A.BSL_ID

--unique number of providers >=25x3
LEFT JOIN (select distinct bsl_id as uniq25x3BSL, uniq25x3 FROM (select bsl_id,provider,count(distinct bsl_id) as ct, SUM(count(distinct bsl_id)) OVER(PARTITION BY bsl_id) as uniq25x3
FROM `postgis.all_25x3CN`
WHERE mxadactdwn>=25 and mxadactup>=3
GROUP BY bsl_id, provider)) P ON P.uniq25x3BSL=A.BSL_ID

--unique number of providers >=100x20
LEFT JOIN (select distinct bsl_id as uniq100x20BSL, uniq100x20 FROM (select bsl_id,provider,count(distinct bsl_id) as ct, SUM(count(distinct bsl_id)) OVER(PARTITION BY bsl_id) as uniq100x20
FROM `postgis.all_25x3CN`
WHERE mxadactdwn>=100 and mxadactup>=20
GROUP BY bsl_id, provider)) Q ON Q.uniq100x20BSL=A.BSL_ID

--unique number of providers >=100x100
LEFT JOIN (select distinct bsl_id as uniq100x100BSL, uniq100x100 FROM (select bsl_id,provider,count(distinct bsl_id) as ct, SUM(count(distinct bsl_id)) OVER(PARTITION BY bsl_id) as uniq100x100
FROM `postgis.all_25x3CN`
WHERE mxadactdwn>=100 and mxadactup>=100 
GROUP BY bsl_id, provider)) R ON R.uniq100x100BSL=A.BSL_ID 

--unique number of providers >=1000x1000
LEFT JOIN (select distinct bsl_id as uniq1Gx1GBSL , uniq1000x1000 FROM (select bsl_id,provider,count(distinct bsl_id) as ct, SUM(count(distinct bsl_id)) OVER(PARTITION BY bsl_id) as uniq1000x1000
FROM `postgis.all_25x3CN`
WHERE mxadactdwn>=1000 and mxadactup>=1000 
GROUP BY bsl_id, provider)) S ON S.uniq1Gx1GBSL=A.BSL_ID

);


--ADD ALL THE FORMATING FIELDS THAT State REQUESTED

ALTER TABLE postgis.State_Results
ADD COLUMN IF NOT EXISTS Served25x3 STRING,
ADD COLUMN IF NOT EXISTS ServedWireline25x3 STRING,
ADD COLUMN IF NOT EXISTS ServedWireless25x3 STRING,

ADD COLUMN IF NOT EXISTS Served100x20 STRING,
ADD COLUMN IF NOT EXISTS ServedWireline100x20 STRING,
ADD COLUMN IF NOT EXISTS ServedWireless100x20 STRING,

ADD COLUMN IF NOT EXISTS Served100x100 STRING,
ADD COLUMN IF NOT EXISTS ServedWireline100x100 STRING,
ADD COLUMN IF NOT EXISTS ServedWireless100x100 STRING,

ADD COLUMN IF NOT EXISTS Served1Gx1G STRING,
ADD COLUMN IF NOT EXISTS ServedWireline1Gx1G STRING,
ADD COLUMN IF NOT EXISTS ServedWireless1Gx1G STRING,

ADD COLUMN IF NOT EXISTS MaxDownWireline FLOAT64,
ADD COLUMN IF NOT EXISTS MaxUpWireline FLOAT64,

ADD COLUMN IF NOT EXISTS MaxDownWireless FLOAT64,
ADD COLUMN IF NOT EXISTS MaxUpWireless FLOAT64,

ADD COLUMN IF NOT EXISTS NumProviders25x3 INT64,
ADD COLUMN IF NOT EXISTS NumProviders100x20 INT64,
ADD COLUMN IF NOT EXISTS NumProviders100x100 INT64,
ADD COLUMN IF NOT EXISTS NumProviders1Gx1G INT64
;
UPDATE `postgis.State_Results` SET Served25x3 = 'Yes' WHERE bsl_id25x3 IS NOT NULL; 
UPDATE `postgis.State_Results` SET ServedWireline25x3 = 'Yes' WHERE bsl_idwire25x3 IS NOT NULL ;
UPDATE `postgis.State_Results` SET ServedWireless25x3 = 'Yes' WHERE bsl_idwireless25x3 IS NOT NULL ;

UPDATE `postgis.State_Results` SET Served100x20 = 'Yes' WHERE bsl_id100x20 IS NOT NULL ;
UPDATE `postgis.State_Results` SET ServedWireline100x20 = 'Yes' WHERE bsl_idwire100x20 IS NOT NULL ;
UPDATE `postgis.State_Results` SET ServedWireless100x20 = 'Yes' WHERE bsl_idwireless100x20 IS NOT NULL ;

UPDATE `postgis.State_Results` SET Served100x100 = 'Yes' WHERE bsl_id100x100 IS NOT NULL ;
UPDATE `postgis.State_Results` SET ServedWireline100x100 = 'Yes' WHERE bsl_idwire100x100 IS NOT NULL ;
UPDATE `postgis.State_Results` SET ServedWireless100x100 = 'Yes' WHERE bsl_idwireless100x100 IS NOT NULL ;

UPDATE `postgis.Staet_Results` SET Served1Gx1G = 'Yes' WHERE bsl_id1Gx1G IS NOT NULL ;
UPDATE `postgis.State_Results` SET ServedWireline1Gx1G = 'Yes' WHERE bsl_idwire1Gx1G IS NOT NULL ;
UPDATE `postgis.State_Results` SET ServedWireless1Gx1G = 'Yes' WHERE bsl_idwireless1Gx1G IS NOT NULL ;

--max down/up wireline
UPDATE `postgis.State_Results` SET MaxDownWireline = maxwiredown  WHERE maxwireBSL IS NOT NULL ;
UPDATE `postgis.State_Results` SET MaxUpWireline = maxwireup  WHERE maxwireBSL IS NOT NULL ;
--max down/up wireless
UPDATE `postgis.State_Results` SET MaxDownWireless = maxwirelessdown  WHERE maxwirelessBSL IS NOT NULL ;
UPDATE `postgis.State_Results` SET MaxUpWireless = maxwirelessup  WHERE maxwirelessBSL IS NOT NULL ;

--unique number of providers
UPDATE `postgis.State_Results` SET NumProviders25x3 = uniq25x3  WHERE uniq25x3BSL IS NOT NULL ;
UPDATE `postgis.State_Results` SET NumProviders100x20 = uniq100x20  WHERE uniq100x20BSL IS NOT NULL ;
UPDATE `postgis.State_Results` SET NumProviders100x100 = uniq100x100  WHERE uniq100x100BSL IS NOT NULL ;
UPDATE `postgis.State_Results` SET NumProviders1Gx1G = uniq1000x1000  WHERE uniq1Gx1GBSL IS NOT NULL ;
