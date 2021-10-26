# Xest Umbrella Introduction

This is a detailed introduction to Xest Umbrella in order to:
- document the code, the design and the reasons why
- guide curious developers and newcomers
- limit frustrations and misunderstanding when working with Xest.

## Goals

- Human Interface to electronic assets, relying on online exchanges or offlines wallets.
- Discovering Elixir Strengths and Weaknesses, Develop Design Patterns for a real world application.
- Pushing Elixir to the limit with an application that can be considered critical in some settings.

## Overall Design

- A main 'Xest' app, containing the models and various design, aiming to be independent from any actual implementation, 
  and free of side-effects on the realworld. Goal is to maximize guarantees of the code there.
- A list of apps, like 'XestBinance', 'XestKraken' and more, interfacing Xest with the realworld, 
  as represented by the external systems we need to connect to in order to retrieve useful information
- A web interface 'XestWeb', providing a more "user-friendly" view of the information we have access to.

## Technical requirements

These are technical requirements.
Depending on resources available, we might want to increase or decrease these, to provide more or less guarantees.
A currently supported technical goal is indicated via a checkbox:

- [X] L0: A working Elixir LiveView webapp, giving a user a centralized view of his electronic assets, directly from the immediate information available on Exchanges and Wallets.
- [ ] L1: An event driven application, reconstructing the current state of the world via the list of events (transactions, etc.) recorded on Exchanges and Wallets.
- [ ] L2: An interactive Application, giving a user the possibility to execute transactions on Exchanges and Wallets.
- [ ] L3: An online application where multiple users can safely access information on their assets. Security is paramount here, so it will probably not happen without serious funding.


## Usage

A minimum of software development knowledge is required, or at least a willingness to dive into it and learn along the way.
In order to try Xest, the approach might depend if your primary interest is as a developer (focused on understanding how it all works), or as a user (focused on understanding how to use it)

