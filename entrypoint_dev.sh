#!/bin/sh

cd chat_elixir

mix setup

elixir --sname cookie --cookie monster -S mix phx.server