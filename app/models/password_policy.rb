# frozen_string_literal: true

# Single source of truth for password complexity rules.
# Used by server-side validation and published to clients so that
# client-side validation can enforce the same rules without hardcoding them.
module PasswordPolicy
  MIN_LENGTH = 8
  MAX_LENGTH = 128

  RULES = [
    { id: "lowercase", pattern: "[a-z]",  message: "must include a lowercase letter" },
    { id: "uppercase", pattern: "[A-Z]",  message: "must include an uppercase letter" },
    { id: "digit",     pattern: "[0-9]",  message: "must include a digit" },
    { id: "special",   pattern: "[\\W_]", message: "must include a special character" }
  ].freeze

  FORMAT = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+\z/

  module_function

  # Returns a list of human-readable messages for each unmet rule.
  def violations(password)
    password = password.to_s
    messages = []
    messages << "must be at least #{MIN_LENGTH} characters" if password.length < MIN_LENGTH
    messages << "must be at most #{MAX_LENGTH} characters" if password.length > MAX_LENGTH
    RULES.each do |rule|
      messages << rule[:message] unless Regexp.new(rule[:pattern]).match?(password)
    end
    messages
  end

  def to_h
    {
      min_length: MIN_LENGTH,
      max_length: MAX_LENGTH,
      required_classes: RULES.map { |rule| rule[:id] },
      rules: RULES.map { |rule| rule.slice(:id, :pattern, :message) }
    }
  end
end
