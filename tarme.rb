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

project = Project.new(project_name)
if not project.resolve!
    puts "Failed to resolve project"
    exit 1
end

r = KdeGitRelease.new()
# FIXME: fuck me running
r.vcs.repository = project.vcs.repository
r.source.target = "#{project_name}-#{options[:version]}"

r.get()

# FIXME: this should be done in optparser
l10n_origin = KdeL10n::TRUNK if (options[:origin] == "trunk")
l10n_origin = KdeL10n::STABLE if (options[:origin] == "stable")

# FIXME: branches are not handled
# FIXME: why not pass project itself? Oo
l = KdeL10n.new(l10n_origin, project.component, project.module)
l.get(r.source.target)

r.archive()
