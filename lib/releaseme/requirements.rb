BEGIN {
  require_relative 'requirement_checker'
  ReleaseMe::RequirementChecker.new.check
}
