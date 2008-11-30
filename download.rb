#!/usr/bin/env ruby
require 'mechanize'
require 'wesabe'

settings = YAML.load_file('settings.yml')

def readline(prompt=nil, quiet=nil)
  system "stty -echo" if quiet
  print prompt if prompt
  gets.chomp
ensure
  if quiet
    system "stty echo"
    puts
  end
end

agent = WWW::Mechanize.new
agent.user_agent_alias = 'Windows IE 7'
page = agent.get('https://bankonline.nationwidebank.com/bankonline/downloadAccountActivity.do')

form = page.form('actionForm')
form.userName = settings['username']
page = form.submit

form = page.form('actionForm')
question = page.search('td.textBold:last').innerHTML.gsub(/&nbsp;/, '')
form.secretAnswer = readline("#{question}: ")
page = form.submit

form = page.form('actionForm')
form.password = readline('NW Bank password: ', :quiet)
page = form.submit

form = page.form('downloadActivityForm')
from_date = Date.today - readline('How many days to include: ').to_i
to_date = Date.today
form.from = from_date.strftime('%m/%d/%Y')
form.to = to_date.strftime('%m/%d/%Y')

username = readline('Wesabe username: ')
password = readline('Wesabe password: ', :quiet)
wesabe = Wesabe.new(username, password)

settings['accounts'].each do |account|
  form.number = account['account_id']
  export = form.submit

  acct = wesabe.accounts.find { |a| a.name == account['wesabe_name'] }
  upload = acct.new_upload
  upload.statement = export.body.strip
  upload.upload!
end

