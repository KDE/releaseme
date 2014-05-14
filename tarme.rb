#!/usr/bin/env ruby

require 'optparse'

options = {}
OptionParser.new do |opts|
    opts.banner = "Usage: tarme.rb [options] PROJECT_NAME"

    opts.on("--origin trunk|stable", [:trunk, :stable],
            "Origin.",
            "   Used to deduce release branch and localization branches.") do |v|
        options[:origin] = v
    end

    opts.on("--version VERSION",
            "Version.",
            "   Versions should be kept in purely numerical format (e.g. x.x.x).",
            "   Alphanumerical version should be avoided if at all possible (e.g. x.x.xbeta1).") do |v|
        options[:version] = v
    end
end.parse!

if options[:origin].nil? or options[:version].nil? or ARGV.empty?
    puts "error"
    exit 1
end

project_name = ARGV.pop

p options
p ARGV
p project_name


require_relative 'lib/project'
require_relative 'lib/kdegitrelease'
require_relative 'lib/kdel10n'
require_relative 'lib/documentation'

project = Project.new(project_name)
if not project.resolve!
    puts "Failed to resolve project"
    exit 1
end
project.vcs.branch = project.i18n_trunk if options[:origin] == :trunk
project.vcs.branch = project.i18n_stable if options[:origin] == :stable

# FIXME: why not pass the project and have the release setup branches and stuff
#        doing it here means all of this is not covered by actual unittests
release = KdeGitRelease.new()
release.vcs.repository = project.vcs.repository
release.source.target = "#{project_name}-#{options[:version]}"

release.get()

# FIXME: branches are not handled
# FIXME: why not pass project itself? Oo
# FIXME: origin should be validated? technically optparse enforces proper values
l10n = KdeL10n.new(options[:origin], project.component, project.module)
l10n.get(release.source.target)

doc = DocumentationL10n.new(options[:origin], project.component, project.module)
doc.get(release.source.target)

release.archive()
