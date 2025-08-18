# Releasing ShopifyApp

## Prerequisites

Before starting a release, ensure you have:

- Merged all code change PRs into main/master
- Access to publish the gem via Shipit

## Release Process

### Step 1: Prepare the Release Branch

1. **Ensure all feature changes are merged**

   ```bash
   git checkout main
   git pull origin main
   ```

   Verify: Latest commits should match GitHub's main branch.

2. **Review changes to determine version bump**
   - Apply [semantic versioning](https://semver.org/):
     - PATCH (X.Y.Z+1): Bug fixes only
     - MINOR (X.Y+1.0): New features, backward compatible
     - MAJOR (X+1.0.0): Breaking changes

### Step 2: Create Release Pull Request

1. **Create a new branch**

   ```bash
   git checkout -b vX.Y.Z
   ```

2. **Update version numbers**
   
   Edit `lib/shopify_app/version.rb`:
   ```ruby
   module ShopifyApp
     VERSION = "X.Y.Z"  # Replace with your version
   end
   ```
   
   Edit `package.json`:
   ```json
   {
     "version": "X.Y.Z"  // Replace with your version
   }
   ```

3. **Update dependencies**

   ```bash
   bundle install
   ```

   Expected: Gemfile.lock updates with new version.

4. **Update CHANGELOG**
   - Add entry with the new version and date:

     ```markdown
     ## X.Y.Z (YYYY-MM-DD)
     
     - [#PR_NUMBER](https://github.com/Shopify/shopify_app/pull/PR_NUMBER) Description of change
     - List all changes since last release
     ```

5. **Create and push PR**

   ```bash
   git add -A
   git commit -m "Packaging for release vX.Y.Z"
   git push origin release-vX.Y.Z
   ```

   - Title PR: "Packaging for release X.Y.Z"
   - Add release notes to PR description

### Step 3: Tag and Publish

1. **After PR is merged, update local main**

   ```bash
   git checkout main
   git pull origin main
   ```

   Verify: `git log -1` shows your merge commit.

2. **Create and push tag**

   ```bash
   git tag -f vX.Y.Z && git push origin vX.Y.Z
   ```

   Verify: Tag appears at https://github.com/Shopify/shopify_app/tags

3. **Check Create Release workflow**

   Monitor the GitHub Actions workflow to ensure it completes successfully.

4. **Publish via Shipit**

   Use Shipit to build and push the gem to RubyGems.
   
   Note: If you see an error like 'You need to create the vX.Y.X tag first', clear git cache in Shipit settings.

5. **Verify gem publication**

   Check the gem on https://rubygems.org/gems/shopify_app
   
   Expected: Shows your new version (may take 5-10 minutes).
