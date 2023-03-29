MIX_ENV=test

mix deps.get

mix format

mix credo list

echo "\e[42mPress enter to continue\e[0m"

printf "%s"
read ans

mix test

echo "\e[42mAll good!\e[0m"