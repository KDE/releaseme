#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: Albert Astals Cid <aacid@kde.org>
# SPDX-FileCopyrightText: 2015 Jonathan Riddell <jr@jriddell.org>
# SPDX-FileCopyrightText: 2016 David Edmundson <kde@davidedmundson.co.uk>
# SPDX-FileCopyrightText: 2020 Bhushan Shah <bhush94@gmail.com>
# SPDX-FileCopyrightText: 2020-2021 Carl Schwan <carl@carlschwan.eu>

# stolen from release-tools Applications/15.04 branch, thanks Albert

import os
import subprocess
import html

def getVersionFrom(repo):
        #jr changed to just return nothing (will diff to latest commit)
        return ""


f = open('git-repositories-for-release-plasma')
srcdir=os.getcwd() + "/tmp-changelog/"
repos=[]

line = f.read().rstrip()
repos = line.split("\n")
repos.sort()

versionsDir = os.getcwd() + "/versions"

for repo in repos:
	toVersion = getVersionFrom(repo)
	os.chdir(srcdir+repo)

	versionsFile = open("../../VERSIONS.inc")
	for line in versionsFile:
		line = line.rstrip()
		if line.startswith("OLD_VERSION="):
			fromVersion = "v" + line[12:]

	p = subprocess.Popen('git fetch', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
	retval = p.wait()
	if retval != 0:
		raise NameError('git fetch failed')

	p = subprocess.Popen('git diff '+fromVersion+'..'+toVersion, shell=True, stdout=subprocess.PIPE)
	diffOutput = p.stdout.readlines()
	retval = p.wait()
	if retval != 0:
		print("{{{{< details title=\"{0}\" href=\"https://commits.kde.org/{0}\" >}}}}".format(repo))
		print("+ New in this release")
		print("{{< /details >}}\n")

	if len(diffOutput):
		p = subprocess.Popen('git log --no-merges --first-parent '+fromVersion+'..'+toVersion, shell=True, stdout=subprocess.PIPE, universal_newlines=True)
		commit = []
		commits = []
		for line in p.stdout.readlines():
			ignoreCommit = False
			if str(line).startswith("commit"):
				if len(commit) > 1 and not ignoreCommit:
					commits.append(commit)
				commitHash = line[7:].strip()
				commit = [commitHash]
			elif str(line).startswith("Author"):
				pass
			elif str(line).startswith("Date"):
				pass
			elif str(line).startswith("Merge"):
				ignoreCommit = True
			else:
				line = line.strip()
				if str(line).startswith("Merge remote-tracking branch"):
					ignoreCommit = True
				elif str(line).startswith("SVN_SILENT"):
					ignoreCommit = True
				elif str(line).startswith("GIT_SILENT"):
					ignoreCommit = True
				elif str(line).startswith("In case of conflict in i18n"):
					ignoreCommit = True
				elif str(line).startswith("To resolve a particular conflict"):
					ignoreCommit = True
				elif str(line).startswith("Merge branch"):
					ignoreCommit = True
                                    #added jr 2017-02-07 for merges
				elif str(line).startswith("Merge Plasma"):
					ignoreCommit = True
                                # changed jr ignore update version commits
				elif str(line).startswith("Update version number for"):
					ignoreCommit = True
				elif str(line).startswith("Update version for new release"):
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
					line = html.escape(str(line))
					if str(line).startswith("BUGS:"):
						bugNumbers = line[line.find(":") + 1:].strip()
						for bugNumber in bugNumbers.split(","):
							if bugNumber.isdigit():
								if extra:
									extra += ". "
								extra += "Fixes bug [#{0}](https://bugs.kde.org/{0})".format(bugNumber)
					elif str(line).startswith("BUG:"):
						bugNumber = line[line.find(":") + 1:].strip()
						if bugNumber.isdigit():
							if extra:
								extra += ". "
							extra += "Fixes bug [#{0}](https://bugs.kde.org/{0})".format(bugNumber)
					elif str(line).startswith("ENHANCEMENT:"):
						enhancementNumber = line[line.find(":") + 1:].strip()
						if enhancementNumber.isdigit():
							if extra:
								extra += ". "
							extra += "Implements improvement [#{0}](https://bugs.kde.org/{0})".format(enhancementNumber)
					elif str(line).startswith("CCBUG:"):
						if extra:
							extra += ". "
						bugNumber = line[line.find(":") + 1:].strip()
						extra += "See bug [#{0}](https://bugs.kde.org/{0})".format(bugNumber)
					elif str(line).startswith("FEATURE:"):
						feature = line[line.find(":") + 1:].strip()
						if feature.isdigit():
							if extra:
								extra += ". "
							extra += "Implements feature [#{0}](https://bugs.kde.org/{0})".format(feature)
						else:
							if feature:
								changelog = feature

					elif str(line).startswith("CHANGELOG:"):
                                                changelog = line[11:] # remove word "CHANGELOG: "
					elif str(line).startswith("Merge Plasma"):
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
