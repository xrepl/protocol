#!/usr/bin/env python3
"""Check planning relocation/provenance; this does not verify protocol behavior."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args], text=True).strip()


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--allow-source-originals', action='store_true', help='Pre-removal check only')
    args = parser.parse_args()
    artifact = Path(__file__).resolve().parent
    project = artifact.parent
    root = project.parent
    source = args.source.resolve()
    manifest = json.loads((artifact / 'migration-manifest.json').read_text())
    errors = []

    def check(condition, message):
        if not condition:
            errors.append(message)

    for entry in manifest['files']:
        archived = root / entry['destination']
        check(archived.is_file(), f"Missing archive: {entry['destination']}")
        if archived.is_file():
            check(digest(archived) == entry['sha256'], f"Archive changed: {entry['destination']}")
            check(archived.stat().st_size == entry['bytes'], f"Archive size: {entry['destination']}")
        old = source / entry['source']
        if args.allow_source_originals:
            check(old.is_file() and digest(old) == entry['sha256'], f"Source changed: {entry['source']}")
        else:
            check(not old.exists(), f"Source original still exists: {entry['source']}")
        if entry['tracked']:
            old_blob = subprocess.check_output(['git', '-C', str(source), 'show', f"{entry['source_commit']}:{entry['source']}"])
            check(hashlib.sha256(old_blob).hexdigest() == entry['sha256'], 'Tracked provenance mismatch')

    for path, expected in manifest['implementation_baseline'].items():
        check((source / path).is_file() and digest(source / path) == expected, f'Implementation changed: {path}')

    check(git(root, 'branch', '--show-current') == 'planning', 'Planning worktree is not on planning')
    base = manifest['source_baseline']
    tip = manifest['spec_impl_tip']
    check(git(source, 'rev-parse', f'{base}^{{tree}}') == manifest['identical_tree'], 'Pinned main tree changed')
    check(git(source, 'rev-parse', f'{tip}^{{tree}}') == manifest['identical_tree'], 'spec-impl is not content-identical')
    ancestor = subprocess.run(['git', '-C', str(source), 'merge-base', '--is-ancestor', tip, base], capture_output=True)
    check(ancestor.returncode == 1, 'Expected squash integration, not spec-impl ancestry')
    # Before the first commit, HEAD is unborn; afterwards require one root with no source ancestry.
    head = subprocess.run(['git', '-C', str(root), 'rev-parse', '--verify', 'HEAD'], capture_output=True, text=True)
    if head.returncode == 0:
        roots = git(root, 'rev-list', '--max-parents=0', 'HEAD').splitlines()
        check(len(roots) == 1, 'Planning has multiple history roots')
        shared = subprocess.run(['git', '-C', str(root), 'merge-base', 'HEAD', base], capture_output=True)
        check(shared.returncode == 1, 'Planning inherits implementation ancestry')
        committed = git(root, 'ls-tree', '-r', '--name-only', 'HEAD').splitlines()
        check(not any(x.startswith(('src/', 'test/', '.github/')) or x in ('rebar.config', 'rebar.lock') for x in committed), 'Implementation files leaked into planning')

    units = manifest['scope_units']
    operations = [n for unit in units for n in unit['operations']]
    check(sorted(operations) == list(range(1, 84)), 'Operation ownership is not exactly 1..83')
    spec = (artifact / 'design/xrepl-unified-spec.md').read_text()
    check(sorted(int(n) for n in re.findall(r'^### (\d+)\. ', spec, re.M)) == list(range(1, 84)), 'Spec operation denominator changed')
    for unit in units:
        for name in ('slice-plan.md', 'ledger.md'):
            check((project / unit['path'] / name).is_file(), f"Missing {unit['path']}/{name}")
        for path in unit['sources'] + unit['tests']:
            check((source / path).is_file(), f'Missing source mapping: {path}')
    actual_slices = {x.parent.relative_to(project).as_posix() for x in project.rglob('slice-plan.md')}
    check(actual_slices == {x['path'] for x in units}, 'Slice inventory differs from manifest')
    arcs = sorted(project.glob('arc[0-9][0-9]-*'))
    check(len(arcs) == 4, 'Expected four reconstructed arcs')
    for arc in arcs:
        check((arc / 'arc-plan.md').is_file() and (arc / 'ledger.md').is_file(), f'Missing arc records: {arc.name}')
    check((project / 'project-plan.md').is_file() and (project / 'ledger.md').is_file(), 'Missing project records')
    for ledger in project.rglob('ledger.md'):
        rows = [line for line in ledger.read_text().splitlines() if re.match(r'\| (?:P-|C-|A\d)', line)]
        check(bool(rows), f'Empty ledger: {ledger}')
        check(all(line.split('|')[6].strip() == 'open' for line in rows), f'Historical acceptance silently upgraded: {ledger}')
    check(not list(project.rglob('*verification.md')), 'Synthetic independent verification file')
    check(not list(project.rglob('cc-prompt*.md')), 'Synthetic CC assignment')
    check(not list(project.rglob('closing-report.md')), 'Historical closure fabricated')

    # Imported evidence is immutable. Its historical paths/links are recorded in the mapping;
    # validate authored navigation separately, including generated heading anchors.
    def anchors(path):
        values = set()
        for line in path.read_text().splitlines():
            if line.startswith('#'):
                heading = re.sub(r'^#+\s+', '', line).strip().lower()
                values.add(re.sub(r'[^\w\- ]', '', heading).replace(' ', '-'))
        return values
    links = 0
    authored = [x for x in root.rglob('*.md') if not (artifact / 'design') in x.parents and not (artifact / 'implementation') in x.parents]
    for doc in authored:
        for raw in re.findall(r'\[[^\]]*\]\(([^)]+)\)', doc.read_text()):
            target = raw.strip('<>')
            parsed = urlsplit(target)
            if parsed.scheme or parsed.netloc:
                continue
            linked = (doc.parent / unquote(parsed.path)).resolve() if parsed.path else doc
            check(linked.exists(), f'Broken link in {doc.relative_to(root)}: {target}')
            if parsed.fragment and linked.is_file():
                check(unquote(parsed.fragment) in anchors(linked), f'Broken anchor in {doc.relative_to(root)}: {target}')
            links += 1

    if errors:
        raise SystemExit('\n'.join('FAIL: ' + e for e in errors))
    print(f"PASS: {len(manifest['files'])} exact archives; {len(manifest['implementation_baseline'])} unchanged implementation/CI files; {len(arcs)} arcs; {len(units)} slices; 83 unique operations; {links} authored local links; all carryover rows open; orphan planning history.")
    if args.allow_source_originals:
        print('PRE-REMOVAL ONLY: source originals still present; rerun without --allow-source-originals after moving them.')


if __name__ == '__main__':
    main()
