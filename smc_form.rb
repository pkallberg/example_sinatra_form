require 'rubygems'
require 'sinatra'
#require 'sinatra_more' # glob all sinatra_more 
require 'sinatra_more/markup_plugin' # or require 'sinatra_more/markup_plugin' for precise inclusion
require 'haml'
#require 'datamapper'
require 'dm-core'
require 'dm-timestamps'
require 'dm-postgres-adapter'
require 'dm-migrations'
require 'pony'

SEND_TO = 'philip@cloud66.com'
Pony.options = {
  :via => :smtp,
  :via_options => {
    :address => 'smtp.sendgrid.net',
    :port => '587',
    :domain => 'testing.com',
    :user_name => ENV['SENDGRID_USERNAME'],
    :password => ENV['SENDGRID_PASSWORD'],
    :authentication => :plain,
    :enable_starttls_auto => true
  }
}

DataMapper::Logger.new($stdout, :debug)
#DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/smc_form.sqlite")
DataMapper::setup(:default, ENV['POSTGRESQL_URL'])

class SMCResponseForm
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime
  property :updated_at, DateTime

  property :tech_contact_name, Text, :required => true, :default => 'NULL'
  property :tech_contact_email, Text, :required => true, :default => 'NULL'
  property :tech_contact_phone, Text, :required => true, :default => 'NULL'
  property :lms_used, Text, :required => true, :default => 'NULL'
  property :other_lms_name, Text, :default => 'NULL'
  property :other_lms_version, Text, :default => 'NULL'
  property :lms_localhost, Text, :required => true, :default => 'NULL'
  property :lms_test_env, Text, :required => true, :default => 'NULL'

end

# perform basic sanity checks and initialize all relationships
# call this once you've defined all your models...
DataMapper.finalize

# create the table
#SMCResponseForm.auto_migrate! 
#drop & recreate db
SMCResponseForm.auto_upgrade!


configure do
	enable :dump_errors
	enable :logging
end

get '/' do
  
  haml :index
end

get '/success' do
	"success!"
end

post '/' do
  # params.each do |y|
  #   p y
  # end
	@results = SMCResponseForm.new params
  @results.created_at = Time.now
  @results.updated_at = Time.now

  if @results.save
    Pony.mail :to => SEND_TO,
        :from => 'SMC_FORM@singlemind.co',
        :subject => 'SMC_FORM',
        :body => "#{params.inspect}"

    "success!"
  else
    "fail! #{@results.errors.to_s}"
  end
  
	#haml :index
	#redirect "/success"
end

