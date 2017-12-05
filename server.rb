require "sinatra"
require "pg"
require "pry"

set :bind, '0.0.0.0'  # bind to all interfaces
set :views, File.join(File.dirname(__FILE__), "app", "views")


configure :development do
  set :db_config, { dbname: "movies" }
end



configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/actors' do
  @actors = db_connection { |conn| conn.exec("SELECT name,id FROM actors ORDER BY name ASC")}
  erb :actors
end

get '/actors/:id' do
  @actor_id = params[:id].to_i
  db_connection do |conn|
    @movies_with_role = conn.exec_params("SELECT movies.id, movies.title, cast_members.character FROM movies LEFT JOIN cast_members ON movies.id = cast_members.movie_id WHERE cast_members.actor_id = $1", [@actor_id])
    @actor = conn.exec_params("SELECT name FROM actors WHERE id =$1", [@actor_id])
  end
  erb :actor_page
end

get '/movies' do
  db_connection do |conn|
    @movies =  conn.exec_params("SELECT movies.title,movies.id,movies.year,movies.rating,studios.name AS studio ,genres.name AS genre FROM movies JOIN genres ON movies.genre_id = genres.id JOIN studios ON movies.studio_id = studios.id ORDER BY title ASC")
  end
  erb :movies
end

get '/movies/:id' do
  @movie_id = params[:id].to_i
  db_connection do |conn|
    @movie_info = conn.exec_params("SELECT movies.title, movies.year, movies.synopsis, genres.name AS genre, studios.name AS studio FROM movies LEFT OUTER JOIN genres ON movies.genre_id = genres.id LEFT OUTER JOIN studios ON movies.studio_id = studios.id WHERE movies.id =$1", [@movie_id])

    @cast_info = conn.exec_params("SELECT actors.id, actors.name AS actor, cast_members.character AS role FROM cast_members JOIN movies ON movies.id = cast_members.movie_id JOIN actors ON actors.id = cast_members.actor_id WHERE movies.id =$1", [@movie_id])
  end
  erb :movie_page
end
