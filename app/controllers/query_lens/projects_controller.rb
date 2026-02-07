module QueryLens
  class ProjectsController < ApplicationController
    skip_forgery_protection

    def index
      projects = Project.includes(:saved_queries).map do |project|
        {
          id: project.id,
          name: project.name,
          description: project.description,
          position: project.position,
          saved_queries: project.saved_queries.map { |q| saved_query_json(q) }
        }
      end

      unorganized = SavedQuery.where(project_id: nil).map { |q| saved_query_json(q) }

      render json: { projects: projects, unorganized: unorganized }
    end

    def create
      project = Project.new(project_params)

      if project.save
        render json: { id: project.id, name: project.name, description: project.description }, status: :created
      else
        render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      project = Project.find(params[:id])

      if project.update(project_params)
        render json: { id: project.id, name: project.name, description: project.description }
      else
        render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def destroy
      project = Project.find(params[:id])
      project.destroy
      head :no_content
    end

    private

    def project_params
      params.permit(:name, :description, :position)
    end

    def saved_query_json(query)
      {
        id: query.id,
        name: query.name,
        description: query.description,
        sql: query.sql,
        project_id: query.project_id,
        position: query.position
      }
    end
  end
end
