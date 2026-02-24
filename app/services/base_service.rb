# frozen_string_literal: true

# Abstract base class for service objects.
# All service objects should inherit from this and implement #call.
#
# Convention:
#   - Initialize with all required dependencies via keyword arguments.
#   - #call returns a ServiceResult (never raises for business logic errors).
#   - Unexpected exceptions propagate to the controller error handler.
class BaseService
  def call
    raise NotImplementedError, "#{self.class.name} must implement #call"
  end

  private

  def success(payload = nil)
    ServiceResult.ok(payload)
  end

  def failure(error, errors: {})
    ServiceResult.fail(error, errors: errors)
  end
end
