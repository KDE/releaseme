#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
# SPDX-FileCopyrightText: 2026 Méven Car <meven@kde.org>

# Counts the people who contributed to a release, and those who contributed for the first time.
# The people of a commit are its author, its Co-authored-by trailers, and for a cherry-pick the
# people of the original commit. A contributor is new when neither their name nor their email
# appears in any of the released repositories before the previous release. Names and emails go
# through the .mailmap of each repository.
#
# The translators of a release are the Last-Translator of each .po file whose PO-Revision-Date
# changed since the previous release. When several translators worked on one file during the
# release, only the last one is counted.
#
# Run on its own after make-changelog has cloned the repositories into tmp-changelog:
#   ./contributor_stats.py

import html
import os
import re
import subprocess
import sys

# Authors of automated commits, such as the translation updates.
IGNORED_EMAILS = {"scripty@kde.org"}
IGNORED_NAMES = {"l10n daemon script"}

CO_AUTHOR = re.compile(r"^\s*co-authored-by:\s*(.*?)\s*<([^>]*)>\s*$", re.IGNORECASE | re.MULTILINE)
CHERRY_PICK = re.compile(r"\(cherry picked from commit ([0-9a-f]{7,40})\)")


def is_ignored(name, email):
    return email.lower() in IGNORED_EMAILS or name in IGNORED_NAMES or name.endswith("[bot]")


def git(repo_dir, *args):
    return subprocess.run(["git", *args], cwd=repo_dir, capture_output=True, text=True, check=True).stdout


def read_commits(repo_dir, *log_args):
    """(hash, author name, author email, message) of each commit that git log lists."""
    output = git(repo_dir, "log", "--format=%H%x00%aN%x00%aE%x00%B%x1e", *log_args)
    commits = []
    for record in output.split("\x1e"):
        record = record.lstrip("\n")
        if record:
            commit_hash, name, email, message = record.split("\x00", 3)
            commits.append((commit_hash, name, email, message))
    return commits


def mailmap(repo_dir, contacts):
    """Maps each "Name <email>" in contacts to (name, email) after the .mailmap."""
    if not contacts:
        return {}
    mapped = git(repo_dir, "check-mailmap", *contacts).splitlines()
    result = {}
    for contact, line in zip(contacts, mapped):
        name, _, email = line.rpartition(" <")
        result[contact] = (name, email.rstrip(">"))
    return result


def existing_commits(repo_dir, revisions):
    """The revisions that name a commit of the repository."""
    if not revisions:
        return []
    output = subprocess.run(["git", "cat-file", "--batch-check"], cwd=repo_dir, input="\n".join(revisions) + "\n",
                            capture_output=True, text=True, check=True).stdout
    return [revision for revision, line in zip(revisions, output.splitlines()) if line.split(" ")[1:2] == ["commit"]]


def people_by_commit(repo_dir, revision_range, follow_cherry_picks=True):
    """Maps the hash of each non-merge commit in revision_range to its people, as (name, email)
    pairs with lower case emails: the author first, then the co-authors. For a cherry-pick whose
    original commit is in the repository, the people of the original commit come first. Automated
    authors are left out."""
    commits = read_commits(repo_dir, "--no-merges", revision_range)

    originals = {}  # revision named in the message -> (hash, name, email, message)
    if follow_cherry_picks:
        named = sorted({original for _, _, _, message in commits for original in CHERRY_PICK.findall(message)})
        found = existing_commits(repo_dir, named)
        if found:
            full_hashes = git(repo_dir, "rev-parse", *found).split()
            by_hash = {original[0]: original for original in read_commits(repo_dir, "--no-walk", *found)}
            for revision, full_hash in zip(found, full_hashes):
                originals[revision] = by_hash[full_hash]

    def co_author_contacts(message):
        return ["{} <{}>".format(name, email) for name, email in CO_AUTHOR.findall(message)]

    contacts = set()
    for _, _, _, message in commits + list(originals.values()):
        contacts.update(co_author_contacts(message))
    mapped = mailmap(repo_dir, sorted(contacts))

    def people_of(name, email, message):
        people = [(name, email)]
        people.extend(mapped[contact] for contact in co_author_contacts(message))
        return people

    result = {}
    for commit_hash, name, email, message in commits:
        people = []
        for original in CHERRY_PICK.findall(message):
            if original in originals:
                people.extend(people_of(*originals[original][1:]))
        people.extend(people_of(name, email, message))
        unique = []
        seen = set()
        for person_name, person_email in people:
            person_email = person_email.lower()
            if is_ignored(person_name, person_email) or person_email in seen or person_name in seen:
                continue
            seen.update((person_name, person_email))
            unique.append((person_name, person_email))
        result[commit_hash] = unique
    return result


def has_revision(repo_dir, revision):
    return subprocess.run(["git", "rev-parse", "--verify", "--quiet", revision + "^{commit}"],
                          cwd=repo_dir, capture_output=True).returncode == 0


def collect(repos):
    """repos is a list of (repo_dir, from_revision, to_revision); an empty to_revision is HEAD.

    Returns the names of all contributors and of the new ones, each sorted, and the repositories
    that were left out because they have no from_revision."""
    release_people = {}  # email -> name
    earlier_names = set()
    earlier_emails = set()
    skipped = []
    for repo_dir, from_revision, to_revision in repos:
        if not has_revision(repo_dir, from_revision):
            # A repository new in this release: its whole history is not part of the release.
            skipped.append(os.path.basename(repo_dir.rstrip("/")))
            continue
        release = people_by_commit(repo_dir, "{}..{}".format(from_revision, to_revision))
        for people in release.values():
            for name, email in people:
                release_people.setdefault(email, name)
        # A cherry-pick before the release has its original before the release too.
        earlier = people_by_commit(repo_dir, from_revision, follow_cherry_picks=False)
        for people in earlier.values():
            for name, email in people:
                earlier_names.add(name)
                earlier_emails.add(email)

    # One person can commit under several emails with the same name.
    contributors = sorted(set(release_people.values()), key=str.casefold)
    newcomers = sorted({name for email, name in release_people.items()
                        if email not in earlier_emails and name not in earlier_names},
                       key=str.casefold)
    return contributors, newcomers, skipped


PO_HEADER_FIELD = re.compile(r'^"(PO-Revision-Date|Last-Translator): *(.*?)\\n"$', re.MULTILINE)


def po_header(content):
    """The PO-Revision-Date and Last-Translator of a .po file, as a dict."""
    header = content.split("\n\n", 1)[0]
    return dict(PO_HEADER_FIELD.findall(header))


def read_blobs(repo_dir, revisions):
    """The content of each "revision:path", None for one that does not exist."""
    process = subprocess.run(["git", "cat-file", "--batch"], cwd=repo_dir,
                             input="".join(revision + "\n" for revision in revisions).encode(),
                             capture_output=True, check=True)
    output = process.stdout
    contents = []
    position = 0
    for _ in revisions:
        line_end = output.index(b"\n", position)
        fields = output[position:line_end].split(b" ")
        position = line_end + 1
        if fields[-1] == b"missing" or len(fields) != 3:
            contents.append(None)
            continue
        size = int(fields[2])
        contents.append(output[position:position + size].decode("utf-8", "replace"))
        position += size + 1
    return contents


def collect_translations(repos):
    """repos is a list of (repo_dir, from_revision, to_revision); an empty to_revision is HEAD.

    Returns the number of translators, and of languages, of the .po files that were translated
    since from_revision. Repositories without from_revision are left out."""
    translators = {}  # email or name -> name
    languages = set()
    for repo_dir, from_revision, to_revision in repos:
        if not has_revision(repo_dir, from_revision):
            continue
        to_revision = to_revision or "HEAD"
        changed = git(repo_dir, "diff", "--name-only", from_revision, to_revision, "--", "po/*.po").split()
        if not changed:
            continue
        old_contents = read_blobs(repo_dir, ["{}:{}".format(from_revision, path) for path in changed])
        new_contents = read_blobs(repo_dir, ["{}:{}".format(to_revision, path) for path in changed])
        for path, old_content, new_content in zip(changed, old_contents, new_contents):
            if new_content is None:
                continue
            new_header = po_header(new_content)
            old_header = po_header(old_content) if old_content else {}
            if new_header.get("PO-Revision-Date") == old_header.get("PO-Revision-Date"):
                continue
            name, _, email = new_header.get("Last-Translator", "").partition("<")
            name = name.strip()
            email = email.rstrip(">").strip().lower()
            if not name or name == "FULL NAME" or is_ignored(name, email):
                continue
            translators.setdefault(email or name, name)
            languages.add(path.split("/")[1])
    return len(set(translators.values())), len(languages)


def markdown_escape(text):
    text = html.escape(text)
    for character in "\\`*_[]":
        text = text.replace(character, "\\" + character)
    return text


def markdown_section(contributors, newcomers, translators=0, languages=0):
    lines = ["", "## Contributors", ""]
    if len(contributors) == 1:
        lines.append("1 person contributed to this release.")
    else:
        lines.append("{} people contributed to this release.".format(len(contributors)))
    if newcomers:
        if len(newcomers) == 1:
            lines[-1] += " 1 of them contributed for the first time:"
        else:
            lines[-1] += " {} of them contributed for the first time:".format(len(newcomers))
        # An HTML list, so that it takes as many columns of 14em as fit the page.
        lines.append("")
        lines.append('<ul style="columns: 14em; column-gap: 2em;">')
        lines.extend("<li>{}</li>".format(html.escape(name)) for name in newcomers)
        lines.append("</ul>")
    if translators:
        lines.append("")
        lines.append("{} {} updated the translations, in {} {}.".format(
            translators, "translator" if translators == 1 else "translators",
            languages, "language" if languages == 1 else "languages"))
    lines.append("")
    return "\n".join(lines)


def read_versions(path):
    values = {}
    with open(path) as versions_file:
        for line in versions_file:
            line = line.split("#", 1)[0].strip()
            if "=" in line:
                key, _, value = line.partition("=")
                values[key] = value.strip().strip('"')
    return values


def main():
    plasma_dir = os.path.dirname(os.path.abspath(__file__))
    versions = read_versions(os.path.join(plasma_dir, "VERSIONS.inc"))
    with open(os.path.join(plasma_dir, "git-repositories-for-release-" + versions["PRODUCT"])) as repo_list:
        repo_names = sorted(line.strip() for line in repo_list if line.strip())
    src_dir = os.path.join(os.getcwd(), "tmp-changelog")
    repos = [(os.path.join(src_dir, repo), "v" + versions["OLD_VERSION"], "") for repo in repo_names]
    contributors, newcomers, skipped = collect(repos)
    for repo in skipped:
        print("{}: no tag v{}, left out of the contributor count".format(repo, versions["OLD_VERSION"]),
              file=sys.stderr)
    translators, languages = collect_translations(repos)
    print(markdown_section(contributors, newcomers, translators, languages))


if __name__ == "__main__":
    main()
