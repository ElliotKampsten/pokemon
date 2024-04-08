require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'
require 'sinatra/flash'

enable :sessions

get('/') do
    slim(:start)
end

get('/users/register') do
    #stoppa in slim i users och fixa slimrouten
    slim(:register)
end

get('/users/login') do
    slim(:login)
end

get('/fel') do
    slim(:fel)
end

get('/pokemons/create') do
  slim(:"pokemons/create")
end

post('/users/store') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    db = SQLite3::Database.new('db/pokemon.db')

    if db.execute("SELECT * FROM Users WHERE Username = ?",username).first != nil 
        #Användarnamn finns redan
        redirect("/fel")
    end
  
    if password == password_confirm
      password_digest = BCrypt::Password.create(password)
      db.execute("INSERT INTO Users (Username,Pwdigest) VALUES (?,?)",username,password_digest)
      redirect('/')
  
    else
        "Lösenorden matchade inte!"
        #redirect to register?
    end

  end

get('/home') do
    slim(:home)
end

get('/pokemons/remove') do
  slim(:"pokemons/remove")
end

get('/pokemons') do
  slim(:"pokemons/index")
end

post('/pokemons/pokemonaddcalc') do

  #MÅSTE FIXA REDIRECT FÖR NÄR MAN REDAN HAR POKEMONEN

  enteredpokemon = params[:enteredpokemon].capitalize()
  db = SQLite3::Database.new('db/pokemon.db')
  db.results_as_hash = true
  
  
  if !db.execute('SELECT * FROM Pokemon WHERE Name == ?',enteredpokemon).first
    #pokemon was misspelled or invalid
    flash[:error] = "Pokemon was misspelled or is invalid"
    redirect("/pokemons/create")
  end

  pokemon_id = db.execute('SELECT * FROM Pokemon WHERE Name == ?', enteredpokemon).first["id"]
  user_id = session[:id]
  

  if db.execute('SELECT * FROM User_Pokemon WHERE User_id == ? AND Pokemon_id == ?',user_id,pokemon_id).first == nil
    #Does not exist already in users pokdex, the rel-table is empty, add pokemon
    db.execute("INSERT INTO User_Pokemon (User_id,Pokemon_id) VALUES (?,?)",user_id,pokemon_id)
    flash[:success] = "Pokemon was successfully added to your pokedex!"
    redirect("/pokemons/create")

  else
    flash[:error] = "Pokemon already exists in your pokedex!"
    redirect("/pokemons/create")
  end
end

post('/pokemons/pokemonremovecalc') do

  #MÅSTE FIXA REDIRECT FÖR NÄR MAN REDAN HAR POKEMONEN

  enteredpokemon = params[:enteredpokemon].capitalize()
  db = SQLite3::Database.new('db/pokemon.db')
  db.results_as_hash = true
  
  
  if !db.execute('SELECT * FROM Pokemon WHERE Name == ?',enteredpokemon).first
    #pokemon was misspelled or invalid
    flash[:error] = "Pokemon was misspelled or is invalid"
    redirect("/pokemons/remove")
  end

  pokemon_id = db.execute('SELECT * FROM Pokemon WHERE Name == ?', enteredpokemon).first["id"]
  user_id = session[:id]
  

  if db.execute('SELECT * FROM User_Pokemon WHERE User_id == ? AND Pokemon_id == ?',user_id,pokemon_id).first == nil
    #Does not exist already in users pokdex, the rel-table is empty, cant remove non-existent pokmon, redirect.
    flash[:error] = "Pokemon does not exist in your pokedex"
    redirect('/pokemons/remove')
  else
    db.execute('DELETE FROM User_Pokemon WHERE User_id == ? AND Pokemon_id == ?',user_id,pokemon_id)
    flash[:success] = "Pokemon was successfully removed from your pokedex!"
    redirect("/pokemons/remove")
  end
end

get('/logout') do 
  session[:id] = nil
  session[:name] = nil
  session[:is_admin] = false
  flash[:success] = "You have successfully logged out!"
  redirect('/')
end

get('/admons') do
  - if session[:is_admin] == true
    slim(:admons)

  else
      flash[:error] = "You dont have admin access"
      if session[:name]
        redirect('/home')
      else
        redirect('/')
      end
  end
end

post('/users/logincalc') do
    username= params[:username]
    password= params[:password]
    session[:is_admin] = false
    db = SQLite3::Database.new('db/pokemon.db')
    db.results_as_hash = true
   
    if db.execute("SELECT * FROM Users WHERE username = ?",username).first == nil 
      #Användare finns inte 
      flash[:error] = "User does not exist or information was spelled incorrectly"
      redirect('/')
    end
    
    result = db.execute("SELECT * FROM Users WHERE username = ?",username).first
    pwdigest = result["Pwdigest"]
    id = result["id"]
    name = result["Username"]

    if name == "Älg"
      session[:is_admin] = true
      flash[:notice] = "Current user is Admin"
    end
  
    
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id 
      session[:name] = name
      redirect('/home')
    else
      #redirect('/fel') - fixa felsida
    end
  end
