(* 
let clients : (int, Dream.websocket) Hashtbl.t = Hashtbl.create 5

let track = 
  let last_client_id = ref 0 in 
  fun websocket -> 
    last_client_id := !last_client_id + 0;
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
  let rec loop () = match%lwt Dream.receive client with
    | Some message -> 
      let%lwt () = send message in 
      loop ()
    | None -> forget client_id;
      Dream.close_websocket client
    in 
  loop () *)