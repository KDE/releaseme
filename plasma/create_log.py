#!/usr/bin/env python

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

print "<script type='text/javascript'>"
print "function toggle(toggleUlId, toggleAElem) {"
print "var e = document.getElementById(toggleUlId)"
print "if (e.style.display == 'none') {"
print "e.style.display='block'"
print "toggleAElem.innerHTML = '[Hide]'"
print "} else {"
print "e.style.display='none'"
print "toggleAElem.innerHTML = '[Show]'"
print "}"
print "}"
print "</script>"

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
		print "<h3><a name='" + repo + "' href='https://commits.kde.org/"+repo+"'>" + repo + "</a></h3>"
		print "<ul id='ul" + repo + "' style='display: block'><li>New in this release</li></ul>"
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
				pass
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
                                # changed jr ignore update version commits
				elif line.startswith("Update version number for"):
					ignoreCommit = True
				elif line:
					commit.append(line)
		# Add the last commit
		if len(commit) > 1 and not ignoreCommit:
			commits.append(commit)
		
		if len(commits):
                        # jr changed to now have show line
			#print "<h3><a name='" + repo + "' href='http://quickgit.kde.org/?p="+repo+".git'>" + repo + "</a> <a href='#" + repo + "' onclick='toggle(\"ul" + repo +"\", this)'>[Show]</a></h3>"
			print "<h3><a name='" + repo + "' href='https://commits.kde.org/"+repo+"'>" + repo + "</a> </h3>" 
			print "<ul id='ul" + repo + "' style='display: block'>"
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
								extra += "Fixes bug <a href='https://bugs.kde.org/" + bugNumber + "'>#" + bugNumber + "</a>"
					elif line.startswith("BUG:"):
						bugNumber = line[line.find(":") + 1:].strip()
						if bugNumber.isdigit():
							if extra:
								extra += ". "
							extra += "Fixes bug <a href='https://bugs.kde.org/" + bugNumber + "'>#" + bugNumber + "</a>"
					elif line.startswith("REVIEW:"):
						if extra:
							extra += ". "
						reviewNumber = line[line.find(":") + 1:].strip()
						extra += "Code review <a href='https://git.reviewboard.kde.org/r/" + reviewNumber + "'>#" + reviewNumber + "</a>"
					elif line.startswith("CCBUG:"):
						if extra:
							extra += ". "
						bugNumber = line[line.find(":") + 1:].strip()
						extra += "See bug <a href='https://bugs.kde.org/" + bugNumber + "'>#" + bugNumber + "</a>"
					elif line.startswith("FEATURE:"):
						feature = line[line.find(":") + 1:].strip()
						if feature.isdigit():
							if extra:
								extra += ". "
							extra += "Implements feature <a href='https://bugs.kde.org/" + feature + "'>#" + feature + "</a>"
						else:
							if feature:
								changelog = feature
							
					elif line.startswith("CHANGELOG:"):
						#extra += "CHANGELOG" + line
						#edited jr don't break
						#raise NameError('Unhandled CHANGELOG')
                                                changelog = line[11:] # remove word "CHANGELOG: "
				
				commitHash = commit[0]
				if not changelog.endswith("."):
					changelog = changelog + "."
				capitalizedChangelog = changelog[0].capitalize() + changelog[1:]
				print "<li>" + capitalizedChangelog + " <a href='https://commits.kde.org/"+repo+"/"+commitHash+"'>Commit.</a> " + extra + "</li>"

				# edited jr, add newlines
			print "</ul>\n\n"
		retval = p.wait()
		if retval != 0:
			raise NameError('git log failed', repo, fromVersion, toVersion)
