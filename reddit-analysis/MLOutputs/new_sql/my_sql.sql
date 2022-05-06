-- create posts table
create table sus_user_posts (
	author varchar(255)
	,author_fullname varchar(255)
	,author_flair_text varchar(255)
	,author_is_blocked varchar(255)
	,author_premium varchar(255)
	,can_mod_post bool
	,created_utm bigint
	,domain varchar(255)
	,id varchar(255)
	,is_created_from_ads_ui bool
	,is_crosspostable bool
	,is_meta bool
	,is_original_content bool
	,is_reddit_media_domain bool
	,is_robot_indexable bool
	,is_self bool
	,is_video bool
	,locked bool
	,over_18 bool
	,permalink varchar(255)
	,subreddit varchar(255)
	,subreddit_id varchar(255)
	,title text
	,url text)

-- inner joins on subqueries ----required for merging the posts and comments into events DB
select t1.author, t1.Num_Posts, t2.Num_Comments
from(
	select author, count(id) as Num_Posts
	from sus_user_posts
	group by author) as t1
Inner join (
	select author, count(comment_id) as Num_Comments
	from sus_user_comments 
	group by author) as t2 
on t1.author = t2.author
order by num_posts desc

---union for making events db referenced above
select *
from (
select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type
from sus_user_posts
where title !='This account is banned and is temporarily preserved for purposes of transparency.') as posts_aggregate
union
select *
from (
select author, comment_body as submission, created_utc as time_created, subreddit, 'comment' as submission_type
from sus_user_comments) as comments_aggregate

-- triple join
select sus_user_name, to_timestamp(account_created)::date as date_created, num_posts, num_comments from sus_users
inner join (
select t1.author as author, t1.num_posts as num_posts, t2.num_comments as num_comments
from(
	select author, count(id) as num_posts
	from sus_user_posts
	group by author) as t1
Inner join (
	select author, count(comment_id) as num_comments
	from sus_user_comments 
	group by author) as t2 on t1.author = t2.author ) as t3 on sus_user_name = t3.author

-- get the users who are in my normal user seed lists bot NOT in the sus user lists
select seed_posts_author
from normal_user_seed_posts l
where seed_posts_author not in ('[deleted]', 'AutoModerator') and not exists(
	select sus_user_name
	from sus_users
where sus_user_name = l.seed_posts_author)
group by seed_posts_author
-- ideal users for analysis (use this as a filter on ML)
select *
from (
select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'True' as is_bot
from sus_user_posts
where title !='This account is banned and is temporarily preserved for purposes of transparency.') as posts_aggregate
union
select *
from (
select author, comment_body as submission, created_utc as time_created, subreddit, 'comment' as submission_type, 'True' as is_bot
from sus_user_comments) as comments_aggregate
union
select *
from (
select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'False' as is_bot
from norm_user_posts) as comments_aggregate
where subreddit in ( 
	select subreddit
	from sus_user_posts
	inner join subreddit_info on sus_user_posts.subreddit = subreddit_info.subreddit_name
	where over18 = 'False'and subreddit not in ('u_reddit', 'funny', 'gifs', 'aww', 'AnimalsBeingBros', 'corgi', 'gif', 'cats', 'memes', 'pics', 'dogpictures', 'puppies', 'UpliftingNews', 'celebrities')
	group by subreddit
	order by count(*) desc
	limit 30)
--ideal users and aggregated data for ML
select author, string_agg(submission, ',') as user_doc, is_bot from
	(select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'True' as is_bot
		from sus_user_posts
		where title !='This account is banned and is temporarily preserved for purposes of transparency.') as posts_aggregate
	union
	select *
	from (
		select author, comment_body as submission, created_utc as time_created, subreddit, 'comment' as submission_type, 'True' as is_bot
		from sus_user_comments) as comments_aggregate
	union
	select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'False' as is_bot
		from norm_user_posts) as norm_posts_aggregate
	where subreddit in ( 
		select subreddit
		from sus_user_posts
		inner join subreddit_info on sus_user_posts.subreddit = subreddit_info.subreddit_name
		where over18 = 'False'and subreddit not in ('u_reddit', 'funny', 'gifs', 'aww', 'AnimalsBeingBros', 'corgi', 'gif', 'cats', 'memes', 'pics', 'dogpictures', 'puppies', 'UpliftingNews', 'celebrities')
		group by subreddit
		order by count(*) desc
		limit 30)) 
	as filtered
group by author, is_bot
having length(string_agg(submission, ',')) >=500
order by length(string_agg(submission, ',')) desc

-- ad hoc attempt to pivot in excel
select t1.author, subreddit, to_timestamp(time_created)::date as day_created, account_created, t1.is_bot from
	(select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'True' as is_bot
		from sus_user_posts
		where title !='This account is banned and is temporarily preserved for purposes of transparency.') as posts_aggregate
	union
	select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'False' as is_bot
		from norm_user_posts) as norm_posts_aggregate
	where subreddit in ( 
		select subreddit
		from sus_user_posts
		inner join subreddit_info on sus_user_posts.subreddit = subreddit_info.subreddit_name
		where over18 = 'False'and subreddit not in ('u_reddit', 'funny', 'gifs', 'aww', 'AnimalsBeingBros', 'corgi', 'gif', 'cats', 'memes', 'pics', 'dogpictures', 'puppies', 'UpliftingNews', 'celebrities')
		group by subreddit
		order by count(*) desc
		limit 30)) 
	as t1
inner join (
	select *
	from (
		select sus_user_name as author, account_created as account_created, 'True' as is_bot
		from sus_users
	) as sus_users
	union
	select  *
	from (
		select norm_user_name as author, account_created as account_created, 'False' as is_bot
		from norm_users
	) as norm_users
	)as t2 on t1.author = t2.author

--better ad hoc attempt with ACTUALLY only 30 subreddits
select t1.author, subreddit, to_timestamp(time_created)::date as post_created, account_created, t1.is_bot from
	(select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'True' as is_bot
		from sus_user_posts
		where title !='This account is banned and is temporarily preserved for purposes of transparency.') as posts_aggregate
	union
	select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 'False' as is_bot
		from norm_user_posts) as norm_posts_aggregate)	as t1
inner join (
	select *
	from (
		select sus_user_name as author, account_created as account_created, 'True' as is_bot
		from sus_users
	) as sus_users
	union
	select  *
	from (
		select norm_user_name as author, account_created as account_created, 'False' as is_bot
		from norm_users
	) as norm_users
	)as t2 on t1.author = t2.author
where subreddit in ( 
		select subreddit
		from sus_user_posts
		inner join subreddit_info on sus_user_posts.subreddit = subreddit_info.subreddit_name
		where over18 = 'False'and subreddit not in ('u_reddit', 'funny', 'gifs', 'aww', 'AnimalsBeingBros', 'corgi', 'gif', 'cats', 'memes', 'pics', 'dogpictures', 'puppies', 'UpliftingNews', 'celebrities')
		group by subreddit
		order by count(*) desc
		limit 30)
--tfid agg attempt
select author, round(avg(is_bot), 0), string_agg(submission, ',') as corpus from (
	select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 1 as is_bot
		from sus_user_posts
		where title !='This account is banned and is temporarily preserved for purposes of transparency.'
	limit 3000) as posts_aggregate
	union
	select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 0 as is_bot
		from norm_user_posts
	limit 3000) as norm_posts_aggregate ) as userbase
	group by author

	--alsdo for full corpus
select author, round(avg(is_bot), 0) as is_bot, lower(string_agg(submission, ',')) as corpus from (
	select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 1 as is_bot
		from sus_user_posts
		where author in (
			select distinct author from sus_user_posts limit 500)
	and subreddit !='u_reddit')as posts_aggregate
	union
	select *
	from (
		select author, title as submission, created_utm as time_created, subreddit, 'post' as submission_type, 0 as is_bot
		from norm_user_posts
		where author in (
			select distinct author from norm_user_posts limit 500)
	and subreddit !='u_reddit') as norm_posts_aggregate ) as userbase
	group by author
	order by length(string_agg(submission, ','))
	
	