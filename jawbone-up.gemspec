Gem::Specification.new do |s|
  s.name        = 'jawbone-up'
  s.version     = '0.0.6'
  s.date        = '2013-08-13'
  s.homepage    = 'https://github.com/aaronpk/jawbone-up-ruby'
  s.summary     = "Client for the Jawbone UP service"
  s.description = "A client for the Jawbone UP service, as discovered by http://eric-blue.com/projects/up-api/"
  s.authors     = ["Aaron Parecki", "Ryan Frantz"]
  s.email       = 'aaron@parecki.com'
  s.files       = [
    "lib/jawbone-up.rb",
    "lib/jawbone-up/response.rb",
    "lib/jawbone-up/session.rb",
    "lib/jawbone-up/error.rb",
    "lib/jawbone-up/config.rb"
  ]
  s.add_dependency 'json'
  s.add_dependency 'rest-client'
end
