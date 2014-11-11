class S2bIssuesController < S2bApplicationController
  
  before_filter :set_related_data => [:get_data]
  before_filter :set_issue, :only => [:destroy, :update, :update_status, :update_version, :update_progress, :get_files, :upload_file]
  
  before_filter lambda { validate_permission_for?(:edit) }, :only => [:index, :update]
  before_filter lambda { validate_permission_for?(:view) }, :only => [:index]

  def index
  end
  
  def get_data
    @versions =  opened_versions_list
    @priority = IssuePriority.all
    @tracker = Tracker.all
    @status = IssueStatus.where("id IN (?)" , DEFAULT_STATUS_IDS['status_no_start'])
    @issues = opened_versions_list.first.fixed_issues
    @issues_backlog = Issue.where(:fixed_version_id => nil).where("project_id IN (?)",@hierarchy_project_id)
    render :json => {:versions => @versions, :issues => @issues, :issues_backlog => @issues_backlog, :tracker => @tracker, :priority => @priority, :status => @status, :members => @members, :status_ids => DEFAULT_STATUS_IDS}
  end
  
  def get_issues_version
    version = Version.find(params[:version_id])
    @issues = version.fixed_issues # <- not too useful
    render :json => {:issues => @issues}
  end

  def get_issues_backlog
    @issues = version.fixed_issues # <- not too useful
    render :json => {:issues => @issues}
  end
  
  def create
    issue = Issue.new(issue_params)
    if issue.save
      render :json => {:result => "create_success", :issue => issue}
    else
      render :json => {:result => issue.errors.full_messages}
    end
  end

  def destroy
    if @issue.present? && @issue.destroy
      render :json => {result: "success"}
    else
      render :json => {result: "error", message: @issue.nil? ? "Invalid Issue!" : @issue.errors.full_messages}
    end
  end

  def update
    if @issue.present? && @issue.update_issue(issue_params, STATUS_IDS)
      render :json => {result: "edit_success", issue: @issue}
    else
      render :json => {result: "error", message: @issue.nil? ? "Invalid Issue!" : @issue.errors.full_messages}
    end
  end

  def update_status
    update_params = {'status_id' => params[:status_id], 'fixed_version_id' => params[:fixed_version_id]}

    if @issue.present? && @issue.update_issue(update_params, STATUS_IDS)
      render :json => {result: @issue.completed?(STATUS_IDS) ? "update_success_completed" : "update_success", issue: @issue}
    else
      render :json => {result: "error", message: @issue.nil? ? "Invalid Issue!" : @issue.errors.full_messages}
    end
  end

  def update_version
    if @issue.present? && @issue.update_issue({'fixed_version_id' => params[:fixed_version_id]})
      render :json => {result: "update_success", issue: @issue}
    else
      render :json => {result: "error", message: @issue.nil? ? "Invalid Issue!" : @issue.errors.full_messages}
    end
  end
  
  def update_progress
    if @issue.present? && @issue.update_issue({'done_ratio' => params[:done_ratio]})
      render :json => {result: "update_success", issue: @issue}
    else
      render :json => {result: "error", message: @issue.nil? ? "Invalid Issue!" : @issue.errors.full_messages}
    end
  end
  
  private
  
    def set_issue
      issue_id = params[:issue_id] || params[:id] || (params[:issue] && params[:issue][:id]) || (params[:issue] && params[:issue][:issue_id])
      #TODO: check permission for this issue's instance with @hierarchy_projects
      @issue = Issue.find(issue_id) rescue nil
    end

    def issue_params
      params.require(:issue).permit(:tracker_id, :subject, :author_id, :description, :due_date, :status_id, :project_id, :assigned_to_id, :priority_id, :fixed_version_id, :start_date, :done_ratio, :estimated_hours)
    end

end
