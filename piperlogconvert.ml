let extracrap = List.map (fun s -> (String.length s, s))
 ["^\\w{3} [ :0-9]{11} [._[:alnum:]-]+ ";
  "^\\w{3} [ :[:digit:]]{11} [._[:alnum:]-]+ "];;
let commentary = Pcre.regexp "^\\s*(#.*)?$"
(* Patterns like [:[:digit:]] with a leading : in the class appear to be
   forbidden in current versions of pcre.  (I'm not sure that they should be,
   though...) *)
let badclass = Pcre.regexp "\\[:([^\\]]*)\\[:([a-z]*):\\]"
let badclass' = Pcre.subst "[[:$2:]:$1"

let discard = Hashtbl.create 20;;

let discardname = ref "/etc/piperlog/discard" in
Arg.parse [
  ("--discard", Arg.Set_string discardname, "File of patterns to discard")
  ] (fun _ -> raise (Arg.Bad "Too many arguments"))
    "Usage: piperlog-convert [--discard <file name>]";

(* The logcheck files include patterns to match the date, time and host,
   so we need to strip that off.

   The "discard" file is in our format.
 *)

File.foldfile !discardname (fun () l -> Hashtbl.add discard l ()) ();;

let cut line =
  let rec cutup = function [] -> None | (extralen,extra)::t ->
    if String.length line > extralen && (String.sub line 0 extralen) = extra
    then Some ("^" ^ (String.sub line extralen (String.length line - extralen)))
    else cutup t
  in cutup extracrap
;;

try
while true do
  let l = read_line () in
  if Pcre.pmatch ~rex:commentary l then
    print_endline l
  else
  match cut l with
    Some cutline ->
      if Hashtbl.mem discard cutline
      then print_endline ("# discarded: " ^ cutline)
      else 
	let newline = Pcre.replace ~rex:badclass ~itempl:badclass' cutline in
	  print_endline newline
  | None ->
      (prerr_string "Dodgy: "; prerr_endline l)
done
with End_of_file -> ()
