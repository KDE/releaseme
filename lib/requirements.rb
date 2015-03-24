BEGIN {
  require_relative 'requirement_checker'
  RequirementChecker.new.check
}
