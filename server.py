from flask import Flask, request, jsonify, make_response
import json
from flask_cors import CORS
from flask_jwt_extended import create_access_token, get_jwt, get_jwt_identity, unset_jwt_cookies, jwt_required, JWTManager
from datetime import datetime, timedelta, timezone
import pymysql

try:
  app = Flask(__name__)
  CORS(app)  # TODO specify origins maybe
  app.config["JWT_SECRET_KEY"] = "please-remember-to-change-me"
  app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=1)
  jwt = JWTManager(app)

  # TODO PUT BACK
  username = input("Enter your MySQL username: ")
  password = input("Enter your MySQL password: ")

  db = pymysql.connect(host="localhost",
                       user=username,
                       password=password,
                       database="trips") # TODO change to db name

  # prepare a cursor object using cursor() method
  cursor = db.cursor(pymysql.cursors.DictCursor)

  @app.after_request
  def refresh_expiring_jwts(response):
    try:
      exp_timestamp = get_jwt()["exp"]
      now = datetime.now(timezone.utc)
      target_timestamp = datetime.timestamp(now + timedelta(minutes=30))
      if target_timestamp > exp_timestamp:
        access_token = create_access_token(identity=get_jwt_identity())
        data = response.get_json()
        if type(data) is dict:
          data["access_token"] = access_token
          response.data = json.dumps(data)
      return response
    except (RuntimeError, KeyError):
      # Case where there is not a valid JWT. Just return the original response
      return response

  @app.route('/register', methods=['POST'])
  def register():
    try:
      args = request.json["username"], request.json["password"], request.json["first_name"], request.json["last_name"], request.json["email"]
      cursor.callproc("create_user", args)
      db.commit()
      return {"msg": "Successfully registered user: " + request.json["username"]}
    except Exception as e:
      return {"msg": str(e)}, 400

  @app.route('/login', methods=['POST'])
  def login():
    try:
      username = request.json["username"]
      args = username, request.json["password"]
      cursor.callproc('check_login_exists', args)
      data = cursor.fetchall()

      if data[0]['@numrows'] == 1:
        try:
          access_token = create_access_token(identity=username)

          get_user = "SELECT * FROM user WHERE username = \""  + request.json["username"] + "\""
          cursor.execute(get_user)

          user_result = cursor.fetchall()[0]
          user_result["access_token"] = access_token

          return jsonify(user_result)
        except Exception as e:
          return {"msg": str(e)}, 400
      else:
        return {"msg": "Incorrect username or password"}, 400
    except Exception as e:
      return {"msg": str(e)}, 400

  @app.route('/profile',  methods=['GET', 'PUT'])
  @jwt_required()
  def profile():
    if request.method == 'GET':
      response_body = {
        "username": "test",
        "password" :"test",
        "first_name": "test_first",
        "last_name": "test_last",
        "email": "test@email.com"
      }
      # TODO procedure
      return response_body
    elif request.method == 'PUT':
      # TODO procedure here with try catch (error code)
      return {"message": "updated profile successfully!"}

  @app.route("/logout", methods=["POST"])
  def logout():
    response = jsonify({"msg": "logout successful"})
    unset_jwt_cookies(response)
    return response

  @app.route("/user/<string:username>/trips", methods=['GET'])
  @jwt_required()
  def trips(username):
    response_body = [
      {
        "trip_id": "1",
        "trip_name": "Dummy Trip Name",
        "description": "Dummy Description",
        "city": "Boston",
        "country": "United States",
        "start_date": "2023-04-01",
        "end_date": "2023-04-05"
      },
      {
        "trip_id": "2",
        "trip_name": "Dummy Trip Name 2",
        "description": "Dummy Description 2",
        "city": "Boston",
        "country": "United States",
        "start_date": "2023-04-03",
        "end_date": "2023-04-10"
      }
    ]
    # TODO procedure: find all trips for username, error if given undefined

    if username != "undefined":
      return response_body
    else:
      # TODO error
      return jsonify(success=False)

  @app.route("/trip", methods=['POST'])
  @jwt_required()
  def create_trip():
    data = request.json

    # TODO procedure here with try catch (error code)

    return data

  @app.route("/trip/<int:trip_id>", methods=['GET', 'PUT', 'DELETE'])
  @jwt_required()
  def trip(trip_id):
    if request.method == 'GET':
      response_body = {
        "trip_id": "1",
        "trip_name": "Dummy Trip Name",
        "description": "Dummy Description",
        "city": "Boston",
        "country": "United States",
        "start_date": "2023-04-01",
        "end_date": "2023-04-05",
        "trip_owner": "test",
        "attendees": [
          {
            "attendee": "test1"
          },
          {
            "attendee": "test2"
          }
        ]
      }

      # TODO procedure here

      return response_body
    elif request.method == 'PUT':
      return {"message": "updated trip successfully!"}
    elif request.method == 'DELETE':
      return {"message": "deleted trip successfully!"}

  @app.route("/trip/<int:trip_id>/expenses", methods=['GET'])
  @jwt_required()
  def expenses(trip_id):
    if request.method == 'GET':
      response_body = [
        {
          "expense_id": "1",
          "expense_name": "Dummy Expense Name",
          "total_cost": 50,
          "amount_owed": 0,
          "transaction_completed": 1,
          "expense_owner": "test"
        },
        {
          "expense_id": "2",
          "expense_name": "Dummy Expense Name 2",
          "total_cost": 100,
          "amount_owed": 50,
          "transaction_completed": 0,
          "expense_owner": "test2",
          "accomodation": {
            "address": "123 Street Boston, MA 02118",
            "start_date": "2023-04-10",
            "end_date": "2023-04-12"
          }
        }
      ]

      # TODO procedure here

      return response_body

  @app.route("/expense/<int:expense_id>", methods=["DELETE", "PUT"])
  def expense(expense_id):
    if request.method == 'DELETE':
      return {"message": "deleted expense successfully!"}
    elif request.method == 'PUT':
      username = request.json["username"]
      print(username)
      return {"message": "updated expense successfully!"}

  @app.route("/expense", methods=['POST'])
  @jwt_required()
  def create_expense():
    data = request.json

    # TODO procedure here with try catch (error code)

    return {"message": "created expense successfully!"}
except Exception as e:
  print(e)

if __name__ == "__main__":
  app.run(port=8000, debug=True)
