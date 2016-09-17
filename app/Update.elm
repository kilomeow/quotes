module Update exposing (..)

import Dict
import Material
import Maybe exposing (Maybe, withDefault)
import Navigation
import Time
import TouchEvents as TE exposing (Direction(..))

import Commands exposing (..)
import CSSModules
import Messages exposing (Msg(..))
import Model exposing (Model, UserDataModel, fromUserData, initialUserData)
import Quotes.Utils
import Routing exposing (Page(..), LocationResult, toPage)


type alias ProgramFlag =
  { cssmodules : Maybe CSSModules.Flag
  , userData : Maybe UserDataModel
  }



-- Model


updateModel : Msg -> Model -> (Model, Cmd Msg)
updateModel msg model =
  case msg of
    -- Pages
    GoToIndex ->
      model ! [Navigation.newUrl "/"]

    GoToSettings ->
      model ! [Navigation.newUrl "/settings"]

    -- Go fetch
    FetchSucceed collection ->
      let
        col = List.map Quotes.Utils.tupleToRecord collection
        ids = List.map (\q -> q.id) col
        see = model.collectionSeen
        len = (List.length ids) == 0
      in
        { model |
          collection = col
        , collectionIds = ids
        , collectionIsEmpty = len
        , fetchInProgress = False
        , fetchError = False
        }

        !

        [selectRandomQuote col see]

    FetchFail error ->
      let
        new = { model |
          fetchInProgress = False
        , fetchError = True
        }
      in
        new ! []

    -- User interactions
    SetCollectionUrl url ->
      let
        new = { model | collectionUrl = url }
      in
        new ! [keepState new, fetchQuotes new]

    -- Selection process
    SetSelectedQuote quote ->
      let
        new = { model |
          collectionSeen = Quotes.Utils.buildSeenList model quote
        , selectedQuote = if quote == Nothing then model.selectedQuote else quote
        }
      in
        new

        !

        if (quote == Nothing) && (model.collectionIsEmpty == False) then
          [keepState new, nextQuote new]
        else
          [keepState new]

    SelectRandomQuote ->
      let
        new = model
      in
        new ! [nextQuote new]

    -- Touch events
    OnTouchStart touchEvent ->
      let
        new = { model | touchPositionX = Just touchEvent.clientX }
      in
        new ! []

    OnTouchEnd touchEvent ->
      let
        stX = withDefault 0 model.touchPositionX
        enX = touchEvent.clientX
        dfX = abs (enX - stX)
        dir = TE.getDirectionX stX enX
        pge = model.page
        new = model
      in
        if (pge == Index) && (dfX > 50) && (dir == Left) then
          new ! [nextQuote new]
        else
          new ! []

    -- Material Design
    Mdl msg' ->
      Material.update msg' model


nextQuote : Model -> Cmd Msg
nextQuote model =
  selectRandomQuote model.collection model.collectionSeen



-- Navigation


urlUpdated : LocationResult -> Model -> (Model, Cmd Msg)
urlUpdated result model =
  { model | page = (toPage result) } ! []



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- Init


setInitialModel : ProgramFlag -> LocationResult -> (Model, Cmd Msg)
setInitialModel flag result =
  let
    model = toPage result
    |> Model.initial
    |> CSSModules.init flag.cssmodules
    |> fromUserData flag.userData
  in
    { model | fetchInProgress = True } !
    [ fetchQuotes model ]
