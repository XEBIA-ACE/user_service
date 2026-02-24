# frozen_string_literal: true

module Errors
  class Base          < StandardError; end
  class Unauthorized  < Base; end
  class Forbidden     < Base; end
  class NotFound      < Base; end
  class Conflict      < Base; end
  class UnprocessableEntity < Base; end
end
