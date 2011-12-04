require 'rubygems'
require 'yaml'
require 'cinch'
require 'sequel'

link_match = /(https?:\/\/[^\s]+)/

bot_config = YAML.load_file 'config.yml'
server = bot_config.first.keys.first
  
DB = Sequel.sqlite(bot_config[0][server]['database'])

bot = Cinch::Bot.new do
  configure do |c|
    c.server = server
    c.user = bot_config[0][server]['user']
    c.realname = bot_config[0][server]['realname']
    c.nick = bot_config[0][server]['nick']
    c.channels = bot_config[0][server]['channels'].collect { |chan| '#' + chan }
  end
  
  # Saving all links in the db
  on :message, link_match do |m, link|
    if DB['SELECT count(*) FROM links WHERE href == ?', link] > 0
      oldlink = DB['SELECT nick FROM links WHERE href == ?', link].first
      if m.user.nick != oldlink[:nick]
        m.reply "Old! #{oldlink[:nick]} linked that like, ages ago"
      end
    else
      DB[:links].insert(
        :nick => m.user.nick,
        :href => link
      )
    end
  end
  
  # Random link from a specific nick
  on :message, /^!link ([^\s]+)/ do |m, nick|
    links = DB['SELECT * FROM links WHERE nick LIKE ?', nick]
    count = links.count
    
    if count == 0
      m.reply "#{m.user.nick}: Links from #{nick.downcase}, I found not."
      return
    end
    
    random_link = links.limit(1, rand(count)).first
    m.reply "#{m.user.nick}: <#{random_link[:nick]}> #{random_link[:href]}"
  end
  
  # Random link from anybody
  on :message, /^!link$/ do |m|
    count = DB[:links].count
    
    if count == 0
      m.reply "#{m.user.nick}: Seems the database is devoid of links!"
      return
    end
    
    random_link = DB[:links].limit(1, rand(count)).first
    m.reply "#{m.user.nick}: <#{random_link[:nick]}> #{random_link[:href]}"
  end
    
end

bot.start