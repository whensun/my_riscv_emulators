#!/usr/bin/env bash
set -euo pipefail

branch="main"
remote_url="git@github.com:whensun/my_riscv_emulators.git"
commit_message="${1:-update}"

MAX_FILE_SIZE=$((80 * 1024 * 1024))

if [ ! -d ".git" ]; then
    git init
fi

if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "$remote_url"
fi

git fetch origin || true

if git show-ref --verify --quiet "refs/heads/$branch"; then
    git switch "$branch"
else
    if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
        git switch -c "$branch" --track "origin/$branch"
    else
        git switch -c "$branch"
    fi
fi

touch .gitignore
grep -qxF 'qemu/tests/keys/' .gitignore || echo 'qemu/tests/keys/' >> .gitignore
grep -qxF '*.pem' .gitignore || echo '*.pem' >> .gitignore
grep -qxF '*.key' .gitignore || echo '*.key' >> .gitignore
grep -qxF 'id_rsa' .gitignore || echo 'id_rsa' >> .gitignore
grep -qxF 'id_dsa' .gitignore || echo 'id_dsa' >> .gitignore
grep -qxF 'id_ecdsa' .gitignore || echo 'id_ecdsa' >> .gitignore
grep -qxF 'id_ed25519' .gitignore || echo 'id_ed25519' >> .gitignore

git rm --cached -r --ignore-unmatch qemu/tests/keys >/dev/null 2>&1 || true

git add -A

echo "Checking staged file sizes..."
while IFS= read -r file; do
    [ -f "$file" ] || continue
    size="$(wc -c < "$file")"
    if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
        echo "Error: file above 80MB: $file ($size bytes)"
        exit 1
    fi
done < <(git diff --cached --name-only --diff-filter=AM)

if ! git diff --cached --quiet; then
    git commit -m "$commit_message"
else
    echo "No changes to commit."
fi

if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git pull --rebase origin "$branch"
fi

git push -u origin "$branch"