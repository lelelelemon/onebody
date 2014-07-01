class Administration::Checkin::GroupsController < ApplicationController

  before_filter :only_admins

  def index
    @time = CheckinTime.find(params[:time_id])
    @group_times = @time.group_times
    @sections = GroupTime.distinct(:section).pluck(:section)
  end

  def create
    @time = CheckinTime.find(params[:time_id])
    Array(params[:ids]).each do |id|
      group = Group.find(id)
      unless group.group_times.where(checkin_time_id: @time.id).any?
        group.group_times.create(checkin_time: @time)
      end
    end
    redirect_to edit_administration_checkin_time_path(@time)
  end

  def update
    @time = CheckinTime.find(params[:time_id])
    if @group_time = @time.group_times.where(group_id: params[:id]).first
      @group_time.attributes = params.permit(:print_nametag, :print_extra_nametag, :section)
      @group_time.save
    end
  end

  def destroy
    @time = CheckinTime.find(params[:time_id])
    GroupTime.where(group_id: params[:id], checkin_time_id: @time.id).destroy_all
    redirect_to administration_checkin_time_groups_path(@time)
  end

  def reorder
    params["group"].to_a.each_with_index do |id, index|
      t = GroupTime.find_by_group_id_and_checkin_time_id(id, params[:time_id])
      t.update_attribute(:ordering, index+1)
    end
    render nothing: true
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_checkin)
      render text: 'You must be an administrator to use this section.', layout: true, status: 401
      return false
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render text: 'This feature is unavailable.', layout: true
      false
    end
  end
end