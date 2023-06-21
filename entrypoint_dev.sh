#!/bin/sh

mix setup

elixir --sname cookie --cookie monster -S mix phx.server