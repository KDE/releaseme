class RequirementChecker
  def initialize
    @ruby_version = RUBY_VERSION
  end

  def check
    err = false
    unless ruby_compatible?
      puts '- Ruby 2.2 or 2.2 required.'
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
    compatible?('2.1.0') || compatible?('2.2.0')
  end

  def missing_binaries
    missing_binaries = []
    missing_binaries << missing('svn')
    missing_binaries << missing('git')
    missing_binaries << missing('tar')
    missing_binaries << missing('xz')
    missing_binaries << missing('msgfmt') # for l10nstats
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
