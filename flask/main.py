from flask import Flask
from flask_cors import CORS

app = Flask(__name__)
application=app
CORS(app)

@app.route('/about')
def route():
    return "hello world ça marche"
if __name__ == '__main__':
    app.run(debug=True, port=5000)