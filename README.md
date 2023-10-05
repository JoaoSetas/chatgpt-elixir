# ChatGPT elixir 

Simple application using the ChatGPT API with the autocomplete model to generate HTML from promp. Like articles, blog posts, etc. Even some html forms with validations.
A image is generated based on the second input box on the application.

`First input` is for the style of the html. Article seems to be the best option for almost every prompt.
`Second input` is for what's the content about
`Code input` is used to add more information like a piece of code

## Some prompt examples
* Create article
  * `First input` - Article
  * `Second input` - How to make elixir
* Create form
  * `First input` - Create login form
  * `Second input` - Create Users address with portugal cities select, postal code and phone number with pattern validation
* Documentation for code
  * `First input` - Article
  * `Second input` - With examples
  * `Code input` - [paste your code]

<img src="gif_example.gif" width="600" height="300"/>

# Installation with docker
## Clone the repo

```BASH
git clone https://github.com/JoaoSetas/chatgpt-elixir.git
```
## Configuring .env
Create the folder `.env` from the `.env.example`

#### `OPENAI_API_KEY`  - Get from https://beta.openai.com/account/api-keys

#### `SECRET_KEY_BASE` - Generate with:
```BASH
docker-compose run --rm phoenix_dev bash -c "echo 'SECRET_KEY_BASE:' & mix phx.gen.secret"
```
## Running the app
Start the containers
```BASH
docker-compose up -d
```
Now you should see the app in http://localhost:4000/
# Development
Checks before commit
```BASH
docker-compose run --rm phoenix_dev sh run-checks.sh
```
Get logs
```BASH
docker-compose logs -f
```
Connect to the container
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
dbg(variable)
```
It needed in the iex this command recompiles any changes 
```elixir
recompile
```