require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'sinatra/reloader'

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

get('/teams/create') do
  slim(:"teams/create")
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


post('/users/logincalc') do
    username= params[:username]
    password= params[:password]
    db = SQLite3::Database.new('db/pokemon.db')
    db.results_as_hash = true
   
    if db.execute("SELECT * FROM Users WHERE username = ?",username).first == nil 
      #Användare finns inte 
      redirect('/')
    end
    
    result = db.execute("SELECT * FROM Users WHERE username = ?",username).first
    pwdigest = result["Pwdigest"]
    id = result["id"]
    name = result["Username"]
  
    
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id 
      session[:name] = name
      redirect('/home')
    else
      #redirect('/fel') - fixa felsida
    end
  end
