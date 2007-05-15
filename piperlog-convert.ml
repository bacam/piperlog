let extracrap = "^\\w{3} [ :0-9]{11} [._[:alnum:]-]+ ";;
let commentary = Pcre.regexp "^\\s*(#.*)?$"
let extralen = String.length extracrap;;
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

try
while true do
  let l = read_line () in
  if Pcre.pmatch ~rex:commentary l then () else
  if String.length l > extralen && (String.sub l 0 extralen) = extracrap
  then begin
    if Hashtbl.mem discard
         ("^" ^ (String.sub l extralen (String.length l - extralen)))
    then ()
    else (print_string "^";
          print_endline (String.sub l extralen (String.length l - extralen)))
  end
  else (prerr_string "Dodgy: "; prerr_endline l)
done
with End_of_file -> ()
