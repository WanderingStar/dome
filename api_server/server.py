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

@app.route('/<int:post_id>/tags', methods=['POST', 'GET'])
def post_tags(post_id):
    # show the post with the given id, the id is a number
    app.logger.debug("%s form: %s\n    data: %s\n    json: %s" % 
                     (request.method, json.dumps(request.form), 
                      json.dumps(request.data), json.dumps(request.json)))

    post = db.post.find_one({'id': post_id}, {'_id':0})
    if not post:
        abort(404)

    if request.method == 'POST':
        if 'tags' in request.json:
            db.post.update({'id': post_id}, {'$set': {'tags' : request.json['tags']}})
    return jsonify(db.post.find_one({'id': post_id}, {'tags':1, '_id':0}))

@app.route("/posts", methods=['POST', 'GET'])
def posts():
    if request.json:
        tags = request.json.get('tags')
        offset = request.json.get('offset', 0)
        limit = request.json.get('limit', 10)
    else:
        tags = None
        offset = 0
        limit = 10

    query = {}
    if tags:
        query = {'tags': {'$all': tags}}
    posts = list(db.post.find(query, {'_id':0}).sort('id').skip(offset).limit(limit))
    count = db.post.find(query).count()
    app.logger.debug(posts)
    return jsonify({'posts': posts, 'count': count})

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
