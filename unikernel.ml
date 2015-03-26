open Lwt
open V1_LWT
open Dns
open Dns_server

let port = 53
let zonefile = "test.zone"

module Main (C:CONSOLE) (K:KV_RO) (S:STACKV4) = struct

  module U = S.UDPV4
  module DNS = Dns_server_mirage.Make(K)(S)

  let ip_endpoint_to_string (ip,pt) =
  (Ipaddr.to_string ip)^":"^(string_of_int pt)

  let print_query c query = 
    let open Packet in
  	match query.questions with
  	| [] -> C.log_s c "QCOUNT = 0"
    | [q] -> C.log_s c (question_to_string q) 
    | _ -> C.log_s c "QCOUNT > 1"

  let print_answer c query = function 
  	| None -> C.log_s c "no answer"
    | Some answer ->
  		let response = Query.response_of_answer query answer in
    	C.log_s c (Packet.to_string response)


  let debug c process ~src ~dst packet =
  	C.log_s c ("src: "^ip_endpoint_to_string src)
  	>>= fun () -> 
  	C.log_s c ("dst: "^ip_endpoint_to_string dst)
  	>>= fun () ->
  	print_query c packet
    >>= fun () -> process ~src ~dst packet
    >>= (fun ans -> print_answer c packet ans
    	>>= fun () -> return ans)


  let start c k s =
    let t = DNS.create s k in
    DNS.eventual_process_of_zonefiles t [zonefile]
    >>= fun process ->
    let processor = (processor_of_process (debug c process) :> (module Dns_server.PROCESSOR)) in 
    DNS.serve_with_processor t ~port ~processor
end
