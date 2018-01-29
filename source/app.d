import vibe.vibe;

void main()
{
	auto settings = new HTTPServerSettings;
	settings.port = 8006;
	settings.bindAddresses = ["::1", "127.0.0.1"];

	auto router = new URLRouter;
	router.get("*", serveStaticFiles("public"));
	router.get("/", &index);
	router.get("/ws", handleWebSockets(&getWS));
	listenHTTP(settings, router);

	logInfo("Please open http://127.0.0.1:8080/ in your browser.");
	runApplication();
}

// [sender, message]
string[2][] history = [["", "# Online-Rechner
## Polynomdivision
[http://www.arndt-bruenner.de/mathe/scripts/polynomdivision.htm](http://www.arndt-bruenner.de/mathe/scripts/polynomdivision.htm)

## Primfaktorzerlegung, ggT, kgV
[http://www.arndt-bruenner.de/mathe/scripts/primzahlen.htm](http://www.arndt-bruenner.de/mathe/scripts/primzahlen.htm)

## Wolframalpha (z.B. für Graphen, Nullstellen, Linearfaktorzerlegung)
[https://www.wolframalpha.com/](https://www.wolframalpha.com/)

## Inverse Matrix
[http://matrix.reshish.com/inverse.php](http://matrix.reshish.com/inverse.php)

## Alles zu Matrizen: (funktioniert sogar mit unbekannten)
[https://matrixcalc.org/de/](https://matrixcalc.org/de/)

# Beispiele für vollständige Induktion

[https://de.wikibooks.org/wiki/Aufgabensammlung_Mathematik:_Vollst%C3%A4ndige_Induktion](https://de.wikibooks.org/wiki/Aufgabensammlung_Mathematik:_Vollst%C3%A4ndige_Induktion)

[http://www.emath.de/Referate/induktion-aufgaben-loesungen.pdf](http://www.emath.de/Referate/induktion-aufgaben-loesungen.pdf)"]];
Task[] connected;

// client -> server packets:
//  (first packet) username string
//  {type:"message",msg:string}
// server -> client packets:
//  {type:"message",msg:string,sender:string}

void broadcast(string s)
{
	foreach_reverse (i, task; connected)
	{
		if (!task || !task.running)
		{
			connected[i] = connected[$ - 1];
			connected.length--;
			continue;
		}
		task.sendCompat(s);
	}
}

void getWS(scope WebSocket ws)
{
	logInfo("WebSocket Connection");
	bool inScope = true;
	scope (exit)
		inScope = false;
	string username = ws.receiveText.strip;
	if (!username.length)
		return;
	logInfo("username: %s", username);
	if (!ws.connected)
		return;
	auto t = runTask({
		while (inScope)
		{
			string s = receiveOnlyCompat!string;
			if (!inScope)
				break;
			ws.send(s);
		}
	});
	connected ~= t;
	while (ws.connected)
	{
		string s = ws.receiveText();
		logInfo("text: %s", s);
		Json val = parseJsonString(s);
		if ("type" !in val)
			continue;
		switch (val["type"].to!string)
		{
		case "message":
			string msg = val["msg"].to!string.strip;
			if (!msg.length)
				break;
			history ~= [username, msg];
			broadcast(Json(["type" : Json("message"), "msg" : Json(msg), "sender"
					: Json(username)]).toString);
			break;
		default:
			break;
		}
	}
	inScope = false;
	t.join();
}

void index(HTTPServerRequest req, HTTPServerResponse res)
{
	res.render!("chat.dt", history);
}
