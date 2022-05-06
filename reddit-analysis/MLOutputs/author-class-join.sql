SELECT posts.author
	,title
	,split_part(permalink, '/', 3) AS subreddit
	,to_timestamp(created)::date AS day	
	,author_classes.class_num as class
	FROM posts
	
	INNER JOIN author_classes ON
	posts.author = author_classes.author
	
-- WHERE to_timestamp(created)::date < '2022-04-01'
-- and to_timestamp(created)::date >='2022-03-01'
	