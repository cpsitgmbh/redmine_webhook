require 'redmine_webhook/git_adapter'

class WebhookController < ApplicationController
  unloadable

  skip_before_filter :verify_authenticity_token, :only => [:index]
  before_filter :verify_webhook
  accept_api_auth :index

  def index
    repository_url = @request['repository']['url'].split(':')
    repository_identifier = repository_url[1].gsub('/', '_').downcase.match(/[a-z0-9\-_]{1,255}/)[0]
    repository_path = Setting.plugin_redmine_webhook['root_path'].chomp('/') + '/' + repository_url[1]
    repository = RedmineWebhook::RedmineWebhook::Git.new(@request['repository']['url'], repository_path)
    commits = []
    unless repository.exists?
      repository.clone
      repository.revisions('', nil, nil).each do |revision|
        commits << {'message' => revision.message}
      end
    else
      unless @request['commits'].nil?
        commits = @request['commits']
      end
    end
    unless commits.empty?
      commits.each do |commit|
        scan_commit_for_issue_ids(commit['message']).each do |issue|
          project = find_project_by_issue_id(issue)
          if project
            unless project.repositories.detect{|repository| repository['identifier'] == repository_identifier}
              project_repository = Repository.factory('Git')
              project_repository.safe_attributes = {
                  'identifier' => repository_identifier,
                  'url' => repository_path
              }
              project_repository.project = project
              project_repository.save
            end
          end
        end
      end
    end
    repository.fetch
    Repository.find_all_by_identifier(repository_identifier).each do |repo|
      repo.fetch_changesets
    end
    render :text => 'OK'
    return
  end

  private

  def verify_webhook
    input = request.raw_post
    if input.empty?
      render :text => 'NO POST DATA'
      return
    end

    @request = ActiveSupport::JSON.decode(request.raw_post)
    if @request['repository'].nil? || @request['repository']['url'].nil?
      render :text => 'NO REPOSITORY'
      return
    end
  end

  def scan_commit_for_issue_ids(commit)
    ref_keywords = Setting.commit_ref_keywords.downcase.split(',').collect(&:strip)
    ref_keywords_any = ref_keywords.delete('*')
    # keywords used to fix issues
    fix_keywords = Setting.commit_fix_keywords.downcase.split(',').collect(&:strip)
    kw_regexp = (ref_keywords + fix_keywords).collect{|kw| Regexp.escape(kw)}.join('|')
    referenced_issues = []
    commit.scan(/([\s\(\[,-]|^)((#{kw_regexp})[\s:]+)?(#\d+(\s+@#{Changeset::TIMELOG_RE})?([\s,;&]+#\d+(\s+@#{Changeset::TIMELOG_RE})?)*)(?=[[:punct:]]|\s|<|$)/i) do |match|
      action, refs = match[2], match[3]
      next unless action.present? || ref_keywords_any
      refs.scan(/#(\d+)(\s+@#{Changeset::TIMELOG_RE})?/).each do |m|
        issue, hours = m[0].to_i, m[2]
        if issue
          referenced_issues << issue
        end
      end
    end
    referenced_issues
  end

  def find_project_by_issue_id(id)
    return nil if id.blank?
    project = nil
    issue = Issue.where(:id => id.to_i).first
    if issue
      project = issue.project
    end
    project
  end

end
