## Major/Minor Release from `main`

- [ ] Run `cargo update`
- [ ] Update CHANGELOG.md
- [ ] Update `FIREURL_VERSION` in the 'Installation' section of README.md on `main`
- [ ] Draft a new Release in GitHub
  - Create a new tag: `v{{version}}`
  - Target: `main`
  - Title: `v{{version}`
  ```markdown
  ## What's Changed
  {{CHANGELOG.md}}

  **All changes**: https://github.com/rusty-snake/fireurl/compare/v{{previous_version}}...v{{version}}
  **Changelog**: https://github.com/rusty-snake/fireurl/blob/main/CHANGELOG.md


  ## New Contributors
  * @user made their first contribution in https://github.com/rusty-snake/fireurl/pull/123

  ---

  ou can use [minisign] (or OpenBSD's signify) to verify the assets like:

  ```bash
  minisign -V -P RWS65FES3L8OgwhyZPHwbh1GyXsCZvJtQ5y4LXWHJKMpkhjNXNDt0Bzi -m fireurl-v{{version}}-x86_64-unknown-linux-musl.tar.xz
  ```

  [minisign]: https://jedisct1.github.io/minisign/
  ```
  - Check "Create a discussion for this release"
- [ ] Publish Release
- [ ] Fetch tag
- [ ] Update `version` in Cargo.toml (post-release bump)
- [ ] Build: `MINISIGN=<PATH> FIREURL_GIT_REF=v{{version}} ./dist.sh`
- [ ] Attach `outdir/*` to Release

## Minor/Patch Release from `release/v1.2.3`

- [ ] Cherry-Pick
- [ ] Run `cargo update`
- [ ] Update CHANGELOG.md on `main` and `release/v1.2.3`
- [ ] Update `version` in Cargo.toml on `release/v1.2.3`
- [ ] Update `FIREURL_VERSION` in the 'Installation' section of README.md on `main`
- [ ] Draft a new Release in GitHub
  - Create a new tag: `v{{version}}`
  - Target: `release/v1.2.3`
  - Title: `v{{version}`
  ```markdown
  ## What's Changed
  {{CHANGELOG.md}}

  **All changes**: https://github.com/rusty-snake/fireurl/compare/v{{previous_version}}...v{{version}}
  **Changelog**: https://github.com/rusty-snake/fireurl/blob/main/CHANGELOG.md


  ## New Contributors
  * @user made their first contribution in https://github.com/rusty-snake/fireurl/pull/123

  ---

  ou can use [minisign] (or OpenBSD's signify) to verify the assets like:

  ```bash
  minisign -V -P RWS65FES3L8OgwhyZPHwbh1GyXsCZvJtQ5y4LXWHJKMpkhjNXNDt0Bzi -m fireurl-v{{version}}-x86_64-unknown-linux-musl.tar.xz
  ```

  [minisign]: https://jedisct1.github.io/minisign/
  ```
  - Check "Create a discussion for this release"
- [ ] Publish Release
- [ ] Fetch tag
- [ ] Build: `MINISIGN=<PATH> FIREURL_GIT_REF=v{{version}} ./dist.sh`
- [ ] Attach `outdir/*` to Release
