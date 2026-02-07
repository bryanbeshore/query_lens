module QueryLens
  class AiController < ApplicationController
    def generate
      messages = params[:messages] || []
      messages = messages.map { |m| m.permit(:role, :content).to_h }

      schema = SchemaIntrospector.cached_schema
      generator = SqlGenerator.new(schema: schema)
      result = generator.generate(messages: messages)

      render json: result
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
