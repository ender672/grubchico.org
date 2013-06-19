#!/bin/env ruby
require 'sqlite3'
require 'redcarpet/compat'
require 'yaml'

def old_path(row)
  "/news_items/#{row[0]}"
end

def new_local_path(row)
  "_posts/#{parsed_date(row).strftime '%Y-%m-%d'}-#{safe_title(row)}.html"
end

def new_web_path(row)
  "/#{parsed_date(row).strftime '%Y/%m/%d'}/#{safe_title(row)}.html"
end

def parsed_date(row)
  Date.parse(row[5])
end

def safe_title(row)
  row[1].gsub(/\W+/, '-').downcase
end

def html(row)
  Markdown.new(row[2]).to_html
end

def header(row)
  YAML.dump(
    'layout' => 'post',
    'title'  => row[1],
    'date'   => parsed_date(row)
  ) + "---\n"
end

def create_jekyll_post(row)
  File.open(new_local_path(row), 'w') do |f|
    f << header(row)
    f << html(row)
  end
end

def create_all_jekyll_posts(db)
  each_news_item(db){ |row| create_jekyll_post(row) }
end

def each_news_item(db)
  db.execute( "select * from news_items" ){ |row| yield row }
end

def add_s3_redirects(db)
  File.open('_jekyll_s3.yml', 'a') do |f|
    each_news_item(db) do |row|
      f << "  #{old_path(row)}: #{new_web_path(row)}\n"
    end
  end
end

db = SQLite3::Database.new "production.sqlite3"

add_s3_redirects(db)