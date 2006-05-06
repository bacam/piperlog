let rec foldlines channel f initial =
  let ml = try Some (input_line channel) with End_of_file -> None in
  match ml with None -> initial
              | Some l -> foldlines channel f (f initial l)

let commentary = Pcre.regexp "^\\s*(#.*)?$"

let foldfile filename f initial =
  let fin = open_in filename in
  let r = foldlines fin (fun a l -> if Pcre.pmatch ~rex:commentary l then a
                                      else (f a l)) initial in
  (close_in fin; r)

