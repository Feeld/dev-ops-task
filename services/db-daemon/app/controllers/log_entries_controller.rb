# frozen_string_literal: true

class LogEntriesController < ApplicationController
  before_action :set_log_entry, only: %i[show update destroy]

  # GET /log_entries
  # GET /log_entries.json
  def index
    @log_entries = LogEntry.all
  end

  # GET /log_entries/1
  # GET /log_entries/1.json
  def show; end

  # POST /log_entries
  # POST /log_entries.json
  def create
    @log_entry = LogEntry.new(log_entry_params)

    if @log_entry.save
      render :show, status: :created, location: @log_entry
    else
      render json: @log_entry.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /log_entries/1
  # PATCH/PUT /log_entries/1.json
  def update
    if @log_entry.update(log_entry_params)
      render :show, status: :ok, location: @log_entry
    else
      render json: @log_entry.errors, status: :unprocessable_entity
    end
  end

  # DELETE /log_entries/1
  # DELETE /log_entries/1.json
  def destroy
    @log_entry.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_log_entry
    @log_entry = LogEntry.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def log_entry_params
    params.require(:log_entry).permit(:details, :failing, :message_id)
  end
end
