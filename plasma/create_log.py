#!/usr/bin/env python3

# stolen from release-tools Applications/15.04 branch, thanks Albert
# TODO: make it so we can share

import os
import subprocess
#edited jr, escape & to &amp; and cgi.escape
import cgi

def getVersionFrom(repo):
        #jr changed to just return nothing (will diff to latest commit)
        return ""
#	f = open(versionsDir + '/' + repo)
#	return f.readlines()[1].strip()
	

f = open('git-repositories-for-release')
#srcdir="/d/kde/src/5/"
srcdir=os.getcwd() + "/tmp-changelog/"
repos=[]

line = f.read().rstrip()
repos = line.split(" ")
repos.sort()

versionsDir = os.getcwd() + "/versions"

for repo in repos:
	toVersion = getVersionFrom(repo)
	os.chdir(srcdir+repo)

	if repo == "kdelibs":
		fromVersion = "v4.14.4"
	elif repo == "kdepim":
		fromVersion = "v4.14.4"
	elif repo == "kdepimlibs":
		fromVersion = "v4.14.4"
	elif repo == "kdepim-runtime":
		fromVersion = "v4.14.4"
	elif repo == "kde-workspace":
		fromVersion = "v4.11.15"
	elif repo == "baloo":
		fromVersion = "v5.9.1"
	elif repo == "kfilemetadata":
		fromVersion = "v5.9.1"
	else:
		fromVersion = "v14.12.1"
    # jr changed to set version
	versionsFile = open("../../VERSIONS.inc")
	for line in versionsFile:
		line = line.rstrip()
		if line.startswith("OLD_VERSION="):
			fromVersion = "v" + line[12:]
		if line.startswith("OLD_BALOO_VERSION=") and (repo == "baloo" or repo == "kfilemetadata"):
			fromVersion = "v" + line[18:]

	p = subprocess.Popen('git fetch', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	retval = p.wait()
	if retval != 0:
		raise NameError('git fetch failed')

	p = subprocess.Popen('git rev-parse '+fromVersion, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	retval = p.wait()
	if retval != 0:
                #jr changed to not have show line
		#print "<h3><a name='" + repo + "' href='http://quickgit.kde.org/?p="+repo+".git'>" + repo + "</a> <a href='#" + repo + "' onclick='toggle(\"ul" + repo +"\", this)'>[Show]</a></h3>"
		print("### [{0}](https://commits.kde.org/{0}))\n".format(repo))
		print("+ New in this release")
		continue

	p = subprocess.Popen('git diff '+fromVersion+'..'+toVersion, shell=True, stdout=subprocess.PIPE)
	diffOutput = p.stdout.readlines()
	retval = p.wait()
	if retval != 0:
		raise NameError('git diff failed', repo, fromVersion, toVersion)

	if len(diffOutput):
		p = subprocess.Popen('git log '+fromVersion+'..'+toVersion, shell=True, stdout=subprocess.PIPE)
		commit = []
		commits = []
		for line in p.stdout.readlines():
			if line.startswith("commit"):
				if len(commit) > 1 and not ignoreCommit:
					commits.append(commit)
				commitHash = line[7:].strip()
				ignoreCommit = False
				commit = [commitHash]
			elif line.startswith("Author"):
				pass
			elif line.startswith("Date"):
				pass
			elif line.startswith("Merge"):
					ignoreCommit = True
			else:
				line = line.strip()
				if line.startswith("Merge remote-tracking branch"):
					ignoreCommit = True
				elif line.startswith("SVN_SILENT"):
					ignoreCommit = True
				elif line.startswith("GIT_SILENT"):
					ignoreCommit = True
				elif line.startswith("Merge branch"):
					ignoreCommit = True
                                #added jr 2017-02-07 for merges
				elif line.startswith("Merge Plasma"):
					ignoreCommit = True
                                # changed jr ignore update version commits
				elif line.startswith("Update version number for"):
					ignoreCommit = True
				elif line:
					commit.append(line)
		# Add the last commit
		if len(commit) > 1 and not ignoreCommit:
			commits.append(commit)
		
		if len(commits):
			print("{{{{< details title=\"{0}\" href=\"https://commits.kde.org/{0}\" >}}}}".format(repo))
			for commit in commits:
				extra = ""
				changelog = commit[1]
				
				for line in commit:
					line = cgi.escape(line)
					if line.startswith("BUGS:"):
						bugNumbers = line[line.find(":") + 1:].strip()
						for bugNumber in bugNumbers.split(","):
							if bugNumber.isdigit():
								if extra:
									extra += ". "
								extra += "Fixes bug [#{0}](https://bugs.kde.org/{0})".format(bugNumber)
					elif line.startswith("BUG:"):
						bugNumber = line[line.find(":") + 1:].strip()
						if bugNumber.isdigit():
							if extra:
								extra += ". "
							extra += "Fixes bug [#{0}](https://bugs.kde.org/{0})".format(bugNumber)
					elif line.startswith("REVIEW:"):
						if extra:
							extra += ". "
						reviewNumber = line[line.find(":") + 1:].strip()
						extra += "Code review [#{0}](https://git.reviewboard.kde.org/r/{0})"
						# jr addition 2017-02 phab link
					elif line.startswith("Differential Revision:"):
						if extra:
							extra += ". "
						reviewNumber = line[line.find("org/") + 4:].strip()
						extra += "Phabricator Code review [{0}](https://phabricator.kde.org/{0})".format(reviewNumber)
					elif line.startswith("CCBUG:"):
						if extra:
							extra += ". "
						bugNumber = line[line.find(":") + 1:].strip()
						extra += "See bug [#{0}](https://bugs.kde.org/{0})".format(bugNumber)
					elif line.startswith("FEATURE:"):
						feature = line[line.find(":") + 1:].strip()
						if feature.isdigit():
							if extra:
								extra += ". "
							extra += "Implements feature [#{0}](https://bugs.kde.org/{0})".format(feature)
						else:
							if feature:
								changelog = feature
							
					elif line.startswith("CHANGELOG:"):
						#extra += "CHANGELOG" + line
						#edited jr don't break
						#raise NameError('Unhandled CHANGELOG')
                                                changelog = line[11:] # remove word "CHANGELOG: "
					elif line.startswith("Merge Plasma"):
                                                pass
				
				commitHash = commit[0]
				if not changelog.endswith("."):
					changelog = changelog + "."
				capitalizedChangelog = changelog[0].capitalize() + changelog[1:]
				print("+ {} [Commit.](http://commits.kde.org/{}/{}) {}".format(capitalizedChangelog, repo, commitHash, extra))

				# edited jr, add newlines
			print("{{< /details >}}\n")
		retval = p.wait()
		if retval != 0:
			raise NameError('git log failed', repo, fromVersion, toVersion)
