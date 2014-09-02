# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
RedmineApp::Application.routes.draw do
  match 'redmine_webhook', :to => 'webhook#index', :via => [:get, :post]
end