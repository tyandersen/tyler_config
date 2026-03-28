#!/bin/zsh

# DIFFTOOL can be opendiff, diff, or any other 2-path diff command.
DIFFTOOL=opendiff

while (( $# > 0 )); do
  case $1 in
    -d|--diff)
      DIFFTOOL=diff
      ;;
    -h|--help)
      print 'Sync repo-managed config files to their local machine paths.'
      print
      print 'Options:'
      print '  -d, --diff  use terminal diff instead of opendiff/FileMerge'
      print '  -h, --help  show this help text'
      print
      print 'The script compares each file under repo subdirectories, shows a diff,'
      print 'prompts before overwriting the local copy, and summarizes any files'
      print 'left out of sync with the repo.'
      exit 0
      ;;
    *)
      print "Unknown option: $1"
      print "Try ./sync_from_repo.zsh --help"
      exit 1
      ;;
  esac
  shift
done

setopt null_glob

# script_dir/repo_root locate the repo so path mapping works no matter where the script is run from.
script_dir=${0:A:h}
repo_root=${script_dir}

# pending_summary stores files left unsynced for the final report.
typeset -a pending_summary

# overwritten_summary stores files copied from the repo for the final report.
typeset -a overwritten_summary

# top_dirs holds top-level repo directories so root files are ignored.
typeset -a top_dirs

# summary colors make overwritten/skipped sections easier to scan.
green=$'\033[32m'
red=$'\033[31m'
reset=$'\033[0m'

map_repo_to_local() {
  local rel_path=$1

  # homedir/ in the repo stands in for ~/ on the local machine.
  if [[ $rel_path == homedir/* ]]; then
    printf '%s\n' "$HOME/${rel_path#homedir/}"
  else
    printf '/%s\n' "$rel_path"
  fi
}

show_diff() {
  local repo_path=$1
  local local_path=$2

  if [[ ! -e $local_path && ! -L $local_path ]]; then
    print "only in repo"
    return
  fi

  case $DIFFTOOL in
    opendiff)
      opendiff -wait "$local_path" "$repo_path"
      ;;
    diff)
      diff --color=auto -y --suppress-common-lines -W "${COLUMNS:-160}" "$local_path" "$repo_path"
      ;;
    *)
      "$DIFFTOOL" "$local_path" "$repo_path"
      ;;
  esac
}

prompt_overwrite() {
  local reply

  while true; do
    read -r "reply?Overwrite local from repo? [y/N] " </dev/tty
    case $reply in
      [Yy]|[Yy][Ee][Ss])
        return 0
        ;;
      ''|[Nn]|[Nn][Oo])
        return 1
        ;;
    esac
  done
}

prompt_proceed_if_repo_stale() {
  local message=$1
  local reply

  while true; do
    read -r "reply?${message} Continue anyway? [y/N] " </dev/tty
    case $reply in
      [Yy]|[Yy][Ee][Ss])
        return 0
        ;;
      ''|[Nn]|[Nn][Oo])
        return 1
        ;;
    esac
  done
}

overwrite_local() {
  local repo_path=$1
  local local_path=$2

  if [[ -L $repo_path || -L $local_path ]]; then
    print 'Refusing to copy when either side is a symlink.'
    return 1
  fi

  if [[ ! -f $repo_path ]]; then
    print "Refusing to copy non-regular repo file at ${repo_path}"
    return 1
  fi

  if [[ -e $local_path && ! -f $local_path ]]; then
    print "Refusing to overwrite non-regular local path at ${local_path}"
    return 1
  fi

  mkdir -p "${local_path:h}"

  cp -f "$repo_path" "$local_path"
}

# record_pending notes skipped files for the final summary.
record_pending() {
  local repo_rel=$1

  pending_summary+=("${repo_rel}")
}

# record_overwritten notes copied files for the final summary.
record_overwritten() {
  local repo_rel=$1

  overwritten_summary+=("${repo_rel}")
}

top_dirs=(${repo_root}/*(/N))

if (( ${#top_dirs} == 0 )); then
  print 'No directories found to process.'
  exit 0
fi

# Check whether the repo matches github/main before syncing local files from it.
if git -C "$repo_root" rev-parse --git-dir >/dev/null 2>&1; then
  repo_branch=''
  repo_branch=$(git -C "$repo_root" branch --show-current 2>/dev/null)
  local_head=''
  local_head=$(git -C "$repo_root" rev-parse HEAD 2>/dev/null)
  remote_head=''

  if ! git -C "$repo_root" fetch github >/dev/null 2>&1; then
    print 'Failed to fetch from github.'
    if ! prompt_proceed_if_repo_stale 'Could not verify that the repo is up-to-date with github/main.'; then
      print 'Aborted.'
      exit 1
    fi
  elif git -C "$repo_root" rev-parse --verify github/main >/dev/null 2>&1; then
    remote_head=$(git -C "$repo_root" rev-parse github/main 2>/dev/null)
  fi

  if [[ $repo_branch != main ]]; then
    print "Repo is on branch ${repo_branch:-'(detached HEAD)'} instead of main."
    if ! prompt_proceed_if_repo_stale 'Repo is not on main.'; then
      print 'Aborted.'
      exit 1
    fi
  elif [[ -n $remote_head && $local_head != $remote_head ]]; then
    print 'Repo is not up-to-date with github/main.'
    if ! prompt_proceed_if_repo_stale 'Repo is not up-to-date with github/main.'; then
      print 'Aborted.'
      exit 1
    fi
  fi
fi

# Walk each tracked subtree, compare repo files to their local targets, show a diff, and prompt before copying.
# Files that are skipped or cannot be copied are recorded for the final summary.
for top_dir in $top_dirs; do
  while IFS= read -r -d '' repo_path; do
    local_rel=${repo_path#$repo_root/}

    if [[ ${local_rel:t} == .gitignore ]]; then
      continue
    fi

    local_path=$(map_repo_to_local "$local_rel")

    if [[ -e $local_path || -L $local_path ]]; then
      if cmp -s "$repo_path" "$local_path"; then
        continue
      fi
    fi

    print
    print "=== ${local_rel} -> ${local_path} ==="
    show_diff "$repo_path" "$local_path"

    if prompt_overwrite; then
      if overwrite_local "$repo_path" "$local_path"; then
        record_overwritten "$local_rel"
      else
        record_pending "$local_rel"
      fi
    else
      record_pending "$local_rel"
    fi
  done < <(find "$top_dir" -mindepth 1 ! -type d -print0)
done

print
if (( ${#overwritten_summary} > 0 )); then
  printf '%sOverwritten:%s\n' "$green" "$reset"
  printf ' - %s\n' "${overwritten_summary[@]}"
  print
fi

if (( ${#pending_summary} == 0 )); then
  print 'Your machine is up-to-date'
else
  printf '%sSkipped:%s\n' "$red" "$reset"
  printf ' - %s\n' "${pending_summary[@]}"
  print
  print 'Your machine is out of sync with the repo in the files listed above.'
fi
