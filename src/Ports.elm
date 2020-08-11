port module Ports exposing (..)

import Quote exposing (Quote)



-- 📣


port addQuote : Quote -> Cmd msg


port removeQuote : Quote -> Cmd msg


port saveSelectionHistory : List String -> Cmd msg


port signIn : () -> Cmd msg



-- 📰


port importedQuotes : (List Quote -> msg) -> Sub msg