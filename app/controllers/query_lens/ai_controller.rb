module QueryLens
  class AiController < ApplicationController
    def generate
      messages = params[:messages] || []
      messages = messages.map { |m| m.permit(:role, :content).to_h }

      schema_prompt = SchemaIntrospector.new.to_prompt
      generator = SqlGenerator.new(schema_prompt: schema_prompt)
      result = generator.generate(messages: messages)

      render json: result
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
