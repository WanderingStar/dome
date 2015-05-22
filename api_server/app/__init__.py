import flask
from flask import Flask, jsonify, request, render_template, abort
import pymongo
from pymongo import MongoClient
import json
import time
import os

app = Flask(__name__)
db = MongoClient().project

def arg(request, name, default=None):
    if request.method == 'POST':
        if request.json:
            return request.json.get(name, default)
        elif 'json' in request.form:
            return json.loads(request.form['json']).get(name, default)
    if request.json:
        return request.json.get(name, default)
    query_param = request.args.get(name)
    if not query_param:
        return default
    try:
        return int(query_param)
    except ValueError:
        if query_param.find(","):
            return [k for k in query_param.split(",") if k and k != ""]
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

@app.route('/<int:post_id>/settings', methods=['POST', 'GET', 'PUT', 'DELETE'])
def post_settings(post_id):
    post = db.post.find_one({'id': post_id}, {'_id':0})
    if not post:
        abort(404)
    if request.method == 'POST':
        if request.json:
            settings = request.json
        elif 'json' in request.form:
            settings = json.loads(request.form['json'])
        db.post.update({'id': post_id}, {'$set': {'settings': settings}});
    return jsonify(post.get('settings',{}))

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

CONTENT_PATH = '/Users/project/dome/api_server/app/static/content'

def filename_from_id(id):
    match = '_%d_' % id
    for root, dirs, files in os.walk(CONTENT_PATH):
        for file in files:
            if match in file:
                response = os.path.join(root, file)
                return response[len(CONTENT_PATH):]

def fetch_history(offset=0, limit=10):
    history = []
    for played in db.history.find({}, {'_id':0}) \
                        .sort('start', pymongo.DESCENDING) \
                        .skip(offset).limit(limit):
        id = int(played['id'])
        played['post'] = db.post.find_one({'id': id}, {'_id':0})
        played['image'] = filename_from_id(id)
        history.append(played)
    return history

@app.route("/history", methods=['POST', 'GET'])
def history():
    # return the list of images that have been shown, and for how long
    #if request.json and request.json['
    offset = arg(request, 'offset', 0)
    limit = arg(request, 'limit', 10)
    if request.method == 'POST':
        if request.json:
            hist = request.json
        elif 'json' in request.form:
            hist = json.loads(request.form['json'])
        #app.logger.info("history: {}".format(hist))
        db.history.replace_one({'id': hist['id'], 'start': hist['start']}, hist, upsert=True)
    history = fetch_history(offset, limit)
    return jsonify({'history': history})

@app.route("/now.html", methods=['GET'])
def now():
    offset = arg(request, 'offset', 0)
    limit = arg(request, 'limit', 10)
    history = fetch_history(offset, limit)    
    return render_template('now.html', history=history)

@app.route("/play", methods=['POST', 'GET'])
def play():
    # set/get the keywords which will drive the display, use - to clear the keywords with a get
    playlist = db.playing.find_one({}, {'_id': 0})
    updated = False
    keywords = arg(request, 'keywords')
    if keywords:
        if keywords == ['-']:
            playlist['keywords'] = []
        else:
            playlist['keywords'] = keywords
        updated = True
    refresh = arg(request, 'refresh')
    if refresh:
        playlist['refresh'] = refresh
        updated = True
    if updated:
        playlist['updated'] = time.time()
        db.playing.replace_one({}, playlist, upsert=True)
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

app.debug = True


if __name__ == "__main__":
    app.debug = True
    app.run(host='0.0.0.0')
