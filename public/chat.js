/// @ts-check

var messages = document.getElementById("messages");
/**
 * @type {HTMLInputElement}
 */
var input = document.getElementById("input");
var hide = document.getElementById("hide");

/**
 * @type {WebSocket}
 */
var ws = null;

var hidden = 0;

var username;
while (!username)
	username = prompt("Enter Username", window.localStorage.getItem("username") || "Anon");
window.localStorage.setItem("username", username);

function hideHandler(e) {
	if (new Date().getTime() - hidden < 2000)
		return;
	if (e.code == "KeyA" && e.shiftKey) {
		hidden = new Date().getTime();
		hide.style.display = "";
		return true;
	}
}

function hideHide() {
	hide.style.display = "none";
}

document.onkeydown = function (e) {
	hideHandler(e);
};

input.onkeydown = function (e) {
	if (hideHandler(e))
		return;
	if ((e.code == "Enter" || e.code == "NumpadEnter") && !e.shiftKey) {
		var val = input.value;
		input.value = "";
		sendMessage(val);
	}
};

function addMessage(senderStr, messageStr) {
	var message = document.createElement("div");
	message.className = "message";
	var sender = document.createElement("div");
	sender.className = "sender";
	sender.textContent = senderStr;
	message.appendChild(sender);
	var msg = document.createElement("div");
	msg.className = "msg";
	msg.innerHTML = marked(messageStr, {
		sanitize: true
	});
	message.appendChild(msg);
	messages.appendChild(message);
	return message;
}

function sendMessage(msg) {
	if (ws && ws.readyState == WebSocket.OPEN)
		ws.send(JSON.stringify({
			type: "message",
			msg: msg
		}));
	else {
		setTimeout(function () {
			sendMessage(msg);
		}, 500);
	}
}

function connectWS() {
	ws = new WebSocket("ws" + (window.location.protocol == "https:" ? "s" : "") + "://" + window.location.host + "/ws");
	ws.onopen = function () {
		ws.send(username);
	};

	ws.onerror = function (e) {
		console.error(e);
		addMessage("system", "**Connection errored, retrying in 5s**");
		setTimeout(connectWS, 5000);
	}

	ws.onmessage = function (e) {
		var j = JSON.parse(e.data);
		switch (j.type) {
			case "message":
				addMessage(j.sender, j.msg);
				break;
		}
	}
}

connectWS();