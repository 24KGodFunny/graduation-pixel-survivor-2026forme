extends Node
## NetworkManager autoload - handles HTTP requests to backend API

signal login_success(data: Dictionary)
signal login_failed(error: String)
signal register_success(data: Dictionary)
signal register_failed(error: String)
signal user_info_received(data: Dictionary)
signal sync_upload_success()
signal sync_upload_failed(error: String)
signal sync_download_success(data: Dictionary)
signal sync_download_failed(error: String)

# API 配置 - 请根据实际部署地址修改
const API_BASE_URL = "http://localhost:8080"

# 登录状态
var is_logged_in: bool = false
var token: String = ""
var user_id: int = 0
var nickname: String = ""
var username: String = ""

# HTTP 请求节点
var http_request: HTTPRequest
var sync_http_request: HTTPRequest

func _ready():
	# 创建 HTTP 请求节点
	http_request = HTTPRequest.new()
	http_request.timeout = 10.0
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# 创建同步专用 HTTP 请求节点
	sync_http_request = HTTPRequest.new()
	sync_http_request.timeout = 30.0
	add_child(sync_http_request)
	sync_http_request.request_completed.connect(_on_sync_request_completed)

# 登录请求
func login(user: String, pwd: String):
	username = user
	var url = API_BASE_URL + "/api/game/user/login"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"username": user,
		"password": pwd
	})
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		login_failed.emit("请求发送失败")

# 注册请求
func register(user: String, pwd: String, nick: String):
	var url = API_BASE_URL + "/api/game/user/register"
	var headers = ["Content-Type: application/json"]
	var body = JSON.stringify({
		"username": user,
		"password": pwd,
		"nickname": nick if nick != "" else user
	})
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		register_failed.emit("请求发送失败")

# 获取用户信息
func get_user_info():
	if token == "":
		return
	
	var url = API_BASE_URL + "/api/game/user/info"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("获取用户信息失败")

# 处理请求完成
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		_handle_error("网络请求失败")
		return
	
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		_handle_error("响应解析失败")
		return
	
	var response = json.data
	if not response is Dictionary:
		_handle_error("无效的响应格式")
		return
	
	# 根据响应码处理
	if response_code == 200:
		_handle_success_response(response)
	else:
		var msg = response.get("message", "请求失败")
		_handle_error(msg)

# 处理成功响应
func _handle_success_response(response: Dictionary):
	var data = response.get("data", {})
	
	# 判断是登录、注册还是用户信息响应
	if data.has("token"):
		# 登录成功
		token = data.get("token", "")
		user_id = data.get("userId", 0)
		nickname = data.get("nickname", "")
		is_logged_in = true
		SaveManager.save_login_data(token, user_id, nickname, username)
		login_success.emit(data)
	elif data.has("id") and data.has("username"):
		# 用户信息
		user_info_received.emit(data)
	elif response.has("message") and response["message"] == "注册成功":
		# 注册成功
		register_success.emit(data)
	else:
		# 通用成功
		if not is_logged_in:
			register_success.emit(data)

# 处理错误
func _handle_error(error_msg: String):
	if not is_logged_in:
		login_failed.emit(error_msg)
	else:
		print("网络错误: ", error_msg)

# 上传本地数据到服务器
func sync_upload(data: Dictionary):
	if token == "":
		sync_upload_failed.emit("未登录")
		return
	var url = API_BASE_URL + "/api/game/sync/upload"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	var body = JSON.stringify(data)
	var error = sync_http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		sync_upload_failed.emit("请求发送失败")

# 从服务器下载数据
func sync_download():
	if token == "":
		sync_download_failed.emit("未登录")
		return
	var url = API_BASE_URL + "/api/game/sync/download"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	var error = sync_http_request.request(url, headers, HTTPClient.METHOD_POST, "")
	if error != OK:
		sync_download_failed.emit("请求发送失败")

# 处理同步请求完成
func _on_sync_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		sync_upload_failed.emit("网络请求失败")
		return
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		sync_upload_failed.emit("响应解析失败")
		return
	var response = json.data
	if not response is Dictionary:
		sync_upload_failed.emit("无效的响应格式")
		return
	if response_code == 200:
		var data = response.get("data", {})
		# 判断是上传还是下载响应
		if data is Dictionary and data.has("coins"):
			# 下载响应
			sync_download_success.emit(data)
		else:
			# 上传响应
			sync_upload_success.emit()
	else:
		var msg = response.get("message", "请求失败")
		sync_upload_failed.emit(msg)

# 退出登录
func logout():
	is_logged_in = false
	token = ""
	user_id = 0
	nickname = ""
	username = ""
	SaveManager.clear_login_data()

# 使用保存的 token 尝试自动登录
func auto_login():
	var saved_token = SaveManager.get_saved_token()
	if saved_token != "":
		token = saved_token
		user_id = SaveManager.get_saved_user_id()
		nickname = SaveManager.get_saved_nickname()
		username = SaveManager.get_saved_username()
		is_logged_in = true
		# 验证 token 是否有效
		get_user_info()
		return true
	return false