#!/usr/bin/ruby
require 'sinatra'
require 'redcarpet'
require 'yaml'

#Config
$config = YAML.load_file('config.yaml')

#Set up Sinatra Config
set  :views => "#{settings.root}/#{$config['template-folder']}/",
:public_folder => "#{settings.root}/#{$config['template-folder']}/",
:static => true

markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)

#All Pages
get '/*' do
  begin
    path = params[:splat].join.split("/")

    #File or folder
    folder = "#{Dir.getwd}/#{$config['hierarchy-folder']}/#{params[:splat].join}"
    if File.directory?(folder) then
      file = "index"
    else
      folder.gsub!(/\/[^\/]+$/,"")
      file = path.pop
    end

    #Get children of current folder
    children = getChildren(folder)

    #Render Markdown
    folder_root = false;
    begin
      content = File.read("#{folder}/#{file}.#{$config['markdown-extension']}")
    rescue
      folder_root = true;
      content = ""
    end

    erb :template, :locals => {
      :siteTitle => $config['site-title'],
      :folder_root => folder_root,
      :currentFile => file,
      :path => path,
      :children => children,

      :content => markdown.render(content)
    }
  rescue StandardError => err
    erb :error, :locals => {
      :siteTitle => $config['site-title'],
      :error => err.to_s
    }
  end
end

#Children Array
def getChildren(folderPath)
  children = {
    :directories => [],
    :pages => []
  }

  #Loop through each child
  Dir.foreach(folderPath) do |child|
    # Skip if index or . or ..
    next if child.match(/^(\.+)$/)
    #Children folder or file
    if File.directory?("#{folderPath}/#{child}") then
      children[:directories].push(child)
    else
      #Throw away extension and push
      children[:pages].push(child.gsub!(/\.[^.]+$/, ''))
    end
  end

  children[:directories].sort!
  children[:pages].sort!

  return children
end
