SELECT author
 		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'benshapiro')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'benshapiro'),0),1)*1.0,3) AS benshapiro_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'BidenWatch')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'BidenWatch'),0),1)*1.0,3) AS conspiracy_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'Conservative')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'Conservative'),0),1)*1.0,3) AS conservative_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'conservatives')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'conservatives'),0),1)*1.0,3) AS conservatives_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'conspiracy')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'conspiracy'),0),1)*1.0,3) AS conspiracy_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'economy')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'economy'),0),1)*1.0,3) AS economy_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'Liberal')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'Liberal'),0),1)*1.0,3) AS liberal_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'politics')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'politics'),0),1)*1.0,3) AS politics_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'Republican')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'Republican'),0),1)*1.0,3) AS republican_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'republicans')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'republicans'),0),1)*1.0,3) AS republicans_ppd
		,ROUND(COUNT(title) FILTER (WHERE Subreddit = 'worldnews')*1.0 / COALESCE( NULLIF(COUNT(DISTINCT Day) FILTER (WHERE Subreddit = 'worldnews'),0),1)*1.0,3) AS worldnews_ppd
		-- ,ROUND(COUNT(ID)*1.0 / COUNT(DISTINCT split_part(url, '/', 3))*1.0,2) as "Posts per Site"  This Really skewed results, even with scaling
		,ROUND(COUNT(ID)*1.0 / COUNT(DISTINCT title),2) as "Cross-Posts"
		,ROUND(AVG(LENGTH(title)),2) AS "Avg Post Length"
		,COUNT(ID) num_posts
		,COUNT(Distinct Day) As num_days
			FROM (
SELECT *
		,split_part(permalink, '/', 3) AS Subreddit
		,to_timestamp(created)::date AS Day
FROM posts) as Subquery
GROUP BY author
ORDER BY COUNT(title)  DESC
