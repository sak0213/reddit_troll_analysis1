from _keys import db_user, db_password, db_name, db_host, db_port
import psycopg2
import pandas as pd
from nltk.corpus import stopwords
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
import pickle
stop=set(stopwords.words('english'))

with open('new_rand_clf_model.pkl', 'rb') as f:
    new_model = pickle.load(f)

with open('new_rand_clf_model_feature_names.pkl', 'rb') as f:
    main_features = pickle.load(f)

print("Assets Loaded")

conn = psycopg2.connect(dbname=db_name, user=db_user, password=db_password, host=db_host, port=db_port)
sql = """
select author, title, id 
from posts 
where author in (
	select author 
	from posts 
	group by author 
	having count(*) >= 20)
"""
cur = conn.cursor()
cur.execute(sql)
output = cur.fetchall()

authors = []
posts = []
post_ids = []
for i in range(len(output)):
    authors.append(output[i][0])
    posts.append(output[i][1])
    post_ids.append(output[i][2])
print("Posts Loaded")

cv = CountVectorizer(min_df=1, vocabulary=main_features)
word_count_vector = cv.fit_transform(posts)
tfid_transformer = TfidfTransformer(smooth_idf=True, use_idf=True)
tfid_transformer.fit(word_count_vector)
tf_idf_vectors = tfid_transformer.transform(word_count_vector)
feature_names = cv.get_feature_names_out()
df = pd.DataFrame(tf_idf_vectors.T.todense(), index=feature_names, columns=post_ids)
print("Dataframe Created")
df = df.T
df['___author'] = authors

df = df.reset_index()
df = df.rename(columns={'index':'post_id'})
print("DF Renamed")

X = df.drop(['___author', "post_id"], axis=1)
predictions = new_model.predict(X)
df['predictions'] = predictions
df_adjusted = df[['___author', 'predictions', 'post_id']]
print("Predictions Made. Saving to CSV")
df_adjusted.to_csv('current_post_predictions.csv')
print("CSV Saved")