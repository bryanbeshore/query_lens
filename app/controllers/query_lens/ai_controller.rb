module QueryLens
  class AiController < ApplicationController
    def generate
      messages = params[:messages] || []
      messages = messages.map { |m| m.permit(:role, :content).to_h }

      schema = SchemaIntrospector.cached_schema
      generator = SqlGenerator.new(schema: schema)
      result = generator.generate(messages: messages)

      audit(action: "generate", sql: result[:sql])

      render json: result
    rescue => e
      audit(action: "generate_error", error: e.message)
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
