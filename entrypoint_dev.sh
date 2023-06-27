#!/bin/sh

mix setup

iex --sname cookie --cookie monster -S mix phx.server