module QueryLens
  class SavedQueriesController < ApplicationController
    skip_forgery_protection

    def create
      query = SavedQuery.new(saved_query_params)

      if query.save
        render json: {
          id: query.id, name: query.name, description: query.description,
          sql: query.sql, project_id: query.project_id, position: query.position
        }, status: :created
      else
        render json: { errors: query.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      query = SavedQuery.find(params[:id])

      if query.update(saved_query_params)
        render json: {
          id: query.id, name: query.name, description: query.description,
          sql: query.sql, project_id: query.project_id, position: query.position
        }
      else
        render json: { errors: query.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      query = SavedQuery.find(params[:id])
      query.destroy
      head :no_content
    end

    private

    def saved_query_params
      params.permit(:name, :description, :sql, :project_id, :position)
    end
  end
end
