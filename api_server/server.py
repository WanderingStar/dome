import flask
from flask import Flask, jsonify, request
from pymongo import MongoClient
import json

app = Flask(__name__)
db = MongoClient().project

@app.route("/")
def homepage():
    return "This is the API server"

@app.route('/<int:post_id>')
def show_post(post_id):
    # show the post with the given id, the id is a number
    return jsonify(db.post.find_one({'id': post_id}, {'_id':0}))

@app.route('/<int:post_id>/keywords', methods=['POST', 'GET'])
def post_keywords(post_id):
    # show or set the keywords associated with a post
    post = db.post.find_one({'id': post_id}, {'_id':0})
    if not post:
        abort(404)
    if request.method == 'POST':
        if 'keywords' in request.json:
            db.post.update({'id': post_id}, {'$set': {'keywords' : request.json['keywords']}})
    return jsonify(db.post.find_one({'id': post_id}, {'keywords':1, '_id':0}))

@app.route("/posts", methods=['POST', 'GET'])
def posts():
    if request.json:
        keywords = request.json.get('keywords')
        offset = request.json.get('offset', 0)
        limit = request.json.get('limit', 10)
    else:
        keywords = None
        offset = 0
        limit = 10

    query = {}
    if keywords:
        query = {'keywords': {'$all': keywords}}
    posts = list(db.post.find(query, {'_id':0}).sort('id').skip(offset).limit(limit))
    count = db.post.find(query).count()
    keywords = keyword_counts(keywords)
    # app.logger.debug(posts)
    return jsonify({'posts': posts, 'count': count, 'keywords': keywords})

def keyword_counts(keywords=None):
    # return keyword->post count, limited to posts matching all of the given keywords
    pipeline = [
        {'$project': {'keywords':1}},
        {'$unwind': '$keywords'},
        {'$group': {'_id': '$keywords', 'count': {'$sum': 1}}},
        {'$sort': {'count': -1}}
    ]
    if keywords:
        pipeline.insert(0, {'$match': {'keywords': {'$all': keywords}}})
    counts = db.post.aggregate(pipeline)
    key_count = {d['_id']: d['count'] for d in counts}
    return key_count

@app.route("/keywords", methods=['POST', 'GET'])
def keywords():
    return jsonify(keyword_counts(request.json and request.json.get('keywords')))

@app.after_request
def add_cors(resp):
    """ Ensure all responses have the CORS headers. This ensures any failures are also accessible
        by the client. """
    resp.headers['Access-Control-Allow-Origin'] = flask.request.headers.get('Origin','*')
    resp.headers['Access-Control-Allow-Credentials'] = 'true'
    resp.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS, GET, PUT, DELETE'
    resp.headers['Access-Control-Allow-Headers'] = flask.request.headers.get( 
        'Access-Control-Request-Headers', 'Authorization' )
    # set low for debugging
    if app.debug:
        resp.headers['Access-Control-Max-Age'] = '1'
    return resp

if __name__ == "__main__":
    app.debug = True
    app.run(host='0.0.0.0')
