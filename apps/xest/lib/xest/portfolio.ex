defmodule Xest.Portfolio do
  @moduledoc false

  # TODO  a way to organise:
  # - what is displayed and how, no matter the view
  # - what can be done with what is displayed
  # - the information that is relevant long term

  # IDEA :
  # a HODL list : currencies already owned, to hold onto (prevent inadvertent selling)
  # a SELL list : currencies sellable (ready to trade as quote -default- or base)
  # a BUY list : currencies that are buyable (ready to trade as quote -default- or base)
  # Note both sell and buy currencies are "tradable".
  # the list note the intent, waiting for an opportunity on the market...

  # This creates a NEW list of the list we dont currently HOLD and want to sell

  # Since it is an intent: the user must decide which currency goes into which list.
  # The list must be remembered between runs... stored into user account/portfolio/bot configuration ?

  # IDEA : 2 levels of user interactions/future bots
  # - one level waiting for the *best* time to sell / buy (currently the user, but to be replaced when possible)
  # - one level deciding what to sell / what to buy and on which exchange (currently the user)

  # HELD + KEEP -> HODL list
  # HELD + TRADE -> SELL list by default (BUY possible) + possible amount adjustment
  # NEW + TRADE -> BUY list by default (SELL possible) + possible amount adjustment
  # Stop condition for automatic exiting BUY and SELL list
  #  -> timeout
  #  -> market conditions...

  # NOTE :
  # - basic functionality first (check markets + spot trade).
  # - wide exchange compatibilty second (need more users !).
  # - detailed functionality (sub accounts, etc.) third.
end
