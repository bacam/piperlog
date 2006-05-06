val foldlines  : in_channel -> ('a -> string -> 'a) -> 'a -> 'a
val commentary : Pcre.regexp
val foldfile   :     string -> ('a -> string -> 'a) -> 'a -> 'a
