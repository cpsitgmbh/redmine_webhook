Redmine::Plugin.register :redmine_webhook do
  name 'Redmine Webhook plugin'
  author 'Nicole Cordes'
  description 'This plugin registers Git repositories (e.g. coming from GitLab) in projects'
  version '0.0.1'
  url 'http://gitlab.cps-projects.de/gitlab/redmine_webhook'
  author_url 'http://www.cps-it.de'
  settings :default => {'root_path' => '/home/redmine/repositories/'}, :partial => 'settings/redmine_webhook_settings'
end
