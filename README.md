# ChatGPT elixir

Simple website using the ChatGPT API with the autocomplete model to generate HTML from promp. Like articles, blog posts, etc. Even some html forms with validations.
Also a image is generated from the second input.

## Some prompt examples
* Article
  * `First input` - Article
  * `Second input` - How to make elixir
* Create form
  * `First input` - Create login form
  * `Second input` - Create Users address with portugal cities select, postal code and phone number with pattern validation
* Documentation
  * `First input` - Documentation
  * `Second input` - this code. With examples
  * `Code input` - [paste your code]

<img src="gif_example.gif" width="600" height="300"/>

# Installation with docker
## Clone the repo

```BASH
git clone https://github.com/JoaoSetas/chatgpt-elixir.git
```
## Configuring .env
Create the folder `.env` from the example

#### `OPENAI_API_KEY`  - Get from https://beta.openai.com/account/api-keys

#### `SECRET_KEY_BASE` - Generate with:
```BASH
docker-compose run --rm phoenix_dev bash -c "echo 'SECRET_KEY_BASE:' & mix phx.gen.secret"
```
## Starting containers
Start the containers
```BASH
docker-compose up -d
```
Now you should see the homepage in http://localhost:4000/
# Development
Get logs
```BASH
docker-compose logs -f
```
Connect to elixir container
```BASH
docker-compose exec phoenix_dev bash
```
# Debug

Connect to the iex with 
```BASH
docker-compose exec phoenix_dev iex --sname console --cookie monster --remsh cookie
```
To debug in the iex put this in your code to break 
```elixir
require IEx; IEx.pry
```
It needed in the iex this command recompiles any changes 
```elixir
IEx.Helpers.recompile
```