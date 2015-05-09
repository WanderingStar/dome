from flask import Flask
app = Flask(__name__)

@app.route("/")
def homepage():
    return "This is the API server"

if __name__ == "__main__":
    app.run(host='0.0.0.0')
    app.debug = True
    app.run()
