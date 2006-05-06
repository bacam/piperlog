let extracrap = "^\\w{3} [ :0-9]{11} [._[:alnum:]-]+ ";;
let extralen = String.length extracrap;;
let discard = Hashtbl.create 20;;

(* The logcheck files include patterns to match the date, time and host,
   so we need to strip that off.

   The "discard" file is in our format.
 *)

File.foldfile "discard" (fun () l -> Hashtbl.add discard l ()) ();;

try
while true do
  let l = read_line () in
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
