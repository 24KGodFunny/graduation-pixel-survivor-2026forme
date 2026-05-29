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
signal token_verify_failed()
signal map_record_submitted()
signal checkin_success()
signal checkin_failed(error: String)
signal monthly_checkin_received(dates: Array)

# API 配置 - 请根据实际部署地址修改
const API_BASE_URL = "http://localhost:8080"

# 登录状态
var is_logged_in: bool = false
var token: String = ""
var user_id: int = 0
var nickname: String = ""
var username: String = ""

# 当前请求类型（用于区分错误信号路由）
var _pending_request: String = ""
# 当前同步请求类型（用于区分上传/下载的错误信号路由）
var _pending_sync_request: String = ""

# HTTP 请求节点
var http_request: HTTPRequest
var sync_http_request: HTTPRequest
var record_http_request: HTTPRequest

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

	# 创建地图记录专用 HTTP 请求节点（fire-and-forget）
	record_http_request = HTTPRequest.new()
	record_http_request.timeout = 10.0
	add_child(record_http_request)
	record_http_request.request_completed.connect(_on_record_request_completed)

# 登录请求
func login(user: String, pwd: String):
	_pending_request = "login"
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
	_pending_request = "register"
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
	_pending_request = "user_info"
	var url = API_BASE_URL + "/api/game/user/info"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]

	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		print("获取用户信息失败")

# 提交通关/失败记录（fire-and-forget，不阻塞 UI）
func submit_map_record(record_data: Dictionary):
	if token == "":
		return
	var url = API_BASE_URL + "/api/game/map-record/submit"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	var body = JSON.stringify(record_data)
	record_http_request.request(url, headers, HTTPClient.METHOD_POST, body)

# 每日签到
func checkin():
	if token == "":
		return
	_pending_request = "checkin"
	var url = API_BASE_URL + "/api/game/checkin"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	http_request.request(url, headers, HTTPClient.METHOD_POST, "")

# 获取月度签到状态
func get_monthly_checkin(year: int, month: int):
	if token == "":
		return
	_pending_request = "monthly_checkin"
	var url = API_BASE_URL + "/api/game/checkin/monthly?year=%d&month=%d" % [year, month]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	http_request.request(url, headers, HTTPClient.METHOD_GET)

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

	# 根据请求类型处理响应
	if _pending_request == "login":
		# 登录成功
		if data is Dictionary:
			token = data.get("token", "")
			user_id = data.get("userId", 0)
			nickname = data.get("nickname", "")
			is_logged_in = true
			SaveManager.save_login_data(token, user_id, nickname, username)
			login_success.emit(data)
		else:
			login_failed.emit("登录响应格式错误")
	elif _pending_request == "register":
		# 注册成功
		register_success.emit(data if data is Dictionary else {})
	elif _pending_request == "user_info":
		# 用户信息
		if data is Dictionary:
			user_info_received.emit(data)
		else:
			print("用户信息响应格式错误")
	elif _pending_request == "checkin":
		checkin_success.emit()
	elif _pending_request == "monthly_checkin":
		var dates = []
		if data is Array:
			for d in data:
				dates.append(d)
		monthly_checkin_received.emit(dates)
	else:
		# 未知请求类型，尝试自动判断
		if data is Dictionary and data.has("token"):
			token = data.get("token", "")
			user_id = data.get("userId", 0)
			nickname = data.get("nickname", "")
			is_logged_in = true
			SaveManager.save_login_data(token, user_id, nickname, username)
			login_success.emit(data)
		else:
			register_success.emit(data if data is Dictionary else {})
	_pending_request = ""

# 处理错误
func _handle_error(error_msg: String):
	if _pending_request == "register":
		register_failed.emit(error_msg)
	elif _pending_request == "login":
		login_failed.emit(error_msg)
	elif _pending_request == "user_info":
		print("Token验证失败: ", error_msg)
		token_verify_failed.emit()
	elif _pending_request == "checkin":
		checkin_failed.emit(error_msg)
	elif _pending_request == "monthly_checkin":
		checkin_failed.emit(error_msg)
	else:
		if not is_logged_in:
			login_failed.emit(error_msg)
		else:
			print("网络错误: ", error_msg)
	_pending_request = ""

# 处理地图记录请求完成（fire-and-forget，仅打印日志）
func _on_record_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("地图记录提交失败: 网络错误")
		return
	if response_code == 200:
		map_record_submitted.emit()
	else:
		print("地图记录提交失败: HTTP ", response_code)

# 检查 sync_http_request 是否正在处理请求，如果是则先取消
func _cancel_pending_sync_request():
	if sync_http_request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		sync_http_request.cancel_request()

# 上传本地数据到服务器（从 GlobalSave 获取数据）
func sync_upload():
	if token == "":
		sync_upload_failed.emit("未登录")
		return
	_cancel_pending_sync_request()
	_pending_sync_request = "upload"
	var url = API_BASE_URL + "/api/game/sync/upload"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	var upload_data = {
		"saveData": GlobalSave.to_dict()
	}
	var body = JSON.stringify(upload_data)
	var error = sync_http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		sync_upload_failed.emit("请求发送失败")
		_pending_sync_request = ""

# 从服务器下载数据
func sync_download():
	if token == "":
		sync_download_failed.emit("未登录")
		return
	_cancel_pending_sync_request()
	_pending_sync_request = "download"
	var url = API_BASE_URL + "/api/game/sync/download"
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + token
	]
	var error = sync_http_request.request(url, headers, HTTPClient.METHOD_POST, "")
	if error != OK:
		sync_download_failed.emit("请求发送失败")
		_pending_sync_request = ""

# 处理同步请求完成
func _on_sync_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_sync_error("网络请求失败")
		return
	var json = JSON.new()
	var error = json.parse(body.get_string_from_utf8())
	if error != OK:
		_emit_sync_error("响应解析失败")
		return
	var response = json.data
	if not response is Dictionary:
		_emit_sync_error("无效的响应格式")
		return
	if response_code == 200:
		var data = response.get("data", {})
		if _pending_sync_request == "download":
			# 下载响应 —— 检查是否有云存档数据
			var save_data = data.get("saveData", null) if data is Dictionary else null
			if save_data is Dictionary:
				# 有云存档，应用到 GlobalSave
				GlobalSave.from_dict(save_data)
				sync_download_success.emit(data)
			else:
				# 无云存档，提示用户，不修改本地数据
				sync_download_failed.emit("当前用户没有云存档")
		else:
			# 上传响应
			sync_upload_success.emit()
	else:
		var msg = response.get("message", "请求失败")
		_emit_sync_error(msg)
	_pending_sync_request = ""

# 根据当前同步请求类型 emit 对应的错误信号
func _emit_sync_error(error_msg: String):
	if _pending_sync_request == "download":
		sync_download_failed.emit(error_msg)
	else:
		sync_upload_failed.emit(error_msg)

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
