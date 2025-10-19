name: Semantic Versioning

on:
  push:
    branches:
      - main
      - ci-cd
  pull_request:
    branches:
      - main

  workflow_dispatch:
    inputs:
      dry_run:
        description: "Dry-run mode (no commits/tags)"
        required: false
        type: boolean
        default: false
      force_version:
        description: "Force specific version (e.g., 1.0.0)"
        type: string
        required: false
  workflow_call:
    inputs:
      dry_run:
        description: "Dry-run mode (no commits/tags)"
        required: false
        type: boolean
        default: false
      force_version:
        description: "Force specific version (e.g., 1.0.0)"
        type: string
        required: false

jobs:
  versioning:
    name: Semantic Release
    runs-on: self-hosted
    outputs:
      handle: ${{ steps.tag.outputs.new_version }}

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0 # important to get full commit history
          fetch-tags: true
          persist-credentials: true

      - name: Setup commit info
        id: commit_info
        run: |
          if [ "${{ github.event_name }}" == "pull_request" ]; then
            USER_NAME="${{ github.event.pull_request.user.login }}"
            USER_EMAIL="${USER_NAME}@users.noreply.github.com"
            COMMIT_MESSAGE="${{ github.event.pull_request.title }}"
          else
            USER_NAME="${{ github.event.head_commit.author.name }}"
            USER_EMAIL="${{ github.event.head_commit.author.email }}"
            COMMIT_MESSAGE="${{ github.event.head_commit.message }}"
          fi

          if [ "${{ github.event_name }}" == "workflow_dispatch" ]; then
            echo "dry_run=${{ github.event.inputs.dry_run }}" >> $GITHUB_ENV
          else
            echo "dry_run=false" >> $GITHUB_ENV
          fi

          echo "max_attempts=3" >> $GITHUB_ENV
          echo "retry_delay=5" >> $GITHUB_ENV
          echo "commit_count=0" >> $GITHUB_ENV
          echo "feature_count=0" >> $GITHUB_ENV
          echo "fix_count=0" >> $GITHUB_ENV
          echo "refactor_count=0" >> $GITHUB_ENV
          echo "misc_count=0" >> $GITHUB_ENV
          echo "merge_count=0" >> $GITHUB_ENV
          echo "bump_type=initial" >> $GITHUB_ENV
          echo "user_name=$USER_NAME" >> $GITHUB_ENV
          echo "user_email=$USER_EMAIL" >> $GITHUB_ENV
          echo "commit_message=$COMMIT_MESSAGE" >> $GITHUB_ENV
          echo "event_name=${{ github.event_name }}" >> $GITHUB_ENV
          echo "workflow_run_id=${{ github.run_id }}" >> $GITHUB_ENV
          echo "workflow_run_number=${{ github.run_number }}" >> $GITHUB_ENV
          echo "workflow_timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" >> $GITHUB_ENV

          echo "[AUDIT] ===== WORKFLOW START ====="
          echo "[AUDIT] Event: ${{ github.event_name }}"
          echo "[AUDIT] User: $USER_NAME"
          echo "[AUDIT] Branch: ${{ github.ref_name }}"
          echo "[AUDIT] Repository: ${{ github.repository }}"
          echo "[AUDIT] Commit: ${{ github.sha }}"
          echo "[AUDIT] Run ID: ${{ github.run_id }}"
          if [ "$DRY_RUN" == "true" ]; then
            echo "[AUDIT] 🔍 DRY-RUN MODE ENABLED - No commits or tags will be created"
          fi

      - name: Get latest tag
        id: get_tag
        run: |
          tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "not_init")
          echo "last_tag=$tag" >> $GITHUB_ENV
          echo "[AUDIT] Last tag found: $tag"

      - name: Get commits since last tag
        id: commits
        run: |
          # Vérifie si le tag existe
          if git rev-parse ${{ env.last_tag }} >/dev/null 2>&1; then
            echo "[AUDIT] Tag exists, getting commits since ${{ env.last_tag }}"
            commits=$(git log ${{ env.last_tag }}..HEAD --pretty=format:"%s%n%b")
          else
            echo "[AUDIT] No previous tag found, using all commits"
            commits=$(git log HEAD --pretty=format:"%s%n%b")
            new_version="v0.0.0"
            echo "new_version=$new_version" >> $GITHUB_ENV
          fi
          commit_count=$(echo "$commits" | wc -l)
          echo "commit_count=$commit_count" >> $GITHUB_ENV
          echo "[AUDIT] Total commits: $commit_count"

          {
            echo "commits<<EOF"
            echo "$commits"
            echo "EOF"
          } >> $GITHUB_ENV

      - name: Determine next version
        if: ${{ env.last_tag != 'not_init' }}
        id: bump
        run: |
          LAST_TAG="${{ env.last_tag }}"

          major=$(echo "$LAST_TAG" | cut -d. -f1 | tr -d v)
          minor=$(echo "$LAST_TAG" | cut -d. -f2)
          patch=$(echo "$LAST_TAG" | cut -d. -f3)

          bump="none"

          if echo "${{ env.commits }}" | grep -E -q "(BREAKING CHANGE|!:)"; then
            bump="major"
          elif echo "${{ env.commits }}" | grep -E -q "^(feat|✨|🚀)"; then
            bump="minor"
          elif echo "${{ env.commits }}" | grep -E -q "^(fix|🐛|perf|⚡|refactor|♻️|🎨)"; then
            bump="patch"
          fi

          if [ "$bump" = "none" ]; then
          echo "[AUDIT] No version bump needed"
          new_version="$LAST_TAG"
          echo "new_version=$new_version" >> $GITHUB_ENV
          exit 0
          fi

          if [ "$bump" = "major" ]; then
          major=$((major+1)); minor=0; patch=0
          elif [ "$bump" = "minor" ]; then
          minor=$((minor+1)); patch=0
          elif [ "$bump" = "patch" ]; then
          patch=$((patch+1))
          fi

          new_version="v${major}.${minor}.${patch}"
          echo "bump_type=$bump" >> $GITHUB_ENV
          echo "new_version=$new_version" >> $GITHUB_ENV
          echo "[AUDIT] Version bump: $bump → $new_version"

      - name: Generate changelog text
        if: ${{ env.event_name == 'push' &&!startsWith(env.commit_message, 'docs(changelog)') }}
        id: changelog
        run: |
          echo "[AUDIT] Starting changelog generation"
          VERSION_TITLE="## ${{ env.new_version }}"
          TMP_FILE="CHANGELOG_TMP.md"
          FINAL_FILE="CHANGELOG.md"
          REPO_URL="https://github.com/${{ github.repository }}"
          LAST_TAG="${{ env.last_tag }}"

          extract_commits() {
            local pattern="$1"
            echo "$ALL_COMMITS_FORMATTED" | grep -E "^- ${pattern}" | while read -r line; do
              # Si le commit commence par le pattern (type connu)
              if [[ "$line" =~ ^-[[:space:]]$pattern(\(|\\|\!|:) ]]; then
                # echo "New line matched pattern '$pattern': $line" >&2
                echo "$line" | sed -E 's#(\\!:|!:)#:#g; s#^- (feat|fix|refactor|perf)(\(([^)]+)\)):#- \3:#; s#^- :#- #g'
              else
                # echo "Line not matching pattern '$pattern': $line" >&2
                echo "$line"
              fi
            done
          }

          extract_misc_commits() {
            # Tout ce qui n'est pas feat, fix, refactor, perf, BREAKING CHANGE
            echo "$ALL_COMMITS_FORMATTED" \
              | grep -Ev "^- ((feat|fix|refactor|perf)(\(|:)|(✨|🚀|🐛|♻️|⚡|🎨))|BREAKING CHANGE|!:|Merge" | sed -E "s|//||g; s|\\?!:|:|g" || true
          }
          extract_merge_commits() {
            # Tout ce qui n'est pas feat, fix, refactor, perf, BREAKING CHANGE
            echo "$ALL_COMMITS_FORMATTED" \
              | grep "Merge" || true
          }

          if [[ "${{ env.last_tag }}" != "not_init" ]]; then
            ALL_COMMITS_FORMATTED="$(git log "${LAST_TAG}..HEAD" --pretty=format:"- %s ([commit %h](${REPO_URL}/commit/%H)) by %an" || true)"

            echo "$ALL_COMMITS_FORMATTED"

            echo "$VERSION_TITLE - $(date +'%Y-%m-%d')" > $TMP_FILE
            echo "" >> $TMP_FILE

            # --- ⚠️ BREAKING CHANGE ---
            breakingChange=$(echo "$ALL_COMMITS_FORMATTED" | grep -E "(BREAKING CHANGE|!:)" | sed -E "s|//||g; s|\\?!:|:|g" || true)
            if [ -n "$breakingChange" ]; then
              echo "### ⚠️ Breaking Changes" >> "$TMP_FILE"
              echo "${breakingChange//!:/:}" >> "$TMP_FILE"
              echo "" >> "$TMP_FILE"
              echo "[AUDIT] ⚠️ Found breaking changes"
            fi

            # --- 🚀 Features ---
            features=$(extract_commits "(feat|✨|🚀)")
            if [ -n "$features" ]; then
              echo "### 🚀 Features" >> "$TMP_FILE"
              echo "$features" >> "$TMP_FILE"
              echo "" >> "$TMP_FILE"
              feature_count=$(echo "$features" | wc -l)
              echo "feature_count=$feature_count" >> $GITHUB_ENV
              echo ""
              echo "[AUDIT] 🚀 Found $feature_count features"
            fi

            # --- 🐛 Fixes ---
            fixes=$(extract_commits "(fix|🐛)")
            if [ -n "$fixes" ]; then
              echo "### 🐛 Fixes" >> "$TMP_FILE"
              echo "$fixes" >> "$TMP_FILE"
              echo "" >> "$TMP_FILE"
              fix_count=$(echo "$fixes" | wc -l)
              echo "fix_count=$fix_count" >> $GITHUB_ENV
              echo ""
              echo "[AUDIT] 🐛 Found $fix_count fixes"
            fi

            # --- ♻️ Refactors / Performance ---
            refactors=$(extract_commits "(refactor|♻️|perf|⚡|🎨)")
            if [ -n "$refactors" ]; then
              echo "### ♻️ Refactors / Performance" >> "$TMP_FILE"
              echo "$refactors" >> "$TMP_FILE"
              echo "" >> "$TMP_FILE"
              refactor_count=$(echo "$refactors" | wc -l)
              echo "refactor_count=$refactor_count" >> $GITHUB_ENV
              echo ""
              echo "[AUDIT] ♻️ Found $refactor_count refactors"
            fi
            
            # --- 📝 Autres changements ---
            misc=$(extract_misc_commits)
            if [ -n "$misc" ]; then
              echo "### 📝 Autres changements" >> "$TMP_FILE"
              echo "$misc" >> "$TMP_FILE"
              echo "" >> "$TMP_FILE"
              misc_count=$(echo "$misc" | wc -l)
              echo "misc_count=$misc_count" >> $GITHUB_ENV
              echo ""
              echo "[AUDIT] 📝 Found $misc_count misc commits"
            fi

            # --- 🔀 Merges & Pull Requests ---
            merge=$(extract_merge_commits)
            if [ -n "$merge" ]; then
              echo "### 🔀 Merges" >> "$TMP_FILE"
              echo "$merge" >> "$TMP_FILE"
              echo "" >> "$TMP_FILE"
              merge_count=$(echo "$merge" | wc -l)
              echo "merge_count=$merge_count" >> $GITHUB_ENV
              echo ""
              echo "[AUDIT] Found 🔀 $merge_count merge commits"
            fi
            
            contributors=$(git log "${LAST_TAG}..HEAD" --pretty=format:"%an" | sort -u | wc -l)
            files_changed=$(git log "${LAST_TAG}..HEAD" --name-only --pretty=format: | sort -u | wc -l)
            start_date=$(git log "${LAST_TAG}" -1 --format=%cs)
            end_date=$(date +'%Y-%m-%d')
            impact_score=$(( feature_count*3 + fix_count*2 + refactor_count + misc_count/2 ))
            echo "period=${start_date} → ${end_date}" >> $GITHUB_ENV
            echo "contributors=$contributors" >> $GITHUB_ENV
            echo "files_changed=$files_changed" >> $GITHUB_ENV
            echo "impact_score=$impact_score" >> $GITHUB_ENV

            echo "### 📊 Release Stats" >> "$TMP_FILE"
            echo "- Commits: ${{ env.commit_count }}" >> "$TMP_FILE"
            echo "- Contributors: $contributors" >> "$TMP_FILE"
            echo "- Files changed: $files_changed" >> "$TMP_FILE"
            echo "- Period: $start_date → $end_date" >> "$TMP_FILE"
            echo "- Impact score: $impact_score 🚀" >> "$TMP_FILE"
            if [ "${{ env.last_tag }}" != "${{ env.new_version }}" ]; then
              echo "- Compare changes: [${{ env.last_tag }}...${{ env.new_version }}](${REPO_URL}/compare/${{ env.last_tag }}...${{ env.new_version }})" >> $TMP_FILE
            fi
            echo "" >> "$TMP_FILE"

            contributors_list=$(git log "${LAST_TAG}..HEAD" --pretty=format:"%an" | sort -u)
            if [ -n "$contributors_list" ]; then
              echo "### 🤝 Contributors" >> "$TMP_FILE"
              echo "$contributors_list" | sed 's/^/- /' >> "$TMP_FILE"
              echo "" >> "$TMP_FILE"
            fi
            

            # --- Fusion si le changelog existe déjà ---
            if [ -f "$FINAL_FILE" ] && grep -q "^$VERSION_TITLE" "$FINAL_FILE"; then
              echo "[AUDIT] Merging new commits under existing version"

              # Extraire tout le changelog sauf la première occurrence du titre
              awk -v ver="$VERSION_TITLE" '
                BEGIN {found=0}
                {
                  if ($0 ~ ver && found==0) {found=1; next}
                  print
                }' "$FINAL_FILE" > CHANGELOG_OLD.tmp

              # Concaténer le nouveau bloc + ancien contenu (sans doublon)
              cat "$TMP_FILE" CHANGELOG_OLD.tmp > "$FINAL_FILE"
            else
              # Nouveau changelog ou nouvelle version
              if [ -f "$FINAL_FILE" ]; then
                cat "$TMP_FILE" "$FINAL_FILE" > CHANGELOG_NEW.tmp
                mv CHANGELOG_NEW.tmp "$FINAL_FILE"
              else
                mv "$TMP_FILE" "$FINAL_FILE"
              fi
            fi
            
            echo "[AUDIT] Changelog generation completed"

            echo "CHANGELOG<<EOF" >> $GITHUB_ENV
            cat "$FINAL_FILE" >> $GITHUB_ENV
            echo "EOF" >> $GITHUB_ENV

          else
            echo "[AUDIT] Skipping changelog generation (first version)"
            touch "$FINAL_FILE"
          fi

      - name: Commit changelog
        if: ${{env.event_name == 'push' && !startsWith(env.commit_message, 'docs(changelog)') && env.dry_run == 'false' }}
        run: |
          MAX_ATTEMPTS="${{ env.max_attempts }}"
          RETRY_DELAY="${{ env.retry_delay }}"

          echo "[AUDIT] Starting changelog commit"
          git config user.name "${{ env.user_name }}"
          git config user.email "${{ env.user_email }}"

          echo "[AUDIT] Git configured as ${{ env.user_name }} <${{ env.user_email }}>"
          git add CHANGELOG.md
          if ! git diff --cached --quiet; then
            git commit -m "docs(changelog): update for ${{ env.new_version }}"
            ATTEMPT=1
            while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
              echo "[AUDIT] Push attempt ${ATTEMPT}/${MAX_ATTEMPTS}..."
              if git push; then
                echo "[AUDIT] Changelog committed and pushed successfully"
                exit 0
              fi
              echo "[AUDIT] Push failed, retrying in ${RETRY_DELAY}s... (attempt ${ATTEMPT}/${MAX_ATTEMPTS})"
              sleep $RETRY_DELAY
              ATTEMPT=$((ATTEMPT+1))
            done
            if [ $ATTEMPT -gt $MAX_ATTEMPTS ]; then
              echo "[ERROR] Failed to push changelog after ${MAX_ATTEMPTS} attempts"
              exit 1
            fi
          else
            echo "[AUDIT] No changelog updates to push"
          fi

      - name: Tag new version
        if: ${{ env.event_name == 'push' && env.dry_run == 'false' }}
        id: tag
        run: |
          MAX_ATTEMPTS="${{ env.max_attempts }}"
          RETRY_DELAY="${{ env.retry_delay }}"
          retry_push() {
            local push_cmd="$1"
            local action_desc="$2"
            local attempt=1
            
            while [ $attempt -le $MAX_ATTEMPTS ]; do
              echo "[AUDIT] $action_desc - Attempt $attempt/$MAX_ATTEMPTS..."
              
              if eval "$push_cmd"; then
                echo "[AUDIT] ✅ $action_desc succeeded"
                return 0
              fi
              
              if [ $attempt -lt $MAX_ATTEMPTS ]; then
                echo "[AUDIT] ⏳ $action_desc failed, retrying in ${RETRY_DELAY}s..."
                sleep $RETRY_DELAY
              fi
              
              attempt=$((attempt+1))
            done
            
            echo "[ERROR] ❌ $action_desc failed after $MAX_ATTEMPTS attempts"
            return 1
          }
          echo "[AUDIT] Starting tag creation"
          TAG="${{ env.new_version }}"
          CURRENT_COMMIT=$(git rev-parse HEAD)

          # Vérifie si le tag existe déjà
          if git rev-parse "$TAG" >/dev/null 2>&1; then
            TAG_COMMIT=$(git rev-list -n 1 "$TAG")
            if [ "$TAG_COMMIT" = "$CURRENT_COMMIT" ]; then
              echo "[AUDIT] ✅ Tag $TAG already points to HEAD. Skipping re-tag."
              echo "new_version=$TAG" >> $GITHUB_OUTPUT
              exit 0
            else
              echo "[AUDIT] ⚠️ Tag $TAG exists but points to another commit. Updating it safely..."
              git tag -d "$TAG"
              git tag "$TAG"
              git push origin ":refs/tags/$TAG"
              git push origin "$TAG"
              if ! retry_push "git push origin ':refs/tags/$TAG' 2>/dev/null" "Deleting old tag"; then
                echo "[WARN] Could not delete old tag on remote, but continuing with new tag..."
              fi
            fi
          else
            echo "[AUDIT] 🏷️ Creating new tag $TAG"
            git tag "$TAG"
          fi
          # Retry pour pusher le nouveau tag
          if retry_push "git push origin '$TAG'" "Pushing new tag"; then
            echo "[AUDIT] Tag created and pushed successfully"
            echo "new_version=$TAG" >> $GITHUB_OUTPUT
            exit 0
          else
            echo "[ERROR] Failed to push tag after $MAX_ATTEMPTS attempts"
            exit 1
          fi

      - name: Preview changes (dry-run)
        if: ${{ env.dry_run == 'true' }}
        run: |
          echo ""
          echo "========== DRY-RUN PREVIEW =========="
          echo "Version: ${{ env.new_version }}"
          echo "Bump Type: ${{ env.bump_type }}"
          echo ""
          echo "Would create:"
          echo "  - Changelog entry"
          echo "  - Commit: docs(changelog): update for ${{ env.new_version }}"
          echo "  - Tag: ${{ env.new_version }}"
          echo ""
          echo "Stats:"
          echo "  - Features: ${{ env.feature_count }}"
          echo "  - Fixes: ${{ env.fix_count }}"
          echo "  - Refactors: ${{ env.refactor_count }}"
          echo "  - Other changes: ${{ env.misc_count }}"
          echo "  - Merges: ${{ env.merge_count }}"
          echo ""
          echo "Preview of changelog:"
          echo "---"
          if [ -f CHANGELOG.md ]; then
            head -n 30 CHANGELOG.md
          else
            echo "(No changelog generated)"
          fi
          echo "---"
          echo "===================================="
          echo ""

      - name: Output version
        run: |
          echo ""
          echo "========== WORKFLOW AUDIT SUMMARY =========="
          echo "Timestamp: ${{ env.workflow_timestamp }}"
          echo "Run ID: ${{ env.workflow_run_id }}"
          echo "Run Number: ${{ env.workflow_run_number }}"
          echo "Event: ${{ env.event_name }}"
          echo "Branch: ${{ github.ref_name }}"
          echo "User: ${{ env.user_name }}"
          echo "Repository: ${{ github.repository }}"
          echo "Commit: ${{ github.sha }}"
          echo ""
          echo "Version Details:"
          echo "  Previous: ${{ env.last_tag }}"
          echo "  New: ${{ env.new_version }}"
          echo "  Bump Type: ${{ env.bump_type }}"
          echo "  Dry-run: ${{ env.dry_run }}"
          echo ""
          echo "Changelog Stats:"
          echo "  Commits: ${{ env.commit_count }}"
          echo "  Features: ${{ env.feature_count }}"
          echo "  Fixes: ${{ env.fix_count }}"
          echo "  Refactors: ${{ env.refactor_count }}"
          echo "  Other: ${{ env.misc_count }}"
          echo "  Merges: ${{ env.merge_count }}"
          echo ""
          echo "Global Stats:"
          echo "  Impact Score: ${{ env.impact_score }} 🚀"
          echo "  Contributors: ${{ env.contributors }}"
          echo "  Files Changed: ${{ env.files_changed }}"
          echo "  Period: ${{ env.period }}"
          echo ""
          echo "=========================================="
          echo ""