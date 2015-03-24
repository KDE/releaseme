class RequirementChecker
  COMPATIBLE_RUBIES = %w(2.1.0 2.2.0)
  REQUIRED_BINARIES = %w(svn git tar xz msgfmt)

  def initialize
    @ruby_version = RUBY_VERSION
  end

  def check
    err = false
    unless ruby_compatible?
      puts "- Ruby #{COMPATIBLE_RUBIES.join(' or ')} required."
      puts "  Currently using: #{@ruby_version}"
      err = true
    end
    missing_binaries.each do |m|
      puts "- Missing binary: #{m}."
      err = true
    end
    fail 'Not all requirements met.' if err
  end

  private

  def ruby_compatible?
    COMPATIBLE_RUBIES.each do |v|
      return true if compatible?(v)
    end
    false
  end

  def missing_binaries
    missing_binaries = []
    REQUIRED_BINARIES.each do |r|
      missing_binaries << missing(r)
    end
    missing_binaries.compact
  end

  def compatible?(a)
    Gem::Dependency.new('', "~> #{a}").match?('', @ruby_version)
  end

  def missing(bin)
    return bin unless system("type #{bin} > /dev/null 2>&1")
    nil
  end
end
