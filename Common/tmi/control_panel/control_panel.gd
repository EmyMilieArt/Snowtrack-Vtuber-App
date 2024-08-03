extends VBoxContainer

@export var tmi: Tmi

const SAVE_DATA = "user://tmi.json"

func _ready():
	tmi.credentials_updated.connect(
		func (credentials):
			var f = FileAccess.open(SAVE_DATA, FileAccess.WRITE)
			f.store_string(credentials.to_json())
			f.close()
			
			%UserId.text = credentials.user_id
			%UserName.text = credentials.user_login
			%Token.text = credentials.token
			%RefreshToken.text = credentials.refresh_token
			%ClientId.text = credentials.client_id
			%ClientSecret.text = credentials.client_secret
			%Channel.text = credentials.channel
			%BroadcastUserId.text = credentials.broadcaster_user_id
	)
	tmi.credentials_updated.connect(
		func (credentials):
			if not credentials.token:
				return
			
			for c in %Rewards.get_children():
				c.queue_free()
				
			if credentials.broadcaster_user_id != credentials.user_id:
				return
				
			var res = await tmi.get_node("TwitchAPI").http(
				"channel_points/custom_rewards",
				{
					"broadcaster_id": credentials.broadcaster_user_id
				}
			)
			
			if res == null:
				return
			
			for reward in res.get("data", []):
				var id = LineEdit.new()
				id.editable = false
				id.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				id.text = reward.get("id")
				var title = Label.new()
				title.text = reward.get("title")
				title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				%Rewards.add_child(id)
				%Rewards.add_child(title)
	)
	
	var credentials = TwitchCredentials.load_from_file(SAVE_DATA)
	if credentials != null:
		tmi.login(credentials)

func _on_twitch_connection_status_changed(status):
	match status:
		Tmi.ConnectionStatus.IRC:
			%ConnectionStatus.text = "IRC"
		Tmi.ConnectionStatus.EVENTSUB:
			%ConnectionStatus.text = "EventSub"
		_:
			%ConnectionStatus.text = "Not Connected"

func _on_login_button_pressed():
	var credentials: TwitchCredentials
	if not %ClientId.text:
		credentials = TwitchCredentials.get_fallback_credentials()
	else:
		credentials = TwitchCredentials.new()
		credentials.client_id = %ClientId.text
		credentials.client_secret = %ClientSecret.text
	credentials.user_id = %UserId.text
	credentials.user_login = %UserName.text
	credentials.channel = %Channel.text
	
	await tmi.login(credentials)

func _on_client_id_text_changed(new_text):
	%UserId.editable = new_text == ""
	%UserName.editable = new_text == ""
	%Channel.editable = %ClientSecret.text != "" or new_text == ""

func _on_channel_text_submitted(new_text):
	pass # Replace with function body.


func _on_show_a_token_button_toggled(toggled_on):
	if toggled_on :
		%Token.secret = false
	else:
		%Token.secret = true


func _on_show_r_token_button_toggled(toggled_on):
	if toggled_on :
		%RefreshToken.secret = false
	else:
		%RefreshToken.secret = true


func _on_show_cid_token_button_toggled(toggled_on):
	if toggled_on :
		%ClientId.secret = false
	else:
		%ClientId.secret = true


func _on_show_cs_token_button_toggled(toggled_on):
	if toggled_on :
		%ClientSecret.secret = false
	else:
		%ClientSecret.secret = true