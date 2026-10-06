# Card Game Calculator

Score keeper for **Trix Complex** and **Estimation** — Arabic & English, no ads, works offline.

- Trix Complex: 4 kingdoms, Trix + Complex (King −75, Queens −25, Diamonds −10, tricks −15, doubling), solo or partners.
- Estimation (Egyptian rules): bids, call, with, dash / dash call, risk, only winner / loser, Sa'aydeh — every value adjustable.

Builds run on GitHub Actions (`.github/workflows/build.yml`): every push to `main` publishes a signed APK and AAB as a release.
The upload keystore is stored encrypted (`keystore/upload.p12.enc`); CI decrypts it with the `KEYSTORE_PASSWORD` secret.
