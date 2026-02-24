# frozen_string_literal: true

# Immutable value object representing the outcome of a service call.
# Services return either ServiceResult.ok(payload) or ServiceResult.fail(error).
#
# Usage:
#   result = SomeService.new(params).call
#   if result.success?
#     do_something(result.payload)
#   else
#     handle_error(result.error, result.errors)
#   end
class ServiceResult
  attr_reader :payload, :error, :errors

  def initialize(success:, payload: nil, error: nil, errors: {})
    @success = success
    @payload = payload
    @error   = error
    @errors  = errors
    freeze
  end

  def self.ok(payload = nil)
    new(success: true, payload: payload)
  end

  def self.fail(error, errors: {})
    new(success: false, error: error, errors: errors)
  end

  def success?
    @success
  end

  def failure?
    !@success
  end
end
