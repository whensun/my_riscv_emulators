#!/usr/bin/env bash
set -euo pipefail

branch="main"
remote_url="git@github.com:whensun/my_riscv_emulators.git"

MAX_FILE_SIZE=$((80 * 1024 * 1024))
MAX_FILE_COUNT=20000

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

if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    if git diff --quiet && git diff --cached --quiet; then
        git pull --rebase origin "$branch"
    else
        echo "Skipping pull --rebase because local changes exist."
    fi
fi

mkdir -p .gitignore.dummy >/dev/null 2>&1 || true

if [ -f "qemu/tests/keys/id_rsa" ]; then
    git rm --cached -f "qemu/tests/keys/id_rsa" 2>/dev/null || true
fi

touch .gitignore
grep -qxF 'qemu/tests/keys/id_rsa' .gitignore || echo 'qemu/tests/keys/id_rsa' >> .gitignore
grep -qxF '*.pem' .gitignore || echo '*.pem' >> .gitignore
grep -qxF '*.key' .gitignore || echo '*.key' >> .gitignore
grep -qxF 'id_rsa' .gitignore || echo 'id_rsa' >> .gitignore
grep -qxF 'id_dsa' .gitignore || echo 'id_dsa' >> .gitignore
grep -qxF 'id_ecdsa' .gitignore || echo 'id_ecdsa' >> .gitignore
grep -qxF 'id_ed25519' .gitignore || echo 'id_ed25519' >> .gitignore

git add .

echo "Checking tracked file count..."
tracked_count="$(git ls-files | wc -l)"
if [ "$tracked_count" -gt "$MAX_FILE_COUNT" ]; then
    echo "Error: tracked file count is $tracked_count, which is above $MAX_FILE_COUNT."
    exit 1
fi

echo "Checking tracked file sizes..."
while IFS= read -r file; do
    [ -f "$file" ] || continue
    size="$(wc -c < "$file")"
    if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
        echo "Error: file above 80MB: $file ($size bytes)"
        exit 1
    fi
done < <(git ls-files)

echo "Checking for obvious private keys..."
#!/usr/bin/env bash
set -euo pipefail

branch="main"
remote_url="git@github.com:whensun/my_riscv_emulators.git"

MAX_FILE_SIZE=$((80 * 1024 * 1024))
MAX_FILE_COUNT=20000

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

if [ -f "qemu/tests/keys/id_rsa" ]; then
    git rm --cached -f "qemu/tests/keys/id_rsa" 2>/dev/null || true
fi

touch .gitignore
grep -qxF 'qemu/tests/keys/id_rsa' .gitignore || echo 'qemu/tests/keys/id_rsa' >> .gitignore
grep -qxF '*.pem' .gitignore || echo '*.pem' >> .gitignore
grep -qxF '*.key' .gitignore || echo '*.key' >> .gitignore
grep -qxF 'id_rsa' .gitignore || echo 'id_rsa' >> .gitignore
grep -qxF 'id_dsa' .gitignore || echo 'id_dsa' >> .gitignore
grep -qxF 'id_ecdsa' .gitignore || echo 'id_ecdsa' >> .gitignore
grep -qxF 'id_ed25519' .gitignore || echo 'id_ed25519' >> .gitignore

git add .

echo "Checking tracked file count..."
tracked_count="$(git ls-files | wc -l)"
if [ "$tracked_count" -gt "$MAX_FILE_COUNT" ]; then
    echo "Error: tracked file count is $tracked_count, which is above $MAX_FILE_COUNT."
    exit 1
fi

echo "Checking tracked file sizes..."
while IFS= read -r file; do
    [ -f "$file" ] || continue
    size="$(wc -c < "$file")"
    if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
        echo "Error: file above 80MB: $file ($size bytes)"
        exit 1
    fi
done < <(git ls-files)

echo "Checking for obvious private keys..."
script_name="$(basename "$0")"

while IFS= read -r file; do
    [ -f "$file" ] || continue
    [ "$(basename "$file")" = "$script_name" ] && continue

    case "$file" in
        qemu/tests/keys/*|*.pem|*.key|*id_rsa*|*id_dsa*|*id_ecdsa*|*id_ed25519*|*vagrant*)
            echo "Error: possible private key detected in tracked file: $file"
            exit 1
            ;;
    esac

    if grep -Fq "BEGIN OPENSSH PRIVATE KEY" "$file" 2>/dev/null || \
       grep -Fq "BEGIN RSA PRIVATE KEY" "$file" 2>/dev/null || \
       grep -Fq "BEGIN EC PRIVATE KEY" "$file" 2>/dev/null; then
        echo "Error: possible private key detected in tracked file: $file"
        exit 1
    fi
done < <(git ls-files)

if ! git diff --cached --quiet; then
    git commit -m "What I did was committing some changes!"
fi

if git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git pull --rebase origin "$branch"
fi

git push -u origin "$branch"