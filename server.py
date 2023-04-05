from flask import Flask, request, jsonify, make_response
import json
from flask_cors import CORS

app = Flask(__name__)
CORS(app) # TODO specify origins maybe

@app.route('/register', methods=['POST'])
def register():
  data = request.json

  # TODO procedure here with try catch (error code)

  return jsonify(success=True)

# @app.route('/login', methods=['GET'])
# def login():

if __name__ == "__main__":
  app.run(port=8000, debug=True)
