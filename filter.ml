let arrayfind f a =
  let i = ref 0 in
  let l = Array.length a in
  while !i < l && not (f a.(!i)) do i := !i + 1 done;
  if !i != l then Some !i else None

let foldfor f initial n =
  let rec next acc i = if i = n then acc else next (f acc i) (i+1)
  in next initial 0

let rec listfind f l =
  match l with
    [] -> None
  | (h::t) -> (match f h with None -> listfind f t | v -> v)
;;

(* We retain a buffer of recent messages, and note whether they matched
   one of the "summarise" entries so that later matches to the same
   entry get included. *)

type msgrecord = Normal
               | Summarise of Pcre.regexp * string array

(* Put a message into the buffer (or increment the count against a
   matching message in the buffer).  If the buffer is full, we return
   the oldest message. *)
let pushmsg summarise (outbuffer, nextindex) (time,host,message) =
  let dupcheck (host,message) (_,host',message',record, _) =
    if host <> host' then false else
    match record with
      Normal -> message = message'
    | Summarise (rex, details') ->
        try
          let details = Pcre.extract ~rex:rex ~full_match:false message in
	  details = details'
	with Not_found -> false
  in match arrayfind (dupcheck (host,message)) outbuffer with
       Some i ->
         let (t,h,m,r,c) = outbuffer.(i) in
	 outbuffer.(i) <- (t,h,m,r,c+1);
	 None
     | None ->
         let (t,_,_,_,_) as old = outbuffer.(!nextindex) in
	 let trysummarise m r =
	   try Some (r, Pcre.extract ~rex:r ~full_match:false m)
	   with Not_found -> None
	 in
	 let record = match listfind (trysummarise message) summarise with
	                None -> Normal
	              | Some (rex,details) -> Summarise (rex,details)
         in
         outbuffer.(!nextindex) <- (time,host,message,record,1);
	 nextindex := (!nextindex + 1) mod Array.length outbuffer;
	 if t = "" then None else Some old



let print_line (t,h,s,record,count) =
  if t = "" then () else
  print_endline (t ^ " " ^ h ^ " " ^ s);
  if count > 1
    then match record with
      Normal -> Printf.printf "%s  repeated %d times.\n" t count
    | Summarise _ -> Printf.printf "%s  and %d similar entries.\n" t count
    else ()

let malformed = ref 0
let maxmalformed = 50
let print_malformed s =
  malformed := !malformed + 1;
  if !malformed = maxmalformed + 1
  then print_endline "* Too many malformed lines, suppressing rest."
  else begin
    if !malformed > maxmalformed
    then ()
    else print_string "Malformed log message: "; print_endline s
  end

let checkignore ignorable service m =
  let rs = Hashtbl.find_all ignorable service in
  if List.exists (fun r -> Pcre.pmatch ~rex:r m) rs then true else
  let rs' = Hashtbl.find_all ignorable "" in
  List.exists (fun r -> Pcre.pmatch ~rex:r m) rs'
  

(* Separate time, host and message, and find out the service if there is one. *)
let timehost_r = Pcre.regexp
  "^(\\S+ +\\S+ +\\S+) +(\\S+) +((?:([^ :[]+)(?:\\[[0-9]+\\])?:)?.*\\S)\\s*$";;

let filter ignorable outbuffer summaries s =
  try
    let parts = Pcre.extract ~rex:timehost_r s in
    let (time, host, message, service) =
    	  (parts.(1), parts.(2), parts.(3), parts.(4)) in
    if checkignore ignorable service message
    then () else
      match pushmsg summaries outbuffer (time, host, message) with
        None -> ()
      | Some v -> print_line v
  with Not_found -> print_malformed s
;;

(* Note the list reversal to ensure the regexps are in the same order as the
   file. *)
let readregexps filename =
  let addregexp a l =
    try (Pcre.regexp l)::a
    with Pcre.BadPattern (msg,pos) ->
      Printf.eprintf "Bad regexp: %s at position %d\n  %s\n%!" msg pos l;
      a
  in
  List.rev (File.foldfile filename addregexp [])
;;

(* Might be more efficient if stored (and updated) a list in the hash table,
   rather than using find_all above. *)
let grabservice = Pcre.regexp
  "^\\^([^ \\\\.\\[|(?*+{:]+)?(?:\\\\\\[\\[0-9\\]\\+\\\\\\])?:";;
let mkignore filename =
  let insert a l =
    let service = 
      try (Pcre.extract ~rex:grabservice ~full_match:false l).(0)
      with Not_found -> ""
    in try (Hashtbl.add a service (Pcre.regexp l); a)
       with Pcre.BadPattern (msg,pos) ->
         Printf.eprintf "Bad regexp: %s at position %d\n  %s\n%!" msg pos l;
         a
  in File.foldfile filename insert (Hashtbl.create 650)

let remaining_iter f (outbuffer, pos) =
  let l = Array.length outbuffer in
  for i = !pos to !pos + l - 1 do
    f outbuffer.(i mod l)
  done
;;

let usefile = Array.length Sys.argv > 1 in
let inchan = if usefile then open_in Sys.argv.(1) else stdin in
let ignorable = mkignore "ignore" in
let summarisable = readregexps "summarise" in
let outbuffer = (Array.make 25 ("", "", "", Normal, 0), ref 0) in
let linecount = ref 0 in
let processline l =
  linecount := !linecount + 1;
  filter ignorable outbuffer summarisable l
in
Pcre.foreach_line ~ic:inchan processline;
remaining_iter print_line outbuffer;
Printf.printf "\nSummary produced from %d lines of input by piperlog.\n" !linecount;
if usefile then close_in inchan else ();;
