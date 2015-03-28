#!/usr/bin/env ruby

require 'sinatra'
require 'httparty'
require 'redcarpet'
require 'ostruct'

require 'haml'
require 'sass'

require 'ap'
require 'pp'
require 'yaml'

# this auto-reloads files with changed mtime
Sinatra::Application.reset!

helpers do
  def http_status?(vhost)
    true if HTTParty.get("http://#{vhost}").code.to_s =~ /^2../
  end

  def build_vhost_list
    @vhosts = {}

    Dir["/etc/nginx/sites-enabled/*"].each do |file|
      next unless File.file?(file)

      File.open(file, 'r') do |file_contents|
        matches = file_contents.grep(/server_name.*;/)

        next if matches.nil?

        matches.inject(@vhosts) do |vhosts, match|
          vhost = match.gsub(/ *server_name */, '').gsub(/;$/, '').chomp

          next if vhost == 'index.localhost'

          vhosts[vhost] = http_status?(vhost) ? :success : :failure
          vhosts
        end
      end
    end
  end
end

before do
  build_vhost_list
end

set :haml, { :ugly=>true }

get '/css/:style.css' do
  scss :"#{params[:style]}"
end

get '/' do
  haml :index
end
