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

          get_user = "SELECT * FROM user WHERE username = \"" + request.json["username"] + "\""
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

  @app.route('/user/<string:username>',  methods=['GET', 'PUT'])
  @jwt_required()
  def profile(username):
    if request.method == 'GET':
      try:
        get_user = "SELECT * FROM user WHERE username = \"" + username + "\""
        cursor.execute(get_user)
        user_result = cursor.fetchall()[0]
        return jsonify(user_result)
      except Exception as e:
        return {"msg": str(e)}, 400
    elif request.method == 'PUT':
      try:
        first_name =  username, request.json["first_name"]
        last_name = username, request.json["last_name"]
        password = username, request.json["password"]

        cursor.callproc("update_user_firstName", first_name)
        cursor.callproc("update_user_lastName", last_name)
        cursor.callproc("update_user_password", password)
        db.commit()
        return {"message": "Successfully updated user: " + username}
      except Exception as e:
        return {"msg": str(e)}, 400

  @app.route("/logout", methods=["POST"])
  def logout():
    response = jsonify({"msg": "logout successful"})
    unset_jwt_cookies(response)
    return response

  @app.route("/user/<string:username>/trips", methods=['GET'])
  @jwt_required()
  def trips(username):
    if request.method == 'GET':
      try:
        cursor.callproc('get_trips', username)
        data = cursor.fetchall()
        return jsonify(data)
      except Exception as e:
        return {"msg": str(e)}, 400

  @app.route("/trip", methods=['POST'])
  @jwt_required()
  def create_trip():
    try:
      args = request.json["trip_name"], request.json["description"], request.json["city"], request.json["country"], request.json["start_date"], request.json["end_date"], request.json["trip_owner"]
      cursor.callproc("create_trip", args)
      db.commit()
      return {"message": "Successfully created trip: " + request.json["trip_name"]}
    except Exception as e:
      return {"msg": str(e)}, 400

  @app.route("/trip/<int:trip_id>", methods=['GET', 'PUT', 'DELETE'])
  @jwt_required()
  def trip(trip_id):
    if request.method == 'GET':
      try:
        cursor.callproc("get_trip_info", [trip_id])
        trip = cursor.fetchall()[0]
        print(trip)
        return jsonify(trip)
      except Exception as e:
        return {"msg": str(e)}, 400
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
