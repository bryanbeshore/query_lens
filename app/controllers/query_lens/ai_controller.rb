module QueryLens
  class AiController < ApplicationController
    def generate
      messages = params[:messages] || []
      messages = messages.map { |m| m.permit(:role, :content).to_h }

      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      schema = SchemaIntrospector.cached_schema
      generator = SqlGenerator.new(schema: schema)
      result = generator.generate(messages: messages)

      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round

      audit(action: "generate", sql: result[:sql])

      render json: result.merge(generation_ms: elapsed_ms)
    rescue => e
      audit(action: "generate_error", error: e.message)
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
