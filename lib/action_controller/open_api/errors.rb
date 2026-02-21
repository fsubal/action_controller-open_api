module ActionController
  module OpenApi
    class Error < StandardError; end

    class RequestValidationError < Error
      attr_reader :validation_errors

      def initialize(validation_errors)
        @validation_errors = validation_errors
        super("Request validation failed: #{validation_errors.map { |e| e["error"] || e[:error] }.join(", ")}")
      end
    end

    class ResponseValidationError < Error
      attr_reader :validation_errors

      def initialize(validation_errors)
        @validation_errors = validation_errors
        super("Response validation failed: #{validation_errors.map { |e| e["error"] || e[:error] }.join(", ")}")
      end
    end
  end
end
