import flask
from flask import Flask, jsonify, request
import pymongo
from pymongo import MongoClient
import json
import time

app = Flask(__name__)
db = MongoClient().project

def arg(request, name, default=None):
    if request.json:
        return request.json.get(name, default)
    query_param = request.args.get(name)
    if not query_param:
        return default
    try:
        return int(query_param)
    except ValueError:
        if query_param.find(","):
            return query_param.split(",")
        return query_param

@app.route("/")
def homepage():
    return "This is the Project API server"

@app.route('/<int:post_id>')
def show_post(post_id):
    # show the post with the given id, the id is a number
    return jsonify(db.post.find_one({'id': post_id}, {'_id':0}))

@app.route('/<int:post_id>/keywords', methods=['POST', 'GET', 'PUT', 'DELETE'])
def post_keywords(post_id):
    # show or set the keywords associated with a post
    post = db.post.find_one({'id': post_id}, {'_id':0})
    if not post:
        abort(404)
    if request.method == 'PUT':
        keyword = request.json
        db.post.update({'id': post_id}, {'$addToSet': {'keywords' : keyword}})
    elif request.method == 'DELETE':
        keyword = request.json
        db.post.update({'id': post_id}, {'$pull': {'keywords' : keyword}})
    else:
        keywords = list(arg(request, 'keywords', []))
        if keywords:
            db.post.update({'id': post_id}, {'$set': {'keywords' : keywords}})
    return jsonify(db.post.find_one({'id': post_id}, {'keywords':1, '_id':0}))

@app.route("/posts", methods=['POST', 'GET'])
def posts():
    keywords = list(arg(request, 'keywords', []))
    offset = arg(request, 'offset', 0)
    limit = arg(request, 'limit', 10)

    query = {}
    if keywords:
        query = {'keywords': {'$all': keywords}}
    posts = list(db.post.find(query, {'_id':0}).sort('id').skip(offset).limit(limit))
    count = db.post.find(query).count()
    k_c = keyword_counts(keywords)
    for post in posts:
        p_k = set(post.get('keywords',[]))
        post['keyword_present'] = {k:k in p_k for k in db.post.distinct('keywords')}
    # app.logger.debug(posts)
    return jsonify({'posts': posts, 'count': count, 'keywords': k_c})

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
    return jsonify(keyword_counts(request.json and arg(request, 'keywords')))

@app.route("/history", methods=['POST', 'GET'])
def history():
    # return the list of images that have been shown, and for how long
    #if request.json and request.json['
    offset = arg(request, 'offset', 0)
    limit = arg(request, 'limit', 10)
    if request.method == 'POST':
        if request.json:
            db.history.insert(request.json)
    history = []
    for played in db.history.find({}, {'_id':0}) \
                        .sort('end', pymongo.DESCENDING) \
                        .skip(offset).limit(limit):
        played['post'] = db.post.find_one({'id': int(played['id'])}, {'_id':0})
        history.append(played)
    return jsonify({'history': history})

@app.route("/play", methods=['POST', 'GET'])
def play():
    # set/get the keywords which will drive the display, use - to clear the keywords with a get
    keywords = arg(request, 'keywords')
    if keywords:
        if keywords == ['-']:
            db.playing.replace_one({}, {'keywords': [], 'updated': time.time()}, upsert=True)
        else:
            db.playing.replace_one({}, {'keywords': sorted(list(keywords)), 'updated': time.time()}, upsert=True)
    playlist = db.playing.find_one({}, {'_id': 0})
    keywords = playlist.get('keywords')
    query = {}
    if keywords:
        query = {'keywords': {'$all': keywords}}
    ids = sorted([d['id'] for d in db.post.find(query, {'id':1, '_id':0})])
    playlist['ids'] = ids
    return jsonify(playlist)

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
