MIX_ENV=test

mix deps.get

mix format

mix hex.audit

MIX_ENV=dev mix dialyzer

echo "\e[42mPress enter to continue\e[0m"
printf "%s"
read ans

mix credo list

echo "\e[42mPress enter to continue\e[0m"
printf "%s"
read ans

mix test

MIX_ENV=dev

echo "\e[42mAll good!\e[0m"