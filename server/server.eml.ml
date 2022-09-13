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
        <h1>Welcome To aHref Chat Group</h1>
        <p>Pick up from where you left off...</p>
        <div><span>Please Enter Your Name: </span> <span id="username" contenteditable="true">User</span><i class="fa fa-pencil"></i></div>
      </header>
      <section class="chatBlock">
        <div class="chatRoom" id="chatRoom">
          <ol class="chatList" id="chatList">
            <li><em>Bot: </em><span>Hello</span></li>
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

      <script>
        let username = document.getElementById("username");
        let message = document.getElementById("chatInput");
        let chatList = document.getElementById("chatList");
        let socket = new WebSocket("ws://" + window.location.host + "/websocket");

        socket.onmessage = function (event) {
          let li = document.createElement("li");
          let em = document.createElement("em");
          let span = document.createElement("span");
          em.textContent = `${username.textContent}: `;
          li.appendChild(em);
          span.textContent = event.data;
          li.appendChild(span);
          chatList.appendChild(li);
        };

        document.querySelector("form").onsubmit = function () {
          if (socket.readyState != WebSocket.OPEN)
            return false;
          if (!message.value)
            return false;

          socket.send(message.value);
          message.value = "";
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

  (* val get_time () *)
(* let receive client = Dream.receive client

let now = (new%js Js.date_now)##getTime  *)

let handle_client client =
  let client_id = track client in
  let rec loop () =
    match%lwt Dream.receive client with
    | Some message ->
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
  @@ Dream.log "Counter is now: %i" counter;
  @@ Dream.log "Client: %s" (Dream.client request);