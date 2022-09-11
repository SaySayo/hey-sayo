let home =
        <html>
        <body>
        <h1>Welcome to Hey Sayo </h1>
        <div id="message-container"> </div>
        <form id="send-container">
        <input type="text" id="message-input" size="60" autofocus>
        <button type="submit" id="send-button">Send</button>
        </form>
          <script>
          let message = document.getElementById("message");
          let message_container = document.getElementById("message-container");
          let message_form = document.getElementById("send-container");
          let message_input = document.getElementById("message-input");
          let chat = document.querySelector("body");
          let socket = new WebSocket("ws://" + window.location.host + "/websocket");
      
          socket.onopen = function () {
            socket.send("Hello?");
          };
      
          socket.onmessage = function (e) {
            let item = document.createElement("div");
            item.innerText = e.data;
            chat.appendChild(item)
            alert(e.data);
          };
      
          </script>
        </body>
        </html>
      
let () =
    Dream.run
    @@ Dream.logger
    @@ Dream.router [
      
        Dream.get "/"
            (fun _ ->
              Dream.html home);
      
        Dream.get "/websocket"
            (fun _ ->
              Dream.websocket (fun websocket ->
                match%lwt Dream.receive websocket with
                | Some "Hello?" ->
                  Dream.send websocket "Message received!"
                | _ ->
                  Dream.close_websocket websocket));
      
        ]