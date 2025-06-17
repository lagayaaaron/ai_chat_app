class ChatsController < ApplicationController
  def index
  end

  def create
    query = params[:message]
    service = ChatQueryService.new(query)
    response = service.call

    render json: { response: response }
  end
end
