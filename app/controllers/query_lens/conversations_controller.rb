module QueryLens
  class ConversationsController < ApplicationController
    skip_forgery_protection

    def index
      conversations = Conversation.select(:id, :title, :updated_at).limit(50)
      render json: conversations
    end

    def show
      conversation = Conversation.find(params[:id])
      render json: {
        id: conversation.id,
        title: conversation.title,
        messages: conversation.messages,
        last_sql: conversation.last_sql,
        updated_at: conversation.updated_at
      }
    end

    def create
      conversation = Conversation.new(conversation_params)

      if conversation.save
        render json: {
          id: conversation.id,
          title: conversation.title,
          messages: conversation.messages,
          last_sql: conversation.last_sql,
          updated_at: conversation.updated_at
        }, status: :created
      else
        render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      conversation = Conversation.find(params[:id])

      if conversation.update(conversation_params)
        render json: {
          id: conversation.id,
          title: conversation.title,
          messages: conversation.messages,
          last_sql: conversation.last_sql,
          updated_at: conversation.updated_at
        }
      else
        render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      conversation = Conversation.find(params[:id])
      conversation.destroy
      head :no_content
    end

    private

    def conversation_params
      params.permit(:title, :last_sql, messages: [:role, :content])
    end
  end
end
