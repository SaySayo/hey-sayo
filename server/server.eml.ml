let home =
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta http-equiv="X-UA-Compatible" content="IE=edge" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css" />
      <link rel="stylesheet" href="/static/style.css" />
      <title>Chat App</title>
    </head>
    <body>
      <header>
        <h1>Welcome To aHrefs Group Chat</h1>
        <p>Pick up from where you left off...</p>
      </header>
      <main>
        <section class="chat-block">
          <div class="username">
            <span class="username-desc">Username: </span> 
            <span class="username-title" id="username-title" contenteditable=true title="Click to edit">Click To Edit</span>
          </div>
          <div class="chat-room" id="chatRoom">
            <ol class="chat-list" id="chatList">
              <li>
                <span>
                  <span class="chat-sender">Bot: </span>
                  <span class="chat-msg">Hello there, you are very welcome! </span>
                </span>
                <i></i>
              </li>
            </ol>
          </div>
          <div class="chatInput">
            <form>
              <input id="chatInput" type="text" placeholder="Type here..." />
              <button type="submit" class="icons plane" id="chatSubmit">
                <i class="fa fa-send"></i>
              </button>
            </form>
          </div>
        </section>
      </main>

      <script>
        let username = document.getElementById("username-title");
        let chatList = document.getElementById("chatList");
        let messageElem = document.getElementById("chatInput");

        const createAndAddChat = (msg) => {
          let li = document.createElement("li");
              let chatWrapper = document.createElement("span");
              let chatSender = document.createElement("span");
              let chatMsg = document.createElement("span");
              let chatFeedback = document.createElement("i");
              chatSender.textContent = `${msg.sender}: `;
              chatMsg.textContent = msg.message;
              chatWrapper.appendChild(chatSender);
              chatWrapper.appendChild(chatMsg);
              chatSender.classList.add("chat-sender");
              chatMsg.classList.add("chat-msg");
              li.appendChild(chatWrapper);
              li.appendChild(chatFeedback);
              chatList.appendChild(li);
        }

        let socket = new WebSocket("ws://" + window.location.host + "/websocket");

        socket.onmessage = function (event) {
          let messages = document.querySelectorAll(".chat-msg");
          let exist = false;
          let recievedData = JSON.parse(event.data);
          messages.forEach((message, i) => {
            if(message.innerHTML.toLowerCase() === recievedData.message.toLowerCase()) {
              message.parentElement.nextElementSibling.classList.add("fa", "fa-check", "sent");
              exist = true;
            } 
          })

          if (exist === false) {
            createAndAddChat(recievedData);
          }
        };

        document.querySelector("form").onsubmit = function (e) {
          e.preventDefault();
          let message = messageElem.value;
          if (socket.readyState != WebSocket.OPEN)
            return false;
          if (!message)
            return false;

          let msg = {
            sender: username.textContent,
            message
          }

          createAndAddChat(msg);

          socket.send(JSON.stringify(msg));
          messageElem.value = "";
          return false;
        };
      </script>
    </body>
  </html>

let clients : (int, Dream.websocket) Hashtbl.t =
  Hashtbl.create 5

let track =
  let last_client_id = ref 0 in
  fun websocket ->
    last_client_id := !last_client_id + 1;
    Hashtbl.replace clients !last_client_id websocket;
    !last_client_id

let forget client_id =
  Hashtbl.remove clients client_id

let send message =
  Hashtbl.to_seq_values clients
  |> List.of_seq
  |> Lwt_list.iter_p (fun client -> Dream.send client message)

let handle_client client =
  let client_id = track client in
  let rec loop () =
    match%lwt Dream.receive client with
    | Some message ->
      Dream.log "Server recieved a message: %s" (message);
      let%lwt () = send message in
      loop ()
    | None ->
      forget client_id;
      Dream.close_websocket client
  in
  loop ()

let () =
  Dream.run 
  @@ Dream.logger 
  @@ Dream.router [
    Dream.get "/" (fun _ -> Dream.html home);

    Dream.get "/websocket"
      (fun _ -> Dream.websocket handle_client);

    Dream.get "/static/**" (Dream.static "./static");
  ]